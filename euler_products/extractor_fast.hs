-- extractor_fast.hs
--
-- Efficient cousin of extractor_monkey.hs.  Same algorithm and same result, but
-- instead of multiplying out dense polynomials (the "monkey" version builds the
-- full product Num*(1-q^2)*(1-q^3)*... and its degree balloons), this keeps the
-- numerator as a *coefficient stream truncated at a working order N* and folds in
-- each new factor as a cheap, sparse update.  You only ever compute coefficients
-- up to the order you actually trust -- exactly the "expand just enough" idea.
--
-- Run (this environment):  ghci -v0 extractor_fast.hs -e main
--        REPL:             ghci extractor_fast.hs   then  > main
--        locally:          runghc extractor_fast.hs
--
--------------------------------------------------------------------------------
-- Haskell refresher (it's been a while), for the idioms used below:
--
--   * [Integer]           a list; we use it as "coefficient k lives at index k".
--   * xs !! k             index into a list (0-based). O(k); fine at this scale.
--   * zipWith f a b       combine two lists elementwise with f, stopping at the
--                         shorter one.  zipWith (+) [1,2,3] [10,20] = [11,22].
--                         We lean on the "stops at the shorter one" to truncate.
--   * replicate n x       a list of n copies of x.  replicate 2 0 = [0,0].
--   * map (c*) xs         multiply every element by c.
--   * [ e | k <- [0..n] ] list comprehension; build a list by ranging k over 0..n.
--   * foldl' step z xs    strict left fold: thread an accumulator z through xs.
--   * Data.Map.Strict     a balanced-tree dictionary; M.insertWith (+) k v adds
--                         v into key k (summing on collision).  Used for the
--                         zeta accumulator: argument -> net exponent.
--   * where / guards      `f x | cond = ... | otherwise = ...  where y = ...`
--                         guards pick a branch; `where` names shared subexpressions
--                         (evaluated lazily, so unused ones cost nothing).
--------------------------------------------------------------------------------

module Main where

import qualified Data.Map.Strict as M
import Data.Map.Strict (Map)
import Data.List (foldl', intercalate)

--------------------------------------------------------------------------------
-- Power series in q, truncated at the working order N.
--
-- A Series is just a list of coefficients of length N+1, where element k is the
-- coefficient of q^k.  Everything downstream silently drops orders above N; that
-- truncation is the whole efficiency trick.
--------------------------------------------------------------------------------
type Series = [Integer]

-- Build a length-(N+1) series from sparse (power, coeff) pairs, zero-filled.
--   seriesFrom 4 [(0,1),(1,-1),(3,1)]  ==  [1,-1,0,1,0]   (i.e. 1 - q + q^3)
seriesFrom :: Int -> [(Int, Integer)] -> Series
seriesFrom n pairs = [ M.findWithDefault 0 k m | k <- [0 .. n] ]
  where m = M.fromListWith (+) pairs   -- collapse duplicate powers by summing

-- Multiply a series by the binomial (1 + c*q^p), truncated back to length N+1.
--
-- Math:  [(1 + c q^p) * s]_k = s_k + c * s_{k-p}.
-- Code:  add s to a copy of s that is shifted up by p slots (prepend p zeros)
--        and scaled by c.  zipWith (+) stops at the length of s, which is what
--        performs the truncation for free.  This is O(N) -- no dense convolution.
mulBinom :: Int -> Integer -> Series -> Series
mulBinom p c s = zipWith (+) s (replicate p 0 ++ map (c *) s)

-- Multiply by (1 + c*q^p)^e for e >= 0, by iterating mulBinom e times.
-- (iterate f x) is [x, f x, f (f x), ...]; !! e grabs the e-th, i.e. f applied e times.
mulBinomPow :: Int -> Integer -> Int -> Series -> Series
mulBinomPow p c e s = iterate (mulBinom p c) s !! e

--------------------------------------------------------------------------------
-- The extraction: sweep orders k = 1, 2, ..., N.
--
-- Invariant: before examining order k, the numerator already agrees with the
-- denominator at every order < k (we cancelled them on the way up).  So the
-- residual coefficient at order k is  cf = num_k - den_k.
--
--   * cf == 0 : nothing to do, advance to k+1.
--   * cf  > 0 : fold in (1 - q^k)^cf   [drives num_k down onto den_k]
--   * cf  < 0 : fold in (1 + q^k)^(-cf) [the "1+" branch; drives num_k up]
--
-- Folding a factor at power k changes only orders >= k, so lower orders stay
-- cancelled and the next nonzero residual is strictly higher up -- which is why
-- a single upward sweep suffices.  We return the ordered list of (power, coeff).
--------------------------------------------------------------------------------
extract :: Int -> Series -> Series -> [(Int, Integer)]
extract n num den = go 1 num
  where
    go k s
      | k > n     = []
      | cf == 0   = go (k + 1) s              -- residual already 0 here
      | otherwise = (k, cf) : go (k + 1) s'   -- record the shift, carry updated series
      where
        cf     = s !! k - den !! k            -- residual coefficient at order k
        (c, e) = if cf > 0 then (-1, cf) else (1, negate cf)  -- (1 - q^k) vs (1 + q^k)
        s'     = mulBinomPow k c (fromIntegral e) s

--------------------------------------------------------------------------------
-- Turn the (power, coeff) shifts into a product of zeta values.
--
-- In this single-q toy, Zeta(k) stands for 1/(1-q^k), and (1+q^k) = Zeta(k)/Zeta(2k).
-- Working out B's contribution per shift (B = 1 / product of the folded factors):
--
--   cf > 0  (factor (1 - q^k)^cf) : contributes Zeta(k)^cf
--   cf < 0  (factor (1 + q^k)^-cf): contributes Zeta(k)^cf * Zeta(2k)^(-cf)
--
-- We track argument -> NET exponent in a Map, so a later shift can cancel an
-- earlier zeta (e.g. a "1+q^8" emits Zeta(16), a later "1+q^16" removes it).
--------------------------------------------------------------------------------
type Zetas = Map Int Integer

toZetas :: [(Int, Integer)] -> Zetas
toZetas = M.filter (/= 0) . foldl' step M.empty
  where
    step z (k, cf)
      | cf > 0    = bump z k cf
      | otherwise = bump (bump z (2 * k) (negate cf)) k cf
    bump z arg e = M.insertWith (+) arg e z

renderZetas :: Zetas -> String
renderZetas z = render numer ++ " / (" ++ render denom ++ ")"
  where
    numer = [ (a, e)      | (a, e) <- M.toList z, e > 0 ]
    denom = [ (a, negate e) | (a, e) <- M.toList z, e < 0 ]
    term (a, e) = "Zeta(" ++ show a ++ ")" ++ if e == 1 then "" else "^" ++ show e
    render xs = if null xs then "1" else intercalate "*" (map term xs)

--------------------------------------------------------------------------------
-- Driver.  workingOrder N is the q-truncation: raise it to extract further into
-- the (infinite) product.  Every factor whose power is <= N is found exactly,
-- because order-k coefficients depend only on coefficients up to k.
--------------------------------------------------------------------------------
workingOrder :: Int
workingOrder = 50

num0, den0 :: [(Int, Integer)]
num0 = [(0, 1), (1, -1),          (3, 1)]   -- 1 - q     + q^3
den0 = [(0, 1), (1, -1), (2, -1), (3, 1)]   -- 1 - q - q^2 + q^3   (for 1/(n*phi(n)))

main :: IO ()
main = do
  let num    = seriesFrom workingOrder num0
      den    = seriesFrom workingOrder den0
      shifts = extract workingOrder num den
      zetas  = toZetas shifts
  putStrLn $ "working order (q-truncation): " ++ show workingOrder
  mapM_ (\(k, cf) -> putStrLn $ "  shift at power " ++ show k ++ ", coeff " ++ show cf) shifts
  putStrLn ""
  putStrLn $ "Accumulator: " ++ renderZetas zetas
