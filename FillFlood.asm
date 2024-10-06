FillFloodCode:
;-------------------------------------------------------------------------------------
; Fill Flood counters adjacent to player
; 
; Source: TileMapScreen - Only checks top byte within each 4 byte tile i.e. Each tile is 16-pixels x 16-pixels
; Target: FFStorage - Based on source, only stores 1 byte per tile, so (TileMapHeight/2)*(TileMapWidth/2)
; Note: Ensure screen refresh doesn't conflict with routine at top of screen, otherwise incorrect end of line
;       values can be reported 
; Troubleshooting:
; 1. Run and create gaps in map and press F1
; 2. Within Debug Console, type -md FFStorageComplete 320
; 3. Copy content of Debug Console into Notepad (wordwrap enabled)
; 4. Size Notepad to fit 20 pairs of digits onto line
; 5. Replace 99 ($63) {FFResetValue} with --
FillFlood:
; Check whether we are continuing to populate the FFStorage i.e. Queue contains entries from last run
        ld      a, (FFQueueContent)
        cp      1
        jp      z, .ContinueRun         ; Jump if we are continuing to populate FFStorage after the last run 

; Starting a new FFStorage population 
; Backup scroll pointers to be used during FF run; required as FF could be split across multiple frames 
        ld      a, (ScrollTileMapBlockXPointer) 
        ld      (FFScrollTileMapBlockXPointerBuilding), a
        ld      a, (ScrollTileMapBlockYPointer) 
        ld      (FFScrollTileMapBlockYPointerBuilding), a

; First check whether player at valid position
        call    GetPlayerTilexy         ; Get/Check player tile position

; Clear Flood Fill Storage
        ld hl, FFStorage
        ld (hl), FFResetValue                   ; Set intial value to be copied

        LD      HL, DMAFFStorageClear           ; HL = pointer to DMA program
        LD      B, DMAFFStorageClearCopySize    ; B = size of the code
        LD      C, $6B                          ; C = $6B (zxnDMA port)
        OTIR                                    ; upload DMA program

; Reset Queue
        call    ResetQueue

        ld      a, 1
        ld      (FFQueueContent), a

; Queue first x, y position - Block coordinates start from 0, 0
        ld      a, (FFStartxBlock)        ; Current player x block
        ld      (FFSourcexPos), a
        ld      d, a
        ld      a, (FFStartyBlock)        ; Current player y block
        ld      (FFSourceyPos), a
        ld      e, a
        
        call    EnQueue                 ; Store first x, y block

        call    GetFFPositionBuilding           ; Return - hl & de = Offset

; Set FF start content to 0 - Player block
        ld      iy, FFStorage
        add     iy, de
        ld      (iy), 0                 

        jp      .NextNode

; Continuing FFStorage population from last run
.ContinueRun:
        call    PeekQueue               ; Return - d(x)e(y)

        ld      a, d
        ld      (FFSourcexPos), a
        ld      a, e
        ld      (FFSourceyPos), a
        
        call    GetFFPositionBuilding           ; Return - hl & de = Offset

        ld      iy, FFStorage
        add     iy, de

; Process Nodes Loop
.NextNode:
; - Check for end of processing - Queue empty
        ld      hl, (QueueStart)
        ld      de, (QueueEnd)
        or      a
        sbc     hl, de
        jp      z, .QueueEmpty          ; Jump if queue empty

; - Check for end of processing - Max nodes per run performed
        ld      a, (FFNodesPerCallCounter)
        cp      FFNodesPerCall
        jp      z, .ResetCounter        ; Jump if required number of nodes process in current run

        inc     a
        ld      (FFNodesPerCallCounter), a      ; Otherwise continue processing nodes and update counter

; Process Node
        call    DeQueue                 ; Return - d(x)e(y)
        ld      (FFSourceyPos), de
        call    GetFFPositionBuilding           ; Return - hl & de = Target Offset

        ld      iy, FFStorage
        add     iy, de
        ld      b, (iy)                 ; Obtain counter for node
        inc     b                       ; Increment counter

