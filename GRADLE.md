# Using Gradle for Clojure Development

This guide is for developers who want to use **Gradle** instead of the Clojure CLI, typically when:
- Integrating Clojure with existing Java projects
- Building JVM applications that mix Java and Clojure
- Using Gradle's extensive plugin ecosystem

> **Note**: Most Clojure developers use `clj` and `deps.edn`. See [QUICKSTART.md](./QUICKSTART.md) for the standard approach.

---

## Setup

### 1. Start the Proxy

```bash
source setup-clojure.sh
```

This starts the proxy wrapper and configures everything needed.

### 2. Create a Gradle Project

```bash
mkdir my-gradle-clojure && cd my-gradle-clojure
```

Create `build.gradle`:
```gradle
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

    // Add more Clojure libraries as needed
    // implementation 'ring:ring-core:1.9.6'
    // implementation 'cheshire:cheshire:5.11.0'
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

// Task to run a Clojure namespace
tasks.register('runClojure', JavaExec) {
    mainClass = 'clojure.main'
    classpath = sourceSets.main.runtimeClasspath
    args = ['-m', 'myapp.core']
}
```

Create `gradle.properties`:
```properties
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=8888
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=8888
systemProp.http.nonProxyHosts=localhost|127.0.0.1
```

### 3. Create Clojure Source

```bash
mkdir -p src/main/clojure/myapp
```

Create `src/main/clojure/myapp/core.clj`:
```clojure
(ns myapp.core
  (:gen-class))

(defn -main [& args]
  (println "Hello from Clojure via Gradle!")
  (println "Clojure version:" (clojure-version)))
```

### 4. Build and Run

```bash
# Download dependencies
gradle build

# Run your app
gradle runClojure

# Or start a REPL
gradle repl
```

---

## Adding Dependencies

### From Maven Central

```gradle
dependencies {
    implementation 'org.clojure:clojure:1.11.1'
    implementation 'org.clojure:data.json:2.4.0'
}
```

### From Clojars

```gradle
dependencies {
    implementation 'ring:ring-core:1.9.6'
    implementation 'ring:ring-jetty-adapter:1.9.6'
    implementation 'compojure:compojure:1.7.0'
    implementation 'cheshire:cheshire:5.11.0'
    implementation 'http-kit:http-kit:2.6.0'
}
```

### Mixed Java and Clojure

```gradle
dependencies {
    // Clojure
    implementation 'org.clojure:clojure:1.11.1'

    // Java libraries
    implementation 'com.google.guava:guava:31.1-jre'
    implementation 'org.apache.commons:commons-lang3:3.12.0'
}
```

After adding dependencies:
```bash
gradle build --refresh-dependencies
```

---

## Project Structure

### Standard Gradle Layout

```
my-gradle-clojure/
├── build.gradle
├── gradle.properties
├── settings.gradle (optional)
├── src/
│   ├── main/
│   │   ├── clojure/      # Clojure source
│   │   │   └── myapp/
│   │   │       └── core.clj
│   │   ├── java/         # Java source (if any)
│   │   └── resources/    # Resources
│   └── test/
│       ├── clojure/      # Clojure tests
│       └── java/         # Java tests
└── .gitignore
```

Add to `.gitignore`:
```
.gradle/
build/
.cpcache/
.clj-kondo/
.lsp/
```

---

## Common Tasks

### Run REPL

```bash
gradle repl
```

### Build JAR

```gradle
// In build.gradle
jar {
    manifest {
        attributes 'Main-Class': 'clojure.main'
    }
    from {
        configurations.runtimeClasspath.collect { it.isDirectory() ? it : zipTree(it) }
    }
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}
```

```bash
gradle jar
java -jar build/libs/my-gradle-clojure.jar -m myapp.core
```

### List Dependencies

```bash
gradle dependencies
```

### Clean Build

```bash
gradle clean build
```

### Run Tests

Add test dependencies:
```gradle
dependencies {
    testImplementation 'org.clojure:clojure:1.11.1'
    testImplementation 'org.clojure:test.check:1.1.1'
}
```

Create `src/test/clojure/myapp/core_test.clj`:
```clojure
(ns myapp.core-test
  (:require [clojure.test :refer :all]
            [myapp.core :as core]))

(deftest example-test
  (testing "Example test"
    (is (= 4 (+ 2 2)))))
```

Run tests:
```bash
gradle test
```

---

## Gradle vs Clojure CLI

| Feature | Gradle | Clojure CLI |
|---------|--------|-------------|
| **Standard in Clojure community** | ❌ No | ✅ Yes |
| **Proxy configuration** | ⭐⭐⭐⭐⭐ Easy | ⭐⭐⭐ Moderate |
| **Java interop** | ⭐⭐⭐⭐⭐ Excellent | ⭐⭐⭐ Good |
| **Build tooling** | ⭐⭐⭐⭐⭐ Extensive | ⭐⭐⭐ Basic |
| **Maven/Clojars** | ✅ Both work | ✅ Both work |
| **Learning curve** | Higher | Lower |
| **Clojure-first** | ❌ No | ✅ Yes |

**Recommendation**: Use Clojure CLI unless you specifically need Gradle's features for Java interop or complex builds.

---

## Example: Web Application

Create a Ring web server with Gradle:

`build.gradle`:
```gradle
dependencies {
    implementation 'org.clojure:clojure:1.11.1'
    implementation 'ring:ring-core:1.9.6'
    implementation 'ring:ring-jetty-adapter:1.9.6'
    implementation 'compojure:compojure:1.7.0'
}

tasks.register('runServer', JavaExec) {
    mainClass = 'clojure.main'
    classpath = sourceSets.main.runtimeClasspath
    args = ['-m', 'myapp.server']
}
```

`src/main/clojure/myapp/server.clj`:
```clojure
(ns myapp.server
  (:require [ring.adapter.jetty :refer [run-jetty]]
            [compojure.core :refer [defroutes GET]]
            [compojure.route :as route]))

(defroutes app-routes
  (GET "/" [] "Hello from Clojure!")
  (GET "/version" [] (str "Clojure " (clojure-version)))
  (route/not-found "Not Found"))

(defn -main [& args]
  (println "Starting server on port 3000...")
  (run-jetty app-routes {:port 3000 :join? true}))
```

Run:
```bash
gradle build
gradle runServer
```

Visit http://localhost:3000/

---

## Troubleshooting

### Proxy Errors

Ensure the proxy wrapper is running and `gradle.properties` has the correct configuration:

```bash
# Check proxy
ps aux | grep proxy-wrapper.py

# Restart if needed
source setup-clojure.sh

# Verify gradle.properties
cat gradle.properties
```

### Dependencies Not Downloading

```bash
# Clear cache
rm -rf ~/.gradle/caches

# Force refresh
gradle build --refresh-dependencies

# Check proxy logs
tail -f /tmp/proxy.log
```

### Build Errors

```bash
# Clean and rebuild
gradle clean build --stacktrace --info
```

---

## Converting from deps.edn to Gradle

If you have a `deps.edn` file:

```clojure
{:deps {org.clojure/clojure {:mvn/version "1.11.1"}
        ring/ring-core {:mvn/version "1.9.6"}
        cheshire/cheshire {:mvn/version "5.11.0"}}}
```

Convert to `build.gradle`:

```gradle
dependencies {
    implementation 'org.clojure:clojure:1.11.1'
    implementation 'ring:ring-core:1.9.6'
    implementation 'cheshire:cheshire:5.11.0'
}
```

The syntax is almost identical!

---

## See Also

- **Standard Clojure setup**: [QUICKSTART.md](./QUICKSTART.md)
- **Test results**: [TEST_RESULTS.md](./TEST_RESULTS.md)
- **Technical details**: [FINDINGS.md](./FINDINGS.md)
- **Working example**: `test-gradle/` directory

---

**Note**: This repository's primary focus is Clojure CLI with deps.edn. Gradle support is provided for Java interop scenarios and developers who prefer Gradle's build tooling.
