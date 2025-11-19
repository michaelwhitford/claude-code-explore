#!/bin/bash
# Gradle wrapper script with proxy configuration

# Set proxy system properties
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8888 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8888"

echo "Starting Gradle with proxy configuration..."
echo "JAVA_TOOL_OPTIONS=$JAVA_TOOL_OPTIONS"
echo ""

exec gradle "$@"
