PalettesCode:
;-------------------------------------------------------------------------------------
; Tilemap Palette Setup
; Parameters:
; - a = Memory Bank (8kb) containing tilemap palette
; - hl = Address of tilemap palette data
; - b = Palette rows (row=16 colours)
SetupTileMapPalette:
; By default tilemap will use the default palette: color[i] = convert8bitColorTo9bit(i)
; which is set by the NEX loader in the first tilemap palette.
; This routine will change the tilemap palette to the specified tilemap palette

; *** Map Tilemap Palette Memory Bank ***
; MEMORY MANAGEMENT SLOT 3 BANK Register
; -  Map memory bank hosting Tilemap palette to slot 3
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank)
; This saves explicitly listing the bank, enabling the bank to be set once when uploading the palette data
        nextreg $53, a

; *** Select Tilemap Palette and Palette Index ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43,%0'011'0'0'0'1  ; Tilemap - First palette
; PALETTE INDEX REGISTER
        nextreg $40,0               ; Start with color index 0

; *** Copy Tilemap Palette Data
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
.SetPaletteLoopRows
        push    bc

        ld      b, 16                   ; 16 colours per row with 2 x writes per colour
.SetPaletteLoopColours:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        
        ld      a,(hl)
        nextreg $44,a
        inc     hl
        
        djnz    .SetPaletteLoopColours

        pop     bc

        djnz    .SetPaletteLoopRows

; *** Configure Tilemap Transparency
; TILEMAP TRANSPARENCY INDEX Register
        nextreg $4c, $00

        ret

;-------------------------------------------------------------------------------------
; Layer 2 Palette Setup
; Parameters:
; - hl = Address of layer 2 palette data
; - MMU 3 - Memory bank containing palette
SetupLayer2Pal:
; Setup first palette - Used for game
; ---
; *** Select Layer 2 Palette and Palette Index ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43,%0'001'0'0'0'1  ; Layer 2 - First palette
; PALETTE INDEX REGISTER
        nextreg $40,0               ; Start with color index 0

; *** Copy Layer 2 Palette Data
; Note: GFX2NEXT -PAL-STD PARAMETER not used
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
        push    hl                  ; Save L2 palette address

        ld      b,0                 ; 256 colors (loop counter)
.SetPaletteLoop1:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        ld      a,(hl)
        inc     hl
        nextreg $44,a
        djnz    .SetPaletteLoop1

; Setup second palette - Used for freeze
; ---
        nextreg $43,%0'101'0'1'0'1  ; Layer 2 - Second palette
        nextreg $40,0               ; Start with color index 0

        pop     hl                  ; Restore L2 palette address

        ld      b,0                 ; 256 colors (loop counter)
.SetPaletteLoop2:
        ld      a,(hl)
        and     %00000111           ; Mask out RRRGGG--
        inc     hl        
        nextreg $44,a
        ld      a,(hl)
        inc     hl
        nextreg $44,a
        djnz    .SetPaletteLoop2

        nextreg $43,%0'001'0'0'0'1  ; Layer 2 - Re-select first palette

        ret

;-------------------------------------------------------------------------------------
; Select TileMap Palette Offset
; Parameters:
; - a = Tilemap palette offset (0-15)
SelectTileMapPalOffset:
; Configure tilemap palette offset for level
; TILEMAP ATTRIBUTE Register
        ld      d, a
        ld      e, 16
        mul     d, e

        ld      a, %0000'0'0'0'0        ; Pal offset 0, no mirrorx, no mirrory, no rotate, tilemap ULA over (also needs to be set on register $6b)
        or      e                       ; Update pal offset
        nextreg $6c, a

        ret

;-------------------------------------------------------------------------------------
; Sprite Palette Setup
; Parameters:
; - a = Memory Bank (8kb) containing sprite palette
; - hl = Address of sprite palette data
SetupSpritePalette:
; By default sprites will use the default palette: color[i] = convert8bitColorTo9bit(i)
; which is set by the NEX loader in the first sprite palette.
; This routine will change the sprite palette to the specified sprite palette

; *** Map Sprite Palette Memory Bank ***
; MEMORY MANAGEMENT SLOT 3 BANK Register
; -  Map memory bank hosting SpritePalette to slot 3
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank)
; This saves explicitly listing the bank, enabling the bank to be set once when uploading the palette data
        nextreg $53, a

; *** Select Sprite Palette and Palette Index ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43,%0'010'0'0'0'1  ; Sprites - First palette
; PALETTE INDEX REGISTER
        nextreg $40,0               ; Start with color index 0

