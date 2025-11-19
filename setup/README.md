# Setup Scripts

Core components for installing and configuring Clojure in Claude Code runtime.

## Files

### setup-clojure.sh

Main setup script - idempotent and safe to run multiple times.

**Usage:**
```bash
# Standard setup
source ./setup-clojure.sh

# Custom proxy port
PROXY_PORT=9999 source ./setup-clojure.sh
```

**What it does:**
1. Installs Clojure CLI (if not present)
2. Starts proxy wrapper on localhost
3. Configures Maven settings (`~/.m2/settings.xml`)
4. Configures Gradle properties (`~/.gradle/gradle.properties`)
5. Exports Java proxy settings (`JAVA_TOOL_OPTIONS`)

**Important:** Must use `source`, not `bash`, to export environment variables.

### proxy-wrapper.py

Python HTTP/HTTPS proxy that adds authentication headers.

**Usage:**
```bash
# Usually started automatically by setup-clojure.sh
# Can run manually for testing:
python3 proxy-wrapper.py 8888
```

**What it does:**
- Listens on localhost (default port 8888)
- Reads upstream proxy from `http_proxy` environment variable
- Adds `Proxy-Authorization` header automatically
- Tunnels traffic bidirectionally

**Logs:** `/tmp/proxy.log`

## Quick Reference

### First Time Setup

```bash
source ./setup-clojure.sh
```

### Verify It Worked

```bash
../verification/verify-setup.sh
```

### Check Proxy Status

```bash
# Is it running?
pgrep -f proxy-wrapper.py

# View logs
tail -f /tmp/proxy.log

# Restart if needed
pkill -f proxy-wrapper.py
source ./setup-clojure.sh
```

### Change Proxy Port

```bash
PROXY_PORT=8889 source ./setup-clojure.sh
```

## For AI Agents

### Standard Workflow

```bash
# 1. Run setup
source ./setup-clojure.sh

# 2. Verify success
if [ $? -eq 0 ]; then
    echo "Setup successful"
else
    echo "Setup failed, check logs"
fi

# 3. Confirm proxy running
pgrep -f proxy-wrapper.py || echo "Proxy not running!"
```

### Error Handling

If setup fails:
1. Check runtime compatibility: `../runtime/inspect-runtime.sh`
2. Check logs: `tail /tmp/proxy.log`
3. Try different port: `PROXY_PORT=8889 source ./setup-clojure.sh`

### Configuration Files Created

After setup, these files will exist:
- `~/.m2/settings.xml` - Maven/Clojure CLI proxy config
- `~/.gradle/gradle.properties` - Gradle proxy config
- `/tmp/proxy.log` - Proxy activity log

## Troubleshooting

See `../docs/TROUBLESHOOTING.md` for detailed help.

**Common issues:**
- Port already in use → Use `PROXY_PORT=8889`
- Proxy won't start → Check `http_proxy` environment variable
- Downloads fail → Check `/tmp/proxy.log`

## See Also

- AI Agent Guide: `../docs/AI-AGENT-GUIDE.md`
- Architecture: `../docs/ARCHITECTURE.md`
- Verification: `../verification/README.md`
