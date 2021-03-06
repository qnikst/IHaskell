{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeSynonymInstances #-}

{-# OPTIONS_GHC -fno-warn-orphans  #-}

module IHaskell.Display.Widgets.Float.BoundedFloatRange.FloatRangeSlider
  ( -- * The FloatRangeSlider Widget
    FloatRangeSlider
    -- * Constructor
  , mkFloatRangeSlider
  ) where

-- To keep `cabal repl` happy when running from the ihaskell repo
import           Prelude

import           Control.Monad (void)
import           Data.Aeson
import           Data.IORef (newIORef)
import qualified Data.Scientific as Sci
import qualified Data.Vector as V
import           Data.Vinyl (Rec(..), (<+>))

import           IHaskell.Display
import           IHaskell.Eval.Widgets
import           IHaskell.IPython.Message.UUID as U

import           IHaskell.Display.Widgets.Types
import           IHaskell.Display.Widgets.Common

-- | 'FloatRangeSlider' represents an FloatRangeSlider widget from IPython.html.widgets.
type FloatRangeSlider = IPythonWidget 'FloatRangeSliderType

-- | Create a new widget
mkFloatRangeSlider :: IO FloatRangeSlider
mkFloatRangeSlider = do
  -- Default properties, with a random uuid
  wid <- U.random

  let boundedFloatAttrs = defaultBoundedFloatRangeWidget "FloatSliderView" "FloatSliderModel"
      sliderAttrs = (Orientation =:: HorizontalOrientation)
                    :& (ShowRange =:: True)
                    :& (ReadOut =:: True)
                    :& (SliderColor =:: "")
                    :& RNil
      widgetState = WidgetState $ boundedFloatAttrs <+> sliderAttrs

  stateIO <- newIORef widgetState

  let widget = IPythonWidget wid stateIO

  -- Open a comm for this widget, and store it in the kernel state
  widgetSendOpen widget $ toJSON widgetState

  -- Return the widget
  return widget

instance IHaskellDisplay FloatRangeSlider where
  display b = do
    widgetSendView b
    return $ Display []

instance IHaskellWidget FloatRangeSlider where
  getCommUUID = uuid
  comm widget val _ =
    case nestedObjectLookup val ["sync_data", "value"] of
      Just (Array values) ->
        case map (\(Number x) -> Sci.toRealFloat x) $ V.toList values of
          [x, y] -> do
            void $ setField' widget FloatPairValue (x, y)
            triggerChange widget
          _ -> pure ()
      _ -> pure ()
