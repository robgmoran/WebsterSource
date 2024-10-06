
;-------------------------------------------------------------------------------------
; Configure Layer2 settings
; Parameters:
Layer2Setup:
; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      

; *** Configure Layer 2 Memory Bank ***
;  LAYER 2 RAM PAGE REGISTER
; - References 16kb memory banks
; - Note: Avoid using banks 5 and 7 for Layer 2
        nextreg $12, L2Start_16_Bank 

; *** Setup Layer 2 Resolution
; LAYER 2 CONTROL REGISTER
; - Layer 2 screen resolution - 320 x 256 x8bpp - L2 palette offset +0
        nextreg $70, %00'01'0000        

; *** Reset Layer 2 Clip Window
; CLIP WINDOW LAYER 2 REGISTERS
; Set to 0 as separate open/close routines control size
       nextreg $1c, %0000'0'0'0'1       ; Clip window to set - Reset Layer 2
       nextreg $18, 0;8                 ; Write to Index 0 - X1 Position
       nextreg $18, 0;160-8-1           ; Write to Index 1 - X2 Position
       nextreg $18, 0;16                ; Write to Index 2 - Y1 Position
       nextreg $18, 0;256-16-1          ; Write to Index 3 - Y2 Position

; *** Reset Scrolling Offset Registers ***
; LAYER 2 X OFFSET REGISTER
        ld      a, L2ScrollOffsetX
        nextreg $16, a 
; LAYER 2 X OFFSET MSB REGISTER
        nextreg $71, %0000000'0
; LAYER 2 Y OFFSET REGISTER
        ld      a, L2ScrollOffsetY
        nextreg $17, a

	ld      hl, $0000
        ld      (L2ScrollXValue), hl    ; Clear both x and y values

        ret

;-------------------------------------------------------------------------------------
; Clear Layer2 8kb Memory Banks
; Parameters:
; a = Starting 8kb Memory Bank
; b = Number of memory banks (256 x 192 = 6 8kb memory banks, 320 x 256 = 10 x memory banks)
; Return:
Layer2Clear:
        push    af, bc

; Obtain memory bank number currently mapped into slot 4; required to be restored later
	ld      a,$54                           ; Port to access - Memory Slot 4
        ld      bc,$243B                        ; TBBlue Register Select
        out     (c),a                           ; Select NextReg $1F

        inc     b                               ; TBBlue Register Access
        in      a, (c)
        ld      (BackupByte), a                 ; Save current bank number in slot 4

        pop     bc, af

.L2MemoryBankLoop:
        push    bc

	nextreg $54, a                          ; Swap memory bank into slot 4 - $8000

; Clear 8kb Memory Bank        
        ld      hl, $8000
        ld      (hl), 0                                 ; Clear source byte
        ld      (DMAMemoryBankUploadPortA), hl          ; DMA Source

        inc     hl
        ld      (DMAMemoryBankUploadPortB), hl          ; DMA Destination

        LD      hl, DMAMemoryBankClear                  ; HL = pointer to DMA program
        ld      b, DMAMemoryBankClearSize
        LD      c, $6B                                  ; C = $6B (zxnDMA port)
        OTIR                                            ; upload DMA program
        
        inc     a                               ; Point to next memory bank

        pop     bc

        djnz    .L2MemoryBankLoop               ; Loop until all memory banks have been cleared

; Restore original memory bank hosted in slot 6
        ld      a, (BackupByte)
        nextreg $54, a                          ; Restore memory bank into slot 3 - $8000

        ret

;-------------------------------------------------------------------------------------
; Write data to Layer 2 Memory - 320 x 256 (10 x memory banks)
; Parameters:
; ix = L2 Data
; a = Width size
; b = Height size
; de = X position
; -Note: Results in de = -------b|bbbxxxxx {where b = bank offset, x = x}
; l = Y position
; Return:
Layer2_320_Write:
	push    af, bc

; Obtain memory bank number currently mapped into slot 4 and save allowing restoration
	ld      a,$54                           ; Port to access - Memory Slot 4
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
	ld      (BackupByte), a                 ; Save current bank number in slot 4

