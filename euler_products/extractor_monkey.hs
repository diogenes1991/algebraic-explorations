-- extractor_monkey.hs
--
-- Deliberately naive, line-by-line-ish translation of euler_product_extractor.frm.
-- Full polynomial expansion (no truncation, no log-space tricks) -- the point is
-- to mirror the FORM driver's control flow, not to be efficient.
--
-- Run:  runghc extractor_monkey.hs      (or: ghc -O2 extractor_monkey.hs && ./extractor_monkey)

module Main where

import qualified Data.Map.Strict as M
import Data.Map.Strict (Map)
import Data.List (intercalate)
import Control.Monad (foldM)

------------------------------------------------------------------------
-- Polynomials in q, as  power -> coefficient   (FORM's $-variables like $Num)
------------------------------------------------------------------------
type Poly = Map Int Integer

-- build from a list of (power, coeff), e.g.  poly [(0,1),(1,-1),(3,1)] = 1 - q + q^3
poly :: [(Int, Integer)] -> Poly
poly = M.filter (/= 0) . M.fromListWith (+)

pOne :: Poly
pOne = M.singleton 0 1

pAdd :: Poly -> Poly -> Poly
pAdd a b = M.filter (/= 0) (M.unionWith (+) a b)

pSub :: Poly -> Poly -> Poly          -- FORM: $Diff = $Num - ($Den)
pSub a b = pAdd a (M.map negate b)

pMul :: Poly -> Poly -> Poly          -- FORM: $Num = ($Num) * (factor)
pMul a b = M.filter (/= 0) $ M.fromListWith (+)
  [ (i + j, ci * cj) | (i, ci) <- M.toList a, (j, cj) <- M.toList b ]

-- (1 + s*q^p) ^ e   with s = +1 or -1 and e >= 0
factor :: Integer -> Int -> Integer -> Poly
factor s p e = go e
  where base   = poly [(0, 1), (p, s)]
        go 0   = pOne
        go n   = pMul base (go (n - 1))

-- FORM: #call LowestPower($Diff,q,$Pow)   (returns -1 for the zero polynomial)
lowestPower :: Poly -> Int
lowestPower d
  | M.null d  = -1
  | otherwise = fst (M.findMin d)

-- FORM: #call CoeffAt($Diff,q,$Pow,$Coeff)
coeffAt :: Poly -> Int -> Integer
coeffAt d k = M.findWithDefault 0 k d

------------------------------------------------------------------------
-- Accumulator: zeta argument -> exponent   (FORM's $Acc of Zeta(...) factors)
------------------------------------------------------------------------
type Zetas = Map Int Integer

mulZeta :: Zetas -> Int -> Integer -> Zetas   -- $Acc = $Acc * Zeta(arg)^e
mulZeta z arg e = M.filter (/= 0) (M.insertWith (+) arg e z)

renderZetas :: Zetas -> String
renderZetas z =
  let nums = [ (a, e)  | (a, e) <- M.toList z, e > 0 ]
      dens = [ (a, -e) | (a, e) <- M.toList z, e < 0 ]
      term (a, e) = "Zeta(" ++ show a ++ ")" ++ if e == 1 then "" else "^" ++ show e
      render xs = if null xs then "1" else intercalate "*" (map term xs)
  in render nums ++ " / (" ++ render dens ++ ")"

------------------------------------------------------------------------
-- The #do loop body
------------------------------------------------------------------------
data St = St { num :: Poly, acc :: Zetas }

-- Numerator / denominator for the sample function 1 / (n*phi(n))
num0, den :: Poly
num0 = poly [(0, 1), (1, -1),          (3, 1)]   -- 1 - q     + q^3
den  = poly [(0, 1), (1, -1), (2, -1), (3, 1)]   -- 1 - q - q^2 + q^3

step :: St -> Int -> IO St
step (St n a) i = do
  let d  = pSub n den            -- $Diff
      pw = lowestPower d         -- $Pow
      cf = coeffAt d pw          -- $Coeff
      (n', a', msg)
        | cf > 0    = ( pMul n (factor (-1) pw cf)                       -- *(1 - q^pw)^cf
                      , mulZeta a pw cf                                  -- *Zeta(pw)^cf
                      , "Positive Coefficient: " ++ show cf ++ " at power " ++ show pw )
        | otherwise = ( pMul n (factor 1 pw (negate cf))                -- *(1 + q^pw)^(-cf)
                      , mulZeta (mulZeta a (2 * pw) (negate cf)) pw cf   -- *(Zeta(2pw)/Zeta(pw))^(-cf)
                      , "Negative Coefficient: " ++ show cf ++ " at power " ++ show pw )
  putStrLn $ "shift " ++ show i ++ ": " ++ msg
  return (St n' a')

main :: IO ()
main = do
  final <- foldM step (St num0 M.empty) [1 .. 10]
  putStrLn ""
  putStrLn $ "Accumulator: " ++ renderZetas (acc final)
