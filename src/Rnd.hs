module Rnd where

import Control.Monad
import Data.List
import Data.List.Split (chunksOf)
import System.Random.MWC.Probability

import Csound.Base

import Tempo
import Utils

-- Random choices from a list
---------------------------------------------------------------------

random_picks n choices gen = do
    let index_max = (length choices) - 1
    index_picks <- samples n (uniformR (0, index_max)) gen
    let picks = map (\i -> choices !! i) index_picks
    return $ picks
    
    
-- Stochastic trapezoid wave signals
---------------------------------------------------------------------

-- Creates a half trapezoid wave of the format
--           __             _
--   eg     /       or       \
--      ___/                  \_____
--
-- with the given heights and lengths for lines
-- a, b and the slope
make_trapezoid_wave_base
    (len_a, height_a)
    len_slope
    (len_b, height_b)
    = let 
        line_a = make_horizontal_line
            len_a height_a
        line_b = make_horizontal_line
            len_b height_b
      in
        slope_connect line_a line_b len_slope

        
-- Calculates the length of a list of numbers
-- representing a trapezoid waves signal in
-- linseg format
trapezoid_waves_length waves =
    let mask = cycle [0, 1]
        segment_lens = zipWith (*) waves mask
    in sum segment_lens

-- Fills waves with half trapezoid waves
-- until the length of the sequence of line
-- segments making up the wavesignal exceeds end
append_trapezoid_waves_base_until
    waves
    (rv_a, height_a)
    rv_slope
    (rv_b, height_b)
    end
    = do
        len_a <- rv_a waves
        len_s_ab <- rv_slope waves
        len_b <- rv_b waves

        len_s_wt <- rv_slope waves
        let 
            tail = make_trapezoid_wave_base
                (len_a, height_a)
                len_s_ab
                (len_b, height_b)
            waves' = slope_connect
                waves tail len_s_wt
                
        if end > trapezoid_waves_length waves'
        then
            append_trapezoid_waves_base_until
                waves'
                (rv_a, height_a)
                rv_slope
                (rv_b, height_b)
                end
        else
            return waves'

remove_last_segment waves = init $ init waves
            
cut_trapezoid_waves_at waves end =
    let len_waves = trapezoid_waves_length waves
    in 
        if len_waves > end
        then
            let waves' = remove_last_segment waves
                len_waves' = trapezoid_waves_length waves'
            in
                if len_waves' < end
                then
                    waves' ++ [end - len_waves', waves' !! (length waves' - 1)]
                else
                    cut_trapezoid_waves_at waves' end
        else
            waves                    

make_trapezoid_waves_until
    (rv_a, height_a)
    rv_slope
    (rv_b, height_b)
    end
    = do
        segments <- append_trapezoid_waves_base_until
            []
            (rv_a, height_a)
            rv_slope
            (rv_b, height_b)
            end
        return $ cut_trapezoid_waves_at segments end