; Obtain x/y coordinates and memory bank
; Start:
;       de = -------b|bbbxxxxx {where b = bank offset, x = x}
;       l  = yyyyyyyy
; Result:
;       d  = xxxxxxxx, e = yyyyyyyy ---> offset into memory bank
;       BackupByte2 = memory bank

	ld	b, 3
	bsla	de, b		        ; d=memory bank

	ld	a, d
	ld	(BackupByte2), a        ; Save Memory Bank
		
        bsra    de, b
	ld	a, e

	and 	%00011111	        
        ld      d, a                    ; d=x coordinate

	ld	a, l
	ld	e, a		        ; e=y coordinate

; Save values
        pop     bc			; Restore height

	ld	a, b
        ld      (BackupByte3), a	; Save height size
	
; Calculate memory bank number and swap in
	ld      a, (BackupByte2)	        ; Restore memory bank offset
	add     a, L2Start_8_Bank               ; A=bank number to swap in (start bank + bank offset)
	nextreg $54, a                          ; Swap memory bank

	pop	af		        ; Restore width

	ld	b, a

        ;ld      ix, (LevelDataL2Data)
; Process width
.NextX:
	push	bc		                ; Save width

; - Check whether we need to change memory bank (32 columns/bank)
	ld	a, d		                ; Obtain x
	cp	32
	jp	nz, .DoNotUpdateMemoryBank      ; Jump if no bank change required

	ld	d, 0		                ; Otherwise reset x as offset into new memory bank

	ld	a, (BackupByte2)	        ; Restore memory bank offset
	inc	a                               ; Point to next memory bank offset
	ld	(BackupByte2), a	        ; Save memory bank

; - Calculate memory bank number and swap in
	add     a, L2Start_8_Bank               ; A=bank number to swap in (start bank + bank offset)
	nextreg $54, a                          ; Swap memory bank

.DoNotUpdateMemoryBank:
; - Convert DE (xy) to screen memory location starting at $6000
	push    de                      ; Save memory bank offset (xy)

	ld      a, d                    ; Copy current X to A
	or      $80                     ; Screen starts at $8000
	ld      d, a                    ; D=high byte for $8000 screen memory

; Process height
        ld      a, (BackupByte3)        ; Restore height
        ld      b, a 

.NextY:
	ld      a, (ix)                 ; A=source data
	ld      (de), a                 ; Write X into corresponding memory
	inc     e                       ; Increment y position
        inc     ix                      ; Increment source data position
	djnz    .NextY

; Check/update columns
	pop     de                      ; Restore memory bank offset (xy)
	inc     d                       ; Increment to next column (x) i.e. Add 256 to memory reference

	pop	bc			; Restore width
        djnz    .NextX                  ; Jump if we need to process more columns

; Restore original memory bank hosted in slot 3
        ld      a, (BackupByte)
	nextreg $54, a                  ; Restore memory bank into slot 3 - $6000

        ret

;-------------------------------------------------------------------------------------
; Setup Layer2 based on Level Data - 320 x 256 (10 x memory banks)
; Parameters:
; - a = Memory bank containing level data
Layer2SetupLevel:
        push    af

; Perform common activities 
; - Clear L2 memory banks
        ld      a, L2Start_8_Bank       ; Starting 8kb memory bank
        ld      b, L2NUM_BANKS          ; Number of 8kb memory banks hosting L2 data to clear
        call    Layer2Clear

; - Configure L2 settings
        call    Layer2Setup

        pop     af

; Perform level specific activities
; -Map memory banks
; -- MMU Slot 3 ($6000) - Level data memory bank
; -- MMU Slot 4 ($8000) - L2 memory bank
        nextreg $53, a                          
        nextreg $54, L2Start_8_Bank

; - Configure L2 palette
        ld      hl, (LevelDataL2PaletteData)
        call    SetupLayer2Pal

; - Draw L2 graphics (based on 16 pixel blocks)
        ld      de, 0                   ; Start x position
        ld      l, 0                    ; Start y position
        ld      b, L2Width/16           ; Top/bottom 16 pixels hidden
.XLoop:
        push    bc, de, hl

        ld      b, L2Height/16          ; Left/Right 16 pixels hidden
