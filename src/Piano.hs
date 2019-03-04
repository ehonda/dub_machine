module Piano where

import Csound.Base
import Csound.Patch

import Rnd
import Scale
import Tempo


-- PIANO
---------------------------------------------------------------
piano_inst = sawOrgan


-- Length: 2 Bars
-- Type: Base Figure
piano_fig1 = 
    [ s_pause (1/4)
    , s_chord (1/16) (note a 4) 
    , s_pause (7/16)
    , s_chord (1/16) (note a 4) 
    , s_pause (7/16)
    , s_chord (1/16) (note e 4)
    , s_pause (7/16)
    , s_chord (1/16) (note e 4) 
    , s_pause (3/16)
    ]
    
-- Length: 2 Bars
-- Type: Base Figure octave down
piano_fig2 = 
    [ s_pause (1/4)
    , s_chord (1/16) (note a 3) 
    , s_pause (7/16)
    , s_chord (1/16) (note a 3) 
    , s_pause (7/16)
    , s_chord (1/16) (note e 3)
    , s_pause (7/16)
    , s_chord (1/16) (note e 3) 
    , s_pause (3/16)
    ]
    
-- Length: 2 Bars
-- Type: Base Figure decorated
piano_fig3 =
    [ s_note (1/16) (note a 4)
    , s_pause (1/16)
    , s_chord (1/16) (note a 4)
    , s_pause (3/16)
    , s_chord (1/16) (note a 4)
    , s_pause (5/16)
    , s_chord (1/16) (note a 4)
    , s_pause (3/16)
    , s_note (1/16) (note e 4)
    , s_pause (1/16)
    , s_chord (1/16) (note e 4)
    , s_pause (3/16)
    , s_chord (1/16) (note e 4)
    , s_pause (3/16)
    , s_note (1/16) (note e 4)
    , s_pause (1/16)
    , s_chord (1/16) (note e 4)
    , s_pause (1/16)
    , s_note (1/16) (note g 4)
    , s_note (1/16) (note e 4)
    ]

make_piano_sig gen = do
    let choices = map ((loopBy 4) . mel) [piano_fig1, piano_fig2, piano_fig3]
    figure_picks <- random_picks 8 choices gen
    let score = mel figure_picks
    return $ mul 0.5 $ mix $ atSco piano_inst score