; *** Copy Sprite Palette Data
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
        ld      b,0                 ; 256 colors (loop counter)
.SetPaletteLoop:
        ld      a,(hl)
        inc     hl        
        nextreg $44,a
        ld      a,(hl)
        inc     hl
        nextreg $44,a
        djnz    .SetPaletteLoop

        nextreg $4b, 0                  ; Set sprite transparent colour to 0
        ret

;-------------------------------------------------------------------------------------
; Cycle Colour Palette; only cycles once
; Parameters:
; - a = End colour offset within palette - 0 - 255 - not offset within current tilemap palette
; - b = Number of palette entries to copy/cycle; does not include End colour (a) or first colour where end colour is copied too
; - d = Palette (value for next register $43)
CyclePalette:
        ld      c, a                    ; Backup original palette element

        push    bc

; - Obtain current register value
        ld      a, $43
        call    ReadNextReg

        and     %00000100               ; Obtain layer2 palette
        or      d                       ; Ensure layer2 palette not changed

        pop     bc 

; - Set new register value
; *** Select TileMap Palette ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43, a

.CycleLoop:
        ld      a, c                    ; Restore original palette element
        nextreg $40, a                  ; Select palette element

        ld      a, $41        
        call    ReadNextReg             ; Read palette element - RRRGGGBB
        ld      (BackupByte), a         ; Backup palette element to copy later

        ld      a, $44        
        call    ReadNextReg             ; Read palette element - -------B
        ld      (BackupByte2), a        ; Backup palette element to copy later

        ld      a, c                    ; Restore original palette element
        dec     a
        ld      d, a                    ; Destination palette element (end colour-1)

.CopyColours:
        ld      a, d
        nextreg $40, a                  ; Select source palette element

        ld      a, $41        
        call    ReadNextReg             ; Read source palette element - RRRGGGBB
        push    af                      ; Backup source value

        ld      a, $44        
        call    ReadNextReg             ; Read palette element - -------B
        ld      (BackupByte3), a        ; Backup palette element to copy later

        inc     d                       ; Point to destination palette element (source+1)
        ld      a, d
        nextreg $40, a                  ; Select destination palette element

        pop     af                      ; Restore source value
        nextreg $44, a                  ; Write destination palette element - RRRGGGBB

        ld      a, (BackupByte3)
        nextreg $44, a                  ; Write destination palette element - -------B

        dec     d                       ; Point to next source palette element
        dec     d
        djnz    .CopyColours

; Copy last colour
        inc     d                       ; Point to final colour element
        ld      a, d
        nextreg $40, a                  ; Select palette element

        ld      a, (BackupByte)         ; Restore last colour to first colour
        nextreg $44, a                  ; Write destination palette element - RRRGGGBB

        ld      a, (BackupByte2)
        nextreg $44, a                  ; Write destination palette element - -------B

        ret

;-------------------------------------------------------------------------------------
; Cycle Colour Palette with delay
; Parameters:
; - BackupByte4 - Frame delay between complete cycles
; - BackupByte5 - Colours for complete cycle 
; - BackupByte6 - Frame delay within complete cycle
CyclePaletteWithDelay:
; - Cycle sprite palette
        ld      a, (BackupByte4)
        cp      0
        jp      z, .CheckCycleColours

        dec     a
        ld      (BackupByte4), a
        jp      .BypassSpriteCycle

.CheckCycleColours
        ld      a, (BackupByte5)
        cp      0
        jp      z, .CycleComplete       ; Jump if all colours cycled within a complete cycle

        ld      a, (BackupByte6)
        cp      0
        jp      nz, .Cont               ; Jump if all cycle delay frames haven't been played

        ld      a, 8
        ld      b, LevelIntroCycleColours-1
        ld      d, %1'010'0'0'0'1       ; Sprite first palette 
        call    CyclePalette            ; Otherwise cycle colours

        ld      a, (BackupByte5)
        dec     a                      
        ld      (BackupByte5), a        ; Decrement colours for complete cycle

        ld      a, LevelIntroCycleDelayBetweenFrames+1
.Cont:
        dec     a
        ld      (BackupByte6), a        ; Decrement frame delay within complete cycle

        jp      .BypassSpriteCycle

.CycleComplete:
        ld      a, LevelIntroCycleDelayBetweenCycles
        ld      (BackupByte4), a                        ; Reset frame delay between complete cycles
        ld      a, LevelIntroCycleColours           
        ld      (BackupByte5), a                        ; Reset colours for complete cycle
        ld      a, LevelIntroCycleDelayBetweenFrames
        ld      (BackupByte6), a                        ; Reset frame delay within complete cycle

