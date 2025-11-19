# Troubleshooting Guide

This guide helps AI agents and users diagnose and fix common issues with the Clojure runtime setup.

## Quick Diagnostic Commands

When something goes wrong, run these first:

```bash
# 1. Check runtime status
./runtime/inspect-runtime.sh

# 2. Verify setup
./verification/verify-setup.sh

# 3. Check proxy logs
tail -50 /tmp/proxy.log

# 4. Check proxy process
ps aux | grep proxy-wrapper.py

# 5. Test basic Clojure
clojure -e '(+ 1 2 3)'
```

## Common Issues

### Issue 1: "clojure: command not found"

**Symptom:**
```bash
$ clojure -e '(+ 1 2 3)'
bash: clojure: command not found
```

**Cause:** Clojure CLI not installed or not in PATH

**Diagnosis:**
```bash
which clojure
ls -la /usr/local/bin/clojure
```

**Solution:**
```bash
source ./setup/setup-clojure.sh
```

**If still failing:**
```bash
# Check if installer exists
ls -la installers/

# Run installer manually
bash installers/linux-install-1.11.1.1435.sh
```

---

### Issue 2: "Could not transfer artifact"

**Symptom:**
```
Could not transfer artifact org.clojure:clojure:jar:1.11.1
from/to central (https://repo1.maven.org/maven2/):
Connection refused
```

**Cause:** Proxy not configured or not running

**Diagnosis:**
```bash
# Check proxy is running
pgrep -f proxy-wrapper.py

# Check Maven settings
cat ~/.m2/settings.xml | grep -A3 "<proxy>"

# Check port matches
pgrep -f "proxy-wrapper.py.*8888"
grep "<port>" ~/.m2/settings.xml
```

**Solution:**
```bash
# Re-run setup
source ./setup/setup-clojure.sh

# Verify proxy started
pgrep -f proxy-wrapper.py || echo "Proxy not running!"

# Check logs
tail -20 /tmp/proxy.log
```

**If proxy won't start:**
```bash
# Check if port is already taken
netstat -tuln | grep 8888
# or
ss -tuln | grep 8888

# If taken, use different port
PROXY_PORT=8889 source ./setup/setup-clojure.sh
```

---

### Issue 3: "407 Proxy Authentication Required"

**Symptom:**
```
Error: 407 Proxy Authentication Required
```

**Cause:** Upstream proxy credentials missing or incorrect

**Diagnosis:**
```bash
# Check if http_proxy is set
echo $http_proxy

# Check proxy logs for auth errors
tail -50 /tmp/proxy.log | grep 407
```

**Solution:**

If `http_proxy` not set:
```bash
export http_proxy="http://username:password@proxy.example.com:8080"
export https_proxy="$http_proxy"
source ./setup/setup-clojure.sh
```

If credentials are wrong:
```bash
# Update with correct credentials
export http_proxy="http://correct_user:correct_pass@proxy.example.com:8080"

# Restart proxy
pkill -f proxy-wrapper.py
source ./setup/setup-clojure.sh
```

---

### Issue 4: JAVA_TOOL_OPTIONS not set

**Symptom:**
```bash
$ echo $JAVA_TOOL_OPTIONS
# Empty output
```

**Cause:** Setup script not sourced (ran with `bash` instead of `source`)

**Diagnosis:**
```bash
# This is WRONG:
bash ./setup/setup-clojure.sh  # Runs in subshell, doesn't export vars

# This is CORRECT:
source ./setup/setup-clojure.sh  # Runs in current shell, exports vars
```

**Solution:**
```bash
# Use source, not bash
source ./setup/setup-clojure.sh

# Verify it's now set
echo $JAVA_TOOL_OPTIONS
```

---

### Issue 5: Port already in use

**Symptom:**
```
[ERROR] Failed to start proxy wrapper
OSError: [Errno 98] Address already in use
```

**Cause:** Port 8888 already taken by another process

**Diagnosis:**
```bash
# Find what's using the port
netstat -tuln | grep 8888
# or
ss -tuln | grep 8888
lsof -i :8888
```

**Solution:**
```bash
# Use a different port
PROXY_PORT=8889 source ./setup/setup-clojure.sh
```

**Or kill the conflicting process:**
```bash
# Find process on port 8888
lsof -ti:8888

# Kill it (if safe to do so)
kill $(lsof -ti:8888)

# Re-run setup
source ./setup/setup-clojure.sh
```

---

### Issue 6: Proxy runs but downloads still fail

**Symptom:**
- `pgrep -f proxy-wrapper.py` shows process
- Maven settings look correct
- But dependency downloads still fail

