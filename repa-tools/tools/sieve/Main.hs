
-- Split the rows in a CSV or TSV file into separate files based on 
-- the first field. See `Config.hs` for an example.
import Config
import Data.Repa.Flow                           as F
import Data.Repa.Array                          as A
import qualified Data.Repa.Flow.Default.IO      as D
import qualified Data.Repa.Flow.Generic         as G
import qualified Data.Repa.Flow.Generic.IO      as G
import System.Environment
import System.Directory
import System.FilePath
import System.IO
import Control.Monad
import Data.Maybe
import Data.Char
import Prelude                                  as P


main :: IO ()
main 
 = do   args    <- getArgs
        config  <- parseArgs args configZero

        mapM_ (pSieve config) 
         $ configInFiles config


pSieve :: Config -> FilePath -> IO ()
pSieve config fileIn
 = do   
        -- Stream the input file.
        let ext = takeExtension fileIn

        sIn     <-  G.project_i 0
                =<< (fromFiles' [fileIn]
                      $ (if | ext == ".tsv" -> D.sourceTSV
                            | ext == ".csv" -> D.sourceCSV
                            | otherwise     -> error $ "unknown format " ++ show ext))

        -- Flatten the stream of chunks into a stream of rows.
        sRows   <- G.unchunk_i sIn

        -- Sieve out rows into separate files based on the 
        -- first field in each row.
        let !dirOut     = fromMaybe "." $ configOutDir config
        createDirectoryIfMissing True dirOut

        let !arrC       = A.fromList U [',']
        let !arrNL      = A.fromList U ['\n']
        let sieve arr   
                = Just  ( dirOut </> A.toList (arr `index` 0)
                        , A.mapS F (fromIntegral . ord) 
                           $ A.concat U 
                           $ A.fromList B [ A.intercalate U arrC arr, arrNL])
            {-# INLINE sieve #-}

        oSieve  <- G.sieve_o sieve 
        G.drainS sRows oSieve
