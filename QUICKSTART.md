# Clojure in Claude Code - 2 Minute Quick Start

## Step 1: Setup (30 seconds)

```bash
source setup-clojure.sh
```

This command:
- Installs Clojure CLI if not present
- Starts the proxy wrapper for Maven Central/Clojars access
- Configures Java proxy settings automatically

## Step 2: Create a Project (30 seconds)

```bash
mkdir hello-clojure && cd hello-clojure
```

Create `deps.edn`:
```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}}
 :aliases {:run {:main-opts ["-m" "hello.core"]}}}
```

Create `src/hello/core.clj`:
```clojure
(ns hello.core)

(defn -main [& args]
  (println "Hello from Clojure!")
  (println "Running in Claude Code runtime")
  (println "Clojure version:" (clojure-version)))
```

## Step 3: Run (30 seconds)

```bash
clj -M:run
```

Output:
```
Hello from Clojure!
Running in Claude Code runtime
Clojure version: 1.11.1
```

## What Just Happened?

1. ✅ Clojure CLI downloaded `org.clojure/clojure` from Maven Central
2. ✅ The proxy wrapper authenticated your requests automatically
3. ✅ Your code ran successfully

## Next Steps

### Add More Dependencies

Edit `deps.edn`:
```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}
        cheshire/cheshire {:mvn/version "5.11.0"}    ; JSON from Clojars
        http-kit/http-kit {:mvn/version "2.6.0"}}}   ; HTTP server
```

Download them:
```bash
clj -Spath
```

### Start a REPL

```bash
clj
```

Try some code:
```clojure
(+ 1 2 3)
=> 6

(map inc [1 2 3])
=> (2 3 4)

(require '[cheshire.core :as json])
(json/generate-string {:message "Hello!"})
=> "{\"message\":\"Hello!\"}"
```

### Run the Example Project

```bash
cd test-clojure-deps
clj -M:run
```

This demonstrates using multiple libraries from both Maven Central and Clojars.

## Troubleshooting

**"Failed to read artifact descriptor"**
```bash
# Restart the setup
source setup-clojure.sh

# Verify it's working
ps aux | grep proxy-wrapper.py
tail /tmp/proxy.log
```

**"Service Unavailable (503)"**
- This is a transient Maven Central error
- Just retry the command

**Dependencies not downloading**
```bash
# Check configuration
echo $JAVA_TOOL_OPTIONS
cat ~/.m2/settings.xml

# Clear cache and retry
rm -rf ~/.m2/repository
clj -Spath
```

## That's It!

You now have full Clojure development with:
- ✅ Standard `clj`/`clojure` commands
- ✅ Normal `deps.edn` workflow
- ✅ Maven Central and Clojars access
- ✅ No special workarounds needed

See [README.md](./README.md) for more details, configuration options, and examples.

**Happy coding! 🚀**