**Diagnosis:**
```bash
# Check if proxy is actually listening
netstat -tuln | grep 8888
ss -tuln | grep 8888

# Check proxy logs for activity
tail -f /tmp/proxy.log
# Then in another terminal:
clojure -Sdeps '{:deps {org.clojure/data.json {:mvn/version "2.4.0"}}}'
# Watch for log entries
```

**Possible causes:**

1. **Proxy crashed after starting:**
```bash
# Check if process is really running
ps aux | grep proxy-wrapper.py

# Check for Python errors in log
grep -i error /tmp/proxy.log
grep -i exception /tmp/proxy.log
```

2. **Maven not using the proxy:**
```bash
# Force verbose Maven output
clojure -Sverbose -Sdeps '{:deps {org.clojure/data.json {:mvn/version "2.4.0"}}}'

# Check if it mentions proxy
```

3. **Upstream proxy unreachable:**
```bash
# Test connectivity to upstream proxy
./runtime/inspect-runtime.sh
```

**Solution:**
```bash
# Full reset
pkill -f proxy-wrapper.py
source ./setup/setup-clojure.sh
./verification/verify-setup.sh
```

---

### Issue 7: "No http_proxy environment variable"

**Symptom:**
```
[WARN] No http_proxy environment variable detected
The proxy wrapper requires http_proxy to be set
```

**Cause:** Upstream proxy not configured in environment

**Impact:** Warning only - setup continues, but proxy wrapper may not work correctly

**Solution:**

If you're in Claude Code runtime, this is usually just a warning. The setup will configure Maven/Gradle settings anyway.

If you do have an upstream proxy:
```bash
export http_proxy="http://user:pass@proxy.example.com:8080"
export https_proxy="$http_proxy"
source ./setup/setup-clojure.sh
```

---

### Issue 8: Dependencies download but code fails to run

**Symptom:**
- Dependencies download successfully
- But `clojure -M:run` fails
- Or REPL throws errors

**Diagnosis:**
```bash
# Check if it's a code issue, not setup issue
clojure -e '(println "Basic Clojure works")'

# If that works, the setup is fine
# Problem is in your code or deps.edn
```

**Common code issues:**

1. **Wrong main namespace:**
```clojure
;; deps.edn
{:aliases {:run {:main-opts ["-m" "my-app.core"]}}}

;; But file is src/my_app/core.clj (underscore)
;; Should be: my-app.core → src/my_app/core.clj
```

2. **Missing -main function:**
```clojure
;; Your code needs:
(defn -main [& args]
  (println "Hello!"))
```

3. **Wrong paths:**
```clojure
{:paths ["src"]}  ;; Make sure this matches your directory structure
```

---

### Issue 9: Setup seems to work but verification fails

**Symptom:**
```bash
$ source ./setup/setup-clojure.sh
# Completes without errors

$ ./verification/verify-setup.sh
[FAIL] Some tests failed!
```

**Diagnosis:**
```bash
# Run verification to see what's failing
./verification/verify-setup.sh

# Common failures:
# - [FAIL] Port 8888 is not listening
# - [FAIL] Maven Central dependency resolution failed
# - [FAIL] Clojars dependency resolution failed
```

**Solution based on failure:**

If **port not listening:**
```bash
# Check if proxy actually started
pgrep -f proxy-wrapper.py
cat /tmp/proxy.log

# Restart
pkill -f proxy-wrapper.py
source ./setup/setup-clojure.sh
```

If **dependency resolution failed:**
```bash
# Test network connectivity
./runtime/inspect-runtime.sh

# Check if Maven/Clojars are reachable
curl -I https://repo1.maven.org/maven2/
curl -I https://repo.clojars.org/

# Check proxy logs during download
tail -f /tmp/proxy.log &
clojure -Sdeps '{:deps {org.clojure/data.json {:mvn/version "2.4.0"}}}'
```

---

### Issue 10: Gradle builds fail

**Symptom:**
```bash
$ ./gradlew build
Could not resolve org.clojure:clojure:1.11.1
```

**Cause:** Gradle not configured for proxy

**Diagnosis:**
```bash
# Check Gradle properties
cat ~/.gradle/gradle.properties

# Should contain:
# systemProp.http.proxyHost=127.0.0.1
# systemProp.http.proxyPort=8888
```

**Solution:**
```bash
# Re-run setup (configures Gradle too)
source ./setup/setup-clojure.sh

# Verify Gradle config created
cat ~/.gradle/gradle.properties

# Try build again
./gradlew build --info  # Verbose output
```

---

## Advanced Diagnostics

### Full System Check

```bash
# 1. Runtime inspection
./runtime/inspect-runtime.sh --verbose > runtime-report.txt

# 2. Verify setup
./verification/verify-setup.sh > verify-report.txt

# 3. Test idempotency (comprehensive)
./verification/test-idempotency.sh > idempotency-report.txt

# 4. Collect logs
cat /tmp/proxy.log > proxy-log.txt

# Now you have 4 files with complete diagnostic info
```

