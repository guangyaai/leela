{-# LANGUAGE TupleSections #-}
{-# LANGUAGE BangPatterns  #-}

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

module Leela.Storage.Backend.ZMQ
    ( ZMQBackend ()
    , zmqbackend
    ) where

import Leela.Logger
import Data.ByteString (ByteString)
import Leela.Data.Types
import Control.Exception
import Leela.HZMQ.Dealer
import Leela.Data.Excepts
import Leela.Storage.Graph
import Leela.Storage.Backend.ZMQ.Protocol

data ZMQBackend = ZMQBackend { dealer :: Dealer }

zmqbackend :: Dealer -> ZMQBackend
zmqbackend = ZMQBackend

recv :: Maybe [ByteString] -> Reply
recv Nothing    = FailMsg 500
recv (Just msg) = decode msg

internalError :: IO a
internalError = do
  lerror Storage "error communicating with the storage backend"
  throwIO SystemExcept

send :: Dealer -> Query -> IO Reply
send pool req = fmap recv (request pool (encode req))

send_ :: Dealer -> Query -> IO ()
send_ pool req = do
  reply <- send pool req
  case reply of
    DoneMsg -> return ()
    _       -> internalError

instance AttrBackend ZMQBackend where

  putAttr _ []    = return ()
  putAttr m attrs = send_ (dealer m) (MsgPutAttr $ map setIndexing attrs)
      where setIndexing (g, a, v, o) = (g, a, v, setOpt Indexing o)

  putTAttr _ []    = return ()
  putTAttr m attrs = send_ (dealer m) (MsgPutTAttr $ map setIndexing attrs)
      where setIndexing (g, a, t, v, o) = (g, a, t, v, setOpt Indexing o)

  getAttr m a k   = do
    reply <- send (dealer m) (MsgGetAttr a k)
    case reply of
      KAttrMsg v  -> return (Just v)
      FailMsg 404 -> return Nothing
      _           -> internalError

  getTAttr m g a time limit = do
    reply <- send (dealer m) (MsgGetTAttr g a time limit)
    case reply of
      TAttrMsg v  -> return v
      FailMsg 404 -> return []
      _           -> internalError

  listAttr m g page limit = do
    reply <- send (dealer m) (MsgListAttr g page limit)
    case reply of
      NAttrMsg xs -> return xs
      _           -> internalError

  listTAttr m g page limit = do
    reply <- send (dealer m) (MsgListTAttr g page limit)
    case reply of
      NAttrMsg xs -> return xs
      _           -> internalError

  delAttr _ []    = return ()
  delAttr m attrs = send_ (dealer m) (MsgDelAttr attrs)

instance GraphBackend ZMQBackend where

  getName m g = do
    reply <- send (dealer m) (MsgGetName g)
    case reply of
      NameMsg u t n _ -> return (u, t, n)
      FailMsg 404     -> throwIO NotFoundExcept
      _               -> internalError

  getGUID m u t n = do
   reply <- send (dealer m) (MsgGetGUID u t n)
   case reply of
     NameMsg _ _ _ g -> return (Just g)
     FailMsg 404     -> return Nothing
     _               -> internalError

  putName m u t n = do
    reply <- send (dealer m) (MsgPutName u t n)
    case reply of
      NameMsg _ _ _ g -> return g
      _               -> internalError

  getLabel m g page limit = do
    reply <- send (dealer m) (MsgGetLabel g page limit)
    case reply of
      LabelMsg xs -> return xs
      _           -> internalError

  putLabel _ []     = return ()
  putLabel m labels = send_ (dealer m) (MsgPutLabel labels)

  hasLink m a l b = do
    reply <- send (dealer m) (MsgHasLink a l b)
    case reply of
      LinkMsg [] -> return False
      LinkMsg _  -> return True
      _          -> internalError

  getLink m a l page limit = do
    reply <- send (dealer m) (MsgGetLink a l page limit)
    case reply of
      LinkMsg xs -> return xs
      _          -> internalError

  putLink _ []    = return ()
  putLink m links = send_ (dealer m) (MsgPutLink links)

  unlink _ []    = return ()
  unlink m links = send_ (dealer m) (MsgUnlink links)

  remove m a = send_ (dealer m) (MsgDelete a)
