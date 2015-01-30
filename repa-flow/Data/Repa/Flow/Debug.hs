{-# LANGUAGE OverlappingInstances, TypeSynonymInstances, FlexibleInstances #-}
module Data.Repa.Flow.Debug
        ( Nicer         (..)
        , Presentable   (..)
        , more
        , moren
        , moret)
where
import Data.Repa.Nice.Present
import Data.Repa.Nice.Tabulate
import Data.Repa.Nice
import Data.Repa.Flow                   hiding (next)
import qualified Data.Repa.Array        as A
import Control.Monad
import Data.List                        as L
import Data.Text                        as T
import Prelude                          as P
#include "repa-stream.h"


-- | Given a source index and a length, pull enough chunks from the source
--   to build a list of the requested length, and discard the remaining 
--   elements in the final chunk.
--  
--   * This function is intended for interactive debugging.
--     If you want to retain the rest of the final chunk then use `head_i`.
--
more    :: (Windowable l a, A.Index l ~ Int)
        => Int          -- ^ Source index.
        -> Int          -- ^ Number of elements to show.
        -> Sources l a
        -> IO (Maybe [a])
more ix len s
        = liftM (liftM fst) $ head_i ix len s
{-# INLINE more #-}


-- | Like `more`, but convert the result to a nice representation.
moren   :: (A.Windowable l a, A.Index l ~ Int, Nicer a)
        => Int          -- ^ Source index.
        -> Int          -- ^ Number of elements to show.
        -> Sources l a
        -> IO (Maybe [Nice a])
moren ix len s
        = liftM (liftM (L.map nice . fst)) $ head_i ix len s
{-# INLINE moren #-}


-- | Like `more`, but print results in tabular form to the console.
moret   :: ( A.Windowable l a, A.Index l ~ Int
           , Nicer [a], Presentable (Nice [a]))
        => Int          -- ^ Source index.
        -> Int          -- ^ Number of elements to show.
        -> Sources l a
        -> IO ()

moret ix len s
 = do   Just (vals, _) <- head_i ix len s
        putStrLn $ T.unpack $ tabulate $ nice vals
{-# NOINLINE moret #-}

