# Clojure Runtime for Claude Code

A simple, reusable setup for Clojure development in the Claude Code runtime environment with HTTP proxy support.

## Quick Start

```bash
# One-command setup
source setup-clojure.sh

# Create and run a Clojure project
mkdir my-app && cd my-app
cat > deps.edn <<EOF
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}}
 :aliases {:run {:main-opts ["-m" "my-app.core"]}}}
EOF

mkdir -p src/my_app
cat > src/my_app/core.clj <<EOF
(ns my-app.core)
(defn -main [& args]
  (println "Hello from Clojure!"))
EOF

# Run it
clj -M:run
```

## How It Works

The Claude Code runtime uses an authenticated HTTP proxy. Java applications can't send authentication headers during HTTPS CONNECT requests, so we use a local proxy wrapper that:

1. Listens on localhost (default: 8888)
2. Auto-detects upstream proxy from `http_proxy` environment variable
3. Adds authentication headers transparently
4. Tunnels all traffic to the upstream proxy

```
clj → localhost:8888 (wrapper adds auth) → Claude Code Proxy → Maven Central/Clojars
```

## Setup Script

The `setup-clojure.sh` script is idempotent and reusable:

- **Auto-detects** proxy settings from environment variables
- **Configurable** proxy port via `PROXY_PORT` environment variable
- **Installs** Clojure CLI if needed
- **Starts** proxy wrapper if not already running
- **Creates** Maven and Gradle configurations
- **Exports** Java system properties

### Custom Proxy Port

```bash
PROXY_PORT=9999 source setup-clojure.sh
```

## Configuration

The setup script automatically creates:

### Maven Settings (`~/.m2/settings.xml`)
Configures Maven/Clojure CLI to use the local proxy wrapper.

### Gradle Properties (`~/.gradle/gradle.properties`)
Configures Gradle builds to use the local proxy wrapper.

### Environment Variables
```bash
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8888 ..."
```

## Common Commands

```bash
# Start a REPL
clj

# Show classpath
clj -Spath

# Run with main function
clj -M:run

# Run specific namespace
clj -M -m my-app.core
```

## Example Project

See `test-clojure-deps/` for a working example that downloads dependencies from both Maven Central and Clojars:

```bash
cd test-clojure-deps
clj -M:run
```

## Using Gradle

If you prefer Gradle or need Java interop:

```gradle
// build.gradle
repositories {
    mavenCentral()
    maven { url "https://repo.clojars.org/" }
}

dependencies {
    implementation 'org.clojure:clojure:1.11.1'
}
```

The setup script automatically configures Gradle proxy settings.

## Troubleshooting

### Check if proxy is running
```bash
ps aux | grep proxy-wrapper.py
tail -f /tmp/proxy.log
```

### Restart setup
```bash
source setup-clojure.sh
```

### Verify environment
```bash
echo $JAVA_TOOL_OPTIONS
cat ~/.m2/settings.xml
```

### DNS or connection errors
Re-run the setup script. It's idempotent and safe to run multiple times.

## Architecture

### Why a Proxy Wrapper?

Java's `HttpURLConnection` cannot send authentication headers during HTTPS CONNECT tunnel establishment. This is a known limitation of Java's HTTP client implementation.

The proxy wrapper (`proxy-wrapper.py`) solves this by:
1. Accepting unauthenticated connections from Java locally
2. Reading upstream proxy settings from `http_proxy` environment variable
3. Adding authentication headers before forwarding to the real proxy
4. Tunneling data bidirectionally after connection establishment

### Files

| File | Purpose |
|------|---------|
| `setup-clojure.sh` | Main setup script (idempotent, reusable) |
| `proxy-wrapper.py` | Local proxy that adds authentication |
| `test-clojure-deps/` | Example Clojure project with deps.edn |

## Verified To Work

- Clojure CLI (clj/clojure) with deps.edn
- Maven Central dependency downloads
- Clojars dependency downloads
- Git dependencies via deps.edn
- Gradle builds with Clojure dependencies

## License

MIT License - See LICENSE file for details.
