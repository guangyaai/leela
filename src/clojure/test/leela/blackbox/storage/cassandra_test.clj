(ns leela.blackbox.storage.cassandra-test
  (:use     [clojure.test]
            [clojurewerkz.cassaforte.query]
            [clojurewerkz.cassaforte.embedded]
            [clojurewerkz.cassaforte.multi.cql])
  (:require [leela.blackbox.f :as f]
            [clojurewerkz.cassaforte.client :as client]
            [leela.blackbox.storage.cassandra :as storage]))

(defn storage-cleanup [f]
  (storage/with-session [cluster ["127.0.0.1"] "leela"]
    (storage/truncate-all cluster))
  (f))

(defmacro dbg[x] `(let [x# ~x] (println "dbg:" '~x "=" x#) x#))

(use-fixtures :each storage-cleanup)

(deftest test-cassandra-backend
  (storage/with-session [cluster ["127.0.0.1"] "leela"]

    (testing "getindex with no data"
      (is (= [] (storage/getindex cluster "0x00" 0))))

    (testing "getindex after putindex"
      (storage/putindex cluster "0x00" 0 "foobar")
      (is (= ["foobar"] (storage/getindex cluster "0x00" 0))))

    (testing "getindex after multiple putindex"
      (storage/putindex cluster "0x00" 1 "f")
      (storage/putindex cluster "0x00" 1 "o")
      (storage/putindex cluster "0x00" 1 "b")
      (storage/putindex cluster "0x00" 1 "a")
      (storage/putindex cluster "0x00" 1 "r")
      (is (= ["a" "b" "f" "o" "r"] (storage/getindex cluster "0x00" 1)) ))

    (testing "getindex pagination with no finish"
      (storage/putindex cluster "0x00" 2 "a0")
      (storage/putindex cluster "0x00" 2 "a1")
      (storage/putindex cluster "0x00" 2 "a2")
      (storage/with-limit 1
        (is (= ["a0"] (storage/getindex cluster "0x00" 2 "")))
        (is (= ["a1"] (storage/getindex cluster "0x00" 2 "a1")))
        (is (= ["a2"] (storage/getindex cluster "0x00" 2 "a2")))))

    (testing "getindex pagination with finish"
      (storage/putindex cluster "0x00" 2 "a0")
      (storage/putindex cluster "0x00" 2 "a1")
      (storage/putindex cluster "0x00" 2 "a2")
      (storage/with-limit 1
        (is (= ["a0"] (storage/getindex cluster "0x00" 2 "" "a1")))
        (is (= ["a1"] (storage/getindex cluster "0x00" 2 "a1" "a2")))))

    (testing "getlink with no data"
      (is (= [] (storage/getlink cluster "0x00" "0x"))))

    (testing "getlink after putlink"
      (storage/putlink cluster "0x00" "0x01")
      (storage/putlink cluster "0x00" "0x02")
      (storage/putlink cluster "0x00" "0x03")
      (is (= ["0x01" "0x02" "0x03"] (storage/getlink cluster "0x00" "0x"))))

    (testing "getlink pagination"
      (storage/putlink cluster "0x00" "0x01")
      (storage/putlink cluster "0x00" "0x02")
      (storage/putlink cluster "0x00" "0x03")
      (storage/with-limit 1
        (is (= ["0x01"] (storage/getlink cluster "0x00")))
        (is (= ["0x01"] (storage/getlink cluster "0x00" "0x01")))
        (is (= ["0x02"] (storage/getlink cluster "0x00" "0x02")))
        (is (= ["0x03"] (storage/getlink cluster "0x00" "0x03")))
        (is (= [] (storage/getlink cluster "0x00" "0x04")))))

    (testing "putattr time series"
      (storage/with-consistency :one
        (is (= [] (storage/putattr cluster "0x00" 0 "0x00")))
        (is (= [] (storage/putattr cluster "0x00" 1 "0x00")))
        (is (= [] (storage/putattr cluster "0x01" 0 "0x01")))
        (is (= [] (storage/putattr cluster "0x01" 1 "0x01"))))
      )

    (testing "getattr time series full slot"
      (storage/with-consistency :one
        (let [res (storage/getattr cluster "0x00")]
          (is (= "0x00" (f/bytes-to-hexstr (get res 0))))
          (is (= "0x00" (f/bytes-to-hexstr (get res 1))))
          )))

    (testing "delattr time series entry"
      (storage/with-consistency :one
          (is (= [] (storage/delattr cluster "0x00")))
          ))

    (testing "getlink after dellink"
      (storage/putlink cluster "0x00" "0x01")
      (storage/putlink cluster "0x00" "0x02")
      (storage/putlink cluster "0x00" "0x03")

      (storage/dellink cluster "0x00" "0x01")
      (storage/dellink cluster "0x00" "0x02")
      (storage/dellink cluster "0x00" "0x03")
      (is (= [] (storage/getlink cluster "0x00" "0x"))))

    (testing "getlink after dellink with no optional argument"
      (storage/putlink cluster "0x00" "0x01")
      (storage/putlink cluster "0x00" "0x02")
      (storage/putlink cluster "0x00" "0x03")

      (storage/dellink cluster "0x00")
      (is (= [] (storage/getlink cluster "0x00" "0x"))))
      ))
