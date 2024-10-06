ScrollCode:
;-------------------------------------------------------------------------------------
; Check/Scroll to Right
; Parameters:
; Return: a = 0 - No scroll, 1 - Scrolled
CheckScrollRight:
; Check whether we have reached the right-edge of the tilemap
        ld      a, (LevelScrollWidth)
        sub     BlockTileMapWidthDisplay
        ld      b, a

        ld      a, (ScrollTileMapBlockXPointer)
        cp      b
        jr      nz, .ContinueChecks     ; Jump if right edge of level not displayed

        ld      a, (ScrollXValue)
        cp      0
        jr      nz, .ContinueChecks     ; Jump if scroll needs to be updated

        ld      a, 0                    ; Not scrolled
        ret

.ContinueChecks:
; Tilemap right-Edge not reached
; Check whether we need to reset the tilemap scroll 
        ld      a, (ScrollXValue)
        inc     a
        ;;;cp      17                     ; Typically matched if previously scrolled left and scroll value was set to 16
        ;;;jr      z, .ScrollScenario1

        cp      16
        jr      z, .ScrollScenario2     ; Matched when ready to scroll to another block

; Not matched, so update scroll
        ld      (ScrollXValue), a      ; Update tilemap scroll
        nextreg $2f, 0
        nextreg $30, a

        ld      de, (CameraXWorldCoordinate)
        inc     de
        ld      (CameraXWorldCoordinate), de    ; Update x camera coordinate

        ld      a, 1                    ; Scrolled
        ret

.ScrollScenario1:
        ;;;halt
        ;;;ld      a, 1
        ;;;ld      (ScrollXValue), a
        
        ;;;jr      .UpdateTileMapRight

.ScrollScenario2:
        ld      a, 0
        ld      (ScrollXValue), a

        ld      a, (LevelScrollWidth)
        sub     BlockTileMapWidthDisplay
        ld      b, a

        ld      a, (ScrollTileMapBlockXPointer)
        cp      b
        ;;cp      BlockTileMapWidth - BlockTileMapWidthDisplay  ; TODO - Re-implement if scroll issue
        jr      nz, .UpdateTileMapRight                       ; Jump if we are not at the far right

; Perform a scroll as we won't be performing a tilemap update
        nextreg $2f, 0
        nextreg $30, a

        ld      de, (CameraXWorldCoordinate)
        inc     de
        ld      (CameraXWorldCoordinate), de    ; Update x camera coordinate

        ld      a, 1                    ; Scrolled
        ret

; Update Tilemap screen to scroll right
.UpdateTileMapRight:
; 1. Reset X scroll value
        ld      a, (ScrollXValue)
        nextreg $2f, 0
        nextreg $30, a

        ld      de, (CameraXWorldCoordinate)
        inc     de
        ld      (CameraXWorldCoordinate), de    ; Update x camera coordinate

; 2. Copy screen contents 2 bytes to the left i.e. 16 pixels via DMA
        LD      HL, DMAScrollRight       ; HL = pointer to DMA program
        LD      B, DMAScrollRightCopySize    ; B = size of the code
        LD      C, $6B                  ; C = $6B (zxnDMA port)
        OTIR                            ; upload DMA program

; 3. Draw new block column to the right
; - Source - Point to block to be copied
        ld      a, (ScrollTileMapBlockYPointer)
        ld      d, a
        ld      e, BlockTileMapWidth
        mul     d, e                            

        ld      a, (ScrollTileMapBlockXPointer)
        add     BlockTileMapWidthDisplay        ; Point to block at end of current line
        add     de, a                           ; Update with x pointer value

        ld      ix, (LevelTileMap)
        add     ix, de                          ; Add pointer to source

; - Destination - Point to tilemap location to be written to
        ld      iy, TileMapLocation
        ld      b, 0
        ld      c, (TileMapWidth)-2             ; Point to last two tiles on the line
        add     iy, bc

        ld      a, BlockTileMapHeightDisplay
        ld      b, a
.BlockTilemapHeightLoop:       ;Height of tilemap in blocks
        push    bc

        push    iy             ; Destination - Save start of line

        ld      d, (ix)         ; Block number
        ld      e, BlockTiles   ; Number of tiles within block
        mul     d, e            ; Obtain tile definition reference
        ld      a, e            ; a = Starting tile definition

        ld      b, BlockHeight
.BlockTileHeight:               ; Height of tiles within block
        push    bc

        ld      b, BlockWidth
.BlockTileWidth:
        ld      (iy), a         ; Write new tile to tilemap

        inc     a               ; Point to next tilemap definition
        inc     iy              ; Point to next tilemap destination

        djnz    .BlockTileWidth
        
; Move to next tilemap line down
        push    af

        ld      a, TileMapWidth
        sub     BlockWidth

        ld      d, 0
        ld      e, a
        add     iy, de          ; Destination - Point to next line down

        pop     af              ; Restore current tile map definition

        pop     bc
        djnz    .BlockTileHeight

; Move to start of next block on next line
        ld      b, 0
        ld      c, BlockTileMapWidth
        add     ix, bc          ; Source - Point to next tile 

        pop     iy              ; Destination - Restore start of line position

        ld      d, TileMapWidth
        ld      e, BlockHeight
        mul     d, e

        add     iy, de          ; Destination - Point to start of next block line

        pop     bc
        djnz    .BlockTilemapHeightLoop

; 4. Increment Pointer within TileMap data
        ld      a, (ScrollTileMapBlockXPointer)
        inc     a
        ld      (ScrollTileMapBlockXPointer), a

        ld      a, 1                    ; Scrolled
        ret

;-------------------------------------------------------------------------------------
; Check/Scroll to Left
; Parameters:
; Return: a = 0 - No scroll, 1 - Scrolled
CheckScrollLeft:
; Check whether we have reached the left-edge of the tilemap
        ld      a, (ScrollTileMapBlockXPointer)
        cp      0
        jr      nz, .ContinueChecks

        ld      a, (ScrollXValue)
        cp      0
        jr      nz, .ContinueChecks     ; Jump if scroll needs to be updated

        ld      a, 0                    ; Not scrolled
        ret

.ContinueChecks:
; Tilemap left-Edge not reached
; Check whether we need to reset the tilemap scroll 
        ld      a, (ScrollXValue)
        dec     a
        cp      255                     ; Typically matched if previously scrolled right and scroll value was set to 0
        jr      z, .ScrollScenario1

        cp      0
        jr      z, .ScrollScenario2     ; Matched when ready to scroll to another block

; Not matched, so update scroll
        ld      (ScrollXValue), a      ; Update tilemap scroll
        nextreg $2f, 0
        nextreg $30, a

        call    CameraMoveLeft

        ld      a, 1                    ; Scrolled
        ret

.ScrollScenario1:
        ld      a, 15
        ld      (ScrollXValue), a

        jr      .UpdateTileMapLeft

.ScrollScenario2:
        ld      a, 0
        ;;;ld      a, 16
        ld      (ScrollXValue), a

        ;;;ld      a, (ScrollTileMapBlockXPointer)
        ;;;cp      0
        ;;;jr      nz, .UpdateTileMapLeft                   ; Jump if we are not at the far left

        ;;;ld      a, 0
        ;;;ld      (ScrollXValue), a

; Perform a scroll as we won't be performing a tilemap update
        nextreg $2f, 0
        nextreg $30, a

        call    CameraMoveLeft

        ld      a, 1                    ; Scrolled
        ret

; Update Tilemap screen to scroll left
.UpdateTileMapLeft:
; 1. Reset X scroll value
        ld      a, (ScrollXValue)
        nextreg $2f, 0
        nextreg $30, a

        call    CameraMoveLeft

; 2. Copy screen contents 2 bytes to the left i.e. 16 pixels via DMA
        LD      HL, DMAScrollLeft               ; HL = pointer to DMA program
        LD      B, DMAScrollLeftCopySize        ; B = size of the code
        LD      C, $6B                          ; C = $6B (zxnDMA port)
        OTIR                                    ; upload DMA program

