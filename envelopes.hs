{-# LANGUAGE FlexibleContexts #-}
module Envelopes    ( make_drums_env
                    , make_piano_env
                    , make_bass_env
                    , make_theme_env
--                    , make_magnus_env
                    , make_magnus_drums_env
                    , make_piano_echo_env
                    , wrap_sig 
                    ) where

import Control.Monad
import System.Random.MWC.Probability


import Csound.Base

import Rnd
import Tempo
import Utils

-- Priority of instruments (highest first)
-- drums
-- bass
-- piano
-- theme

wrap_sig s env = mul env s
--wrap_sig s env = at (\x -> mul x env) s

--mul_stereo :: Sig2 -> Sig2
--mul_stereo s = mul s

--wrap_stereo_sig s env = at (\x -> mul 

rv_bin n p get_time_bars gen = \waves ->
    liftM (get_time_bars . fromIntegral) $
        sample (binomial n p) gen

-- Drums
----------------------------------------------------------
        
drum_env_intro = 
    let length = secs_from_bars1 song_intro_bars_dbl
    in [1, length, 1]
    
drum_env_main gen = do
    let 
        rv_on = rv_bin
            8 0.85
            secs_from_bars1
            gen
            
        rv_off = rv_bin
            2 0.4
            secs_from_bars4
            gen
            
    make_trapezoid_waves_until
        (rv_on, 1)
        (\waves -> return 0)
        (rv_off, 0)
        $ secs_from_bars1 song_main_bars_dbl

drum_env_outro =
    let length = secs_from_bars1 song_outro_bars_dbl
    in [0, length, 0]

make_drums_env gen = do
    let env_intro = drum_env_intro
        env_outro = drum_env_outro
    env_main <- drum_env_main gen
    
    let env_song = slope_connect 
            env_intro (slope_connect env_main env_outro 0) 0
    
    return $ linseg $ map double env_song

-- Piano
----------------------------------------------------------

piano_env_intro gen = do
    let n = (floor $ song_intro_bars_dbl / 4)
    let p = 0.5
    on_step <- sample (binomial n p) gen
    
    let on_time = secs_from_bars4 $ fromIntegral on_step
        end_intro = secs_from_bars1 song_intro_bars_dbl
        len_a = on_time
        len_b = end_intro - on_time
    return $ [0, len_a, 0, 0, 1, len_b, 1]
    
piano_env_main gen = do
    let 
        rv_on = rv_bin
            8 0.85
            secs_from_bars2
            gen
            
        rv_off = rv_bin
            2 0.4
            secs_from_bars2
            gen
            
    make_trapezoid_waves_until
        (rv_on, 1)
        (\waves -> return 0)
        (rv_off, 0)
        $ secs_from_bars1 song_main_bars_dbl
        
piano_env_outro gen = do
    let n = (floor $ song_outro_bars_dbl / 2)
    let p = 0.65
    on_step <- sample (binomial n p) gen
    
    let on_time = secs_from_bars2 $ fromIntegral on_step
        end_intro = secs_from_bars1 song_intro_bars_dbl
        len_a = on_time
        len_fade = end_intro - on_time
    return $ [1, len_a, 1, len_fade, 0]
    
make_piano_env gen = do
    env_intro <- piano_env_intro gen
    env_outro <- piano_env_outro gen
    env_main <- piano_env_main gen
    
    let env_song = slope_connect 
            env_intro (slope_connect env_main env_outro 0) 0
    
    return $ linseg $ map double env_song
    
-- Bass
----------------------------------------------------------

bass_env_intro gen = do
    let n = (floor $ song_intro_bars_dbl / 4)
    let p = 0.35
    on_step <- sample (binomial n p) gen
    
    let on_time = secs_from_bars4 $ fromIntegral on_step
        end_intro = secs_from_bars1 song_intro_bars_dbl
        len_a = on_time
        len_b = max 0 (end_intro - on_time)
    return $ [0, len_a, 0, 0, 1, len_b, 1]

--bass_env_intro gen = do
--    let length = secs_from_bars1 song_intro_bars_dbl
--    return [1, length, 1]
    
bass_env_main gen = do
    let 
        rv_on = rv_bin
            8 0.75
            secs_from_bars2
            gen
            
        rv_off = rv_bin
            2 0.4
            secs_from_bars2
            gen
            
    make_trapezoid_waves_until
        (rv_on, 1)
        (\waves -> return 0)
        (rv_off, 0)
        $ secs_from_bars1 song_main_bars_dbl
        

bass_env_outro gen = do
    let n = (floor $ song_outro_bars_dbl / 2)
    let p = 0.65
    on_step <- sample (binomial n p) gen
    
    let on_time = secs_from_bars2 $ fromIntegral on_step
        end_intro = secs_from_bars1 song_intro_bars_dbl
        len_a = on_time
        len_b = end_intro - on_time
    return $ [1, len_a, 1, 0, 0, len_b, 0]        
        
        
make_bass_env gen = do
    env_intro <- bass_env_intro gen
    env_outro <- bass_env_outro gen
    env_main <- bass_env_main gen
    
    let env_song = slope_connect 
            env_intro (slope_connect env_main env_outro 0) 0
    
    return $ linseg $ map double env_song
    
-- Theme
----------------------------------------------------------

theme_env_intro =
    let length = secs_from_bars1 song_intro_bars_dbl
    in [0, length, 0]
    
    
theme_env_main gen = do
    let 
        rv_on = rv_bin
            4 0.8
            secs_from_bars4
            gen
            
        rv_off = rv_bin
            4 0.45
            secs_from_bars4
            gen
            
    make_trapezoid_waves_until
        (rv_on, 1)
        (\waves -> return 0)
        (rv_off, 0)
        $ secs_from_bars1 song_main_bars_dbl
        
theme_env_outro =
    let length = secs_from_bars1 song_outro_bars_dbl
    in [1, length, 1]
    
make_theme_env gen = do
    let env_intro = theme_env_intro
        env_outro = theme_env_outro
    env_main <- theme_env_main gen
    
    let env_song = slope_connect 
            env_intro (slope_connect env_main env_outro 0) 0
    
    return $ linseg $ map double env_song
            
-- Magnetic delay
----------------------------------------------------------

make_magnus_drums_env gen = do
    let 
        rv_on = rv_bin
            4 0.6
            sfb_double
            gen
            
        rv_off = rv_bin
            4 0.8
            secs_from_bars1
            gen
            
    segments <- make_trapezoid_waves_until
        (rv_off, 0)
        (\waves -> return 0.01)
        (rv_on, 1)
        $ secs_from_bars1 song_length_bars_dbl
    
    return $ linseg $ map double segments
    

-- Piano echo
----------------------------------------------------------

make_piano_echo_env gen = do
    let 
        rv_on = rv_bin
            2 0.6
            secs_from_bars1
            gen
            
        rv_off = rv_bin
            4 0.75
            secs_from_bars1
            gen
    
    segments <- make_trapezoid_waves_until
        (rv_off, 0)
        (\waves -> return 0.01)
        (rv_on, 1)
        $ secs_from_bars1 song_length_bars_dbl
    
    return $ linseg $ map double segments
    

--make_magnus_env gen (drums, piano) = do
--    drums_env <- make_magnus_drums_env gen
--    let drums_wrapped = at (\x 
--    --let drums_wrapped = wrap_sig drums_env drums
--    --return drums_wrapped