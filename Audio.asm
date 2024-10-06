AudioCode:
;-------------------------------------------------------------------------------------
; Setup AYFX for playing sound effects - Game events
; Params:
SetupAYFXGame:
; Common AY Chip Settings
; - Setup mapping of chip channels to stereo channels
        nextreg $08, %00010010          ; Use ABC, enable internal speaker + $turbosound
        nextreg $09, %11100000          ; Enable mono for AY1-3
                                        ; A+B+C is sent to both R and L channels, makes it a bit louder than stereo mode

; AY3 - Configure/init AY Chip3
        ld      a, %1'11'111'01         ; Enable left+right audio, select AY3
        ld      bc, $fffd
        out     (c), a

        ld      hl, AyFXBankGame            ; Bank containing sound effects
        call    AFX3Init

; AY2 - Configure/init Second AY Chip2
        ld      a, %1'11'111'10         ; Enable left+right audio, select AY2
        ld      bc, $fffd
        out     (c), a

        ld      hl, AyFXBankGame            ; Bank containing sound effects
        call    AFX2Init

; AY1 - Configure/init Second AY Chip1
        ld      a, %1'11'111'11         ; Enable left+right audio, select AY1
        ld      bc, $fffd
        out     (c), a

        ld      hl, AyFXBankGame            ; Bank containing sound effects
        call    AFX1Init

        ret

;-------------------------------------------------------------------------------------
; Setup AYFX for playing sound effects - Non-game events e.g. Level intro...
; Params:
; hl = AyFXBank -- Bank containing sound effects
SetupAYFXNonGame:
; Common AY Chip Settings
; - Setup mapping of chip channels to stereo channels
        nextreg $08, %00010010          ; Use ABC, enable internal speaker + $turbosound
        nextreg $09, %11100000          ; Enable mono for AY1-3
                                        ; A+B+C is sent to both R and L channels, makes it a bit louder than stereo mode

; AY3 - Configure/init AY Chip3
        ld      a, %1'11'111'01         ; Enable left+right audio, select AY3
        ld      bc, $fffd
        out     (c), a

        push    hl
        call    AFX3Init
        pop     hl

; AY2 - Configure/init Second AY Chip2
        ld      a, %1'11'111'10         ; Enable left+right audio, select AY2
        ld      bc, $fffd
        out     (c), a

        push    hl
        call    AFX2Init
        pop     hl

; AY1 - Configure/init Second AY Chip1
        ld      a, %1'11'111'11         ; Enable left+right audio, select AY1
        ld      bc, $fffd
        out     (c), a

        push    hl
        call    AFX1Init
        pop     hl

        ret

/* 21/06/23 - Not Used
;-------------------------------------------------------------------------------------
; Configure AY3 as mono; call after PlayNextDAWSong
; A+B+C is sent to both R and L channels, makes it a bit louder than stereo mode
; Params:
SetAYToMono:        
        ld      a, $09
        call    ReadNextReg
        
        set     7, a
        set     6, a
        set     5, a
        nextreg $09, a
        
        ret
*/

; -Minimal ayFX player (Improved)  v2.05  25/01/21--------------;
; https://github.com/Threetwosevensixseven/ayfxedit-improved    ;
; Zeus format (http://www.desdes.com/products/oldfiles)         ;
;                                                               ;
; Forked from  v0.15  06/05/06                                  ;
; https://shiru.untergrund.net/software.shtml                   ;
;                                                               ;
; The simplest effects player. Plays effects on one AY,         ;
; without music in the background.                              ;
; Priority of the choice of channels: if there are free         ;
; channels, one of them is selected if free.                    ;
; If there are are no free channels, the longest-sounding       ;
; one is selected.                                              ;
; Procedure plays registers AF, BC, DE, HL, IX.                 ;
;                                                               ;
; Initialization:                                               ;
;   ld hl, the address of the effects bank                      ;
;   call AFXInit                                                ;
;                                                               ;
; Start the effect:                                             ;
;   ld a, the number of the effect (0..255)                     ;
;   call AFXPlay                                                ;
;                                                               ;
; In the interrupt handler:                                     ;
;   call AFXFrame                                               ;
;                                                               ;
; Start the effect on a specified channel:                      ;
;   ld a, the number of the effect (0..255)                     ;
;   ld e, the number of the channel (A=0, B=1, C=2)             ;
;   call AFXPlayChannel                                         ;
;                                                               ;
; Start the effect with sustain loop enabled:                   ;
;   ld a, the number of the effect (0..255)                     ;
;   ld e, the number of the channel (A=0, B=1, C=2)             ;
;   ld bc, the bank address + the release address offset        ;
;   call AFXPlayChannel                                         ;
;                                                               ;
; Notify AFX.Frame that the should be should be looped back to  ;
; the sustain point once the release point has been reached:    ;
;   ld a, the number of the effect (0..255)                     ;
;   ld e, the number of the channel (A=0, B=1, C=2)             ;
;   ld bc, the bank address + the sustain address offset        ;
;   call AFXSustain                                             ;
;                                                               ;
; Change log:
;   v2.05  25/01/21  Bug fix: AFXInit was overwriting itself    ;
;                    the first time it was called, so it        ;
;                    couldn't ever be called a second time.     ;       												;
;   v2.04  22/10/17  Bug fix: EffectTime was not fully          ;
;                    initialised.                               ;
;   v2.03  22/10/17  Bug fix: disabled loop markers should have ;
;                    MSB $00, as $FF could be a valid address.  ;
;                    Backported Zeus player to Pasmo format.    ;
;   v2.02  21/10/17  Added the ability to loop a sound while    ;
;                    receiving sustain messages.                ;
;   v2.01  21/10/17  Added the ability to play a sound on a     ;
;                    specific channel.                          ;
;   v2.00  27/08/17  Converted Z80 player to Zeus format.       ;
; --------------------------------------------------------------;

; ****** AYChip1 Routine (for selected chip, not AY1 chip) ******
;
; Channel descriptors, 4 bytes per channel:
; +0 (2) current address (channel is free if high byte=$00)
; +2 (2) sound effect time
; +2 (2) start address of sustain loop (disabled if high byte=$00)
; +2 (2) end address of sustain loop (disabled if high byte=$00)

; --------------------------------------------------------------;
; Initialize the effects player - AYChip1                       ;
; Turns off all channels, sets variables.                       ;
;                                                               ;
; Input: HL = bank address with effects                         ;
; --------------------------------------------------------------;

AFX3Init:
                        inc hl
                        ld (afx3BnkAdr1+1), hl           ; Save the address of the table of offsets
                        ;;;ld (afx3BnkAdr2+1), hl           ; Save the address of the table of offsets
                        ld hl, afx3ChDesc                ; Mark all channels as empty
                        ld de, $00ff
                        ld bc, afx3ChDescCount*256+$fd

; Initialise afxDesc table
afx3Init0:
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), e
                        inc hl
                        ld (hl), e
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        djnz afx3Init0

; Initialize  AY
                        ld hl, $ffbf                    
                        ld e, $15
; Reset AY registers
afx3Init1:
                        dec e
                        ld b, h
                        out (c), e
                        ld b,l
                        out (c), d
                        jr nz, afx3Init1

                        ld (afx3NseMix+1), de            ; Reset the player variables

                        ret

; --------------------------------------------------------------;
; Play the current frame.                                       ;
;                                                               ;
; No parameters.                                                ;
; --------------------------------------------------------------;
AFX3Frame:
; Select AY3 Chip
                        ld      a, %1'11'111'01         ; Enable left+right audio, select AY3
                        ld      bc, $fffd
                        out     (c), a

                        ld bc, $03fd
                        ld ix, afx3ChDesc
afx3Frame0:
                        push bc

                        ld a,11
                        ld h,(ix+1)                     ; Compare high-order byte of address to <11
                        cp h
                        jr nc, afx3Frame7                ; The channel does not play, we skip
                        ld l, (ix+0)
                        ld e, (hl)                      ; We take the value of the information byte
                        inc hl
                        
                        sub b                           ; Select the volume register:
                        ld d, b                         ; (11-3=8, 11-2=9, 11-1=10)

                        ld b, $ff                       ; Output the volume value
                        out (c), a
                        ld b, $bf
                        ld a, e
                        and $0f
                        out (c), a

                        bit 5, e                        ; Will the tone change?
                        jr z, afx3Frame1                 ; Tone does not change

                        ld a, 3                         ; Select the tone registers:
                        sub d                           ; 3-3=0, 3-2=1, 3-1=2
                        add a, a                        ; 0*2=0, 1*2=2, 2*2=4

                        ld b, $ff                       ; Output the tone values
                        out (c), a
                        ld b, $bf
                        ld d, (hl)
                        inc hl
                        out (c), d
                        ld b, $ff
                        inc a
                        out (c), a
                        ld b, $bf
                        ld d, (hl)
                        inc hl
                        out (c), d

afx3Frame1:
                        bit 6, e                        ; Will the noise change?
                        jr z, afx3Frame3                 ; Noise does not change

                        ld a, (hl)                      ; Read the meaning of noise
                        sub $20
                        jr c, afx3Frame2                 ; Less than $20, play on
                        ld h, a                         ; Otherwise the end of the effect
                        ld c,$ff
                        ld b, c                         ; In BC we record the most time
                        jr afx3Frame6

afx3Frame2:
                        inc hl
                        ld (afx3NseMix+1), a             ; Keep the noise value

afx3Frame3:
                        pop bc                          ; Restore the value of the cycle in B
                        push bc
                        inc b                           ; Number of shifts for flags TN

                        ld a, %01101111                 ; Mask for flags TN
afx3Frame4:
                        rrc e                           ; Shift flags and mask
                        rrca
                        djnz afx3Frame4
                        ld d, a

                        ld bc, afx3NseMix+2              ; Store the values of the flags
                        ld a, (bc)
                        xor e
                        and d
                        xor e                           ; E is masked with D
                        ld (bc), a

afx3Frame5:
                        ld c, (ix+2)                    ; Increase the time counter
                        ld b, (ix+3)
                        inc bc

afx3Frame6:
                        ld (ix+2), c
                        ld (ix+3), b

                        ld (ix+0), l                    ; Save the changed address
                        ld (ix+1), h

                        call CheckRelease3
afx3Frame7:
                        ld bc, 8                        ; Go to the next channel
                        add ix, bc
                        pop bc
                        djnz afx3Frame0

                        ld hl, $ffbf                    ; Output the value of noise and mixer
afx3NseMix:
                        ld de, 0                        ; +1(E)=noise, +2(D)=mixer
                        ld a, 6
                        ld b, h
                        out (c), a
                        ld b, l
                        out (c), e
                        inc a
                        ld b, h
                        out (c), a
                        ld b, l
                        out (c), d
                        ret
CheckRelease3:
                        ld a, (ix+6)                    ; get release LSB
                        cp l
                        ret nz                          ; Carry on if no MLB match
                        ld a, (ix+7)                    ; get release MSB
                        or a
                        ret z                           ; Carry on if release disabled
                        cp h
                        ret nz                          ; Carry on if no MSB match
                        push bc
                        ld a, (ix+4)
                        or a
                        jp z, NoLoop3
                        ld a, (ix+5)                    ; Set CurrentAddrCh[N] back
                        ld (ix+1), a                    ; to  SustainAddrCh[N] LSB
                        ld a, (ix+4)                    ;
                        ld (ix+0), a                    ; and                  MSB
                        xor a
                        ld (ix+4), a                    ; then toggle off the sustain
                        ld (ix+5), a                    ; to require it to be resent
NoLoop3:
                        pop bc
                        ret

/* 21/06/23 - Not Used
; --------------------------------------------------------------;
; Launch the effect on a specific channel. Any sound currently  ;
; playing on that channel is terminated next frame.             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
;        E = Channel (A=0, B=1, C=2)                            ;
; --------------------------------------------------------------;
AFX3PlayChannel:
                        ld bc, $0000

; --------------------------------------------------------------;
; Launch the effect on a specific channel. Any sound currently  ;
; playing on that channel is terminated next frame.             ;
; During playback, when reaching ReleaseAddrCh[N], if an        ;
; AFXSustain call has been received since this AFXPlayLooped    ;
; returned, the playback time frame will loop back to           ;
; SustainAddrCh[N].                                             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
;        E = Channel (A=0, B=1, C=2)                            ;
;       BC = ReleaseAddrCh[N]                                   ;
; --------------------------------------------------------------;
AFX3PlayLooped:
                        push af
                        ld a, c
                        ld (ReleaseLoSMC3), a            ; SMC>
                        ld a, b
                        ld (ReleaseHiSMC3), a            ; SMC>
                        ld a, e
                        add a, a
                        add a, a
                        add a, a
                        ld e, a
                        ld d, 0
                        ld ix, afx3ChDesc
                        add ix, de
                        ld e, 3
                        add ix, de
                        pop af
                        ld de, 0                        ; In DE the longest time in search
                        ld h, e
                        ld l, a
                        add hl, hl
afx3BnkAdr2:
                        ld bc, 0                        ; Address of the effect offsets table
                        add hl, bc
                        ld c, (hl)
                        inc hl
                        ld b, (hl)
                        add hl, bc                      ; The effect address is obtained in hl
                        push hl                         ; Save the effect address on the stack
                        jp DoPlay3
*/

; --------------------------------------------------------------;
; Launch the effect on a free channel. If no free channels,     ;
; the longest sounding is selected.                             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
; --------------------------------------------------------------;
AFX3Play:
                        push af

                        ld a, c
                        ld (ReleaseLoSMC3), a            ; SMC>
                        ld a, b
                        ld (ReleaseHiSMC3), a            ; SMC>
                        pop af
                        ld de, 0                        ; In DE the longest time in search
                        ld h, e
                        ld l, a
                        add hl, hl
afx3BnkAdr1:
                        ld bc, 0                        ; Address of the effect offsets table
                        add hl, bc
                        ld c, (hl)
                        inc hl
                        ld b, (hl)
                        add hl, bc                      ; The effect address is obtained in hl
                        push hl                         ; Save the effect address on the stack
                        ld hl, afx3ChDesc                ; Empty channel search
                        ld b, 3
afx3Play0:
                        inc hl
                        inc hl
                        ld a, (hl)                      ; Compare the channel time with the largest
                        inc hl
                        cp e
                        jr c, afx3Play1
                        ld c, a
                        ld a, (hl)
                        cp d
                        jr c, afx3Play1
                        ld e, c                         ; Remember the longest time
                        ld d, a
                        push hl                         ; Remember the channel address+3 in IX
                        pop ix
afx3Play1:
                        ld a, 5
                        add a, l						; Add(hl, a) }
                        ld l, a							;			 }
                        adc a, h						;			 }
                        sub l							;			 }
                        ld h, a							;			 }			
                        djnz afx3Play0
DoPlay3:
                        pop de                          ; Take the effect address from the stack
                        ld (ix-3), e                    ; Put in the channel descriptor
                        ld (ix-2), d
                        ld (ix-1), b                    ; Zero the playing time
                        ld (ix-0), b 
ReleaseLoSMC3 equ $+3  
                        ld (ix+3), AFX3SMC               ; <SMC Release LSB
ReleaseHiSMC3 equ $+3
			ld (ix+4), AFX3SMC               ; <SMC Release MSB
                        xor a
                        ld (ix+1), a                    ; Reset sustain LSB
                        ld (ix+2), a                    ; Reset sustain MSB
                        ret

/* 21/06/23 - Not Used
; --------------------------------------------------------------;
; Notify AFX.Frame that the sound in channel E should be looped ;
; back to SustainAddrCh[N] once ReleaseAddrCh[N] has been       ;
; reached,provided playback was started with AFX.PlayLooped     ;
;                                                               ;
; Input: E = Channel (A=0, B=1, C=2)                            ;
;       BC = SustainAddrCh[N]                                   ;
; --------------------------------------------------------------;
AFX3Sustain:
                        ld a, e
                        add a, a
                        add a, a
                        add a, a
                        ld e, 4
                        add a, e
                        ld hl, afx3ChDesc
                        add a, l						; Add(hl, a) }
                        ld l, a							;			 }
                        adc a, h						;			 }
                        sub l							;			 }
                        ld h, a							;			 }	
                        ld (hl), c
                        inc hl
                        ld (hl), b
                        ret
*/

; ****** AYChip2 Routines ******
;
; Channel descriptors, 4 bytes per channel:
; +0 (2) current address (channel is free if high byte=$00)
; +2 (2) sound effect time
; +2 (2) start address of sustain loop (disabled if high byte=$00)
; +2 (2) end address of sustain loop (disabled if high byte=$00)

; --------------------------------------------------------------;
; Initialize the effects player - AYChip2                       ;
; Turns off all channels, sets variables.                       ;
;                                                               ;
; Input: HL = bank address with effects                         ;
; --------------------------------------------------------------;

AFX2Init:
                        inc hl
                        ld (afx2BnkAdr1+1), hl           ; Save the address of the table of offsets
                        ;;;ld (afx2BnkAdr2+1), hl           ; Save the address of the table of offsets
                        ld hl, afx2ChDesc                ; Mark all channels as empty
                        ld de, $00ff
                        ld bc, afx2ChDescCount*256+$fd

; Initialise afxDesc table
afx2Init0:
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), e
                        inc hl
                        ld (hl), e
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        djnz afx2Init0

; Initialize  AY
                        ld hl, $ffbf                    
                        ld e, $15
; Reset AY registers
afx2Init1:
                        dec e
                        ld b, h
                        out (c), e
                        ld b,l
                        out (c), d
                        jr nz, afx2Init1

                        ld (afx2NseMix+1), de            ; Reset the player variables

                        ret

; --------------------------------------------------------------;
; Play the current frame.                                       ;
;                                                               ;
; No parameters.                                                ;
; --------------------------------------------------------------;
AFX2Frame:
; Select AY2 Chip
                        ld      a, %1'11'111'10         ; Enable left+right audio, select AY2
                        ld      bc, $fffd
                        out     (c), a

                        ld bc, $03fd
                        ld ix, afx2ChDesc
afx2Frame0:
                        push bc

                        ld a,11
                        ld h,(ix+1)                     ; Compare high-order byte of address to <11
                        cp h
                        jr nc, afx2Frame7                ; The channel does not play, we skip
                        ld l, (ix+0)
                        ld e, (hl)                      ; We take the value of the information byte
                        inc hl
                        
                        sub b                           ; Select the volume register:
                        ld d, b                         ; (11-3=8, 11-2=9, 11-1=10)

                        ld b, $ff                       ; Output the volume value
                        out (c), a
                        ld b, $bf
                        ld a, e
                        and $0f
                        out (c), a

                        bit 5, e                        ; Will the tone change?
                        jr z, afx2Frame1                 ; Tone does not change

                        ld a, 3                         ; Select the tone registers:
                        sub d                           ; 3-3=0, 3-2=1, 3-1=2
                        add a, a                        ; 0*2=0, 1*2=2, 2*2=4

                        ld b, $ff                       ; Output the tone values
                        out (c), a
                        ld b, $bf
                        ld d, (hl)
                        inc hl
                        out (c), d
                        ld b, $ff
                        inc a
                        out (c), a
                        ld b, $bf
                        ld d, (hl)
                        inc hl
                        out (c), d

afx2Frame1:
                        bit 6, e                        ; Will the noise change?
                        jr z, afx2Frame3                 ; Noise does not change

                        ld a, (hl)                      ; Read the meaning of noise
                        sub $20
                        jr c, afx2Frame2                 ; Less than $20, play on
                        ld h, a                         ; Otherwise the end of the effect
                        ld c,$ff
                        ld b, c                         ; In BC we record the most time
                        jr afx2Frame6

afx2Frame2:
                        inc hl
                        ld (afx2NseMix+1), a             ; Keep the noise value

afx2Frame3:
                        pop bc                          ; Restore the value of the cycle in B
                        push bc
                        inc b                           ; Number of shifts for flags TN

                        ld a, %01101111                 ; Mask for flags TN
afx2Frame4:
                        rrc e                           ; Shift flags and mask
                        rrca
                        djnz afx2Frame4
                        ld d, a

                        ld bc, afx2NseMix+2              ; Store the values of the flags
                        ld a, (bc)
                        xor e
                        and d
                        xor e                           ; E is masked with D
                        ld (bc), a

afx2Frame5:
                        ld c, (ix+2)                    ; Increase the time counter
                        ld b, (ix+3)
                        inc bc

afx2Frame6:
                        ld (ix+2), c
                        ld (ix+3), b

                        ld (ix+0), l                    ; Save the changed address
                        ld (ix+1), h

                        call CheckRelease2
afx2Frame7:
                        ld bc, 8                        ; Go to the next channel
                        add ix, bc
                        pop bc
                        djnz afx2Frame0

                        ld hl, $ffbf                    ; Output the value of noise and mixer
afx2NseMix:
                        ld de, 0                        ; +1(E)=noise, +2(D)=mixer
                        ld a, 6
                        ld b, h
                        out (c), a
                        ld b, l
                        out (c), e
                        inc a
                        ld b, h
                        out (c), a
                        ld b, l
                        out (c), d
                        ret
CheckRelease2:
                        ld a, (ix+6)                    ; get release LSB
                        cp l
                        ret nz                          ; Carry on if no MLB match
                        ld a, (ix+7)                    ; get release MSB
                        or a
                        ret z                           ; Carry on if release disabled
                        cp h
                        ret nz                          ; Carry on if no MSB match
                        push bc
                        ld a, (ix+4)
                        or a
                        jp z, NoLoop2
                        ld a, (ix+5)                    ; Set CurrentAddrCh[N] back
                        ld (ix+1), a                    ; to  SustainAddrCh[N] LSB
                        ld a, (ix+4)                    ;
                        ld (ix+0), a                    ; and                  MSB
                        xor a
                        ld (ix+4), a                    ; then toggle off the sustain
                        ld (ix+5), a                    ; to require it to be resent
NoLoop2:
                        pop bc
                        ret

/* 21/06/23 - Not Used
; --------------------------------------------------------------;
; Launch the effect on a specific channel. Any sound currently  ;
; playing on that channel is terminated next frame.             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
;        E = Channel (A=0, B=1, C=2)                            ;
; --------------------------------------------------------------;
AFX2PlayChannel:
                        ld bc, $0000

; --------------------------------------------------------------;
; Launch the effect on a specific channel. Any sound currently  ;
; playing on that channel is terminated next frame.             ;
; During playback, when reaching ReleaseAddrCh[N], if an        ;
; AFXSustain call has been received since this AFXPlayLooped    ;
; returned, the playback time frame will loop back to           ;
; SustainAddrCh[N].                                             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
;        E = Channel (A=0, B=1, C=2)                            ;
;       BC = ReleaseAddrCh[N]                                   ;
; --------------------------------------------------------------;
AFX2PlayLooped:
                        push af
                        ld a, c
                        ld (ReleaseLoSMC2), a            ; SMC>
                        ld a, b
                        ld (ReleaseHiSMC2), a            ; SMC>
                        ld a, e
                        add a, a
                        add a, a
                        add a, a
                        ld e, a
                        ld d, 0
                        ld ix, afx2ChDesc
                        add ix, de
                        ld e, 3
                        add ix, de
                        pop af
                        ld de, 0                        ; In DE the longest time in search
                        ld h, e
                        ld l, a
                        add hl, hl
afx2BnkAdr2:
                        ld bc, 0                        ; Address of the effect offsets table
                        add hl, bc
                        ld c, (hl)
                        inc hl
                        ld b, (hl)
                        add hl, bc                      ; The effect address is obtained in hl
                        push hl                         ; Save the effect address on the stack
                        jp DoPlay2
*/

; --------------------------------------------------------------;
; Launch the effect on a free channel. If no free channels,     ;
; the longest sounding is selected.                             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
; --------------------------------------------------------------;
AFX2Play:
                        push af

                        ld a, c
                        ld (ReleaseLoSMC2), a            ; SMC>
                        ld a, b
                        ld (ReleaseHiSMC2), a            ; SMC>
                        pop af
                        ld de, 0                        ; In DE the longest time in search
                        ld h, e
                        ld l, a
                        add hl, hl
afx2BnkAdr1:
                        ld bc, 0                        ; Address of the effect offsets table
                        add hl, bc
                        ld c, (hl)
                        inc hl
                        ld b, (hl)
                        add hl, bc                      ; The effect address is obtained in hl
                        push hl                         ; Save the effect address on the stack
                        ld hl, afx2ChDesc                ; Empty channel search
                        ld b, 3
afx2Play0:
                        inc hl
                        inc hl
                        ld a, (hl)                      ; Compare the channel time with the largest
                        inc hl
                        cp e
                        jr c, afx2Play1
                        ld c, a
                        ld a, (hl)
                        cp d
                        jr c, afx2Play1
                        ld e, c                         ; Remember the longest time
                        ld d, a
                        push hl                         ; Remember the channel address+3 in IX
                        pop ix
afx2Play1:
                        ld a, 5
                        add a, l						; Add(hl, a) }
                        ld l, a							;			 }
                        adc a, h						;			 }
                        sub l							;			 }
                        ld h, a							;			 }			
                        djnz afx2Play0
DoPlay2:
                        pop de                          ; Take the effect address from the stack
                        ld (ix-3), e                    ; Put in the channel descriptor
                        ld (ix-2), d
                        ld (ix-1), b                    ; Zero the playing time
                        ld (ix-0), b 
ReleaseLoSMC2 equ $+3  
						ld (ix+3), AFX2SMC               ; <SMC Release LSB
ReleaseHiSMC2 equ $+3
						ld (ix+4), AFX2SMC               ; <SMC Release MSB
                        xor a
                        ld (ix+1), a                    ; Reset sustain LSB
                        ld (ix+2), a                    ; Reset sustain MSB
                        ret


/* 21/06/23 - Not Used
; --------------------------------------------------------------;
; Notify AFX.Frame that the sound in channel E should be looped ;
; back to SustainAddrCh[N] once ReleaseAddrCh[N] has been       ;
; reached,provided playback was started with AFX.PlayLooped     ;
;                                                               ;
; Input: E = Channel (A=0, B=1, C=2)                            ;
;       BC = SustainAddrCh[N]                                   ;
; --------------------------------------------------------------;
AFX2Sustain:
                        ld a, e
                        add a, a
                        add a, a
                        add a, a
                        ld e, 4
                        add a, e
                        ld hl, afx2ChDesc
                        add a, l						; Add(hl, a) }
                        ld l, a							;			 }
                        adc a, h						;			 }
                        sub l							;			 }
                        ld h, a							;			 }	
                        ld (hl), c
                        inc hl
                        ld (hl), b
                        ret
*/
; ****** AYChip1 Routines ******
;
; Channel descriptors, 4 bytes per channel:
; +0 (2) current address (channel is free if high byte=$00)
; +2 (2) sound effect time
; +2 (2) start address of sustain loop (disabled if high byte=$00)
; +2 (2) end address of sustain loop (disabled if high byte=$00)

; --------------------------------------------------------------;
; Initialize the effects player - AYChip1                       ;
; Turns off all channels, sets variables.                       ;
;                                                               ;
; Input: HL = bank address with effects                         ;
; --------------------------------------------------------------;

AFX1Init:
                        inc hl
                        ld (AFX1BnkAdr1+1), hl           ; Save the address of the table of offsets
                        ;;;ld (AFX1BnkAdr2+1), hl           ; Save the address of the table of offsets
                        ld hl, afx1ChDesc                ; Mark all channels as empty
                        ld de, $00ff
                        ld bc, afx1ChDescCount*256+$fd
; Initialise afxDesc table
AFX1Init0:
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), e
                        inc hl
                        ld (hl), e
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        ld (hl), d
                        inc hl
                        djnz AFX1Init0

; Initialize  AY
                        ld hl, $ffbf                    
                        ld e, $15
; Reset AY registers
AFX1Init1:
                        dec e
                        ld b, h
                        out (c), e
                        ld b,l
                        out (c), d
                        jr nz, AFX1Init1

                        ld (AFX1NseMix+1), de            ; Reset the player variables

                        ret

; --------------------------------------------------------------;
; Play the current frame.                                       ;
;                                                               ;
; No parameters.                                                ;
; --------------------------------------------------------------;
AFX1Frame:
; Select AY1 Chip
                        ld      a, %1'11'111'11         ; Enable left+right audio, select AY1
                        ld      bc, $fffd
                        out     (c), a

                        ld bc, $03fd
                        ld ix, afx1ChDesc
AFX1Frame0:
                        push bc

                        ld a,11
                        ld h,(ix+1)                     ; Compare high-order byte of address to <11
                        cp h
                        jr nc, AFX1Frame7                ; The channel does not play, we skip
                        ld l, (ix+0)
                        ld e, (hl)                      ; We take the value of the information byte
                        inc hl
                        
                        sub b                           ; Select the volume register:
                        ld d, b                         ; (11-3=8, 11-2=9, 11-1=10)

                        ld b, $ff                       ; Output the volume value
                        out (c), a
                        ld b, $bf
                        ld a, e
                        and $0f
                        out (c), a

                        bit 5, e                        ; Will the tone change?
                        jr z, AFX1Frame1                 ; Tone does not change

                        ld a, 3                         ; Select the tone registers:
                        sub d                           ; 3-3=0, 3-2=1, 3-1=2
                        add a, a                        ; 0*2=0, 1*2=2, 2*2=4

                        ld b, $ff                       ; Output the tone values
                        out (c), a
                        ld b, $bf
                        ld d, (hl)
                        inc hl
                        out (c), d
                        ld b, $ff
                        inc a
                        out (c), a
                        ld b, $bf
                        ld d, (hl)
                        inc hl
                        out (c), d

AFX1Frame1:
                        bit 6, e                        ; Will the noise change?
                        jr z, AFX1Frame3                 ; Noise does not change

                        ld a, (hl)                      ; Read the meaning of noise
                        sub $20
                        jr c, AFX1Frame2                 ; Less than $20, play on
                        ld h, a                         ; Otherwise the end of the effect
                        ld c,$ff
                        ld b, c                         ; In BC we record the most time
                        jr AFX1Frame6

AFX1Frame2:
                        inc hl
                        ld (AFX1NseMix+1), a             ; Keep the noise value

AFX1Frame3:
                        pop bc                          ; Restore the value of the cycle in B
                        push bc
                        inc b                           ; Number of shifts for flags TN

                        ld a, %01101111                 ; Mask for flags TN
AFX1Frame4:
                        rrc e                           ; Shift flags and mask
                        rrca
                        djnz AFX1Frame4
                        ld d, a

                        ld bc, AFX1NseMix+2              ; Store the values of the flags
                        ld a, (bc)
                        xor e
                        and d
                        xor e                           ; E is masked with D
                        ld (bc), a

AFX1Frame5:
                        ld c, (ix+2)                    ; Increase the time counter
                        ld b, (ix+3)
                        inc bc

AFX1Frame6:
                        ld (ix+2), c
                        ld (ix+3), b

                        ld (ix+0), l                    ; Save the changed address
                        ld (ix+1), h

                        call CheckRelease1
AFX1Frame7:
                        ld bc, 8                        ; Go to the next channel
                        add ix, bc
                        pop bc
                        djnz AFX1Frame0

                        ld hl, $ffbf                    ; Output the value of noise and mixer
AFX1NseMix:
                        ld de, 0                        ; +1(E)=noise, +2(D)=mixer
                        ld a, 6
                        ld b, h
                        out (c), a
                        ld b, l
                        out (c), e
                        inc a
                        ld b, h
                        out (c), a
                        ld b, l
                        out (c), d
                        ret
CheckRelease1:
                        ld a, (ix+6)                    ; get release LSB
                        cp l
                        ret nz                          ; Carry on if no MLB match
                        ld a, (ix+7)                    ; get release MSB
                        or a
                        ret z                           ; Carry on if release disabled
                        cp h
                        ret nz                          ; Carry on if no MSB match
                        push bc
                        ld a, (ix+4)
                        or a
                        jp z, NoLoop1
                        ld a, (ix+5)                    ; Set CurrentAddrCh[N] back
                        ld (ix+1), a                    ; to  SustainAddrCh[N] LSB
                        ld a, (ix+4)                    ;
                        ld (ix+0), a                    ; and                  MSB
                        xor a
                        ld (ix+4), a                    ; then toggle off the sustain
                        ld (ix+5), a                    ; to require it to be resent
NoLoop1:
                        pop bc
                        ret

/* 21/06/23 - Not Used
; --------------------------------------------------------------;
; Launch the effect on a specific channel. Any sound currently  ;
; playing on that channel is terminated next frame.             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
;        E = Channel (A=0, B=1, C=2)                            ;
; --------------------------------------------------------------;
AFX1PlayChannel:
                        ld bc, $0000

; --------------------------------------------------------------;
; Launch the effect on a specific channel. Any sound currently  ;
; playing on that channel is terminated next frame.             ;
; During playback, when reaching ReleaseAddrCh[N], if an        ;
; AFXSustain call has been received since this AFXPlayLooped    ;
; returned, the playback time frame will loop back to           ;
; SustainAddrCh[N].                                             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
;        E = Channel (A=0, B=1, C=2)                            ;
;       BC = ReleaseAddrCh[N]                                   ;
; --------------------------------------------------------------;
AFX1PlayLooped:
                        push af
                        ld a, c
                        ld (ReleaseLoSMC1), a            ; SMC>
                        ld a, b
                        ld (ReleaseHiSMC1), a            ; SMC>
                        ld a, e
                        add a, a
                        add a, a
                        add a, a
                        ld e, a
                        ld d, 0
                        ld ix, AFX1ChDesc
                        add ix, de
                        ld e, 3
                        add ix, de
                        pop af
                        ld de, 0                        ; In DE the longest time in search
                        ld h, e
                        ld l, a
                        add hl, hl
AFX1BnkAdr2:
                        ld bc, 0                        ; Address of the effect offsets table
                        add hl, bc
                        ld c, (hl)
                        inc hl
                        ld b, (hl)
                        add hl, bc                      ; The effect address is obtained in hl
                        push hl                         ; Save the effect address on the stack
                        jp DoPlay2
*/

; --------------------------------------------------------------;
; Launch the effect on a free channel. If no free channels,     ;
; the longest sounding is selected.                             ;
;                                                               ;
; Input: A = Effect number 0..255                               ;
; --------------------------------------------------------------;
AFX1Play:
                        push af

                        ld a, c
                        ld (ReleaseLoSMC1), a            ; SMC>
                        ld a, b
                        ld (ReleaseHiSMC1), a            ; SMC>
                        pop af
                        ld de, 0                        ; In DE the longest time in search
                        ld h, e
                        ld l, a
                        add hl, hl
AFX1BnkAdr1:
                        ld bc, 0                        ; Address of the effect offsets table
                        add hl, bc
                        ld c, (hl)
                        inc hl
                        ld b, (hl)
                        add hl, bc                      ; The effect address is obtained in hl
                        push hl                         ; Save the effect address on the stack
                        ld hl, afx1ChDesc                ; Empty channel search
                        ld b, 3
AFX1Play0:
                        inc hl
                        inc hl
                        ld a, (hl)                      ; Compare the channel time with the largest
                        inc hl
                        cp e
                        jr c, AFX1Play1
                        ld c, a
                        ld a, (hl)
                        cp d
                        jr c, AFX1Play1
                        ld e, c                         ; Remember the longest time
                        ld d, a
                        push hl                         ; Remember the channel address+3 in IX
                        pop ix
AFX1Play1:
                        ld a, 5
                        add a, l						; Add(hl, a) }
                        ld l, a							;			 }
                        adc a, h						;			 }
                        sub l							;			 }
                        ld h, a							;			 }			
                        djnz AFX1Play0
DoPlay1:
                        pop de                          ; Take the effect address from the stack
                        ld (ix-3), e                    ; Put in the channel descriptor
                        ld (ix-2), d
                        ld (ix-1), b                    ; Zero the playing time
                        ld (ix-0), b 
ReleaseLoSMC1 equ $+3  
						ld (ix+3), AFX1SMC               ; <SMC Release LSB
ReleaseHiSMC1 equ $+3
						ld (ix+4), AFX1SMC               ; <SMC Release MSB
                        xor a
                        ld (ix+1), a                    ; Reset sustain LSB
                        ld (ix+2), a                    ; Reset sustain MSB
                        ret


/* 21/06/23 - Not Used
; --------------------------------------------------------------;
; Notify AFX.Frame that the sound in channel E should be looped ;
; back to SustainAddrCh[N] once ReleaseAddrCh[N] has been       ;
; reached,provided playback was started with AFX.PlayLooped     ;
;                                                               ;
; Input: E = Channel (A=0, B=1, C=2)                            ;
;       BC = SustainAddrCh[N]                                   ;
; --------------------------------------------------------------;
AFX1Sustain:
                        ld a, e
                        add a, a
                        add a, a
                        add a, a
                        ld e, 4
                        add a, e
                        ld hl, AFX1ChDesc
                        add a, l						; Add(hl, a) }
                        ld l, a							;			 }
                        adc a, h						;			 }
                        sub l							;			 }
                        ld h, a							;			 }	
                        ld (hl), c
                        inc hl
                        ld (hl), b
                        ret
*/

EndofAudioCode: