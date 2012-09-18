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

-- | The sole datatype that the core deals with.
module DarkMatter.Data.Event
       ( Event(time, val)
       , temporal
       , update
       ) where

import DarkMatter.Data.Time

-- | The event, the sole datatype [from user perspective] that the
-- core deals with.
data Event = Temporal { time :: Time
                      , val  :: Double
                      }

temporal :: Time -> Double -> Event
temporal = Temporal

update :: (Time -> Time) -> (Double -> Double) -> Event -> Event
update f g e = e { time = f (time e)
                 , val  = g (val e)
                 }
