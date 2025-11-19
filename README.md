# Clojure Runtime for Claude Code

**A reference implementation for AI agents to set up Clojure in Claude Code runtime environment.**

This repository provides everything needed to install and configure Clojure in Claude Code's authenticated proxy environment. It's designed as a reference for AI agents and developers who need to solve the Java proxy authentication problem.

## For AI Agents: Quick Start

```bash
# Step 1: Understand your runtime
./runtime/inspect-runtime.sh

# Step 2: Run setup
source ./setup/setup-clojure.sh

# Step 3: Verify it works
./verification/verify-setup.sh

# Step 4: Test with example
cd examples/greenfield/simple-app && clj -M:run
```

**Read the complete guide:** [`docs/AI-AGENT-GUIDE.md`](docs/AI-AGENT-GUIDE.md)

## The Problem We Solve

Claude Code runtime uses an authenticated HTTP proxy. **Java applications cannot send authentication headers during HTTPS CONNECT requests** (a fundamental Java limitation). This prevents:

- Clojure CLI from downloading dependencies
- Maven/Gradle from accessing repositories
- Any JVM application from working through authenticated proxies

## The Solution

A local HTTP proxy wrapper that transparently adds authentication:

```
Clojure/Java → localhost:8888 → [adds auth] → Claude Code Proxy → Internet
```

**Technical details:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

## Repository Structure

```
claude-code-clojure/
├── runtime/              # Inspect your execution environment
│   ├── inspect-runtime.sh          # Understand runtime before setup
│   └── README.md
├── setup/                # Core installation scripts
│   ├── setup-clojure.sh            # Main idempotent setup script
│   ├── proxy-wrapper.py            # HTTP proxy with auth
│   └── README.md
├── verification/         # Confirm setup works correctly
│   ├── verify-setup.sh             # Quick comprehensive check
│   ├── test-idempotency.sh         # Thorough quality tests
│   └── README.md
├── examples/             # Reference implementations
│   ├── greenfield/                 # Starting from scratch
│   │   ├── simple-app/             # Minimal deps.edn project
│   │   └── README.md
│   └── existing-project/           # Integration examples
│       ├── deps-edn-example/       # Clojure CLI project
│       ├── gradle-example/         # Gradle build
│       └── README.md
├── docs/                 # Comprehensive documentation
│   ├── AI-AGENT-GUIDE.md           # Step-by-step for AI agents
│   ├── ARCHITECTURE.md             # Technical design & decisions
│   └── TROUBLESHOOTING.md          # Common issues & solutions
└── installers/           # Bundled installers
    └── linux-install-1.11.1.1435.sh    # Clojure CLI v1.11.1.1435
```

## How It Works

### 1. Runtime Inspection

Understand your environment before making changes:

```bash
./runtime/inspect-runtime.sh
```

**Output:**
- System information (OS, architecture, resources)
- Runtime environment (shell, user, permissions)
- Network configuration (proxy settings, connectivity)
- Installed tools (git, python, java)
- Clojure ecosystem status
- Assessment of readiness for setup

### 2. Automated Setup

One command configures everything:

```bash
source ./setup/setup-clojure.sh
```

**What it does:**
1. Installs Clojure CLI (if not present)
2. Starts local proxy wrapper on localhost:8888
3. Configures Maven settings (`~/.m2/settings.xml`)
4. Configures Gradle properties (`~/.gradle/gradle.properties`)
5. Sets Java system properties (`JAVA_TOOL_OPTIONS`)

**Note:** Idempotent - safe to run multiple times.

### 3. Verification

Confirm everything works:

```bash
./verification/verify-setup.sh
```

Tests all components:
- Clojure CLI installation
- Proxy wrapper process
- Configuration files
- Dependency resolution from Maven Central and Clojars
- Code execution

### 4. Examples

Working examples for different scenarios:

**Greenfield (new project):**
```bash
cd examples/greenfield/simple-app
clj -M:run
```

**Existing deps.edn project:**
```bash
cd examples/existing-project/deps-edn-example
clj -M:run
```

**Gradle build:**
```bash
cd examples/existing-project/gradle-example
gradle testDependencies
```

## Use Cases

### For AI Agents

**Scenario 1: User asks "Set up Clojure"**
1. Clone this repository
2. Run `./runtime/inspect-runtime.sh`
3. Run `source ./setup/setup-clojure.sh`
4. Verify with `./verification/verify-setup.sh`
5. Use appropriate example based on their needs

**Scenario 2: User has existing Clojure project**
1. Run setup in Claude Code runtime
2. Navigate to their project
3. Run their project (dependencies now work)

