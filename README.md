# Clojure Development in Claude Code Runtime

**Quick setup for Clojure development with deps.edn in the Claude Code runtime environment.**

> **TL;DR**: Run `source setup-clojure.sh` and start coding with `clj`.

---

## Why This Repo Exists

The Claude Code runtime uses an authenticated HTTP proxy that Java applications can't use directly for HTTPS connections. This prevents Clojure CLI from downloading dependencies from Maven Central and Clojars.

**Solution**: A local proxy wrapper that handles authentication transparently.

## Quick Start (2 minutes)

### 1. One-Command Setup

```bash
source setup-clojure.sh
```

This automatically:
- ✅ Installs Clojure CLI if needed
- ✅ Starts the proxy wrapper
- ✅ Configures all required settings

### 2. Create a Clojure Project

```bash
mkdir my-app && cd my-app
```

Create `deps.edn`:
```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}}
 :aliases {:run {:main-opts ["-m" "my-app.core"]}}}
```

Create `src/my_app/core.clj`:
```clojure
(ns my-app.core)

(defn -main [& args]
  (println "Hello from Clojure!"))
```

### 3. Run Your App

```bash
clj -M:run
```

**That's it!** Dependencies download automatically from Maven Central and Clojars.

---

## How It Works

```
clj (Clojure CLI)
    ↓
localhost:8888 (proxy wrapper adds auth)
    ↓
Claude Code Proxy (authenticated)
    ↓
Maven Central / Clojars
```

The proxy wrapper (`proxy-wrapper.py`) runs locally and adds JWT authentication headers that Java can't add itself for HTTPS CONNECT requests.

---

## Working Example

Check `test-clojure-deps/` for a complete working example:

```bash
cd test-clojure-deps
clj -M:run
```

This demo app uses:
- **org.clojure/clojure** from Maven Central
- **org.clojure/data.json** from Maven Central
- **cheshire/cheshire** from Clojars

All dependencies download through the proxy automatically.

---

## Common Commands

```bash
# Start a REPL
clj

# Show classpath
clj -Spath

# Run with main function
clj -M:run

# Run a specific namespace
clj -M -m my-app.core

# Add dependencies (edit deps.edn, then run):
clj -Spath  # Downloads new deps
```

---

## Troubleshooting

### "Failed to read artifact descriptor" or DNS errors

**Problem**: Proxy wrapper isn't running or configuration is missing.

**Solution**:
```bash
# Check if proxy is running
ps aux | grep proxy-wrapper.py

# Restart setup
source setup-clojure.sh

# Verify environment
echo $JAVA_TOOL_OPTIONS
cat ~/.m2/settings.xml
```

### "Service Unavailable (503)"

**Problem**: Temporary Maven Central hiccup.

**Solution**: Just retry the command. The error is transient.

### Check Proxy Logs

```bash
tail -f /tmp/proxy.log
```

You should see `[REQUEST]` lines showing connections to `repo1.maven.org` and `repo.clojars.org`.

---

## Configuration Details

The setup script creates two configuration files:

### 1. `~/.m2/settings.xml` (Maven/Clojure CLI)

```xml
<proxies>
  <proxy>
    <active>true</active>
    <protocol>http</protocol>
    <host>127.0.0.1</host>
    <port>8888</port>
  </proxy>
  <proxy>
    <active>true</active>
    <protocol>https</protocol>
    <host>127.0.0.1</host>
    <port>8888</port>
  </proxy>
</proxies>
```

### 2. Environment Variables

```bash
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8888 \
                          -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8888"
```

These are set automatically by `setup-clojure.sh`.

---

## Adding Dependencies

Edit `deps.edn` and add dependencies:

```clojure
{:deps {org.clojure/clojure {:mvn/version "1.11.1"}
        ring/ring-core {:mvn/version "1.9.6"}           ; From Clojars
        cheshire/cheshire {:mvn/version "5.11.0"}       ; JSON library
        http-kit/http-kit {:mvn/version "2.6.0"}}}      ; HTTP server
```

Run any `clj` command to download:
```bash
clj -Spath
```

---

## Project Structure

```
my-app/
├── deps.edn          # Dependencies and configuration
├── src/              # Source code (default path)
│   └── my_app/
│       └── core.clj
└── test/             # Tests (add to :extra-paths in alias)
    └── my_app/
        └── core_test.clj
```

Add `.gitignore`:
```
.cpcache/
.clj-kondo/
.lsp/
```

---

## Using Aliases

Create different aliases for dev, test, build:

```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}}

 :aliases
 {:run {:main-opts ["-m" "my-app.core"]}

  :test {:extra-paths ["test"]
         :extra-deps {io.github.cognitect-labs/test-runner
                      {:git/tag "v0.5.1" :git/sha "dfb30dd"}}}

  :dev {:extra-deps {nrepl/nrepl {:mvn/version "1.0.0"}
                     cider/cider-nrepl {:mvn/version "0.30.0"}}}}}
```

Usage:
```bash
clj -M:test           # Run tests
clj -M:dev            # Start dev REPL with nREPL
```

---

## Alternative: Using Gradle

If you prefer Gradle or need integration with Java projects, see [GRADLE.md](./GRADLE.md).

Gradle works well but is less common in the Clojure community. The Clojure CLI with deps.edn is the standard tool.

---

## Technical Background

### Why Java Can't Use the Proxy Directly

Java's `HttpURLConnection` can't send authentication headers during HTTPS CONNECT requests (used for establishing TLS tunnels). This is a limitation of Java's HTTP client implementation.

The proxy wrapper solves this by:
1. Accepting unauthenticated connections from Java locally
2. Adding authentication headers before forwarding to the real proxy
3. Tunneling data bidirectionally after connection establishment

For full technical details, see [FINDINGS.md](./FINDINGS.md).

---

## Files in This Repo

| File | Purpose |
|------|---------|
| `setup-clojure.sh` | **Main setup script** - Run this first |
| `proxy-wrapper.py` | Local proxy that adds authentication |
| `test-clojure-deps/` | Working example Clojure project |
| `TEST_RESULTS.md` | Detailed test results and verification |
| `FINDINGS.md` | Technical deep-dive on the proxy issue |
| `setup-environment.sh` | Original multi-tool setup (legacy) |
| `test-gradle/` | Gradle example (for Java interop) |

---

## Verified To Work

✅ **Clojure CLI** (clj/clojure) with deps.edn
✅ **Maven Central** dependency downloads
✅ **Clojars** dependency downloads
✅ **Git dependencies** via deps.edn
✅ **Gradle** with Clojure dependencies

See [TEST_RESULTS.md](./TEST_RESULTS.md) for complete test results.

---

## Getting Help

**Issue**: Proxy not working
**Check**: `ps aux | grep proxy-wrapper && tail /tmp/proxy.log`

**Issue**: Dependencies not downloading
**Check**: `cat ~/.m2/settings.xml && echo $JAVA_TOOL_OPTIONS`

**Issue**: DNS resolution errors
**Solution**: Run `source setup-clojure.sh` again

**Still stuck?**
Check the detailed troubleshooting in [TEST_RESULTS.md](./TEST_RESULTS.md) or review [FINDINGS.md](./FINDINGS.md) for technical details.

---

## Summary

This repository enables standard Clojure development with `clj` and `deps.edn` in the Claude Code runtime:

1. **Run** `source setup-clojure.sh`
2. **Create** your `deps.edn` file
3. **Start coding** with `clj`

The proxy wrapper handles all authentication automatically. No special commands or workarounds needed after initial setup.

**Happy Clojure coding! 🚀**