; 3. Draw new block column to the left
; - Source - Point to block to be copied
        ld      a, (ScrollTileMapBlockYPointer)
        ld      d, a
        ld      e, BlockTileMapWidth
        mul     d, e                            

        ld      a, (ScrollTileMapBlockXPointer)
        dec     a
        add     de, a                           ; Update with x pointer value

        ld      ix, (LevelTileMap)
        add     ix, de                          ; Add pointer to source

; - Destination - Point to tilemap location to be written to
        ld      iy, TileMapLocation

        ld      a, BlockTileMapHeightDisplay
        ld      b, a
.BlockTilemapHeightLoop:       ;Height of tilemap in blocks
        push    bc

        push    iy             ; Destination - Save start of line

        ld      d, (ix)         ; Block number
        ld      e, BlockTiles   ; Number of tiles within block
        mul     d, e            ; Obtain tile definition reference
        ld      a, e            ; a = Starting tile definition

        ld      b, BlockHeight
.BlockTileHeight:               ; Height of tiles within block
        push    bc

        ld      b, BlockWidth
.BlockTileWidth:
        ld      (iy), a         ; Write new tile to tilemap

        inc     a               ; Point to next tilemap definition
        inc     iy              ; Point to next tilemap destination

        djnz    .BlockTileWidth
        
; Move to next tilemap line down
        push    af

        ld      a, TileMapWidth
        sub     BlockWidth

        ld      d, 0
        ld      e, a
        add     iy, de          ; Destination - Point to next line down

        pop     af              ; Restore current tile map definition

        pop     bc
        djnz    .BlockTileHeight

; Move to start of next block on next line
        ld      b, 0
        ld      c, BlockTileMapWidth
        add     ix, bc          ; Source - Point to next tile 

        pop     iy              ; Destination - Restore start of line position

        ld      d, TileMapWidth
        ld      e, BlockHeight
        mul     d, e

        add     iy, de          ; Destination - Point to start of next block line

        pop     bc
        djnz    .BlockTilemapHeightLoop

; 4. Increment Pointer within TileMap data
        ld      a, (ScrollTileMapBlockXPointer)
        dec     a
        ld      (ScrollTileMapBlockXPointer), a

        ld      a, 1                    ; Scrolled
        ret

;-------------------------------------------------------------------------------------
; Check/Scroll Down
; Parameters:
; Return: a = 0 - No scroll, 1 - Scrolled
CheckScrollDown:
; Check whether we have reached the bottom of the tilemap
        ld      a, (LevelScrollHeight)
        sub     BlockTileMapHeightDisplay
        ld      c, a

        ld      a, (ScrollTileMapBlockYPointer)
        cp      c
        jr      nz, .ContinueChecks     ; Jump if bottom edge of level not displayed

        ld      a, (ScrollYValue)
        cp      0
        jr      nz, .ContinueChecks     ; Jump if scroll needs to be updated

        ld      a, 0                    ; Not scrolled
        ret

.ContinueChecks:
; Tilemap down-bottom not reached
; Check whether we need to reset the tilemap scroll 
        ld      a, (ScrollYValue)
        inc     a
        ;;;cp      17                     ; Typically matched if previously scrolled up and scroll value was set to 16
        ;;;jr      z, .ScrollScenario1

        cp      16
        jr      z, .ScrollScenario2     ; Matched when ready to scroll to another block

; Not matched, so update scroll
        ld      (ScrollYValue), a      ; Update tilemap scroll
        nextreg $31, a

        ld      de, (CameraYWorldCoordinate)
        inc     de
        ld      (CameraYWorldCoordinate), de    ; Update y camera coordinate

        ld      a, 1                    ; Scrolled
        ret

.ScrollScenario1:
        ;;;ld      a, 1
        ;;;ld      (ScrollYValue), a
        
        ;;;jr      .UpdateTileMapDown

.ScrollScenario2:
        ld      a, 0
        ld      (ScrollYValue), a

        ld      a, (LevelScrollHeight)
        sub     BlockTileMapHeightDisplay
        ld      b, a

        ld      a, (ScrollTileMapBlockYPointer)
        cp      b
        ;;;cp      BlockTileMapHeight - BlockTileMapHeightDisplay       ; TODO - Re-implement if scroll issue
        jr      nz, .UpdateTileMapDown                       ; Return if we are at the bottom

