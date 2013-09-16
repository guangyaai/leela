(ns leela.blackbox.blackbox
  (:use     [clojure.tools.cli :only [cli]])
  (:import  [org.zeromq ZMQ])
  (:require [leela.blackbox.network.zmqserver :as zserver]
            [leela.blackbox.storage.cassandra :as storage])
  (:gen-class))

(defn seed-assoc-fn [opts k v]
  (assoc opts k
         (case k
           :seed (if-let [oldval (get opts k)]
                   (conj oldval v)
                   [v])
           v)))

(defn -main [& args]
  (let [[options args banner] (cli args
                                   ["--help" "this message"
                                    :default false
                                    :flag true]
                                   ["--keyspace" "the keyspace to use"
                                    :default "leela"]
                                   ["--creat" "creates the keyspace if it does not exist"
                                    :default false
                                    :flag true]
                                   ["--seed" "cassandra seed nodes (may be used multiple times)"
                                    :default "localhost"
                                    :assoc-fn seed-assoc-fn]
                                   ["--endpoint" "the address to bind to"
                                    :default "tcp://*:4080"])]
    (when (:help options)
      (println banner)
      (java.lang.System/exit 0))

    (zserver/server-start (zserver/create-session (:seed options) (:keyspace options) (:creat options))
                          (ZMQ/context 1)
                          (conj options {:capabilities 64 :queue-size 32}))))