.YLoop:
        push    bc, de

        ld      a, 16                   ; Block Width
        ld      b, 16                   ; Block Height
        ld      ix, (LevelDataL2Data)
        call    Layer2_320_Write

        pop     de, bc

        add     hl, 16                  ; Update y position
        djnz    .YLoop

        pop     hl, de, bc

        add     de, 16                   ; Update x position
        djnz    .XLoop

; Map ULA Memory banks 10/11 (8KB) to slots 3/4
        nextreg $53, 10
        nextreg $54, 11

        ret

;-------------------------------------------------------------------------------------
; Scroll Layer2 based on Tilemap scroll variable (Scrolled)
; Parameters:
Layer2Scroll:
; Check scroll delay counter
        ld      a, (L2ScrollDelayCounter)
        cp      L2ScrollDelay
        jp      z, .L2Scroll                    ; Jump if we should scroll

        inc     a
        ld      (L2ScrollDelayCounter), a       ; Otherwise update scroll delay counter

        ret

; Scroll Layer2
.L2Scroll:
        ld      a, (Scrolled)
        ld      b, a

        ld      a, (L2ScrollXValue)

; - Check/Update scroll - Based on Scrolled(---R) 
        rrc     b
        adc     a, 0                            ; Scroll in player movement direction
        ;sbc     a, 0                           ; Scroll in opposite player movement direction

; - Check/Update scroll - Based on Scrolled(--L-) 
        rrc     b
        sbc     a, 0                            ; Scroll in player movement direction
        ;adc     a, 0                           ; Scroll in opposite player movement direction

        ld      (L2ScrollXValue), a

        nextreg $71, 0
        nextreg $16, a

        ld      a, (L2ScrollYValue)

; - Check/Update scroll - Based on Scrolled(-D--) 
        rrc     b
        adc     a, 0                            ; Scroll in player movement direction
        ;sbc     a, 0                           ; Scroll in opposite player movement direction

; - Check/Update scroll - Based on Scrolled(U---) 
        rrc     b
        sbc     a, 0                            ; Scroll in player movement direction
        ;adc     a, 0                           ; Scroll in opposite player movement direction

        ld      (L2ScrollYValue), a

        nextreg $17, a

        ld      a, 0
        ld      (L2ScrollDelayCounter), a       ; Reset delay scroll counter

        ret

/* 04/11/23 - Not required as using 320 x 256 layer2
;-------------------------------------------------------------------------------------
; Write data to Layer 2 Memory
; Parameters:
; a = Horizontal size
; b = Vertical size
; de = Y/X position
; Note: Results in d = bbb'yyyyy = b = bank offset, y = y offset in bank
; Return:
Layer2_256_Write:
        push    af, bc

; Obtain memory bank number currently mapped into slot 3 and save allowing restoration
	ld      a,$53                           ; Port to access - Memory Slot 3
        ld      bc,$243B                        ; TBBlue Register Select
        out     (c),a                           ; Select NextReg $1F

        inc     b                               ; TBBlue Register Access
        in      a, (c)
        ld      (BackupByte), a                 ; Save current bank number in slot 7

        pop     bc, af

; Save values
        ld      (BackupByte2), a        ; Save horizontal size

; Process rows
.NextY:
        ld      a, b
        ld      (BackupByte3), a        ; Save vertical size

; Calculate memory bank number and swap in
	ld      a, d                    ; Copy current bbb'yyyyy to A
	and     %11100000               ; 32100000 (3MSB = bank number)
	rlca                            ; 21000003
	rlca                            ; 10000032
	rlca                            ; 00000321
	add     a, L2Start_8_Bank       ; A=bank number to swap in (start bank + bank offset)
	nextreg $53, a                  ; Swap bank

; Convert DE (yx) to screen memory location starting at $6000
	push    de                      ; (DE) will be changed to bank offset
	ld      a, d                    ; Copy current Y to A
	and     %00011111               ; Discard bank offset number
	or      $60                     ; Screen starts at $6000
	ld      d, a                    ; D=high byte for $6000 screen memory

        ld      a, (BackupByte2)        ; Restore horizonal size
        ld      b, a 

; Process columns
.NextX:
	ld      a, e                    ; A=current X
	ld      (de), a                 ; Write X into corresponding memory
	inc     e                       ; Increment x position
	djnz    .NextX

; Check/update rows
	pop     de                      ; Restore DE to coordinates
	inc     d                       ; Increment to next Y i.e. Add 256 to memory reference
								    ; Note: Also increments bank offset (bbb'-----)
								    ; every 32 line boundary

        ld      a, (BackupByte3)        ; Obtain row count   
        ld      b, a

        djnz    .NextY

; Restore original memory bank hosted in slot 3
        ld      a, (BackupByte)
	nextreg $53, a                  ; Restore memory bank into slot 3 - $6000

        ret
*/

