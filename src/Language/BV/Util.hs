{-# LANGUAGE BangPatterns, RecordWildCards #-}

module Language.BV.Util
  ( exprSize
  , programSize

  , partitions2
  , partitions3

  , whileM_
  ) where

import Language.BV.Types (BVProgram(..), BVExpr(..), BVFold(..))


exprSize :: BVExpr -> Int
exprSize !e = go e where
  go :: BVExpr -> Int
  go (If0 e0 e1 e2) = 1 + go e0 + go e1 + go e2
  go (Fold (BVFold { bvfLambda = (_larg0, _larg1, le0), ..})) =
      2 + go bvfArg + go bvfInit + go le0
  go (Op1 _op1 e0)    = 1 + go e0
  go (Op2 _op2 e0 e1) = 1 + go e0 + go e1
  go _e = 1

programSize :: BVProgram -> Int
programSize (BVProgram (_arg, e)) = 1 + exprSize e


partitions2 :: Int -> [(Int, Int)]
partitions2 i = [(j, k) | j <- [1..i], k <- [1..i], j + k == i]
{-# INLINE partitions2 #-}

partitions3 :: Int -> [(Int, Int, Int)]
partitions3 i = [ (j, k, l)
                | j <- [1..i], k <- [1..i], l <- [1..i], j + k + l == i
                ]
{-# INLINE partitions3 #-}

whileM_ :: (Monad m) => m Bool -> m a -> m ()
whileM_ p f = do
    x <- p
    if x
    then f >> whileM_ p f
    else return ()
{-# SPECIALIZE whileM_ :: IO Bool -> IO a -> IO () #-}
