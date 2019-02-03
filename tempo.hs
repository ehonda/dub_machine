{-# LANGUAGE GADTs #-}
module Tempo where

import Csound.Base

import Scale

----------------------------------------
-- TEMPO

-- Constants
------------------------------------------------------
bpm_double = 130
bpm :: D
bpm = double bpm_double

bps_double = bpm_double / 60
bps :: D
bps = double bps_double

beat_length_double = 1/4
beat_length :: D
beat_length = double beat_length_double

bar_length_int :: Int
bar_length_int = 4

bar_length_double :: Double
bar_length_double = 4
bar_length :: D
bar_length = double bar_length_double    -- 4/4-Takt

drum_raster :: D
drum_raster = 16


song_length_bars_int :: Int
song_length_bars_int = 64
song_length_bars_dbl :: Double
song_length_bars_dbl = fromIntegral song_length_bars_int

song_intro_bars_int :: Int
song_intro_bars_int = 16
song_intro_bars_dbl :: Double
song_intro_bars_dbl = fromIntegral song_intro_bars_int

song_main_bars_int :: Int
song_main_bars_int = 32
song_main_bars_dbl :: Double
song_main_bars_dbl = fromIntegral song_main_bars_int

song_outro_bars_int :: Int
song_outro_bars_int = 16
song_outro_bars_dbl :: Double
song_outro_bars_dbl = fromIntegral song_outro_bars_int





-- Time conversion functions
------------------------------------------------------

secs_from_beats beats = beats/bps
sfb beats = secs_from_beats beats

sfb_double beats = beats/bps_double

secs_from_note_value nv = sfb $ nv / beat_length

-- Time conversion from different steps
secs_from_bars step = sfb_double . (*) (step * bar_length_double)
secs_from_bars1 = secs_from_bars 1
secs_from_bars2 = secs_from_bars 2
secs_from_bars4 = secs_from_bars 4

-- Timed note functions
------------------------------------------------------

-- Beat note, time is counted in bars
b_note beats note = str (sig (secs_from_beats beats)) $ temp (1, just note)
b_pause beats = rest (sig (secs_from_beats beats))

-- Score note, time is counted in note value
s_note nv note = str (sig (secs_from_note_value nv)) $ temp (1, just note)
s_pause nv = rest (sig (secs_from_note_value nv)) 

-- Chord note, time is counted in note value
s_chord nv base = har $ map (s_note nv) $ chord base

 