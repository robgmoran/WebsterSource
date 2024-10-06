HUDCode:
;-------------------------------------------------------------------------------------
; Convert integer to string - Used to update 2 or 3 x digit text only
; NOTE: Converts to 4bit Sprite String reference
; Ref: http://map.grauw.nl/sources/external/z80bits.html
; Params:
; a = Integer
; b = Number of digits (1, 2 or 3)
; de = Memory to store string
ConvertIntToString:
        ld      h, 0
        ld      l, a

        ld      a, b
        cp      2
        jp      z, .Tens                ; Jump if 2 x digits

        cp      3
        jp      z, .Hundreds            ; Jump if 3 x digits

; - Single digit
        or      a                       ; Clear carry flag
        ld      a, l
        rr      a                       ; Rotate into carry flag
        jp      c, .OddValue

; -- Even Value
        add     HUDSpriteDigit0Pattern  ; Add base value for even digits
        jp      .Cont

; -- Odd Value
.OddValue:
        add     HUDSpriteDigit1Pattern  ; Add base value for odd digits
        jp      .Cont

	;ld	bc,-10000
	;call	Num1
	;ld	bc,-1000
	;call	Num1
.Hundreds:
	ld	bc,-100
	call	.Num1
.Tens:
        ld      b, $ff
        ld	c,-10
	call	.Num1
	ld	c,b

.Num1	ld	a,'0'-1
.Num2	inc	a
	add	hl,bc
	jr	c,.Num2
	sbc	hl,bc

        sub     48                      ; Subtract ASCII value of character 0 i.e. Convert number to offset starting at 0

        bit     0, a            
        jp      nz, .OddNumber          ; Jump if value odd

; -- Even Value
; --- Routine used for different sprite sheet so need to check/add correct offsets
        push    af

        ld      a, (GameStatus2)
        bit     1, a
        jp      nz, .TitleEven

        pop     af

        sra     a                               ; Divide by 2 to get offset
        add     HUDSpriteDigit0Pattern          ; Add base value for even digits

        jp      .Cont

.TitleEven:
        pop     af

        sra     a                               ; Divide by 2 to get offset
        add     TitleHUDSpriteDigit0Pattern     ; Add base value for even digits

        jp      .Cont

; -- Odd Value
.OddNumber:
; --- Routine used for different sprite sheet so need to check/add correct offsets
        push    af

        ld      a, (GameStatus2)
        bit     1, a
        jp      nz, .TitleOdd

        pop     af

        sra     a                               ; Divide by 2 to get offset
        add     HUDSpriteDigit1Pattern          ; Add base value for odd digits

        jp      .Cont

.TitleOdd:
        pop     af

        sra     a                               ; Divide by 2 to get offset
        add     TitleHUDSpriteDigit1Pattern     ; Add base value for even digits

.Cont:
	ld	(de),a
	inc	de

	ret

;-------------------------------------------------------------------------------------
; Convert integer to string - Used to update 2 or 3 x digit text only
; Note: Converts to ASCII string reference
; Ref: http://map.grauw.nl/sources/external/z80bits.html
; Params:
; a = Integer
; b = Number of digits (2 or 3)
; de = Memory to store string - 2 x digits followed by 0
ConvertIntToString2:
        ld      h, 0
        ld      l, a

        ld      a, b
        cp      2
        jp      z, .Tens

	;ld	bc,-10000
	;call	Num1
	;ld	bc,-1000
	;call	Num1
.Hundreds:
	ld	bc,-100
	call	.Num1
.Tens:
        ld      b, $ff
        ld	c,-10
	call	.Num1
	ld	c,b

.Num1	ld	a,'0'-1
.Num2	inc	a
	add	hl,bc
	jr	c,.Num2
	sbc	hl,bc

	ld	(de),a
	inc	de

	ret

;-------------------------------------------------------------------------------------
; Update Score
; Params:
; iy = Length of points and points to add e.g. 3, "100"
UpdateScore:
        ld      b, (iy)         ; Get points length
        inc     iy              ; Point to points value

.UpdateLoop:
        ld      a, ScoreLength
        sub     b
        ld      hl, Score
        add     hl, a           ; Score starting pointer offset
        
.ScoreLoop:
        ld      a, (iy)         ; Get points digit
        cp      48
        jr      z, .ContinueLoop        ; Jump if digit 0

        sub     48              ; Subtract "0" to convert to digit              
        ld      d, b            ; Save register
        ld      b, a            ; Value to add to score
        call    .UpdateTextValue

        ld      b, d            ; Restore register

.ContinueLoop:
        inc     hl              ; Increment score pointer
        inc     iy              ; Increment points pointer
        djnz    .UpdateLoop

