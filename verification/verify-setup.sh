#!/bin/bash
# Comprehensive Clojure Setup Verification Script
#
# This script verifies that the Clojure runtime is properly installed
# and configured for the Claude Code environment.
#
# Usage:
#   bash verify-clojure-setup.sh
#   PROXY_PORT=9999 bash verify-clojure-setup.sh

# Configuration
PROXY_PORT="${PROXY_PORT:-8888}"
PROXY_LOG="/tmp/proxy.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Counters
PASSED=0
FAILED=0
WARNINGS=0

echo "============================================================"
echo "Clojure Setup Verification Script"
echo "============================================================"
echo ""
echo "Configuration:"
echo "  Expected proxy port: $PROXY_PORT"
echo "  Script directory: $SCRIPT_DIR"
echo ""
echo "============================================================"
echo ""

# Helper functions
pass() {
    echo "[PASS] $1"
    ((PASSED++))
}

fail() {
    echo "[FAIL] $1"
    ((FAILED++))
}

warn() {
    echo "[WARN] $1"
    ((WARNINGS++))
}

info() {
    echo "[INFO] $1"
}

section() {
    echo ""
    echo "------------------------------------------------------------"
    echo "$1"
    echo "------------------------------------------------------------"
}

# ============================================================
# Test 1: Check Clojure CLI Installation
# ============================================================

section "Test 1: Clojure CLI Installation"

if command -v clojure &> /dev/null; then
    pass "Clojure CLI command found"
    VERSION=$(clojure --version 2>&1 | head -n1)
    info "Version: $VERSION"
else
    fail "Clojure CLI command not found"
fi

if command -v clj &> /dev/null; then
    pass "clj command found"
else
    fail "clj command not found"
fi

# Check installation path
if [ -f "/usr/local/bin/clojure" ]; then
    pass "Clojure binary exists at /usr/local/bin/clojure"
else
    fail "Clojure binary not found at /usr/local/bin/clojure"
fi

# ============================================================
# Test 2: Proxy Wrapper Process
# ============================================================

section "Test 2: Proxy Wrapper Process"

if pgrep -f "proxy-wrapper.py.*$PROXY_PORT" > /dev/null; then
    PROXY_PID=$(pgrep -f "proxy-wrapper.py.*$PROXY_PORT")
    pass "Proxy wrapper running on port $PROXY_PORT (PID: $PROXY_PID)"

    # Check if port is actually listening
    if command -v netstat &> /dev/null; then
        if netstat -tuln | grep ":$PROXY_PORT " > /dev/null 2>&1; then
            pass "Port $PROXY_PORT is listening"
        else
            fail "Port $PROXY_PORT is not listening"
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln | grep ":$PROXY_PORT " > /dev/null 2>&1; then
            pass "Port $PROXY_PORT is listening"
        else
            fail "Port $PROXY_PORT is not listening"
        fi
    else
        warn "Cannot verify port status (netstat/ss not available)"
    fi
else
    fail "Proxy wrapper not running on port $PROXY_PORT"

    # Check if running on different port
    if pgrep -f "proxy-wrapper.py" > /dev/null; then
        OTHER_PID=$(pgrep -f "proxy-wrapper.py")
        warn "Proxy wrapper running on different port (PID: $OTHER_PID)"
    fi
fi

# Check proxy log
if [ -f "$PROXY_LOG" ]; then
    pass "Proxy log exists at $PROXY_LOG"
    LOG_SIZE=$(du -h "$PROXY_LOG" | cut -f1)
    info "Log size: $LOG_SIZE"

    # Check for recent activity (modified in last 10 minutes)
    if [ $(find "$PROXY_LOG" -mmin -10 2>/dev/null | wc -l) -gt 0 ]; then
        info "Proxy log recently updated (active)"
    else
        warn "Proxy log not recently updated (may be idle)"
    fi
else
    warn "Proxy log not found at $PROXY_LOG"
fi

# ============================================================
# Test 3: Configuration Files
# ============================================================

section "Test 3: Configuration Files"

# Maven settings.xml
MAVEN_SETTINGS="$HOME/.m2/settings.xml"
if [ -f "$MAVEN_SETTINGS" ]; then
    pass "Maven settings.xml exists"

    # Verify it contains the correct port
    if grep -q "<port>$PROXY_PORT</port>" "$MAVEN_SETTINGS"; then
        pass "Maven settings.xml configured with port $PROXY_PORT"
    else
        fail "Maven settings.xml does not contain port $PROXY_PORT"
    fi

    # Verify proxy configuration
    if grep -q "<host>127.0.0.1</host>" "$MAVEN_SETTINGS"; then
        pass "Maven settings.xml has localhost proxy"
    else
        fail "Maven settings.xml missing localhost proxy configuration"
    fi
else
    fail "Maven settings.xml not found at $MAVEN_SETTINGS"
fi

# Gradle properties
GRADLE_PROPS="$HOME/.gradle/gradle.properties"
if [ -f "$GRADLE_PROPS" ]; then
    pass "Gradle properties file exists"

    # Verify it contains the correct port
    if grep -q "proxyPort=$PROXY_PORT" "$GRADLE_PROPS"; then
        pass "Gradle configured with port $PROXY_PORT"
    else
        fail "Gradle properties does not contain port $PROXY_PORT"
    fi

    # Verify proxy host
    if grep -q "proxyHost=127.0.0.1" "$GRADLE_PROPS"; then
        pass "Gradle configured with localhost proxy"
    else
        fail "Gradle properties missing localhost proxy configuration"
    fi
