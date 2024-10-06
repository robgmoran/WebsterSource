WorldCode:
;-------------------------------------------------------------------------------------
; Camera - Configure initial camera coordinate values at tilemap offset
; Parameters:
CameraSetInitialCoords:
        ld      a, (BlockTileMapXBlocksOffset)
        ;ld      a, (ScrollTileMapBlockXPointer)
        inc     a                               ; Point to first visible block, as the specified block starts at the edge of the screen and is hidden

        ld      d, a
        ld      e, 16                           ; Size of hidden column
        mul     d, e

        ld      (CameraXWorldCoordinate), de    ; Set x to start of visible area

        ld      a, (BlockTileMapYBlocksOffset)
        ;ld      a, (ScrollTileMapBlockYPointer)
        inc     a                               ; Point to first visible block, as the specified block starts at the top of the screen and is hidden

        ld      d, a
        ld      e, 16                           ; Size of hidden row
        mul     d, e

        ld      (CameraYWorldCoordinate), de    ; Set y to start of visible area

        ret

;-------------------------------------------------------------------------------------
; Camera - Left - Update camera coordinate value
; Note: Right updated in scroll code
; Parameters:                   
CameraMoveLeft:
; Check whether we have reached the far right visible area
        ld      hl, CameraXWorldCoordinate
        ld      de, 16
        sbc     hl, de
        ret     z                               ; Return as we've reached the far left visible area 

        ld      de, (CameraXWorldCoordinate)
        dec     de
        ld      (CameraXWorldCoordinate), de    ; Update x camera coordinate

        ret

;-------------------------------------------------------------------------------------
; Camera - Up - Update camera coordinate value
; Note: Down updated in scroll code
; Parameters:                   
CameraMoveUp:
; Check whether we have reached the far right visible area
        ld      hl, CameraYWorldCoordinate
        ld      de, 16
        sbc     hl, de
        ret     z                               ; Return as we've reached the top visible area 

        ld      de, (CameraYWorldCoordinate)
        dec     de
        ld      (CameraYWorldCoordinate), de    ; Update x camera coordinate

        ret

/*
;-------------------------------------------------------------------------------------
; Check Sprite within Camera Boundary
; Parameters:
CheckSpritesToCamera:
        ld      ix, OtherSprites

        ld      b, 63
.SpriteLoop:
        push    bc
        ld      a, (ix+S_SPRITE_TYPE.active)
        cp      1
        jr      nz, .NextSprite                 ; Jump if sprite not active

        call    CheckSpriteCameraBoundary       ; Display/Hide sprite as appropriate 

.NextSprite:
        ld      d, 0
        ld      e, S_SPRITE_TYPE
        add     ix, de                          ; Point to next sprite data

        pop     bc
        djnz    .SpriteLoop

        ret
*/

;-------------------------------------------------------------------------------------
; Check Sprite within Camera Boundary
; Parameters:
; ix = Source sprite
; Return Values:
; a = 0 Sprite not visible, 1 Sprite visible
CheckSpriteCameraBoundary:
; Check whether sprite is still active
        ld      a, (ix+S_SPRITE_TYPE.active)
        cp      0
        ret     z                               ; Return if sprite no longer active

; Obtain source and target 9-bit x coordinates
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      bc, hl                          ; Backup source.x value
        
        ld      de, (CameraXWorldCoordinate)
        ld      (BackupWord1), de                ; Backup target.x value

; Box Check 1 - source.x < target.x + width
        add     de, CameraWidth                 ; Add width to target.x value

        or      a
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if source.x (hl) >= target.x + width (de)

; Box Check 2 - source.x + width > target.x
        ld      hl, bc                          ; Restore source.x value
        ld      a, (ix+S_SPRITE_TYPE.Width)
        add     hl, a                           ; Add width to source.x

        ld      de, (BackupWord1)                ; Restore target.x value

        or      a
        ex      hl, de                          ; Swap target.x and source.x
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if target.x (hl) >= source.x + width (de)

; Obtain source and target 8-bit y coordinates
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      bc, hl                          ; Backup source.x value

        ld      de, (CameraYWorldCoordinate)
        ld      (BackupWord1), de                ; Backup target.x value
        
; Box Check 3 - source.y < target.y + height
        add     de, CameraHeight                ; Add height to target.y

        or      a
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if source.y (hl) >= target.y + height (de)

; Box Check 4 - source.y + height > target.y
        ld      hl, bc                          ; Restore source.y

        ld      a, (ix+S_SPRITE_TYPE.Height)
        add     hl, a                           ; Add height to source.y
        
        ld      de, (BackupWord1)                ; Restore target.y

        or      a
        ex      hl, de                          ; Swap target.x and source.x
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if target.y (hl) >= source.y + height        

; Sprite within camera boundary
        call    DisplaySprite                   ; Make sprite visible on screen

        ld      a, 1                            ; Return value
        ret
        
.NotInRange:
        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        call    nz, HideSprite                  ; Call if sprite currently visible

        ld      a, 0                            ; Return value

        ret

;-------------------------------------------------------------------------------------
; Convert World Coordinate to Display Coordinate - Run separately for x and y
; Parameters:
; hl - World Coordinate
; de - Camera World Coordinate
; Return:
; hl - Display Coordinate
ConvertWorldToDisplayCoord:
        or      a
        sbc     hl, de                          ; Calculate offset
        add     hl, 16                          ; Display starts at column 16, so Add display offset value

        ret

;-------------------------------------------------------------------------------------
; Convert Block Coordinates to World Coordinates
; Parameters:
; h = x block coordinate
; l = y block coordinate
; iy = Sprite storage memory address
ConvertBlockToWorldCoord:
        ld      a, l
        ld      d, a                    ; Block Y
        ld      e, 16                   ; Height of block
        mul     d, e                    ; Y world coordinate
        ld      (iy+S_SPRITE_TYPE.YWorldCoordinate), de ; Set world y coordinate

        ld      a, h
        ld      d, a                    ; Block X
        ld      e, 16                   ; Width of block
        mul     d, e                    ; X world coordinate
        ld      (iy+S_SPRITE_TYPE.XWorldCoordinate), de ; Set world x coordinate

        ret

/* 23/11/22 - Removed as no longer used
;-------------------------------------------------------------------------------------
; Convert Block Coordinates to Block Offset in tilemap data ; TODO - Remove if not used
; Parameters:
; h = x block coordinate
; l = y block coordinate
ConvertBlockToBlockOffset:
        ld      a, l                    
        ld      d, a                    ; BlockY
        ld      e, BlockTileMapWidth    ; Number of blocks wide
        mul     d, e

        ld      a, h                    ; BlockX
        add     de, a                   ; Block offset

        ret
*/

;-------------------------------------------------------------------------------------
; Convert World Coordinates to Block Offset in tilemap data
; Parameters:
; bc = x world coordinate
; hl = y world coordinate
; Return:
; bc - Block offset
; de - d = x block offset, e = y block offset
ConvertWorldToBlockOffset:
; Y - Convert into block row 
; (y/16)*Number of blocks in row
        push    bc              ; Save x world coordinate

        ld      de, hl
        ld      b, 4            ; Number of bits to rotate right = divide by 16
        bsra    de, b           ; e = Result of division
        
        pop     bc              ; Restore x world coordinate
        push    de              ; Save row offset

        ld      d, BlockTileMapWidth
        mul     d, e
                
        ld      hl, de          ; Copy row offset for later calculation

; X - Convert into block column 
; x/16
        ld      de, bc
        ld      b, 4            ; Number of bits to rotate right = divide by 16
        bsra    de, b           ; e = Result of division

; Calculate block offset
        add     hl, de          ; Add column offset to row offset

        ld      bc, hl          ; Return - bc = Block offset

; Prepare return values
        ld      a, e
        ld      d, a            ; Return - d = x block offset

        pop     hl              ; Restore row offset

        ld      a, l
        ld      e, a            ; Return - e = y block offset
        
        ret

/* 23/11/22 - Removed as no longer used
;-------------------------------------------------------------------------------------
; Convert Screen Coordinates to tile within Screen Tilemap at block accuracy 
; i.e. Tile mapped to first tile within block boundary 
; Parameters:
; hl = x screen coordinate
; a = y screen coordinate
; Return:
; hl - Screen tilemap (x/y)
ConvertScreenToTileMap:
; X - Convert into tilemap column 
; - x/16 - To map to block offset
        ld      de, hl
        ld      b, 4            ; Number of bits to rotate right = divide by 16
        bsra    de, b           ; e = Result of division

; Result*2 - To map to first tile within block offset
        ld      d, 2
        mul     d, e

        ld      h, e            ; Store x tile offset

; Y - Convert into tilemap row 
; - (y/16) - To map to block offset
        ld      d, 0
        ld      e, a
        ld      b, 4            ; Number of bits to rotate right = divide by 16
        bsra    de, b           ; e = Result of division
        
; Result*2 - To map to first tile within block offset
        ld      d, 2
        mul     d, e

        ld      l, e
        
        ret
*/

;-------------------------------------------------------------------------------------
; Check whether position divisable by 16
; Limited to 4080 (255(max byte size)*16), which equals 14 screens wide (4080/(18*16)) or 31 screens high (4080/(8*16))
; Parameters:
; de = Sprite Position either x or y
; Return Values:
; a = 0 - Not Divisable by 16, 1 - Divisable by 16
CheckDivisableBy16:
        ld      a, 0            ; Assume divisible by 16
        ld      b, 16-4         ; Rotate right 4 i.e. Divide by 16
        brlc    de,b            ; Divide by 16; If d=0 then number divisible by 16
        cp      d
        ret     nz              ; Return if not divisible

        inc     a
        ret
/*
; Check whether value is divisable by 16
        ld      a, e            ; Store low byte
        ld      b, 1            ; Assume divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp     c, .Remainder    ; If carry set then position not directly divisable by 16
        rra                     ; Rotate to right through carry - Divide by 2
        jp      nc, .Continue   ; If no carry then position divisible by 16
.Remainder
        dec     b               ; Indicate position not divisable by 16
.Continue
        ld      a, b
        ret
*/
EndofWorldCode: