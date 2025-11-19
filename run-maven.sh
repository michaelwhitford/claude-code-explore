#!/bin/bash
# Maven wrapper script with proxy configuration

export MAVEN_OPTS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8888 -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8888 -Dhttp.nonProxyHosts=localhost|127.0.0.1"

echo "Starting Maven with proxy configuration..."
echo "MAVEN_OPTS=$MAVEN_OPTS"
echo ""

exec /opt/maven/bin/mvn "$@"
