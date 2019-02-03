module Drums where

import Csound.Base
import Csound.Catalog.Drum.Tr808 as Tr
import Csound.Sam

import Tempo

-- SAMPLES WITH EFFECTS
---------------------------------------------------------------

-- Snare
--------------------------------------------
sn_phasy :: Sig2 -> Sig2
sn_phasy s = flan
    0.5
    0.9
    0.008
    0.73
    s

sn_tort :: Sig2 -> Sig2
sn_tort s = tort1 s

eff_sn :: Sam -> Sam
eff_sn sn =
    let sn_t = at (\x -> sn_tort x) sn
    in at (\x -> sn_phasy x) sn_t

    
-- Closed hi hat
--------------------------------------------
chh_crusher :: Sig2 -> Sig2
--chh_crusher s = crusher
--    0
--    0.005
--    s
chh_crusher = id
    
chh_phasy :: Sig2 -> Sig2
chh_phasy s = phasy
    0.01
    0.9
    0.5
    0.84
    s
    
eff_chh :: Sam -> Sam
eff_chh chh = 
    let
        chh_c = at (\x -> chh_crusher x) chh
        chh_p = at (\x -> chh_phasy x) chh_c
    in mul 0.65 chh_p


-- DRUM MACHINE
-- Raster: 16 Beats per bar
---------------------------------------------------------------

-- Length: 1 Bar
-- Type: Steppers base
make_drums_base_pattern =
    let d_chh = eff_chh $ pat [2] Tr.chh
        d_bd = pat [4] Tr.bd
        d_sn = eff_sn $ del 8 $ pat [16] Tr.sn
    in sum [ d_chh, d_bd, d_sn ]
    
-- Length: 1 Bar
-- Type: Steppers fill 1
make_drums_fill_pattern_1 =
    let d_chh = eff_chh $ pat [ 2, 2, 2, 1, 2, 7 ] Tr.chh
        d_ohh = del 2 $ pat [7] Tr.ohh
        d_sn = eff_sn $ del 14 $ pat [1] Tr.sn
        d_con = mul 4 $ del 4 $ pat [2, 3] $ Tr.hcon
    in sum [ d_chh, d_ohh, d_sn, d_con ]

-- Length: 1 Bar
-- Type: Steppers fill 2
make_drums_fill_pattern_2 =
    let d_chh = eff_chh $ pat [16] Tr.chh
        d_cym = pat [8] Tr.cym
        d_sn = eff_sn $ pat [3] Tr.sn
        d_bd = pat [1,1,12] Tr.bd
    in sum [ d_chh, d_cym, d_sn, d_bd ]

-- Length: 1 Bar
-- Type: Steppers fill 3 (all random)
make_drums_fill_pattern_3 =
    pickBy 2 
        [ (1/14, Tr.bd)
        , (1/14, eff_sn Tr.sn)
        , (1/14, Tr.ohh)
        , (1/14, eff_chh Tr.chh)
        , (1/14, Tr.htom)
        , (1/14, Tr.mtom)
        , (1/14, Tr.ltom)
        , (1/14, Tr.cym)
        , (1/14, Tr.cl)
        , (1/14, Tr.rim)
        , (1/14, Tr.mar)
        , (1/14, Tr.hcon)
        , (1/14, Tr.mcon)
        , (1/14, Tr.lcon)
        ]
        
-- Length: Infinite
-- Type: Base pattern decorated with fills
--       every fourth bar
make_drum_machine_sig gen = do
    let base = make_drums_base_pattern
        fills1 = make_drums_fill_pattern_1
        fills2 = make_drums_fill_pattern_2
        fills3 = make_drums_fill_pattern_3
        drums_4_bars_with_fills = mel
            [ lim (sig (3 * drum_raster)) base
            , lim (sig drum_raster) $ pickBy (sig drum_raster)
                [ (1/4, base)
                , (1/4, fills1)
                , (1/4, fills2)
                , (1/4, fills3)
                ]
            ]
        drums_without_effects = runSam (sig (bpm * 4)) $ loop drums_4_bars_with_fills
        drums_with_effect = drums_without_effects
    return drums_without_effects
