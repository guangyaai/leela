{-# LANGUAGE OverloadedStrings #-}
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

-- | The sole purpose of this module is to provide a string
-- represetation [mostly for testing/debug purposes/ of the Asm type
-- such as `parse . render == id`.
module DarkMatter.Data.Asm.Render
       ( render
       , renderFunction
       ) where

import qualified Data.ByteString.Char8 as B
import           DarkMatter.Data.Time
import           DarkMatter.Data.Asm.Types

renderPipeline :: [Function] -> B.ByteString
renderPipeline [] = ""
renderPipeline xs = " | " `B.append` (B.intercalate " | " (map renderFunction xs))

renderArithF :: ArithF -> B.ByteString
renderArithF f = case (f)
                      of Mul v -> myRender "*" v
                         Div v -> myRender "/" v
                         Add v -> myRender "+" v
                         Sub v -> myRender "-" v
  where myRender op (Left n)  = B.concat [B.pack $ show n, " ", op]
        myRender op (Right n) = B.concat [op, " ", B.pack $ show n]

renderTime :: Time -> B.ByteString
renderTime t = B.concat [ B.pack $ show $ seconds t
                        , "."
                        , B.pack $ show $ nseconds t
                        ]

renderFunction :: Function -> B.ByteString
renderFunction Mean           = "mean"
renderFunction Median         = "median"
renderFunction Maximum        = "maximum"
renderFunction Minimum        = "minimum"
renderFunction Count          = "count"
renderFunction Floor          = "floor"
renderFunction Ceil           = "ceil"
renderFunction Round          = "round"
renderFunction Truncate       = "truncate"
renderFunction Abs            = "abs"
renderFunction (Arithmetic f) = B.concat [ "("
                                         , renderArithF f
                                         , ")"
                                         ]
renderFunction (TimeWindow t) = B.concat [ "time_window "
                                         , renderTime t
                                         ]
renderFunction (Window n m)   = B.concat [ "window "
                                         , B.pack $ show n
                                         , " "
                                         , B.pack $ show m
                                         ]

render :: Asm -> B.ByteString
render (Free k)         = B.concat [ "free "
                                   , B.pack $ show k
                                   ]
render (Send k c v)     = B.concat [ "send "
                                   , B.pack $ show k
                                   , " "
                                   , renderTime c
                                   , " "
                                   , B.pack $ show v
                                   ]
render (Exec k f)       = B.concat [ "exec "
                                   , B.pack $ show k
                                   , " "
                                   , renderPipeline f
                                   ]
