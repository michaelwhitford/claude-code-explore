#!/bin/bash
# Runtime Inspection Script for Claude Code
# Helps AI agents understand their execution environment before setup
#
# Usage:
#   ./inspect-runtime.sh              # Human-readable output
#   ./inspect-runtime.sh --json       # Machine-readable JSON
#   ./inspect-runtime.sh --quiet      # Only show blockers/warnings

set +e  # Don't exit on errors - we're inspecting

# Configuration
OUTPUT_MODE="human"
VERBOSE=false
OUTPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --json) OUTPUT_MODE="json" ;;
        --quiet) OUTPUT_MODE="quiet" ;;
        --verbose) VERBOSE=true ;;
        --output) OUTPUT_FILE="$2"; shift ;;
        --help)
            echo "Runtime Inspection Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --json      Output in JSON format"
            echo "  --quiet     Only show warnings and blockers"
            echo "  --verbose   Show detailed information"
            echo "  --output    Save output to file"
            echo "  --help      Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1. Use --help for usage."; exit 1 ;;
    esac
    shift
done

# Collect system information
OS_TYPE=$(uname -s)
OS_VERSION=$(uname -r)
ARCH=$(uname -m)
DISK_AVAILABLE=$(df -BG . 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//')
MEMORY_AVAILABLE=$(free -g 2>/dev/null | awk 'NR==2 {print $7}' || echo "unknown")

# Collect runtime information
SHELL_TYPE=$(basename "$SHELL")
SHELL_VERSION=$($SHELL --version 2>/dev/null | head -n1 || echo "unknown")
CURRENT_USER=$(whoami)
IS_ROOT=false
[ "$CURRENT_USER" = "root" ] && IS_ROOT=true
HOME_DIR="$HOME"
CURRENT_DIR=$(pwd)

# Collect network information
HTTP_PROXY_SET=false
HTTPS_PROXY_SET=false
[ -n "$http_proxy" ] || [ -n "$HTTP_PROXY" ] && HTTP_PROXY_SET=true
[ -n "$https_proxy" ] || [ -n "$HTTPS_PROXY" ] && HTTPS_PROXY_SET=true

# Mask passwords in proxy URLs for display
PROXY_DISPLAY="${http_proxy:-${HTTP_PROXY:-not set}}"
if [[ "$PROXY_DISPLAY" =~ ://([^:]+):([^@]+)@ ]]; then
    PROXY_DISPLAY=$(echo "$PROXY_DISPLAY" | sed 's|://[^:]*:[^@]*@|://***:***@|')
fi

# Test internet connectivity
INTERNET_CONNECTED=false
if timeout 5 curl -s -o /dev/null https://repo1.maven.org/maven2/ 2>/dev/null || \
   timeout 5 wget -q --spider https://repo1.maven.org/maven2/ 2>/dev/null; then
    INTERNET_CONNECTED=true
fi

MAVEN_REACHABLE=false
if timeout 5 curl -s -o /dev/null https://repo1.maven.org/maven2/ 2>/dev/null || \
   timeout 5 wget -q --spider https://repo1.maven.org/maven2/ 2>/dev/null; then
    MAVEN_REACHABLE=true
fi

CLOJARS_REACHABLE=false
if timeout 5 curl -s -o /dev/null https://repo.clojars.org/ 2>/dev/null || \
   timeout 5 wget -q --spider https://repo.clojars.org/ 2>/dev/null; then
    CLOJARS_REACHABLE=true
fi

# Collect installed tools
HAS_GIT=false
GIT_VERSION=""
if command -v git &> /dev/null; then
    HAS_GIT=true
    GIT_VERSION=$(git --version | awk '{print $3}')
fi

HAS_CURL=false
if command -v curl &> /dev/null; then
    HAS_CURL=true
fi

HAS_WGET=false
if command -v wget &> /dev/null; then
    HAS_WGET=true
fi

HAS_PYTHON3=false
PYTHON_VERSION=""
if command -v python3 &> /dev/null; then
    HAS_PYTHON3=true
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
fi

HAS_JAVA=false
JAVA_VERSION=""
if command -v java &> /dev/null; then
    HAS_JAVA=true
    JAVA_VERSION=$(java -version 2>&1 | head -n1 | awk -F '"' '{print $2}')
fi

# Collect Clojure ecosystem info
HAS_CLOJURE=false
CLOJURE_VERSION=""
if command -v clojure &> /dev/null; then
    HAS_CLOJURE=true
    CLOJURE_VERSION=$(clojure --version 2>&1 | head -n1)
fi

HAS_LEIN=false
if command -v lein &> /dev/null; then
    HAS_LEIN=true
fi

MAVEN_SETTINGS_EXISTS=false
[ -f "$HOME/.m2/settings.xml" ] && MAVEN_SETTINGS_EXISTS=true

GRADLE_PROPS_EXISTS=false
[ -f "$HOME/.gradle/gradle.properties" ] && GRADLE_PROPS_EXISTS=true

# Detect Clojure projects in current directory
PROJECTS_DETECTED=""
[ -f "deps.edn" ] && PROJECTS_DETECTED="deps.edn "
[ -f "project.clj" ] && PROJECTS_DETECTED="${PROJECTS_DETECTED}project.clj "
[ -f "build.gradle" ] && grep -q "clojure" build.gradle 2>/dev/null && PROJECTS_DETECTED="${PROJECTS_DETECTED}build.gradle "

# Check permissions
CAN_WRITE_USR_LOCAL=false
touch /usr/local/bin/.test_write 2>/dev/null && rm /usr/local/bin/.test_write 2>/dev/null && CAN_WRITE_USR_LOCAL=true

CAN_WRITE_M2=false
mkdir -p "$HOME/.m2" 2>/dev/null && touch "$HOME/.m2/.test_write" 2>/dev/null && rm "$HOME/.m2/.test_write" 2>/dev/null && CAN_WRITE_M2=true

CAN_START_PROCESSES=true  # Assume true unless we have reason to believe otherwise

# Check port availability
PORTS_AVAILABLE=""
for port in 8888 8889 8890; do
    if ! netstat -tuln 2>/dev/null | grep -q ":$port " && ! ss -tuln 2>/dev/null | grep -q ":$port "; then
        PORTS_AVAILABLE="$PORTS_AVAILABLE$port "
    fi
done

# Determine readiness
READY_FOR_SETUP=true
BLOCKERS=""
WARNINGS=""

# Check for blockers
if ! $HAS_PYTHON3; then
    READY_FOR_SETUP=false
    BLOCKERS="${BLOCKERS}Python3 required for proxy wrapper. "
fi

if ! $HTTP_PROXY_SET && ! $INTERNET_CONNECTED; then
    WARNINGS="${WARNINGS}No proxy configured and direct internet connectivity uncertain. "
fi

if ! $CAN_WRITE_M2; then
    READY_FOR_SETUP=false
    BLOCKERS="${BLOCKERS}Cannot write to ~/.m2 directory. "
fi

if [ -z "$PORTS_AVAILABLE" ]; then
    WARNINGS="${WARNINGS}Default ports (8888-8890) may be in use. "
fi

# Add informational warnings
if ! $HAS_JAVA && ! $HAS_CLOJURE; then
    WARNINGS="${WARNINGS}Java not installed (will be installed by Clojure CLI installer). "
fi

# Output functions
output_human() {
    echo "============================================================"
    echo "Claude Code Runtime Inspection Report"
    echo "============================================================"
    echo "Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo ""

    echo "[SYSTEM]"
    echo "  OS: $OS_TYPE $OS_VERSION"
    echo "  Architecture: $ARCH"
    echo "  Available disk: ${DISK_AVAILABLE}GB"
    echo "  Available memory: ${MEMORY_AVAILABLE}GB"
    echo ""

    echo "[RUNTIME]"
    echo "  Shell: $SHELL_TYPE"
    echo "  User: $CURRENT_USER $([ "$IS_ROOT" = true ] && echo '(root)' || echo '(non-root)')"
    echo "  Home: $HOME_DIR"
    echo "  Working directory: $CURRENT_DIR"
    echo ""

    echo "[NETWORK]"
    echo "  http_proxy: $PROXY_DISPLAY"
    echo "  Internet: $([ "$INTERNET_CONNECTED" = true ] && echo 'Connected' || echo 'Not confirmed')"
    echo "  Maven Central: $([ "$MAVEN_REACHABLE" = true ] && echo 'Reachable' || echo 'Not reachable')"
    echo "  Clojars: $([ "$CLOJARS_REACHABLE" = true ] && echo 'Reachable' || echo 'Not reachable')"
    echo ""

    echo "[INSTALLED TOOLS]"
    echo "  git: $([ "$HAS_GIT" = true ] && echo "yes (${GIT_VERSION})" || echo 'no')"
    echo "  curl: $([ "$HAS_CURL" = true ] && echo 'yes' || echo 'no')"
    echo "  wget: $([ "$HAS_WGET" = true ] && echo 'yes' || echo 'no')"
    echo "  python3: $([ "$HAS_PYTHON3" = true ] && echo "yes (${PYTHON_VERSION})" || echo 'no')"
    echo "  java: $([ "$HAS_JAVA" = true ] && echo "yes (${JAVA_VERSION})" || echo 'no')"
    echo ""

    echo "[CLOJURE ECOSYSTEM]"
    echo "  Clojure CLI: $([ "$HAS_CLOJURE" = true ] && echo "Installed (${CLOJURE_VERSION})" || echo 'Not installed')"
    echo "  Leiningen: $([ "$HAS_LEIN" = true ] && echo 'Installed' || echo 'Not installed')"
    echo "  Maven settings: $([ "$MAVEN_SETTINGS_EXISTS" = true ] && echo 'Found' || echo 'Not found')"
    echo "  Gradle properties: $([ "$GRADLE_PROPS_EXISTS" = true ] && echo 'Found' || echo 'Not found')"
    echo "  Projects detected: $([ -n "$PROJECTS_DETECTED" ] && echo "$PROJECTS_DETECTED" || echo 'None')"
    echo ""

    echo "[PERMISSIONS]"
    echo "  Can write to /usr/local/bin: $([ "$CAN_WRITE_USR_LOCAL" = true ] && echo 'Yes' || echo 'No (may need sudo)')"
    echo "  Can write to ~/.m2: $([ "$CAN_WRITE_M2" = true ] && echo 'Yes' || echo 'No')"
    echo "  Can start background processes: $([ "$CAN_START_PROCESSES" = true ] && echo 'Yes' || echo 'Unknown')"
    echo "  Available ports: $PORTS_AVAILABLE"
    echo ""

    echo "[ASSESSMENT]"
    if [ -n "$BLOCKERS" ]; then
        echo "  BLOCKERS: $BLOCKERS"
    fi
    if [ -n "$WARNINGS" ]; then
        echo "  WARNINGS: $WARNINGS"
    fi

    if [ "$READY_FOR_SETUP" = true ]; then
        echo "  STATUS: Ready for setup"
        echo ""
        echo "Next step: source ./setup/setup-clojure.sh"
    else
        echo "  STATUS: Not ready - resolve blockers first"
    fi

    echo ""
    echo "============================================================"
}

output_json() {
    cat <<EOF
{
  "timestamp": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "system": {
    "os": "$OS_TYPE",
    "version": "$OS_VERSION",
    "arch": "$ARCH",
    "disk_available_gb": "$DISK_AVAILABLE",
    "memory_available_gb": "$MEMORY_AVAILABLE"
  },
  "runtime": {
    "shell": "$SHELL_TYPE",
    "user": "$CURRENT_USER",
    "is_root": $IS_ROOT,
    "home": "$HOME_DIR",
    "cwd": "$CURRENT_DIR"
  },
  "network": {
    "http_proxy_set": $HTTP_PROXY_SET,
    "https_proxy_set": $HTTPS_PROXY_SET,
    "internet_connected": $INTERNET_CONNECTED,
    "maven_central_reachable": $MAVEN_REACHABLE,
    "clojars_reachable": $CLOJARS_REACHABLE
  },
  "tools": {
    "git": {"installed": $HAS_GIT, "version": "$GIT_VERSION"},
    "curl": {"installed": $HAS_CURL},
    "wget": {"installed": $HAS_WGET},
    "python3": {"installed": $HAS_PYTHON3, "version": "$PYTHON_VERSION"},
    "java": {"installed": $HAS_JAVA, "version": "$JAVA_VERSION"}
  },
  "clojure_ecosystem": {
    "clojure_cli_installed": $HAS_CLOJURE,
    "leiningen_installed": $HAS_LEIN,
    "maven_settings_exists": $MAVEN_SETTINGS_EXISTS,
    "gradle_properties_exists": $GRADLE_PROPS_EXISTS,
    "projects_detected": "$(echo $PROJECTS_DETECTED | xargs)"
  },
  "permissions": {
    "can_write_usr_local_bin": $CAN_WRITE_USR_LOCAL,
    "can_write_home_m2": $CAN_WRITE_M2,
    "can_start_background_processes": $CAN_START_PROCESSES,
    "ports_available": "$(echo $PORTS_AVAILABLE | xargs)"
  },
  "ready_for_setup": $READY_FOR_SETUP,
  "blockers": "$BLOCKERS",
  "warnings": "$WARNINGS"
}
EOF
}

output_quiet() {
    if [ -n "$BLOCKERS" ]; then
        echo "BLOCKERS: $BLOCKERS"
    fi
    if [ -n "$WARNINGS" ]; then
        echo "WARNINGS: $WARNINGS"
    fi
    if [ "$READY_FOR_SETUP" = true ] && [ -z "$BLOCKERS" ] && [ -z "$WARNINGS" ]; then
        echo "Ready for setup"
    fi
}

# Main output
OUTPUT=""
case $OUTPUT_MODE in
    json) OUTPUT=$(output_json) ;;
    quiet) OUTPUT=$(output_quiet) ;;
    *) OUTPUT=$(output_human) ;;
esac

# Write to file or stdout
if [ -n "$OUTPUT_FILE" ]; then
    echo "$OUTPUT" > "$OUTPUT_FILE"
    echo "Report saved to: $OUTPUT_FILE"
else
    echo "$OUTPUT"
fi

# Exit with appropriate code
if [ "$READY_FOR_SETUP" = true ]; then
    exit 0
elif [ -n "$WARNINGS" ] && [ -z "$BLOCKERS" ]; then
    exit 1
else
    exit 2
fi
