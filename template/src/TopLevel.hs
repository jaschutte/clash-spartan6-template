
module TopLevel where

import Clash.Annotations.TH
import Clash.Prelude
import Clash.Explicit.Prelude (noReset)

timer ::
  ( HiddenClockResetEnable dom
  ) =>
  Signal dom (Unsigned 32)
timer = register 1 $ (satAdd SatWrap 1) <$> timer

leds ::
  ( HiddenClockResetEnable dom
  ) =>
  Signal dom (BitVector 8)
leds = pack . truncateB . flip rotate (-24) <$> timer

topEntity ::
  "clk" ::: Clock XilinxSystem ->
  "switch" ::: Signal XilinxSystem (BitVector 8) ->
  "led" ::: Signal XilinxSystem (BitVector 8)
topEntity clk _switch = withClockResetEnable clk noReset enableGen leds

makeTopEntity 'topEntity

