module Effects 
    ( make_drums_delay 
    , make_piano_echo_sig
    , make_theme_hall_sig
    ) where

import System.Random.MWC.Probability

import Csound.Base

import Envelopes
import Tempo

-- Magnus
-----------------------------------------------

eff_delay :: Sig2 -> Sig2
--eff_delay s = magnus
--    1
--    (sig (secs_from_note_value (1/4)))
--    0.8
--    1
--    0.5
--    0.1
--    s
eff_delay s = pingPong
    (sig (secs_from_note_value (3/16)))
    0.6
    1
    s

--make_magnus_drums_sig :: GenIO -> SE Sig2 -> SE Sig2
envelope_delay_drums :: GenIO -> SE Sig2 -> IO (SE Sig2)
envelope_delay_drums gen drums = do
    env <- make_magnus_drums_env gen
    return $ at (\x -> wrap_sig env x) drums
--    return $ at (\x -> eff_magnus x) wrapped_drums
--
make_drums_delay :: GenIO -> SE Sig2 -> IO (SE Sig2)
make_drums_delay gen drums = do
    env_drums <- envelope_delay_drums gen drums
    return $ mul 0.6 $ at (\x -> eff_delay x) env_drums

-- Piano echo
-----------------------------------------------

--eff_piano_echo :: Sig -> Sig2
--eff_piano_echo s = at (\x -> echo
--    (secs_from_note_value (1/3))
--    0.6
--    x) s

--make_piano_echo_sig :: GenIO -> Sig2 -> Sig2
make_piano_echo_sig gen piano = do
    env <- make_piano_echo_env gen
    let wrapped_piano = wrap_sig env $ toMono piano
    return $ mul 0.45 $ cave 0.15
        $ echo
        (secs_from_note_value (1/3))
        0.8
        wrapped_piano
        
        
-- Theme hall
-----------------------------------------------

make_theme_hall_sig theme =
    mul 0.4 $ smallHall2 theme