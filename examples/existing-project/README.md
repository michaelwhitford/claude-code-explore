# Existing Projects: Integration Guide

Examples for integrating Clojure runtime setup into existing projects.

## Examples

### deps-edn-example

Clojure project using `deps.edn` for dependency management.

**Features:**
- Multiple dependencies from Maven Central and Clojars
- Demonstrates JSON libraries (clojure.data.json, cheshire)
- Shows namespace structure

**Usage:**
```bash
cd deps-edn-example
clj -M:run
```

### gradle-example

Java/Gradle project with Clojure dependencies.

**Features:**
- Gradle build configuration
- Maven Central and Clojars repositories
- Clojure as a dependency in Java project

**Usage:**
```bash
cd gradle-example
gradle testDependencies
```

## For AI Agents: Working with Existing Projects

### Scenario 1: User Has deps.edn Project

Project structure:
```
user-project/
├── deps.edn
├── src/
│   └── user/
│       └── core.clj
└── ...
```

**Steps:**

1. **Run setup in Claude Code runtime:**
   ```bash
   source ../../setup/setup-clojure.sh
   ```

2. **Navigate to user's project:**
   ```bash
   cd /path/to/user-project
   ```

3. **Try to run their project:**
   ```bash
   # Common commands:
   clj -M:run                    # If they have :run alias
   clj -M -m their.main.ns       # Specify namespace
   clj                           # Start REPL
   ```

4. **If dependencies fail to download:**
   ```bash
   # Check proxy is running
   pgrep -f proxy-wrapper.py

   # Check logs
   tail /tmp/proxy.log

   # Re-run setup
   source ../../setup/setup-clojure.sh
   ```

### Scenario 2: User Has Gradle Project with Clojure

Project has `build.gradle` with Clojure dependencies:

```gradle
dependencies {
    implementation 'org.clojure:clojure:1.11.1'
}
```

**Steps:**

1. **Run setup:**
   ```bash
   source ../../setup/setup-clojure.sh
   ```
   *(Setup configures Gradle proxy settings automatically)*

2. **Run their Gradle build:**
   ```bash
   cd /path/to/user-project
   ./gradlew build
   ```

3. **If build fails with proxy errors:**
   ```bash
   # Verify Gradle config
   cat ~/.gradle/gradle.properties

   # Should contain proxy settings
   # If not, re-run setup
   source ../../setup/setup-clojure.sh

   # Try build again
   ./gradlew build --info
   ```

### Scenario 3: User Has Leiningen Project

Project has `project.clj`:

```clojure
(defproject my-app "0.1.0"
  :dependencies [[org.clojure/clojure "1.11.1"]])
```

**Steps:**

1. **Install Leiningen if needed:**
   ```bash
   # Download lein script
   curl -O https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
   chmod +x lein
   mv lein /usr/local/bin/

   # First run installs Leiningen
   lein version
   ```

2. **Run setup (configures Maven settings used by Lein):**
   ```bash
   source ../../setup/setup-clojure.sh
   ```

3. **Run their project:**
   ```bash
   cd /path/to/user-project
   lein run
   ```

### Common Integration Patterns

#### Pattern 1: deps.edn Project
```bash
# 1. Setup runtime
source ../../setup/setup-clojure.sh

# 2. Navigate to project
cd user-project

# 3. Check their deps.edn
cat deps.edn

# 4. Run based on their aliases
clj -M:run          # Or whatever alias they have
```

#### Pattern 2: Gradle Project
```bash
# 1. Setup runtime (includes Gradle config)
source ../../setup/setup-clojure.sh

# 2. Navigate to project
cd user-project

# 3. Run their build
./gradlew build
```

#### Pattern 3: Mix of Both
```bash
# Setup once, works for both
source ../../setup/setup-clojure.sh

# Then use either tool:
clj -M:run          # Clojure CLI
./gradlew build     # Gradle
```

## Troubleshooting Existing Projects

### Issue: "Could not find artifact"

**Cause:** Dependency not in standard repositories

**Solution:**
Check their `deps.edn` for custom repositories:
```clojure
{:mvn/repos
 {"custom" {:url "https://custom-repo.example.com"}}}
```

Ensure proxy can reach custom repository.

### Issue: "Syntax error in deps.edn"

**Cause:** Invalid EDN syntax

**Solution:**
```bash
# Validate deps.edn
clj -Sdescribe

# If error, check:
# - Matching braces
# - Commas (EDN doesn't use commas!)
# - Keywords have colons
```

### Issue: "Namespace not found"

**Cause:** File path doesn't match namespace

**Fix:** Ensure path matches namespace:
- `my-app.core` → `src/my_app/core.clj`
- `user.foo.bar` → `src/user/foo/bar.clj`

## Reference Examples

### deps-edn-example

Shows:
- Complex dependencies
- Multiple namespaces
- Clojars and Maven Central
- Alias configuration

### gradle-example

Shows:
- Gradle + Clojure integration
- Repository configuration
- Custom tasks

## See Also

- Greenfield projects: `../greenfield/`
- Troubleshooting: `../../docs/TROUBLESHOOTING.md`
- AI Agent Guide: `../../docs/AI-AGENT-GUIDE.md`
