{-# LANGUAGE FlexibleInstances, DeriveDataTypeable #-}
-- |
-- Copyright   : (c) 2011, 2012 Benedikt Schmidt
-- License     : GPL v3 (see LICENSE)
-- 
-- Maintainer  : Benedikt Schmidt <beschmi@gmail.com>
--
-- Subterm rewriting rules.
module Term.SubtermRule (
      StRhs(..)
    , StRule(..)
    , rRuleToStRule
    , stRuleToRRule
    ) where

import Term.LTerm
import Term.Positions

-- | The righthand-side of a subterm rewrite rule.
--   Does not enforce that the term for RhsGround must be ground.
data StRhs = RhsGround LNTerm | RhsPosition Position
    deriving (Show,Ord,Eq)

-- | A subterm rewrite rule.
data StRule = StRule LNTerm StRhs
    deriving (Show,Ord,Eq)

-- | Convert a rewrite rule to a subterm rewrite rule if possible.
rRuleToStRule :: RRule LNTerm -> Maybe StRule
rRuleToStRule (lhs `RRule` rhs)
  | frees rhs == [] = Just $ StRule lhs (RhsGround rhs)
  | otherwise       = case findSubterm lhs [] of
                        []:_     -> Nothing  -- proper subterm required
                        pos:_    -> Just $ StRule lhs (RhsPosition (reverse pos))
                        []       -> Nothing
  where
    findSubterm t rpos | t == rhs  = [rpos]
    findSubterm (FApp _ args) rpos =
        concat $ zipWith (\t i -> findSubterm t (i:rpos)) args [0..]
    findSubterm (Lit _)         _  = []

-- | Convert a subterm rewrite rule to a rewrite rule.
stRuleToRRule :: StRule -> RRule LNTerm
stRuleToRRule (StRule lhs rhs) = case rhs of
                                     RhsGround t   -> lhs `RRule` t
                                     RhsPosition p -> lhs `RRule` (lhs >* p)

{-

test:
xorRules == map (stRuleToRRule . fromJust .  rRuleToStRule) xorRules

-}