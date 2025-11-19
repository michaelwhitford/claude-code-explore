(ns simple.core)

(defn -main
  "A minimal Clojure application"
  [& args]
  (println "Hello from Clojure!")
  (println "Setup is working correctly.")
  (println (str "Clojure version: " (clojure-version))))
