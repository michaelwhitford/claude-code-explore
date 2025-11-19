# AI Agent Guide: Setting Up Clojure in Claude Code Runtime

This guide is specifically designed for AI agents (like Claude) that need to set up Clojure in the Claude Code runtime environment.

## Quick Start (Copy These Commands)

```bash
# Step 1: Understand your runtime
./runtime/inspect-runtime.sh

# Step 2: Run setup
source ./setup/setup-clojure.sh

# Step 3: Verify it works
./verification/verify-setup.sh

# Step 4: Test with example
cd examples/greenfield/simple-app
clojure -M:run
```

## Understanding This Repository

### What Problem Does This Solve?

Claude Code runtime uses an authenticated HTTP proxy. Java applications cannot send authentication headers during HTTPS CONNECT requests (a Java limitation). This repository provides:

1. **Proxy wrapper** (`setup/proxy-wrapper.py`) - Adds authentication transparently
2. **Setup script** (`setup/setup-clojure.sh`) - Configures everything automatically
3. **Verification tools** (`verification/`) - Confirms setup works correctly

### Architecture Overview

```
Your Clojure app → localhost:8888 (proxy wrapper) → Claude Code Proxy → Internet
                       ↑
                  Adds auth headers automatically
```

## Decision Tree for AI Agents

### Scenario 1: Greenfield Project (No Existing Code)

You're starting a new Clojure project from scratch.

**Actions:**
1. Run setup: `source ./setup/setup-clojure.sh`
2. Follow example: `examples/greenfield/README.md`
3. Create your `deps.edn` based on the example

**Expected outcome:** Working Clojure environment ready for development

### Scenario 2: Existing deps.edn Project

User has existing Clojure project with `deps.edn` in their repository.

**Actions:**
1. Run setup: `source ./setup/setup-clojure.sh`
2. Reference example: `examples/existing-project/deps-edn-example/`
3. Test their project: `clojure -M:run` (or their specific command)

**Expected outcome:** Their existing project can download dependencies and run

### Scenario 3: Existing Gradle Project

User has Gradle build with Clojure dependencies.

**Actions:**
1. Run setup: `source ./setup/setup-clojure.sh` (configures Gradle too!)
2. Reference example: `examples/existing-project/gradle-example/`
3. Test their build: `./gradlew build`

**Expected outcome:** Gradle can download Clojure dependencies through proxy

## Step-by-Step Setup Process

### Step 0: Inspect Runtime (RECOMMENDED)

Before making any changes, understand your environment:

```bash
./runtime/inspect-runtime.sh
```

This tells you:
- What's already installed
- What will be installed
- Any potential issues
- If you're ready to proceed

**For automated workflows, use JSON output:**
```bash
./runtime/inspect-runtime.sh --json > runtime-info.json
```

Parse the JSON to check `ready_for_setup`:
```bash
cat runtime-info.json | grep -o '"ready_for_setup": [^,]*'
```

### Step 1: Run Setup

The setup script is **idempotent** - safe to run multiple times:

```bash
source ./setup/setup-clojure.sh
```

**What this does:**
1. Installs Clojure CLI if not present
2. Starts proxy wrapper on localhost:8888
3. Configures Maven settings (`~/.m2/settings.xml`)
4. Configures Gradle properties (`~/.gradle/gradle.properties`)
5. Sets Java system properties via `JAVA_TOOL_OPTIONS`

**Note:** Use `source` (not `bash`) to export environment variables to your current shell.

**Custom port (if 8888 is taken):**
```bash
PROXY_PORT=9999 source ./setup/setup-clojure.sh
```

### Step 2: Verify Setup

Confirm everything works:

```bash
./verification/verify-setup.sh
```

**What this checks:**
- Clojure CLI installed and executable
- Proxy wrapper running on correct port
- Configuration files created correctly
- Environment variables set properly
- Can download dependencies from Maven Central
- Can download dependencies from Clojars
- Code execution works

**Expected output:**
```
[PASS] All critical tests passed!
Your Clojure runtime is properly configured and working.
```

**If verification fails:**
```bash
# Get detailed diagnostics
./runtime/inspect-runtime.sh --verbose

# Check proxy logs
tail -f /tmp/proxy.log

# Re-run setup
source ./setup/setup-clojure.sh
```

### Step 3: Test with Example

Verify end-to-end functionality:

```bash
cd examples/greenfield/simple-app
clojure -M:run
```

**Expected output:**
```
Dependencies downloaded...
Hello from Clojure!
Dependencies resolved from Maven Central and Clojars.
```

## Verification Checklist

After setup, all of these should be true:

- [ ] `which clojure` returns a path (e.g., `/usr/local/bin/clojure`)
- [ ] `pgrep -f proxy-wrapper.py` shows a running process
- [ ] `cat ~/.m2/settings.xml` shows proxy configuration
- [ ] `echo $JAVA_TOOL_OPTIONS` shows proxy settings
- [ ] `clojure -e '(+ 1 2 3)'` outputs `6`
- [ ] Can download dependency: `clojure -Sdeps '{:deps {org.clojure/data.json {:mvn/version "2.4.0"}}}'`

## Common Issues and Solutions

### Issue: "No http_proxy environment variable"

**Cause:** Proxy wrapper needs upstream proxy configuration

**Solution:** This is usually just a warning. The setup continues and Maven/Gradle configs will work. If you do have a proxy, set it:
```bash
export http_proxy="http://user:pass@proxy.example.com:8080"
source ./setup/setup-clojure.sh
```

### Issue: "Port 8888 already in use"

**Cause:** Another service using the default port

**Solution:** Use a different port:
```bash
PROXY_PORT=8889 source ./setup/setup-clojure.sh
```