else
    warn "Gradle properties not found at $GRADLE_PROPS (optional)"
fi

# ============================================================
# Test 4: Environment Variables
# ============================================================

section "Test 4: Environment Variables"

# Check http_proxy
if [ -n "$http_proxy" ] || [ -n "$HTTP_PROXY" ]; then
    pass "http_proxy environment variable is set"
    info "http_proxy: ${http_proxy:-$HTTP_PROXY}"
else
    warn "http_proxy environment variable not set"
fi

# Check JAVA_TOOL_OPTIONS
if [ -n "$JAVA_TOOL_OPTIONS" ]; then
    pass "JAVA_TOOL_OPTIONS is set"

    # Verify it contains correct proxy settings
    if echo "$JAVA_TOOL_OPTIONS" | grep -q "proxyPort=$PROXY_PORT"; then
        pass "JAVA_TOOL_OPTIONS contains port $PROXY_PORT"
    else
        fail "JAVA_TOOL_OPTIONS does not contain port $PROXY_PORT"
    fi

    if echo "$JAVA_TOOL_OPTIONS" | grep -q "proxyHost=127.0.0.1"; then
        pass "JAVA_TOOL_OPTIONS contains localhost proxy"
    else
        fail "JAVA_TOOL_OPTIONS missing localhost proxy"
    fi
else
    warn "JAVA_TOOL_OPTIONS not set (will be set when sourcing setup-clojure.sh)"
    info "Maven settings.xml will handle proxy for Clojure CLI"
fi

# ============================================================
# Test 5: Dependency Resolution (Quick Test)
# ============================================================

section "Test 5: Dependency Resolution Test"

# Create a temporary test project
TEST_DIR=$(mktemp -d)
info "Creating temporary test project in $TEST_DIR"

cat > "$TEST_DIR/deps.edn" <<'EOF'
{:deps {org.clojure/clojure {:mvn/version "1.11.1"}}}
EOF

echo "Testing Maven Central dependency resolution..."
if timeout 60 clojure -Sdeps '{:deps {org.clojure/data.json {:mvn/version "2.4.0"}}}' -e '(println "Dependency test passed")' > /dev/null 2>&1; then
    pass "Maven Central dependency resolution works"
else
    fail "Maven Central dependency resolution failed"
fi

echo "Testing Clojars dependency resolution..."
if timeout 60 clojure -Sdeps '{:deps {cheshire/cheshire {:mvn/version "5.11.0"}}}' -e '(println "Dependency test passed")' > /dev/null 2>&1; then
    pass "Clojars dependency resolution works"
else
    fail "Clojars dependency resolution failed"
fi

# Cleanup
rm -rf "$TEST_DIR"

# ============================================================
# Test 6: Code Execution Test
# ============================================================

section "Test 6: Clojure Code Execution Test"

echo "Testing basic Clojure code execution..."
OUTPUT=$(clojure -e '(+ 1 2 3)' 2>&1 | tail -n1)
if [ "$OUTPUT" = "6" ]; then
    pass "Basic Clojure code execution works"
else
    fail "Basic Clojure code execution failed (expected 6, got: $OUTPUT)"
fi

echo "Testing Clojure standard library..."
OUTPUT=$(clojure -e '(require (quote [clojure.string :as str])) (str/upper-case "hello")' 2>&1 | tail -n1)
if [ "$OUTPUT" = "\"HELLO\"" ]; then
    pass "Clojure standard library works"
else
    fail "Clojure standard library test failed (got: $OUTPUT)"
fi

# ============================================================
# Test 7: Test Project Verification
# ============================================================

section "Test 7: Test Project Verification"

if [ -d "$SCRIPT_DIR/test-clojure-deps" ]; then
    pass "Test project directory exists"

    if [ -f "$SCRIPT_DIR/test-clojure-deps/deps.edn" ]; then
        pass "Test project deps.edn exists"
    else
        fail "Test project deps.edn not found"
    fi

    if [ -f "$SCRIPT_DIR/test-clojure-deps/src/hello/core.clj" ]; then
        pass "Test project source file exists"

        echo "Running test project..."
        cd "$SCRIPT_DIR/test-clojure-deps"
        if timeout 120 clojure -M:run > /dev/null 2>&1; then
            pass "Test project executes successfully"
        else
            fail "Test project execution failed"
        fi
        cd "$SCRIPT_DIR"
    else
        fail "Test project source file not found"
    fi
else
    warn "Test project directory not found (optional)"
fi

# ============================================================
# Summary
# ============================================================

echo ""
echo "============================================================"
echo "Verification Summary"
echo "============================================================"
echo ""
echo "Passed:   $PASSED"
echo "Failed:   $FAILED"
echo "Warnings: $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "[PASS] All critical tests passed!"
    echo ""
    echo "Your Clojure runtime is properly configured and working."
    echo ""
    exit 0
else
    echo "[FAIL] Some tests failed!"
    echo ""
    echo "Please run setup-clojure.sh to fix issues:"
    echo "  source setup-clojure.sh"
    echo ""
    exit 1
fi