.CheckUp:
; Check whether at top of screen
        ld      a, (FFTargetyPos)
        cp      BlockPlayerTopRow       ; Check whether at top
        jr      z, .CheckRight          ; Jump if at top

; Target Node Above - Does it already have a value?
        ld      hl, iy
        ld      de, TileMapWidth/2      
        sub     hl, de                  ; Target - Move up 1 x line        
        ld      iy, hl        

        ld      a, (iy)
        cp      FFResetValue            ; Target - Check whether a new value has already been stored
        jr      nz, .CheckRight         ; Jump if assigned

; Source Node Above - Is it a wall...
        ld      hl, (FFSourceOffset)        
        ld      de, BlockTileMapWidth
        sub     hl, de                  ; Source - Move up one line

        ld      de, (LevelTileMap)
        add     hl, de
        ld      ix, hl                  ; Source location

        call    CheckBlockType
        cp      0
        jp      z, .CheckRight          ; Jump if source block contains inaccessible block type

; Accessible source block type - Store new node value
        ld      (iy), b                 ; Target - Store content value 
; Place node onto queue
        ld      a, (FFSourcexPos)
        ld      d, a
        ld      a, (FFSourceyPos)
        dec     a                       ; Move up extra line i.e. Next 16-pixel tile up
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.CheckRight:
; Check whether at right of screen - Check target and not source
        ld      a, (FFTargetxPos)
        cp      BlockPlayerRightCol     ; Check whether at far right
        jr      z, .CheckDown

; Target Node Right - Does it already have a value?
        ld      iy, FFStorage
        ld      hl, (FFTargetOffset)    ; Restore hl
        inc     hl                      ; Target - Move right one byte
        ex      hl, de
        add     iy, de
        ld      a, (iy)
        cp      FFResetValue            ; Target - Check whether a new value has already been stored
        jr      nz, .CheckDown

; Source Node Right - Is it a wall...
        ld      hl, (FFSourceOffset)        
        ld      de, (LevelTileMap)
        add     hl, de
        ld      ix, hl                  ; Source location

        inc     ix                      ; Source - Move right one byte

        call    CheckBlockType
        cp      0
        jp      z, .CheckDown           ; Jump if source block contains inaccessible block type

; Accessible source block type - Store new node value
        ld      (iy), b                 ; Target - Store content value 
        
; Place node onto queue
        ld      a, (FFSourcexPos)
        ;inc     a
        inc     a                       ; Move right extra byte i.e. Next 16-pixel tile right
        ld      d, a
        ld      a, (FFSourceyPos)
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.CheckDown:
; Check whether at bottom of screen
        ld      a, (FFTargetyPos)
        cp      BlockPlayerBottomRow    ; Check whether at bottom
        jr      z, .CheckLeft           ; Jump if at bottom

; Target Node Below - Does it already have a value?
        ld      hl, FFStorage
        ld      de, TileMapWidth/2      
        add     hl, de                  ; Target - Move down 1 x line        
        ld      de, (FFTargetOffset)
        add     hl, de
        ld      iy, hl        

        ld      a, (iy)
        cp      FFResetValue            ; Target - Check whether a new value has already been stored
        jr      nz, .CheckLeft         

; Source Node Below - Is it a wall...
        ld      hl, (FFSourceOffset)        
        ld      de, BlockTileMapWidth
        add     hl, de                  ; Source - Move down one line

        ld      de, (LevelTileMap)      
        add     hl, de
        ld      ix, hl                  ; Source location

        call    CheckBlockType
        cp      0
        jp      z, .CheckLeft         ; Jump if source block contains inaccessible block type

; Accessible source block type - Store new node value
        ld      (iy), b                 ; Target - Store content value 

