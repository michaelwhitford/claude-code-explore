(ns hello.core
  (:require [clojure.data.json :as json]
            [cheshire.core :as cheshire]))

(defn -main
  "A simple Clojure application to test deps.edn and runtime"
  [& args]
  (println "=" 60)
  (println "Clojure Runtime Test with deps.edn")
  (println "=" 60)
  (println)

  ;; Test basic Clojure functionality
  (println "1. Basic Clojure:")
  (println "   (+ 1 2 3 4 5) =>" (+ 1 2 3 4 5))
  (println "   (map inc [1 2 3]) =>" (map inc [1 2 3]))
  (println)

  ;; Test clojure.data.json
  (println "2. Testing clojure.data.json:")
  (let [data {:name "Claude" :type "AI Assistant" :version 1.0}
        json-str (json/write-str data)]
    (println "   Original data:" data)
    (println "   JSON string:" json-str)
    (println "   Parsed back:" (json/read-str json-str :key-fn keyword)))
  (println)

  ;; Test cheshire
  (println "3. Testing cheshire (faster JSON library):")
  (let [data {:framework "deps.edn"
              :language "Clojure"
              :features ["simple" "powerful" "Maven compatible"]
              :works? true}
        json-str (cheshire/generate-string data {:pretty true})]
    (println "   Generated pretty JSON:")
    (println json-str)
    (println "   Parsed back:" (cheshire/parse-string json-str true)))
  (println)

  (println "=" 60)
  (println "All tests passed! Clojure runtime is working perfectly.")
  (println "Dependencies from Maven Central and Clojars were resolved.")
  (println "=" 60))
