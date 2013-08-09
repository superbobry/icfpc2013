module Language.BV.Simplifier
  ( simplify
  ) where

import Language.BV.Eval (evalExpr)
import Language.BV.Types

-- Transformations:
--
-- not (not e)             = e
-- (or e 0)  = (or 0 e)    = e
-- (and e e)               = e
-- (or e e)                = e
-- (xor e e)               = 0
-- (plus e 0) = (plus 0 e) = e
-- (shr4 (shr4 (shr4 (shr4 e)))) = (shr16 e)
-- (shr1 (shr1 (shr1 (shr1 e)))) = (shr4 e)
-- (or (not e1) (not e2))  = (not (and e1 e2))
-- (and (not e1) (not e2)) = (not (or e1 e2))
-- (if e0 e1 e1)           = e1

simplify :: BVExpr -> Either BVExpr BVExpr
simplify (Op1 Not (Op1 Not e))   = Right e
simplify (Op2 Or e Zero)         = Right e
simplify (Op2 Or Zero e)         = Right e
simplify (Op2 And e0 e1) | e0 == e1 = Right e0
simplify (Op2 Or e0 e1)  | e0 == e1 = Right e0
simplify (Op2 Xor e0 e1) | e0 == e1 = Right Zero
simplify (Op2 Plus e Zero)       = Right e
simplify (Op2 Plus Zero e)       = Right e
simplify (Op1 Shr4 (Op1 Shr4 (Op1 Shr4 (Op1 Shr4 e)))) = Right (Op1 Shr16 e)
simplify (Op1 Shr1 (Op1 Shr1 (Op1 Shr1 (Op1 Shr1 e)))) = Right (Op1 Shr4 e)
simplify (Op2 And (Op1 Not e0) (Op1 Not e1)) = Right (Op1 Not (Op2 And e0 e1))
simplify (Op2 Or (Op1 Not e0) (Op1 Not e1))  = Right (Op1 Not (Op2 Or e0 e1))
simplify (If0 _e0 e1 e2) | e1 == e2 = Right e1
simplify e = mix e

mix :: BVExpr -> Either BVExpr BVExpr
mix (If0 Zero e1 _e2) = Right e1
mix (If0 One _e1 e2)  = Right e2
mix e =
    if isClosed e
    then case evalExpr e [] of
        0    -> Right Zero
        1    -> Right One
        _res ->
            -- Note(superbobry): we can also express constants other than
            -- 0 or 1 as terms.
            Left e
    else Left e

isClosed :: BVExpr -> Bool
isClosed Zero = True
isClosed One  = True
isClosed (Id _id) = False
isClosed (If0 e0 e1 e2)  = isClosed e0 && isClosed e1 && isClosed e2
isClosed (Fold (BVFold { bvfLambda = (_larg0, _larg1, le) })) = isClosed le
isClosed (Op1 _op e0)    = isClosed e0
isClosed (Op2 _op e0 e1) = isClosed e0 && isClosed e1
