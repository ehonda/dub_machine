import Control.Monad
import System.Random.MWC.Probability

import Csound.Base
import Csound.Patch
import Csound.Catalog.Drum.Tr808 as Tr
import Csound.Catalog.Drum.Hm as Hm
import Csound.Sam

import Effects
import Envelopes
import Instruments
import Scale
import Rnd
import Tempo
import Utils
    
-- MAIN
-- ###################################################################

main = do
  final_sig <- compose
  
  -- dac final_sig

  writeSnd "out.wav" final_sig
  let audio = wav "out.wav"
  dac $ runSam (sig bpm) audio
  
compose = do
    gen <- createSystemRandom
    
    -- Instrument Signals
    drums_raw <- make_drum_machine_sig gen
    piano_raw <- make_piano_sig gen
    bass_raw <- make_bass_sig gen
    theme_raw <- make_theme_sig gen
       
    drums_env <- make_drums_env gen
    piano_env <- make_piano_env gen
    bass_env <- make_bass_env gen
    theme_env <- make_theme_env gen
    
    
    
    let 
        drums_sig = at (\x -> wrap_sig drums_env x) drums_raw
        piano_sig = at (\x -> mul 0.5 (wrap_sig piano_env x)) piano_raw
        bass_sig = at (\x -> mul 0.5 (wrap_sig bass_env x)) bass_raw
        theme_sig = at (\x -> mul 0.5 (wrap_sig theme_env x)) theme_raw

    -- Effect signals
    magnus_sig <- make_drums_delay gen drums_sig
        
    let
        sigs = [piano_sig, bass_sig, theme_sig]
        final_sig = at (\x -> combine (sigs ++ [x])) 
            (mul 0.5 (drums_sig + magnus_sig))

    return final_sig

