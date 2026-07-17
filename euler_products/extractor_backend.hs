-- extractor_backend.hs
--
-- Machine-readable backend for the TeX generator (tex_reduction.py).
-- Reads three lines from stdin:
--     line 1: working order N (integer)
--     line 2: numerator pairs "power:coeff power:coeff ..."   e.g.  0:1 1:-1 3:1
--     line 3: denominator pairs, same format
-- and prints one line per extracted shift:
--     SHIFT <power> <coeff>
--
-- Same truncated-stream algorithm as extractor_fast.hs (kept in sync by hand for
-- now; a shared module is the obvious later refactor).
--
-- Run here:  echo "9\n0:1 1:-1 3:1\n0:1 1:-1 2:-1 3:1" | ghci -v0 extractor_backend.hs -e main

module Main where

import qualified Data.Map.Strict as M

type Series = [Integer]

seriesFrom :: Int -> [(Int, Integer)] -> Series
seriesFrom n pairs = [ M.findWithDefault 0 k m | k <- [0 .. n] ]
  where m = M.fromListWith (+) pairs

mulBinom :: Int -> Integer -> Series -> Series
mulBinom p c s = zipWith (+) s (replicate p 0 ++ map (c *) s)

mulBinomPow :: Int -> Integer -> Int -> Series -> Series
mulBinomPow p c e s = iterate (mulBinom p c) s !! e

extract :: Int -> Series -> Series -> [(Int, Integer)]
extract n num den = go 1 num
  where
    go k s
      | k > n     = []
      | cf == 0   = go (k + 1) s
      | otherwise = (k, cf) : go (k + 1) s'
      where
        cf     = s !! k - den !! k
        (c, e) = if cf > 0 then (-1, cf) else (1, negate cf)
        s'     = mulBinomPow k c (fromIntegral e) s

-- parse "power:coeff" tokens into (Int, Integer) pairs
parsePairs :: String -> [(Int, Integer)]
parsePairs = map tok . words
  where tok t = let (a, b) = break (== ':') t in (read a, read (drop 1 b))

main :: IO ()
main = do
  contents <- getContents
  let ls    = lines contents
      order = read (head ls) :: Int
      num   = seriesFrom order (parsePairs (ls !! 1))
      den   = seriesFrom order (parsePairs (ls !! 2))
  mapM_ (\(k, c) -> putStrLn ("SHIFT " ++ show k ++ " " ++ show c)) (extract order num den)
