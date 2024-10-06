SetupCode:
SetCommonLayerSettings:
; *** Setup Sprite Behavior and Layer Priority ***
; SPRITE AND LAYERS SYSTEM REGISTER
; - LowRes off
; - Sprite rendering flipped i.e. Sprite 0 (Player) on top of other sprites
; - Sprite clipping in over border mode enabled
; - Layer Priority - SUL (Top - Sprites, Enhanced_ULA, Layer 2)
; - Sprites visible and displayed in border
        nextreg $15, %0'1'1'010'1'1

; *** Configure Layer 2 and ULA Transparency Colour
; GLOBAL TRANSPARENCY Register
        nextreg $14,$00         ; Transparency Colour - Ensure palettes are configured correctly

        ret

;-------------------------------------------------------------------------------------
; Setup environment for title screen
; Parameters:
; Return:
TitleScreenSetup:
.ReDisplay:
; Obtain memory bank number currently mapped into slot 2 & 4 and save allowing restoration
; - MMU2 - $4000-$5fff
	ld      a,$52                           ; Port to access - Memory Slot 2
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
	ld      (BackupByte6), a                 ; Save current bank number in slot 2

; - MMU4 - $8000 - $9fff
	ld      a,$54                           ; Port to access - Memory Slot 4
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
	ld      (BackupByte7), a                ; Save current bank number in slot 4

; Map Title routines into slot 2
	ld      a, $$TitleScreen                
	nextreg $52, a                          ; Swap memory bank

; Map Title NextDAW memory bank into slot 4
	ld      a, $$NextDAWPlayer                
	nextreg $54, a                          ; Swap memory bank

; Set NextDAW run flag
	ld		a, (GameStatus3)
	set		2, a
	ld		(GameStatus3), a

; Display Title screen
    	call    TitleScreen

; Title Screen exited
; - Reset NextDAW run flag - Required to stop NextDAW as MMU4 being swapped out
	ld	a, (GameStatus3)
	res	2, a
	ld	(GameStatus3), a

; - Swap original memory bank back into slot 2
	ld      a, (BackupByte6)                 ; Restore original memory bank
	nextreg $52, a                          ; Swap memory bank

; - Swap original memory bank back into slot 4
	ld      a, (BackupByte7)                ; Restore original memory bank
	nextreg $54, a                          ; Swap memory bank

; Start new game
        call    StartNewGame

; Check whether quit was selected from level screen
        ld      a, (GameStatus2)
        bit     1, a
        jp      nz, .ReDisplay                  ; Jump if quit selected

        ret

EndofSetupCode: