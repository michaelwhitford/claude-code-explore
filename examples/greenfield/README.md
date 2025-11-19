# Greenfield Projects: Starting from Scratch

This directory contains examples for creating new Clojure projects from scratch.

## simple-app

Minimal Clojure application demonstrating basic setup.

### Structure

```
simple-app/
├── deps.edn          # Project dependencies
└── src/
    └── simple/
        └── core.clj  # Main application code
```

### Usage

```bash
cd simple-app
clj -M:run
```

**Expected output:**
```
Hello from Clojure!
Setup is working correctly.
Clojure version: 1.11.1
```

### For AI Agents: Creating a New Project

Use this as a template for greenfield Clojure projects:

**Step 1: Create project structure**
```bash
mkdir my-project
cd my-project
mkdir -p src/my_project
```

**Step 2: Create deps.edn**
```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}}
 :aliases
 {:run {:main-opts ["-m" "my-project.core"]}}}
```

**Step 3: Create main source file** (`src/my_project/core.clj`)
```clojure
(ns my-project.core)

(defn -main [& args]
  (println "Hello, world!"))
```

**Note:** Hyphens in namespace become underscores in filesystem:
- Namespace: `my-project.core`
- File path: `src/my_project/core.clj`

**Step 4: Run it**
```bash
clj -M:run
```

### Adding Dependencies

Edit `deps.edn`:

```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}
        ;; Add dependencies here:
        cheshire/cheshire {:mvn/version "5.11.0"}           ;; JSON
        org.clojure/data.json {:mvn/version "2.4.0"}        ;; JSON
        clj-http/clj-http {:mvn/version "3.12.3"}}          ;; HTTP client
 :aliases
 {:run {:main-opts ["-m" "my-project.core"]}}}
```

Then require in your code:

```clojure
(ns my-project.core
  (:require [cheshire.core :as json]
            [clj-http.client :as http]))

(defn -main [& args]
  (println (json/generate-string {:hello "world"})))
```

### Common deps.edn Patterns

**Testing:**
```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}}
 :aliases
 {:test {:extra-paths ["test"]
         :extra-deps {org.clojure/test.check {:mvn/version "1.1.1"}}
         :main-opts ["-m" "cognitect.test-runner"]}
  :run {:main-opts ["-m" "my-project.core"]}}}
```

**REPL:**
```clojure
{:aliases
 {:repl {:extra-deps {nrepl/nrepl {:mvn/version "1.0.0"}
                      cider/cider-nrepl {:mvn/version "0.30.0"}}
         :main-opts ["-m" "nrepl.cmdline" "--interactive"]}}}
```

**Build:**
```clojure
{:aliases
 {:uberjar {:extra-deps {com.github.seancorfield/depstar {:mvn/version "2.1.303"}}
            :exec-fn hf.depstar/uberjar
            :exec-args {:jar "my-project.jar"
                        :main-class my-project.core}}}}
```

## Starting Your Project

1. **Ensure setup is complete:**
   ```bash
   ../../verification/verify-setup.sh
   ```

2. **Copy the simple-app template:**
   ```bash
   cp -r simple-app my-new-project
   cd my-new-project
   ```

3. **Customize:**
   - Edit `deps.edn` with your dependencies
   - Rename namespace in source files
   - Update directory structure to match namespaces

4. **Run:**
   ```bash
   clj -M:run
   ```

## See Also

- Existing projects: `../existing-project/`
- Setup guide: `../../setup/README.md`
- AI Agent Guide: `../../docs/AI-AGENT-GUIDE.md`