; Perform a scroll as we won't be performing a tilemap update
        nextreg $31, a

        ld      de, (CameraYWorldCoordinate)
        inc     de
        ld      (CameraYWorldCoordinate), de    ; Update y camera coordinate

        ld      a, 1                    ; Scrolled
        ret

; Update Tilemap screen to scroll down
.UpdateTileMapDown:
; 1. Reset X scroll value
        ld      a, (ScrollYValue)
        nextreg $31, a

        ld      de, (CameraYWorldCoordinate)
        inc     de
        ld      (CameraYWorldCoordinate), de    ; Update y camera coordinate

; 2. Copy screen contents 2 bytes to the left i.e. 16 pixels via DMA
        LD      HL, DMAScrollDown       ; HL = pointer to DMA program
        LD      B, DMAScrollDownCopySize    ; B = size of the code
        LD      C, $6B                  ; C = $6B (zxnDMA port)
        OTIR                            ; upload DMA program
; 3. Draw new block column at the bottom
; - Source - Point to block to be copied
; a = x + (y*width)
        ld      ix, (LevelTileMap)
        ld      a, (ScrollTileMapBlockYPointer)
        ld      b, BlockTileMapHeightDisplay
        add     b                               
        ld      d, a
        ld      e, BlockTileMapWidth
        mul     d, e                            ; Point to block after bottom of screen

        ld      a, (ScrollTileMapBlockXPointer)
        add     de, a                           ; Update with x pointer value
        add     ix, de                          ; Add pointer to source

; - Destination - Point to tilemap location to be written to
; a = TileMapHeight-2 * TileMapWidth???
        ld      iy, TileMapLocation

        ld      d, TileMapHeight-2             ; Point to first row hidden at botton of screen
        ld      e, TileMapWidth
        mul     d, e
        add     iy, de                          ; Add offset to destination

        ld      a, BlockTileMapWidthDisplay
        ld      b, a
.BlockTilemapWidthLoop:         ; Width of tilemap in blocks
        push    bc

        push    iy              ; Destination - Save position on line

        ld      d, (ix)         ; Block number
        ld      e, BlockTiles   ; Number of tiles within block
        mul     d, e            ; Obtain tile definition reference
        ld      a, e            ; a = Starting tile definition

        ld      b, BlockHeight
.BlockTileHeight:               ; Height of tiles within block
        push    bc

        ld      b, BlockWidth
.BlockTileWidth:
        ld      (iy), a         ; Write new tile to tilemap

        inc     a               ; Point to next tilemap definition
        inc     iy              ; Point to next tilemap destination

        djnz    .BlockTileWidth
        
; Move to next tilemap line down
        push    af

        ld      a, TileMapWidth
        sub     BlockWidth

        ld      d, 0
        ld      e, a
        add     iy, de          ; Destination - Point to next line down

        pop     af              ; Restore current tile map definition

        pop     bc
        djnz    .BlockTileHeight

; Move to start of next block on same line
        inc     ix

        pop     iy              ; Destination - Restore start of previous block

        ld      d, 0
        ld      e, BlockWidth
        add     iy, de          ; Destination - Point to start of next block across

        pop     bc
        djnz    .BlockTilemapWidthLoop

; 4. Increment Pointer within TileMap data
        ld      a, (ScrollTileMapBlockYPointer)
        inc     a
        ld      (ScrollTileMapBlockYPointer), a

        ld      a, 1                    ; Scrolled
        ret

;-------------------------------------------------------------------------------------
; Check/Scroll Up
; Parameters:
; Return: a = 0 - No scroll, 1 - Scrolled
CheckScrollUp:
; Check whether we have reached the top of the tilemap
        ld      a, (ScrollTileMapBlockYPointer)
        cp      0
        jr      nz, .ContinueChecks

        ld      a, (ScrollYValue)
        cp      0
        ret     z

        ;;;ld      a, (ScrollYValue)
        ;;;cp      0
        ;;;jr      nz, .ContinueChecks     ; Jump if scroll needs to be updated

        ;;;ld      a, 0                    ; Not scrolled
        ;;;ret

.ContinueChecks:
; Tilemap up-top not reached
; Check whether we need to reset the tilemap scroll 
        ld      a, (ScrollYValue)
        dec     a
        cp      255                     ; Typically matched if previously scrolled down and scroll value was set to 0
        jr      z, .ScrollScenario1

        ;;;cp      0
        ;;;jr      z, .ScrollScenario2     ; Matched when ready to scroll to another block

; Not matched, so update scroll
        ld      (ScrollYValue), a      ; Update tilemap scroll
        nextreg $31, a

        call    CameraMoveUp

        ld      a, 1                    ; Scrolled
        ret

.ScrollScenario1:
        ld      a, 15
        ld      (ScrollYValue), a
        
        jr      .UpdateTileMapUp

.ScrollScenario2:
        ;;;ld      a, 0
        ;;;ld      a, 16

        ld      (ScrollYValue), a

        ;;;ld      a, (ScrollTileMapBlockYPointer)
        ;;;cp      0
        ;;;jr      nz, .UpdateTileMapUp                       ; Return if we are at the top

        ;;;ld      a, 0
        ;;;ld      (ScrollYValue), a

; Perform a scroll as we won't be performing a tilemap update
        nextreg $31, a

        call    CameraMoveUp

        ld      a, 1                    ; Scrolled
        ret

; Update Tilemap screen to scroll up
.UpdateTileMapUp:
; 1. Reset X scroll value
        ld      a, (ScrollYValue)
        nextreg $31, a

        call    CameraMoveUp

; 2. Copy screen contents 2 bytes to the left i.e. 16 pixels via DMA
        LD      HL, DMAScrollUp       ; HL = pointer to DMA program
        LD      B, DMAScrollUpCopySize    ; B = size of the code
        LD      C, $6B                  ; C = $6B (zxnDMA port)
        OTIR                            ; upload DMA program

; 3. Draw new block column at the bottom
; - Source - Point to block to be copied
; a = x + (y*width)
        ld      ix, (LevelTileMap)
        ld      a, (ScrollTileMapBlockYPointer)

        dec     a

        ;ld      b, BlockTileMapHeightDisplay
        ;add     b                               
        ld      d, a
        ld      e, BlockTileMapWidth
        mul     d, e                            ; Point to block on line above

        ld      a, (ScrollTileMapBlockXPointer)
        add     de, a                           ; Update with x pointer value
        add     ix, de                          ; Add pointer to source

; - Destination - Point to tilemap location to be written to
; a = TileMapHeight-2 * TileMapWidth???
        ld      iy, TileMapLocation

        ld      a, BlockTileMapWidthDisplay
        ld      b, a
.BlockTilemapWidthLoop:         ; Width of tilemap in blocks
        push    bc

        push    iy              ; Destination - Save position on line

        ld      d, (ix)         ; Block number
        ld      e, BlockTiles   ; Number of tiles within block
        mul     d, e            ; Obtain tile definition reference
        ld      a, e            ; a = Starting tile definition

        ld      b, BlockHeight
.BlockTileHeight:               ; Height of tiles within block
        push    bc

        ld      b, BlockWidth
.BlockTileWidth:
        ld      (iy), a         ; Write new tile to tilemap

        inc     a               ; Point to next tilemap definition
        inc     iy              ; Point to next tilemap destination

        djnz    .BlockTileWidth
        
; Move to next tilemap line down
        push    af

        ld      a, TileMapWidth
        sub     BlockWidth

        ld      d, 0
        ld      e, a
        add     iy, de          ; Destination - Point to next line down

        pop     af              ; Restore current tile map definition

        pop     bc
        djnz    .BlockTileHeight

; Move to start of next block on same line
        inc     ix

        pop     iy              ; Destination - Restore start of previous block

        ld      d, 0
        ld      e, BlockWidth
        add     iy, de          ; Destination - Point to start of next block across

        pop     bc
        djnz    .BlockTilemapWidthLoop

; 4. Increment Pointer within TileMap data
        ld      a, (ScrollTileMapBlockYPointer)
        dec     a
        ld      (ScrollTileMapBlockYPointer), a

        ld      a, 1                    ; Scrolled
        ret

EndofScrollCode: