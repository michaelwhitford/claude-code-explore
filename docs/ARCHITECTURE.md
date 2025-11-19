# Architecture: Clojure Runtime for Claude Code

This document explains the technical design, why it works, and the trade-offs made.

## The Problem

### HTTP Proxy Authentication in Java

Claude Code runtime uses an authenticated HTTP proxy to control network access. This creates a challenge for Java applications:

**Java's HTTP client cannot send authentication headers during HTTPS CONNECT tunnel establishment.**

This is a fundamental limitation in Java's `HttpURLConnection` and related HTTP client implementations. Here's what happens:

```
1. Java app initiates HTTPS request
2. Java HTTP client sends: CONNECT example.com:443 HTTP/1.1
3. Proxy requires: Proxy-Authorization header
4. Java client cannot add this header during CONNECT
5. Proxy rejects: 407 Proxy Authentication Required
6. Connection fails
```

### Why This Matters for Clojure

Clojure runs on the JVM and uses Java's HTTP libraries for:
- **Downloading dependencies** from Maven Central and Clojars
- **Git dependencies** in deps.edn
- **Any HTTP/HTTPS requests** in your code

Without solving the proxy auth problem, **Clojure cannot download dependencies** in Claude Code runtime.

## The Solution: Local Proxy Wrapper

### Design Overview

Insert a local, unauthenticated proxy that adds authentication before forwarding to the upstream proxy:

```
┌─────────────────┐
│  Clojure/Java   │
│   Application   │
└────────┬────────┘
         │ No auth required
         │ HTTP/HTTPS
         ▼
┌─────────────────┐
│   Local Proxy   │  ← proxy-wrapper.py
│  (localhost:8888)│  ← Python script
└────────┬────────┘
         │ Adds Proxy-Authorization header
         │ HTTP/HTTPS
         ▼
┌─────────────────┐
│  Claude Code    │
│     Proxy       │  ← Requires authentication
└────────┬────────┘
         │
         ▼
    Internet
(Maven Central, Clojars, etc.)
```

### Why This Works

1. **Java → Local Proxy:** Java connects to localhost:8888 without authentication (no CONNECT auth required)
2. **Local Proxy → Upstream:** Python proxy adds `Proxy-Authorization` header before forwarding
3. **Upstream → Internet:** Authenticated request succeeds, data flows back

The local proxy acts as a **transparent authentication wrapper**.

## Implementation Details

### Component 1: proxy-wrapper.py

**Technology choice:** Python
- **Why Python?** Available in Claude Code runtime, simple socket programming, good for I/O
- **Alternatives considered:** Go (not installed), Node.js (adds dependency), bash (too complex)

**Core functionality:**

```python
# Simplified flow:

1. Listen on localhost:8888
2. Accept connection from Java app
3. Read HTTP/CONNECT request
4. Parse upstream proxy from http_proxy env var
5. Connect to upstream proxy
6. Add Proxy-Authorization header
7. Forward request
8. Relay response back to Java
9. Tunnel bidirectional data
```

**Key features:**
- **Multi-threaded:** Each connection gets its own thread
- **Both HTTP and HTTPS:** Handles regular requests and CONNECT tunneling
- **Auto-configuration:** Reads proxy URL from environment
- **Credential extraction:** Parses username:password from proxy URL
- **Logging:** Activity logged to `/tmp/proxy.log`

**CONNECT handling (HTTPS):**

HTTPS requires special handling via CONNECT method:

```python
# Java sends:
CONNECT repo1.maven.org:443 HTTP/1.1

# Proxy wrapper forwards with auth:
CONNECT repo1.maven.org:443 HTTP/1.1
Proxy-Authorization: Basic <credentials>

# Upstream responds:
HTTP/1.1 200 Connection Established

# Then bidirectional tunnel:
Java ←→ Proxy Wrapper ←→ Upstream Proxy ←→ Maven
```

### Component 2: setup-clojure.sh

**Technology choice:** Bash
- **Why Bash?** Universal on Linux, good for system configuration, easy to read/modify
- **Idempotent design:** Can run multiple times safely

**Configuration layers:**

The script configures **three** different mechanisms (defense in depth):

#### Layer 1: Maven Settings (~/.m2/settings.xml)

Clojure CLI uses Maven under the hood for dependency resolution:

```xml
<proxies>
  <proxy>
    <id>local-proxy-http</id>
    <protocol>http</protocol>
    <host>127.0.0.1</host>
    <port>8888</port>
  </proxy>
  <proxy>
    <id>local-proxy-https</id>
    <protocol>https</protocol>
    <host>127.0.0.1</host>
    <port>8888</port>
  </proxy>
</proxies>
```

**Why both protocols?** Maven uses different settings for HTTP vs HTTPS repositories.

#### Layer 2: Java System Properties (JAVA_TOOL_OPTIONS)

Global Java proxy settings:

