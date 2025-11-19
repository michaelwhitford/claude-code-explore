# Verification Tools

Scripts to confirm Clojure runtime setup is working correctly.

## Files

### verify-setup.sh

Quick comprehensive check of setup status.

**Usage:**
```bash
./verify-setup.sh
```

**What it checks:**
- Clojure CLI installed
- Proxy wrapper process running on correct port
- Configuration files created correctly
- Environment variables set properly
- Can download from Maven Central
- Can download from Clojars
- Code execution works

**Output:**
```
[PASS] Clojure CLI command found
[PASS] Proxy wrapper running on port 8888
[PASS] Maven Central dependency resolution works
...
[PASS] All critical tests passed!
```

**Exit codes:**
- `0` - All tests passed
- `1` - Some tests failed

### test-idempotency.sh

Comprehensive test of setup script robustness.

**Usage:**
```bash
./test-idempotency.sh
```

**What it tests:**
- Running setup multiple times produces consistent results
- No duplicate processes or configurations
- Recovers from broken states (killed proxy, deleted configs)
- Handles port changes correctly
- Safe under rapid/concurrent execution

**When to use:**
- Verifying setup script quality
- Debugging complex issues
- Understanding edge cases
- Contributing improvements

## Quick Reference

### After Initial Setup

```bash
# Verify everything works
./verify-setup.sh

# Expected output:
# Passed: 15
# Failed: 0
# [PASS] All critical tests passed!
```

### Troubleshooting a Problem

```bash
# Run verification to see what's broken
./verify-setup.sh

# Check specific failures
# Example output:
# [FAIL] Maven Central dependency resolution failed
# → Now you know what to fix
```

### Testing Setup Quality

```bash
# Run comprehensive idempotency tests
./test-idempotency.sh

# This runs setup 5+ times and verifies:
# - Exactly one proxy process
# - Configurations stable
# - Recovers from failures
```

## For AI Agents

### Standard Workflow

```bash
# After running setup, verify it worked:
../setup/setup-clojure.sh
./verify-setup.sh

# Check exit code
if [ $? -eq 0 ]; then
    echo "Setup verified successfully"
else
    echo "Verification failed - see output for details"
fi
```

### Parsing Verification Output

```bash
# Count passes and failures
./verify-setup.sh | grep -c "^\[PASS\]"
./verify-setup.sh | grep -c "^\[FAIL\]"

# Check for specific tests
./verify-setup.sh | grep "Maven Central"
./verify-setup.sh | grep "Clojars"
```

### Automated Testing

```bash
#!/bin/bash
# Example automated workflow

set -e

# Setup
source ../setup/setup-clojure.sh

# Verify
if ./verify-setup.sh; then
    echo "Setup successful and verified"
else
    echo "Verification failed"

    # Diagnose
    ../runtime/inspect-runtime.sh --verbose
    tail -50 /tmp/proxy.log

    exit 1
fi

# Proceed with your build
cd ../examples/greenfield/simple-app
clojure -M:run
```

## Understanding Test Output

### verify-setup.sh Output

```
[PASS] - Test passed ✓
[FAIL] - Test failed ✗
[WARN] - Warning (not critical)
[INFO] - Informational message
```

**Summary section:**
```
Passed:   15   ← Number of successful tests
Failed:   0    ← Number of failed tests
Warnings: 2    ← Number of warnings
```

### test-idempotency.sh Output

Tests are grouped by category:
- **Test 1:** Multiple sequential runs
- **Test 2:** Duplicate entry detection
- **Test 3:** Port binding stability
- **Test 4:** Recovery from broken state
- **Test 5:** Config file recreation
- **Test 6:** Environment variable consistency
- **Test 7:** Port change handling
- **Test 8:** Concurrent execution safety

## Troubleshooting

If verification fails:

```bash
# 1. Check what failed
./verify-setup.sh > verify-output.txt
grep FAIL verify-output.txt

# 2. Get more details
../runtime/inspect-runtime.sh --verbose

# 3. Check proxy logs
tail -50 /tmp/proxy.log

# 4. Re-run setup
source ../setup/setup-clojure.sh

# 5. Verify again
./verify-setup.sh
```

## See Also

- Setup guide: `../setup/README.md`
- Troubleshooting: `../docs/TROUBLESHOOTING.md`
- AI Agent Guide: `../docs/AI-AGENT-GUIDE.md`