/*
;-------------------------------------------------------------------------------------
; Write data to Layer 2 Memory - 320 x 256 (10 x memory banks)
; Note: Writes to all pixels but is NOT efficient i.e. runs loops too many times
; Parameters:
L2320Test:
START_16K_BANK  EQU 9
START_8K_BANK   EQU START_16K_BANK*2

RESOLUTION_X    EQU 320
RESOLUTION_Y    EQU 256

BANK_8K_SIZE    EQU 8192
NUM_BANKS       EQU RESOLUTION_X * RESOLUTION_Y / BANK_8K_SIZE
BANK_X          EQU BANK_8K_SIZE / RESOLUTION_Y

; Obtain memory bank number currently mapped into slot 3; required to be restored later
	ld      a,$53                           ; Port to access - Memory Slot 3
        ld      bc,$243B                        ; TBBlue Register Select
        out     (c),a                           ; Select NextReg $1F

        inc     b                               ; TBBlue Register Access
        in      a, (c)
        ld      (BackupByte), a                 ; Save current bank number in slot 7

        ; Enable Layer 2
	LD BC, $123B
	LD A, 2
	OUT (C), A

	; Setup starting Layer2 16K bank and swap corresponding 8K
	; memory bank into screen memory $C000 where L2 will read from
	NEXTREG $12, START_16K_BANK
	NEXTREG $70, %00010000    ; 320x256 256 colour mode

	; Setup window clip for 320x256 resolution
	NEXTREG $1C, 1            ; Reset Layer 2 clip window reg index
	NEXTREG $18, 0;16                                 ; Minus 16 pixels   
	NEXTREG $18, 159;(RESOLUTION_X - 16) / 2 - 1        ; Minus 16 pixels
	NEXTREG $18, 0;16                                 ; Minus 16 pixels
	NEXTREG $18, 255;(RESOLUTION_Y - 16) - 1            ; Minus 16 pixels

	LD B, START_8K_BANK       ; Bank number
	LD H, 10                   ; Colour

nextBank:
	; Swap to next bank, exit once all 5 are done
	LD A, B                   ; Copy current bank number to A
	NEXTREG $53, A            ; Switch to bank

	; Fill in current bank
	LD DE, $6000              ; Prepare starting address

nextY:
	; Fill in 256 pixels in memory bank
        ; - Maps to column within L2 display
	LD A, H                   ; Copy colour to A
	LD (DE), A                ; Write colour into memory
	INC E                     ; Increment Y
	JR NZ, nextY              ; Continue with next Y until we wrap to next X

	; Move to start of next 256 pixels in memory bank
        ; - Maps to next column within L2 display
	INC H                     ; Increment colour
	INC D                     ; Increment X
	LD A, D                   ; Copy X to A
	AND %00111111             ; Clear $60 to get pure X coordinate
	CP BANK_X                 ; Did we reach next bank?
	JP NZ, nextY              ; No, continue with next Y

	; Prepare for next bank
	INC B                     ; Increment to next bank
	LD A, B                   ; Copy bank to A
	CP START_8K_BANK+NUM_BANKS; Did we fill last bank?
	JP NZ, nextBank           ; No, proceed with next bank


; Restore original memory bank hosted in slot 3
        ld      a, (BackupByte)
	nextreg $53, a                  ; Restore memory bank into slot 3 - $6000

	RET
*/
EndofLayer2Code: