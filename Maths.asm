MathsCode:
;-------------------------------------------------------------------------------------
BC_Div_DE_88:
;Inputs:
;     DE,BC are 8.8 Fixed Point numbers
;Outputs:
;     DE is the 8.8 Fixed Point result (rounded to the least significant bit)
;if DE is 0 : 122cc or 136cc if BC is negative
;if |BC|>=128*|DE| : 152cc or 166cc if BC is negative
;Otherwise:
;min: 1107cc
;max: 1319cc
;avg: 1201cc

; RM Update - Added as values over >=128 produced incorrect results
        ld      a, 127
        cp      b
        jp      nc, .Check2     ; Jump if b <=127

        ld      b, 127

.Check2:
        ld      a, 127
        cp      d
        jp      nc, .Cont       ; Jump if d <=127

        ld      d, 127          ; Reset d to 127

.Cont:
; First, find out if the output is positive or negative
    ld a,b
    xor d
    push af   ;sign bit is the result sign bit

; Now make sure the inputs are positive
    xor b     ;A now has the value of B, since I XORed it with D twice (cancelling)
    jp p,BC_Div_DE_88_lbl1   ;if Positive, don't negate
    xor a
    sub c
    ld c,a
    sbc a,a
    sub b
    ld b,a
BC_Div_DE_88_lbl1:

;now make DE negative to optimize the remainder comparison
    ld a,d
    or d
    jp m,BC_Div_DE_88_lbl2
    xor a
    sub e
    ld e,a
    sbc a,a
    sub d
    ld d,a
BC_Div_DE_88_lbl2:

;if DE is 0, we can call it an overflow
;A is the current value of D
  or e
  jr z,div_fixed88_overflow

;The accumulator gets set to B if no overflow.
;We can use H=0 to save a few cc in the meantime
    ld h,0

;if B+DE>=0, then we'll have overflow
    ld a,b
    add a,e
    ld a,d
    adc a,h
    jr c,div_fixed88_overflow

;Now we can load the accumulator/remainder with B
;H is already 0
    ld l,b

    ld a,c
    call div_fixed88_sub
    ld c,a

    ld a,b      ;A is now 0
    call div_fixed88_sub

    ld d,c
    ld e,a
    pop af
    ret p
    xor a
    sub e
    ld e,a
    sbc a,a
    sub d
    ld d,a
    ret

div_fixed88_overflow:
    ld de,$7FFF
    pop af
    ret p
    inc de
    inc e
    ret

div_fixed88_sub:
;min: 456cc
;max: 536cc
;avg: 496cc
    ld b,8
BC_Div_DE_88_lbl3:
    rla
    adc hl,hl
    add hl,de
    jr c,$+4
    sbc hl,de
    djnz BC_Div_DE_88_lbl3
    adc a,a
    ret

;-------------------------------------------------------------------------------------
; Convert Tangent (of the angle) to Angle/Rotation
; Parameters:
; d = Tangent before decimal point
; e = Tangent after decimal point
; Note: Actual value = de/256
; Return:
; a = Rotation value
; Notes:
; - Tangent parameter (8.8 format) calculated by Opposite/Adjacent i.e. Distance vector y/x
; - To find angle, match the tangent with specific values in the Table of tan(angle)
; - e.g. 5 degrees = tangent of 0.0875
; - Therefore to match with routine parameters - Convert the table value to the corresponding de value (8.8 format)
; - i.e. 0.0875 * 256 = 22.4, but round down to 22 to remove decimal place to enable match
; - Therefore this would match de=22
ConvertTangentToRotation:
; Check - Angle of ~5 degrees
        or      a
        ld      hl, de
        ld      bc, 22                  ; Tangent 0.0859375 * 256 = 22 (8.8 format)
        sbc     hl, bc
        jp      c, .A0Degrees           ; Jump if hl < 22

; Check - Inverse tangent of ~10 degrees
        or      a
        ld      hl, de
        ld      bc, 45                  ; Tangent 0.17578125 * 256 = 45 (8.8 format)
        sbc     hl, bc
        jp      c, .A5Degrees           ; Jump if hl < 45

; Check - Inverse tangent of ~15 degrees
        or      a
        ld      hl, de
        ld      bc, 69                  ; Tangent 0.265625 * 256 = 69 (8.8 format)
        sbc     hl, bc
        jp      c, .A10Degrees          ; Jump if hl < 69

; Check - Inverse tangent of ~20 degrees
        or      a
        ld      hl, de
        ld      bc, 93                  ; Tangent 0.36328125 * 256 = 93 (8.8 format)
        sbc     hl, bc
        jp      c, .A15Degrees          ; Jump if hl < 93

; Check - Inverse tangent of ~25 degrees
        or      a
        ld      hl, de
        ld      bc, 119                 ; Tangent 0.46484375 * 256 = 119 (8.8 format)
        sbc     hl, bc
        jp      c, .A20Degrees          ; Jump if hl < 119

; Check - Inverse tangent of ~30 degrees
        or      a
        ld      hl, de
        ld      bc, 148                 ; Tangent 0.578125 * 256 = 148 (8.8 format)
        sbc     hl, bc
        jp      c, .A25Degrees          ; Jump if hl < 148

; Check - Inverse tangent of ~35 degrees
        or      a
        ld      hl, de
        ld      bc, 179                 ; Tangent 0.69921875 * 256 = 179 (8.8 format)
        sbc     hl, bc
        jp      c, .A30Degrees          ; Jump if hl < 179

; Check - Inverse tangent of ~40 degrees
        or      a
        ld      hl, de
        ld      bc, 215                 ; Tangent 0.83984375 * 256 = 215 (8.8 format)
        sbc     hl, bc
        jp      c, .A35Degrees          ; Jump if hl < 215

; Check - Inverse tangent of ~45 degrees
        or      a
        ld      hl, de
        ld      bc, 256                 ; Tangent 1 * 256 = 256 (8.8 format)
        sbc     hl, bc
        jp      c, .A40Degrees          ; Jump if hl < 256

; Check for inverse tangent of ~50 degrees
        or      a
        ld      hl, de
        ld      bc, 305                 ; Tangent 1.19140625 * 256 = 305 (8.8 format)
        sbc     hl, bc
        jp      c, .A45Degrees          ; Jump if hl < 305

; Check - Inverse tangent of ~55 degrees
        or      a
        ld      hl, de
        ld      bc, 366                 ; Tangent 1.4296875 * 256 = 366 (8.8 format)
        sbc     hl, bc
        jp      c, .A50Degrees          ; Jump if hl < 366

; Check - Inverse tangent of ~60 degrees
        or      a
        ld      hl, de
        ld      bc, 443                 ; Tangent 1.73046875 * 256 = 443 (8.8 format)
        sbc     hl, bc
        jp      c, .A55Degrees          ; Jump if hl < 443

; Check for inverse tangent of ~65 degrees
        or      a
        ld      hl, de
        ld      bc, 549                 ; Tangent 2.14453125 * 256 = 549 (8.8 format)
        sbc     hl, bc
        jp      c, .A60Degrees          ; Jump if hl < 549

; Check for inverse tangent of ~70 degrees
        or      a
        ld      hl, de
        ld      bc, 703                 ; Tangent 2.74609375 * 256 = 703 (8.8 format)
        sbc     hl, bc
        jp      c, .A65Degrees          ; Jump if hl < 703

; Check for inverse tangent of ~75 degrees
        or      a
        ld      hl, de
        ld      bc, 955                 ; Tangent 3.73046875 * 256 = 955 (8.8 format)
        sbc     hl, bc
        jp      c, .A70Degrees          ; Jump if hl < 955

; Check - Inverse tangent of ~80 degrees
        or      a
        ld      hl, de
        ld      bc, 1452                ; Tangent 5.671875 * 256 = 1452 (8.8 format)
        sbc     hl, bc
        jp      c, .A75Degrees          ; Jump if hl < 1452

; Check for inverse tangent of ~85 degrees
        or      a
        ld      hl, de
        ld      bc, 2926                ; Tangent 11.4296875 * 256 = 2926 (8.8 format)
        sbc     hl, bc
        jp      c, .A80Degrees          ; Jump if hl < 2926

; Check - Inverse tangent of ~89 degrees
        or      a
        ld      hl, de
        ld      bc, 14666               ; Tangent 57.2890625 * 256 = 14666 (8.8 format)
        sbc     hl, bc
        jp      c, .A85Degrees          ; Jump if hl < 14666

; ~90 Degrees
        ld      a, 64
        ret
        
.A0Degrees:
        ld      a, 0
        ret

.A5Degrees:
        ld      a, 4
        ret

.A10Degrees:
        ld      a, 7
        ret

.A15Degrees:
        ld      a, 11
        ret

.A20Degrees:
        ld      a, 14
        ret

.A25Degrees:
        ld      a, 18
        ret

.A30Degrees:
        ld      a, 21
        ret

.A35Degrees:
        ld      a, 25
        ret

.A40Degrees:
        ld      a, 28
        ret

.A45Degrees:
        ld      a, 32
        ret

.A50Degrees:
        ld      a, 36
        ret

.A55Degrees:
        ld      a, 39
        ret

.A60Degrees:
        ld      a, 43
        ret

.A65Degrees:
        ld      a, 46
        ret

.A70Degrees:
        ld      a, 50
        ret

.A75Degrees:
        ld      a, 53
        ret

.A80Degrees:
        ld      a, 57
        ret

.A85Degrees:
        ld      a, 60
        ret

/* 23/11/22 - Removed as no longer used
;-------------------------------------------------------------------------------------
; Fast Random Number Generator
; An 8-bit pseudo-random number generator,
; using a similar method to the Spectrum ROM,
; - without the overhead of the Spectrum ROM.
;
; R = random number seed
; an integer in the range [1, 256]
;
; R -> (33*R) mod 257
;
; S = R - 1
; an 8-bit unsigned integer
; Parameters:
; Seed
; Return:
; a = Random number
RandomNumber:
        ld a, (RandomNumberSeed)
        ld b, a 

        rrca ; multiply by 32
        rrca
        rrca
        xor 0x1f

        add a, b
        sbc a, 255 ; carry

        ld (RandomNumberSeed), a
        
        ret

;Inputs:
;     DE,BC are 8.8 Fixed Point numbers
;Outputs:
;     DE is the 8.8 Fixed Point result (rounded to the least significant bit)

*/

/* 21/06/23 - Not Used
;-------------------------------------------------------------------------------------
; Divide a by 10
; Parameters:
; a = Number to divide by 10
; Return:
; a = Quotient
a_div_10:
;returns result in H
        ld      d, 0
        ld      e, a
        ld      hl, de

        sla     hl              ; Running total x 2
        add     hl, de          ; Running total + number
        sla     hl              ; Running total x 2
        sla     hl              ; Running total x 2
        add     hl, de          ; Running total + number
        sla     hl              ; Running total x 2

        ld      a, h

        ret
*/
EndofMathsCode: