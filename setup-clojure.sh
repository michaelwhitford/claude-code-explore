#!/bin/bash
# Clojure Development Setup for Claude Code Runtime
#
# This script sets up everything needed for Clojure development with deps.edn
# in the Claude Code runtime environment.

set -e

PROXY_PORT=8888
PROXY_LOG="/tmp/proxy.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo "Clojure Development Setup for Claude Code"
echo "============================================================"
echo ""

# ============================================================
# 1. Check/Install Clojure CLI
# ============================================================

if command -v clojure &> /dev/null; then
    echo "✓ Clojure CLI already installed"
    clojure --version
else
    echo "Installing Clojure CLI..."
    if [ -f "$SCRIPT_DIR/linux-install-1.11.1.1435.sh" ]; then
        bash "$SCRIPT_DIR/linux-install-1.11.1.1435.sh"
        echo "✓ Clojure CLI installed successfully"
    else
        echo "✗ Clojure installer not found: $SCRIPT_DIR/linux-install-1.11.1.1435.sh"
        echo "  Please ensure the installer is in the repository"
        exit 1
    fi
fi

echo ""

# ============================================================
# 2. Start Proxy Wrapper
# ============================================================

if pgrep -f "proxy-wrapper.py" > /dev/null; then
    PROXY_PID=$(pgrep -f "proxy-wrapper.py")
    echo "✓ Proxy wrapper already running (PID: $PROXY_PID)"
else
    echo "Starting proxy wrapper..."
    if [ -f "$SCRIPT_DIR/proxy-wrapper.py" ]; then
        python3 "$SCRIPT_DIR/proxy-wrapper.py" $PROXY_PORT > $PROXY_LOG 2>&1 &
        sleep 2

        if pgrep -f "proxy-wrapper.py" > /dev/null; then
            PROXY_PID=$(pgrep -f "proxy-wrapper.py")
            echo "✓ Proxy wrapper started (PID: $PROXY_PID)"
        else
            echo "✗ Failed to start proxy wrapper"
            echo "  Check logs: tail $PROXY_LOG"
            exit 1
        fi
    else
        echo "✗ proxy-wrapper.py not found in $SCRIPT_DIR"
        exit 1
    fi
fi

echo "  Logs: $PROXY_LOG"
echo ""

# ============================================================
# 3. Configure Maven Settings (for Clojure CLI)
# ============================================================

MAVEN_SETTINGS="$HOME/.m2/settings.xml"
mkdir -p "$HOME/.m2"

if [ -f "$MAVEN_SETTINGS" ]; then
    echo "✓ Maven settings.xml already exists"
else
    echo "Creating Maven settings.xml for proxy..."
    cat > "$MAVEN_SETTINGS" <<'EOF'
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
      <port>8888</port>
      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts>
    </proxy>
    <proxy>
      <id>local-proxy-https</id>
      <active>true</active>
      <protocol>https</protocol>
      <host>127.0.0.1</host>
      <port>8888</port>
      <nonProxyHosts>localhost|127.0.0.1</nonProxyHosts>
    </proxy>
  </proxies>
</settings>
EOF
    echo "✓ Created $MAVEN_SETTINGS"
fi

echo ""

# ============================================================
# 4. Export Java System Properties
# ============================================================

echo "Exporting Java proxy settings..."

export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=$PROXY_PORT"

echo "✓ JAVA_TOOL_OPTIONS configured"
echo ""

# ============================================================
# 5. Optional: Gradle Configuration
# ============================================================

GRADLE_PROPS="$HOME/.gradle/gradle.properties"
if [ ! -f "$GRADLE_PROPS" ]; then
    echo "Creating Gradle proxy configuration (optional)..."
    mkdir -p "$HOME/.gradle"
    cat > "$GRADLE_PROPS" <<EOF
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=$PROXY_PORT
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=$PROXY_PORT
systemProp.http.nonProxyHosts=localhost|127.0.0.1
EOF
    echo "✓ Created $GRADLE_PROPS"
else
    echo "✓ Gradle configuration already exists"
fi

echo ""

# ============================================================
# Summary
# ============================================================

echo "============================================================"
echo "Setup Complete! ✓"
echo "============================================================"
echo ""
echo "You can now use Clojure CLI with deps.edn:"
echo ""
echo "  # Start a REPL"
echo "  clj"
echo ""
echo "  # Run a project"
echo "  clj -M:run"
echo ""
echo "  # Show classpath"
echo "  clj -Spath"
echo ""
echo "Try the example project:"
echo "  cd test-clojure-deps && clj -M:run"
echo ""
echo "To check proxy activity:"
echo "  tail -f $PROXY_LOG"
echo ""
echo "============================================================"
