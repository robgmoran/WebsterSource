RoutinesCode:
; 06/08/23 - Not used, replaced with ClearTileMapScreen routine
;-------------------------------------------------------------------------------------
; Clear Screen and Screen Attributes
ClearULAScreen: ; Refer to Dougie Do! for code

;-------------------------------------------------------------------------------------
; Clear Screen and Screen Attributes
; Note: Only resets screen tilemap and not tile definitions
; Parameters:
; a = Tile definition attribute used for reset
ClearTileMapScreen:
        ld hl, TileMapLocation                  ; Source
        ld de, TileMapLocation+1                ; Destination = Source + 1
        ld bc, (TileMapWidth*TileMapHeight)-1   ; Number of bytes

        ld (hl), a                              ; Set first byte to '0'
        ldir                                    ; Copy bytes

        ret

;-------------------------------------------------------------------------------------
; Wait for ULA Scan Line
; a = Scanline to wait for
WaitForScanlineUnderUla:
; Sync the main game loop by waiting for particular scanline under the ULA paper area, i.e. scanline 192

/*
; NonFFFrameCount - Check/Update
        ld      a, (NonFFFrameCount)
        cp      NonFFFrameDelay
        jp      nz, .NonFFNotReached

        ld      a, 0                    ; Reset NonFFFrameCount
        ld      (NonFFFrameCount), a

        jp      .UpdateTotalFrames

.NonFFNotReached:
        inc     a                       ; Increment NonFFFrameCount
        ld      (NonFFFrameCount), a            
*/

/* 04/04/23 - Not Used
; Update the TotalFrames counter by +1
.UpdateTotalFrames:
        ld      hl, (TotalFrames)
        inc     hl
        ld      (TotalFrames),hl

; if HL=0, increment upper 16bit too
; Cannot compare a word (hl) therefore need to compare both h & l together
        ld      a,h
        or      l
        jr      nz,.totalFramesUpdated
        ld      hl,(TotalFrames+2)
        inc     hl
        ld      (TotalFrames+2),hl

.totalFramesUpdated:
*/
        ld      e, a            ; Save scanline

; read NextReg $1F - LSB of current raster line
        ld      bc,$243B        ; TBBlue Register Select
        ld      a,$1F           ; Port to access - Active Video Line LSB Register
        out     (c),a           ; Select NextReg $1F
        inc     b               ; TBBlue Register Access
; If already at scanline, then wait extra whole frame (for super-fast game loops)


.cantStartAtScanLine:
        ld      a, e            ; Restore scanline     
        ;;;ld      a, (WaitForScanLine)
        ld      d,a
        ;;;in      a,(c)       ; read the raster line LSB
        ;;;cp      d
        ;;;jr      z,.cantStartAtScanLine
; If not yet at scanline, wait for it ... wait for it ...
.waitLoop:
        ;ld a, 2
	;out (#fe), a   ; set the border color

        in      a,(c)       ; read the raster line LSB

        ;ld a, 0
	;out (#fe), a   ; set the border color
        ;jp      .waitLoop

        cp      d
        jp      c, .waitLoop
        
        
        ;jr      nz,.waitLoop
; and because the max scanline number is between 260..319 (depends on video mode),
; I don't need to read MSB. 256+192 = 448 -> such scanline is not part of any mode.

        ret

;-------------------------------------------------------------------------------------
; Read NextReg

; Params:
; A = nextreg to read
; Output:
; A = value in nextreg
ReadNextReg:
        push    bc
        ld      bc, $243B       ; TBBLUE_REGISTER_SELECT_P_243B
        out     (c),a
        inc     b               ; bc = TBBLUE_REGISTER_ACCESS_P_253B
        in      a,(c)           ; read desired NextReg state
        pop     bc
        
        ret

;-------------------------------------------------------------------------------------
; Process Screen - Open/Close Sprites/TileMap Display Area
; Params:
; a = Area type (0=Tilemap/Layer2+Sprites, 1=Tilemap/Layer2, 2=Sprites)
; GameStatus variable (bit 0 = Set close, bit 1 = set open)
; Output:
ProcessScreen:
        ld      (BackupByte7), a        ; Save area type

        ld      a, (GameStatus)
        bit     1, a                    ; Jump if open screen enabled
        jp      nz, .OpenScreen

        bit     0, a                    ; Jump if close screen enabled
        jp      nz, .CloseScreen

        ret

.OpenScreen:
        call    OpenScreen

        ret

.CloseScreen:
        call    CloseScreen

        ret
;-------------------------------------------------------------------------------------
; Close Screen - Sprites/TileMap Display Area
; Params:
; Output:
CloseScreen:
        ld      b, 0                            ; Register to hold status

; Update Y1 Position
        ld      a, (ClearScreenY1Counter)            
        cp      ClearScreenY1Middle
        jp      nz, .UpdateY1

        set     0, b                            ; Bit 0 set = Y1 target position met

        jp      .ProcessY2

.UpdateY1:
        inc     a
        inc     a
        ld      (ClearScreenY1Counter), a

; Update Y2 Position
.ProcessY2:
        ld      a, (ClearScreenY2Counter)            
        cp      ClearScreenY2Middle
        jp      nz, .UpdateY2

        set     1, b                            ; Bit 1 set = Y2 target position met

        jp      .ProcessX1

.UpdateY2:
        dec     a
        dec     a
        ld      (ClearScreenY2Counter), a

; Update X1 Position
.ProcessX1:
        ld      a, (ClearScreenX1Counter)            
        cp      ClearScreenX1Middle
        jp      nz, .UpdateX1

        set     2, b                            ; Bit 3 set = X1 target position met

        jp      .ProcessX2

.UpdateX1:
        ;dec     a
        inc     a
        ld      (ClearScreenX1Counter), a

; Update X2 Position
.ProcessX2:
        ld      a, (ClearScreenX2Counter)            
        cp      ClearScreenX1Middle
        jp      nz, .UpdateX2

        set     3, b                            ; Bit 4 set = X2 target position met

        ld      a, b
        cp      %00001111
        jp      z, .CloseComplete               ; Jump if all borders set

        jp      .UpdateScreen

.UpdateX2:
        dec     a
        ld      (ClearScreenX2Counter), a

.UpdateScreen:
        call    UpdateScreen

        ret

; Screen closed so reset Close flag
.CloseComplete:
        ld      a, (GameStatus)
        res     0, a
        ld      (GameStatus), a

        ret

;-------------------------------------------------------------------------------------
; Open Screen - Sprites/TileMap Display Area
; Params:
; Output:
OpenScreen:
        ld      b, 0                            ; Register to hold status 

; Update Y1 Position
        ld      a, (ClearScreenY1Counter)            
        cp      TileMapYOffsetTop
        jp      nz, .UpdateY1

        set     0, b                            ; Bit 0 set = Y1 target position met

        jp      .ProcessY2

.UpdateY1:
        dec     a
        dec     a
        ld      (ClearScreenY1Counter), a

; Update Y2 Position
.ProcessY2:
        ld      a, (ClearScreenY2Counter)            
        cp      TileMapYOffsetBottom
        jp      nz, .UpdateY2

        set     1, b                            ; Bit 1 set = Y2 target position met

        jp      .ProcessX1

.UpdateY2:
        inc     a
        inc     a
        ld      (ClearScreenY2Counter), a

; Update X1 Position
.ProcessX1:
        ld      a, (ClearScreenX1Counter)            
        cp      TileMapXOffsetLeft
        jp      nz, .UpdateX1

        set     2, b                            ; Bit 2 set = X1 target position met

        jp      .ProcessX2

.UpdateX1:
        ;dec     a
        dec     a
        ld      (ClearScreenX1Counter), a

; Update X2 Position
.ProcessX2:
        ld      a, (ClearScreenX2Counter)            
        cp      TileMapXOffsetRight
        jp      nz, .UpdateX2

        set     3, b                            ; Bit 3 set = X2 target position met

        ld      a, b
        cp      %00001111
        jp      z, .OpenComplete                ; Jump if all borders set

        jp      .UpdateScreen

.UpdateX2:
        inc     a
        ld      (ClearScreenX2Counter), a

.UpdateScreen:
        call    UpdateScreen

        ret

; Screen open so reset Open flag
.OpenComplete:
        ld      a, (GameStatus)
        res     1, a
        ld      (GameStatus), a

; Check whether title screen should be displayed
        ld      a, (GameStatus2)
        bit     1, a
        ret     nz              ; Return if on title screen; we don't want to display the player

; Display Player Sprite so spawn animation can be played
        ld      a, (PlayerSprAtt+S_SPRITE_ATTR.vpat)
        set     7, a                                    ; Make sprite visible
        ld      (PlayerSprAtt+S_SPRITE_ATTR.vpat), a    ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ret

;-------------------------------------------------------------------------------------
; Update Screen - Sprites/TileMap Display Area
; Params:
; Output:
UpdateScreen:
        ld      a, (BackupByte7)
        cp      1
        jp      z, .TileMapArea                 ; Jump if TileMap area only

; Update Sprite screen position - Title and non-title
        nextreg $1c, %0000'0010                 ; Reset tilemap clip write index
        ld      a, (ClearScreenX1Counter)       
        nextreg $19, a                          ; X1 Position
        ld      a, (ClearScreenX2Counter)       
        nextreg $19, a                          ; X2 Position

        ld      a, (ClearScreenY1Counter)            
        nextreg $19, a                          ; Y1 Position
        ld      a, (ClearScreenY2Counter)            
        nextreg $19, a                          ; Y2 Position

        ld      a, (BackupByte7)
        cp      2
        ret     z                               ; Return if Sprite area only

.TileMapArea:
; Update Tilemap screen position
        ld      a, (GameStatus2)
        bit     1, a
        jp      z, .ProcessOpenNonTitle         ; Jump if non-title screen

        call    TitleUpdateScreen

        jp      .ProcessLayer2

; Update Tilemap screen position - Non-Title only (open), Title/Non-Title (Close)
.ProcessOpenNonTitle:
; Check whether we are closing the title screen
; Note: Only checking top value
        ld      a, (ClearScreenY1Counter)
        ld      b, a
        ld      a, (TitleTileMapYOffsetTopCounter)
        cp      b
        jp      nc, .ProcessLayer2              ; Jump if new value <= current value

        nextreg $1c, %0000'1000                 ; Reset tilemap clip write index
        ld      a, (ClearScreenX1Counter)       
        nextreg $1b, a                          ; X1 Position
        ld      a, (ClearScreenX2Counter)       
        nextreg $1b, a                          ; X2 Position

        ld      a, (ClearScreenY1Counter)            
        nextreg $1b, a                          ; Y1 Position
        ld      a, (ClearScreenY2Counter)            
        nextreg $1b, a                          ; Y2 Position

; Update Layer2 screen position - Title and non-title
.ProcessLayer2:
        nextreg $1c, %0000'0001                 ; Reset tilemap clip write index
        ld      a, (ClearScreenX1Counter)       
        nextreg $18, a                          ; X1 Position
        ld      a, (ClearScreenX2Counter)       
        nextreg $18, a                          ; X2 Position

        ld      a, (ClearScreenY1Counter)            
        nextreg $18, a                          ; Y1 Position
        ld      a, (ClearScreenY2Counter)            
        nextreg $18, a                          ; Y2 Position

        ret

;-------------------------------------------------------------------------------------
; Update Screen - TileMap Display Area
; Note: Called from UpdateScreen routine
; Params:
; Output:
TitleUpdateScreen:
; - Default to ClearScreen counters
        ld      hl, (ClearScreenX1Counter)
        ld      (TitleTileMapXOffsetLeftCounter), hl
        ld      hl, (ClearScreenY1Counter)
        ld      (TitleTileMapYOffsetTopCounter), hl

; -- Check left value
        ld      a, (ClearScreenX1Counter)       
        cp      TitleTileMapXOffsetLeft
        jp      nc, .CheckX2                            ; Jump if required title value <= new value

        ld      a, TitleTileMapXOffsetLeft
        ld      (TitleTileMapXOffsetLeftCounter), a     ; Otherwise override with required title value

; -- Check right value
.CheckX2:
        ld      a, (ClearScreenX2Counter)       
        ld      b, a
        ld      a, TitleTileMapXOffsetRight
        cp      b
        jp      nc, .CheckY1                            ; Jump if new value <= required title value

        ld      a, TitleTileMapXOffsetRight
        ld      (TitleTileMapXOffsetRightCounter), a    ; Otherwise override with required title value

; -- Check top value
.CheckY1:
        ld      a, (ClearScreenY1Counter)       
        cp      TitleTileMapYOffsetTop
        jp      nc, .CheckY2                            ; Jump if required title value <= new value

        ld      a, TitleTileMapYOffsetTop
        ld      (TitleTileMapYOffsetTopCounter), a      ; Otherwise override with required title value

; -- Check bottom value
.CheckY2:
        ld      a, (ClearScreenY2Counter)       
        ld      b, a
        ld      a, TitleTileMapYOffsetBottom
        cp      b
        jp      nc, .ProcessOpen                        ; Jump if new value <= required title value

        ld      a, TitleTileMapYOffsetBottom
        ld      (TitleTileMapYOffsetBottomCounter), a   ; Otherwise override with required title value

.ProcessOpen:
        nextreg $1c, %0000'1000                         ; Reset tilemap clip write index
        ld      a, (TitleTileMapXOffsetLeftCounter)       
        nextreg $1b, a                                  ; X1 Position
        ld      a, (TitleTileMapXOffsetRightCounter)       
        nextreg $1b, a                                  ; X2 Position

        ld      a, (TitleTileMapYOffsetTopCounter)            
        nextreg $1b, a                                  ; Y1 Position
        ld      a, (TitleTileMapYOffsetBottomCounter)            
        nextreg $1b, a                                  ; Y2 Position

        ret

EndOfRoutines: