{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE AllowAmbiguousTypes #-}

-- | Eq properties
--
-- You will need @TypeApplications@ to use these.
module Test.Validity.Eq
    ( eqSpecOnValid
    , eqSpec
    , eqSpecOnArbitrary
    , eqSpecOnGen
    ) where

import Data.Data

import Data.GenValidity

import Test.Hspec
import Test.QuickCheck

import Test.Validity.Functions
import Test.Validity.Relations
import Test.Validity.Utils

eqTypeStr
    :: forall a.
       Typeable a
    => String
eqTypeStr = binRelStr @a "=="

neqTypeStr
    :: forall a.
       Typeable a
    => String
neqTypeStr = binRelStr @a "/="

-- | Standard test spec for properties of Eq instances for valid values
--
-- Example usage:
--
-- > eqSpecOnValid @Double
eqSpecOnValid
    :: forall a.
       (Show a, Eq a, Typeable a, GenValid a)
    => Spec
eqSpecOnValid = eqSpecOnGen @a genValid "valid"

-- | Standard test spec for properties of Eq instances for unchecked values
--
-- Example usage:
--
-- > eqSpec @Int
eqSpec
    :: forall a.
       (Show a, Eq a, Typeable a, GenUnchecked a)
    => Spec
eqSpec = eqSpecOnGen @a genUnchecked "unchecked"

-- | Standard test spec for properties of Eq instances for arbitrary values
--
-- Example usage:
--
-- > eqSpecOnArbitrary @Int
eqSpecOnArbitrary
    :: forall a.
       (Show a, Eq a, Typeable a, Arbitrary a)
    => Spec
eqSpecOnArbitrary = eqSpecOnGen @a arbitrary "arbitrary"

-- | Standard test spec for properties of Eq instances for values generated by a given generator (and name for that generator).
--
-- Example usage:
--
-- > eqSpecOnGen ((* 2) <$> genValid @Int) "even"
eqSpecOnGen
    :: forall a.
       (Show a, Eq a, Typeable a)
    => Gen a -> String -> Spec
eqSpecOnGen gen genname =
    parallel $ do
        let name = nameOf @a
            funeqstr = eqTypeStr @a
            funneqstr = neqTypeStr @a
            gen2 = (,) <$> gen <*> gen
            gen3 = (,,) <$> gen <*> gen <*> gen
        describe ("Eq " ++ name) $ do
            let eq = (==) @a
                neq = (/=) @a
            describe funeqstr $ do
                it
                    (unwords
                         [ "is reflexive for"
                         , "\"" ++ genname
                         , name ++ "\"" ++ "'s"
                         ]) $
                    reflexivityOnGen eq gen
                it
                    (unwords
                         [ "is symmetric for"
                         , "\"" ++ genname
                         , name ++ "\"" ++ "'s"
                         ]) $
                    symmetryOnGens eq gen2
                it
                    (unwords
                         [ "is transitive for"
                         , "\"" ++ genname
                         , name ++ "\"" ++ "'s"
                         ]) $
                    transitivityOnGens eq gen3
                it
                    (unwords
                         [ "is equivalent to (\\a b -> not $ a /= b) for"
                         , "\"" ++ genname
                         , name ++ "\"" ++ "'s"
                         ]) $
                    equivalentOnGens2 eq (\a b -> not $ a `neq` b) gen2
            describe funneqstr $ do
                it
                    (unwords
                         [ "is antireflexive for"
                         , "\"" ++ genname
                         , name ++ "\"" ++ "'s"
                         ]) $
                    antireflexivityOnGen neq gen
                it
                    (unwords
                         [ "is equivalent to (\\a b -> not $ a == b) for"
                         , "\"" ++ genname
                         , name ++ "\"" ++ "'s"
                         ]) $
                    equivalentOnGens2 neq (\a b -> not $ a `eq` b) gen2