### Issue: "Cannot download dependencies"

**Cause:** Proxy not working or network issues

**Diagnosis:**
```bash
# Check proxy is running
pgrep -f proxy-wrapper.py

# Check proxy logs
tail -f /tmp/proxy.log

# Test connectivity
./runtime/inspect-runtime.sh
```

**Solution:**
```bash
# Restart setup
source ./setup/setup-clojure.sh

# If still failing, check network access to Maven/Clojars
curl -v https://repo1.maven.org/maven2/
```

### Issue: "JAVA_TOOL_OPTIONS not set"

**Cause:** Setup script not sourced (ran with `bash` instead of `source`)

**Solution:**
```bash
source ./setup/setup-clojure.sh  # Note: source, not bash!
```

### Issue: Verification fails after setup

**Diagnosis workflow:**
```bash
# 1. Check what's failing
./verification/verify-setup.sh

# 2. Get detailed runtime info
./runtime/inspect-runtime.sh --verbose

# 3. Check proxy process
ps aux | grep proxy-wrapper.py

# 4. Check proxy logs
tail -50 /tmp/proxy.log

# 5. Verify config files
cat ~/.m2/settings.xml
cat ~/.gradle/gradle.properties
```

**Solution:** Re-run setup (it's idempotent):
```bash
source ./setup/setup-clojure.sh
./verification/verify-setup.sh
```

## Advanced: Comprehensive Testing

To thoroughly test idempotency and edge cases:

```bash
./verification/test-idempotency.sh
```

**What this tests:**
- Running setup multiple times produces same result
- No duplicate processes or configurations
- Recovers from broken states (killed proxy, deleted configs)
- Handles port changes correctly
- Safe under rapid/concurrent execution

This is useful for:
- Verifying setup script quality
- Understanding edge cases
- Debugging complex issues

## Adapting for Your Project

### If you need to customize the setup:

1. **Copy the scripts** to your project
2. **Modify** `setup/setup-clojure.sh` for your needs:
   - Different proxy port
   - Additional configuration
   - Project-specific setup steps
3. **Keep verification** to ensure it still works

### Adding to existing project workflow:

```bash
# In your project's setup script or documentation:

# 1. Clone reference repo
git clone https://github.com/yourusername/claude-code-clojure.git

# 2. Run setup
source claude-code-clojure/setup/setup-clojure.sh

# 3. Continue with your project-specific setup
# ...
```

### For CI/CD or automation:

```bash
#!/bin/bash
# Automated Clojure setup for CI

set -e

# Check runtime first
./runtime/inspect-runtime.sh --json > runtime.json

# Parse readiness
if grep -q '"ready_for_setup": true' runtime.json; then
    echo "Runtime ready, proceeding with setup..."
    source ./setup/setup-clojure.sh
    ./verification/verify-setup.sh
else
    echo "Runtime not ready, check runtime.json for details"
    exit 1
fi

# Continue with your build
clj -M:test
```

## Understanding the Components

### setup/setup-clojure.sh
- **Idempotent:** Run multiple times safely
- **Auto-detects:** Reads proxy from environment
- **Configurable:** Set `PROXY_PORT` to customize
- **Comprehensive:** Handles Clojure CLI, Maven, Gradle

### setup/proxy-wrapper.py
- **Transparent:** Adds auth without app changes
- **Automatic:** Reads upstream proxy from `http_proxy`
- **Bidirectional:** Tunnels data after CONNECT
- **Logged:** Activity logged to `/tmp/proxy.log`

### verification/verify-setup.sh
- **Quick check:** Confirms setup successful
- **Comprehensive:** Tests all components
- **Helpful output:** Clear pass/fail with guidance

### verification/test-idempotency.sh
- **Quality assurance:** Proves setup is robust
- **Edge cases:** Tests recovery and concurrent execution
- **Documentation:** Shows what "correct" looks like

## For AI Agents: Exploration Strategy

When encountering this repository:

1. **Start with README.md** - Get overview
2. **Read this guide** - Understand how to use it
3. **Inspect runtime** - `./runtime/inspect-runtime.sh`
4. **Check examples** - Match to user's scenario
5. **Run setup** - `source ./setup/setup-clojure.sh`
6. **Verify** - `./verification/verify-setup.sh`
7. **Adapt** - Apply to user's specific project

## Exit Codes for Automation

All scripts follow consistent exit code conventions:

- `0` - Success, everything works
- `1` - Warnings present but can proceed
- `2` - Blockers found, cannot proceed

**Example automated workflow:**
```bash
./runtime/inspect-runtime.sh
RESULT=$?

if [ $RESULT -eq 0 ]; then
    echo "Runtime ready"
    source ./setup/setup-clojure.sh
elif [ $RESULT -eq 1 ]; then
    echo "Warnings present, proceeding anyway"
    source ./setup/setup-clojure.sh
else
    echo "Blockers found, cannot proceed"
    exit 1
fi
```

## Summary

**For AI agents, the workflow is:**

1. Clone/explore this repository
2. Inspect runtime: `./runtime/inspect-runtime.sh`
3. Run setup: `source ./setup/setup-clojure.sh`
4. Verify: `./verification/verify-setup.sh`
5. Choose example matching user's scenario
6. Apply to user's project

**Key principles:**
- Setup is idempotent (safe to repeat)
- Everything is verified (tests prove it works)
- Failures are debuggable (logs and diagnostics)
- Examples show the way (copy and adapt)

**When in doubt:**
- Re-run `./runtime/inspect-runtime.sh` to diagnose
- Re-run `source ./setup/setup-clojure.sh` to fix
- Check `/tmp/proxy.log` for proxy issues
- Consult `docs/TROUBLESHOOTING.md` for common issues
