# Java/Clojure HTTP Proxy Setup for Claude Code Runtime

This repository contains documentation and scripts to enable Java-based tools (Maven, Gradle, Clojure) to download libraries from Maven Central and Clojars in the Claude Code runtime environment.

## Problem Summary

The Claude Code runtime uses an HTTP proxy with JWT authentication. While curl works perfectly with this proxy through environment variables, Java's HttpURLConnection has limitations:

1. **HTTP requests work**: Java can use the proxy for plain HTTP when the `Proxy-Authorization` header is set manually
2. **HTTPS tunneling fails**: Java cannot authenticate during CONNECT requests for HTTPS tunneling, resulting in `401 Unauthorized` errors
3. **Maven and Gradle fail**: Both tools fail to download dependencies from HTTPS repositories (Maven Central, Clojars)

## Solution

A **local proxy wrapper** written in Python that:
- Runs on `localhost:8888` (no authentication required)
- Forwards requests to the upstream authenticated proxy
- Automatically adds the JWT authentication headers
- Supports both HTTP and HTTPS (CONNECT) tunneling

## Architecture

```
Java Application
    ↓
localhost:8888 (proxy-wrapper.py)
    ↓ (adds JWT auth)
Upstream Proxy (21.0.0.189:15004)
    ↓
Internet (Maven Central, Clojars, etc.)
```

## Files in This Repository

### Core Components

- **`proxy-wrapper.py`**: Python HTTP/HTTPS proxy wrapper with authentication
- **`setup-environment.sh`**: Script to start the proxy and configure environment
- **`run-gradle.sh`**: Wrapper script for Gradle with proxy configuration
- **`test-proxy/`**: Java test programs demonstrating the proxy behavior

### Configuration Files

- **`gradle.properties.template`**: Template for Gradle proxy configuration
- **`.m2/settings.xml.template`**: Template for Maven proxy configuration (note: Maven has issues, use Gradle)

### Test Projects

