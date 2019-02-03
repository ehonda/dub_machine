module Scale where

import Csound.Base

-- SCALE
---------------------------------------------------------------

freq_c0 = 16.35

just :: Int -> D
just i =
    let freqs = [ 1, 9/8, 5/4, 4/3, 3/2, 5/3, 15/8 ]
        (octave,step) = divMod (i-1) 7
    in  freq_c0 * 2 ^^ octave * (freqs !! step)

[c, d, e, f, g, a, b] = [1..7 :: Int]

note n o = n + 7 * o

-- CHORS
---------------------------------------------------------------

chord base = [base, base + 2, base + 4]