; Update HUD
        ld      b, HUDScoreValueDigits
        ld      a, (HUDScoreValueSpriteNum)
        ld      c, a
        ld      de, Score                               ; Convert string
        call    UpdateHUDValueSprites                      

        push    ix, iy
        call    CheckHiScore
        pop     iy, ix

        ret

.UpdateTextValue:
        ld a,(hl)           ; current value of digit.

        add a,b             ; add points to this digit.
        ld (hl),a           ; place new digit back in string.
        cp 58               ; more than ASCII value '9'?
        ret c               ; no - relax.
        sub 10              ; subtract 10.
        ld (hl),a           ; put new character back in string.
.uval0:
        dec hl              ; previous character in string.
        inc (hl)            ; up this by one.
        ld a,(hl)           ; what's the new value?

        cp 58               ; gone past ASCII nine?
        ret c               ; no, scoring done.
        sub 10              ; down by ten.
        ld (hl),a           ; put it back
        jp .uval0           ; go round again.



;-------------------------------------------------------------------------------------
; Check for new Hiscore
; Params:
CheckHiScore:
; Check whether the score is already the HiScore
        ld      a, (GameStatus3)
        bit     7, a
        jp      nz, .BypassSound        ; Jump if score already HiScore

        ld      ix, Score
        ld      iy, HiScore

        ld      b, ScoreLength
.DigitLoop:
        ld      a, (ix)
        ld      d, (iy)
        cp      d
        ret     c                       ; Return if HiScore digit > Score digit

        jr      nz, .NewHiScore         ; Jump if HiScore digit != Score Digit

.NextDigit:
        inc     ix                      ; Point to next score digit
        inc     iy                      ; Point to next Hiscore digit
        djnz    .DigitLoop

        ret

; Copy new score to Hiscore
.NewHiScore:
        ;ld      a, AyFXHighScoreChA
        ;call    AFX1Play
        ;ld      a, AyFXHighScoreChB
        ;call    AFX3Play

.BypassSound:
        ld      hl, Score
        ld      de, HiScore
        ld      b, 0
        ld      c, ScoreLength
        ldir

; Update HUD
        ld      b, HUDHiScoreValueDigits
        ld      a, (HUDHiScoreValueSpriteNum)
        ld      c, a
        ld      de, HiScore                             ; Convert string
        call    UpdateHUDValueSprites                      

        ld      a, (GameStatus3)
        set     7, a
        ld      (GameStatus3), a                        ; Set HiScore flag

        ret

;-------------------------------------------------------------------------------------
; Convert string to sprite string - Game
; Note: Converts string of ascii values to sprite pattern values
; Params:
; de = Address containing value (string)
; - Convert string to sprite string
ConvertStringToSpriteString:
        ld      ix, SpriteString        ; Destination            
.ConvertStringLoop:
        ld      a, (de)                 ; Get string value to convert
        sub     48                      ; Convert to actual value
        rr      a                       ; Rotate into carry flag
        jp      c,.OddValue             ; Jump if odd value
        
        add     HUDSpriteDigit0Pattern  ; Even Value -- Convert to sprite value
        jp      .UpdateSpriteString

.OddValue:
        add     HUDSpriteDigit1Pattern  ; Odd Value -- Convert to sprite value

.UpdateSpriteString:
        ld      (ix), a                 ; Save sprite value to SpriteString

        inc     de                      ; Point to next source
        inc     ix                      ; Point to next target

        djnz    .ConvertStringLoop

        ret

/*
;-------------------------------------------------------------------------------------
; Convert integer to string - Used to update 2 x digit text only
; Ref: https://chuntey.wordpress.com/tag/z80-assembly/
; Params:
; hl = Number
ConvertNumberToASCII: 

        ld      a, 48           ; leading zeroes (or spaces).
       ;ld de,10000         ; ten thousands column.
       ;call shwdg          ; show digit.
       ;ld de,1000          ; thousands column.
       ;call shwdg          ; show digit.
       ;ld de,100           ; hundreds column.
       ;call shwdg          ; show digit.
        ld      de,10           ; tens column.
        call    Convertdg       ; show digit.
        or      16              ; last digit is always shown.
        ld      de,1            ; units column.
Convertdg:  
        and     48              ; clear carry, clear digit.
Convertdg1:
        sbc     hl,de           ; subtract from column.
        jr      c,Convertdg0    ; nothing to show.
        or      16              ; something to show, make it a digit.
        inc     a               ; increment digit.
        jr      Convertdg1      ; repeat until column is zero.
Convertdg0:
        add     hl,de           ; restore total.
; a = Converted ASCII value 


       ;push af
       ;pop af

        ret
*/
EndofHUDCode: