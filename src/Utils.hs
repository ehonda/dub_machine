module Utils where

import Csound.Base

-- Functions to generate lists to construct
-- linsegs from
make_horizontal_line len height = [height, len, height]
slope_connect w v s = 
    case (w, v) of
        ([], _) -> v
        (_, []) -> w
        (_, _) -> w ++ [s] ++ v


    
combine ws = sum ws
