{-# LANGUAGE OverloadedStrings #-}

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

module Leela.Data.Time
       ( Time
       , Date (..)
       , add
       , now
       , diff
       , seconds
       , dateTime
       , dateToInt
       , fromSeconds
       , fromDateTime
       ) where

import Data.Bits
import Data.Time
import Data.Time.Clock.POSIX

newtype Time = Time { unTime :: UTCTime }
             deriving (Show, Eq, Ord)

newtype Date = Date (Int, Int, Int)
             deriving (Show, Eq, Ord)

add :: NominalDiffTime -> Time -> Time
add increment (Time t) = Time (addUTCTime increment t)

seconds :: Time -> Double
seconds = realToFrac . utcTimeToPOSIXSeconds . unTime

dateTime :: Time -> (Date, Double)
dateTime (Time u) = let time                      = realToFrac $ utctDayTime u
                        (year, month, dayOfMonth) = toGregorian $ utctDay u
                    in (Date (fromIntegral $ year, month, dayOfMonth), time)

dateToInt :: Date -> Int
dateToInt (Date (y, m, d)) = (y `shiftL` 9) .|. (m `shiftL` 5) .|. d

diff :: Time -> Time -> Double
diff (Time a) (Time b) = realToFrac $ a `diffUTCTime` b

fromSeconds :: Double -> Time
fromSeconds = Time . posixSecondsToUTCTime . realToFrac

fromDateTime :: Date -> Double -> Time
fromDateTime date time = Time $ UTCTime (fromDate date) (realToFrac time)

fromDate :: Date -> Day
fromDate (Date (y, m, d)) = fromGregorian (fromIntegral y) m d

toDate :: Day -> Date
toDate day = let (year, month, dayOfMonth) = toGregorian day
             in Date (fromIntegral year, month, dayOfMonth)

now :: IO Time
now = fmap Time getCurrentTime

instance Enum Date where

  succ = toDate . succ . fromDate
  pred = toDate . pred . fromDate

  toEnum   = toDate . toEnum
  fromEnum = fromEnum . fromDate
