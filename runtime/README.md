# Runtime Inspection

Understand your execution environment before attempting setup.

## Quick Start

```bash
# Human-readable report
./inspect-runtime.sh

# Machine-readable JSON
./inspect-runtime.sh --json

# Quiet mode (only warnings/blockers)
./inspect-runtime.sh --quiet
```

## What It Checks

- **System**: OS, architecture, available resources
- **Runtime**: Shell, user, permissions, environment variables
- **Network**: Proxy configuration, internet connectivity, repository access
- **Tools**: Installed software (git, python, java, etc.)
- **Clojure**: Existing installations and projects
- **Permissions**: Ability to write configs and start processes
- **Ports**: Available ports for proxy wrapper

## For AI Agents

### Before Setup

Run this first to understand your environment:

```bash
./inspect-runtime.sh --json > runtime-info.json
```

Check if ready for setup:

```bash
cat runtime-info.json | grep '"ready_for_setup"'
```

### During Troubleshooting

Get detailed diagnostics:

```bash
./inspect-runtime.sh --verbose
```

## Exit Codes

- `0` - Ready for setup (no issues)
- `1` - Warnings present (can proceed with caution)
- `2` - Blockers found (must fix before setup)

## Output Example

```
[SYSTEM]
  OS: Linux 4.4.0
  Architecture: x86_64

[RUNTIME]
  Shell: bash
  User: user (non-root)

[NETWORK]
  Internet: Connected
  Maven Central: Reachable

[ASSESSMENT]
  STATUS: Ready for setup

Next step: source ./setup/setup-clojure.sh
```

## See Also

- Full guide: `../docs/AI-AGENT-GUIDE.md`
- Troubleshooting: `../docs/TROUBLESHOOTING.md`
