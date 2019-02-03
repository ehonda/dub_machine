<CsoundSynthesizer>

<CsOptions>

--nodisplays --output=dac --input=adc

</CsOptions>

<CsInstruments>

sr = 44100
ksmps = 64
nchnls = 2
0dbfs = 1.0
gkrggBpmVar init 110.0
girgfree_vco = 109
ir13 = girgfree_vco
ir15 vco2init 1, ir13
girgfree_vco = ir15
ir18 = girgfree_vco
ir20 vco2init 8, ir18
girgfree_vco = ir20
giPort init 1
opcode FreePort, i, 0
xout giPort
giPort = giPort + 1
endop

; Distortion
; ----------------
; A distortion effect offering stomp-box-like controls
;
; aout  Distortion  ain,klevel,kdrive,ktone
;
; Performance
; -----------
; ain    --  input audio to be distorted
; klevel --  output level of the effect (range: 0 to 1)
; kdrive --  intensity of the distortion effect (range: 0 to 1)
; ktone  --  tone of a lowpass filter (range: 0 to 1)

opcode	Distortion, a, aKKK
	ain,klevel,kdrive,ktone	xin							;READ IN INPUT ARGUMENTS
	klevel		scale		klevel,0.8,0					;RESCALE LEVEL CONTROL
	kdrive		expcurve	kdrive,8					;EXPONENTIALLY REMAP kdrive
	kdrive		scale		kdrive,0.4,0.01					;RESCALE kdrive
	kLPF		expcurve	ktone,4						;EXPONENTIALLY REMAP ktone
	kLPF		scale		kLPF,12000,200					;RESCALE klpf
	kGainComp1	logcurve	ktone,700					;LOGARITHMIC RESCALING OF ktone TO CREAT A GAIN COMPENSATION VARIABLE FOR WHEN TONE IS LOWERED
	kGainComp1	scale		kGainComp1,1,5					;RESCALE GAIN COMPENSATION VARIABLE
	kpregain	=		(kdrive*100)					;DEFINE PREGAIN FROM kdrive
	kpostgain	=		0.5 * (((1-kdrive) * 0.4) + 0.6)		;DEFINE POSTGAIN FROM kdrive
	aDist		distort1	ain*(32768/0dbfs), kpregain, kpostgain, 0, 0	;CREATE DISTORTION SIGNAL
	aDist		butlp		aDist/(32768/0dbfs), kLPF			;LOWPASS FILTER DISTORTED SIGNAL
			xout		aDist*klevel*kGainComp1				;SEND AUDIO BACK TO CALLER INSTRUMENT. RESCALE WITH USER LEVEL CONTROL AND GAIN COMPENSATION			
endop
; Flanger
; ----------------
; A flanger effect following the typical design of a so called 'stomp box'
;
; aout  Flanger  ain,krate,kdepth,kdelay,kfback
;
; Performance
; -----------
; ain    --  input audio to which the flanging effect will be applied
; krate  --  rate control of the lfo of the effect *NOT IN HERTZ* (range 0 to 1)
; kdepth --  depth of the lfo of the effect (range 0 to 1)
; kdelay --  static delay offset of the flanging effect (range 0 to 1)
; kfback --  feedback and therefore intensity of the effect (range 0 to 1)


opcode	Flanger,a,aKKKK
	ain,krate,kdepth,kdelay,kfback	xin					;READ IN INPUT ARGUMENTS
	krate		expcurve	krate,50				;CREATE AN EXPONENTIAL REMAPPING OF krate
	krate		scale	krate,14,0.001					;RESCALE VALUE	
	kdelay		expcurve	kdelay,200				;CREATE AN EXPONENTIAL REMAPPING OF kdelay
	kdelay		scale		kdelay,0.1,0.00015			;RESCALE VALUE	
	ilfoshape	ftgentmp	0, 0, 131072, 19, 0.5, 1, 180, 1	;U-SHAPE PARABOLA FOR LFO
	kporttime	linseg		0, 0.001, 0.1 				;USE OF AN ENVELOPE VALUE THAT QUICKLY RAMPS UP FROM ZERON TO THE REQUIRED VALUE PREVENTS VARIABLES GLIDING TO THEIR REQUIRED VALUES EACH TIME THE INSTRUMENT IS STARTED
	kdlt		portk		kdelay, kporttime 			;PORTAMENTO IS APPLIED TO A VARIABLE. A NEW VARIABLE 'kdlt' IS CREATED.
	adlt		interp		kdlt					;A NEW A-RATE VARIABLE 'adlt' IS CREATED BY INTERPOLATING THE K-RATE VARIABLE 'kdlt'
	kdep		portk		kdepth*0.01, kporttime 			;PORTAMENTO IS APPLIED TO A VARIABLE. A NEW VARIABLE 'kdep' IS CREATED.
	amod		oscili		kdep, krate, ilfoshape			;OSCILLATOR THAT MAKES USE OF THE POSITIVE DOMAIN ONLY U-SHAPE PARABOLA WITH FUNCTION TABLE NUMBER ilfoshape
	adlt		sum		adlt, amod				;STATIC DELAY TIME AND MODULATING DELAY TIME ARE SUMMED
	adelsig		flanger 	ain, adlt, kfback , 1.2			;FLANGER SIGNAL CREATED
	aout		sum		ain*0.5, adelsig*0.5			;CREATE DRY/WET MIX 
			xout		aout					;SEND AUDIO BACK TO CALLER INSTRUMENT
endop
; Phaser
; ----------------
; An phase shifting effect that mimics the design of a so called 'stomp box'
;
; aout  Phaser  ain,krate,kdepth,kfreq,kfback
;
; Performance
; -----------
; ain    --  input audio to be pitch shifted
; krate  --  rate of lfo of the effect (range 0 to 1)
; kdepth --  depth of lfo of the effect (range 0 to 1)
; kfreq  --  centre frequency of the phase shifting effect in octaves (suggested range 6 to 11)
; kfback --  feedback and therefore intensity of the effect (range 0 to 1)

opcode	Phaser,a,aKKKK
	ain,krate,kdepth,kfreq,kfback	xin					;READ IN INPUT ARGUMENTS
	krate		expcurve	krate,10				;CREATE AN EXPONENTIAL REMAPPING OF krate
	krate		scale	krate,14,0.01					;RESCALE 0 - 1 VALUE TO 0.01 - 14	
	klfo	lfo	kdepth*0.5, krate, 1					;LFO FOR THE PHASER (TRIANGULAR SHAPE)
	aout	phaser1	ain, cpsoct((klfo+(kdepth*0.5)+kfreq)), 8, kfback	;PHASER1 IS APPLIED TO THE INPUT AUDIO
		xout	aout							;SEND AUDIO BACK TO CALLER INSTRUMENT
endop
opcode StereoPingPongDelay, aa, aaKKKKKi
    aInL, aInR, kdelayTime, kFeedback, kMix, kWidth, kDamp, iMaxDelayTime xin

    iporttime   =       .1          ;PORTAMENTO TIME
    kporttime   linseg      0, .001, iporttime  ;USE OF AN ENVELOPE VALUE THAT QUICKLY RAMPS UP FROM ZERO TO THE REQUIRED VALUE. THIS PREVENTS VARIABLES GLIDING TO THEIR REQUIRED VALUES EACH TIME THE INSTRUMENT IS STARTED
    kdlt        portk       kdelayTime, kporttime    ;PORTAMENTO IS APPLIED TO THE VARIABLE 'gkdlt'. A NEW VARIABLE 'kdlt' IS CREATED.
    adlt        interp      kdlt            ;A NEW A-RATE VARIABLE 'adlt' IS CREATED BY INTERPOLATING THE K-RATE VARIABLE 'kdlt' 

    ;;;LEFT CHANNEL OFFSET;;;NO FEEDBACK!!;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    abufferL_OS delayr  iMaxDelayTime          ;CREATE A DELAY BUFFER OF imaxdelay SECONDS DURATION
    adelsigL_OS     deltap3 adlt                ;TAP THE DELAY LINE AT adlt SECONDS
    adelsigL_OS tone adelsigL_OS, kDamp
            delayw  aInL                ;WRITE AUDIO SOURCE INTO THE BEGINNING OF THE BUFFER

    ;;;LEFT CHANNEL DELAY;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    abufferL    delayr  iMaxDelayTime*2            ;CREATE A DELAY BUFFER OF 5 SECONDS DURATION (EQUIVALENT TO THE MAXIMUM DELAY TIME POSSIBLE USING THIS EXAMPLE)
    adelsigL    deltap3 adlt*2              ;TAP THE DELAY LINE AT gkdlt SECONDS
    adelsigL    tone adelsigL, kDamp
            delayw  adelsigL_OS + (adelsigL * kFeedback)    ;WRITE AUDIO SOURCE FROM OFFSETTTING DELAY AND FEEDBACK SIGNAL INTO THE BEGINNING OF THE BUFFER
    
    abufferR    delayr  iMaxDelayTime*2            ;CREATE A DELAY BUFFER OF 5 SECONDS DURATION (EQUIVALENT TO THE MAXIMUM DELAY TIME POSSIBLE USING THIS EXAMPLE)
    adelsigR    deltap3 adlt*2              ;TAP THE DELAY LINE AT gkdlt SECONDS
    adelsigR    tone adelsigR, kDamp
            delayw  aInR+(adelsigR*kFeedback)   ;WRITE AUDIO SOURCE AND FEEDBACK SIGNAL INTO THE BEGINNING OF THE BUFFER

    ;CREATE LEFT AND RIGHT CHANNEL MIXES
    aOutL       sum     (adelsigL  + adelsigL_OS)* kMix, aInL * (1-kMix), (1 - kWidth) * adelsigR
    aOutR       sum     adelsigR                 * kMix, aInR * (1-kMix), (1 - kWidth) * adelsigL     
            xout        aOutL, aOutR        ;CREATE A MIX BETWEEN THE WET AND THE DRY SIGNALS AT THE OUTPUT
endop
; Gated, Retriggerable Envelope Generator UDO (adsr140)
; Based on design of Doepfer A-140 Envelope Generator Module
; Code based on ADSR code by Nigel Redmon 
; (http://www.earlevel.com/main/2013/06/03/envelope-generators-adsr-code/)
; Example by Steven Yi (2015.02.08)

opcode adsr140_calc_coef, k, kk
  
  knum_samps, kratio xin
  xout exp( -log((1.0 + kratio) / kratio) / knum_samps)
    
endop

/* Gated, Re-triggerable ADSR modeled after the Doepfer A-140 */
opcode adsr140, a, aakkkk

agate, aretrig, kattack, kdecay, ksustain, krelease xin

kstate init 0  ; 0 = attack, 1 = decay, 2 = sustain
klasttrig init -1
kval init 0.0
asig init 0
kindx = 0

kattack_base init 0
kdecay_base init 0
krelease_base init 0

kattack_samps init 0
kdecay_samps init 0
krelease_samps init 0

kattack_coef init 0
kdecay_coef init 0
ksustain_coef init 0

klast_attack init -1
klast_decay init -1
klast_release init -1

if (klast_attack != kattack) then
  klast_attack = kattack
  kattack_samps = kattack * sr
  kattack_coef = adsr140_calc_coef(kattack_samps, 0.3)
  kattack_base = (1.0 + 0.3) * (1 - kattack_coef)
endif

if (klast_decay != kdecay) then
  klast_decay = kdecay
  kdecay_samps = kdecay * sr
  kdecay_coef = adsr140_calc_coef(kdecay_samps, 0.0001)
  kdecay_base = (ksustain - 0.0001) * (1.0 - kdecay_coef)
endif

if (klast_release != krelease) then
  klast_release = krelease
  krelease_samps = krelease * sr
  krelease_coef = adsr140_calc_coef(krelease_samps, 0.0001)
  krelease_base =  -0.0001 * (1.0 - krelease_coef)
endif


while (kindx < ksmps) do
  if (agate[kindx] > 0) then
    kretrig = aretrig[kindx]
    if (kretrig > 0 && klasttrig <= 0) then
      kstate = 0
    endif
    klasttrig = kretrig

    if (kstate == 0) then
      kval = kattack_base + (kval * kattack_coef)
      if(kval >= 1.0) then
        kval = 1.0
        kstate = 1
      endif
      asig[kindx] = kval

    elseif (kstate == 1) then
      kval = kdecay_base + (kval * kdecay_coef)
      if(kval <= ksustain) then
        kval = ksustain
        kstate = 2
      endif
      asig[kindx] = kval 

    else
      asig[kindx] = ksustain
    endif

  else ; in a release state
    kstate = 0
    if (kval == 0.0) then
      asig[kindx] = 0
    else 
    ; releasing
      kval = krelease_base + (kval * krelease_coef)
    if(kval <= 0.0) then
      kval = 0.0
    endif
    asig[kindx] = kval  
    endif

  endif

  kindx += 1
od

xout asig

endop



instr 242

endin

instr 241
 event_i "i", 240, 118.15384615384617, 1.0e-2
endin

instr 240
ir1 = 239
ir2 = 0.0
 turnoff2 ir1, ir2, ir2
ir5 = 238
 turnoff2 ir5, ir2, ir2
ir8 = 237
 turnoff2 ir8, ir2, ir2
ir11 = 236
 turnoff2 ir11, ir2, ir2
ir14 = 235
 turnoff2 ir14, ir2, ir2
ir17 = 234
 turnoff2 ir17, ir2, ir2
ir20 = 233
 turnoff2 ir20, ir2, ir2
ir23 = 232
 turnoff2 ir23, ir2, ir2
ir26 = 231
 turnoff2 ir26, ir2, ir2
ir29 = 230
 turnoff2 ir29, ir2, ir2
ir32 = 229
 turnoff2 ir32, ir2, ir2
ir35 = 228
 turnoff2 ir35, ir2, ir2
ir38 = 227
 turnoff2 ir38, ir2, ir2
ir41 = 226
 turnoff2 ir41, ir2, ir2
ir44 = 225
 turnoff2 ir44, ir2, ir2
ir47 = 224
 turnoff2 ir47, ir2, ir2
ir50 = 223
 turnoff2 ir50, ir2, ir2
ir53 = 222
 turnoff2 ir53, ir2, ir2
ir56 = 221
 turnoff2 ir56, ir2, ir2
ir59 = 220
 turnoff2 ir59, ir2, ir2
ir62 = 219
 turnoff2 ir62, ir2, ir2
ir65 = 218
 turnoff2 ir65, ir2, ir2
ir68 = 217
 turnoff2 ir68, ir2, ir2
ir71 = 216
 turnoff2 ir71, ir2, ir2
ir74 = 215
 turnoff2 ir74, ir2, ir2
ir77 = 214
 turnoff2 ir77, ir2, ir2
ir80 = 213
 turnoff2 ir80, ir2, ir2
ir83 = 212
 turnoff2 ir83, ir2, ir2
ir86 = 211
 turnoff2 ir86, ir2, ir2
ir89 = 210
 turnoff2 ir89, ir2, ir2
ir92 = 209
 turnoff2 ir92, ir2, ir2
ir95 = 208
 turnoff2 ir95, ir2, ir2
ir98 = 207
 turnoff2 ir98, ir2, ir2
ir101 = 206
 turnoff2 ir101, ir2, ir2
ir104 = 205
 turnoff2 ir104, ir2, ir2
ir107 = 204
 turnoff2 ir107, ir2, ir2
ir110 = 203
 turnoff2 ir110, ir2, ir2
ir113 = 202
 turnoff2 ir113, ir2, ir2
ir116 = 201
 turnoff2 ir116, ir2, ir2
ir119 = 200
 turnoff2 ir119, ir2, ir2
ir122 = 199
 turnoff2 ir122, ir2, ir2
ir125 = 198
 turnoff2 ir125, ir2, ir2
ir128 = 197
 turnoff2 ir128, ir2, ir2
ir131 = 196
 turnoff2 ir131, ir2, ir2
ir134 = 195
 turnoff2 ir134, ir2, ir2
ir137 = 194
 turnoff2 ir137, ir2, ir2
ir140 = 193
 turnoff2 ir140, ir2, ir2
ir143 = 192
 turnoff2 ir143, ir2, ir2
ir146 = 191
 turnoff2 ir146, ir2, ir2
ir149 = 190
 turnoff2 ir149, ir2, ir2
ir152 = 189
 turnoff2 ir152, ir2, ir2
ir155 = 188
 turnoff2 ir155, ir2, ir2
ir158 = 187
 turnoff2 ir158, ir2, ir2
ir161 = 186
 turnoff2 ir161, ir2, ir2
ir164 = 185
 turnoff2 ir164, ir2, ir2
ir167 = 184
 turnoff2 ir167, ir2, ir2
ir170 = 183
 turnoff2 ir170, ir2, ir2
ir173 = 182
 turnoff2 ir173, ir2, ir2
ir176 = 181
 turnoff2 ir176, ir2, ir2
ir179 = 180
 turnoff2 ir179, ir2, ir2
ir182 = 179
 turnoff2 ir182, ir2, ir2
ir185 = 178
 turnoff2 ir185, ir2, ir2
ir188 = 177
 turnoff2 ir188, ir2, ir2
ir191 = 176
 turnoff2 ir191, ir2, ir2
ir194 = 175
 turnoff2 ir194, ir2, ir2
ir197 = 174
 turnoff2 ir197, ir2, ir2
ir200 = 173
 turnoff2 ir200, ir2, ir2
ir203 = 172
 turnoff2 ir203, ir2, ir2
ir206 = 171
 turnoff2 ir206, ir2, ir2
ir209 = 170
 turnoff2 ir209, ir2, ir2
ir212 = 169
 turnoff2 ir212, ir2, ir2
ir215 = 168
 turnoff2 ir215, ir2, ir2
ir218 = 167
 turnoff2 ir218, ir2, ir2
ir221 = 166
 turnoff2 ir221, ir2, ir2
ir224 = 165
 turnoff2 ir224, ir2, ir2
ir227 = 164
 turnoff2 ir227, ir2, ir2
ir230 = 163
 turnoff2 ir230, ir2, ir2
ir233 = 162
 turnoff2 ir233, ir2, ir2
ir236 = 161
 turnoff2 ir236, ir2, ir2
ir239 = 160
 turnoff2 ir239, ir2, ir2
ir242 = 159
 turnoff2 ir242, ir2, ir2
ir245 = 158
 turnoff2 ir245, ir2, ir2
ir248 = 157
 turnoff2 ir248, ir2, ir2
ir251 = 156
 turnoff2 ir251, ir2, ir2
ir254 = 155
 turnoff2 ir254, ir2, ir2
ir257 = 154
 turnoff2 ir257, ir2, ir2
ir260 = 153
 turnoff2 ir260, ir2, ir2
ir263 = 152
 turnoff2 ir263, ir2, ir2
ir266 = 151
 turnoff2 ir266, ir2, ir2
ir269 = 150
 turnoff2 ir269, ir2, ir2
ir272 = 149
 turnoff2 ir272, ir2, ir2
ir275 = 148
 turnoff2 ir275, ir2, ir2
ir278 = 147
 turnoff2 ir278, ir2, ir2
ir281 = 146
 turnoff2 ir281, ir2, ir2
ir284 = 145
 turnoff2 ir284, ir2, ir2
ir287 = 144
 turnoff2 ir287, ir2, ir2
ir290 = 143
 turnoff2 ir290, ir2, ir2
ir293 = 142
 turnoff2 ir293, ir2, ir2
ir296 = 141
 turnoff2 ir296, ir2, ir2
ir299 = 140
 turnoff2 ir299, ir2, ir2
ir302 = 139
 turnoff2 ir302, ir2, ir2
ir305 = 138
 turnoff2 ir305, ir2, ir2
ir308 = 137
 turnoff2 ir308, ir2, ir2
ir311 = 136
 turnoff2 ir311, ir2, ir2
ir314 = 135
 turnoff2 ir314, ir2, ir2
ir317 = 134
 turnoff2 ir317, ir2, ir2
ir320 = 133
 turnoff2 ir320, ir2, ir2
ir323 = 132
 turnoff2 ir323, ir2, ir2
ir326 = 131
 turnoff2 ir326, ir2, ir2
ir329 = 130
 turnoff2 ir329, ir2, ir2
ir332 = 129
 turnoff2 ir332, ir2, ir2
ir335 = 128
 turnoff2 ir335, ir2, ir2
ir338 = 127
 turnoff2 ir338, ir2, ir2
ir341 = 126
 turnoff2 ir341, ir2, ir2
ir344 = 125
 turnoff2 ir344, ir2, ir2
ir347 = 124
 turnoff2 ir347, ir2, ir2
ir350 = 123
 turnoff2 ir350, ir2, ir2
ir353 = 122
 turnoff2 ir353, ir2, ir2
ir356 = 121
 turnoff2 ir356, ir2, ir2
ir359 = 120
 turnoff2 ir359, ir2, ir2
ir362 = 119
 turnoff2 ir362, ir2, ir2
ir365 = 118
 turnoff2 ir365, ir2, ir2
ir368 = 117
 turnoff2 ir368, ir2, ir2
ir371 = 116
 turnoff2 ir371, ir2, ir2
ir374 = 115
 turnoff2 ir374, ir2, ir2
ir377 = 114
 turnoff2 ir377, ir2, ir2
ir380 = 113
 turnoff2 ir380, ir2, ir2
ir383 = 112
 turnoff2 ir383, ir2, ir2
ir386 = 111
 turnoff2 ir386, ir2, ir2
ir389 = 110
 turnoff2 ir389, ir2, ir2
ir392 = 109
 turnoff2 ir392, ir2, ir2
ir395 = 108
 turnoff2 ir395, ir2, ir2
ir398 = 107
 turnoff2 ir398, ir2, ir2
ir401 = 106
 turnoff2 ir401, ir2, ir2
ir404 = 105
 turnoff2 ir404, ir2, ir2
ir407 = 104
 turnoff2 ir407, ir2, ir2
ir410 = 103
 turnoff2 ir410, ir2, ir2
ir413 = 102
 turnoff2 ir413, ir2, ir2
ir416 = 101
 turnoff2 ir416, ir2, ir2
ir419 = 100
 turnoff2 ir419, ir2, ir2
ir422 = 99
 turnoff2 ir422, ir2, ir2
ir425 = 98
 turnoff2 ir425, ir2, ir2
ir428 = 97
 turnoff2 ir428, ir2, ir2
ir431 = 96
 turnoff2 ir431, ir2, ir2
ir434 = 95
 turnoff2 ir434, ir2, ir2
ir437 = 94
 turnoff2 ir437, ir2, ir2
ir440 = 93
 turnoff2 ir440, ir2, ir2
ir443 = 92
 turnoff2 ir443, ir2, ir2
ir446 = 91
 turnoff2 ir446, ir2, ir2
ir449 = 90
 turnoff2 ir449, ir2, ir2
ir452 = 89
 turnoff2 ir452, ir2, ir2
ir455 = 88
 turnoff2 ir455, ir2, ir2
ir458 = 87
 turnoff2 ir458, ir2, ir2
ir461 = 86
 turnoff2 ir461, ir2, ir2
ir464 = 85
 turnoff2 ir464, ir2, ir2
ir467 = 84
 turnoff2 ir467, ir2, ir2
ir470 = 83
 turnoff2 ir470, ir2, ir2
ir473 = 82
 turnoff2 ir473, ir2, ir2
ir476 = 81
 turnoff2 ir476, ir2, ir2
ir479 = 80
 turnoff2 ir479, ir2, ir2
ir482 = 79
 turnoff2 ir482, ir2, ir2
ir485 = 78
 turnoff2 ir485, ir2, ir2
ir488 = 77
 turnoff2 ir488, ir2, ir2
ir491 = 76
 turnoff2 ir491, ir2, ir2
ir494 = 75
 turnoff2 ir494, ir2, ir2
ir497 = 74
 turnoff2 ir497, ir2, ir2
ir500 = 73
 turnoff2 ir500, ir2, ir2
ir503 = 72
 turnoff2 ir503, ir2, ir2
ir506 = 71
 turnoff2 ir506, ir2, ir2
ir509 = 70
 turnoff2 ir509, ir2, ir2
ir512 = 69
 turnoff2 ir512, ir2, ir2
ir515 = 68
 turnoff2 ir515, ir2, ir2
ir518 = 67
 turnoff2 ir518, ir2, ir2
ir521 = 66
 turnoff2 ir521, ir2, ir2
ir524 = 65
 turnoff2 ir524, ir2, ir2
ir527 = 64
 turnoff2 ir527, ir2, ir2
ir530 = 63
 turnoff2 ir530, ir2, ir2
ir533 = 62
 turnoff2 ir533, ir2, ir2
ir536 = 61
 turnoff2 ir536, ir2, ir2
ir539 = 60
 turnoff2 ir539, ir2, ir2
ir542 = 59
 turnoff2 ir542, ir2, ir2
ir545 = 58
 turnoff2 ir545, ir2, ir2
ir548 = 57
 turnoff2 ir548, ir2, ir2
ir551 = 56
 turnoff2 ir551, ir2, ir2
ir554 = 55
 turnoff2 ir554, ir2, ir2
ir557 = 54
 turnoff2 ir557, ir2, ir2
ir560 = 53
 turnoff2 ir560, ir2, ir2
ir563 = 52
 turnoff2 ir563, ir2, ir2
ir566 = 51
 turnoff2 ir566, ir2, ir2
ir569 = 50
 turnoff2 ir569, ir2, ir2
ir572 = 49
 turnoff2 ir572, ir2, ir2
ir575 = 48
 turnoff2 ir575, ir2, ir2
ir578 = 47
 turnoff2 ir578, ir2, ir2
ir581 = 46
 turnoff2 ir581, ir2, ir2
ir584 = 45
 turnoff2 ir584, ir2, ir2
ir587 = 44
 turnoff2 ir587, ir2, ir2
ir590 = 43
 turnoff2 ir590, ir2, ir2
ir593 = 42
 turnoff2 ir593, ir2, ir2
ir596 = 41
 turnoff2 ir596, ir2, ir2
ir599 = 40
 turnoff2 ir599, ir2, ir2
ir602 = 39
 turnoff2 ir602, ir2, ir2
ir605 = 38
 turnoff2 ir605, ir2, ir2
ir608 = 37
 turnoff2 ir608, ir2, ir2
ir611 = 36
 turnoff2 ir611, ir2, ir2
ir614 = 35
 turnoff2 ir614, ir2, ir2
ir617 = 34
 turnoff2 ir617, ir2, ir2
ir620 = 33
 turnoff2 ir620, ir2, ir2
ir623 = 32
 turnoff2 ir623, ir2, ir2
ir626 = 31
 turnoff2 ir626, ir2, ir2
ir629 = 30
 turnoff2 ir629, ir2, ir2
ir632 = 29
 turnoff2 ir632, ir2, ir2
ir635 = 28
 turnoff2 ir635, ir2, ir2
ir638 = 27
 turnoff2 ir638, ir2, ir2
ir641 = 26
 turnoff2 ir641, ir2, ir2
ir644 = 25
 turnoff2 ir644, ir2, ir2
ir647 = 24
 turnoff2 ir647, ir2, ir2
ir650 = 23
 turnoff2 ir650, ir2, ir2
ir653 = 22
 turnoff2 ir653, ir2, ir2
ir656 = 21
 turnoff2 ir656, ir2, ir2
ir659 = 20
 turnoff2 ir659, ir2, ir2
ir662 = 19
 turnoff2 ir662, ir2, ir2
ir665 = 18
 turnoff2 ir665, ir2, ir2
 exitnow 
endin

instr 239
ir1 = 1.0
ar0 upsamp k(ir1)
kr0 = rnd(ir1)
kr1 = rnd(ir1)
kr2 = rnd(ir1)
kr3 = rnd(ir1)
kr4 = rnd(ir1)
kr5 = rnd(ir1)
ir14 = 0.8
ir15 = 0.0
ar1 noise ir14, ir15
 xtratim 0.1
ir20 = 9.0e-2
kr6 = birnd(ir20)
ir23 = 5.0e-2
kr7 = birnd(ir23)
kr8 = birnd(ir23)
ir28 = 5.0e-3
kr9 = birnd(ir28)
 xtratim 0.1
kr10 = birnd(ir20)
ir35 = 8.5e-2
kr11 = birnd(ir35)
kr12 = birnd(ir35)
ir40 = 8.5e-3
kr13 = birnd(ir40)
kr14 = rnd(ir1)
kr15 = rnd(ir1)
ir47 = 0.75
ar2 noise ir47, ir15
 xtratim 0.1
kr16 = birnd(ir20)
kr17 = rnd(ir1)
kr18 = rnd(ir1)
kr19 = rnd(ir1)
kr20 = rnd(ir1)
kr21 = rnd(ir1)
kr22 = rnd(ir1)
ar3 noise ir14, ir15
 xtratim 0.1
kr23 = birnd(ir20)
kr24 = birnd(ir23)
kr25 = birnd(ir23)
kr26 = birnd(ir28)
 xtratim 0.1
kr27 = birnd(ir20)
kr28 = birnd(ir35)
kr29 = birnd(ir35)
kr30 = birnd(ir40)
kr31 = rnd(ir1)
kr32 = rnd(ir1)
ar4 noise ir47, ir15
 xtratim 0.1
kr33 = birnd(ir20)
kr34 = rnd(ir1)
kr35 = rnd(ir1)
kr36 = rnd(ir1)
kr37 = rnd(ir1)
kr38 = rnd(ir1)
kr39 = rnd(ir1)
ar5 noise ir14, ir15
 xtratim 0.1
kr40 = birnd(ir20)
kr41 = rnd(ir1)
kr42 = rnd(ir1)
kr43 = rnd(ir1)
kr44 = rnd(ir1)
kr45 = rnd(ir1)
kr46 = rnd(ir1)
ar6 noise ir14, ir15
 xtratim 0.1
kr47 = birnd(ir20)
kr48 = birnd(ir35)
kr49 = birnd(ir35)
kr50 = birnd(ir40)
kr51 = rnd(ir1)
kr52 = rnd(ir1)
ar7 noise ir47, ir15
 xtratim 0.1
kr53 = birnd(ir20)
kr54 = rnd(ir1)
 xtratim 0.1
kr55 = birnd(ir20)
kr56 = rnd(ir1)
kr57 = rnd(ir1)
kr58 = rnd(ir1)
kr59 = rnd(ir1)
kr60 = rnd(ir1)
kr61 = rnd(ir1)
ar8 noise ir14, ir15
 xtratim 0.1
kr62 = birnd(ir20)
ar9 noise ir14, ir15
 xtratim 0.1
kr63 = birnd(ir20)
kr64 = birnd(ir35)
kr65 = birnd(ir35)
kr66 = birnd(ir40)
kr67 = rnd(ir1)
kr68 = rnd(ir1)
ar10 noise ir47, ir15
 xtratim 0.1
kr69 = birnd(ir20)
kr70 = birnd(ir23)
kr71 = birnd(ir23)
kr72 = birnd(ir28)
 xtratim 0.1
kr73 = birnd(ir20)
kr74 = birnd(ir23)
kr75 = birnd(ir23)
kr76 = birnd(ir28)
 xtratim 0.1
kr77 = birnd(ir20)
kr78 = birnd(ir35)
kr79 = birnd(ir35)
kr80 = birnd(ir40)
kr81 = rnd(ir1)
kr82 = rnd(ir1)
ar11 noise ir47, ir15
 xtratim 0.1
kr83 = birnd(ir20)
kr84 = rnd(ir1)
kr85 = rnd(ir1)
kr86 = rnd(ir1)
kr87 = rnd(ir1)
kr88 = rnd(ir1)
kr89 = rnd(ir1)
ar12 noise ir14, ir15
 xtratim 0.1
kr90 = birnd(ir20)
kr91 = rnd(ir1)
kr92 = rnd(ir1)
kr93 = rnd(ir1)
kr94 = rnd(ir1)
kr95 = rnd(ir1)
kr96 = rnd(ir1)
ar13 noise ir14, ir15
 xtratim 0.1
kr97 = birnd(ir20)
kr98 = rnd(ir1)
ir270 = 0.4
ar14 noise ir1, ir270
 xtratim 0.1
kr99 = birnd(ir20)
kr100 = rnd(ir1)
ar15 noise ir1, ir270
 xtratim 0.1
kr101 = birnd(ir20)
kr102 = rnd(ir1)
ar16 noise ir1, ir270
 xtratim 0.1
kr103 = birnd(ir20)
ar17 noise ir14, ir15
 xtratim 0.1
kr104 = birnd(ir20)
kr105 = rnd(ir1)
 xtratim 0.1
kr106 = birnd(ir20)
kr107 = birnd(ir35)
kr108 = birnd(ir35)
kr109 = birnd(ir40)
kr110 = rnd(ir1)
ar18 noise ir1, ir15
 xtratim 0.1
kr111 = birnd(ir20)
ar19 noise ir47, ir15
 xtratim 0.1
kr112 = birnd(ir20)
kr113 = rnd(ir1)
 xtratim 0.1
kr114 = birnd(ir20)
kr115 = rnd(ir1)
 xtratim 0.1
kr116 = birnd(ir20)
kr117 = rnd(ir1)
 xtratim 0.1
kr118 = birnd(ir20)
kr119 = rnd(ir1)
kr120 = rnd(ir1)
kr121 = rnd(ir1)
kr122 = rnd(ir1)
kr123 = rnd(ir1)
kr124 = rnd(ir1)
ar20 noise ir14, ir15
 xtratim 0.1
kr125 = birnd(ir20)
kr126 = birnd(ir23)
kr127 = birnd(ir23)
kr128 = birnd(ir28)
 xtratim 0.1
kr129 = birnd(ir20)
kr130 = birnd(ir35)
kr131 = birnd(ir35)
kr132 = birnd(ir40)
kr133 = rnd(ir1)
kr134 = rnd(ir1)
ar21 noise ir47, ir15
 xtratim 0.1
kr135 = birnd(ir20)
kr136 = rnd(ir1)
kr137 = rnd(ir1)
kr138 = rnd(ir1)
kr139 = rnd(ir1)
kr140 = rnd(ir1)
kr141 = rnd(ir1)
ar22 noise ir14, ir15
 xtratim 0.1
kr142 = birnd(ir20)
kr143 = birnd(ir23)
kr144 = birnd(ir23)
kr145 = birnd(ir28)
 xtratim 0.1
kr146 = birnd(ir20)
kr147 = birnd(ir35)
kr148 = birnd(ir35)
kr149 = birnd(ir40)
kr150 = rnd(ir1)
kr151 = rnd(ir1)
ar23 noise ir47, ir15
 xtratim 0.1
kr152 = birnd(ir20)
kr153 = rnd(ir1)
kr154 = rnd(ir1)
kr155 = rnd(ir1)
kr156 = rnd(ir1)
kr157 = rnd(ir1)
kr158 = rnd(ir1)
ar24 noise ir14, ir15
 xtratim 0.1
kr159 = birnd(ir20)
kr160 = rnd(ir1)
kr161 = rnd(ir1)
kr162 = rnd(ir1)
kr163 = rnd(ir1)
kr164 = rnd(ir1)
kr165 = rnd(ir1)
ar25 noise ir14, ir15
 xtratim 0.1
kr166 = birnd(ir20)
kr167 = birnd(ir35)
kr168 = birnd(ir35)
kr169 = birnd(ir40)
kr170 = rnd(ir1)
kr171 = rnd(ir1)
ar26 noise ir47, ir15
 xtratim 0.1
kr172 = birnd(ir20)
kr173 = rnd(ir1)
 xtratim 0.1
kr174 = birnd(ir20)
kr175 = rnd(ir1)
kr176 = rnd(ir1)
kr177 = rnd(ir1)
kr178 = rnd(ir1)
kr179 = rnd(ir1)
kr180 = rnd(ir1)
ar27 noise ir14, ir15
 xtratim 0.1
kr181 = birnd(ir20)
ar28 noise ir14, ir15
 xtratim 0.1
kr182 = birnd(ir20)
kr183 = birnd(ir35)
kr184 = birnd(ir35)
kr185 = birnd(ir40)
kr186 = rnd(ir1)
kr187 = rnd(ir1)
ar29 noise ir47, ir15
 xtratim 0.1
kr188 = birnd(ir20)
kr189 = birnd(ir23)
kr190 = birnd(ir23)
kr191 = birnd(ir28)
 xtratim 0.1
kr192 = birnd(ir20)
kr193 = birnd(ir23)
kr194 = birnd(ir23)
kr195 = birnd(ir28)
 xtratim 0.1
kr196 = birnd(ir20)
kr197 = birnd(ir35)
kr198 = birnd(ir35)
kr199 = birnd(ir40)
kr200 = rnd(ir1)
kr201 = rnd(ir1)
ar30 noise ir47, ir15
 xtratim 0.1
kr202 = birnd(ir20)
kr203 = rnd(ir1)
kr204 = rnd(ir1)
kr205 = rnd(ir1)
kr206 = rnd(ir1)
kr207 = rnd(ir1)
kr208 = rnd(ir1)
ar31 noise ir14, ir15
 xtratim 0.1
kr209 = birnd(ir20)
kr210 = rnd(ir1)
kr211 = rnd(ir1)
kr212 = rnd(ir1)
kr213 = rnd(ir1)
kr214 = rnd(ir1)
kr215 = rnd(ir1)
ar32 noise ir14, ir15
 xtratim 0.1
kr216 = birnd(ir20)
kr217 = rnd(ir1)
ar33 noise ir1, ir270
 xtratim 0.1
kr218 = birnd(ir20)
kr219 = rnd(ir1)
ar34 noise ir1, ir270
 xtratim 0.1
kr220 = birnd(ir20)
kr221 = rnd(ir1)
ar35 noise ir1, ir270
 xtratim 0.1
kr222 = birnd(ir20)
ar36 noise ir14, ir15
 xtratim 0.1
kr223 = birnd(ir20)
kr224 = rnd(ir1)
 xtratim 0.1
kr225 = birnd(ir20)
kr226 = birnd(ir35)
kr227 = birnd(ir35)
kr228 = birnd(ir40)
kr229 = rnd(ir1)
ar37 noise ir1, ir15
 xtratim 0.1
kr230 = birnd(ir20)
ar38 noise ir47, ir15
 xtratim 0.1
kr231 = birnd(ir20)
kr232 = rnd(ir1)
 xtratim 0.1
kr233 = birnd(ir20)
kr234 = rnd(ir1)
 xtratim 0.1
kr235 = birnd(ir20)
kr236 = rnd(ir1)
 xtratim 0.1
kr237 = birnd(ir20)
arl0 init 0.0
arl1 init 0.0
ar39, ar40 subinstr 20
ar41 = (0.5 * ar39)
kr238 linseg 0.0, 14.76923076923077, 0.0, 0.0, 1.0, 14.76923076923077, 1.0, 0.0, 1.0, 18.461538461538463, 1.0, 0.0, 0.0, 3.6923076923076925, 0.0, 0.0, 1.0, 22.153846153846157, 1.0, 0.0, 0.0, 3.6923076923076925, 0.0, 0.0, 1.0, 11.076923076923073, 1.0, 0.0, 1.0, 11.076923076923078, 1.0, 18.46153846153846, 0.0, 1.0, 0.0
ar39 upsamp kr238
ar42 = (ar41 * ar39)
ar41 = (0.5 * ar42)
ar42, ar43 subinstr 24
ar44 = (0.8 * ar42)
kr238 linseg 0.0, 14.76923076923077, 0.0, 0.0, 1.0, 14.76923076923077, 1.0, 0.0, 1.0, 14.76923076923077, 1.0, 0.0, 0.0, 3.6923076923076925, 0.0, 0.0, 1.0, 14.76923076923077, 1.0, 0.0, 0.0, 3.6923076923076925, 0.0, 0.0, 1.0, 22.153846153846153, 1.0, 0.0, 1.0, 22.153846153846157, 1.0, 0.0, 0.0, 7.384615384615383, 0.0, 1.0, 0.0
ar42 upsamp kr238
ar45 = (ar44 * ar42)
ar44 = (0.5 * ar45)
ar45 = (ar41 + ar44)
ar41, ar44 subinstr 26
ar46 = (1.0 * ar41)
kr238 linseg 0.0, 29.53846153846154, 0.0, 0.0, 1.0, 22.153846153846157, 1.0, 0.0, 0.0, 14.76923076923077, 0.0, 0.0, 1.0, 22.153846153846157, 1.0, 0.0, 0.0, 0.0, 1.0, 29.53846153846154, 1.0, 1.0, 1.0
ar41 upsamp kr238
ar47 = (ar46 * ar41)
ar46 = (0.5 * ar47)
ar47 = (ar45 + ar46)
ar45, ar46 subinstr 132
kr238 linseg 1.0, 29.53846153846154, 1.0, 0.0, 1.0, 14.76923076923077, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 12.923076923076923, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 12.923076923076923, 1.0, 0.0, 0.0, 7.384615384615385, 0.0, 0.0, 1.0, 11.07692307692308, 1.0, 0.0, 0.0, 29.53846153846154, 0.0, 1.0, 0.0
ar48 upsamp kr238
ar49 = (ar45 * ar48)
ar45, ar50 subinstr 238
ar51 = (ar45 * ar48)
kr238 linseg 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 0.46153846153846156, 1.0, 1.0e-2, 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 5.538461538461539, 0.0, 1.0e-2, 1.0, 0.9230769230769231, 1.0, 1.0e-2, 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 0.9230769230769231, 1.0, 1.0e-2, 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 3.6923076923076925, 0.0, 1.0e-2, 1.0, 0.46153846153846156, 1.0, 1.0e-2, 0.0, 5.538461538461539, 0.0, 1.0e-2, 1.0, 0.9230769230769231, 1.0, 1.0e-2, 0.0, 5.538461538461539, 0.0, 1.0e-2, 1.0, 0.0, 1.0, 1.0e-2, 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 0.46153846153846156, 1.0, 1.0e-2, 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 0.9230769230769231, 1.0, 1.0e-2, 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 5.538461538461539, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 5.538461538461539, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 7.384615384615385, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 3.6923076923076925, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 3.6923076923076925, 0.0, 1.0e-2, 1.0, 1.3846153846153848, 1.0, 1.0e-2, 0.0, 3.833846153846082, 0.0, 1.0, 0.0
ar45 upsamp kr238
ar52 = (ar51 * ar45)
ar51 = (ar50 * ar48)
ar50 = (ar51 * ar45)
ir711 = 0.3461538461538462
ir712 = 0.6
ir713 = 3500.0
ar45, ar51 StereoPingPongDelay ar52, ar50, ir711, ir712, ir1, ir712, ir713, 5.0
ar50 = (0.6 * ar45)
ar45 = (ar49 + ar50)
ar49 = (0.5 * ar45)
ar45 = (ar47 + ar49)
ir720 = 90.0
ir721 = 100.0
ar47 compress ar45, ar0, ir15, ir720, ir720, ir721, ir15, ir15, 0.0
ar45 = (ar47 * 0.8)
arl0 = ar45
ar45 = (0.5 * ar44)
ar44 = (ar45 * ar39)
ar39 = (0.5 * ar44)
ar44 = (0.8 * ar43)
ar43 = (ar44 * ar42)
ar42 = (0.5 * ar43)
ar43 = (ar39 + ar42)
ar39 = (1.0 * ar40)
ar40 = (ar39 * ar41)
ar39 = (0.5 * ar40)
ar40 = (ar43 + ar39)
ar39 = (ar46 * ar48)
ar41 = (0.6 * ar51)
ar42 = (ar39 + ar41)
ar39 = (0.5 * ar42)
ar41 = (ar40 + ar39)
ar39 compress ar41, ar0, ir15, ir720, ir720, ir721, ir15, ir15, 0.0
ar0 = (ar39 * 0.8)
arl1 = ar0
ar0 = arl0
ar39 = arl1
 outs ar0, ar39
endin

instr 238
krl0 init 10.0
ir3 FreePort 
ir5 = 0.13541666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 237
    ir12 = 0.0
    ir13 = 7.384615384615385
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 237
arl0 init 0.0
ar0, ar1 subinstr 148
ar2, ar3 subinstr 236
ar4 = (ar0 + ar2)
arl0 = ar4
ar0 = arl0
S12 sprintf "p1_%d", p4
 chnmix ar0, S12
arl1 init 0.0
ar0 = (ar1 + ar3)
arl1 = ar0
ar0 = arl1
S24 sprintf "p2_%d", p4
 chnmix ar0, S24
S27 sprintf "alive_%d", p4
kr0 chnget S27
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S27
endin

instr 236
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 235
    ir13 = 5.538461538461538
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 235
arl0 init 0.0
ar0, ar1 subinstr 234
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 234
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 233
    ir13 = 1.8461538461538463
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 233
arl0 init 0.0
ar0, ar1 subinstr 232
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 232
krl0 init 10.0
ir3 FreePort 
krl1 init 0.0
ir7 = 0.5416666666666666
kr0 metro ir7
if (kr0 == 1.0) then
    kr0 = krl1
    ir13 = 0.0
    ir14 = 1.0
    ar0 random ir13, ir14
    krl0 = 2.0
    ir19 = 231
    ir20 = 0.0
    ir21 = 0.0
    ir22 = 1.0
    kr1 random ir21, ir22
    ir24 = 0.0
    ir25 = 1.0
    kr2 random ir24, ir25
    ir27 = 0.0
    ir28 = 1.0
    kr3 random ir27, ir28
    ir30 = 0.0
    ir31 = 1.0
    kr4 random ir30, ir31
    if (kr4 < 1.0) then
    kr5 = -1.0
else
    kr5 = -1.0
endif
    if (kr3 < 0.75) then
    kr4 = -1.0
else
    kr4 = kr5
endif
    if (kr2 < 0.5) then
    kr3 = -1.0
else
    kr3 = kr4
endif
    if (kr1 < 0.25) then
    kr2 = -1.0
else
    kr2 = kr3
endif
    kr1 = (kr2 * 1.0)
    ir38 = 0.0
    ir39 = 1.0
    kr2 random ir38, ir39
    ir41 = 0.0
    ir42 = 1.0
    kr3 random ir41, ir42
    ir44 = 0.0
    ir45 = 1.0
    kr4 random ir44, ir45
    ir47 = 0.0
    ir48 = 1.0
    kr5 random ir47, ir48
    if (kr5 < 1.0) then
    kr6 = 3.0
else
    kr6 = 3.0
endif
    if (kr4 < 0.75) then
    kr5 = 2.0
else
    kr5 = kr6
endif
    if (kr3 < 0.5) then
    kr4 = 1.0
else
    kr4 = kr5
endif
    if (kr2 < 0.25) then
    kr3 = 0.0
else
    kr3 = kr4
endif
     event "i", ir19, ir20, kr1, kr3, ir3
    kr1 = krl1
    krl1 = kr1
endif
S61 sprintf "p1_%d", ir3
ar1 chnget S61
S64 sprintf "p2_%d", ir3
ar2 chnget S64
 chnclear S61
 chnclear S64
arl2 init 0.0
arl3 init 0.0
arl2 = ar1
arl3 = ar2
ar1 = arl2
ar2 = arl3
 outs ar1, ar2
kr1 = krl0
S87 sprintf "alive_%d", ir3
 chnset kr1, S87
endin

instr 231
arl0 init 0.0
ar0, ar1 subinstr 152
ir5 = 1.0e-2
ir6 = 0.9
ir7 = 8.5
ir8 = 0.84
ar2 Phaser ar0, ir5, ir6, ir7, ir8
ar0 = (0.65 * ar2)
ar2, ar3 subinstr 156
ar4 = (ar0 + ar2)
ar0, ar2 subinstr 162
ir16 = 1.0
ir17 = 0.1
ir18 = 0.5
ar5 Distortion ar0, ir16, ir17, ir18
ir20 = 8.0e-3
ir21 = 0.73
ar0 Flanger ar5, ir18, ir6, ir20, ir21
ar5 = (ar4 + ar0)
ar0, ar4 subinstr 166
ar6 Phaser ar0, ir5, ir6, ir7, ir8
ar0 = (0.65 * ar6)
ar6, ar7 subinstr 172
ar8 = (ar0 + ar6)
ar0, ar6 subinstr 178
ar9 Distortion ar0, ir16, ir17, ir18
ar0 Flanger ar9, ir18, ir6, ir20, ir21
ar9 = (ar8 + ar0)
ar0, ar8 subinstr 184
ar10 = (4.0 * ar0)
ar0 = (ar9 + ar10)
ar9, ar10 subinstr 188
ar11 Phaser ar9, ir5, ir6, ir7, ir8
ar9 = (0.65 * ar11)
ar11, ar12 subinstr 192
ar13 = (ar9 + ar11)
ar9, ar11 subinstr 196
ar14 Distortion ar9, ir16, ir17, ir18
ar9 Flanger ar14, ir18, ir6, ir20, ir21
ar14 = (ar13 + ar9)
ar9, ar13 subinstr 200
ar15 = (ar14 + ar9)
ar9, ar14 subinstr 230
if (3.0 == p4) then
    ar16 = ar9
else
    ar16 = ar5
endif
if (2.0 == p4) then
    ar9 = ar15
else
    ar9 = ar16
endif
if (1.0 == p4) then
    ar15 = ar0
else
    ar15 = ar9
endif
if (0.0 == p4) then
    ar0 = ar5
else
    ar0 = ar15
endif
arl0 = ar0
ar0 = arl0
S65 sprintf "p1_%d", p5
 chnmix ar0, S65
arl1 init 0.0
ar0 Phaser ar1, ir5, ir6, ir7, ir8
ar1 = (0.65 * ar0)
ar0 = (ar1 + ar3)
ar1 Distortion ar2, ir16, ir17, ir18
ar2 Flanger ar1, ir18, ir6, ir20, ir21
ar1 = (ar0 + ar2)
ar0 Phaser ar4, ir5, ir6, ir7, ir8
ar2 = (0.65 * ar0)
ar0 = (ar2 + ar7)
ar2 Distortion ar6, ir16, ir17, ir18
ar3 Flanger ar2, ir18, ir6, ir20, ir21
ar2 = (ar0 + ar3)
ar0 = (4.0 * ar8)
ar3 = (ar2 + ar0)
ar0 Phaser ar10, ir5, ir6, ir7, ir8
ar2 = (0.65 * ar0)
ar0 = (ar2 + ar12)
ar2 Distortion ar11, ir16, ir17, ir18
ar4 Flanger ar2, ir18, ir6, ir20, ir21
ar2 = (ar0 + ar4)
ar0 = (ar2 + ar13)
if (3.0 == p4) then
    ar2 = ar14
else
    ar2 = ar1
endif
if (2.0 == p4) then
    ar4 = ar0
else
    ar4 = ar2
endif
if (1.0 == p4) then
    ar0 = ar3
else
    ar0 = ar4
endif
if (0.0 == p4) then
    ar2 = ar1
else
    ar2 = ar0
endif
arl1 = ar2
ar0 = arl1
S111 sprintf "p2_%d", p5
 chnmix ar0, S111
S114 sprintf "alive_%d", p5
kr0 chnget S114
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S114
endin

instr 230
krl0 init 10.0
ir3 FreePort 
krl1 init 0.0
ir7 = 4.333333333333333
kr0 metro ir7
if (kr0 == 1.0) then
    kr0 = krl1
    ir13 = 0.0
    ir14 = 1.0
    ar0 random ir13, ir14
    krl0 = 2.0
    ir19 = 229
    ir20 = 0.0
    ir21 = 0.0
    ir22 = 1.0
    kr1 random ir21, ir22
    ir24 = 0.0
    ir25 = 1.0
    kr2 random ir24, ir25
    ir27 = 0.0
    ir28 = 1.0
    kr3 random ir27, ir28
    ir30 = 0.0
    ir31 = 1.0
    kr4 random ir30, ir31
    ir33 = 0.0
    ir34 = 1.0
    kr5 random ir33, ir34
    ir36 = 0.0
    ir37 = 1.0
    kr6 random ir36, ir37
    ir39 = 0.0
    ir40 = 1.0
    kr7 random ir39, ir40
    ir42 = 0.0
    ir43 = 1.0
    kr8 random ir42, ir43
    ir45 = 0.0
    ir46 = 1.0
    kr9 random ir45, ir46
    ir48 = 0.0
    ir49 = 1.0
    kr10 random ir48, ir49
    ir51 = 0.0
    ir52 = 1.0
    kr11 random ir51, ir52
    ir54 = 0.0
    ir55 = 1.0
    kr12 random ir54, ir55
    ir57 = 0.0
    ir58 = 1.0
    kr13 random ir57, ir58
    ir60 = 0.0
    ir61 = 1.0
    kr14 random ir60, ir61
    if (kr14 < 0.9999999999999997) then
    kr15 = 0.46153846153846156
else
    kr15 = 0.46153846153846156
endif
    if (kr13 < 0.9285714285714283) then
    kr14 = 0.46153846153846156
else
    kr14 = kr15
endif
    if (kr12 < 0.8571428571428569) then
    kr13 = 0.46153846153846156
else
    kr13 = kr14
endif
    if (kr11 < 0.7857142857142855) then
    kr12 = 0.46153846153846156
else
    kr12 = kr13
endif
    if (kr10 < 0.7142857142857141) then
    kr11 = 0.46153846153846156
else
    kr11 = kr12
endif
    if (kr9 < 0.6428571428571427) then
    kr10 = 0.46153846153846156
else
    kr10 = kr11
endif
    if (kr8 < 0.5714285714285713) then
    kr9 = 0.9230769230769231
else
    kr9 = kr10
endif
    if (kr7 < 0.4999999999999999) then
    kr8 = 0.46153846153846156
else
    kr8 = kr9
endif
    if (kr6 < 0.4285714285714285) then
    kr7 = 0.46153846153846156
else
    kr7 = kr8
endif
    if (kr5 < 0.3571428571428571) then
    kr6 = 0.46153846153846156
else
    kr6 = kr7
endif
    if (kr4 < 0.2857142857142857) then
    kr5 = 0.46153846153846156
else
    kr5 = kr6
endif
    if (kr3 < 0.21428571428571427) then
    kr4 = 0.9230769230769231
else
    kr4 = kr5
endif
    if (kr2 < 0.14285714285714285) then
    kr3 = 0.46153846153846156
else
    kr3 = kr4
endif
    if (kr1 < 7.142857142857142e-2) then
    kr2 = 0.46153846153846156
else
    kr2 = kr3
endif
    kr1 = (kr2 * 1.0)
    ir78 = 0.0
    ir79 = 1.0
    kr2 random ir78, ir79
    ir81 = 0.0
    ir82 = 1.0
    kr3 random ir81, ir82
    ir84 = 0.0
    ir85 = 1.0
    kr4 random ir84, ir85
    ir87 = 0.0
    ir88 = 1.0
    kr5 random ir87, ir88
    ir90 = 0.0
    ir91 = 1.0
    kr6 random ir90, ir91
    ir93 = 0.0
    ir94 = 1.0
    kr7 random ir93, ir94
    ir96 = 0.0
    ir97 = 1.0
    kr8 random ir96, ir97
    ir99 = 0.0
    ir100 = 1.0
    kr9 random ir99, ir100
    ir102 = 0.0
    ir103 = 1.0
    kr10 random ir102, ir103
    ir105 = 0.0
    ir106 = 1.0
    kr11 random ir105, ir106
    ir108 = 0.0
    ir109 = 1.0
    kr12 random ir108, ir109
    ir111 = 0.0
    ir112 = 1.0
    kr13 random ir111, ir112
    ir114 = 0.0
    ir115 = 1.0
    kr14 random ir114, ir115
    ir117 = 0.0
    ir118 = 1.0
    kr15 random ir117, ir118
    if (kr15 < 0.9999999999999997) then
    kr16 = 13.0
else
    kr16 = 13.0
endif
    if (kr14 < 0.9285714285714283) then
    kr15 = 12.0
else
    kr15 = kr16
endif
    if (kr13 < 0.8571428571428569) then
    kr14 = 11.0
else
    kr14 = kr15
endif
    if (kr12 < 0.7857142857142855) then
    kr13 = 10.0
else
    kr13 = kr14
endif
    if (kr11 < 0.7142857142857141) then
    kr12 = 9.0
else
    kr12 = kr13
endif
    if (kr10 < 0.6428571428571427) then
    kr11 = 8.0
else
    kr11 = kr12
endif
    if (kr9 < 0.5714285714285713) then
    kr10 = 7.0
else
    kr10 = kr11
endif
    if (kr8 < 0.4999999999999999) then
    kr9 = 6.0
else
    kr9 = kr10
endif
    if (kr7 < 0.4285714285714285) then
    kr8 = 5.0
else
    kr8 = kr9
endif
    if (kr6 < 0.3571428571428571) then
    kr7 = 4.0
else
    kr7 = kr8
endif
    if (kr5 < 0.2857142857142857) then
    kr6 = 3.0
else
    kr6 = kr7
endif
    if (kr4 < 0.21428571428571427) then
    kr5 = 2.0
else
    kr5 = kr6
endif
    if (kr3 < 0.14285714285714285) then
    kr4 = 1.0
else
    kr4 = kr5
endif
    if (kr2 < 7.142857142857142e-2) then
    kr3 = 0.0
else
    kr3 = kr4
endif
     event "i", ir19, ir20, kr1, kr3, ir3
    kr1 = krl1
    krl1 = kr1
endif
S141 sprintf "p1_%d", ir3
ar1 chnget S141
S144 sprintf "p2_%d", ir3
ar2 chnget S144
 chnclear S141
 chnclear S144
arl2 init 0.0
arl3 init 0.0
arl2 = ar1
arl3 = ar2
ar1 = arl2
ar2 = arl3
 outs ar1, ar2
kr1 = krl0
S167 sprintf "alive_%d", ir3
 chnset kr1, S167
endin

instr 229
arl0 init 0.0
ar0, ar1 subinstr 202
ar2, ar3 subinstr 204
ir7 = 1.0
ir8 = 0.1
ir9 = 0.5
ar4 Distortion ar2, ir7, ir8, ir9
ir11 = 0.9
ir12 = 8.0e-3
ir13 = 0.73
ar2 Flanger ar4, ir9, ir11, ir12, ir13
ar4, ar5 subinstr 206
ar6, ar7 subinstr 208
ir19 = 1.0e-2
ir20 = 8.5
ir21 = 0.84
ar8 Phaser ar6, ir19, ir11, ir20, ir21
ar6 = (0.65 * ar8)
ar8, ar9 subinstr 210
ar10, ar11 subinstr 212
ar12, ar13 subinstr 214
ar14, ar15 subinstr 216
ar16, ar17 subinstr 218
ar18, ar19 subinstr 220
ar20, ar21 subinstr 222
ar22, ar23 subinstr 224
ar24, ar25 subinstr 226
ar26, ar27 subinstr 228
if (13.0 == p4) then
    ar28 = ar26
else
    ar28 = ar0
endif
if (12.0 == p4) then
    ar26 = ar24
else
    ar26 = ar28
endif
if (11.0 == p4) then
    ar24 = ar22
else
    ar24 = ar26
endif
if (10.0 == p4) then
    ar22 = ar20
else
    ar22 = ar24
endif
if (9.0 == p4) then
    ar20 = ar18
else
    ar20 = ar22
endif
if (8.0 == p4) then
    ar18 = ar16
else
    ar18 = ar20
endif
if (7.0 == p4) then
    ar16 = ar14
else
    ar16 = ar18
endif
if (6.0 == p4) then
    ar14 = ar12
else
    ar14 = ar16
endif
if (5.0 == p4) then
    ar12 = ar10
else
    ar12 = ar14
endif
if (4.0 == p4) then
    ar10 = ar8
else
    ar10 = ar12
endif
if (3.0 == p4) then
    ar8 = ar6
else
    ar8 = ar10
endif
if (2.0 == p4) then
    ar6 = ar4
else
    ar6 = ar8
endif
if (1.0 == p4) then
    ar4 = ar2
else
    ar4 = ar6
endif
if (0.0 == p4) then
    ar2 = ar0
else
    ar2 = ar4
endif
arl0 = ar2
ar0 = arl0
S62 sprintf "p1_%d", p5
 chnmix ar0, S62
arl1 init 0.0
ar0 Distortion ar3, ir7, ir8, ir9
ar2 Flanger ar0, ir9, ir11, ir12, ir13
ar0 Phaser ar7, ir19, ir11, ir20, ir21
ar3 = (0.65 * ar0)
if (13.0 == p4) then
    ar0 = ar27
else
    ar0 = ar1
endif
if (12.0 == p4) then
    ar4 = ar25
else
    ar4 = ar0
endif
if (11.0 == p4) then
    ar0 = ar23
else
    ar0 = ar4
endif
if (10.0 == p4) then
    ar4 = ar21
else
    ar4 = ar0
endif
if (9.0 == p4) then
    ar0 = ar19
else
    ar0 = ar4
endif
if (8.0 == p4) then
    ar4 = ar17
else
    ar4 = ar0
endif
if (7.0 == p4) then
    ar0 = ar15
else
    ar0 = ar4
endif
if (6.0 == p4) then
    ar4 = ar13
else
    ar4 = ar0
endif
if (5.0 == p4) then
    ar0 = ar11
else
    ar0 = ar4
endif
if (4.0 == p4) then
    ar4 = ar9
else
    ar4 = ar0
endif
if (3.0 == p4) then
    ar0 = ar3
else
    ar0 = ar4
endif
if (2.0 == p4) then
    ar3 = ar5
else
    ar3 = ar0
endif
if (1.0 == p4) then
    ar0 = ar2
else
    ar0 = ar3
endif
if (0.0 == p4) then
    ar2 = ar1
else
    ar2 = ar0
endif
arl1 = ar2
ar0 = arl1
S103 sprintf "p2_%d", p5
 chnmix ar0, S103
S106 sprintf "alive_%d", p5
kr0 chnget S106
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S106
endin

instr 228
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 227
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 227
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (227.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.328, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (227.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 226
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 225
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 225
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (310.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.264, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (310.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 224
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 223
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 223
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (420.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.17600000000000002, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (420.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 222
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 221
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 221
arl0 init 0.0
ar0 expsega 0.4, 1.1200000000000002e-2, 1.0, 8.0e-3, 5.0e-2, 4.000000000000001e-2, 1.0e-3, 1.0, 1.0e-3
ir4 = 0.75
ir5 = 0.0
ar1 noise ir4, ir5
kr0 = octave(ir5)
ar2 upsamp kr0
ar3 = (6000.0 * ar2)
ir9 = 20.0
kr0 = (sr / 2.0)
ar4 limit ar3, ir9, kr0
ar3 buthp ar1, ar4
ar1 = (12000.0 * ar2)
kr0 = (sr / 3.0)
ar2 limit ar1, ir9, kr0
ar1 butlp ar3, ar2
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 220
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 219
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 219
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (2.7e-2 * ir6)
ar0 expsega 1.0, ir7, 1.0e-3, 1.0, 1.0e-3
ar1 = (ar0 - 1.0e-3)
ar0 = (0.5 * ar1)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 1700.0)
kr0 = (1700.0 + kr1)
kr1 = birnd(ir3)
kr2 = (kr1 * 0.7)
kr1 = octave(kr2)
kr2 = (kr0 * kr1)
ir20 = rnd(ir11)
ar1 oscil3 ir11, kr2, 8, ir20
kr0 = (kr2 * 8.0)
ar2 butbp ar1, kr2, kr0
ar1 = (ar0 * ar2)
ir25 = (ir7 - 2.0e-3)
ir26 = (ir25 - 5.0e-3)
ar0 expsega 1.0, 2.0e-3, 0.8, 5.0e-3, 0.5, ir26, 1.0e-4, 1.0, 1.0e-4
ar2 = (ar0 - 1.0e-3)
ir29 = 0.0
ar0 noise ir11, ir29
kr0 expsegr 4000.0, ir7, 20.0, 1.0, 20.0, ir7, 20.0
ar3 upsamp kr0
ar4 butlp ar0, ar3
ar0 = (ar2 * ar4)
ar2 = (ar1 + ar0)
ar0 = (0.8 * ar2)
ir36 = 9.0e-2
kr0 = birnd(ir36)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S44 sprintf "p1_%d", p4
 chnmix ar0, S44
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S53 sprintf "p2_%d", p4
 chnmix ar0, S53
S56 sprintf "alive_%d", p4
kr0 chnget S56
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S56
endin

instr 218
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 217
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 217
arl0 init 0.0
ar0 expsega 1.0, 3.6e-2, 1.0e-3, 1.0, 1.0e-3
ar1 = (ar0 - 1.0e-3)
ar0 = (0.4 * ar1)
ar1 = (-ar0)
ir7 = 1.0
ir8 = 0.0
kr0 = octave(ir8)
kr1 = (2500.0 * kr0)
ar0 upsamp kr1
ar2 expsega 3.0, 5.0e-5, 1.0, 1.0, 1.0
ar3 = (ar0 * ar2)
ir13 = rnd(ir7)
ar0 oscil3 ir7, ar3, 2, ir13
ar2 = (ar1 * ar0)
ir16 = 9.0e-2
kr0 = birnd(ir16)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S24 sprintf "p1_%d", p4
 chnmix ar1, S24
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S33 sprintf "p2_%d", p4
 chnmix ar0, S33
S36 sprintf "alive_%d", p4
kr0 chnget S36
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S36
endin

instr 216
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 215
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 215
arl0 init 0.0
ar0 expon 1.0, 1.6, 1.0e-4
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
kr0 = (0.962 * kr1)
ar3 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir27 = 5000.0
ar2 reson ar1, ar3, ir27, 1.0
ir29 = 10000.0
ar1 upsamp k(ir29)
ar3 buthp ar2, ar1
ir31 = 12000.0
ar1 upsamp k(ir31)
ar2 butlp ar3, ar1
ar3 butlp ar2, ar1
ar1 = (ar0 * ar3)
ar0 expsega 1.0, 0.3, 7.0e-2, 1.5, 1.0e-5, 1.0, 1.0e-5
ir36 = 0.8
ar2 noise ir36, ir5
kr0 expseg 14000.0, 0.7, 7000.0, 1.5, 5000.0, 1.0, 5000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir40 = 8000.0
ar2 upsamp k(ir40)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir44 = 9.0e-2
kr0 = birnd(ir44)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S52 sprintf "p1_%d", p4
 chnmix ar0, S52
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S61 sprintf "p2_%d", p4
 chnmix ar0, S61
S64 sprintf "alive_%d", p4
kr0 chnget S64
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S64
endin

instr 214
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 213
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 213
arl0 init 0.0
kr0 linseg 0.0, 4.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 transeg 1.0, 0.48, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar1 upsamp kr0
ar2 = (ar0 * ar1)
ar0 = (-ar2)
ir7 = 1.0
ir8 = 0.0
ir9 = octave(ir8)
kr0 = (90.0 * ir9)
ar1 upsamp kr0
ir11 = (90.0 * ir9)
ir12 = (0.125 / ir11)
ar2 expsega 5.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir7)
ar1 oscil3 ir7, ar3, 2, ir15
ar2 = (ar0 * ar1)
kr0 transeg 1.0, 0.48, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir19 = 0.4
ar1 noise ir7, ir19
kr0 = octave(ir8)
ar3 upsamp kr0
ar4 = (40.0 * ar3)
ir23 = 800.0
ar5 reson ar1, ar4, ir23, 1.0
ar1 = (100.0 * ar3)
ar4 buthp ar5, ar1
ar1 = (600.0 * ar3)
ar3 butlp ar4, ar1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir31 = 9.0e-2
kr0 = birnd(ir31)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S39 sprintf "p1_%d", p4
 chnmix ar0, S39
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S48 sprintf "p2_%d", p4
 chnmix ar0, S48
S51 sprintf "alive_%d", p4
kr0 chnget S51
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S51
endin

instr 212
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 211
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 211
arl0 init 0.0
kr0 linseg 0.0, 4.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 transeg 1.0, 0.48, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar1 upsamp kr0
ar2 = (ar0 * ar1)
ar0 = (-ar2)
ir7 = 1.0
ir8 = 0.0
ir9 = octave(ir8)
kr0 = (133.0 * ir9)
ar1 upsamp kr0
ir11 = (133.0 * ir9)
ir12 = (0.125 / ir11)
ar2 expsega 5.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir7)
ar1 oscil3 ir7, ar3, 2, ir15
ar2 = (ar0 * ar1)
kr0 transeg 1.0, 0.48, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir19 = 0.4
ar1 noise ir7, ir19
kr0 = octave(ir8)
ar3 upsamp kr0
ar4 = (400.0 * ar3)
ir23 = 800.0
ar5 reson ar1, ar4, ir23, 1.0
ar1 = (100.0 * ar3)
ar4 buthp ar5, ar1
ar1 = (600.0 * ar3)
ar3 butlp ar4, ar1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir31 = 9.0e-2
kr0 = birnd(ir31)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S39 sprintf "p1_%d", p4
 chnmix ar0, S39
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S48 sprintf "p2_%d", p4
 chnmix ar0, S48
S51 sprintf "alive_%d", p4
kr0 chnget S51
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S51
endin

instr 210
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 209
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 209
arl0 init 0.0
kr0 linseg 0.0, 4.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 transeg 1.0, 0.4, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar1 upsamp kr0
ar2 = (ar0 * ar1)
ar0 = (-ar2)
ir7 = 1.0
ir8 = 0.0
ir9 = octave(ir8)
kr0 = (200.0 * ir9)
ar1 upsamp kr0
ir11 = (200.0 * ir9)
ir12 = (0.125 / ir11)
ar2 expsega 5.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir7)
ar1 oscil3 ir7, ar3, 2, ir15
ar2 = (ar0 * ar1)
kr0 transeg 1.0, 0.4, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir19 = 0.4
ar1 noise ir7, ir19
kr0 = octave(ir8)
ar3 upsamp kr0
ar4 = (400.0 * ar3)
ir23 = 800.0
ar5 reson ar1, ar4, ir23, 1.0
ar1 = (100.0 * ar3)
ar4 buthp ar5, ar1
ar1 = (1000.0 * ar3)
ar3 butlp ar4, ar1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir31 = 9.0e-2
kr0 = birnd(ir31)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S39 sprintf "p1_%d", p4
 chnmix ar0, S39
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S48 sprintf "p2_%d", p4
 chnmix ar0, S48
S51 sprintf "alive_%d", p4
kr0 chnget S51
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S51
endin

instr 208
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 207
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 207
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 206
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 205
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 205
arl0 init 0.0
kr0 linsegr 1.0, 0.35000000000000003, 0.1, 5.0e-2, 0.0, 1.0, 0.0, 0.8, 0.0
ar0 upsamp kr0
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 204
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 203
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 203
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 202
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 201
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 201
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 200
krl0 init 10.0
ir3 FreePort 
ir5 = 0.6190476190476191
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 6.0
    ir11 = 199
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
    ir16 = 199
    ir17 = 0.11538461538461539
    ir18 = 0.46153846153846156
     event "i", ir16, ir17, ir18, ir3
    ir21 = 199
    ir22 = 0.23076923076923078
    ir23 = 0.46153846153846156
     event "i", ir21, ir22, ir23, ir3
endif
S28 sprintf "p1_%d", ir3
ar0 chnget S28
S31 sprintf "p2_%d", ir3
ar1 chnget S31
 chnclear S28
 chnclear S31
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S54 sprintf "alive_%d", ir3
 chnset kr0, S54
endin

instr 199
arl0 init 0.0
ar0, ar1 subinstr 198
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 198
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 197
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 197
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 196
krl0 init 10.0
ir3 FreePort 
ir5 = 2.888888888888889
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 195
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 195
arl0 init 0.0
ar0, ar1 subinstr 194
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 194
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 193
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 193
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 192
krl0 init 10.0
ir3 FreePort 
ir5 = 1.0833333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 191
    ir12 = 0.0
    ir13 = 0.9230769230769231
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 191
arl0 init 0.0
ar0, ar1 subinstr 190
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 190
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 189
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 189
arl0 init 0.0
ar0 expon 1.0, 1.6, 1.0e-4
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
kr0 = (0.962 * kr1)
ar3 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir27 = 5000.0
ar2 reson ar1, ar3, ir27, 1.0
ir29 = 10000.0
ar1 upsamp k(ir29)
ar3 buthp ar2, ar1
ir31 = 12000.0
ar1 upsamp k(ir31)
ar2 butlp ar3, ar1
ar3 butlp ar2, ar1
ar1 = (ar0 * ar3)
ar0 expsega 1.0, 0.3, 7.0e-2, 1.5, 1.0e-5, 1.0, 1.0e-5
ir36 = 0.8
ar2 noise ir36, ir5
kr0 expseg 14000.0, 0.7, 7000.0, 1.5, 5000.0, 1.0, 5000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir40 = 8000.0
ar2 upsamp k(ir40)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir44 = 9.0e-2
kr0 = birnd(ir44)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S52 sprintf "p1_%d", p4
 chnmix ar0, S52
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S61 sprintf "p2_%d", p4
 chnmix ar0, S61
S64 sprintf "alive_%d", p4
kr0 chnget S64
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S64
endin

instr 188
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 187
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 187
arl0 init 0.0
ar0, ar1 subinstr 186
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 186
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 185
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 185
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 184
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 183
    ir13 = 0.46153846153846156
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 183
arl0 init 0.0
ar0, ar1 subinstr 182
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 182
krl0 init 10.0
ir3 FreePort 
ir5 = 1.7333333333333334
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 4.0
    ir11 = 181
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
    ir16 = 181
    ir17 = 0.23076923076923078
    ir18 = 0.46153846153846156
     event "i", ir16, ir17, ir18, ir3
endif
S23 sprintf "p1_%d", ir3
ar0 chnget S23
S26 sprintf "p2_%d", ir3
ar1 chnget S26
 chnclear S23
 chnclear S26
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S49 sprintf "alive_%d", ir3
 chnset kr0, S49
endin

instr 181
arl0 init 0.0
ar0, ar1 subinstr 180
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 180
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 179
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 179
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (420.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.17600000000000002, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (420.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 178
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 177
    ir13 = 1.6153846153846154
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 177
arl0 init 0.0
ar0, ar1 subinstr 176
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 176
krl0 init 10.0
ir3 FreePort 
ir5 = 8.666666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 175
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 175
arl0 init 0.0
ar0, ar1 subinstr 174
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 174
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 173
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 173
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 172
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 171
    ir13 = 0.23076923076923078
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 171
arl0 init 0.0
ar0, ar1 subinstr 170
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 170
krl0 init 10.0
ir3 FreePort 
ir5 = 1.2380952380952381
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 169
    ir12 = 0.0
    ir13 = 0.9230769230769231
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 169
arl0 init 0.0
ar0, ar1 subinstr 168
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 168
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 167
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 167
arl0 init 0.0
kr0 linsegr 1.0, 0.35000000000000003, 0.1, 5.0e-2, 0.0, 1.0, 0.0, 0.8, 0.0
ar0 upsamp kr0
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 166
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 12.0
    ir11 = 165
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
    ir16 = 165
    ir17 = 0.23076923076923078
    ir18 = 0.46153846153846156
     event "i", ir16, ir17, ir18, ir3
    ir21 = 165
    ir22 = 0.46153846153846156
    ir23 = 0.46153846153846156
     event "i", ir21, ir22, ir23, ir3
    ir26 = 165
    ir27 = 0.6923076923076923
    ir28 = 0.46153846153846156
     event "i", ir26, ir27, ir28, ir3
    ir31 = 165
    ir32 = 0.8076923076923077
    ir33 = 0.46153846153846156
     event "i", ir31, ir32, ir33, ir3
    ir36 = 165
    ir37 = 1.0384615384615385
    ir38 = 0.46153846153846156
     event "i", ir36, ir37, ir38, ir3
endif
S43 sprintf "p1_%d", ir3
ar0 chnget S43
S46 sprintf "p2_%d", ir3
ar1 chnget S46
 chnclear S43
 chnclear S46
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S69 sprintf "alive_%d", ir3
 chnset kr0, S69
endin

instr 165
arl0 init 0.0
ar0, ar1 subinstr 164
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 164
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 163
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 163
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 162
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 161
    ir13 = 0.9230769230769231
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 161
arl0 init 0.0
ar0, ar1 subinstr 160
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 160
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 159
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 159
arl0 init 0.0
ar0, ar1 subinstr 158
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 158
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 157
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 157
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 156
krl0 init 10.0
ir3 FreePort 
ir5 = 2.1666666666666665
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 155
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 155
arl0 init 0.0
ar0, ar1 subinstr 154
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 154
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 153
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 153
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 152
krl0 init 10.0
ir3 FreePort 
ir5 = 4.333333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 151
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 151
arl0 init 0.0
ar0, ar1 subinstr 150
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 150
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 149
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 149
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 148
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 147
    ir13 = 5.538461538461538
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 147
arl0 init 0.0
ar0, ar1 subinstr 136
ir5 = 1.0e-2
ir6 = 0.9
ir7 = 8.5
ir8 = 0.84
ar2 Phaser ar0, ir5, ir6, ir7, ir8
ar0 = (0.65 * ar2)
ar2, ar3 subinstr 140
ar4 = (ar0 + ar2)
ar0, ar2 subinstr 146
ir16 = 1.0
ir17 = 0.1
ir18 = 0.5
ar5 Distortion ar0, ir16, ir17, ir18
ir20 = 8.0e-3
ir21 = 0.73
ar0 Flanger ar5, ir18, ir6, ir20, ir21
ar5 = (ar4 + ar0)
arl0 = ar5
ar0 = arl0
S28 sprintf "p1_%d", p4
 chnmix ar0, S28
arl1 init 0.0
ar0 Phaser ar1, ir5, ir6, ir7, ir8
ar1 = (0.65 * ar0)
ar0 = (ar1 + ar3)
ar1 Distortion ar2, ir16, ir17, ir18
ar2 Flanger ar1, ir18, ir6, ir20, ir21
ar1 = (ar0 + ar2)
arl1 = ar1
ar0 = arl1
S46 sprintf "p2_%d", p4
 chnmix ar0, S46
S49 sprintf "alive_%d", p4
kr0 chnget S49
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S49
endin

instr 146
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 145
    ir13 = 0.9230769230769231
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 145
arl0 init 0.0
ar0, ar1 subinstr 144
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 144
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 143
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 143
arl0 init 0.0
ar0, ar1 subinstr 142
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 142
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 141
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 141
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 140
krl0 init 10.0
ir3 FreePort 
ir5 = 2.1666666666666665
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 139
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 139
arl0 init 0.0
ar0, ar1 subinstr 138
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 138
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 137
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 137
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 136
krl0 init 10.0
ir3 FreePort 
ir5 = 4.333333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 135
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 135
arl0 init 0.0
ar0, ar1 subinstr 134
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 134
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 133
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 133
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 132
krl0 init 10.0
ir3 FreePort 
ir5 = 0.13541666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 131
    ir12 = 0.0
    ir13 = 7.384615384615385
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 131
arl0 init 0.0
ar0, ar1 subinstr 42
ar2, ar3 subinstr 130
ar4 = (ar0 + ar2)
arl0 = ar4
ar0 = arl0
S12 sprintf "p1_%d", p4
 chnmix ar0, S12
arl1 init 0.0
ar0 = (ar1 + ar3)
arl1 = ar0
ar0 = arl1
S24 sprintf "p2_%d", p4
 chnmix ar0, S24
S27 sprintf "alive_%d", p4
kr0 chnget S27
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S27
endin

instr 130
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 129
    ir13 = 5.538461538461538
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 129
arl0 init 0.0
ar0, ar1 subinstr 128
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 128
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 127
    ir13 = 1.8461538461538463
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 127
arl0 init 0.0
ar0, ar1 subinstr 126
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 126
krl0 init 10.0
ir3 FreePort 
krl1 init 0.0
ir7 = 0.5416666666666666
kr0 metro ir7
if (kr0 == 1.0) then
    kr0 = krl1
    ir13 = 0.0
    ir14 = 1.0
    ar0 random ir13, ir14
    krl0 = 2.0
    ir19 = 125
    ir20 = 0.0
    ir21 = 0.0
    ir22 = 1.0
    kr1 random ir21, ir22
    ir24 = 0.0
    ir25 = 1.0
    kr2 random ir24, ir25
    ir27 = 0.0
    ir28 = 1.0
    kr3 random ir27, ir28
    ir30 = 0.0
    ir31 = 1.0
    kr4 random ir30, ir31
    if (kr4 < 1.0) then
    kr5 = -1.0
else
    kr5 = -1.0
endif
    if (kr3 < 0.75) then
    kr4 = -1.0
else
    kr4 = kr5
endif
    if (kr2 < 0.5) then
    kr3 = -1.0
else
    kr3 = kr4
endif
    if (kr1 < 0.25) then
    kr2 = -1.0
else
    kr2 = kr3
endif
    kr1 = (kr2 * 1.0)
    ir38 = 0.0
    ir39 = 1.0
    kr2 random ir38, ir39
    ir41 = 0.0
    ir42 = 1.0
    kr3 random ir41, ir42
    ir44 = 0.0
    ir45 = 1.0
    kr4 random ir44, ir45
    ir47 = 0.0
    ir48 = 1.0
    kr5 random ir47, ir48
    if (kr5 < 1.0) then
    kr6 = 3.0
else
    kr6 = 3.0
endif
    if (kr4 < 0.75) then
    kr5 = 2.0
else
    kr5 = kr6
endif
    if (kr3 < 0.5) then
    kr4 = 1.0
else
    kr4 = kr5
endif
    if (kr2 < 0.25) then
    kr3 = 0.0
else
    kr3 = kr4
endif
     event "i", ir19, ir20, kr1, kr3, ir3
    kr1 = krl1
    krl1 = kr1
endif
S61 sprintf "p1_%d", ir3
ar1 chnget S61
S64 sprintf "p2_%d", ir3
ar2 chnget S64
 chnclear S61
 chnclear S64
arl2 init 0.0
arl3 init 0.0
arl2 = ar1
arl3 = ar2
ar1 = arl2
ar2 = arl3
 outs ar1, ar2
kr1 = krl0
S87 sprintf "alive_%d", ir3
 chnset kr1, S87
endin

instr 125
arl0 init 0.0
ar0, ar1 subinstr 46
ir5 = 1.0e-2
ir6 = 0.9
ir7 = 8.5
ir8 = 0.84
ar2 Phaser ar0, ir5, ir6, ir7, ir8
ar0 = (0.65 * ar2)
ar2, ar3 subinstr 50
ar4 = (ar0 + ar2)
ar0, ar2 subinstr 56
ir16 = 1.0
ir17 = 0.1
ir18 = 0.5
ar5 Distortion ar0, ir16, ir17, ir18
ir20 = 8.0e-3
ir21 = 0.73
ar0 Flanger ar5, ir18, ir6, ir20, ir21
ar5 = (ar4 + ar0)
ar0, ar4 subinstr 60
ar6 Phaser ar0, ir5, ir6, ir7, ir8
ar0 = (0.65 * ar6)
ar6, ar7 subinstr 66
ar8 = (ar0 + ar6)
ar0, ar6 subinstr 72
ar9 Distortion ar0, ir16, ir17, ir18
ar0 Flanger ar9, ir18, ir6, ir20, ir21
ar9 = (ar8 + ar0)
ar0, ar8 subinstr 78
ar10 = (4.0 * ar0)
ar0 = (ar9 + ar10)
ar9, ar10 subinstr 82
ar11 Phaser ar9, ir5, ir6, ir7, ir8
ar9 = (0.65 * ar11)
ar11, ar12 subinstr 86
ar13 = (ar9 + ar11)
ar9, ar11 subinstr 90
ar14 Distortion ar9, ir16, ir17, ir18
ar9 Flanger ar14, ir18, ir6, ir20, ir21
ar14 = (ar13 + ar9)
ar9, ar13 subinstr 94
ar15 = (ar14 + ar9)
ar9, ar14 subinstr 124
if (3.0 == p4) then
    ar16 = ar9
else
    ar16 = ar5
endif
if (2.0 == p4) then
    ar9 = ar15
else
    ar9 = ar16
endif
if (1.0 == p4) then
    ar15 = ar0
else
    ar15 = ar9
endif
if (0.0 == p4) then
    ar0 = ar5
else
    ar0 = ar15
endif
arl0 = ar0
ar0 = arl0
S65 sprintf "p1_%d", p5
 chnmix ar0, S65
arl1 init 0.0
ar0 Phaser ar1, ir5, ir6, ir7, ir8
ar1 = (0.65 * ar0)
ar0 = (ar1 + ar3)
ar1 Distortion ar2, ir16, ir17, ir18
ar2 Flanger ar1, ir18, ir6, ir20, ir21
ar1 = (ar0 + ar2)
ar0 Phaser ar4, ir5, ir6, ir7, ir8
ar2 = (0.65 * ar0)
ar0 = (ar2 + ar7)
ar2 Distortion ar6, ir16, ir17, ir18
ar3 Flanger ar2, ir18, ir6, ir20, ir21
ar2 = (ar0 + ar3)
ar0 = (4.0 * ar8)
ar3 = (ar2 + ar0)
ar0 Phaser ar10, ir5, ir6, ir7, ir8
ar2 = (0.65 * ar0)
ar0 = (ar2 + ar12)
ar2 Distortion ar11, ir16, ir17, ir18
ar4 Flanger ar2, ir18, ir6, ir20, ir21
ar2 = (ar0 + ar4)
ar0 = (ar2 + ar13)
if (3.0 == p4) then
    ar2 = ar14
else
    ar2 = ar1
endif
if (2.0 == p4) then
    ar4 = ar0
else
    ar4 = ar2
endif
if (1.0 == p4) then
    ar0 = ar3
else
    ar0 = ar4
endif
if (0.0 == p4) then
    ar2 = ar1
else
    ar2 = ar0
endif
arl1 = ar2
ar0 = arl1
S111 sprintf "p2_%d", p5
 chnmix ar0, S111
S114 sprintf "alive_%d", p5
kr0 chnget S114
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S114
endin

instr 124
krl0 init 10.0
ir3 FreePort 
krl1 init 0.0
ir7 = 4.333333333333333
kr0 metro ir7
if (kr0 == 1.0) then
    kr0 = krl1
    ir13 = 0.0
    ir14 = 1.0
    ar0 random ir13, ir14
    krl0 = 2.0
    ir19 = 123
    ir20 = 0.0
    ir21 = 0.0
    ir22 = 1.0
    kr1 random ir21, ir22
    ir24 = 0.0
    ir25 = 1.0
    kr2 random ir24, ir25
    ir27 = 0.0
    ir28 = 1.0
    kr3 random ir27, ir28
    ir30 = 0.0
    ir31 = 1.0
    kr4 random ir30, ir31
    ir33 = 0.0
    ir34 = 1.0
    kr5 random ir33, ir34
    ir36 = 0.0
    ir37 = 1.0
    kr6 random ir36, ir37
    ir39 = 0.0
    ir40 = 1.0
    kr7 random ir39, ir40
    ir42 = 0.0
    ir43 = 1.0
    kr8 random ir42, ir43
    ir45 = 0.0
    ir46 = 1.0
    kr9 random ir45, ir46
    ir48 = 0.0
    ir49 = 1.0
    kr10 random ir48, ir49
    ir51 = 0.0
    ir52 = 1.0
    kr11 random ir51, ir52
    ir54 = 0.0
    ir55 = 1.0
    kr12 random ir54, ir55
    ir57 = 0.0
    ir58 = 1.0
    kr13 random ir57, ir58
    ir60 = 0.0
    ir61 = 1.0
    kr14 random ir60, ir61
    if (kr14 < 0.9999999999999997) then
    kr15 = 0.46153846153846156
else
    kr15 = 0.46153846153846156
endif
    if (kr13 < 0.9285714285714283) then
    kr14 = 0.46153846153846156
else
    kr14 = kr15
endif
    if (kr12 < 0.8571428571428569) then
    kr13 = 0.46153846153846156
else
    kr13 = kr14
endif
    if (kr11 < 0.7857142857142855) then
    kr12 = 0.46153846153846156
else
    kr12 = kr13
endif
    if (kr10 < 0.7142857142857141) then
    kr11 = 0.46153846153846156
else
    kr11 = kr12
endif
    if (kr9 < 0.6428571428571427) then
    kr10 = 0.46153846153846156
else
    kr10 = kr11
endif
    if (kr8 < 0.5714285714285713) then
    kr9 = 0.9230769230769231
else
    kr9 = kr10
endif
    if (kr7 < 0.4999999999999999) then
    kr8 = 0.46153846153846156
else
    kr8 = kr9
endif
    if (kr6 < 0.4285714285714285) then
    kr7 = 0.46153846153846156
else
    kr7 = kr8
endif
    if (kr5 < 0.3571428571428571) then
    kr6 = 0.46153846153846156
else
    kr6 = kr7
endif
    if (kr4 < 0.2857142857142857) then
    kr5 = 0.46153846153846156
else
    kr5 = kr6
endif
    if (kr3 < 0.21428571428571427) then
    kr4 = 0.9230769230769231
else
    kr4 = kr5
endif
    if (kr2 < 0.14285714285714285) then
    kr3 = 0.46153846153846156
else
    kr3 = kr4
endif
    if (kr1 < 7.142857142857142e-2) then
    kr2 = 0.46153846153846156
else
    kr2 = kr3
endif
    kr1 = (kr2 * 1.0)
    ir78 = 0.0
    ir79 = 1.0
    kr2 random ir78, ir79
    ir81 = 0.0
    ir82 = 1.0
    kr3 random ir81, ir82
    ir84 = 0.0
    ir85 = 1.0
    kr4 random ir84, ir85
    ir87 = 0.0
    ir88 = 1.0
    kr5 random ir87, ir88
    ir90 = 0.0
    ir91 = 1.0
    kr6 random ir90, ir91
    ir93 = 0.0
    ir94 = 1.0
    kr7 random ir93, ir94
    ir96 = 0.0
    ir97 = 1.0
    kr8 random ir96, ir97
    ir99 = 0.0
    ir100 = 1.0
    kr9 random ir99, ir100
    ir102 = 0.0
    ir103 = 1.0
    kr10 random ir102, ir103
    ir105 = 0.0
    ir106 = 1.0
    kr11 random ir105, ir106
    ir108 = 0.0
    ir109 = 1.0
    kr12 random ir108, ir109
    ir111 = 0.0
    ir112 = 1.0
    kr13 random ir111, ir112
    ir114 = 0.0
    ir115 = 1.0
    kr14 random ir114, ir115
    ir117 = 0.0
    ir118 = 1.0
    kr15 random ir117, ir118
    if (kr15 < 0.9999999999999997) then
    kr16 = 13.0
else
    kr16 = 13.0
endif
    if (kr14 < 0.9285714285714283) then
    kr15 = 12.0
else
    kr15 = kr16
endif
    if (kr13 < 0.8571428571428569) then
    kr14 = 11.0
else
    kr14 = kr15
endif
    if (kr12 < 0.7857142857142855) then
    kr13 = 10.0
else
    kr13 = kr14
endif
    if (kr11 < 0.7142857142857141) then
    kr12 = 9.0
else
    kr12 = kr13
endif
    if (kr10 < 0.6428571428571427) then
    kr11 = 8.0
else
    kr11 = kr12
endif
    if (kr9 < 0.5714285714285713) then
    kr10 = 7.0
else
    kr10 = kr11
endif
    if (kr8 < 0.4999999999999999) then
    kr9 = 6.0
else
    kr9 = kr10
endif
    if (kr7 < 0.4285714285714285) then
    kr8 = 5.0
else
    kr8 = kr9
endif
    if (kr6 < 0.3571428571428571) then
    kr7 = 4.0
else
    kr7 = kr8
endif
    if (kr5 < 0.2857142857142857) then
    kr6 = 3.0
else
    kr6 = kr7
endif
    if (kr4 < 0.21428571428571427) then
    kr5 = 2.0
else
    kr5 = kr6
endif
    if (kr3 < 0.14285714285714285) then
    kr4 = 1.0
else
    kr4 = kr5
endif
    if (kr2 < 7.142857142857142e-2) then
    kr3 = 0.0
else
    kr3 = kr4
endif
     event "i", ir19, ir20, kr1, kr3, ir3
    kr1 = krl1
    krl1 = kr1
endif
S141 sprintf "p1_%d", ir3
ar1 chnget S141
S144 sprintf "p2_%d", ir3
ar2 chnget S144
 chnclear S141
 chnclear S144
arl2 init 0.0
arl3 init 0.0
arl2 = ar1
arl3 = ar2
ar1 = arl2
ar2 = arl3
 outs ar1, ar2
kr1 = krl0
S167 sprintf "alive_%d", ir3
 chnset kr1, S167
endin

instr 123
arl0 init 0.0
ar0, ar1 subinstr 96
ar2, ar3 subinstr 98
ir7 = 1.0
ir8 = 0.1
ir9 = 0.5
ar4 Distortion ar2, ir7, ir8, ir9
ir11 = 0.9
ir12 = 8.0e-3
ir13 = 0.73
ar2 Flanger ar4, ir9, ir11, ir12, ir13
ar4, ar5 subinstr 100
ar6, ar7 subinstr 102
ir19 = 1.0e-2
ir20 = 8.5
ir21 = 0.84
ar8 Phaser ar6, ir19, ir11, ir20, ir21
ar6 = (0.65 * ar8)
ar8, ar9 subinstr 104
ar10, ar11 subinstr 106
ar12, ar13 subinstr 108
ar14, ar15 subinstr 110
ar16, ar17 subinstr 112
ar18, ar19 subinstr 114
ar20, ar21 subinstr 116
ar22, ar23 subinstr 118
ar24, ar25 subinstr 120
ar26, ar27 subinstr 122
if (13.0 == p4) then
    ar28 = ar26
else
    ar28 = ar0
endif
if (12.0 == p4) then
    ar26 = ar24
else
    ar26 = ar28
endif
if (11.0 == p4) then
    ar24 = ar22
else
    ar24 = ar26
endif
if (10.0 == p4) then
    ar22 = ar20
else
    ar22 = ar24
endif
if (9.0 == p4) then
    ar20 = ar18
else
    ar20 = ar22
endif
if (8.0 == p4) then
    ar18 = ar16
else
    ar18 = ar20
endif
if (7.0 == p4) then
    ar16 = ar14
else
    ar16 = ar18
endif
if (6.0 == p4) then
    ar14 = ar12
else
    ar14 = ar16
endif
if (5.0 == p4) then
    ar12 = ar10
else
    ar12 = ar14
endif
if (4.0 == p4) then
    ar10 = ar8
else
    ar10 = ar12
endif
if (3.0 == p4) then
    ar8 = ar6
else
    ar8 = ar10
endif
if (2.0 == p4) then
    ar6 = ar4
else
    ar6 = ar8
endif
if (1.0 == p4) then
    ar4 = ar2
else
    ar4 = ar6
endif
if (0.0 == p4) then
    ar2 = ar0
else
    ar2 = ar4
endif
arl0 = ar2
ar0 = arl0
S62 sprintf "p1_%d", p5
 chnmix ar0, S62
arl1 init 0.0
ar0 Distortion ar3, ir7, ir8, ir9
ar2 Flanger ar0, ir9, ir11, ir12, ir13
ar0 Phaser ar7, ir19, ir11, ir20, ir21
ar3 = (0.65 * ar0)
if (13.0 == p4) then
    ar0 = ar27
else
    ar0 = ar1
endif
if (12.0 == p4) then
    ar4 = ar25
else
    ar4 = ar0
endif
if (11.0 == p4) then
    ar0 = ar23
else
    ar0 = ar4
endif
if (10.0 == p4) then
    ar4 = ar21
else
    ar4 = ar0
endif
if (9.0 == p4) then
    ar0 = ar19
else
    ar0 = ar4
endif
if (8.0 == p4) then
    ar4 = ar17
else
    ar4 = ar0
endif
if (7.0 == p4) then
    ar0 = ar15
else
    ar0 = ar4
endif
if (6.0 == p4) then
    ar4 = ar13
else
    ar4 = ar0
endif
if (5.0 == p4) then
    ar0 = ar11
else
    ar0 = ar4
endif
if (4.0 == p4) then
    ar4 = ar9
else
    ar4 = ar0
endif
if (3.0 == p4) then
    ar0 = ar3
else
    ar0 = ar4
endif
if (2.0 == p4) then
    ar3 = ar5
else
    ar3 = ar0
endif
if (1.0 == p4) then
    ar0 = ar2
else
    ar0 = ar3
endif
if (0.0 == p4) then
    ar2 = ar1
else
    ar2 = ar0
endif
arl1 = ar2
ar0 = arl1
S103 sprintf "p2_%d", p5
 chnmix ar0, S103
S106 sprintf "alive_%d", p5
kr0 chnget S106
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S106
endin

instr 122
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 121
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 121
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (227.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.328, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (227.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 120
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 119
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 119
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (310.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.264, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (310.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 118
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 117
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 117
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (420.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.17600000000000002, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (420.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 116
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 115
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 115
arl0 init 0.0
ar0 expsega 0.4, 1.1200000000000002e-2, 1.0, 8.0e-3, 5.0e-2, 4.000000000000001e-2, 1.0e-3, 1.0, 1.0e-3
ir4 = 0.75
ir5 = 0.0
ar1 noise ir4, ir5
kr0 = octave(ir5)
ar2 upsamp kr0
ar3 = (6000.0 * ar2)
ir9 = 20.0
kr0 = (sr / 2.0)
ar4 limit ar3, ir9, kr0
ar3 buthp ar1, ar4
ar1 = (12000.0 * ar2)
kr0 = (sr / 3.0)
ar2 limit ar1, ir9, kr0
ar1 butlp ar3, ar2
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 114
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 113
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 113
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (2.7e-2 * ir6)
ar0 expsega 1.0, ir7, 1.0e-3, 1.0, 1.0e-3
ar1 = (ar0 - 1.0e-3)
ar0 = (0.5 * ar1)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 1700.0)
kr0 = (1700.0 + kr1)
kr1 = birnd(ir3)
kr2 = (kr1 * 0.7)
kr1 = octave(kr2)
kr2 = (kr0 * kr1)
ir20 = rnd(ir11)
ar1 oscil3 ir11, kr2, 8, ir20
kr0 = (kr2 * 8.0)
ar2 butbp ar1, kr2, kr0
ar1 = (ar0 * ar2)
ir25 = (ir7 - 2.0e-3)
ir26 = (ir25 - 5.0e-3)
ar0 expsega 1.0, 2.0e-3, 0.8, 5.0e-3, 0.5, ir26, 1.0e-4, 1.0, 1.0e-4
ar2 = (ar0 - 1.0e-3)
ir29 = 0.0
ar0 noise ir11, ir29
kr0 expsegr 4000.0, ir7, 20.0, 1.0, 20.0, ir7, 20.0
ar3 upsamp kr0
ar4 butlp ar0, ar3
ar0 = (ar2 * ar4)
ar2 = (ar1 + ar0)
ar0 = (0.8 * ar2)
ir36 = 9.0e-2
kr0 = birnd(ir36)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S44 sprintf "p1_%d", p4
 chnmix ar0, S44
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S53 sprintf "p2_%d", p4
 chnmix ar0, S53
S56 sprintf "alive_%d", p4
kr0 chnget S56
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S56
endin

instr 112
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 111
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 111
arl0 init 0.0
ar0 expsega 1.0, 3.6e-2, 1.0e-3, 1.0, 1.0e-3
ar1 = (ar0 - 1.0e-3)
ar0 = (0.4 * ar1)
ar1 = (-ar0)
ir7 = 1.0
ir8 = 0.0
kr0 = octave(ir8)
kr1 = (2500.0 * kr0)
ar0 upsamp kr1
ar2 expsega 3.0, 5.0e-5, 1.0, 1.0, 1.0
ar3 = (ar0 * ar2)
ir13 = rnd(ir7)
ar0 oscil3 ir7, ar3, 2, ir13
ar2 = (ar1 * ar0)
ir16 = 9.0e-2
kr0 = birnd(ir16)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S24 sprintf "p1_%d", p4
 chnmix ar1, S24
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S33 sprintf "p2_%d", p4
 chnmix ar0, S33
S36 sprintf "alive_%d", p4
kr0 chnget S36
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S36
endin

instr 110
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 109
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 109
arl0 init 0.0
ar0 expon 1.0, 1.6, 1.0e-4
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
kr0 = (0.962 * kr1)
ar3 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir27 = 5000.0
ar2 reson ar1, ar3, ir27, 1.0
ir29 = 10000.0
ar1 upsamp k(ir29)
ar3 buthp ar2, ar1
ir31 = 12000.0
ar1 upsamp k(ir31)
ar2 butlp ar3, ar1
ar3 butlp ar2, ar1
ar1 = (ar0 * ar3)
ar0 expsega 1.0, 0.3, 7.0e-2, 1.5, 1.0e-5, 1.0, 1.0e-5
ir36 = 0.8
ar2 noise ir36, ir5
kr0 expseg 14000.0, 0.7, 7000.0, 1.5, 5000.0, 1.0, 5000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir40 = 8000.0
ar2 upsamp k(ir40)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir44 = 9.0e-2
kr0 = birnd(ir44)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S52 sprintf "p1_%d", p4
 chnmix ar0, S52
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S61 sprintf "p2_%d", p4
 chnmix ar0, S61
S64 sprintf "alive_%d", p4
kr0 chnget S64
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S64
endin

instr 108
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 107
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 107
arl0 init 0.0
kr0 linseg 0.0, 4.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 transeg 1.0, 0.48, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar1 upsamp kr0
ar2 = (ar0 * ar1)
ar0 = (-ar2)
ir7 = 1.0
ir8 = 0.0
ir9 = octave(ir8)
kr0 = (90.0 * ir9)
ar1 upsamp kr0
ir11 = (90.0 * ir9)
ir12 = (0.125 / ir11)
ar2 expsega 5.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir7)
ar1 oscil3 ir7, ar3, 2, ir15
ar2 = (ar0 * ar1)
kr0 transeg 1.0, 0.48, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir19 = 0.4
ar1 noise ir7, ir19
kr0 = octave(ir8)
ar3 upsamp kr0
ar4 = (40.0 * ar3)
ir23 = 800.0
ar5 reson ar1, ar4, ir23, 1.0
ar1 = (100.0 * ar3)
ar4 buthp ar5, ar1
ar1 = (600.0 * ar3)
ar3 butlp ar4, ar1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir31 = 9.0e-2
kr0 = birnd(ir31)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S39 sprintf "p1_%d", p4
 chnmix ar0, S39
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S48 sprintf "p2_%d", p4
 chnmix ar0, S48
S51 sprintf "alive_%d", p4
kr0 chnget S51
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S51
endin

instr 106
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 105
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 105
arl0 init 0.0
kr0 linseg 0.0, 4.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 transeg 1.0, 0.48, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar1 upsamp kr0
ar2 = (ar0 * ar1)
ar0 = (-ar2)
ir7 = 1.0
ir8 = 0.0
ir9 = octave(ir8)
kr0 = (133.0 * ir9)
ar1 upsamp kr0
ir11 = (133.0 * ir9)
ir12 = (0.125 / ir11)
ar2 expsega 5.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir7)
ar1 oscil3 ir7, ar3, 2, ir15
ar2 = (ar0 * ar1)
kr0 transeg 1.0, 0.48, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir19 = 0.4
ar1 noise ir7, ir19
kr0 = octave(ir8)
ar3 upsamp kr0
ar4 = (400.0 * ar3)
ir23 = 800.0
ar5 reson ar1, ar4, ir23, 1.0
ar1 = (100.0 * ar3)
ar4 buthp ar5, ar1
ar1 = (600.0 * ar3)
ar3 butlp ar4, ar1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir31 = 9.0e-2
kr0 = birnd(ir31)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S39 sprintf "p1_%d", p4
 chnmix ar0, S39
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S48 sprintf "p2_%d", p4
 chnmix ar0, S48
S51 sprintf "alive_%d", p4
kr0 chnget S51
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S51
endin

instr 104
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 103
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 103
arl0 init 0.0
kr0 linseg 0.0, 4.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 transeg 1.0, 0.4, -10.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar1 upsamp kr0
ar2 = (ar0 * ar1)
ar0 = (-ar2)
ir7 = 1.0
ir8 = 0.0
ir9 = octave(ir8)
kr0 = (200.0 * ir9)
ar1 upsamp kr0
ir11 = (200.0 * ir9)
ir12 = (0.125 / ir11)
ar2 expsega 5.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir7)
ar1 oscil3 ir7, ar3, 2, ir15
ar2 = (ar0 * ar1)
kr0 transeg 1.0, 0.4, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ir19 = 0.4
ar1 noise ir7, ir19
kr0 = octave(ir8)
ar3 upsamp kr0
ar4 = (400.0 * ar3)
ir23 = 800.0
ar5 reson ar1, ar4, ir23, 1.0
ar1 = (100.0 * ar3)
ar4 buthp ar5, ar1
ar1 = (1000.0 * ar3)
ar3 butlp ar4, ar1
ar1 = (ar0 * ar3)
ar0 = (ar2 + ar1)
ir31 = 9.0e-2
kr0 = birnd(ir31)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S39 sprintf "p1_%d", p4
 chnmix ar0, S39
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S48 sprintf "p2_%d", p4
 chnmix ar0, S48
S51 sprintf "alive_%d", p4
kr0 chnget S51
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S51
endin

instr 102
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 101
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 101
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 100
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 99
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 99
arl0 init 0.0
kr0 linsegr 1.0, 0.35000000000000003, 0.1, 5.0e-2, 0.0, 1.0, 0.0, 0.8, 0.0
ar0 upsamp kr0
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 98
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 97
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 97
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 96
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 95
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 95
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 94
krl0 init 10.0
ir3 FreePort 
ir5 = 0.6190476190476191
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 6.0
    ir11 = 93
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
    ir16 = 93
    ir17 = 0.11538461538461539
    ir18 = 0.46153846153846156
     event "i", ir16, ir17, ir18, ir3
    ir21 = 93
    ir22 = 0.23076923076923078
    ir23 = 0.46153846153846156
     event "i", ir21, ir22, ir23, ir3
endif
S28 sprintf "p1_%d", ir3
ar0 chnget S28
S31 sprintf "p2_%d", ir3
ar1 chnget S31
 chnclear S28
 chnclear S31
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S54 sprintf "alive_%d", ir3
 chnset kr0, S54
endin

instr 93
arl0 init 0.0
ar0, ar1 subinstr 92
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 92
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 91
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 91
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 90
krl0 init 10.0
ir3 FreePort 
ir5 = 2.888888888888889
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 89
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 89
arl0 init 0.0
ar0, ar1 subinstr 88
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 88
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 87
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 87
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 86
krl0 init 10.0
ir3 FreePort 
ir5 = 1.0833333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 85
    ir12 = 0.0
    ir13 = 0.9230769230769231
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 85
arl0 init 0.0
ar0, ar1 subinstr 84
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 84
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 83
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 83
arl0 init 0.0
ar0 expon 1.0, 1.6, 1.0e-4
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
kr0 = (0.962 * kr1)
ar3 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
ar1 vco2 ir4, kr0, 2.0, 0.25
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir27 = 5000.0
ar2 reson ar1, ar3, ir27, 1.0
ir29 = 10000.0
ar1 upsamp k(ir29)
ar3 buthp ar2, ar1
ir31 = 12000.0
ar1 upsamp k(ir31)
ar2 butlp ar3, ar1
ar3 butlp ar2, ar1
ar1 = (ar0 * ar3)
ar0 expsega 1.0, 0.3, 7.0e-2, 1.5, 1.0e-5, 1.0, 1.0e-5
ir36 = 0.8
ar2 noise ir36, ir5
kr0 expseg 14000.0, 0.7, 7000.0, 1.5, 5000.0, 1.0, 5000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir40 = 8000.0
ar2 upsamp k(ir40)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir44 = 9.0e-2
kr0 = birnd(ir44)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S52 sprintf "p1_%d", p4
 chnmix ar0, S52
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S61 sprintf "p2_%d", p4
 chnmix ar0, S61
S64 sprintf "alive_%d", p4
kr0 chnget S64
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S64
endin

instr 82
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 81
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 81
arl0 init 0.0
ar0, ar1 subinstr 80
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 80
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 79
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 79
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 78
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 77
    ir13 = 0.46153846153846156
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 77
arl0 init 0.0
ar0, ar1 subinstr 76
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 76
krl0 init 10.0
ir3 FreePort 
ir5 = 1.7333333333333334
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 4.0
    ir11 = 75
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
    ir16 = 75
    ir17 = 0.23076923076923078
    ir18 = 0.46153846153846156
     event "i", ir16, ir17, ir18, ir3
endif
S23 sprintf "p1_%d", ir3
ar0 chnget S23
S26 sprintf "p2_%d", ir3
ar1 chnget S26
 chnclear S23
 chnclear S26
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S49 sprintf "alive_%d", ir3
 chnset kr0, S49
endin

instr 75
arl0 init 0.0
ar0, ar1 subinstr 74
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 74
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 73
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 73
arl0 init 0.0
ir3 = 0.0
ir4 = octave(ir3)
ir5 = (420.0 * ir4)
ir6 = (1.0 / ir5)
kr0 transeg 0.7, ir6, 1.0, 1.0, 0.17600000000000002, -6.0, 1.0e-3, 1.0, 0.0, 1.0e-3
ar0 upsamp kr0
ar1 = (0.25 * ar0)
ar0 = (-ar1)
ir10 = 1.0
kr0 = (420.0 * ir4)
ar1 upsamp kr0
ir12 = (0.25 / ir5)
ar2 expsega 3.0, ir12, 1.0, 1.0, 1.0
ar3 = (ar1 * ar2)
ir15 = rnd(ir10)
ar1 oscil3 ir10, ar3, 2, ir15
ar2 = (ar0 * ar1)
ir18 = 9.0e-2
kr0 = birnd(ir18)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S26 sprintf "p1_%d", p4
 chnmix ar1, S26
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S35 sprintf "p2_%d", p4
 chnmix ar0, S35
S38 sprintf "alive_%d", p4
kr0 chnget S38
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S38
endin

instr 72
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 71
    ir13 = 1.6153846153846154
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 71
arl0 init 0.0
ar0, ar1 subinstr 70
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 70
krl0 init 10.0
ir3 FreePort 
ir5 = 8.666666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 69
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 69
arl0 init 0.0
ar0, ar1 subinstr 68
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 68
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 67
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 67
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 66
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 65
    ir13 = 0.23076923076923078
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 65
arl0 init 0.0
ar0, ar1 subinstr 64
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 64
krl0 init 10.0
ir3 FreePort 
ir5 = 1.2380952380952381
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 63
    ir12 = 0.0
    ir13 = 0.9230769230769231
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 63
arl0 init 0.0
ar0, ar1 subinstr 62
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 62
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 61
    ir13 = 0.9230769230769231
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 61
arl0 init 0.0
kr0 linsegr 1.0, 0.35000000000000003, 0.1, 5.0e-2, 0.0, 1.0, 0.0, 0.8, 0.0
ar0 upsamp kr0
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 60
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 12.0
    ir11 = 59
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
    ir16 = 59
    ir17 = 0.23076923076923078
    ir18 = 0.46153846153846156
     event "i", ir16, ir17, ir18, ir3
    ir21 = 59
    ir22 = 0.46153846153846156
    ir23 = 0.46153846153846156
     event "i", ir21, ir22, ir23, ir3
    ir26 = 59
    ir27 = 0.6923076923076923
    ir28 = 0.46153846153846156
     event "i", ir26, ir27, ir28, ir3
    ir31 = 59
    ir32 = 0.8076923076923077
    ir33 = 0.46153846153846156
     event "i", ir31, ir32, ir33, ir3
    ir36 = 59
    ir37 = 1.0384615384615385
    ir38 = 0.46153846153846156
     event "i", ir36, ir37, ir38, ir3
endif
S43 sprintf "p1_%d", ir3
ar0 chnget S43
S46 sprintf "p2_%d", ir3
ar1 chnget S46
 chnclear S43
 chnclear S46
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S69 sprintf "alive_%d", ir3
 chnset kr0, S69
endin

instr 59
arl0 init 0.0
ar0, ar1 subinstr 58
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 58
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 57
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 57
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 56
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 55
    ir13 = 0.9230769230769231
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 55
arl0 init 0.0
ar0, ar1 subinstr 54
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 54
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 53
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 53
arl0 init 0.0
ar0, ar1 subinstr 52
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 52
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 51
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 51
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 50
krl0 init 10.0
ir3 FreePort 
ir5 = 2.1666666666666665
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 49
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 49
arl0 init 0.0
ar0, ar1 subinstr 48
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 48
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 47
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 47
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 46
krl0 init 10.0
ir3 FreePort 
ir5 = 4.333333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 45
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 45
arl0 init 0.0
ar0, ar1 subinstr 44
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 44
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 43
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 43
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 42
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 41
    ir13 = 5.538461538461538
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 41
arl0 init 0.0
ar0, ar1 subinstr 30
ir5 = 1.0e-2
ir6 = 0.9
ir7 = 8.5
ir8 = 0.84
ar2 Phaser ar0, ir5, ir6, ir7, ir8
ar0 = (0.65 * ar2)
ar2, ar3 subinstr 34
ar4 = (ar0 + ar2)
ar0, ar2 subinstr 40
ir16 = 1.0
ir17 = 0.1
ir18 = 0.5
ar5 Distortion ar0, ir16, ir17, ir18
ir20 = 8.0e-3
ir21 = 0.73
ar0 Flanger ar5, ir18, ir6, ir20, ir21
ar5 = (ar4 + ar0)
arl0 = ar5
ar0 = arl0
S28 sprintf "p1_%d", p4
 chnmix ar0, S28
arl1 init 0.0
ar0 Phaser ar1, ir5, ir6, ir7, ir8
ar1 = (0.65 * ar0)
ar0 = (ar1 + ar3)
ar1 Distortion ar2, ir16, ir17, ir18
ar2 Flanger ar1, ir18, ir6, ir20, ir21
ar1 = (ar0 + ar2)
arl1 = ar1
ar0 = arl1
S46 sprintf "p2_%d", p4
 chnmix ar0, S46
S49 sprintf "alive_%d", p4
kr0 chnget S49
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S49
endin

instr 40
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 39
    ir13 = 0.9230769230769231
    ir14 = 604800.0
     event "i", ir12, ir13, ir14, ir3
endif
S19 sprintf "p1_%d", ir3
ar0 chnget S19
S22 sprintf "p2_%d", ir3
ar1 chnget S22
 chnclear S19
 chnclear S22
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S45 sprintf "alive_%d", ir3
 chnset kr0, S45
endin

instr 39
arl0 init 0.0
ar0, ar1 subinstr 38
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 38
krl0 init 10.0
ir3 FreePort 
ir5 = 0.5416666666666666
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 37
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 37
arl0 init 0.0
ar0, ar1 subinstr 36
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 36
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 35
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 35
arl0 init 0.0
ir3 = 8.5e-2
ir4 = birnd(ir3)
ir5 = (ir4 * 0.8)
ir6 = (0.8 + ir5)
ir7 = (ir6 * 0.1)
ir8 = (ir6 * 0.3)
kr0 expsegr 1.0, ir7, 1.0e-4, 1.0, 1.0e-4, ir8, 1.0e-4
ar0 upsamp kr0
ar1 = (0.75 * ar0)
ir11 = 1.0
ir12 = 8.5e-3
kr0 = birnd(ir12)
kr1 = (kr0 * 342.0)
kr0 = (342.0 + kr1)
ar0 upsamp kr0
ir16 = rnd(ir11)
ar2 oscil3 ir11, kr0, 2, ir16
ar3 = (0.5 * ar0)
ir19 = rnd(ir11)
ar0 oscil3 ir11, ar3, 2, ir19
ar3 = (ar2 + ar0)
ar0 = (ar1 * ar3)
ar1 expon 1.0, ir8, 5.0e-4
ir24 = 0.75
ir25 = 0.0
ar2 noise ir24, ir25
kr0 = birnd(ir3)
kr1 = (kr0 * 0.7)
kr0 = octave(kr1)
kr1 = (10000.0 * kr0)
ir31 = 10000.0
ar3 butbp ar2, kr1, ir31
ir33 = 1000.0
ar2 upsamp k(ir33)
ar4 buthp ar3, ar2
kr0 expsegr 5000.0, 0.1, 3000.0, 1.0, 3000.0, ir8, 1.0e-4
ar2 upsamp kr0
ar3 butlp ar4, ar2
ar2 = (ar1 * ar3)
ar1 = (ar0 + ar2)
ir39 = 9.0e-2
kr0 = birnd(ir39)
ar0 upsamp kr0
ar2 = (1.0 + ar0)
ar0 = (ar1 * ar2)
arl0 = ar0
ar1 = arl0
S47 sprintf "p1_%d", p4
 chnmix ar1, S47
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S56 sprintf "p2_%d", p4
 chnmix ar0, S56
S59 sprintf "alive_%d", p4
kr0 chnget S59
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S59
endin

instr 34
krl0 init 10.0
ir3 FreePort 
ir5 = 2.1666666666666665
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 33
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 33
arl0 init 0.0
ar0, ar1 subinstr 32
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 32
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 31
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 31
arl0 init 0.0
ir3 = 0.5
ir4 = 5.0e-3
ir5 = birnd(ir4)
ir6 = (ir5 * 55.0)
kr0 = (55.0 + ir6)
ar0 upsamp kr0
ir8 = 5.0e-2
ir9 = birnd(ir8)
ir10 = (ir9 * 0.95)
ir11 = (0.95 + ir10)
kr0 transegr 0.5, 1.2, -4.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar1 upsamp kr0
ar2 = semitone(ar1)
ar1 = (ar0 * ar2)
ir15 = 20.0
ir16 = 1.0
ir17 = (ir11 * 0.5)
kr0 transegr 0.2, ir17, -15.0, 1.0e-2, ir17, 0.0, 0.0, 1.0, 0.0, 0.0, ir11, 0.0, 0.0
ar0 gbuzz ir3, ar1, ir15, ir16, kr0, 6
ir20 = (ir11 - 4.0e-3)
kr0 transeg 1.0, ir20, -6.0, 0.0, 1.0, 0.0, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
kr0 linseg 0.0, 4.0e-3, 1.0, 1.0, 1.0
ar0 upsamp kr0
ar1 = (ar2 * ar0)
ar0 = (ar1 * 0.7)
kr0 linseg 1.0, 7.0e-2, 0.0, 1.0, 0.0
ir27 = (55.0 + ir6)
ir28 = (8.0 * ir27)
ar1 expsega ir28, 7.0e-2, 1.0e-3, 1.0, 1.0e-3
ar2 oscili kr0, ar1, 2
ar1 = (ar2 * 0.25)
ar2 = (ar0 + ar1)
ir33 = 9.0e-2
kr0 = birnd(ir33)
ar0 upsamp kr0
ar1 = (1.0 + ar0)
ar0 = (ar2 * ar1)
arl0 = ar0
ar1 = arl0
S41 sprintf "p1_%d", p4
 chnmix ar1, S41
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S50 sprintf "p2_%d", p4
 chnmix ar0, S50
S53 sprintf "alive_%d", p4
kr0 chnget S53
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S53
endin

instr 30
krl0 init 10.0
ir3 FreePort 
ir5 = 4.333333333333333
kr0 metro ir5
if (kr0 == 1.0) then
    krl0 = 2.0
    ir11 = 29
    ir12 = 0.0
    ir13 = 0.46153846153846156
     event "i", ir11, ir12, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 29
arl0 init 0.0
ar0, ar1 subinstr 28
arl0 = ar0
ar0 = arl0
S9 sprintf "p1_%d", p4
 chnmix ar0, S9
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S19 sprintf "p2_%d", p4
 chnmix ar0, S19
S22 sprintf "alive_%d", p4
kr0 chnget S22
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S22
endin

instr 28
krl0 init 10.0
ir3 FreePort 
ir5 = 0.0
ar0 mpulse k(ksmps), ir5, 0.0
kr0 downsamp ar0, ksmps
if (kr0 == 1.0) then
    krl0 = 2.0
    ir12 = 27
    ir13 = 0.46153846153846156
     event "i", ir12, ir5, ir13, ir3
endif
S18 sprintf "p1_%d", ir3
ar0 chnget S18
S21 sprintf "p2_%d", ir3
ar1 chnget S21
 chnclear S18
 chnclear S21
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
kr0 = krl0
S44 sprintf "alive_%d", ir3
 chnset kr0, S44
endin

instr 27
arl0 init 0.0
ar0 expsega 1.0, 0.4, 1.0e-3, 1.0, 1.0e-3
ir4 = 1.0
ir5 = 0.0
ar1 upsamp k(ir5)
ar2 = octave(ar1)
kr0 downsamp ar2
kr1 = (296.0 * kr0)
kr0 = (1.0 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
kr0 = (0.962 * kr1)
kr2 = rnd(ir4)
ar3 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar1 + ar3)
kr0 = (1.233 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (1.175 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar4 = (ar3 + ar1)
kr0 = (1.419 * kr1)
kr2 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr2
ar3 = (ar4 + ar1)
kr0 = (2.821 * kr1)
kr1 = rnd(ir4)
ar1 vco2 ir4, kr0, 2.0, 0.25, kr1
ar4 = (ar3 + ar1)
ar1 = (0.5 * ar4)
ar3 = (5000.0 * ar2)
ir33 = 5000.0
ar2 upsamp k(ir33)
ar4 reson ar1, ar3, ir33, 1.0
ar1 buthp ar4, ar2
ar3 buthp ar1, ar2
ar1 = (ar0 * ar3)
ir38 = 0.8
ar2 noise ir38, ir5
kr0 expseg 20000.0, 0.7, 9000.0, 0.30000000000000004, 9000.0, 1.0, 9000.0
ar3 upsamp kr0
ar4 butlp ar2, ar3
ir42 = 8000.0
ar2 upsamp k(ir42)
ar3 buthp ar4, ar2
ar2 = (ar0 * ar3)
ar0 = (ar1 + ar2)
ir46 = 9.0e-2
kr0 = birnd(ir46)
ar1 upsamp kr0
ar2 = (1.0 + ar1)
ar1 = (ar0 * ar2)
arl0 = ar1
ar0 = arl0
S54 sprintf "p1_%d", p4
 chnmix ar0, S54
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S63 sprintf "p2_%d", p4
 chnmix ar0, S63
S66 sprintf "alive_%d", p4
kr0 chnget S66
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S66
endin

instr 26
ir1 FreePort 
krl0 init 10.0
ir5 FreePort 
 event_i "i", 21, 0.0, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 0.23076923076923078, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 0.46153846153846156, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 0.6923076923076923, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 0.9230769230769231, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 1.3846153846153846, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 1.6153846153846154, 0.46153846153846156, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 2.076923076923077, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 2.307692307692308, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 2.5384615384615388, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 2.7692307692307696, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 3.0000000000000004, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 3.2307692307692313, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 3.461538461538462, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 3.692307692307693, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 4.153846153846154, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 4.384615384615385, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 4.615384615384616, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 5.0769230769230775, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 5.307692307692308, 1.153846153846154, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 7.384615384615386, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 7.615384615384617, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 7.846153846153848, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 8.076923076923078, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 8.307692307692308, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 8.76923076923077, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 9.0, 0.46153846153846156, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 9.461538461538462, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 9.692307692307692, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 9.923076923076922, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 10.153846153846152, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 10.384615384615381, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 10.615384615384611, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 10.846153846153841, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 11.076923076923071, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 11.538461538461533, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 11.769230769230763, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 11.999999999999993, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 12.461538461538455, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 12.692307692307685, 1.153846153846154, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 14.769230769230772, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 15.000000000000002, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 15.230769230769232, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 15.692307692307693, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 16.153846153846153, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 16.615384615384613, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 17.076923076923073, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 17.999999999999996, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 18.230769230769226, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 18.461538461538456, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 18.923076923076916, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 19.384615384615376, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 19.846153846153836, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 20.307692307692296, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 20.538461538461526, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 20.769230769230756, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 21.46153846153845, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 21.92307692307691, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 22.153846153846157, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 22.384615384615387, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 22.615384615384617, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 23.076923076923077, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 23.538461538461537, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 23.999999999999996, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 24.461538461538456, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 25.38461538461538, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 25.61538461538461, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 25.84615384615384, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 26.3076923076923, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 26.76923076923076, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 27.23076923076922, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 27.69230769230768, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 27.92307692307691, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 28.15384615384614, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 28.846153846153832, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 29.307692307692292, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 29.538461538461544, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 29.769230769230774, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 30.000000000000004, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 30.461538461538463, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 30.923076923076923, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 31.384615384615383, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 31.846153846153843, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 32.76923076923077, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 33.0, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 33.23076923076923, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 33.69230769230769, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 34.15384615384615, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 34.61538461538461, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 35.07692307692307, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 35.30769230769231, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 35.53846153846154, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 36.23076923076923, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 36.69230769230769, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 36.92307692307693, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 37.15384615384616, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 37.384615384615394, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 37.846153846153854, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 38.307692307692314, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 38.769230769230774, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 39.23076923076923, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 40.15384615384615, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 40.38461538461539, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 40.61538461538462, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 41.07692307692308, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 41.53846153846154, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 42.0, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 42.46153846153846, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 42.69230769230769, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 42.92307692307693, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 43.61538461538462, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 44.07692307692308, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 44.307692307692314, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 44.53846153846155, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 44.76923076923078, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 45.23076923076924, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 45.6923076923077, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 46.15384615384616, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 46.61538461538462, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 47.53846153846154, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 47.769230769230774, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 48.00000000000001, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 48.46153846153847, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 48.92307692307693, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 49.38461538461539, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 49.84615384615385, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 50.07692307692308, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 50.307692307692314, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 51.00000000000001, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 51.46153846153847, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 51.6923076923077, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 51.923076923076934, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 52.15384615384617, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 52.61538461538463, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 53.07692307692309, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 53.53846153846155, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 54.00000000000001, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 54.92307692307693, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 55.15384615384616, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 55.384615384615394, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 55.846153846153854, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 56.307692307692314, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 56.769230769230774, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 57.23076923076923, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 57.46153846153847, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 57.6923076923077, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 58.384615384615394, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 58.846153846153854, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 59.07692307692309, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 59.30769230769232, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 59.538461538461554, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 60.000000000000014, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 60.461538461538474, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 60.923076923076934, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 61.384615384615394, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 62.307692307692314, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 62.53846153846155, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 62.76923076923078, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 63.23076923076924, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 63.6923076923077, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 64.15384615384616, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 64.61538461538463, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 64.84615384615385, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 65.07692307692308, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 65.76923076923077, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 66.23076923076924, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 66.46153846153847, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 66.6923076923077, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 66.92307692307692, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 67.38461538461539, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 67.84615384615385, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 68.30769230769232, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 68.76923076923079, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 69.69230769230771, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 69.92307692307693, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 70.15384615384616, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 70.61538461538463, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 71.0769230769231, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 71.53846153846156, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 72.00000000000003, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 72.23076923076925, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 72.46153846153848, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 73.15384615384617, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 73.61538461538464, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 73.84615384615385, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 74.07692307692308, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 74.3076923076923, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 74.53846153846153, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 74.76923076923076, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 75.23076923076923, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 75.46153846153845, 0.46153846153846156, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 75.92307692307692, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 76.15384615384615, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 76.38461538461537, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 76.6153846153846, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 76.84615384615383, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 77.07692307692305, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 77.30769230769228, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 77.5384615384615, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 77.99999999999997, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 78.2307692307692, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 78.46153846153842, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 78.92307692307689, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 79.15384615384612, 1.153846153846154, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 81.23076923076924, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 81.46153846153847, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 81.6923076923077, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 81.92307692307692, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 82.15384615384615, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 82.61538461538461, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 82.84615384615384, 0.46153846153846156, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 83.3076923076923, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 83.53846153846153, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 83.76923076923076, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 83.99999999999999, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 84.23076923076921, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 84.46153846153844, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 84.69230769230766, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 84.92307692307689, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 85.38461538461536, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 85.61538461538458, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 85.84615384615381, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 86.30769230769228, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 86.5384615384615, 1.153846153846154, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 88.61538461538463, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 88.84615384615385, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 89.07692307692308, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 89.53846153846155, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 90.00000000000001, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 90.46153846153848, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 90.92307692307695, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 91.84615384615387, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 92.0769230769231, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 92.30769230769232, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 92.76923076923079, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 93.23076923076925, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 93.69230769230772, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 94.15384615384619, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 94.38461538461542, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 94.61538461538464, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 95.30769230769234, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 95.7692307692308, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 96.00000000000001, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 96.23076923076924, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 96.46153846153847, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 96.92307692307693, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 97.3846153846154, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 97.84615384615387, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 98.30769230769234, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 99.23076923076925, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 99.46153846153848, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 99.69230769230771, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 100.15384615384617, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 100.61538461538464, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 101.07692307692311, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 101.53846153846158, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 101.7692307692308, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 102.00000000000003, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 102.69230769230772, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 103.15384615384619, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 103.3846153846154, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 103.61538461538463, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 103.84615384615385, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 104.30769230769232, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 104.76923076923079, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 105.23076923076925, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 105.69230769230772, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 106.61538461538464, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 106.84615384615387, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 107.0769230769231, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 107.53846153846156, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 108.00000000000003, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 108.4615384615385, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 108.92307692307696, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 109.15384615384619, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 109.38461538461542, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 110.07692307692311, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 110.53846153846158, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 110.76923076923079, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 111.00000000000001, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 111.23076923076924, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 111.69230769230771, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 112.15384615384617, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 112.61538461538464, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 113.07692307692311, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 114.00000000000003, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 114.23076923076925, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 21, 114.46153846153848, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 114.92307692307695, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 115.38461538461542, 0.23076923076923078, 1.0, 261.6, ir5
 event_i "i", 21, 115.84615384615388, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 116.30769230769235, 0.23076923076923078, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 116.53846153846158, 0.23076923076923078, 1.0, 218.00000000000003, ir5
 event_i "i", 21, 116.7692307692308, 0.46153846153846156, 1.0, 245.25000000000003, ir5
 event_i "i", 21, 117.4615384615385, 0.23076923076923078, 1.0, 327.0, ir5
 event_i "i", 21, 117.92307692307696, 0.23076923076923078, 1.0, 294.3, ir5
 event_i "i", 25, 0.0, 118.15384615384617, ir5, ir1
krl0 = 2.0
kr0 = krl0
S605 sprintf "alive_%d", ir1
 chnset kr0, S605
S608 sprintf "p1_%d", ir1
ar0 chnget S608
S611 sprintf "p2_%d", ir1
ar1 chnget S611
 chnclear S608
 chnclear S611
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
endin

instr 25
S1 sprintf "p1_%d", p4
ar0 chnget S1
kr0 downsamp ar0
S4 sprintf "p2_%d", p4
ar1 chnget S4
kr1 downsamp ar1
S7 sprintf "p3_%d", p4
ar1 chnget S7
kr2 downsamp ar1
 chnclear S1
 chnclear S4
 chnclear S7
arl0 init 0.0
if (kr2 == 0.0) then
    ar1 = 0.0
else
    ar1 = 1.0
endif
kr2 downsamp ar1
kr3 changed kr0, kr1, kr2
ar2 upsamp kr3
ir20 = 1.9e-2
ir21 = 8.5
ir22 = 0.2
ir23 = 7.0e-2
ar3 adsr140 ar1, ar2, ir20, ir21, ir22, ir23
ar1 = (ar0 * ar3)
ir26 = 1.0
kr0 port kr1, 1.0e-3
kr1 vco2ft kr0, 0
ar0 oscilikt ir26, kr0, kr1
kr1 = (kr0 * 0.503)
kr2 vco2ft kr1, 0
ar2 oscilikt ir26, kr1, kr2
ar3 = (0.5 * ar2)
ar2 = (ar0 + ar3)
kr1 = (kr0 * 0.253)
kr0 vco2ft kr1, 3
ar0 oscilikt ir26, kr1, kr0
ar3 = (0.25 * ar0)
ar0 = (ar2 + ar3)
ar2 = (ar1 * ar0)
ir41 = 0.5
ar0 oscil3 ir26, ir41, 4
ar1 = (0.5 * ar0)
ar0 = (0.5 + ar1)
ar1 = (4500.0 * ar0)
ar3 = (550.0 + ar1)
ar1 = (0.4 * ar0)
ar0 = (0.52 + ar1)
ar1 = (17.0 * ar0)
ar0 diode_ladder ar2, ar3, ar1, 1.0, 1.2
ir51 = 30.0
ar1 upsamp k(ir51)
ar2 buthp ar0, ar1
arl0 = ar2
ar0 = arl0
S57 sprintf "p1_%d", p5
 chnmix ar0, S57
arl1 init 0.0
arl1 = ar2
ar0 = arl1
S66 sprintf "p2_%d", p5
 chnmix ar0, S66
endin

instr 24
ir1 FreePort 
krl0 init 10.0
ir5 FreePort 
 event_i "i", 23, 0.0, 118.15384615384617, ir5, ir1
ir9 FreePort 
 event_i "i", 21, 0.0, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 0.46153846153846156, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 1.3846153846153846, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 1.6153846153846154, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 1.8461538461538463, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 2.076923076923077, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 2.307692307692308, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 2.7692307692307696, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 3.0000000000000004, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 3.2307692307692313, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 3.692307692307693, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 4.153846153846154, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 5.0769230769230775, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 5.307692307692308, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 5.538461538461539, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 5.76923076923077, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 6.000000000000001, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 6.461538461538463, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 6.692307692307693, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 6.923076923076924, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 7.384615384615386, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 7.846153846153848, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 8.76923076923077, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 9.0, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 9.23076923076923, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 9.46153846153846, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 9.69230769230769, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 10.153846153846152, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 10.384615384615381, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 10.615384615384611, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 11.076923076923078, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 11.53846153846154, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 12.461538461538463, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 12.692307692307693, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 12.923076923076923, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 13.153846153846153, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 13.384615384615383, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 13.846153846153845, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 14.076923076923075, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 14.307692307692305, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 14.769230769230772, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 15.000000000000002, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 15.230769230769232, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 16.153846153846153, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 16.384615384615383, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 16.615384615384613, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 16.846153846153843, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 17.076923076923073, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 17.999999999999996, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 18.230769230769226, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 18.461538461538463, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 18.692307692307693, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 18.923076923076923, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 19.846153846153847, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 20.076923076923077, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 20.307692307692307, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 20.538461538461537, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 20.769230769230766, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 21.69230769230769, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 21.92307692307692, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 22.153846153846157, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 22.384615384615387, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 22.615384615384617, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 23.53846153846154, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 23.76923076923077, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 24.0, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 24.23076923076923, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 24.46153846153846, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 25.384615384615383, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 25.615384615384613, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 25.84615384615385, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 26.07692307692308, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 26.30769230769231, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 27.230769230769234, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 27.461538461538463, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 27.692307692307693, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 27.923076923076923, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 28.153846153846153, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 29.076923076923077, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 29.307692307692307, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 29.53846153846154, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 29.76923076923077, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 30.0, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 30.923076923076923, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 31.153846153846153, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 31.384615384615383, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 31.615384615384613, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 31.846153846153843, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 32.76923076923077, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 33.0, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 33.23076923076923, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 33.46153846153847, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 33.6923076923077, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 34.61538461538462, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 34.846153846153854, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 35.07692307692309, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 35.30769230769232, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 35.538461538461554, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 36.461538461538474, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 36.69230769230771, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 36.92307692307693, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 37.15384615384616, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 37.384615384615394, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 38.307692307692314, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 38.53846153846155, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 38.76923076923078, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 39.000000000000014, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 39.23076923076925, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 40.15384615384617, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 40.3846153846154, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 40.61538461538462, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 40.846153846153854, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 41.07692307692309, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 42.00000000000001, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 42.23076923076924, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 42.461538461538474, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 42.69230769230771, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 42.92307692307694, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 43.84615384615386, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 44.076923076923094, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 44.30769230769231, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 44.76923076923077, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 45.692307692307686, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 45.92307692307692, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 46.15384615384615, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 46.38461538461539, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 46.61538461538462, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 47.07692307692308, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 47.307692307692314, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 47.53846153846155, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 48.0, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 48.46153846153846, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 49.38461538461538, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 49.61538461538461, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 49.84615384615385, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 50.07692307692308, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 50.307692307692314, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 50.769230769230774, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 51.00000000000001, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 51.23076923076924, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 51.69230769230769, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 52.15384615384615, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 53.07692307692307, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 53.30769230769231, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 53.53846153846154, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 53.769230769230774, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 54.00000000000001, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 54.46153846153847, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 54.6923076923077, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 54.923076923076934, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 55.38461538461539, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 55.84615384615385, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 56.76923076923077, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 57.0, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 57.23076923076923, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 57.46153846153847, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 57.6923076923077, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 58.15384615384616, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 58.384615384615394, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 58.61538461538463, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 59.07692307692308, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 59.53846153846154, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 60.46153846153846, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 60.69230769230769, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 60.92307692307693, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 61.15384615384616, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 61.384615384615394, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 61.846153846153854, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 62.07692307692309, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 62.30769230769232, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 62.769230769230774, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 63.23076923076923, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 64.15384615384616, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 64.38461538461539, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 64.61538461538461, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 64.84615384615384, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 65.07692307692307, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 65.53846153846153, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 65.76923076923076, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 65.99999999999999, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 66.46153846153847, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 66.92307692307693, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 67.84615384615385, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 68.07692307692308, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 68.3076923076923, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 68.53846153846153, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 68.76923076923076, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 69.23076923076923, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 69.46153846153845, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 69.69230769230768, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 70.15384615384616, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 70.61538461538463, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 71.53846153846155, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 71.76923076923077, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 72.0, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 72.23076923076923, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 72.46153846153845, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 72.92307692307692, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 73.15384615384615, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 73.38461538461537, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 73.84615384615385, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 74.07692307692308, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 74.3076923076923, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 75.23076923076923, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 75.46153846153845, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 75.69230769230768, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 75.9230769230769, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 76.15384615384613, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 77.07692307692305, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 77.30769230769228, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 77.53846153846155, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 77.76923076923077, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 78.0, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 78.92307692307692, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 79.15384615384615, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 79.38461538461537, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 79.6153846153846, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 79.84615384615383, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 80.76923076923075, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 80.99999999999997, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 81.23076923076924, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 81.46153846153847, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 81.6923076923077, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 82.61538461538461, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 82.84615384615384, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 83.07692307692307, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 83.30769230769229, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 83.53846153846152, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 84.46153846153844, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 84.69230769230766, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 84.92307692307693, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 85.15384615384616, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 85.38461538461539, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 86.3076923076923, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 86.53846153846153, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 86.76923076923076, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 86.99999999999999, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 87.23076923076921, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 88.15384615384613, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 88.38461538461536, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 88.61538461538463, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 88.84615384615385, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 89.07692307692308, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 90.0, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 90.23076923076923, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 90.46153846153845, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 90.69230769230768, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 90.9230769230769, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 91.84615384615383, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 92.07692307692305, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 92.30769230769232, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 92.53846153846155, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 92.76923076923077, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 93.6923076923077, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 93.92307692307692, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 94.15384615384615, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 94.38461538461537, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 94.6153846153846, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 95.53846153846152, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 95.76923076923075, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 96.00000000000001, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 96.23076923076924, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 96.46153846153847, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 97.38461538461539, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 97.61538461538461, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 97.84615384615384, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 98.07692307692307, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 98.30769230769229, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 99.23076923076921, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 99.46153846153844, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 99.69230769230771, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 99.92307692307693, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 100.15384615384616, 0.9230769230769231, 1.0, 65.4, ir9
 event_i "i", 21, 101.07692307692308, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 101.3076923076923, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 101.53846153846153, 0.23076923076923078, 1.0, 30.656250000000004, ir9
 event_i "i", 21, 101.76923076923076, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 101.99999999999999, 0.9230769230769231, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 102.9230769230769, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 103.15384615384613, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 103.3846153846154, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 103.84615384615387, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 104.76923076923079, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 105.00000000000001, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 105.23076923076924, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 105.46153846153847, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 105.6923076923077, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 106.15384615384616, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 106.38461538461539, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 106.61538461538461, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 107.0769230769231, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 107.53846153846156, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 108.46153846153848, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 108.69230769230771, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 108.92307692307693, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 109.15384615384616, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 109.38461538461539, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 109.84615384615385, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 110.07692307692308, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 110.3076923076923, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 110.76923076923079, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 111.23076923076925, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 112.15384615384617, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 112.3846153846154, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 112.61538461538463, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 112.84615384615385, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 113.07692307692308, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 113.53846153846155, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 113.76923076923077, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 114.0, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 21, 114.46153846153848, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 114.92307692307695, 0.46153846153846156, 1.0, 65.4, ir9
 event_i "i", 21, 115.84615384615387, 0.23076923076923078, 1.0, 81.75, ir9
 event_i "i", 21, 116.0769230769231, 0.23076923076923078, 1.0, 54.50000000000001, ir9
 event_i "i", 21, 116.30769230769232, 0.23076923076923078, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 116.53846153846155, 0.23076923076923078, 1.0, 73.575, ir9
 event_i "i", 21, 116.76923076923077, 0.46153846153846156, 1.0, 61.31250000000001, ir9
 event_i "i", 21, 117.23076923076924, 0.23076923076923078, 1.0, 87.2, ir9
 event_i "i", 21, 117.46153846153847, 0.23076923076923078, 1.0, 98.10000000000001, ir9
 event_i "i", 21, 117.6923076923077, 0.46153846153846156, 1.0, 81.75, ir9
 event_i "i", 22, 0.0, 118.15384615384617, ir9, ir5
krl0 = 2.0
kr0 = krl0
S657 sprintf "alive_%d", ir5
 chnset kr0, S657
krl0 = 2.0
kr0 = krl0
S664 sprintf "alive_%d", ir1
 chnset kr0, S664
S667 sprintf "p1_%d", ir1
ar0 chnget S667
S670 sprintf "p2_%d", ir1
ar1 chnget S670
 chnclear S667
 chnclear S670
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
endin

instr 23
S1 sprintf "p1_%d", p4
ar0 chnget S1
S4 sprintf "p2_%d", p4
ar1 chnget S4
 chnclear S1
 chnclear S4
arl0 init 0.0
ar2 = (0.85 * ar0)
ir14 = 0.6
ir15 = 12000.0
ar3, ar4 reverbsc ar0, ar1, ir14, ir15
ar5 = (ar0 + ar3)
ar0 = (0.15 * ar5)
ar3 = (ar2 + ar0)
arl0 = ar3
ar0 = arl0
S25 sprintf "p1_%d", p5
 chnmix ar0, S25
arl1 init 0.0
ar0 = (0.85 * ar1)
ar2 = (ar1 + ar4)
ar1 = (0.15 * ar2)
ar2 = (ar0 + ar1)
arl1 = ar2
ar0 = arl1
S39 sprintf "p2_%d", p5
 chnmix ar0, S39
endin

instr 22
S1 sprintf "p1_%d", p4
ar0 chnget S1
kr0 downsamp ar0
S4 sprintf "p2_%d", p4
ar0 chnget S4
kr1 downsamp ar0
S7 sprintf "p3_%d", p4
ar0 chnget S7
kr2 downsamp ar0
 chnclear S1
 chnclear S4
 chnclear S7
ir16 = 1.0
ir17 = rnd(ir16)
ir19 = rnd(ir16)
ir21 = rnd(ir16)
arl0 init 0.0
kr3 port kr0, 1.0e-2
ar0 upsamp kr3
if (kr2 == 0.0) then
    ar1 = 0.0
else
    ar1 = 1.0
endif
kr2 downsamp ar1
kr3 changed kr0, kr1, kr2
ar2 upsamp kr3
ir28 = 0.35
ir29 = 0.5
ar3 adsr140 ar1, ar2, ir28, ir29, ir16, ir29
ar2 = (ar0 * ar3)
kr0 linseg 0.0, 1.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 linsegr 1.0, 1.0, 1.0, 5.0e-2, 0.0
ar3 upsamp kr0
ar4 = (ar0 * ar3)
ar0 delay1 ar1
kr0 downsamp ar0
kr2 = (kr0 * 1.0e-2)
kr0 portk kr1, kr2
ar0 upsamp kr0
ar1 oscil3 ir16, kr0, 2, ir17
ar3 = (2.0 * ar0)
ir40 = 12.0
ar5 upsamp k(ir40)
ar6 = cent(ar5)
ar5 = (ar3 * ar6)
ar3 oscil3 ir16, ar5, 2, ir19
ar5 = (ar1 + ar3)
ar1 = (3.0 * ar0)
ir46 = 24.0
ar0 upsamp k(ir46)
ar3 = cent(ar0)
ar0 = (ar1 * ar3)
ar1 oscil3 ir16, ar0, 2, ir21
ar0 = (ar5 + ar1)
ar1 = (ar0 / 3.0)
ar0 = (ar4 * ar1)
ar1 = (ar2 * ar0)
ar0 = (0.4 * ar1)
arl0 = ar0
ar1 = arl0
S59 sprintf "p1_%d", p5
 chnmix ar1, S59
arl1 init 0.0
arl1 = ar0
ar0 = arl1
S68 sprintf "p2_%d", p5
 chnmix ar0, S68
endin

instr 21
S1 sprintf "p1_%d", p6
ar0 chnget S1
S4 sprintf "p2_%d", p6
ar1 chnget S4
S7 sprintf "p3_%d", p6
ar2 chnget S7
ir10 = p4
ar3 upsamp k(ir10)
 chnset ar3, S1
ir13 = p5
ar3 upsamp k(ir13)
 chnset ar3, S4
ar3 = (ar2 + 1.0)
 chnset ar3, S7
endin

instr 20
ir1 FreePort 
krl0 init 10.0
ir5 FreePort 
 event_i "i", 19, 0.0, 118.15384615384617, ir5, ir1
 event_i "i", 18, 0.0, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 0.23076923076923078, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 0.23076923076923078, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 0.23076923076923078, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 0.6923076923076923, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 0.6923076923076923, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 0.6923076923076923, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 1.3846153846153846, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 1.3846153846153846, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 1.3846153846153846, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 1.8461538461538463, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 2.076923076923077, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 2.076923076923077, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 2.076923076923077, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 2.5384615384615388, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 2.5384615384615388, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 2.5384615384615388, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 3.0000000000000004, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 3.2307692307692313, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 3.2307692307692313, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 3.2307692307692313, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 3.461538461538462, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 3.5769230769230775, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 3.692307692307693, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 3.923076923076924, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 3.923076923076924, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 3.923076923076924, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 4.384615384615385, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 4.384615384615385, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 4.384615384615385, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 5.0769230769230775, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 5.0769230769230775, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 5.0769230769230775, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 5.538461538461539, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 5.76923076923077, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 5.76923076923077, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 5.76923076923077, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 6.230769230769232, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 6.230769230769232, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 6.230769230769232, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 6.692307692307693, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 6.923076923076924, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 6.923076923076924, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 6.923076923076924, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 7.153846153846155, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 7.26923076923077, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 7.384615384615386, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 7.615384615384617, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 7.615384615384617, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 7.615384615384617, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 8.076923076923078, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 8.076923076923078, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 8.076923076923078, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 8.76923076923077, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 8.76923076923077, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 8.76923076923077, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 9.230769230769232, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 9.461538461538462, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 9.461538461538462, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 9.461538461538462, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 9.923076923076923, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 9.923076923076923, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 9.923076923076923, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 10.384615384615385, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 10.615384615384615, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 10.615384615384615, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 10.615384615384615, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 10.846153846153845, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 10.96153846153846, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 11.076923076923078, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 11.307692307692308, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 11.307692307692308, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 11.307692307692308, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 11.76923076923077, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 11.76923076923077, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 11.76923076923077, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 12.461538461538462, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 12.461538461538462, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 12.461538461538462, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 12.923076923076923, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 13.153846153846153, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 13.153846153846153, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 13.153846153846153, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 13.615384615384615, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 13.615384615384615, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 13.615384615384615, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 14.076923076923077, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 14.307692307692307, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 14.307692307692307, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 14.307692307692307, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 14.538461538461537, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 14.653846153846152, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 15.230769230769234, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 15.230769230769234, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 15.230769230769234, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 16.153846153846157, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 16.153846153846157, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 16.153846153846157, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 17.07692307692308, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 17.07692307692308, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 17.07692307692308, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 18.000000000000004, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 18.000000000000004, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 18.000000000000004, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 18.923076923076923, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 18.923076923076923, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 18.923076923076923, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 19.846153846153847, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 19.846153846153847, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 19.846153846153847, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 20.76923076923077, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 20.76923076923077, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 20.76923076923077, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 21.692307692307693, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 21.692307692307693, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 21.692307692307693, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 22.615384615384617, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 22.615384615384617, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 22.615384615384617, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 23.53846153846154, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 23.53846153846154, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 23.53846153846154, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 24.461538461538463, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 24.461538461538463, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 24.461538461538463, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 25.384615384615387, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 25.384615384615387, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 25.384615384615387, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 26.30769230769231, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 26.30769230769231, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 26.30769230769231, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 27.230769230769234, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 27.230769230769234, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 27.230769230769234, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 28.153846153846157, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 28.153846153846157, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 28.153846153846157, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 29.07692307692308, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 29.07692307692308, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 29.07692307692308, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 30.000000000000004, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 30.000000000000004, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 30.000000000000004, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 30.923076923076927, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 30.923076923076927, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 30.923076923076927, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 31.84615384615385, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 31.84615384615385, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 31.84615384615385, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 32.769230769230774, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 32.769230769230774, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 32.769230769230774, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 33.69230769230769, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 33.69230769230769, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 33.69230769230769, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 34.61538461538461, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 34.61538461538461, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 34.61538461538461, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 35.53846153846153, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 35.53846153846153, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 35.53846153846153, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 36.46153846153845, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 36.46153846153845, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 36.46153846153845, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 37.38461538461539, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 37.38461538461539, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 37.38461538461539, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 38.30769230769231, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 38.30769230769231, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 38.30769230769231, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 39.230769230769226, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 39.230769230769226, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 39.230769230769226, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 40.153846153846146, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 40.153846153846146, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 40.153846153846146, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 41.07692307692308, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 41.07692307692308, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 41.07692307692308, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 42.0, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 42.0, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 42.0, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 42.92307692307692, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 42.92307692307692, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 42.92307692307692, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 43.84615384615384, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 43.84615384615384, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 43.84615384615384, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 44.769230769230774, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 44.769230769230774, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 44.769230769230774, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 45.69230769230769, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 45.69230769230769, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 45.69230769230769, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 46.61538461538461, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 46.61538461538461, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 46.61538461538461, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 47.53846153846153, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 47.53846153846153, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 47.53846153846153, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 48.46153846153847, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 48.46153846153847, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 48.46153846153847, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 49.38461538461539, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 49.38461538461539, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 49.38461538461539, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 50.30769230769231, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 50.30769230769231, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 50.30769230769231, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 51.230769230769226, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 51.230769230769226, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 51.230769230769226, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 52.15384615384616, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 52.15384615384616, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 52.15384615384616, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 53.07692307692308, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 53.07692307692308, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 53.07692307692308, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 54.0, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 54.0, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 54.0, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 54.92307692307692, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 54.92307692307692, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 54.92307692307692, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 55.846153846153854, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 55.846153846153854, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 55.846153846153854, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 56.769230769230774, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 56.769230769230774, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 56.769230769230774, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 57.69230769230769, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 57.69230769230769, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 57.69230769230769, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 58.61538461538461, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 58.61538461538461, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 58.61538461538461, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 59.07692307692309, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 59.30769230769232, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 59.30769230769232, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 59.30769230769232, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 59.76923076923078, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 59.76923076923078, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 59.76923076923078, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 60.461538461538474, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 60.461538461538474, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 60.461538461538474, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 60.923076923076934, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 61.15384615384617, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 61.15384615384617, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 61.15384615384617, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 61.61538461538463, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 61.61538461538463, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 61.61538461538463, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 62.07692307692309, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 62.30769230769232, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 62.30769230769232, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 62.30769230769232, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 62.538461538461554, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 62.65384615384617, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 62.76923076923078, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 63.000000000000014, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 63.000000000000014, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 63.000000000000014, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 63.461538461538474, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 63.461538461538474, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 63.461538461538474, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 64.15384615384616, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 64.15384615384616, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 64.15384615384616, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 64.61538461538463, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 64.84615384615385, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 64.84615384615385, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 64.84615384615385, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 65.30769230769232, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 65.30769230769232, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 65.30769230769232, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 65.76923076923079, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 66.00000000000001, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 66.00000000000001, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 66.00000000000001, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 66.23076923076924, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 66.34615384615385, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 66.46153846153847, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 66.6923076923077, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 66.6923076923077, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 66.6923076923077, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 67.15384615384616, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 67.15384615384616, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 67.15384615384616, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 67.84615384615385, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 67.84615384615385, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 67.84615384615385, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 68.30769230769232, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 68.53846153846155, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 68.53846153846155, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 68.53846153846155, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 69.00000000000001, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 69.00000000000001, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 69.00000000000001, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 69.46153846153848, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 69.69230769230771, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 69.69230769230771, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 69.69230769230771, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 69.92307692307693, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 70.03846153846155, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 70.15384615384616, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 70.38461538461539, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 70.38461538461539, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 70.38461538461539, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 70.84615384615385, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 70.84615384615385, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 70.84615384615385, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 71.53846153846155, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 71.53846153846155, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 71.53846153846155, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 72.00000000000001, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 72.23076923076924, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 72.23076923076924, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 72.23076923076924, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 72.69230769230771, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 72.69230769230771, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 72.69230769230771, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 73.15384615384617, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 73.3846153846154, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 73.3846153846154, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 73.3846153846154, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 73.61538461538463, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 73.73076923076924, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 74.30769230769232, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 74.30769230769232, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 74.30769230769232, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 75.23076923076924, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 75.23076923076924, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 75.23076923076924, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 76.15384615384616, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 76.15384615384616, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 76.15384615384616, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 77.07692307692308, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 77.07692307692308, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 77.07692307692308, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 78.00000000000001, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 78.00000000000001, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 78.00000000000001, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 78.92307692307693, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 78.92307692307693, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 78.92307692307693, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 79.84615384615385, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 79.84615384615385, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 79.84615384615385, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 80.76923076923077, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 80.76923076923077, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 80.76923076923077, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 81.69230769230771, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 81.69230769230771, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 81.69230769230771, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 82.61538461538463, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 82.61538461538463, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 82.61538461538463, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 83.53846153846155, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 83.53846153846155, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 83.53846153846155, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 84.46153846153847, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 84.46153846153847, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 84.46153846153847, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 85.3846153846154, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 85.3846153846154, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 85.3846153846154, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 86.30769230769232, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 86.30769230769232, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 86.30769230769232, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 87.23076923076924, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 87.23076923076924, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 87.23076923076924, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 88.15384615384616, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 88.15384615384616, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 88.15384615384616, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 89.0769230769231, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 89.0769230769231, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 89.0769230769231, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 90.00000000000001, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 90.00000000000001, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 90.00000000000001, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 90.92307692307693, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 90.92307692307693, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 90.92307692307693, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 91.84615384615385, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 91.84615384615385, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 91.84615384615385, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 92.76923076923079, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 92.76923076923079, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 92.76923076923079, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 93.69230769230771, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 93.69230769230771, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 93.69230769230771, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 94.61538461538463, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 94.61538461538463, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 94.61538461538463, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 95.53846153846155, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 95.53846153846155, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 95.53846153846155, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 96.46153846153848, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 96.46153846153848, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 96.46153846153848, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 97.3846153846154, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 97.3846153846154, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 97.3846153846154, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 98.30769230769232, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 98.30769230769232, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 98.30769230769232, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 99.23076923076924, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 99.23076923076924, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 99.23076923076924, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 100.15384615384617, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 100.15384615384617, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 100.15384615384617, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 101.0769230769231, 0.11538461538461539, 1.0, 218.00000000000003, ir5
 event_i "i", 18, 101.0769230769231, 0.11538461538461539, 1.0, 261.6, ir5
 event_i "i", 18, 101.0769230769231, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 102.00000000000001, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 102.00000000000001, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 102.00000000000001, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 102.92307692307693, 0.11538461538461539, 1.0, 163.5, ir5
 event_i "i", 18, 102.92307692307693, 0.11538461538461539, 1.0, 196.20000000000002, ir5
 event_i "i", 18, 102.92307692307693, 0.11538461538461539, 1.0, 245.25000000000003, ir5
 event_i "i", 18, 103.3846153846154, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 103.61538461538463, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 103.61538461538463, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 103.61538461538463, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 104.0769230769231, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 104.0769230769231, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 104.0769230769231, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 104.76923076923079, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 104.76923076923079, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 104.76923076923079, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 105.23076923076925, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 105.46153846153848, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 105.46153846153848, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 105.46153846153848, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 105.92307692307695, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 105.92307692307695, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 105.92307692307695, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 106.38461538461542, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 106.61538461538464, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 106.61538461538464, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 106.61538461538464, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 106.84615384615387, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 106.96153846153848, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 107.0769230769231, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 107.30769230769232, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 107.30769230769232, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 107.30769230769232, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 107.76923076923079, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 107.76923076923079, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 107.76923076923079, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 108.46153846153848, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 108.46153846153848, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 108.46153846153848, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 108.92307692307695, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 109.15384615384617, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 109.15384615384617, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 109.15384615384617, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 109.61538461538464, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 109.61538461538464, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 109.61538461538464, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 110.07692307692311, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 110.30769230769234, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 110.30769230769234, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 110.30769230769234, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 110.53846153846156, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 110.65384615384617, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 110.76923076923079, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 111.00000000000001, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 111.00000000000001, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 111.00000000000001, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 111.46153846153848, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 111.46153846153848, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 111.46153846153848, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 112.15384615384617, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 112.15384615384617, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 112.15384615384617, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 112.61538461538464, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 112.84615384615387, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 112.84615384615387, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 112.84615384615387, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 113.30769230769234, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 113.30769230769234, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 113.30769230769234, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 113.7692307692308, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 114.00000000000003, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 114.00000000000003, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 114.00000000000003, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 114.23076923076925, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 114.34615384615387, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 114.46153846153848, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 114.69230769230771, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 114.69230769230771, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 114.69230769230771, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 115.15384615384617, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 115.15384615384617, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 115.15384615384617, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 115.84615384615387, 0.11538461538461539, 1.0, 436.00000000000006, ir5
 event_i "i", 18, 115.84615384615387, 0.11538461538461539, 1.0, 523.2, ir5
 event_i "i", 18, 115.84615384615387, 0.11538461538461539, 1.0, 654.0, ir5
 event_i "i", 18, 116.30769230769234, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 116.53846153846156, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 116.53846153846156, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 116.53846153846156, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 117.00000000000003, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 117.00000000000003, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 117.00000000000003, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 117.4615384615385, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 117.69230769230772, 0.11538461538461539, 1.0, 327.0, ir5
 event_i "i", 18, 117.69230769230772, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 117.69230769230772, 0.11538461538461539, 1.0, 490.50000000000006, ir5
 event_i "i", 18, 117.92307692307695, 0.11538461538461539, 1.0, 392.40000000000003, ir5
 event_i "i", 18, 118.03846153846156, 0.11538461538461539, 1.0, 327.0, ir5
krl0 = 2.0
kr0 = krl0
S1045 sprintf "alive_%d", ir5
 chnset kr0, S1045
krl0 = 2.0
kr0 = krl0
S1052 sprintf "alive_%d", ir1
 chnset kr0, S1052
S1055 sprintf "p1_%d", ir1
ar0 chnget S1055
S1058 sprintf "p2_%d", ir1
ar1 chnget S1058
 chnclear S1055
 chnclear S1058
arl1 init 0.0
arl2 init 0.0
arl1 = ar0
arl2 = ar1
ar0 = arl1
ar1 = arl2
 outs ar0, ar1
endin

instr 19
S1 sprintf "p1_%d", p4
ar0 chnget S1
S4 sprintf "p2_%d", p4
ar1 chnget S4
 chnclear S1
 chnclear S4
arl0 init 0.0
ir13 = 3500.0
ir14 = 0.1
ar2 moogvcf ar0, ir13, ir14
ar0 = (1.0 * ar2)
ar2 = (0.75 * ar0)
ar3 moogvcf ar1, ir13, ir14
ar1 = (1.0 * ar3)
ir20 = 0.8
ir21 = 12000.0
ar3, ar4 reverbsc ar0, ar1, ir20, ir21
ar5 = (ar0 + ar3)
ar0 = (0.25 * ar5)
ar3 = (ar2 + ar0)
arl0 = ar3
ar0 = arl0
S31 sprintf "p1_%d", p5
 chnmix ar0, S31
arl1 init 0.0
ar0 = (0.75 * ar1)
ar2 = (ar1 + ar4)
ar1 = (0.25 * ar2)
ar2 = (ar0 + ar1)
arl1 = ar2
ar0 = arl1
S45 sprintf "p2_%d", p5
 chnmix ar0, S45
endin

instr 18
ir1 = 1.0
ir2 = rnd(ir1)
arl0 init 0.0
kr0 linseg 0.0, 1.0e-2, 1.0, 1.0, 1.0
ar0 upsamp kr0
kr0 linsegr 1.0, 1.0, 1.0, 1.0e-2, 0.0
ar1 upsamp kr0
ar2 = (ar0 * ar1)
ir9 = p5
kr0 vco2ft ir9, 0
ar0 oscilikt ir1, ir9, kr0, ir2
ar1 = (ar2 * ar0)
ar0 = (ar1 * p4)
ar1 = (0.45 * ar0)
arl0 = ar1
ar0 = arl0
S19 sprintf "p1_%d", p6
 chnmix ar0, S19
arl1 init 0.0
arl1 = ar1
ar0 = arl1
S28 sprintf "p2_%d", p6
 chnmix ar0, S28
S31 sprintf "alive_%d", p6
kr0 chnget S31
if (kr0 < -10.0) then
     turnoff 
endif
kr1 = (kr0 - 1.0)
 chnset kr1, S31
endin

</CsInstruments>

<CsScore>

f8 0 1024 10  0.971 0.269 4.1e-2 5.4e-2 1.1e-2 1.3e-2 8.0e-2 6.5e-3 5.0e-3 4.0e-3 3.0e-3 3.0e-3 2.0e-3 2.0e-3 2.0e-3 2.0e-3 2.0e-3 1.0e-3 1.0e-3 1.0e-3 1.0e-3 1.0e-3 2.0e-3 1.0e-3 1.0e-3
f2 0 8192 10  1.0
f4 0 8192 10  1.0 0.0 0.0 0.0 5.0e-2
f6 0 8192 11  1.0

f0 604800.0

i 242 0.0 -1.0 
i 241 0.0 -1.0 
i 239 0.0 -1.0 

</CsScore>



</CsoundSynthesizer>