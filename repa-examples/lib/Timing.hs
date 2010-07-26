module Timing
	(time)
where
import GHC.Exts	(traceEvent)
import System.CPUTime
import System.Time


-- Time -----------------------------------------------------------------------
data Time 
	= Time 
	{ cpu_time  :: Integer
        , wall_time :: Integer
        }

zipT :: (Integer -> Integer -> Integer) -> Time -> Time -> Time
zipT f (Time cpu1 wall1) (Time cpu2 wall2) 
	= Time (f cpu1 cpu2) (f wall1 wall2)

minus :: Time -> Time -> Time
minus = zipT (-)

plus :: Time -> Time -> Time
plus = zipT (+)


-- TimeUnit -------------------------------------------------------------------
type TimeUnit 
	= Integer -> Integer

picoseconds :: TimeUnit
picoseconds = id

milliseconds :: TimeUnit
milliseconds n = n `div` 1000000000

seconds :: TimeUnit
seconds n = n `div` 1000000000000

cpuTime :: TimeUnit -> Time -> Integer
cpuTime f = f . cpu_time

wallTime :: TimeUnit -> Time -> Integer
wallTime f = f . wall_time


-- | Get the current time.
getTime :: IO Time
getTime =
  do
    cpu          <- getCPUTime
    TOD sec pico <- getClockTime
    return $ Time cpu (pico + sec * 1000000000000)


-- | Show a time as a string, in milliseconds.
showTime :: Time -> String
showTime t = (show $ wallTime milliseconds t)
          ++ "/"
          ++ (show $ cpuTime  milliseconds t)


-- Timing benchmarks ----------------------------------------------------------
time :: IO a -> IO (a, Time)
{-# NOINLINE time #-}
time p = do
           start <- getTime
           traceEvent "Bench.Benchmark: start timing"
           x     <- p
           traceEvent "Bench.Benchmark: finished timing"
           end   <- getTime
           return (x, end `minus` start)
