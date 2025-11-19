# Clojure Runtime Test Results

**Date:** November 19, 2025
**Environment:** Claude Code Runtime with HTTP Proxy
**Status:** ✅ ALL TESTS PASSED

---

## Executive Summary

The Clojure runtime with `deps.edn` is **fully functional** in the Claude Code environment. The HTTP proxy wrapper solution successfully enables:

- ✅ Clojure CLI (tools.deps) dependency resolution
- ✅ Downloads from Maven Central (repo1.maven.org)
- ✅ Downloads from Clojars (repo.clojars.org)
- ✅ Java runtime execution with external libraries
- ✅ Gradle builds with Clojure dependencies

---

## Test Environment Setup

### Components Installed

| Component | Version | Location |
|-----------|---------|----------|
| Clojure CLI | 1.11.1.1435 | /usr/local/bin/clojure |
| Gradle | 8.14.3 | /opt/gradle/bin/gradle |
| Java JDK | 21.0.8 (OpenJDK) | /usr/lib/jvm/java-21-openjdk-amd64 |
| Python | 3.x | /usr/bin/python3 |

### Proxy Configuration

- **Proxy Wrapper:** Running on 127.0.0.1:8888
- **Upstream Proxy:** 21.0.0.67:15004 (with JWT authentication)
- **Configuration Method:**
  - JAVA_TOOL_OPTIONS environment variable
  - Maven settings.xml (~/.m2/settings.xml)
  - Gradle properties (gradle.properties)

---

## Test 1: Gradle Build with Clojure Dependencies

**Test:** Verify Gradle can download Clojure from Maven Central

**Dependencies Tested:**
- org.clojure:clojure:1.11.1
- org.clojure:spec.alpha:0.3.218
- org.clojure:core.specs.alpha:0.2.62

**Command:**
```bash
cd test-gradle
gradle build
gradle testDependencies
```

**Result:** ✅ **PASSED**

**Downloaded JARs:**
- /root/.gradle/caches/modules-2/files-2.1/org.clojure/clojure/1.11.1/clojure-1.11.1.jar
- /root/.gradle/caches/modules-2/files-2.1/org.clojure/spec.alpha/0.3.218/spec.alpha-0.3.218.jar
- /root/.gradle/caches/modules-2/files-2.1/org.clojure/core.specs.alpha/0.2.62/core.specs.alpha-0.2.62.jar

**Proxy Activity:**
```
[REQUEST] 127.0.0.1:51652 -> CONNECT repo.maven.apache.org:443 HTTP/1.1
[REQUEST] 127.0.0.1:37314 -> CONNECT repo.maven.apache.org:443 HTTP/1.1
```

---

## Test 2: Clojure CLI with deps.edn

**Test:** Create and run a toy Clojure application using deps.edn

**Project Structure:**
```
test-clojure-deps/
├── deps.edn
└── src/
    └── hello/
        └── core.clj
```

**deps.edn Configuration:**
```clojure
{:paths ["src"]
 :deps {org.clojure/clojure {:mvn/version "1.11.1"}
        org.clojure/data.json {:mvn/version "2.4.0"}
        cheshire/cheshire {:mvn/version "5.11.0"}}
 :aliases
 {:run {:main-opts ["-m" "hello.core"]}}}
```

**Dependencies from Multiple Sources:**
- Maven Central: org.clojure/clojure, org.clojure/data.json
- Clojars: cheshire/cheshire
- Transitive: Jackson libraries, tigris

**Commands:**
```bash
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8888 \
                          -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8888"
cd test-clojure-deps
clojure -Spath    # Build classpath
clojure -M:run    # Run application
```

**Result:** ✅ **PASSED**

**Successfully Downloaded:**
1. org.clojure/clojure:1.11.1
2. org.clojure/data.json:2.4.0
3. cheshire/cheshire:5.11.0 (from Clojars!)
4. com.fasterxml.jackson.core/jackson-core:2.13.3
5. com.fasterxml.jackson.dataformat/jackson-dataformat-smile:2.13.3
6. com.fasterxml.jackson.dataformat/jackson-dataformat-cbor:2.13.3
7. tigris/tigris:0.1.2 (from Clojars!)
8. org.clojure/spec.alpha:0.3.218
9. org.clojure/core.specs.alpha:0.2.62

**Classpath Output:**
```
src:/root/.m2/repository/cheshire/cheshire/5.11.0/cheshire-5.11.0.jar:
/root/.m2/repository/org/clojure/clojure/1.11.1/clojure-1.11.1.jar:
/root/.m2/repository/org/clojure/data.json/2.4.0/data.json-2.4.0.jar:
[... 9 total JARs ...]
```

**Proxy Activity:**
```
[REQUEST] 127.0.0.1:56851 -> CONNECT repo1.maven.org:443 HTTP/1.1
[REQUEST] 127.0.0.1:55395 -> CONNECT repo1.maven.org:443 HTTP/1.1
[REQUEST] 127.0.0.1:57005 -> CONNECT repo.clojars.org:443 HTTP/1.1
[REQUEST] 127.0.0.1:63740 -> CONNECT repo.clojars.org:443 HTTP/1.1
[REQUEST] 127.0.0.1:25098 -> CONNECT repo.clojars.org:443 HTTP/1.1
```

---

## Test 3: Clojure Runtime Execution

**Test:** Run actual Clojure code using downloaded libraries

**Application Features:**
1. Basic Clojure operations (arithmetic, collections)
2. JSON serialization with clojure.data.json
3. JSON serialization with cheshire (from Clojars)
4. Pretty printing and parsing

**Application Output:**
```
= 60
Clojure Runtime Test with deps.edn
= 60

1. Basic Clojure:
   (+ 1 2 3 4 5) => 15
   (map inc [1 2 3]) => (2 3 4)

2. Testing clojure.data.json:
   Original data: {:name Claude, :type AI Assistant, :version 1.0}
   JSON string: {"name":"Claude","type":"AI Assistant","version":1.0}
   Parsed back: {:name Claude, :type AI Assistant, :version 1.0}

3. Testing cheshire (faster JSON library):
   Generated pretty JSON:
{
  "framework" : "deps.edn",
  "language" : "Clojure",
  "features" : [ "simple", "powerful", "Maven compatible" ],
  "works?" : true
}
   Parsed back: {:framework deps.edn, :language Clojure,
                 :features [simple powerful Maven compatible], :works? true}

= 60
All tests passed! Clojure runtime is working perfectly.
Dependencies from Maven Central and Clojars were resolved.
= 60
```

**Result:** ✅ **PASSED**

---

## Key Configuration Requirements

### 1. Proxy Wrapper Must Be Running

```bash
python3 proxy-wrapper.py > /tmp/proxy.log 2>&1 &
```

### 2. Maven Settings Required for Clojure CLI

File: `~/.m2/settings.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
  <proxies>
    <proxy>
      <id>local-proxy</id>
      <active>true</active>
      <protocol>http</protocol>
      <host>127.0.0.1</host>
      <port>8888</port>
    </proxy>
    <proxy>
      <id>local-proxy-https</id>
      <active>true</active>
      <protocol>https</protocol>
      <host>127.0.0.1</host>
      <port>8888</port>
    </proxy>
  </proxies>
</settings>
```

### 3. Java System Properties

```bash
export JAVA_TOOL_OPTIONS="-Dhttp.proxyHost=127.0.0.1 -Dhttp.proxyPort=8888 \
                          -Dhttps.proxyHost=127.0.0.1 -Dhttps.proxyPort=8888"
```

### 4. Gradle Properties (for Gradle builds)

File: `gradle.properties` or `~/.gradle/gradle.properties`

```properties
systemProp.http.proxyHost=127.0.0.1
systemProp.http.proxyPort=8888
systemProp.https.proxyHost=127.0.0.1
systemProp.https.proxyPort=8888
systemProp.http.nonProxyHosts=localhost|127.0.0.1
```

---

## Performance Observations

### Download Speeds
- Dependencies download successfully through the proxy
- Occasional 503 errors from Maven Central (transient, retries work)
- Clojars access is reliable

### Caching
- Maven local repository: `~/.m2/repository/`
- Gradle cache: `~/.gradle/caches/`
- Subsequent builds are much faster (local cache used)

---

## Troubleshooting Tips

### Issue: DNS Resolution Errors

**Symptom:** "Temporary failure in name resolution"

**Solution:** Ensure Maven settings.xml is configured correctly. The Clojure CLI uses Maven Aether which requires Maven proxy configuration, not just Java system properties.

### Issue: 503 Service Unavailable

**Symptom:** "status code: 503, reason phrase: Service Unavailable"

**Solution:** Transient error from Maven Central. Simply retry the command.

### Issue: Proxy Not Working

**Check:**
```bash
# Verify proxy is running
ps aux | grep proxy-wrapper.py

# Check proxy logs
tail -f /tmp/proxy.log

# Verify port is listening
lsof -i :8888
```

---

## Comparison: Gradle vs Clojure CLI

| Feature | Gradle | Clojure CLI (deps.edn) |
|---------|--------|------------------------|
| **Proxy Config** | gradle.properties | Maven settings.xml + JAVA_TOOL_OPTIONS |
| **Ease of Setup** | ⭐⭐⭐⭐⭐ Very Easy | ⭐⭐⭐ Moderate |
| **Maven Central** | ✅ Works | ✅ Works |
| **Clojars** | ✅ Works | ✅ Works |
| **Documentation** | Excellent | Requires Maven knowledge |
| **Caching** | Fast | Fast |
| **Reliability** | Excellent | Good (occasional retries needed) |

---

## Recommendations

### For New Projects
- ✅ **Use Clojure CLI with deps.edn** - It's the standard Clojure tool
- ✅ **Configure both Maven settings.xml AND JAVA_TOOL_OPTIONS** - Required for full compatibility
- ✅ **Keep proxy wrapper running** - Essential for HTTPS downloads

### For Production
- ✅ **Use the automated setup script** - `source setup-environment.sh`
- ✅ **Monitor proxy logs** - Helps debug any connectivity issues
- ✅ **Consider Gradle for complex builds** - More mature proxy support

### Best Practices
1. Always start the proxy wrapper before running Clojure commands
2. Export JAVA_TOOL_OPTIONS in your shell profile or startup scripts
3. Keep ~/.m2/settings.xml configured with proxy settings
4. Use `clojure -Spath` to verify classpath before running applications
5. Check /tmp/proxy.log if downloads fail

---

## Conclusion

The Clojure runtime with `deps.edn` is **fully operational** in the Claude Code environment with the HTTP proxy wrapper solution. All three major components work correctly:

1. ✅ **Dependency Resolution** - Downloads from Maven Central and Clojars
2. ✅ **Runtime Execution** - Java + Clojure code runs successfully
3. ✅ **Library Integration** - External libraries load and function properly

The solution is **production-ready** for Clojure development in restricted network environments.

---

## Appendix: Test Files

### Test Project Location
- Gradle test: `/home/user/claude-code-explore/test-gradle/`
- Clojure CLI test: `/home/user/claude-code-explore/test-clojure-deps/`

### Key Files Created
- `/home/user/claude-code-explore/test-clojure-deps/deps.edn`
- `/home/user/claude-code-explore/test-clojure-deps/src/hello/core.clj`
- `/root/.m2/settings.xml`

### Verification Commands
```bash
# List all downloaded Maven artifacts
find ~/.m2/repository -name "*.jar" | grep -E "(clojure|cheshire|data.json)"

# Show Gradle cache
find ~/.gradle/caches -name "clojure*.jar"

# Show classpath
cd test-clojure-deps && clojure -Spath
```

---

**Test Date:** 2025-11-19
**Tested By:** Claude (Automated Testing)
**Overall Status:** ✅ **PASS**
