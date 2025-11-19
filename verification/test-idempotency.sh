#!/bin/bash
# Idempotency Test Script for setup-clojure.sh
#
# This script tests whether setup-clojure.sh is truly idempotent by:
# 1. Running the setup script multiple times
# 2. Verifying no duplicate processes or configurations
# 3. Testing recovery from broken states
#
# Usage:
#   bash test-idempotency.sh

set +e  # Disable errexit to allow test failures without stopping execution

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETUP_SCRIPT="$REPO_ROOT/setup/setup-clojure.sh"
PROXY_PORT="${PROXY_PORT:-8888}"
PROXY_LOG="/tmp/proxy.log"
MAVEN_SETTINGS="$HOME/.m2/settings.xml"
GRADLE_PROPS="$HOME/.gradle/gradle.properties"

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

echo "============================================================"
echo "Idempotency Test for setup-clojure.sh"
echo "============================================================"
echo ""
echo "This test will run setup-clojure.sh multiple times and"
echo "verify that it produces consistent, correct results."
echo ""
echo "============================================================"
echo ""

pass() {
    echo "[PASS] $1"
    ((TESTS_PASSED++))
}

fail() {
    echo "[FAIL] $1"
    ((TESTS_FAILED++))
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

# Helper function to count proxy processes
count_proxy_processes() {
    pgrep -f "proxy-wrapper.py" | wc -l
}

# Helper function to get Maven settings hash
get_maven_hash() {
    if [ -f "$MAVEN_SETTINGS" ]; then
        md5sum "$MAVEN_SETTINGS" | cut -d' ' -f1
    else
        echo "none"
    fi
}

# Helper function to get Gradle properties hash
get_gradle_hash() {
    if [ -f "$GRADLE_PROPS" ]; then
        md5sum "$GRADLE_PROPS" | cut -d' ' -f1
    else
        echo "none"
    fi
}

# Helper function to check for duplicate entries in Maven settings
check_maven_duplicates() {
    if [ -f "$MAVEN_SETTINGS" ]; then
        local count=$(grep -c "<proxy>" "$MAVEN_SETTINGS" || echo 0)
        echo $count
    else
        echo 0
    fi
}

# Helper function to check for duplicate entries in Gradle properties
check_gradle_duplicates() {
    if [ -f "$GRADLE_PROPS" ]; then
        local count=$(grep -c "proxyHost" "$GRADLE_PROPS" || echo 0)
        echo $count
    else
        echo 0
    fi
}

# ============================================================
# Test 1: Multiple Sequential Runs
# ============================================================

section "Test 1: Running setup-clojure.sh 5 times sequentially"

declare -a proxy_counts
declare -a maven_hashes
declare -a gradle_hashes

for i in {1..5}; do
    echo ""
    info "Run #$i..."

    # Source the setup script (disable errexit temporarily as setup script has set -e)
    (set +e; source "$SETUP_SCRIPT") > /dev/null 2>&1
    set +e  # Ensure errexit is off after sourcing

    # Capture state after this run
    proxy_counts[$i]=$(count_proxy_processes)
    maven_hashes[$i]=$(get_maven_hash)
    gradle_hashes[$i]=$(get_gradle_hash)

    info "  Proxy processes: ${proxy_counts[$i]}"
    info "  Maven hash: ${maven_hashes[$i]}"
    info "  Gradle hash: ${gradle_hashes[$i]}"

    # Small delay between runs
    sleep 1
done

echo ""
section "Test 1 Results: Analyzing consistency"

# Check proxy process count consistency
unique_proxy_counts=$(printf '%s\n' "${proxy_counts[@]}" | sort -u | wc -l)
if [ $unique_proxy_counts -eq 1 ]; then
    pass "Proxy process count consistent across all runs (${proxy_counts[1]} processes)"

    if [ "${proxy_counts[1]}" -eq 1 ]; then
        pass "Exactly one proxy process running (expected)"
    else
        fail "Expected 1 proxy process, found ${proxy_counts[1]}"
    fi
else
    fail "Proxy process count inconsistent: ${proxy_counts[*]}"
fi

# Check Maven hash consistency (runs 2-5 should be identical)
maven_stable=true
for i in {2..5}; do
    if [ "${maven_hashes[$i]}" != "${maven_hashes[2]}" ]; then
        maven_stable=false
    fi
done

if $maven_stable; then
    pass "Maven settings.xml stable across runs 2-5"
else
    fail "Maven settings.xml changed between runs: ${maven_hashes[*]}"
fi

# Check Gradle hash consistency (runs 2-5 should be identical)
gradle_stable=true
for i in {2..5}; do
    if [ "${gradle_hashes[$i]}" != "${gradle_hashes[2]}" ]; then
        gradle_stable=false
    fi
done

if $gradle_stable; then
    pass "Gradle properties stable across runs 2-5"
else
    fail "Gradle properties changed between runs: ${gradle_hashes[*]}"
fi

# ============================================================
# Test 2: Check for Duplicate Entries
# ============================================================

section "Test 2: Checking for duplicate configuration entries"

maven_proxy_count=$(check_maven_duplicates)
if [ $maven_proxy_count -eq 2 ]; then
    pass "Maven settings.xml has correct number of proxy entries (2)"
elif [ $maven_proxy_count -gt 2 ]; then
    fail "Maven settings.xml has duplicate proxy entries ($maven_proxy_count found, expected 2)"
else
    fail "Maven settings.xml has incorrect proxy entries ($maven_proxy_count found, expected 2)"
fi

gradle_proxy_count=$(check_gradle_duplicates)
if [ $gradle_proxy_count -eq 2 ]; then
    pass "Gradle properties has correct number of proxy entries (2)"
elif [ $gradle_proxy_count -gt 2 ]; then
    fail "Gradle properties has duplicate proxy entries ($gradle_proxy_count found, expected 2)"
else
    fail "Gradle properties has incorrect proxy entries ($gradle_proxy_count found, expected 2)"
fi

# ============================================================
# Test 3: Port Binding Test
# ============================================================

section "Test 3: Testing port binding stability"

info "Checking if port $PROXY_PORT is listening..."
if command -v netstat &> /dev/null; then
    if netstat -tuln | grep ":$PROXY_PORT " > /dev/null 2>&1; then
        pass "Port $PROXY_PORT is correctly bound"
    else
        fail "Port $PROXY_PORT is not listening"
    fi
elif command -v ss &> /dev/null; then
    if ss -tuln | grep ":$PROXY_PORT " > /dev/null 2>&1; then
        pass "Port $PROXY_PORT is correctly bound"
    else
        fail "Port $PROXY_PORT is not listening"
    fi
else
    info "Cannot verify port binding (netstat/ss not available)"
fi

# ============================================================
# Test 4: Recovery Test (Self-Healing)
# ============================================================

section "Test 4: Testing recovery from broken state"

info "Simulating broken state by stopping proxy..."
if pgrep -f "proxy-wrapper.py" > /dev/null; then
    pkill -f "proxy-wrapper.py"
    sleep 1
    pass "Stopped proxy process"
fi

info "Running setup script to test recovery..."
source "$SETUP_SCRIPT" > /dev/null 2>&1

if pgrep -f "proxy-wrapper.py.*$PROXY_PORT" > /dev/null; then
    pass "Setup script successfully restarted proxy (recovery works)"
else
    fail "Setup script failed to restart proxy"
fi

# ============================================================
# Test 5: Config File Deletion Recovery
# ============================================================

section "Test 5: Testing config file recovery"

info "Deleting Maven settings.xml..."
if [ -f "$MAVEN_SETTINGS" ]; then
    rm "$MAVEN_SETTINGS"
    pass "Deleted Maven settings.xml"
fi

info "Deleting Gradle properties..."
if [ -f "$GRADLE_PROPS" ]; then
    rm "$GRADLE_PROPS"
    pass "Deleted Gradle properties"
fi

info "Running setup script to recreate configs..."
source "$SETUP_SCRIPT" > /dev/null 2>&1

if [ -f "$MAVEN_SETTINGS" ]; then
    pass "Maven settings.xml recreated"
else
    fail "Maven settings.xml not recreated"
fi

if [ -f "$GRADLE_PROPS" ]; then
    pass "Gradle properties recreated"
else
    fail "Gradle properties not recreated"
fi

# Verify recreated files have correct content
if grep -q "<port>$PROXY_PORT</port>" "$MAVEN_SETTINGS" 2>/dev/null; then
    pass "Recreated Maven settings has correct port"
else
    fail "Recreated Maven settings has incorrect port"
fi

# ============================================================
# Test 6: Environment Variable Persistence
# ============================================================

section "Test 6: Testing environment variable consistency"

# Run setup again
source "$SETUP_SCRIPT" > /dev/null 2>&1

if [ -n "$JAVA_TOOL_OPTIONS" ]; then
    pass "JAVA_TOOL_OPTIONS is set"

    # Count occurrences of proxy settings (should not be duplicated)
    proxy_host_count=$(echo "$JAVA_TOOL_OPTIONS" | grep -o "proxyHost" | wc -l)
    if [ $proxy_host_count -eq 2 ]; then
        pass "JAVA_TOOL_OPTIONS has correct number of proxy entries (2)"
    else
        fail "JAVA_TOOL_OPTIONS has incorrect entries (found $proxy_host_count proxyHost, expected 2)"
    fi
else
    fail "JAVA_TOOL_OPTIONS not set"
fi

# ============================================================
# Test 7: Different Port Configuration
# ============================================================

section "Test 7: Testing port change handling"

info "Running setup with different port (9999)..."
PROXY_PORT=9999 source "$SETUP_SCRIPT" > /dev/null 2>&1

# Check if old proxy on 8888 was stopped
if pgrep -f "proxy-wrapper.py.*8888" > /dev/null; then
    fail "Old proxy on port 8888 still running (should be stopped)"
else
    pass "Old proxy on port 8888 stopped correctly"
fi

# Check if new proxy on 9999 is running
if pgrep -f "proxy-wrapper.py.*9999" > /dev/null; then
    pass "New proxy on port 9999 started correctly"
else
    fail "New proxy on port 9999 not started"
fi

# Verify configs updated
if grep -q "<port>9999</port>" "$MAVEN_SETTINGS"; then
    pass "Maven settings.xml updated to port 9999"
else
    fail "Maven settings.xml not updated to port 9999"
fi

# Restore original port
info "Restoring original port ($PROXY_PORT)..."
PROXY_PORT=8888 source "$SETUP_SCRIPT" > /dev/null 2>&1

# ============================================================
# Test 8: Concurrent Execution Safety
# ============================================================

section "Test 8: Testing safety under rapid execution"

info "Running setup script 3 times rapidly..."
for i in {1..3}; do
    (source "$SETUP_SCRIPT") > /dev/null 2>&1
    sleep 0.5
done

sleep 2

# Check proxy process count
final_count=$(count_proxy_processes)
if [ $final_count -eq 1 ]; then
    pass "Only one proxy process running after concurrent executions"
else
    fail "Multiple proxy processes running after concurrent executions ($final_count found)"
fi

# ============================================================
# Summary
# ============================================================

echo ""
echo "============================================================"
echo "Idempotency Test Summary"
echo "============================================================"
echo ""
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "[PASS] All idempotency tests passed!"
    echo ""
    echo "The setup-clojure.sh script is truly idempotent:"
    echo "  - Safe to run multiple times"
    echo "  - No duplicate processes or configurations"
    echo "  - Automatically recovers from broken states"
    echo "  - Handles port changes correctly"
    echo ""
    exit 0
else
    echo "[FAIL] Some idempotency tests failed!"
    echo ""
    echo "The setup script may not be fully idempotent."
    echo "Review the failures above for details."
    echo ""
    exit 1
fi