.BypassSpriteCycle:
/*
; Cycle TileMap Colours
        ld      a, (CycleTMColourDelayCounter)
        cp      0
        jp      nz, .UpdateCycleTMCounter

        ld      a, (DoorLockdownPalCycleOffset)
        ld      b, 1                            ; Number of colours to cycle-1
        ld      d, %1'011'0'0'0'1               ; Tilemap first palette
        call    CyclePalette

        ld      a, CycleTMColourDelay+1

.UpdateCycleTMCounter:
        dec     a
        ld      (CycleTMColourDelayCounter), a
*/
        ret

;-------------------------------------------------------------------------------------
; Fade out palette
; - Supports 256 colours in palette
; Parameters:
; a = Number of fade updates (7 = Fade all colours to black)
; Note: Each colour consists of 3 bits. Therefore it would take 7 updates to go from RRR to ---
; Note: Setting a > 7 will provide a delay post-fade
; b = Palette reference
FadeOutPalette:
        push    af                      ; Save fade updates

; Select palette
        ld      a, b                    ; Select tilemap palette
        nextreg $43, a

/* - No longer required as 256 colours will be faded in palette
; Tilemap - Identify palette offset i.e. 0, 16, 32...
	ld      a, $6c                  ; register 
	ld      bc, $243B               ; port $243B
	out     (c), a                  ; set port

	inc     b                       ; port $253B
	in      a, (c)                  ; read to A

        swapnib
        and     %00001111

        ld      d, a
        ld      e, 16
        mul     d, e

        ld      a, e
        ld      (BackupByte), a         ; Palette offset

*/
        ld      a, 0                    ; Starting palette index number
        ld      b, 0                    ; 256 colours
        call    FadeReadColours

; Fade Palette Colours
        pop     af                      ; Restore fade updates

        ld      b, a                    ; Loop - x times for all palette colours
.ColourBitLoop:
        push    bc

        ld      ix, Queue

        ld      b, 0                    ; Loop - 256 colours in table
.TableLoop:
        push    bc
        
; Red
        ld      a, (ix)
        and     %11100000
        cp      0
        jp      z, .CheckGreen   ; Jump if Red = 000

        ld      a, (ix)
        sub     %00100000       ; Decrement Red
        ld      (ix), a

; Green
.CheckGreen:
        ld      a, (ix)
        and     %00011100
        cp      0
        jp      z, .CheckBlue   ; Jump if Green = 000

        ld      a, (ix)
        sub     %00000100       ; Decrement Green
        ld      (ix), a

; Blue
.CheckBlue:
        ld      a, (ix+1)
        rr      a               ; Bit 0 copied to carry

        ld      a, (ix)
        rl      a               ; Bit 0 copied from carry; Bit 7 copied to carry

        push    af              ; Save value + flags

        and     %00000111       
        cp      0
        jp      z, .BypassBlue  ; Jump if Blue = 000

        pop     af              ; Restore value + flags

        dec     a               ; Decrement Blue

        rr      a               ; Bit 7 copied from carry; Bit 0 copied to carry

        ld      (ix), a

        ld      a, 0
        rl      a               ; Bit 0 copied from carry

        ld      (ix+1), a

        jp      .ContLoop

.BypassBlue:
        pop     af              

.ContLoop:
        inc     ix
        inc     ix              ; Point to next colour in table

        pop     bc

        djnz    .TableLoop

        ld      b, LevelFadeOutFrameDelay
.DelayLoop:
        halt

        djnz    .DelayLoop

; Write updated palette
        ld      a, 0                    ; Starting palette index number
        ld      b, 0                    ; 256 colours
        call    FadeWriteColours

        pop     bc

        djnz    .ColourBitLoop

        ret

;-------------------------------------------------------------------------------------
; Fade - Read and store palette colours
; Parameters:
; a = Palette offset i.e. 0, 16, 32...
; b = Number of colours
; Return:
; Queue = Palette colours read
FadeReadColours:
        ld      ix, Queue

; Read - Loop between colours - Low --> High
.ReadLoop:
        push    af                      ; Save palette element reference

        nextreg $40, a                  ; Select source palette element

        ld      a, $41        
        call    ReadNextReg             ; Read source palette element - RRRGGGBB
        ld      (ix), a
        
        inc     ix

        ld      a, $44        
        call    ReadNextReg             ; Read palette element - -------B
        ld      (ix), a        

        inc     ix

        pop     af                      ; Restore palette element reference
        
        inc     a                       ; Point to next palette element

        djnz    .ReadLoop

        ret

;-------------------------------------------------------------------------------------
; Fade - Write palette colours
; Parameters:
; a = Palette offset i.e. 0, 16, 32...
; b = Number of colours
FadeWriteColours:
        ld      ix, Queue

        nextreg $40, a                  ; Select source palette element - Auto-increment enabled

; Write - Loop between colours Low --> High
.WriteLoop:
        ld      a, (ix)
        nextreg $44, a                  ; Write destination palette element - RRRGGGBB

        inc     ix
        ld      a, (ix)
        nextreg $44, a                  ; Write destination palette element - -------B

        inc     ix

        djnz    .WriteLoop

        ret

;-------------------------------------------------------------------------------------
; Fade in palette
; - Supports 16 colours in palette
; Parameters:
; a = Number of fade updates (7 = Fade all colours in)
; Note: Each colour consists of 3 bits. Therefore it would take 7 updates to go from --- to RRR
; Note: Setting a > 7 will provide a delay post-fade
; b = Palette reference e.g. Sprite...
; c = Palette index number i.e. Required colours (target colours)
; Note: Working index number is 0 i.e. Colours that start at 0 (black)
FadeInPalette:
        push    af                      ; Save fade-in update value

; Select palette
        ld      a, b                    ; Select palette
        nextreg $43, a

; Save palette
        ld      a, c                    ; Starting palette index number
        ld      b, 16                   ; 16 colours
        call    FadeReadColours

; Copy/Update saved colours
; - 0 - 31 = Working colours i.e. Colours that will be increased to target colours
; - 32 - 63 = Target colours i.e. Colours saved from palette
        ld      ix, Queue
        
        ld      b, 16*2                 ; 16 colours = 32 bytes
.CopyPaletteColours:
        ld      a, (ix)                 
        ld      (ix+32), a              ; Save copy of colour

        ld      (ix), 0                 ; Reset colour

        inc     ix                      ; Point to next colour

        djnz    .CopyPaletteColours

        pop     af                      ; Restore fade-in update value

        ld      b, a                    ; Loop - x times for all palette colours
.ColourBitLoop:
        push    bc

        ld      ix, Queue

        ld      b, 16                    ; Loop - 16 colours in table
.TableLoop:
        push    bc
; Red
        ld      a, (ix+32)
        and     %11100000
        ld      b, a                    ; Target value
        
        ld      a, (ix) 
        ld      c, a                    ; Save value
        and     %11100000               ; Working value

        cp      b
        jp      z, .CheckGreen          ; Jump if working = target value

        ld      a, c                    ; Restore value
        add     %00100000
        ld      (ix), a                 ; Save new working value

.CheckGreen:
; Green
        ld      a, (ix+32)
        and     %00011100
        ld      b, a                    ; Target value

        ld      a, (ix) 
        ld      c, a                    ; Save value
        and     %00011100               ; Working value

        cp      b
        jp      z, .CheckBlue           ; Jump if working = target value

        ld      a, c                    ; Restore value
        add     %00000100
        ld      (ix), a                 ; Save new working value

.CheckBlue:
; Blue
; - Working value
        ld      a, (ix+1)
        rr      a               ; Bit 0 copied to carry

        ld      a, (ix)
        rl      a               ; Bit 0 copied from carry; Bit 7 copied to carry

        push    af              ; Save RRGGBBB + flags (R)

        and     %00000111       

        push    af              ; Save -----BBB value

; - Target value
        ld      a, (ix+33)
        rr      a               ; Bit 0 copied to carry

        ld      a, (ix+32)
        rl      a               ; Bit 0 copied from carry; Bit 7 copied to carry

        and     %00000111       
        ld      b, a

        pop     af              ; Restore working value -----BBB value

        cp      b
        jp      z, .BypassBlue

        pop     af              ; Restore working value RRGGGBBB value
        inc     a

        rr      a               ; Bit 7 copied from carry; Bit 0 copied to carry

        ld      (ix), a

        ld      a, 0
        rl      a               ; Bit 0 copied from carry

        ld      (ix+1), a

        jp      .ContLoop

.BypassBlue:
        pop     af

.ContLoop:
        inc     ix
        inc     ix              ; Point to next colour in table

        pop     bc

        djnz    .TableLoop

        ld      b, LevelFadeInFrameDelay
.DelayLoop:
; -- Wait for vertical sync to ensure colours fade correctly
        halt

        djnz    .DelayLoop

; Write updated palette
        ld      a, 0                   ; Starting palette index number
        ld      b, 16                   ; 16 colours
        call    FadeWriteColours

        pop     bc

        dec     b
        ld      a, b
        cp      0
        jp      nz, .ColourBitLoop

        ret




