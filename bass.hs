module Bass where

import Csound.Base
import Csound.Patch

import Rnd
import Scale
import Tempo


-- BASS
---------------------------------------------------------------
--bass_inst = simpleBass
--bass_inst = pwBass
bass_inst = hammondOrganm

o = 1

-- Length: 2 Bars
-- Type: Bass base figure
bass_fig1 =
    [ s_note (1/8) (note b o)
    , s_pause (1/8)
    , s_note (1/4) (note c (o+1))
    , s_pause (1/4)
    , s_note (1/8) (note e (o+1))
    , s_note (1/8) (note a o)
    , s_note (1/8) (note b o)
    , s_note (1/8) (note d (o+1))
    , s_note (1/4) (note b o)
    , s_note (1/8) (note f (o+1))
    , s_note (1/8) (note g (o+1))
    , s_note (1/4) (note e (o+1))
    ]

-- Length: 2 Bars
-- Type: Variation slow
bass_fig2 =
    [ s_note (1/8) (note b o)
    , s_note (1/8) (note b o)
    , s_note (1/2) (note c (o+1))
    , s_note (1/8) (note e (o+1))
    , s_note (1/8) (note a o)
    , s_note (1/8) (note b (o-1))
    , s_note (1/8) (note b o)
    , s_note (1/2) (note b o)
    , s_note (1/8) (note e (o+1))
    , s_note (1/8) (note d (o+1))
    ]

    
make_bass_sig gen = do
    let choices = map ((loopBy 4) . mel) [bass_fig1, bass_fig2]
    figure_picks <- random_picks 8 choices gen
    let score = mel figure_picks
    return $ mul 0.8 $ mix $ atSco bass_inst score

    
    
    
    
    
    
    
-- Length: 2 Bars
-- Type: Bass base figure
--bass_fig1 =
--    [ s_note (1/8) (note b 1)
--    , s_pause (1/8)
--    , s_note (1/4) (note c 2)
--    , s_pause (1/4)
--    , s_note (1/8) (note e 2)
--    , s_note (1/8) (note a 1)
--    , s_note (1/8) (note b 1)
--    , s_note (1/8) (note d 2)
--    , s_note (1/4) (note b 1)
--    , s_note (1/8) (note f 2)
--    , s_note (1/8) (note g 2)
--    , s_note (1/4) (note e 2)
--    ]
--
---- Length: 2 Bars
---- Type: Variation slow
--bass_fig2 =
--    [ s_note (1/8) (note b 1)
--    , s_note (1/8) (note b 1)
--    , s_note (1/2) (note c 2)
--    , s_note (1/8) (note e 2)
--    , s_note (1/8) (note a 1)
--    , s_note (1/8) (note b 0)
--    , s_note (1/8) (note b 1)
--    , s_note (1/2) (note b 1)
--    , s_note (1/8) (note e 2)
--    , s_note (1/8) (note d 2)
--    ]