- **`test-gradle/`**: Working Gradle project that downloads Clojure dependencies
- **`test-maven/`**: Maven project (for reference, but proxy authentication doesn't work reliably)

## Quick Start

### 1. Start the Proxy Wrapper

```bash
# Start the proxy wrapper in the background
python3 proxy-wrapper.py 8888 > /tmp/proxy.log 2>&1 &

# Verify it's running
tail /tmp/proxy.log
```

You should see:
```
[INFO] Proxy server listening on 127.0.0.1:8888
[INFO] Forwarding to: 21.0.0.189:15004
```

### 2. Configure Your Build Tool

#### For Gradle (Recommended)

Create or edit `~/.gradle/gradle.properties`:

```properties
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=8888
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=8888
systemProp.http.nonProxyHosts=localhost|127.0.0.1
```

Or use the project-level `gradle.properties` file in your project directory.

#### For Maven (Has Issues)

Maven's proxy support has limitations with the current setup. **We recommend using Gradle instead.**

If you must use Maven, you can try:
1. Copy `maven-settings.xml` to `~/.m2/settings.xml`
2. Set `MAVEN_OPTS` in `~/.mavenrc`

However, Maven may still fail to authenticate with the proxy for HTTPS downloads.

#### For Clojure CLI

Clojure CLI uses Maven under the hood, so it has the same limitations. **Use Gradle with Clojure dependencies** or configure similar system properties.

### 3. Test Your Setup

#### Test Gradle

```bash
cd test-gradle
gradle build
gradle testDependencies
```

Expected output:
```
BUILD SUCCESSFUL
org.clojure/clojure/1.11.1/clojure-1.11.1.jar
org.clojure/spec.alpha/0.3.218/spec.alpha-0.3.218.jar
...
```

#### Test Java Directly

```bash
cd test-proxy
javac TestLocalProxy.java

# Run with proxy configuration
java -Dhttp.proxyHost=127.0.0.1 \
     -Dhttp.proxyPort=8888 \
     -Dhttps.proxyHost=127.0.0.1 \
     -Dhttps.proxyPort=8888 \
     TestLocalProxy
```

Expected output:
```
=== Test 1: Maven Central (HTTPS) ===
   Status: SUCCESS ✓

=== Test 2: Clojars (HTTPS) ===
   Status: SUCCESS ✓
```

## Environment Setup Script

Use the provided `setup-environment.sh` script to automatically configure your environment:

```bash
source setup-environment.sh
```

This script:
1. Checks if the proxy wrapper is running
2. Starts it if needed
3. Sets Java system properties
4. Configures Gradle and Maven

## Clojure Development

### Using Gradle (Recommended)

Create a `build.gradle` file:

```gradle
plugins {
    id 'java'
}

repositories {
    mavenCentral()
    maven {
        url "https://repo.clojars.org/"
    }
}

dependencies {
    implementation 'org.clojure:clojure:1.11.1'
    implementation 'ring/ring-core:1.9.6'  // Example Clojars dependency
}
```

Configure `gradle.properties`:

```properties
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=8888
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=8888
```

Then run:

```bash
gradle build
```

### Using Clojure CLI (Alternative)

If you need to use Clojure CLI despite its limitations:

1. Install Clojure CLI to `~/.local`:
   ```bash
   curl -O https://download.clojure.org/install/linux-install-1.11.1.1435.sh
   chmod +x linux-install-1.11.1.1435.sh
   ./linux-install-1.11.1.1435.sh --prefix ~/.local
   ```

2. Add to PATH:
   ```bash
   export PATH="$HOME/.local/bin:$PATH"
   ```

3. Set Java system properties for every Clojure command:
   ```bash
   clojure -J-Dhttp.proxyHost=127.0.0.1 \
           -J-Dhttp.proxyPort=8888 \
           -J-Dhttps.proxyHost=127.0.0.1 \
           -J-Dhttps.proxyPort=8888 \
           -M:your-alias
   ```

## Technical Details

### Why Java HTTPS Proxy Authentication Fails

Java's `HttpURLConnection` handles HTTPS connections through HTTP proxies using the CONNECT method:

1. Client sends: `CONNECT example.com:443 HTTP/1.1`
2. Proxy responds with: `HTTP/1.1 200 Connection Established` (if authenticated)
3. Client establishes TLS tunnel through the proxy

The problem: Java's `Authenticator` class doesn't send credentials during step 1 for CONNECT requests with this specific proxy configuration. This is a known limitation of Java's HTTP client.

### How the Proxy Wrapper Works

The `proxy-wrapper.py` script:

1. Listens on `localhost:8888` for incoming connections
2. Parses the `http_proxy` environment variable to extract:
   - Upstream proxy host and port (`21.0.0.189:15004`)
   - JWT credentials from the URL
3. For CONNECT requests (HTTPS):
   - Forwards the CONNECT to the upstream proxy
   - Adds `Proxy-Authorization: Basic <base64-encoded-creds>` header
   - Relays the tunnel once established
4. For regular HTTP requests:
   - Adds the auth header if missing
   - Forwards the request

### Test Results

| Tool | HTTP | HTTPS | Status |
|------|------|-------|--------|
| curl | ✓ | ✓ | Works with `http_proxy` env var |
| Java (manual Proxy-Authorization) | ✓ | ✗ | HTTPS fails on CONNECT |
| Java (via proxy wrapper) | ✓ | ✓ | Both work! |
| Gradle (via proxy wrapper) | ✓ | ✓ | Downloads from Maven Central and Clojars |
| Maven (via proxy wrapper) | ✗ | ✗ | Still has issues, use Gradle |
| Clojure CLI (via proxy wrapper) | ? | ? | Untested, likely same as Maven |

## Troubleshooting

### Proxy wrapper not starting

Check if port 8888 is already in use:
```bash
lsof -i :8888
```

Use a different port:
```bash
python3 proxy-wrapper.py 9999
```

Update your proxy configuration to match.

### Gradle still failing

1. Check if the proxy wrapper is running:
   ```bash
   ps aux | grep proxy-wrapper
   ```

2. Verify `gradle.properties` has the correct settings

3. Check proxy logs for activity:
   ```bash
   tail -f /tmp/proxy.log
   ```

4. Clear Gradle cache and try again:
   ```bash
   rm -rf ~/.gradle/caches
   gradle build --refresh-dependencies
   ```

### Testing the proxy directly

Use curl to test the proxy wrapper:

```bash
# Test HTTPS through the wrapper
http_proxy=http://127.0.0.1:8888 \
https_proxy=http://127.0.0.1:8888 \
curl -I https://repo1.maven.org/maven2/
```

Should return `HTTP/1.1 200 Connection Established` followed by `HTTP/2 200`.

## Files Reference

### proxy-wrapper.py

Main proxy server script. Usage:
```bash
python3 proxy-wrapper.py [port]
```

Default port: 8888

### setup-environment.sh

Environment setup script. Usage:
```bash
source setup-environment.sh
```

Sets up:
- Starts proxy wrapper if not running
- Exports Java system properties
- Configures build tools

### Test Files

- `test-proxy/TestProxy.java` - Basic proxy test (fails without wrapper)
- `test-proxy/TestProxyAuth.java` - Test with Java Authenticator (fails for HTTPS)
- `test-proxy/TestProxyManualAuth.java` - Test with manual auth header (HTTP works, HTTPS fails)
- `test-proxy/TestLocalProxy.java` - Test with proxy wrapper (works!)

## Summary

This setup enables Java-based tools to download dependencies from Maven Central and Clojars in the Claude Code runtime. The key is using the local proxy wrapper to handle authentication, which Java's built-in HTTP client cannot do properly for HTTPS CONNECT requests.

**Recommended approach**: Use Gradle with the local proxy wrapper for reliable Clojure development.