**Scenario 3: Setup fails**
1. Check `./runtime/inspect-runtime.sh --verbose`
2. Review `/tmp/proxy.log`
3. Consult `docs/TROUBLESHOOTING.md`
4. Re-run setup (idempotent)

### For Developers

**As a reference:**
- Copy scripts to your own project
- Study the proxy wrapper implementation
- Understand the configuration layers
- Adapt for other JVM languages (Kotlin, Scala, etc.)

**As a dependency:**
- Include as git submodule
- Run setup as part of your project initialization
- Reference examples for documentation

## Key Features

### Idempotent Setup
Run setup multiple times safely - it detects existing configuration and updates as needed.

### Comprehensive Testing
- **verify-setup.sh** - Quick health check
- **test-idempotency.sh** - Thorough edge case testing

### Multiple Configuration Layers
Configures all three mechanisms:
- Maven settings (for Clojure CLI)
- Java system properties (for direct Java usage)
- Gradle properties (for Gradle builds)

### Self-Documenting
- Tests serve as documentation
- Examples prove correctness
- Architecture explains the "why"

### AI-Friendly Organization
- Clear directory structure
- Machine-readable output (JSON)
- Explicit error messages
- Consistent exit codes

## Common Commands

```bash
# Check runtime compatibility
./runtime/inspect-runtime.sh

# Setup Clojure (idempotent)
source ./setup/setup-clojure.sh

# Verify setup worked
./verification/verify-setup.sh

# Check proxy status
pgrep -f proxy-wrapper.py
tail -f /tmp/proxy.log

# Use different port
PROXY_PORT=8889 source ./setup/setup-clojure.sh

# Test with example
cd examples/greenfield/simple-app && clj -M:run

# Comprehensive testing
./verification/test-idempotency.sh
```

## Troubleshooting

**Setup fails:**
```bash
./runtime/inspect-runtime.sh --verbose
tail /tmp/proxy.log
```

**Dependencies won't download:**
```bash
pgrep -f proxy-wrapper.py  # Proxy running?
cat ~/.m2/settings.xml     # Config correct?
source ./setup/setup-clojure.sh  # Re-run setup
```

**Port conflict:**
```bash
PROXY_PORT=8889 source ./setup/setup-clojure.sh
```

**See:** [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) for detailed solutions.

## Documentation

| Document | Purpose |
|----------|---------|
| [AI-AGENT-GUIDE.md](docs/AI-AGENT-GUIDE.md) | Complete step-by-step guide for AI agents |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md) | Technical design, decisions, and data flow |
| [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |
| [setup/README.md](setup/README.md) | Setup scripts documentation |
| [verification/README.md](verification/README.md) | Testing and verification tools |
| [runtime/README.md](runtime/README.md) | Runtime inspection guide |
| [examples/](examples/) | Working examples for different scenarios |

## Requirements

- **OS:** Linux (tested on Claude Code runtime)
- **Python:** 3.6+ (for proxy wrapper)
- **Bash:** 4.0+ (for setup scripts)
- **Network:** HTTP proxy configuration in `http_proxy` environment variable

**Automatically installed:**
- Clojure CLI tools (if not present)

## Why This Approach?

**Alternatives considered:**
- ❌ Modify Java to support proxy auth (not possible)
- ❌ Pre-download all dependencies (doesn't scale)
- ❌ Use different Clojure distribution (doesn't solve root problem)
- ✅ **Local proxy wrapper** (transparent, reliable, debuggable)

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for detailed analysis.

## Verified To Work

✅ Clojure CLI (clj/clojure) with deps.edn
✅ Maven Central dependency downloads
✅ Clojars dependency downloads
✅ Git dependencies via deps.edn
✅ Gradle builds with Clojure dependencies
✅ Multiple concurrent Clojure processes
✅ Idempotent setup (can run multiple times)
✅ Port configuration (customizable)
✅ Recovery from broken states

## Contributing

This is a reference implementation. To improve:

1. Test in your environment
2. Run `./verification/test-idempotency.sh`
3. Document issues in `docs/TROUBLESHOOTING.md`
4. Submit improvements

## License

MIT License - See [LICENSE](LICENSE) file for details.

## For More Information

- **Start here:** [`docs/AI-AGENT-GUIDE.md`](docs/AI-AGENT-GUIDE.md)
- **Understand the design:** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- **Fix problems:** [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)
- **See it working:** [`examples/`](examples/)

---

**Repository Purpose:** Reference implementation for AI agents to reliably set up Clojure in Claude Code runtime's authenticated proxy environment. Designed to be explored, understood, and adapted.
