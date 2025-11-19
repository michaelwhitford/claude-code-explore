# Quick Start Guide

Get up and running with Clojure development in Claude Code runtime in 5 minutes.

## Prerequisites

- Claude Code runtime environment
- This repository cloned/available

## Setup (One-Time)

### 1. Start the Proxy Wrapper

```bash
cd claude-code-explore
source setup-environment.sh
```

You should see:
```
✓ Proxy wrapper started successfully
✓ Environment configured
✓ Gradle configuration exists
```

### 2. Verify Setup

Test that everything works:

```bash
cd test-gradle
gradle build
```

Expected output:
```
BUILD SUCCESSFUL in 8s
```

## Create Your First Clojure Project

### 1. Create Project Directory

```bash
mkdir my-clojure-app
cd my-clojure-app
```

### 2. Create build.gradle

```bash
cat > build.gradle << 'EOF'
plugins {
    id 'java'
    id 'application'
}

repositories {
    mavenCentral()
    maven {
        url "https://repo.clojars.org/"
    }
}

dependencies {
    implementation 'org.clojure:clojure:1.11.1'
}

application {
    mainClass = 'clojure.main'
}

// Task to run Clojure REPL
tasks.register('repl', JavaExec) {
    mainClass = 'clojure.main'
    classpath = sourceSets.main.runtimeClasspath
    standardInput = System.in
}

// Task to run a Clojure script
tasks.register('runClojure', JavaExec) {
    mainClass = 'clojure.main'
    classpath = sourceSets.main.runtimeClasspath
    args = ['-m', 'my-clojure-app.core']
}
EOF
```

### 3. Create gradle.properties

```bash
cat > gradle.properties << 'EOF'
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=8888
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=8888
EOF
```

### 4. Create Clojure Source

```bash
mkdir -p src/main/clojure/my_clojure_app

cat > src/main/clojure/my_clojure_app/core.clj << 'EOF'
(ns my-clojure-app.core
  (:gen-class))

(defn -main
  [& args]
  (println "Hello, Clojure!")
  (println "Running in Claude Code runtime")
  (println "Clojure version:" (clojure-version)))
EOF
```

### 5. Build and Run

```bash
# Download dependencies and build
gradle build

# Run your Clojure application
gradle runClojure
```

Expected output:
```
Hello, Clojure!
Running in Claude Code runtime
Clojure version: 1.11.1
```

## Adding More Dependencies

Edit `build.gradle` and add dependencies:

```gradle
dependencies {
    implementation 'org.clojure:clojure:1.11.1'

    // Web development
    implementation 'ring:ring-core:1.9.6'
    implementation 'ring:ring-jetty-adapter:1.9.6'
    implementation 'compojure:compojure:1.7.0'

    // JSON
    implementation 'cheshire:cheshire:5.11.0'

    // HTTP client
    implementation 'clj-http:clj-http:3.12.3'

    // Testing
    testImplementation 'org.clojure:test.check:1.1.1'
}
```

Then run:
```bash
gradle build --refresh-dependencies
```

## Common Tasks

### Run Clojure REPL

```bash
gradle repl
```

### Run Tests

Create `src/test/clojure/my_clojure_app/core_test.clj`:

```clojure
(ns my-clojure-app.core-test
  (:require [clojure.test :refer :all]
            [my-clojure-app.core :as core]))

(deftest example-test
  (testing "Example test"
    (is (= 4 (+ 2 2)))))
```

Configure testing in `build.gradle`:

```gradle
tasks.register('testClojure', JavaExec) {
    mainClass = 'clojure.main'
    classpath = sourceSets.test.runtimeClasspath + sourceSets.main.runtimeClasspath
    args = ['-e', '(require \'clojure.test) (clojure.test/run-all-tests #"my-clojure-app.*-test")']
}
```

Run tests:
```bash
gradle testClojure
```

### Clean Build

```bash
gradle clean build
```

### View Dependencies

```bash
gradle dependencies
```

## Troubleshooting

### "Connection refused" or "401 Unauthorized"

The proxy wrapper is not running. Restart it:

```bash
cd claude-code-explore
source setup-environment.sh
```

### "Cannot resolve dependency"

1. Check proxy is running:
   ```bash
   ps aux | grep proxy-wrapper
   ```

2. Check proxy logs:
   ```bash
   tail -f /tmp/proxy.log
   ```

3. Verify gradle.properties has proxy configuration

### Clear Gradle cache

```bash
rm -rf ~/.gradle/caches
gradle build --refresh-dependencies
```

## Next Steps

- Read [README.md](README.md) for complete documentation
- Read [FINDINGS.md](FINDINGS.md) for technical details
- Explore example projects in `test-gradle/`

## Tips

1. **Always source setup-environment.sh** at the start of your session
2. **Use Gradle** instead of Leiningen or Maven
3. **Project-level gradle.properties** is recommended for each project
4. **Check proxy logs** if downloads fail

## Example: Web Server

Create a simple Ring web server:

```clojure
(ns my-clojure-app.web
  (:require [ring.adapter.jetty :refer [run-jetty]]
            [ring.middleware.params :refer [wrap-params]]
            [compojure.core :refer [defroutes GET]]
            [compojure.route :as route]))

(defroutes app-routes
  (GET "/" [] "Hello from Clojure!")
  (GET "/version" [] (str "Clojure " (clojure-version)))
  (route/not-found "Not Found"))

(def app
  (wrap-params app-routes))

(defn -main [& args]
  (run-jetty app {:port 3000 :join? false}))
```

Add dependencies:
```gradle
dependencies {
    implementation 'org.clojure:clojure:1.11.1'
    implementation 'ring:ring-core:1.9.6'
    implementation 'ring:ring-jetty-adapter:1.9.6'
    implementation 'compojure:compojure:1.7.0'
}
```

Run:
```bash
gradle build
gradle run
```

Visit http://localhost:3000/

---

**Happy Clojure coding in Claude Code runtime! 🚀**
