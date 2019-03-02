module Theme where

import Csound.Base
import Csound.Patch

import Rnd
import Scale
import Tempo


-- THEME
---------------------------------------------------------------
--theme_inst = robotVowel maleA
--theme_inst = simpleMarimba
--theme_inst = black
--theme_inst = soloSharc shTrumpetBach
--theme_inst = sharcOrgan shFlute

--theme_inst = phasingLead
theme_inst = dafunkLead


-- Length: 4 Bars
-- Type: Theme
theme = 
    [ s_note (1/8) (note b 3)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note c 4)
    , s_pause (1/8)
    , s_note (1/8) (note c 4)
    , s_pause (1/8)
    , s_note (1/8) (note e 4)
    , s_pause (1/8)
    , s_note (1/8) (note b 3)
    , s_pause (1/8)
    , s_note (1/4) (note b 3)
    , s_pause (1/4)
    , s_note (1/8) (note e 4)
    , s_note (1/8) (note d 4)
    
    , s_note (1/4) (note b 3)
    , s_note (1/8) (note c 4)
    , s_pause (1/8)
    , s_note (1/8) (note c 4)
    , s_pause (1/8)
    , s_note (1/8) (note e 4)
    , s_pause (1/8)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note a 3)
    , s_note (1/4) (note b 3)
    , s_pause (1/8)
    , s_note (1/8) (note e 4)
    , s_pause (1/8)
    , s_note (1/8) (note d 4)
    ]
    
-- Length: 4 Bars
-- Type: Variation theme
theme_variation_1 =
    [ s_note (1/8) (note a 3)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note c 4)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note c 4)
    , s_pause (1/8)
    , s_note (1/8) (note e 4)
    , s_note (1/4) (note a 3)
    , s_note (1/8) (note a 3)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note a 3)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note d 4)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note a 3)
    , s_note (1/4) (note b 3)
    , s_note (1/8) (note c 4)
    , s_note (1/8) (note b 3)
    , s_note (1/8) (note c 4)
    , s_pause (1/8)
    , s_note (1/8) (note e 4)
    , s_note (5/8) (note a 3)
    , s_pause (1/2)
    ]

make_theme_sig gen = do
    let choices = map ((loopBy 2) . mel) [theme, theme_variation_1]
    figure_picks <- random_picks 8 choices gen
    let score = mel figure_picks
    return $ mul 1 $ mix $ atSco theme_inst score    