```bash
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 \
  -Dhttp.proxyPort=8888 \
  -Dhttps.proxyHost=127.0.0.1 \
  -Dhttps.proxyPort=8888"
```

**Why this too?** Some Java code ignores Maven settings and uses system properties.

#### Layer 3: Gradle Properties (~/.gradle/gradle.properties)

For Gradle builds with Clojure:

```properties
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=8888
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=8888
```

**Why separate?** Gradle has its own configuration system independent of Maven.

### Component 3: Clojure CLI Installer

**Bundled installer:** `installers/linux-install-1.11.1.1435.sh`

**Why bundle instead of download?**
- Guaranteed to work (no chicken-and-egg proxy problem)
- Specific tested version
- Fast setup (no download wait)

**Trade-off:** Version becomes outdated over time

**Alternative approach (not implemented):**
```bash
# Download latest via proxy
curl -O https://download.clojure.org/install/linux-install.sh
bash linux-install.sh
```

## Data Flow Examples

### Example 1: Downloading a Dependency

User runs: `clojure -Sdeps '{:deps {cheshire/cheshire {:mvn/version "5.11.0"}}}'`

**Flow:**

```
1. Clojure CLI starts
2. Reads Maven settings → sees proxy 127.0.0.1:8888
3. Connects to localhost:8888 (proxy wrapper)
4. Sends: CONNECT repo.clojars.org:443 HTTP/1.1
5. Proxy wrapper:
   - Reads http_proxy env var
   - Parses credentials
   - Connects to upstream proxy
   - Adds Proxy-Authorization header
   - Forwards CONNECT request
6. Upstream proxy authenticates → responds 200 OK
7. Proxy wrapper tells Java: 200 Connection Established
8. TLS handshake happens through tunnel
9. HTTP GET request for cheshire JAR
10. Data flows back through tunnel
11. Dependency downloaded successfully
```

### Example 2: Running a REPL

User runs: `clojure`

**Flow:**

```
1. Clojure CLI starts
2. Downloads Clojure JAR if needed (via proxy as above)
3. Starts JVM with JAVA_TOOL_OPTIONS
4. REPL starts
5. User can require libraries:
   (require '[clojure.data.json :as json])
6. If not in classpath, downloads via proxy
7. REPL ready with library loaded
```

### Example 3: Gradle Build

User runs: `gradle build` in Gradle project with Clojure

**Flow:**

```
1. Gradle starts
2. Reads ~/.gradle/gradle.properties
3. Sees proxy configuration
4. Connects to localhost:8888 for dependencies
5. Proxy wrapper handles authentication
6. Downloads Clojure JARs from Maven Central
7. Build succeeds
```

## Design Decisions

### Decision 1: Local Proxy vs Direct Configuration

**Chosen:** Local proxy wrapper

**Alternative:** Configure Java to handle proxy auth differently

**Rationale:**
- Java limitation is fundamental, cannot be configured around
- Local proxy is transparent to applications
- Works for all Java applications, not just Clojure
- Easy to debug (can see proxy logs)

### Decision 2: Python vs Other Languages

**Chosen:** Python 3

**Alternatives:**
- **Go:** Not in runtime, requires installation
- **Node.js:** Requires npm, adds complexity
- **Java:** Circular dependency (need proxy to download Java libs)
- **Bash/netcat:** Too complex for bidirectional tunneling

**Rationale:**
- Python 3 is in Claude Code runtime
- Good socket/threading libraries
- Easy to read and modify
- Standard library sufficient (no pip needed)

### Decision 3: Bundled vs On-Demand Installer

**Chosen:** Bundled installer

**Rationale:**
- Avoids chicken-and-egg (need proxy to download installer)
- Faster setup
- Guaranteed compatible version

**Trade-off:** Must update manually when new Clojure versions release

### Decision 4: Multiple Configuration Layers

**Chosen:** Configure Maven + JAVA_TOOL_OPTIONS + Gradle

**Why not just one?**
- Different tools read different configs
- Defense in depth ensures coverage
- Some apps override Maven settings with system properties
- Gradle completely separate ecosystem

**Overhead:** Minimal - just extra file writes during setup

### Decision 5: Idempotent Setup Script

**Chosen:** Script can run multiple times safely

