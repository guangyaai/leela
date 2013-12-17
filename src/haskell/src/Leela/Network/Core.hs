{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE BangPatterns      #-}
{-# LANGUAGE TupleSections     #-}
{-# LANGUAGE Rank2Types        #-}

-- Copyright 2013 (c) Diego Souza <dsouza@c0d3.xxx>
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

module Leela.Network.Core
       ( CoreServer ()
       , new
       , process
       ) where

import qualified Data.Map as M
import           Data.Maybe
import           Leela.Logger
import           Leela.Helpers
import           Control.Monad
import           Leela.Data.LQL
import qualified Data.ByteString as B
import           Leela.Data.Graph (Matcher (..) , Result)
import qualified Leela.Data.Graph as G
import           Control.Exception
import           Control.Concurrent
import           Leela.Data.Journal
import           Leela.Data.QDevice
import           Leela.Data.Excepts
import           Leela.Data.LQL.Comp
import           Leela.Data.Namespace
import           Leela.Storage.Backend
import           Control.Concurrent.STM
import           Leela.Network.Protocol

data CoreServer = CoreServer { fdseq  :: TVar FH
                             , fdlist :: TVar (M.Map (B.ByteString, FH) (Int, Device Reply))
                             }

data Stream a = Chunk a
              | EOF

ttl :: Int
ttl = 30

whenChunk :: (Stream a -> IO ()) -> Stream a -> IO ()
whenChunk _ EOF   = return ()
whenChunk f chunk = f chunk

new :: IO CoreServer
new = do
  state <- makeState
  _     <- forkIO (forever (sleep 1 >> rungc (fdlist state)))
  return state
    where
      makeState = atomically $
        liftM2 CoreServer (newTVar 0) (newTVar M.empty)

rungc :: (Ord k, Show k) => TVar (M.Map k (Int, Device a)) -> IO ()
rungc tvar = atomically kill >>= mapM_ burry
    where
      partition acc []       = acc
      partition (a, b) ((k, (tick, dev)):xs)
        | tick == 0 = partition ((k, dev) : a, b) xs
        | otherwise = partition (a, (k, (tick - 1, dev)) : b) xs

      kill = do
        (dead, alive) <- fmap (partition ([], []) . M.toList) (readTVar tvar)
        writeTVar tvar (M.fromList alive)
        return dead

      burry (k, dev) = do
        lwarn Network $ printf "closing/purging unused channel: %s" (show k)
        atomically $ close dev

nextfd :: CoreServer -> STM FH
nextfd srv = do
  curr <- readTVar $ fdseq srv
  writeTVar (fdseq srv) (curr + 1)
  return curr

makeFD :: CoreServer -> User -> IO (FH, Device Reply)
makeFD srv (User u) = atomically $ do
  ctrl <- control
  fd   <- nextfd srv
  dev  <- open ctrl pageSize
  modifyTVar (fdlist srv) (M.insert (u, fd) (ttl, dev))
  return (fd, dev)

selectFD :: CoreServer -> (User, FH) -> IO (Maybe (Device Reply))
selectFD srv ((User u), fh) = atomically $ do
  let resetTTL _ (_, dev) = Just (ttl, dev)
  (mdev, newv) <- fmap (M.updateLookupWithKey resetTTL (u, fh)) (readTVar (fdlist srv))
  writeTVar (fdlist srv) newv
  return (fmap snd mdev)

closeFD :: CoreServer -> Bool -> (User, FH) -> IO ()
closeFD srv nowait ((User u), fh) = do
  ldebug Network (printf "closing fd %s" (show k))
  atomically $ do
    db   <- readTVar (fdlist srv)
    case (M.lookup k db) of
      Nothing       -> return ()
      Just (_, dev) -> do unless nowait (linger dev)
                          writeTVar (fdlist srv) (M.delete k db)
                          close dev
    where
      k = (u, fh)

store :: (GraphBackend m) => m -> Journal -> IO ()
store storage (PutNode n k g)    = putName n k g storage
store storage (PutLabel g lbls)  = putLabel g lbls storage
store storage (PutLink g lnks)   = putLink g lnks storage

fetch :: (GraphBackend m, HasControl ctrl) => ctrl -> m -> Matcher r -> (Stream r -> IO ()) -> IO ()
fetch ctrl storage selector callback0 =
  case selector of
    ByLabel k l f  -> do dev <- openIO ctrl 2
                         getLabel dev k (glob l) storage
                         load1 k Nothing f dev
    ByNode k f     -> do dev <- openIO ctrl 2
                         getLabel dev k (All Nothing) storage
                         load1 k Nothing f dev
    ByEdge a l b f -> do dev <- openIO ctrl 2
                         getLabel dev a (glob l) storage
                         load1 a (Just b) f dev
    where
      load1 a mb f dev = do
        mlabels <- fmap (maybe (Left $ SomeException SystemExcept) id) (devreadIO dev)
        case mlabels of
          Left e            -> throwIO e
          Right (0, [])     -> callback0 (Chunk $ f [])
          Right (_, [])     -> callback0 EOF
          Right (_, labels) -> do
            let keys = M.fromList $ map (\l -> (G.labelRef a l, l)) labels
            subdev <- openIO ctrl 4
            case mb of
              Nothing -> getLink subdev (M.keys keys) storage
              Just b  -> getEdge subdev (map (, b) (M.keys keys)) storage
            load2 subdev $ \guidNodes ->
              let labelNodes = map (\(lk, g) -> (g, fromJust $ M.lookup lk keys)) guidNodes
              in unless (null labelNodes) (callback0 $ Chunk (f labelNodes))
            load1 a mb f dev

      load2 subdev callback = do
        mnodes <- fmap (maybe (Left $ SomeException SystemExcept) id) (devreadIO subdev)
        case mnodes of
          Left e           -> throwIO e
          Right (_, [])    -> callback []
          Right (_, nodes) -> callback nodes >> load2 subdev callback

eval :: (GraphBackend m, HasControl ctrl) => ctrl -> m -> Result r -> (Stream r -> IO ()) -> IO ()
eval _ _ (G.Fail 404 _) _         = throwIO NotFoundExcept
eval _ _ (G.Fail code msg) _      = do lwarn Network (printf "eval has failed: %d/%s" code msg)
                                       throwIO SystemExcept
eval ctrl storage (G.Load f g) callback =
  catch (fetch ctrl storage f $ \chunk ->
           case chunk of
             EOF     -> callback EOF
             Chunk r -> eval ctrl storage r (whenChunk callback))
        (\e -> case e of
                 NotFoundExcept -> eval ctrl storage g callback
                 _              -> throwIO e)
eval _ storage (G.Done r j) callback    = do
  mapM_ (store storage) j
  callback (Chunk r)
  callback EOF

evalLQL :: (GraphBackend m) => m -> Device Reply -> [LQL] -> IO ()
evalLQL _ dev []     = devwriteIO dev (Last Nothing)
evalLQL storage dev (x:xs) =
  case x of
    PathStmt _ cursor -> navigate cursor (evalLQL storage dev xs)
    MakeStmt _ stmt   ->
      eval dev storage stmt $ \chunk ->
        case chunk of
          EOF -> evalLQL storage dev xs
          _   -> return ()
    NameStmt u g      -> do
      (nsTree, name) <- getName g storage
      let (nTree, nsUser) = underive nsTree
          (nUser, _)      = underive nsUser
      if (nsUser `isDerivedOf` (root u))
        then devwriteIO dev (Item $ Name g nUser nTree name) >> evalLQL storage dev xs
        else devwriteIO dev (Fail 403 Nothing)
    KillStmt _ a mb   -> do
      unlink a mb storage
      evalLQL storage dev xs
    where
      navigate G.Tail cont                   = cont
      navigate (G.Need r) cont               = eval dev storage r $ \chunk ->
        case chunk of
          EOF          -> cont
          Chunk cursor -> navigate cursor (return ())
      navigate (G.Item path links next) cont = do
        devwriteIO dev (Item $ makeList $ map (Path . (:path)) links)
        navigate next cont
      navigate (G.Head g) cont               =
        eval dev storage (G.loadNode1 g Nothing Nothing G.done) $ \chunk ->
          case chunk of
            EOF          -> cont
            Chunk links  -> devwriteIO dev (Item $ makeList $ map (Path . (:[])) links)

evalFinalizer :: FH -> Device Reply -> Either SomeException () -> IO ()
evalFinalizer chan dev (Left e)  = do
  devwriteIO dev (encodeE e) `catch` ignore
  closeIO dev
  linfo Network $ printf "[fd: %s] session terminated with failure: %s" (show chan) (show e)
evalFinalizer chan dev (Right _)   = do
  closeIO dev
  linfo Network $ printf "[fd: %s] session terminated successfully" (show chan)

process :: (GraphBackend m) => m -> CoreServer -> Query -> IO Reply
process storage srv (Begin sig msg) =
  case (chkloads (parseLQL (namespaceFrom sig)) msg) of
    Left _      -> return $ Fail 400 (Just "syntax error")
    Right stmts -> do
      (fh, dev) <- makeFD srv (sigUser sig)
      lnotice Network (printf "BEGIN %s %d" (show msg) fh)
      _         <- forkFinally (evalLQL storage dev stmts) (evalFinalizer fh dev)
      return $ Done fh
process _ srv (Fetch sig fh) = do
  let channel = (sigUser sig, fh)
  ldebug Network (printf "FETCH %d" fh)
  mdev <- selectFD srv channel
  case mdev of
    Nothing  -> return $ Fail 404 $ Just "no such channel"
    Just dev -> do
      blocks <- blkreadIO 32 dev
      case blocks of
        [] -> closeIO dev >> return (Last Nothing)
        _  -> let answer = foldr1 reduce blocks
              in when (isEOF answer) (closeIO dev) >> return answer
process _ srv (Close nowait sig fh) = do
  lnotice Network (printf "CLOSE %d" fh)
  closeFD srv nowait (sigUser sig, fh)
  return $ Last Nothing
