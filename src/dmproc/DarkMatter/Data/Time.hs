-- -*- mode: haskell; -*-
-- All Rights Reserved.
--
--    Licensed under the Apache License, Version 2.0 (the "License");
--    you may not use this file except in compliance with the License.
--    You may obtain a copy of the License at
--
--        http://www.apache.org/licenses/LICENSE-2.0
--
--    Unless required by applicable law or agreed to in writing, software
--    distributed under the License is distributed on an "AS IS" BASIS,
--    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--    See the License for the specific language governing permissions and
--    limitations under the License.

module DarkMatter.Data.Time
       ( Time
       , seconds
       , nseconds
       , toDouble
       , zero
       , mktime
       , diff
       , add
       ) where

newtype Time = Time { unTime :: (Int, Int) }
             deriving (Show, Eq, Ord)

seconds :: Time -> Int
seconds = fst . unTime

nseconds :: Time -> Int
nseconds = snd . unTime

toDouble :: (Fractional a) => Time -> a
toDouble t = let s = fromIntegral (seconds t)
                 n = fromIntegral (nseconds t)
             in s + n / nmax

mktime :: Int -> Int -> Time
mktime s n = let (s1, n1) = n `divMod` nmax
             in Time (s+s1, n1)
{-# INLINE mktime #-}

zero :: Time -> Bool
zero t = seconds t == 0 && nseconds t == 0

nmax :: (Num a) => a
nmax = 1000000000

diff :: Time -> Time -> Time
diff t0 t1 = let s0     = abs $ seconds t1 - seconds t0
                 (r, n) = fmap abs $ (nseconds t1 - nseconds t0) `quotRem` nmax
                 s      = abs $ s0 - r
             in mktime s n

add :: Time -> Time -> Time
add t0 t1 = mktime (seconds t0 + seconds t1) (nseconds t0 + nseconds t1)
