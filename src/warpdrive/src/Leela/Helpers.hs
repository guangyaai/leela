-- Copyright 2014 (c) Diego Souza <dsouza@c0d3.xxx>
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

module Leela.Helpers where

import Leela.Logger
import Control.Monad
import Control.Exception
import Control.Concurrent

forkSupervised :: Logger -> IO Bool -> String -> IO () -> IO ()
forkSupervised syslog check name io =
  void $ forkIO (superviseWith syslog check name io)

forkSupervised_ :: Logger -> String -> IO () -> IO ()
forkSupervised_ syslog name io =
  void $ forkIO (supervise syslog name io)

superviseWith :: Logger -> IO Bool -> String -> IO () -> IO ()
superviseWith syslog check name io =
  (foreverWith check io) `catch` restart
    where
      restart (SomeException e)= do
        threadDelay 500000
        warning syslog (printf "supervised thread [%s] has died: %s" name (show e))
        superviseWith syslog check name io

supervise :: Logger -> String -> IO () -> IO ()
supervise syslog name io = do
  (forever io) `catch` restart
    where
      restart (SomeException e)= do
        threadDelay 500000
        warning syslog (printf "supervised thread [%s] has died: %s" name (show e))
        supervise syslog name io

ignore :: SomeException -> IO ()
ignore _ = return ()

foreverWith :: IO Bool -> IO () -> IO ()
foreverWith check io = do
  ok <- check
  when ok (io >> foreverWith check io)

sleep :: Int -> IO ()
sleep s = threadDelay (s * 1000000)

intoChunks :: Int -> [a] -> [[a]]
intoChunks _ [] = []
intoChunks n l  = let (a, rest) = splitAt n l
                  in a : intoChunks n rest
