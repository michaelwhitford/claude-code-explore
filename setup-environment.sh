#!/bin/bash
# Environment setup script for Java/Clojure development with proxy

PROXY_PORT=8888
PROXY_LOG="/tmp/proxy.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "================================================"
echo "Java/Clojure Proxy Environment Setup"
echo "================================================"
echo ""

# Check if proxy wrapper is already running
if pgrep -f "proxy-wrapper.py" > /dev/null; then
    echo "✓ Proxy wrapper is already running"
    PROXY_PID=$(pgrep -f "proxy-wrapper.py")
    echo "  PID: $PROXY_PID"
else
    echo "Starting proxy wrapper..."
    if [ -f "$SCRIPT_DIR/proxy-wrapper.py" ]; then
        python3 "$SCRIPT_DIR/proxy-wrapper.py" $PROXY_PORT > $PROXY_LOG 2>&1 &
        sleep 2

        if pgrep -f "proxy-wrapper.py" > /dev/null; then
            PROXY_PID=$(pgrep -f "proxy-wrapper.py")
            echo "✓ Proxy wrapper started successfully"
            echo "  PID: $PROXY_PID"
            echo "  Log: $PROXY_LOG"
        else
            echo "✗ Failed to start proxy wrapper"
            echo "  Check $PROXY_LOG for errors"
            return 1
        fi
    else
        echo "✗ proxy-wrapper.py not found in $SCRIPT_DIR"
        return 1
    fi
fi

echo ""
echo "Configuring environment..."

# Export Java system properties for command-line tools
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=$PROXY_PORT"

# Export MAVEN_OPTS for Maven
export MAVEN_OPTS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=$PROXY_PORT"

# Export GRADLE_OPTS for Gradle (though gradle.properties is preferred)
export GRADLE_OPTS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=$PROXY_PORT -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=$PROXY_PORT"

# Add Clojure to PATH if installed in .local
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "✓ Environment configured"
echo ""
echo "Environment variables set:"
echo "  JAVA_TOOL_OPTIONS=$JAVA_TOOL_OPTIONS"
echo "  MAVEN_OPTS=$MAVEN_OPTS"
echo "  GRADLE_OPTS=$GRADLE_OPTS"
echo ""

# Check and create Gradle configuration
GRADLE_PROPS="$HOME/.gradle/gradle.properties"
if [ ! -f "$GRADLE_PROPS" ]; then
    echo "Creating Gradle proxy configuration..."
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
    echo "✓ Gradle configuration exists: $GRADLE_PROPS"
fi

# Check and create Maven configuration (though it has issues)
MAVEN_SETTINGS="$HOME/.m2/settings.xml"
if [ ! -f "$MAVEN_SETTINGS" ]; then
    echo ""
    echo "Note: Maven proxy configuration has known issues."
    echo "We recommend using Gradle instead."
fi

echo ""
echo "================================================"
echo "Setup complete!"
echo "================================================"
echo ""
echo "You can now use:"
echo "  • gradle build (recommended for Clojure projects)"
echo "  • java with automatic proxy configuration"
echo "  • clojure (if installed)"
echo ""
echo "To test the setup:"
echo "  cd test-gradle && gradle build"
echo ""
echo "To view proxy activity:"
echo "  tail -f $PROXY_LOG"
echo ""
