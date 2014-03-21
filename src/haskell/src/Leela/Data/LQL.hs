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

module Leela.Data.LQL
    ( Using (..)
    , LQL (..)
    ) where

import Leela.Data.Types

data Using = Using { uUser :: User
                   , uTree :: Tree
                   }
           deriving (Eq)

data LQL = StatStmt
         | PathStmt (Matcher, [(GUID -> Matcher)])
         | KAttrGetStmt GUID Attr [Option]
         | TAttrGetStmt GUID Attr TimeRange [Option]
         | KAttrListStmt GUID (Mode Attr)
         | TAttrListStmt GUID (Mode Attr)
         | NameStmt Using GUID
         | GUIDStmt Using Node
         | AlterStmt [Journal]