**Implementation:**
- Check before install (don't re-install if present)
- Kill old proxy before starting new (handle port changes)
- Overwrite config files (ensure correct port)
- Export env vars (updates current shell)

**Rationale:**
- AI agents may run setup multiple times
- Users may need to re-run after failures
- Port may change between runs
- Safer than assuming clean state

## Security Considerations

### Credential Handling

**Proxy credentials:**
- Read from environment variable (`http_proxy`)
- Never written to disk
- Logged with masking in proxy-wrapper output
- Transmitted only to upstream proxy

**Local exposure:**
- Proxy listens on 127.0.0.1 only (not 0.0.0.0)
- Only localhost can connect
- No authentication on local proxy (not needed)

### Process Security

**Background process:**
- Runs as current user (not root)
- PID available via `pgrep`
- Can be killed by user
- Logs to /tmp (user-accessible)

**No privilege escalation:**
- Does not require sudo
- Does not modify system files (only user home)
- Does not install system packages

## Performance Characteristics

### Latency

**Added overhead per request:**
- Local TCP connection: ~1ms
- Proxy processing: ~1-2ms
- Total: ~2-3ms added latency

**Compared to direct connection:** Negligible for dependency downloads (dominated by network)

### Throughput

**Proxy wrapper:**
- Bidirectional relay in separate threads
- 8KB buffers for data transfer
- No buffering delays

**Bottleneck:** Network speed, not proxy

### Resource Usage

**Memory:**
- Python process: ~10-20MB
- Per-connection thread: ~1-2MB
- Total: Minimal for typical usage

**CPU:**
- Idle: 0%
- Active transfer: <5% (I/O bound)

## Failure Modes

### Proxy Wrapper Crashes

**Symptom:** Cannot download dependencies

**Detection:**
```bash
pgrep -f proxy-wrapper.py  # No output
```

**Recovery:**
```bash
source ./setup/setup-clojure.sh  # Restarts proxy
```

### Wrong Port Configuration

**Symptom:** Downloads fail, connection refused

**Detection:**
```bash
cat ~/.m2/settings.xml  # Shows wrong port
pgrep -f "proxy-wrapper.*8889"  # Proxy on different port
```

**Recovery:**
```bash
PROXY_PORT=8889 source ./setup/setup-clojure.sh
```

### Upstream Proxy Unreachable

**Symptom:** All downloads timeout

**Detection:**
```bash
tail /tmp/proxy.log  # Shows connection failures
```

**Recovery:** Fix network/proxy configuration (external issue)

### Credentials Invalid

**Symptom:** 407 Proxy Authentication Required

**Detection:**
```bash
tail /tmp/proxy.log  # Shows 407 responses
```

**Recovery:** Update `http_proxy` environment variable with correct credentials

## Testing Strategy

### Unit Testing: Not Implemented

**Why?** Simple scripts, integration testing more valuable

**If needed:** Could add Python unit tests for proxy logic

### Integration Testing: Comprehensive

**verify-setup.sh:**
- Tests all components together
- Actual dependency downloads
- Real network requests

**test-idempotency.sh:**
- Runs setup multiple times
- Tests edge cases
- Validates recovery

### Manual Testing

**Included examples:**
- `examples/greenfield/simple-app` - Basic deps.edn
- `examples/existing-project/deps-edn-example` - Complex dependencies
- `examples/existing-project/gradle-example` - Gradle build

## Alternatives Considered

### Alternative 1: Use Babashka Instead of Clojure CLI

**Babashka:** Fast-starting Clojure scripting environment

**Why not chosen:**
- Different from standard Clojure (subset of language)
- Doesn't solve dependency download problem
- User may need full Clojure anyway

### Alternative 2: Download All Dependencies in Advance

**Approach:** Pre-populate Maven cache

**Why not chosen:**
- Requires knowing all deps in advance
- Large download/storage
- Doesn't help with user's custom deps
- Doesn't solve the root problem

### Alternative 3: Modify Java to Support Proxy Auth

**Approach:** Use custom Java HTTP client

**Why not chosen:**
- Cannot modify system Java
- Clojure tools use built-in HTTP client
- Would need to rebuild Clojure CLI itself

### Alternative 4: VPN Instead of Proxy

**Approach:** Use VPN tunnel for network access

**Why not chosen:**
- Outside scope of this solution
- Proxy is the constraint we must work within
- VPN setup more complex than proxy wrapper

## Future Improvements

### Potential Enhancements

1. **Auto-update installer:** Download latest Clojure version on-demand
2. **Health monitoring:** Periodic checks that proxy is responsive
3. **Metrics:** Track requests, bytes transferred, errors
4. **Retry logic:** Automatically retry failed downloads
5. **Proxy pool:** Support multiple upstream proxies
6. **Configuration file:** YAML/JSON config instead of env vars

### Known Limitations

1. **IPv6:** Only IPv4 tested
2. **Authentication types:** Only Basic auth implemented (not NTLM, Kerberos)
3. **Proxy chaining:** Only one upstream proxy supported
4. **SSL/TLS inspection:** Assumes no MITM proxy

## Conclusion

This architecture solves Java's proxy authentication limitation through a simple, transparent local proxy. The design prioritizes:

- **Simplicity:** Minimal dependencies, easy to understand
- **Reliability:** Idempotent setup, comprehensive testing
- **Transparency:** Works without application changes
- **Debuggability:** Logs, verification tools, clear error messages

The result is a robust Clojure runtime setup that works reliably in Claude Code's authenticated proxy environment.
