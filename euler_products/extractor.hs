{-# LANGUAGE BangPatterns #-}
-- Term-by-term extraction of B_p(x) = NUM(x)/DEN(x) into a product of
-- (1 - p^l x^u)^gamma factors, matching Euler's zeta identities.
--
-- p-polynomials are sparse maps: power-of-p -> integer coefficient.
-- Series in x are plain lists of p-polynomials, index = power of x.

import qualified Data.Map.Strict as M
import Data.List (foldl')
import System.CPUTime
import Text.Printf (printf)

type PPoly  = M.Map Int Integer
type Series = [PPoly]                    -- length N+1, index k = coeff of x^k

pZero, pOne :: PPoly
pZero = M.empty
pOne  = M.singleton 0 1

pAdd :: PPoly -> PPoly -> PPoly
pAdd a b = M.filter (/= 0) (M.unionWith (+) a b)

pMul :: PPoly -> PPoly -> PPoly
pMul a b = M.filter (/= 0) $ M.fromListWith (+)
  [ (i + j, ca * cb) | (i, ca) <- M.toList a, (j, cb) <- M.toList b ]

seriesMulTrunc :: Int -> Series -> Series -> Series
seriesMulTrunc n a b =
  [ foldl' pAdd pZero [ pMul (a !! i) (b !! (k - i)) | i <- [0 .. k] ] | k <- [0 .. n] ]

-- Invert a series with constant term exactly 1 (over the ring Z[p]).
-- Fails (returns Nothing) if the constant term isn't the unit 1.
seriesInvert :: Int -> Series -> Maybe Series
seriesInvert n a
  | a !! 0 /= pOne = Nothing
  | otherwise      = Just (go [pOne])
  where
    go acc
      | length acc > n = reverse (take (n+1) (reverse acc))
      | otherwise =
          let m = length acc
              s = foldl' pAdd pZero
                    [ pMul (a !! i) (acc !! (m - i)) | i <- [1 .. m] ]
              next = M.map negate s
          in go (acc ++ [next])

-- exact integer binomial coefficient C(g,k) for any integer g (can be negative)
binom :: Integer -> Int -> Integer
binom g k = product [ g - fromIntegral i | i <- [0 .. k-1] ] `div` product [1 .. toInteger k]

-- series for (1 - p^l x^u)^c, truncated to order n
factorSeries :: Int -> Int -> Int -> Integer -> Series
factorSeries n u l c = [ term k | k <- [0 .. n] ]
  where
    term k
      | k `mod` u /= 0 = pZero
      | otherwise =
          let j = k `div` u
          in if j == 0 then pOne
             else let co = binom c j * (if odd j then -1 else 1)
                  in if co == 0 then pZero else M.singleton (l * j) co

-- At each order u, the residual coefficient c(p) = sum_l c_l p^l is a plain
-- integer polynomial: extract ONE factor (1-p^l x^u)^{-c_l} per nonzero term,
-- all at this same u, before moving to u+1.
extract :: Int -> Series -> [(Int,Int,Integer)]
extract n res0 = go 1 [] res0
  where
    go u acc res
      | u > n = reverse acc
      | otherwise =
          let terms = M.toList (res !! u)
          in if null terms
             then go (u+1) acc res
             else let (acc', res') = foldl' step (acc, res) terms
                      step (a, r) (l, c0) =
                        let gamma  = negate c0
                            factor = factorSeries n u l c0
                        in ((u,l,gamma):a, seriesMulTrunc n r factor)
                  in go (u+1) acc' res'

mkSeries :: Int -> [(Int, PPoly)] -> Series
mkSeries n assoc = [ M.findWithDefault pZero k m | k <- [0 .. n] ]
  where m = M.fromList assoc

poly :: [(Int,Integer)] -> PPoly
poly = M.filter (/=0) . M.fromList

bitLen :: Integer -> Int
bitLen x = length (show (abs x))   -- decimal digit count, good enough as a size proxy

runCase :: Bool -> String -> Int -> Series -> Series -> IO ()
runCase verbose name n num den = do
  putStrLn $ "=== " ++ name ++ " (order N=" ++ show n ++ ") ==="
  case seriesInvert n den of
    Nothing -> putStrLn "  DEN(0) != 1 in Z[p]: cannot invert termwise in the polynomial ring. STOP."
    Just denInv -> do
      let r = seriesMulTrunc n num denInv
          factors = extract n r
      if verbose
        then mapM_ (\(u,l,g) -> printf "  u=%2d  l=%3d  gamma=%4d   -> (1 - p^%d x^%d)^%d\n" u l g l u g) factors
        else do
          printf "  factors extracted: %d\n" (length factors)
          let maxDigits = maximum (0 : [ bitLen g | (_,_,g) <- factors ])
          printf "  max |gamma| decimal digits: %d\n" maxDigits
          case factors of
            [] -> return ()
            _  -> let (u,l,g) = last factors
                  in printf "  last: u=%d l=%d gamma=%d\n" u l g
  putStrLn ""

main :: IO ()
main = do
  let n = 60   -- benchmark order
      verbose = False
      num1 = mkSeries n [ (0, pOne), (1, poly [(0,1),(1,-2)]) ]
      den1 = mkSeries n [ (0, pOne), (1, poly [(2,-1)]) ]
      num2 = mkSeries n [ (0, poly [(2,1),(3,-2),(4,1)]), (1, poly [(0,-1),(1,2)]) ]
      den2 = mkSeries n [ (0, poly [(2,1),(3,-2),(4,1)]), (1, poly [(0,-1),(1,2),(2,-1)]) ]
  t0 <- getCPUTime
  runCase verbose "phi^2(n)      [Mathar 3.78/3.79 test]" n num1 den1
  runCase verbose "1/phi(n)^2    [our target]"             n num2 den2
  t1 <- getCPUTime
  printf "CPU time: %.4f s\n" (fromIntegral (t1 - t0) / (10^12) :: Double)