; Place node onto queue
        ld      a, (FFSourcexPos)
        ld      d, a
        ld      a, (FFSourceyPos)
        ;inc     a
        inc     a                       ; Move down extra line i.e. Next 16-pixel tile down
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.CheckLeft:
; Check whether at left of screen
        ld      a, (FFTargetxPos)
        cp      BlockPlayerLeftCol      ; Check whether at far left
        jr      z, .EndOfCheck

; Target Node Left - Does it already have a value?
        ld      iy, FFStorage
        ld      hl, (FFTargetOffset)    ; Restore hl
        dec     hl                      ; Target - Move left one byte
        ex      hl, de
        add     iy, de
        ld      a, (iy)
        cp      FFResetValue            ; Target - Check whether a new value has already been stored
        jr      nz, .EndOfCheck

; Source Node Left - Is it a wall...
        ld      hl, (FFSourceOffset)        
        ld      de, (LevelTileMap)
        add     hl, de
        ld      ix, hl                  ; Source location

        dec     ix                      ; Source - Move left one byte

        call    CheckBlockType
        cp      0
        jp      z, .EndOfCheck         ; Jump if source block contains inaccessible block type

; Accessible source block type - Store new node value
        ld      (iy), b                 ; Target - Store content value 
        
; Place node onto queue
        ld      a, (FFSourcexPos)
        dec     a                       ; Move right extra byte i.e. Next 16-pixel tile right
        ld      d, a
        ld      a, (FFSourceyPos)
        ld      e, a
        call    EnQueue                 ; Store up x, y position

.EndOfCheck:
        jp      .NextNode

; Reset counters for next complete new run
.QueueEmpty:
; Copy FFStorage to FFStorageComplete
        LD      HL, DMAFFStorageCopy            ; HL = pointer to DMA program
        LD      B, DMAFFStorageCopySize         ; B = size of the code
        LD      C, $6B                          ; C = $6B (zxnDMA port)
        OTIR                                    ; upload DMA program

; Backup scroll pointers to be used when accessing newly built FF; required as FF will be constantly rebuilt 
        ld      a, (FFScrollTileMapBlockXPointerBuilding)
        ld      (FFScrollTileMapBlockXPointerBuilt), a
        ld      a, (FFScrollTileMapBlockYPointerBuilding)
        ld      (FFScrollTileMapBlockYPointerBuilt), a

        ld      a, 0
        ld      (FFQueueContent), a
        ld      (FFNodesPerCallCounter), a

        ld      a, 1
        ld      (FFBuilt), a
        
        ret

; Reset counter for next partial run
.ResetCounter:
        ld      a, 0
        ld      (FFNodesPerCallCounter), a
        
        ret

;-------------------------------------------------------------------------------------
; Check node for inaccessible blocks e.g. Wall blocks
; Parameters:
; ix - Source location of node to be checked in tilemap
; iy - Target location of node in FFStorage 
; Return Values:
; a = 0 - Inaccessible block, 1 - Accessible block
CheckBlockType:
; Check for wall, destructable and turret blocks
        ld      a, (ix)
        cp      BlockWallsEnd+1
        jp      c, .InaccessibleBlock    ; Jump if source node is inaccessible i.e. Wall block or destructable block

/* - TODO - Re-add if hazard blocks should be included within FF
; Check for hazard blocks
        cp      HazardStart
        jp      c, .NotHazard           ; Jump if HazardStart > Block

        ld      d, a
        ld      a, HazardEnd
        cp      d
        jp      c, .NotHazard           ; Jump if block > HazardEnd

        jp      .InaccessibleBlock
*/

.NotHazard:
; Check for locked doors
        ld      a, (ix)
        cp      HorDoor1End+1
        jp      z, .InaccessibleBlock

        cp      HorDoorTrigger
        jp      z, .InaccessibleBlock

        cp      VerDoor1End+1
        jp      z, .InaccessibleBlock

        cp      VerDoorTrigger
        jp      z, .InaccessibleBlock

; 16/10/23 - Removed Reverse Hazard check as it was causing issue with way points enemies
; Check for Reverse-Hazard
        cp      ReverseHazardBlock
        jp      z, .InaccessibleBlock

; Check for Door Lockdown + Unlocked Door
        ld      d, a

        ld      a, (DoorLockdown)
        cp      0
        jp      z, .AccessibleBlock             ; Jump if DoorLockdown not enabled

        ld      a, d
        cp      HorDoorStart
        jp      z, .InaccessibleBlock

        cp      VerDoorStart
        jp      z, .InaccessibleBlock

.AccessibleBlock:
; Source node is accessible
        ld      a, 1
        ret

.InaccessibleBlock:
; Source node is inaccessible
        ld      a, 0
        ret

;-------------------------------------------------------------------------------------
; Get/Check Player x, y tilemap coordinates
; Player needs to be at either an x or y tilemap coordinate divisable by 16 i.e. new block
; Parameters:
; Return Values:
; a = 0 - Don't perform FF, 1 - Perform FF
; FFStartxBlock - Player x block offset
; FFStartyBlock - Player y block offset
GetPlayerTilexy:
        ;;ld      iy, PlayerSprite

/* - Update if code required by a future function 
; 1. Calculate Tile Column (using x position)
        ;;ld      de, (iy+S_SPRITE_TYPE.xPosition)
        ld      de, (PlayerSprite+S_SPRITE_TYPE.xPosition)
        call    CheckDivisableBy16

        cp      1
        jp      z, .ConfigReturnValues  ; Jump if x divisable by 16

; 2. Calculate Tile Row (using y Position and tilemap offset y)
        ld      d, 0
        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)
        ld      e, a
        call    CheckDivisableBy16

        cp      1
        jp      z, .ConfigReturnValues  ; Jump if x divisable by 16

        ret
*/

.ConfigReturnValues:
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, 8                                                   ; Point to x middle
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 8                                                   ; Point to y middle
        call    ConvertWorldToBlockOffset

        ld      a, d
        ld      (FFStartxBlock), a                                      ; Store valid x block

        ld      a, e
        ld      (FFStartyBlock), a                                      ; Store valid y block

        ld      a, 1

        ret

GetFFPositionBuilding:
; Get FF positions based on tilemap coordinates during building of FF
; Parameters:
; de = x, y block coordinates; not sprite x, y coordinates
; Return Values:
; hl & de = Target TilePosition
; FFSourceOffset
; FFTargetOffset
; FFTargetxPos
; FFTargetyPos

; Calculate block offset in Flood Fill storage
        push    de              ; Backup

; - Calculate Source Offset - Map data
        ld      c, d                            ; Backup x
        
        ld      a, e
        ld      d, a
        ld      e, BlockTileMapWidth
        mul     d, e                            ; Calculate y offset

        ld      a, c                            ; Restore x
        add     de, a                           ; Add x offset

        ld      (FFSourceOffset), de

; - Calculate Target Offset - FFStorage
        pop     de                              ; Restore

        ld      c, d                            ; Backup x
        
        ld      a, (FFScrollTileMapBlockYPointerBuilding)
        ld      h, a
        ld      a, e
        sub     h

        ld      (FFTargetyPos), a               

        ld      d, a
                
        ld      e, TileMapWidth/2
        mul     d, e                            ; Calculate y offset

        ld      a, (FFScrollTileMapBlockXPointerBuilding)
        ld      h, a
        ld      a, c                            ; Restore x
        sub     h

        ld      (FFTargetxPos), a               

        add     de, a                           ; Add x offset

        ld      (FFTargetOffset), de

        ret

/* 23/11/22 - Removed as no longer used
GetFFPositionBuilt:
; Get FF positions based on tilemap coordinates when FF built
; Parameters:
; de = x, y block coordinates; not sprite x, y coordinates
; Return Values:
; de = Target TilePosition
; FFSourceOffset
; FFTargetOffset
; FFTargetxPos
; FFTargetyPos

; Calculate block offset in Flood Fill storage
        push    de              ; Backup

; - Calculate Source Offset - Map data
        ld      c, d                            ; Backup x
        
        ld      a, e
        ld      d, a
        ld      e, BlockTileMapWidth
        mul     d, e                            ; Calculate y offset

        ld      a, c                            ; Restore x
        add     de, a                           ; Add x offset

        ld      (FFSourceOffset), de

; - Calculate Target Offset - FFStorage
        pop     de                              ; Restore

        ld      c, d                            ; Backup x
        
        ld      a, (FFScrollTileMapBlockYPointerBuilt)
        ld      h, a
        ld      a, e
        sub     h

        ld      (FFTargetyPos), a               

        ld      d, a
                
        ld      e, TileMapWidth/2
        mul     d, e                            ; Calculate y offset

        ld      a, (FFScrollTileMapBlockXPointerBuilt)
        ld      h, a
        ld      a, c                            ; Restore x
        sub     h

        ld      (FFTargetxPos), a               

        add     de, a                           ; Add x offset

        ld      (FFTargetOffset), de

        ret
*/

;-------------------------------------------------------------------------------------
; Check Sprite block is within FFStorage Complete Area
; Parameters:
; de = Sprite Block coordinates (x/y)
; FFScrollTileMapBlockXPointerBuilt
; FFScrollTileMapBlockYPointerBuilt
; Return Values:
; a = 0 - Not in FFStorageComplete Area, 1 - In FFStorageComplete Area
; de = Offset within FFStorageComplete Area
CheckSpriteInFFStorageComplete:
; Sprite Block > FFStorageComplete Left Edge
	ld	a, (FFScrollTileMapBlockXPointerBuilt)
	cp	d
	jp	nc, .NotInFFStorageComplete	; Jump if Enemy block <= FFScrollTileMapBlockXPointerBuilt

; Sprite Block <= FFStorageComplete Right Edge (+ Width-2)
	add	BlockTileMapWidthDisplay-2	; Minus 2 due to first/last columns being hidden
	cp	d
	jp	c, .NotInFFStorageComplete	; Jump if Enemy block > FFScrollTileMapBlockXPointerBuilt

; Sprite Block >FFStorageComplete Top Edge
	ld	a, (FFScrollTileMapBlockYPointerBuilt)
	cp	e
	jp	nc, .NotInFFStorageComplete	; Jump if Enemy block <= FFScrollTileMapBlockYPointerBuilt

; Sprite Block <=FFStorageComplete Bottom Edge (+ Height-2)
	add	BlockTileMapHeightDisplay-2	; Minus 2 due to first/last rows being hidden
	cp	e
	jp	c, .NotInFFStorageComplete	; Jump if Enemy block > FFScrollTileMapBlockYPointerBuilt

; Sprite block within FFStorageComplete Area
; - Calculate FFStorageComplete Area offset
        ld      a, (FFScrollTileMapBlockXPointerBuilt) 
        ld      b, a
        ld      a, d
        sub     b                                       ; Calculate x Offset within area
        ld      c, a                                    ; Save x offset

        ld      a, (FFScrollTileMapBlockYPointerBuilt) 
        ld      b, a
        ld      a, e
        sub     b
        
        ld      d, a
        ld      e, BlockTileMapWidthDisplay
        mul     de                                      ; Calculate y Offset within area

        ld      a, c                                    ; Restore x offset
        add     de, a                                   ; Add x offset to y offset

	ld	a, 1				        ; Return - In FFStorage Area
	ret

; Sprite block not within FFStorageComplete area
.NotInFFStorageComplete:
	ld	a, 0				; Return - Not in FFStorage Area
	ret

EndofFillFloodCode: