#!/bin/bash
# Clojure Development Setup for Claude Code Runtime
#
# This script sets up everything needed for Clojure development with deps.edn
# in the Claude Code runtime environment.
#
# Features:
# - Idempotent: Safe to run multiple times
# - Configurable: Set PROXY_PORT environment variable to customize port
# - Auto-detects: Reads upstream proxy from http_proxy environment variable
#
# Usage:
#   source setup-clojure.sh
#   PROXY_PORT=9999 source setup-clojure.sh

set -e

# Configuration (can be overridden by environment variables)
PROXY_PORT="${PROXY_PORT:-8888}"
PROXY_LOG="/tmp/proxy.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Validate PROXY_PORT
if ! [[ "$PROXY_PORT" =~ ^[0-9]+$ ]] || [ "$PROXY_PORT" -lt 1024 ] || [ "$PROXY_PORT" -gt 65535 ]; then
    echo "[ERROR] Invalid PROXY_PORT: $PROXY_PORT"
    echo "  Port must be a number between 1024 and 65535"
    return 1
fi

echo "============================================================"
echo "Clojure Development Setup for Claude Code"
echo "============================================================"
echo ""
echo "Configuration:"
echo "  Proxy port: $PROXY_PORT"
echo "  Proxy log:  $PROXY_LOG"
echo ""

# ============================================================
# 1. Verify http_proxy environment variable
# ============================================================

if [ -z "$http_proxy" ] && [ -z "$HTTP_PROXY" ]; then
    echo "[WARN] No http_proxy environment variable detected"
    echo "  The proxy wrapper requires http_proxy to be set"
    echo "  Continuing anyway, but proxy may not work correctly"
    echo ""
fi

# ============================================================
# 2. Check/Install Clojure CLI
# ============================================================

if command -v clojure &> /dev/null; then
    echo "[OK] Clojure CLI already installed"
    clojure --version
else
    echo "Installing Clojure CLI..."
    INSTALLER_PATH="$REPO_ROOT/installers/linux-install-1.11.1.1435.sh"
    if [ -f "$INSTALLER_PATH" ]; then
        bash "$INSTALLER_PATH"
        echo "[OK] Clojure CLI installed successfully"
    else
        echo "[ERROR] Clojure installer not found: $INSTALLER_PATH"
        echo "  Please ensure the installer is in the repository"
        return 1
    fi
fi

echo ""

# ============================================================
# 3. Start Proxy Wrapper
# ============================================================

if pgrep -f "proxy-wrapper.py.*$PROXY_PORT" > /dev/null; then
    PROXY_PID=$(pgrep -f "proxy-wrapper.py.*$PROXY_PORT")
    echo "[OK] Proxy wrapper already running on port $PROXY_PORT (PID: $PROXY_PID)"
else
    # Check if different port is running
    if pgrep -f "proxy-wrapper.py" > /dev/null; then
        OLD_PID=$(pgrep -f "proxy-wrapper.py")
        echo "[WARN] Proxy wrapper running on different port (PID: $OLD_PID)"
        echo "  Stopping old proxy wrapper..."
        kill $OLD_PID 2>/dev/null || true
        sleep 1
    fi

    # Check if port is available
    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$PROXY_PORT "; then
            echo "[WARN] Port $PROXY_PORT appears to be in use by another process"
            echo "  The proxy may fail to start. Consider using a different port:"
            echo "  PROXY_PORT=8889 source setup-clojure.sh"
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$PROXY_PORT "; then
            echo "[WARN] Port $PROXY_PORT appears to be in use by another process"
            echo "  The proxy may fail to start. Consider using a different port:"
            echo "  PROXY_PORT=8889 source setup-clojure.sh"
        fi
    fi

    echo "Starting proxy wrapper on port $PROXY_PORT..."
    if [ -f "$SCRIPT_DIR/proxy-wrapper.py" ]; then
        python3 "$SCRIPT_DIR/proxy-wrapper.py" $PROXY_PORT > $PROXY_LOG 2>&1 &
        sleep 2

        if pgrep -f "proxy-wrapper.py.*$PROXY_PORT" > /dev/null; then
            PROXY_PID=$(pgrep -f "proxy-wrapper.py.*$PROXY_PORT")
            echo "[OK] Proxy wrapper started (PID: $PROXY_PID)"
        else
            echo "[ERROR] Failed to start proxy wrapper"
            echo "  Check logs: tail $PROXY_LOG"
            return 1
        fi
    else
        echo "[ERROR] proxy-wrapper.py not found in $SCRIPT_DIR"
        return 1
    fi
fi

echo "  Logs: $PROXY_LOG"
echo ""

# ============================================================
# 4. Configure Maven Settings (for Clojure CLI)
# ============================================================

MAVEN_SETTINGS="$HOME/.m2/settings.xml"
mkdir -p "$HOME/.m2"

# Always recreate settings.xml to ensure port is correct (idempotent)
echo "Configuring Maven settings.xml for proxy..."
cat > "$MAVEN_SETTINGS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <proxies>
    <proxy>
      <id>local-proxy-http</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>127.0.0.1</host>
      <port>$PROXY_PORT</port>
      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts>
    </proxy>
    <proxy>
      <id>local-proxy-https</id>
      <active>true</active>
      <protocol>https</protocol>
      <host>127.0.0.1</host>
      <port>$PROXY_PORT</port>
      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts>
    </proxy>
  </proxies>
</settings>
EOF
echo "[OK] Created $MAVEN_SETTINGS"

echo ""

# ============================================================
# 5. Export Java System Properties
# ============================================================

echo "Exporting Java proxy settings..."

export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=$PROXY_PORT"

echo "[OK] JAVA_TOOL_OPTIONS configured"
echo ""

# ============================================================
# 6. Configure Gradle (Optional but recommended)
# ============================================================

GRADLE_PROPS="$HOME/.gradle/gradle.properties"
mkdir -p "$HOME/.gradle"

# Always recreate gradle.properties to ensure port is correct (idempotent)
echo "Configuring Gradle proxy settings..."
cat > "$GRADLE_PROPS" <<EOF
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=$PROXY_PORT
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=$PROXY_PORT
systemProp.http.nonProxyHosts=localhost|127.0.0.1
EOF
echo "[OK] Created $GRADLE_PROPS"

echo ""

# ============================================================
# Summary
# ============================================================

echo "============================================================"
echo "Setup Complete!"
echo "============================================================"
echo ""
echo "You can now use Clojure CLI with deps.edn:"
echo ""
echo "  # Start a REPL"
echo "  clojure"
echo ""
echo "  # Run a project"
echo "  clojure -M:run"
echo ""
echo "  # Show classpath"
echo "  clojure -Spath"
echo ""
echo "Try the example project:"
echo "  cd $REPO_ROOT/examples/greenfield/simple-app && clojure -M:run"
echo ""
echo "To check proxy activity:"
echo "  tail -f $PROXY_LOG"
echo ""
echo "To use a different port next time:"
echo "  PROXY_PORT=9999 source setup-clojure.sh"
echo ""
echo "============================================================"