### Manual Proxy Test

Test the proxy wrapper directly:

```bash
# Start proxy manually
python3 ./setup/proxy-wrapper.py 8888

# In another terminal, test it
curl -x http://127.0.0.1:8888 http://example.com
curl -x http://127.0.0.1:8888 https://repo1.maven.org/maven2/

# Watch logs
tail -f /tmp/proxy.log
```

### Manual Clojure Dependency Test

```bash
# Minimal test
clojure -Sdeps '{:deps {org.clojure/data.json {:mvn/version "2.4.0"}}}' \
  -e '(require (quote [clojure.data.json :as json])) (json/write-str {:test true})'

# Expected output:
# "{\"test\":true}"

# If this works, setup is correct
```

### Check Maven Settings Manually

```bash
# View Maven settings
cat ~/.m2/settings.xml

# Should look like:
# <proxies>
#   <proxy>
#     <protocol>http</protocol>
#     <host>127.0.0.1</host>
#     <port>8888</port>
#   </proxy>
# </proxies>

# Test Maven directly (if mvn installed)
mvn help:effective-settings
```

## Recovery Procedures

### Full Reset

If everything is broken, reset completely:

```bash
# 1. Kill proxy
pkill -f proxy-wrapper.py

# 2. Remove configs
rm ~/.m2/settings.xml
rm ~/.gradle/gradle.properties

# 3. Unset environment
unset JAVA_TOOL_OPTIONS

# 4. Re-run setup
source ./setup/setup-clojure.sh

# 5. Verify
./verification/verify-setup.sh
```

### Clean Slate (Remove Everything)

To completely remove Clojure runtime:

```bash
# Remove Clojure CLI
sudo rm /usr/local/bin/clojure
sudo rm /usr/local/bin/clj
sudo rm -rf /usr/local/lib/clojure

# Remove Maven cache and config
rm -rf ~/.m2

# Remove Gradle config
rm -rf ~/.gradle

# Kill proxy
pkill -f proxy-wrapper.py
rm /tmp/proxy.log

# Now reinstall from scratch
source ./setup/setup-clojure.sh
```

## Getting Help

### Information to Collect

When reporting issues, collect:

```bash
# 1. Runtime info
./runtime/inspect-runtime.sh --verbose

# 2. Verification results
./verification/verify-setup.sh

# 3. Proxy status
pgrep -f proxy-wrapper.py && echo "Running" || echo "Not running"

# 4. Last 50 proxy log lines
tail -50 /tmp/proxy.log

# 5. Config files
cat ~/.m2/settings.xml
cat ~/.gradle/gradle.properties
echo $JAVA_TOOL_OPTIONS

# 6. System info
uname -a
python3 --version
java -version 2>&1
```

### Self-Service Checklist

Before asking for help, verify:

- [ ] Ran `source ./setup/setup-clojure.sh` (not `bash`)
- [ ] Proxy process is running: `pgrep -f proxy-wrapper.py`
- [ ] Port is listening: `netstat -tuln | grep 8888`
- [ ] Maven settings exist: `ls ~/.m2/settings.xml`
- [ ] JAVA_TOOL_OPTIONS is set: `echo $JAVA_TOOL_OPTIONS`
- [ ] Basic Clojure works: `clojure -e '(+ 1 2 3)'`
- [ ] Checked proxy logs: `tail /tmp/proxy.log`
- [ ] Runtime inspection passes: `./runtime/inspect-runtime.sh`

### For AI Agents

When troubleshooting autonomously:

1. **Gather information first** - Don't make changes until you understand the problem
2. **Check logs** - Most issues show up in `/tmp/proxy.log`
3. **Re-run setup** - It's idempotent, safe to retry
4. **Test incrementally** - Fix one thing, verify, then next
5. **Use verification tools** - They're designed for diagnosis

**Typical debugging flow:**
```bash
# 1. What's broken?
./verification/verify-setup.sh

# 2. Why is it broken?
./runtime/inspect-runtime.sh --verbose
tail -50 /tmp/proxy.log

# 3. Fix it
source ./setup/setup-clojure.sh

# 4. Confirm fix
./verification/verify-setup.sh
```

## Summary

**Most common fixes:**
1. Re-run setup: `source ./setup/setup-clojure.sh`
2. Check proxy is running: `pgrep -f proxy-wrapper.py`
3. Use different port: `PROXY_PORT=8889 source ./setup/setup-clojure.sh`
4. Check logs: `tail -50 /tmp/proxy.log`

**Key insight:** The setup is designed to be idempotent, so "when in doubt, re-run setup" is always a safe first step.
