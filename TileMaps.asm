TileMapsCode:
;-------------------------------------------------------------------------------------
; Setup Level Tilemap Configuration
; Parameters:
; a = Memory block containing level tilemap data
;
SetupLevelTileMap:
; Obtain source tilemap level data
; - Map source tilemap level data bank to slot 3
        ld      a, (LevelDataMemBank)           ; Memory bank (8kb) containing tilemap data
        nextreg $53, a                          

; - Copy source TileMap to new working TileMap location in data bank
        ld      hl, (LevelDataTileMapData)      ; Tilemap for current level (skip width, height bytes)
        add     hl, 2
        call    CopyTileMapData

; - Setup Player Start Position
        call    SetupPlayerStartPosition

; - Find world position of finish block
        call    FindFinishPosition

; - Populate Spawn Point data
        call    PopulateSpawnPointData          ; Copies level spawnpoint data and updates tilemap

; - Populate Hazard Data
        call    PopulateHazardData              ; Copies hazard data and updates tilemap

; - Adjust tilemap clipping/scroll values based on size of tilemap
; Note: TileMapLevelData bank needs to be mapped into memory
        call    AdjustTileMap                   

; Setup TileMap palette/screen/definitions; palette faded by intro routine
; - Obtain bank number currently mapped into slot 7; required to be restored later
	ld      a,$57                           ; Port to access - Memory Slot 7
        ld      bc,$243B                        ; TBBlue Register Select
        out     (c),a                           ; Select NextReg $1F

        inc     b                               ; TBBlue Register Access
        in      a, (c)
        ld      (BackupByte), a                 ; Save current bank number in slot 7
        
; - Tilemap Palette
        ld      a, $$PaletteData                ; Memory bank (8kb) containing tilemap palette data        
        ld      hl, (LevelDataTileMapDefPalData); Address of first byte of layer 2 palette data
        ld      b, TileMapDefPalRows            ; Number of colours in palette
        call    SetupTileMapPalette

; - Tilemap Screen
        call    SetupTileMapConfig

; - TileMap Definitions - Already setup within Text Intro routine

        ret

;-------------------------------------------------------------------------------------
; Setup Level Tilemap Configuration
; Parameters:
; a = Memory block containing level tilemap data
;
SetupLevelIntroTileMap:
; Obtain source tilemap level data
; - Map source tilemap level data bank to slot 3
        ;ld      a, (LevelDataMemBank)           ; Memory bank (8kb) containing tilemap data
        nextreg $53, a                          

; - Copy source TileMap to new working TileMap location in data bank
        ld      hl, LevelIntroTileMapData      ; Tilemap for current level (skip width, height bytes)
        add     hl, 2
        call    CopyIntroTileMapData

; Configure Savepoint credits from level data
        call    SetSavePointCredits

; Setup TileMap palette/screen/definitions
; - Obtain bank number currently mapped into slot 7; required to be restored later
	ld      a,$57                           ; Port to access - Memory Slot 7
        ld      bc,$243B                        ; TBBlue Register Select
        out     (c),a                           ; Select NextReg $1F

        inc     b                               ; TBBlue Register Access
        in      a, (c)
        ld      (BackupByte), a                 ; Save current bank number in slot 7
        
; - Tilemap Palette
        ld      a, $$PaletteData                ; Memory bank (8kb) containing tilemap palette data        
        ld      hl, (LevelDataTileMapDefPalData); Address of first byte of layer 2 palette data
        ld      b, TileMapDefPalRows            ; Number of colours in palette
        call    SetupTileMapPalette

; - Tilemap Screen
        call    SetupTileMapConfig

; - TileMap Definitions
        ld      a, (LevelDataTileMapDefMemBank) ;$$TileMapDef1                 ; Memory bank (8kb) containing tilemap definition data
        ld      b, TileMapDefBlocks             ; Number of blocks to upload
        call    UploadTileBlockPatterns

; Re-Map Slot 7 to original bank number
        ld      a, (BackupByte)
        nextreg $57, a                          ; Re-map memory bank

        ret

;-------------------------------------------------------------------------------------
; Setup Tilemap Configuration
; Parameters:
SetupTileMapConfig:
; ULA CONTROL Register
; TODO - Raster
        ld      a, %1'00'0'1'0'0'0      ; Disable ULA , no stencil mode, other bits to default 0 configs
        nextreg $68, a

;-------------------------------------------------------------------------------------
; Configure TileMap Memory Locations
; Map memory bank to slot 7 ($e000)
; MEMORY MANAGEMENT SLOT 7 BANK Register
; - Map ULA Memory banks 10/11 (16KB) to slots 3/4)
        nextreg $53, 10
        nextreg $54, 11

        ld      a, 0
        call    ClearTileMapScreen

        ;call    ClearULAScreen  ; TODO

; TILEMAP BASE ADDRESS Register
        ld      a, TileMapLocationOffset
        nextreg $6e, a

; TILEMAP DEFINITIONS BASE ADDRESS Register
        ld      bc, TileMapDefLocationOffset
        ld      a, b 
        nextreg $6f, a

;-------------------------------------------------------------------------------------
; Configure Common Tile Attribute and enable TileMap
; 1 x Byte per Tilemap Entry - Configure Common Tilemap Attributes
; TILEMAP ATTRIBUTE Register
        ld      a, (LevelDataPalOffset)
        ld      (CurrentTileMapPal), a
        call    SelectTileMapPalOffset

; TILEMAP CONTROL Register
        ld      a, %1'0'1'0'0'0'0'1     ; Enable tilemap, 40x32, no attributes, primary pal, 256 mode, Tilemap over ULA (can be overidden by tile attribute)
        nextreg $6b, a

/* - Set in AdjustTileMap routine
;-------------------------------------------------------------------------------------
; Configure Clip Window
; CLIP WINDOW TILEMAP Register
; The X coordinates are internally doubled (40x32 mode) or quadrupled (80x32 mode), and origin [0,0] is 32* pixels left and above the top-left ULA pixel
; i.e. Tilemap mode does use same coordinates as Sprites, reaching 32* pixels into "BORDER" on each side.
; It will extend from X1*2 to X2*2+1 horizontally and from Y1 to Y2 vertically.
        nextreg $1c, %0000'1000         ; Reset tilemap clip write index
        nextreg $1b, 0                  ; X1 Position
        nextreg $1b, 159                ; X2 Position
        nextreg $1b, 0                  ; Y1 Position
        nextreg $1b, 255              ; Y2 Position
*/
;-------------------------------------------------------------------------------------
; Configure Tile Offset
; Note: Doesn't change the memory address of the tilemap, only where it's displayed on the screen
; Therefore the top tile of the tilemap will still be located at the start of the tilemap memory even though it might
; be displayed at a different offset on the screen 
; TILEMAP OFFSET X MSB Register
        nextreg $2f,%000000'00          ; Offset 0 
; TILEMAP OFFSET X LSB Register
        nextreg $30,%00000000           ; Offset 0
; TILEMAP OFFSET Y Register
        nextreg $31,%00000000           ; Offset 0

        ret

;-------------------------------------------------------------------------------------
; Setup Tilemap Configuration to Assist Scrolling
; Parameters:
AdjustTileMap:
;-------------------------------------------------------------------------------------
; Configure Clip Window
; CLIP WINDOW TILEMAP Register
; The X coordinates are internally doubled (40x32 mode) or quadrupled (80x32 mode), and origin [0,0] is 32* pixels left and above the top-left ULA pixel
; i.e. Tilemap mode does use same coordinates as Sprites, reaching 32* pixels into "BORDER" on each side.
; It will extend from X1*2 to X2*2+1 horizontally and from Y1 to Y2 vertically.

; Don't display screen as ProcessScreen routine used to configure values
        nextreg $1c, %0000'1000                 ; Reset tilemap clip write index
        ld      a, TileMapXOffsetLeft           ; Hide left column
        nextreg $1b, a                          ; X1 Position
        ld      a, TileMapXOffsetRight          ; Hide right column
        nextreg $1b, a                        ; X2 Position
        ld      a, ClearScreenY1Middle ;TileMapYOffsetTop
        nextreg $1b, a          ; Y1 Position
        ld      a, ClearScreenY2Middle ;TileMapYOffsetBottom        
        nextreg $1b, a       ; Y2 Position

;-------------------------------------------------------------------------------------
; Set Level Scroll Values - Used to restrict scroll if level smaller than actual tilemap
        ld      hl, (LevelDataTileMapData)
        ;dec     hl, hl                  ; Subtract 2 to point to width data
        ld      a, (hl)
        ld      (LevelScrollWidth), a

        inc     hl                      ; Add 1 to point to height data
        ld      a, (hl)
        ld      (LevelScrollHeight), a

;-------------------------------------------------------------------------------------
; Calculate Starting BlockTileMap and Scroll offsets based on starting Player Block
        call    CalcStartingBlockOffsets                

;-------------------------------------------------------------------------------------
; Configure tilemap Scroll Offset
        ld      a, ScrollXStart
        nextreg $2f, 0
        nextreg $30, a
        ld      (ScrollXValue), a

        ld      a, ScrollYStart
        nextreg $31, a
        ld      (ScrollYValue), a

        ret

;-------------------------------------------------------------------------------------
; Calculate Starting Tilemap and Scroll Block Offsets - Based on player starting blocks
; Parameters:
CalcStartingBlockOffsets:
; Calculate Scroll Zone Blocks
        ld      bc, ScreenMiddleX
        ld      hl, ScreenMiddleY
        call    ConvertWorldToBlockOffset

        ld      (ScrollYBlock), de              ; Blocks at which tilemap scrolls

; Check x block
; - Check X Left DeadZone
        ld      de, (PlayerStartXYBlock)        ; d=x, e=y

        ld      a, d                            
        ld      b, a                            ; b=PlayerStartX block
        ld      a, (ScrollXBlock)               ; a=Left ScrollXBlock
        cp      b
        jp      c, .CheckXRightDeadZone         ; Jump if PlayerStartX block > left ScrollXBlock

; - Left dead zone
        ld      a, 0
        ld      (BlockTileMapXBlocksOffset), a
        ld      (ScrollTileMapBlockXPointer), a
        jp      .CheckYBlock

; - Check X Right DeadZone
.CheckXRightDeadZone:
        ld      a, (ScrollXBlock)
        ld      b, a

        ld      a, (LevelScrollWidth)
        sub     b                               
        ld      b, a                            ; b=Right ScrollXBlock                            
        
        ld      a, d                            ; a=PlayerStartX block
        cp      b
        jp      c, .CheckXScrollZone            ; Jump if right ScrollXBlock > PlayerStartX block

; - Right dead zone
        ld      a, (LevelScrollWidth)
        sub     BlockTileMapWidthDisplay

        ld      (BlockTileMapXBlocksOffset), a
        ld      (ScrollTileMapBlockXPointer), a
        jp      .CheckYBlock

; - X Scroll Zone
.CheckXScrollZone:
        ld      a, (ScrollXBlock)
        ld      b, a                            ; b=ScrollXBlock
        ld      a, d                            ; a=PlayerStartX block
        sub     b
        
        ld      (BlockTileMapXBlocksOffset), a
        ld      (ScrollTileMapBlockXPointer), a

; Check y Block
.CheckYBlock:
; - Check Y Top DeadZone
        ld      de, (PlayerStartXYBlock)        ; d=x, e=y

        ld      a, e                            
        ld      b, a                            ; b=PlayerStartY block
        ld      a, (ScrollYBlock)               ; a=Top ScrollYBlock
        cp      b
        jp      c, .CheckYBottomDeadZone        ; Jump if PlayerStartY block > left ScrollYBlock

; - Top dead zone
        ld      a, 0
        ld      (BlockTileMapYBlocksOffset), a
        ld      (ScrollTileMapBlockYPointer), a

        ret

; - Check Y Bottom DeadZone
.CheckYBottomDeadZone:
        ld      a, (ScrollYBlock)
        ld      b, a

        ld      a, (LevelScrollHeight)
        sub     b                               
        ld      b, a                            ; b=Bottom ScrollYBlock

        ld      a, e                            ; a=PlayerStartY block
        cp      b
        jp      c, .CheckYScrollZone            ; Jump if bottom ScrollYBlock > PlayerStartY block

; - Bottom dead zone
        ld      a, (LevelScrollHeight)
        sub     BlockTileMapHeightDisplay

        ld      (BlockTileMapYBlocksOffset), a
        ld      (ScrollTileMapBlockYPointer), a

        ret

; - Y Scroll Zone
.CheckYScrollZone:
        ld      a, (ScrollYBlock)
        ld      b, a                            ; b=ScrollYBlock
        ld      a, e                            ; a=PlayerStartY block
        sub     b
        
        ld      (BlockTileMapYBlocksOffset), a
        ld      (ScrollTileMapBlockYPointer), a

        ret

;-------------------------------------------------------------------------------------
; Copy Tilemap definition data - Contained in blocks
; Parameters:
; - a = Memory Bank containing tilemap definition data
; - b = Number of blocks to import (block = Contains multiple tiles)
UploadTileBlockPatterns:        
; Map memory bank to slot 7 ($e000)
; MEMORY MANAGEMENT SLOT 7 BANK Register
; - Map tilemap definition memory bank to slot 7
        nextreg $57, a                  ; Map ULA memory bank

        ld      ix, TileMapDefSource    ; Source
        ld      iy, TileMapDefLocation  ; Destination

; Upload tilemap defintions contained in blocks
; - 64 pixels/tilemap definition (8 x 8)
; - Tile definitions saved as 4bit = 1 nibble/pixel = 1 byte/2 pixels = 32 bytes/tile definition

.BlockLoop:             ; Number of overall blocks to be imported
        push    bc

        ld      b, BlockHeight
.BlockHeightLoop:       ; Height of block in tiles
        push    bc

        ld      b, TileDefHeight
.TileHeightLoop:        ; Height of tile
        push    bc

        ld      b, BlockWidth
.BlockWidthLoop:        ; Width of block in tiles
        push    bc

        ld      b, TileDefWidth
.TileWidthLoop:         ; Width of tile
        ld      a, (ix)
        ld      (iy), a
        
        inc     ix
        inc     iy
        djnz    .TileWidthLoop

        ld      de, (TileDefHeight*TileDefWidth)-TileDefWidth;64-8
        add     iy, de  ; Destination: Point to next tilemap def

        pop     bc
        djnz    .BlockWidthLoop

        ld      hl, iy
        ld      de, ((TileDefHeight*TileDefWidth)*BlockWidth)-TileDefWidth;(64*2)-8
        sbc     hl, de
        ld      iy, hl  ; Destination: Point to previous tilemap def

        pop     bc
        djnz    .TileHeightLoop
        
        ld      de, TileDefHeight*TileDefWidth;64
        add     iy, de  ; Destination: Point to next tilemap def
        
        pop     bc
        djnz    .BlockHeightLoop

        pop     bc
        djnz    .BlockLoop

; Don't write to Title variable if not on title screen
; Otherwise will end up overwriting code as title mem bank not mapped in
        ld      a, (GameStatus2)
        bit     1, a
        jp      z, .BypassTitleVariable

        ld      (TitleTextTileMapDefsStart), iy

        ret

.BypassTitleVariable:
        call    ClearTileMap

        ret

;-------------------------------------------------------------------------------------
; Copy Tilemap definition data - Standard
; Parameters:
; - a = Memory Bank containing tilemap definition data
; - de = Destination memory location where tilemap definitions should be uploaded
UploadTileDefPatterns:
; Map memory bank to slot 7 ($e000)
; MEMORY MANAGEMENT SLOT 7 BANK Register
; - Map tilemap definition memory bank to slot 6 ($E000..$FFFF)
        nextreg $57, a

; Copy Tilemap Definition Data
        ld      hl, TitleTileMapDef2                            ; Source
        ld      bc, TitleTileMapDef2End-TitleTileMapDef2        ;  Number of tiles
        ldir

        ret

;-------------------------------------------------------------------------------------
; Draw Tilemap from blocks
; Parameters:
DrawTileMap:
        ld      ix, (LevelTileMap)       ; Source
        ld      iy, TileMapLocation     ; Destination

; Source - Width - Update based on BlockTileMap X Block Offset
        ld      de, 0
        ld      a, (BlockTileMapXBlocksOffset)
        ld      e, a
        add     ix, de

; Source - Height - Update based on BlockTileMap Y Block Offset 
        ld      a, (BlockTileMapYBlocksOffset)
        ld      d, a
        ld      e, BlockTileMapWidth
        mul     d, e
        add     ix, de

; Destination - Width - Calculate number of blocks to draw and offset for source
        ld      a, (BlockTileMapXBlocksOffset)
        ld      b, a
        ld      a, BlockTileMapWidth
        sub     b                               ; Calculate number of blocks that can be displayed

        ld      b, a
        ld      a, BlockTileMapWidthDisplay
        cp      b
        jr      nc, .BlockTileMapWidthOK        ; Jump if all blocks can be displayed on line

        ld      (BlockWidthLoopCounter), a
        ld      a, BlockTileMapWidth
        ld      b, BlockTileMapWidthDisplay
        sub     b
        ld      (BlockWidthSourceCounter), a
        
        jr      .CalculateDestHeight

.BlockTileMapWidthOK:
        ld      a, b
        ld      (BlockWidthLoopCounter), a
        ld      a, (BlockTileMapXBlocksOffset)
        ld      (BlockWidthSourceCounter), a

; Destination - Height - Calculate number of blocks to draw and offset for source
.CalculateDestHeight:
        ld      a, (BlockTileMapYBlocksOffset)
        ld      b, a

        ld      a, BlockTileMapHeight
        sub     b                               ; Calculate number of blocks that can be displayed

        ld      b, a
        ld      a, BlockTileMapHeightDisplay
        cp      b
        jr      nc, .BlockTileMapHeightOK        ; Jump if all blocks can be displayed on line

        ld      (BlockHeightLoopCounter), a
        
        jr      .StartDraw

.BlockTileMapHeightOK:
        ld      a, b
        ld      (BlockHeightLoopCounter), a

.StartDraw:        
        ld      a, (BlockHeightLoopCounter);BlockTileMapHeightDisplay
        ld      b, a
.BlockTilemapHeightLoop:       ;Height of tilemap in blocks
        push    bc

        push    iy             ; Destination - Save start of line

        ld      a, (BlockWidthLoopCounter);BlockTileMapWidth
        ld      b, a
.BlockTilemapWidthLoop:        ; Width of tilemap in blocks
        push    bc

        ld      d, (ix)         ; Block number
        ld      e, BlockTiles   ; Number of tiles within block
        mul     d, e            ; Obtain tile definition reference
        ld      a, e            ; a = Starting tile definition

        push    iy              ; Destination - Save for future restore

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

        ld      de, 0
        ld      e, a
        add     iy, de          ; Destination - Point to next line down

        pop     af              ; Restore current tile map definition

        pop     bc
        djnz    .BlockTileHeight

; Move to start of next block on line
        pop     iy              ; Destination - Restore to point to start of current block

        ld      de, BlockWidth
        add     iy, de          ; Destination - Point to start of next block

        inc     ix              ; Source - Point to next tile definition

        pop     bc
        djnz    .BlockTilemapWidthLoop
        
        pop     iy              ; Destination - Restore start of line position

        ld      d, TileMapWidth
        ld      e, BlockHeight
        mul     d, e

        add     iy, de          ; Destination - Point to start of next block line

        ld      d, 0            
        ld      a, (BlockWidthSourceCounter)
        ld      e, a
        add     ix, de          ; Increment source based on whether all blocks have been displayed on line

        pop     bc
        djnz    .BlockTilemapHeightLoop

        ret

;-------------------------------------------------------------------------------------
; Draw Level Intro Tilemap
; Parameters:
DrawLevelIntroTileMap:
	ld	ix, LevelTileMapData    ; Point to data

        ld      hl, 0
        ld      (BackupWord1), hl       ; BlockOffset = 0

	ld	b, 16		        ; Height = 16 blocks
.HeightLoop:
	push	bc

	ld	a, 16
	sub	b
	ld	(BlockWidthLoopCounter), a
	
	ld	b, 20		        ; Width = 20 blocks
	
.WidthLoop:
	push	bc

	ld	a, 20
	sub	b
	ld	h, a		        ; BlockXOffset
	
	ld	a, (BlockWidthLoopCounter)
	ld	l, a		        ; BlockYOffset

        ld      de, (BackupWord1)       ; BlockOffset

	call	UpdateScreenTileMap

        ld      hl, (BackupWord1)
        inc     hl
        ld      (BackupWord1), hl       ; Increment BlockOffset

	pop	bc

	djnz	.WidthLoop	

	pop	bc

	djnz	.HeightLoop

	ret

;-------------------------------------------------------------------------------------
; Clear TileMap
; Parameters:
ClearTileMap:
        ld      hl, TileMapLocation
        ld      (hl), FloorStandardBlock;TileEmpty
        ld      de, TileMapLocation+1
        ld      bc, (TileMapWidth*TileMapHeight)-1
        ldir

        ret

;-------------------------------------------------------------------------------------
; Copy source TileMap data to working TileMap data used during gameplay
; Parameters:
; hl = Source TileMap data
CopyTileMapData:
        ld      de, LevelTileMapData
        ld      bc, LevelTileMapMaxWidth*LevelTileMapMaxHeight
        ldir

        ret

;-------------------------------------------------------------------------------------
; Copy source TileMap data to working TileMap data used during gameplay
; Parameters:
; hl = Source TileMap data
CopyIntroTileMapData:
        ld      de, LevelTileMapData
        ld      bc, LevelIntroTileMapWidth*LevelIntroTileMapHeight
        ldir

        ret

;-------------------------------------------------------------------------------------
; Copy source Waypoint data to working Waypoint data used during gameplay
; Parameters:
; hl = Source Waypoint data
CopyWayPointData:
; 1. Copy source waypoint data --> Working waypoint data
        ld      a, (LevelDataWayPointNumber)
        ld      d, a
        ld      e, S_WAYPOINT_DATA
        mul     d, e

        ld      bc, de
        ld      de, LevelWayPointData
        ldir

; 2. Update working Waypoint data addresses from old source addresses to new working addresses
; (Waypointaddress-source waypoint start address) + working waypoint start address
        ld      ix, LevelWayPointData                   ; Working waypoint start address
        ld      a, (LevelDataWayPointNumber)
        ld      b, a
.NextWayPoint:
; a. CurrentWayPoint
        ld      hl, ix                                  ; Get source waypoint address
        ld      (ix+S_WAYPOINT_DATA.CurrentWayPoint), hl

; b. NextWayPoint
        ld      hl, (ix+S_WAYPOINT_DATA.NextWayPoint)   ; Get source waypoint address
        ld      de, (LevelDataWayPointData)             ; Get source waypoint data start address
        or      a
        sbc     hl,  de                                 ; Subtract source waypoint start address === waypoint offset
        ;ld      de, LevelWayPointData
        add     hl, LevelWayPointData                   ; Add working waypoint start address === Updated waypoint address
        ld      (ix+S_WAYPOINT_DATA.NextWayPoint), hl

        ld      de, S_WAYPOINT_DATA
        add     ix, de
        djnz    .NextWayPoint

        ret

;-------------------------------------------------------------------------------------
; Door - Populate Door Table
; Parameters:
PopulateDoorData:
; Clear table data via DMA
        ld      iy, DoorData

        ld      a, 0
        ld      (iy), a                         ; Set intial value to be copied
        LD      HL, DMADoorDataClear            ; HL = pointer to DMA program
        LD      B, DMADoorDataClearCopySize     ; B = size of the code
        LD      C, $6B                          ; C = $6B (zxnDMA port)
        OTIR                                    ; upload DMA program

        ld      (DoorsInLevel), a               ; Reset door level counter

; Process Map Data 
        ld      hl, (LevelTileMap)       ; Source
        ld      iy, DoorData            ; Destination

        ld      a, 0
        ld      (BlockHeightLoopCounter), a
        
        ld      b, BlockTileMapHeight
.HeightLoop:
        push    bc

        ld      a, 0
        ld      (BlockWidthLoopCounter), a

        ld      b, BlockTileMapWidth
.WidthLoop:
        ld      ix, DoorTypeData        ; Door types

        push    bc

        ld      b, MaxDoorTypes
.CheckDoorType:
; Door - Lower Check
        ld      a, (hl)                 ; Get tilemap block
        ld      d, a
        ld      a, (ix+S_DOOR_TYPE.TileStartValue)
        dec     a
        cp      d
        jp      nc, .NextDoorType       ; Jump if tile (d) <= TileStartvalue-1 (a)

; Door - Upper Check
        ld      a, (ix+S_DOOR_TYPE.TileEndValue)
        cp      d
        jp      c, .NextDoorType        ; Jump if tile (d) > TileEndValue
        
; Door - Found, add to table
; Increment door level counter
        ld      a, (DoorsInLevel)
        inc     a
        ld      (DoorsInLevel),a 

; Calculate/Store block offset        
        call    DoorCalculateTileMapOffset

; Store tile pattern start/end values
        ld      a, (hl)                 ; Get tilemap block
        ld      (iy+S_DOOR_DATA.TileBlockStartValue), a

        ld      a, (ix+S_DOOR_TYPE.TileEndValue)
        ld      (iy+S_DOOR_DATA.TileBlockEndValue), a

; Store door type
        ld      a, (ix+S_DOOR_TYPE.DoorType)
        ld      (iy+S_DOOR_DATA.DoorType), a

/* - 09/04/23 - No longer necessary as dedicated door type assigned to trigger door
; - Check whether door should be configured with a trigger lock
        push    ix, iy, hl
        ld      hl, de                                  ; de set within DoorCalculateTileMapOffset
        call    SearchTriggerTargetData                 ; Search for door offset in TriggerTarget data
        pop     hl, iy, ix

        cp      0
        jp      z, .ContDoorConfig                      ; Jump if door offset not found

        ld      a, (iy+S_DOOR_DATA.DoorType)
        xor     TriggerDoorType                         ; Otherwise configure door with trigger lock
        ld      (iy+S_DOOR_DATA.DoorType), a

.ContDoorConfig:
*/

; Store animation pattern
        ld      de, (ix+S_DOOR_TYPE.TilePattern)
        ld      (iy+S_DOOR_DATA.TilePattern), de

; Store animation counter
        ld      a, (de)                                 ; Get pattern animation counter
        ld      (iy+S_DOOR_DATA.TileBlockCounter), a    ; Set tile animation counter

        ld      a, S_DOOR_DATA
        ld      d, 0
        ld      e, a
        add     iy, de                                  ; Point to next entry within door table

        jp      .NextDoor

.NextDoorType:
        ld      d, 0
        ld      a, S_DOOR_TYPE
        ld      e, a
        add     ix, de                  ; Point to next door type

        djnz    .CheckDoorType

.NextDoor:
        pop     bc

        inc     hl                      ; Point to next tile within tilemap

        ld      a, (BlockWidthLoopCounter)
        inc     a
        ld      (BlockWidthLoopCounter), a

        djnz    .WidthLoop

        ld      a, (BlockHeightLoopCounter)
        inc     a
        ld      (BlockHeightLoopCounter), a

        pop     bc

        dec     b
        ld      a, b
        cp      0
        jp      nz, .HeightLoop

        ret

;-------------------------------------------------------------------------------------
; Door - Calculate Tilemap Offset
; Note: Called by PopulateDoorData
DoorCalculateTileMapOffset:
; Calculate/Store block offset        
        ld      a, (BlockHeightLoopCounter)
        ld      (iy+S_DOOR_DATA.TileBlockOffsetY), a
        ld      d, a
        ld      a, BlockTileMapWidth
        ld      e, a
        mul     d, e                    ; Calculate offset

        ld      a, (BlockWidthLoopCounter)
        ld      (iy+S_DOOR_DATA.TileBlockOffsetX), a
        add     de, a                   ; Add column offset

        ld      (iy+S_DOOR_DATA.TileBlockOffset), de

        ret

;-------------------------------------------------------------------------------------
; Enemy Spawn Point - Populate Spawn Point Table
; Parameters:
PopulateSpawnPointData:
; Clear table data via DMA
        ld      iy, SpawnPointData              ; Destination
        ld      a, 0
        ld      (iy), a                         ; Set intial value to be copied
        LD      HL, DMASpawnPointDataClear	; HL = pointer to DMA program
        LD      B, DMASpawnPointDataClearCopySize     ; B = size of the code
        LD      C, $6B                          ; C = $6B (zxnDMA port)
        OTIR                                    ; upload DMA program

        ld      (SpawnPointsInLevel), a		; Reset spawn point level counter

; Process SpawnPoint Source Data
        ld      a, (LevelDataSpawnPointNumber)
        cp      0
        ret     z                               ; Return if no spawn points

        ld      b, a

        ld      ix, (LevelDataSpawnPointData)
        ld      iy, SpawnPointData

.SpawnPointCopyLoop:
        push    bc

        ld      a, 1
        ld      (iy+S_SPAWNPOINT_DATA.Active), a

; Store world coordinates
        ld      bc, (ix+S_SPAWNPOINTASM_DATA.WorldX)
        ld      (iy+S_SPAWNPOINT_DATA.WorldX), bc

        ld      hl, (ix+S_SPAWNPOINTASM_DATA.WorldY)
        ld      (iy+S_SPAWNPOINT_DATA.WorldY), hl

; Calculate/Store block offsets        
        call    ConvertWorldToBlockOffset

        ld      (iy+S_SPAWNPOINT_DATA.TileBlockOffset), bc
        ld      (iy+S_SPAWNPOINT_DATA.TileBlockOffsetY), de

; Write spawn point tile onto tilemap
        ld      hl, (LevelTileMap)
        add     hl, bc                                  ; Point to tilemap offset

; - Check which spawnpoint tile block should be written to tilemap
        ld      a, (ix+S_SPAWNPOINTASM_DATA.DisableAtStart)
        cp      0
        jp      z, .SetEnabledTile                      ; Jump if spawnpoint not disabled at start

        ld      a, SpawnPointDisabledBlock              ; Write disabled spawnpoint tile
        jp      .WriteTile

.SetEnabledTile:
; - Check which spawnpoint block should be displayed
        ld      a, (ix+S_SPAWNPOINTASM_DATA.Reuse)
        cp      1
        jp      z, .SpawnPoint1                         ; Jump if spawnpoint configured for reuse

        ld      a, SpawnPoint2StartBlock

        jp      .WriteTile

.SpawnPoint1:
        ld      a, SpawnPoint1StartBlock

.WriteTile:
        ld      (hl), a                                 ; Write spawn point tile block to tilemap

; Store enemy type + bullet type
        ld      de, (ix+S_SPAWNPOINTASM_DATA.EnemyType)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyType), de

        ld      de, (ix+S_SPAWNPOINTASM_DATA.BulletType)
        ld      (iy+S_SPAWNPOINT_DATA.BulletType), de

; Store enemyplayerrange + playerrange
        ld      de, (ix+S_SPAWNPOINTASM_DATA.EnemyPlayerRange)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyPlayerRange), de
        ld      de, (ix+S_SPAWNPOINTASM_DATA.PlayerRange)
        ld      (iy+S_SPAWNPOINT_DATA.PlayerRange), de

; Store max enemies
        ld      a, (ix+S_SPAWNPOINTASM_DATA.MaxEnemies)
        ld      (iy+S_SPAWNPOINT_DATA.MaxEnemies), a

; Store spawn delay
        ld      a, (ix+S_SPAWNPOINTASM_DATA.SpawnDelay)
        ld      (iy+S_SPAWNPOINT_DATA.SpawnDelay), a

; Store enemy energy + damage + disable reset timeout
        ld      a, (ix+S_SPAWNPOINTASM_DATA.EnemyEnergy)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyEnergy), a

        ld      a, (ix+S_SPAWNPOINTASM_DATA.EnemyDamage)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyDamage), a

        ld      a, (ix+S_SPAWNPOINTASM_DATA.EnemyDisableTimeout)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyDisableTimeout), a

; Store spawnpoint energy
        ld      hl, (ix+S_SPAWNPOINTASM_DATA.Energy)
        ld      (iy+S_SPAWNPOINT_DATA.Energy), hl

; Store reuse
        ld      a, (ix+S_SPAWNPOINTASM_DATA.Reuse)
        ld      (iy+S_SPAWNPOINT_DATA.Reuse), a

; Store disableAtStart
        ld      a, (ix+S_SPAWNPOINTASM_DATA.DisableAtStart)
        ld      (iy+S_SPAWNPOINT_DATA.DisableAtStart), a

; Store RecordSpawned
        ld      a, (ix+S_SPAWNPOINTASM_DATA.RecordSpawned)
        ld      (iy+S_SPAWNPOINT_DATA.RecordSpawned), a

; Store Flee flag
        ld      a, (ix+S_SPAWNPOINTASM_DATA.Flee)
        ld      (iy+S_SPAWNPOINT_DATA.Flee), a

; Store Spawn flag
        ld      a, (ix+S_SPAWNPOINTASM_DATA.Spawn)
        ld      (iy+S_SPAWNPOINT_DATA.Spawn), a

; Check difficulty and override values
        ld      a, (GameStatus2)
        bit     4, a
        jp      z, .BypassHardValues                    ; Jump if not hard difficulty

; - Override with hard values
        ld      a, (ix+S_SPAWNPOINTASM_DATA.MaxEnemiesHard)
        ld      (iy+S_SPAWNPOINT_DATA.MaxEnemies), a

        ld      a, (ix+S_SPAWNPOINTASM_DATA.SpawnDelayHard)
        ld      (iy+S_SPAWNPOINT_DATA.SpawnDelay), a

        ld      a, (ix+S_SPAWNPOINTASM_DATA.EnemyEnergyHard)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyEnergy), a

        ld      a, (ix+S_SPAWNPOINTASM_DATA.EnemyDamageHard)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyDamage), a

        ld      a, (ix+S_SPAWNPOINTASM_DATA.EnemyDisableTimeoutHard)
        ld      (iy+S_SPAWNPOINT_DATA.EnemyDisableTimeout), a

        ld      hl, (ix+S_SPAWNPOINTASM_DATA.EnergyHard)
        ld      (iy+S_SPAWNPOINT_DATA.Energy), hl

.BypassHardValues:
        ld      a, (SpawnPointsInLevel)
        inc     a
        ld      (SpawnPointsInLevel), a

        ld      bc, S_SPAWNPOINTASM_DATA
        add     ix, bc
        ld      bc, S_SPAWNPOINT_DATA
        add     iy, bc
        
        pop     bc
        
        dec     b
        ld      a, b
        cp      0
        jp      nz, .SpawnPointCopyLoop

        ret

;-------------------------------------------------------------------------------------
; Door - Check for Door
; Params:
; bc - Tile Offset to Search for
; Return:
; a - 0 - No movement permitted, 1 - Movement permitted
; bc - Offset of door opened
DoorCheckType:
; Check whether DoorLockdown is enabled
        ld      a, (DoorLockdown)
        cp      0
        jp      z, .ContDoorCheck       ; Jump if DoorLockdown not enabled

        ld      a, 0                    ; Return value
        ret

.ContDoorCheck:
        ld      de, bc                  ; Offset to search for
        ld      ix, DoorData

        ld      b, MaxDoors
.SearchDoorTable:
        ld      hl, (ix+S_DOOR_DATA.TileBlockOffset)
        or      a
        sbc     hl, de
        jp      z, .FoundDoor

        push    de
        ld      d, 0
        ld      e, S_DOOR_DATA
        add     ix, de                  ; Point to next entry within door table
        pop     de

        djnz    .SearchDoorTable

; Door not found
        ld      a, 0                    ; Return Value - a = 0 - Don't pass througb door; door not found
        ld      bc, 0                   ; Return Value - bc = 0 - Door not found
        ret

; Check door type
.FoundDoor:
        ld      a, (ix+S_DOOR_DATA.DoorType)

; Check whether door open
        bit     6, a
        jp      nz, .Movement           ; Jump if door open - No need to change door type

; Check whether door opening
        bit     5, a
        jp      nz, .Movement           ; Jump if door opening - No need to change door type

; Check whether door closed
        bit     4, a
        jp      nz, .OpenDoor           ; Jump if door closed - Need to change door type

; Check whether door closing
        bit     3, a
        jp      nz, .NoMovement         ; Jump if door closing; no need to change door type

; Otherwise
        ld      a, 0                    ; Return Value - a = 0 - Don't pass through door
        ret

; Allow movement through door
.Movement:
        ld      a, 1                                    ; Return Value - a = 1 - Pass through door
        ld      bc, (ix+S_DOOR_DATA.TileBlockOffset)    ; Return Value - bc = door offset
        ret

; Prevent movement through door
.NoMovement:
        ld      a, 0                    ; Return Value - a = 0 - Don't pass through door
        ld      bc, (ix+S_DOOR_DATA.TileBlockOffset)    ; Return Value - bc = door offset
        ret

; Update door type
.OpenDoor:
; Check whether door locked
        bit     2, a                    
        jp      z, .ContOpen            ; Jump if door not locked

; Locked - Check type 1 lock
        and     %00000011               ; Obtain door key bits

        cp      1
        jp      nz, .NoMovement         ; Jump if trigger lock on door

; Locked - Type 1 lock
        ld      a, (PlayerType1Keys)
        cp      0
        jp      z, .NoMovement          ; Jump if player has no key and cannot open door

        ld      (LastDoorPlayerUnlocked), ix     ; Save memory of last door player unlocked; used for door lockdown

        dec     a
        ld      (PlayerType1Keys), a    ; Remove key from player

; Update key HUD values
        ld      b, HUDKeyValueDigits
        ld      d, a
        ld      a, (HUDKeyValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites           ; Update HUD values

.Unlocked:
        ld      a, (ix+S_DOOR_DATA.DoorType)

.ContOpen:
; Update door type
        and     %11111'000              ; Reset locked status; enabling door to open/close

        res     4, a                    ; Door - Clear closed flag
        set     5, a                    ; Door - Set opening flag

        ld      (ix+S_DOOR_DATA.DoorType), a

        bit     7, (ix+S_DOOR_DATA.DoorType)
        jp      z, .VerticalLocked

; - Horizontal locked door
        ld      hl, Door1HorTypeBlockPattern            ; Change to hor unlocked animation

        jp      .ContOpenEnd

; - Vertical locked door
.VerticalLocked:
        ld      hl, Door1VerTypeBlockPattern            ; Change to ver unlocked animation

.ContOpenEnd:
        ld      (ix+S_DOOR_DATA.TilePattern), hl        ; Change animation
        inc     hl

        ld      a, (hl)                                 ; Get first frame in animation

; Source Tilemap - Replace door block
        ld      de, (ix+S_DOOR_DATA.TileBlockOffset)    ; Parameter - de = Block offset
        ld      hl, (LevelTileMap)
        add     hl, de

        ld      (hl), a

; Screen TileMap - Update display
        ld      h, (ix+S_DOOR_DATA.TileBlockOffsetX)    ; Parameter - hl = x block offset, y block offset
        ld      l, (ix+S_DOOR_DATA.TileBlockOffsetY)    ; Parameter - hl = x block offset, y block offset

        push    ix                                  ; Save sprite pointer, TileMap Offset
        call    UpdateScreenTileMap

        pop     ix

        ld      a, 1                    ; Return Value - a = 1 - Pass through door
        ld      bc, (ix+S_DOOR_DATA.TileBlockOffset)    ; Return Value - bc = door offset
        ret

;-------------------------------------------------------------------------------------
; Door - Process doors - Enemy opening/closing of doors + playing player/enemy door animations
; Params:
; Return:
DoorProcess:
; Note: Don't check for DoorLockdown, as routine required for closing locked doors and allowing
;       enemies to open unlocked doors

        ld      ix, DoorData

        ld      a, (DoorsInLevel)
        cp      0
        ret     z                       ; Return if no doors in level

        ld      b, a
.SearchDoorTable:
        push    ix, bc

        ld      a, (ix+S_DOOR_DATA.DoorType)
        cp      0
        jp      z, .NextDoor            ; Jump if door type is 0 i.e. No door defined

; Check whether door is locked
        bit     2, a                    
        jp 	z, .UnlockedDoor        ; Call if door not locked

; Locked door
; - Check whether locked door is open
        bit     6, a
        jp      nz, .NextDoor           ; Jump if locked door already open

; - Check lock type
        and     %00000011               ; Obtain door key bits

        cp      1
        jp      z, .DoorAnimation       ; Jump if lock type 1

; Trigger Door Lock
; - Trigger Condition - Check TriggerTarget
        ld      hl, (ix+S_DOOR_DATA.TileBlockOffset)
        push    ix
        call    CheckTriggerTargetData
        pop     ix

        cp      0
        jp      z, .NextDoor            ; Jump if trigger condition not met and cannot open door

; - Update door type
        ld      a, (ix+S_DOOR_DATA.DoorType)

        and     %11111'000              ; Reset locked status; enabling door to open/close

        ;;;res     4, a                    ; Door - Clear closed flag
        ;;;set     5, a                    ; Door - Set opening flag

        ;;;res     1, a                    ; Door - Reset locked type 2 flag; ensures door is not treated again as trigger door
        ;;;set     0, a                    ; Door - Set locked type 1 flag; ensures door is not treated again as trigger door

        ld      (ix+S_DOOR_DATA.DoorType), a

        ld      bc, (ix+S_DOOR_DATA.TileBlockOffset)
        ld      hl, (LevelTileMap)
        add     hl, bc

        ld      a, (hl)
        cp      HorDoorTrigger
        jp      nz, .VerDoorTrigger

; - Horizontal trigger door
        ld      de, Door1HorTypeBlockPattern            ; Change to hor unlocked animation

        ;;;ld      a, HorDoorTriggerLockedDoor
        ;;;ld      (hl), a
        ;;;jp      .DoorAnimation

        jp      .ContOpenEnd

; - Vertical trigger door
.VerDoorTrigger:
        ld      de, Door1VerTypeBlockPattern            ; Change to ver unlocked animation

        ;;;ld      a, VerDoorTriggerLockedDoor
        ;;;ld      (hl), a
        ;;;jp      .DoorAnimation

.ContOpenEnd:
        ld      (ix+S_DOOR_DATA.TilePattern), de        ; Change animation
        inc     de

        ld      a, (de)                                 ; Get first frame in animation

; Source Tilemap - Replace door block

        ld      (hl), a

; Screen TileMap - Update display
        ld      de, bc                                  ; Parameter - de = Block offset

        ld      h, (ix+S_DOOR_DATA.TileBlockOffsetX)    ; Parameter - hl = x block offset, y block offset
        ld      l, (ix+S_DOOR_DATA.TileBlockOffsetY)    ; Parameter - hl = x block offset, y block offset

        push    ix                                  ; Save sprite pointer, TileMap Offset
        call    UpdateScreenTileMap

        pop     ix

        jp      .NextDoor

.UnlockedDoor:
        call 	DoorUpdateStatus     

; - Play door animation
.DoorAnimation:
        call	DoorPlayAnimation

.NextDoor:
        pop     bc, ix

        ld      d, 0
        ld      e, S_DOOR_DATA
        add     ix, de                  ; Point to next entry within door table

        dec     b

        jp      nz, .SearchDoorTable
        ;;;djnz    .SearchDoorTable

        ret

;-------------------------------------------------------------------------------------
; Door - Check/Update opening/closing of doors via enemies
; Note: The opening/closing of doors via the player is performing using player code
; Params:
; ix = S_DOOR_DATA
DoorUpdateStatus:
; Check whether player has already opened door
        or      a
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.DoorVerBlockOffset)
        ld      de, (ix+S_DOOR_DATA.TileBlockOffset)
        sbc     hl, de
        ret     z                       ; Return as player opened door, so player code should control door

        or      a
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.DoorHorBlockOffset)
        ld      de, (ix+S_DOOR_DATA.TileBlockOffset)
        sbc     hl, de
        ret     z                       ; Return as player opened door, so player code should control door

; Player not opened door - Check status of door tile within EnemyMovementBlockMap
        ld      de, (ix+S_DOOR_DATA.TileBlockOffset)
        call    EnemyGetBlockMapBit     ; Get updated byte

; Check whether byte has changed i.e. Is the block occupied
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .Unoccupied          ; Jump if source block bit not set i.e. Unoccupied

        jp      .DoorTileContainsEntity

.Unoccupied:
; Door tile does not contain enemy
; - Check whether door open
        bit     6, (ix+S_DOOR_DATA.DoorType)
        jp      nz, .CloseDoor          ; Jump if door open - Close door

        bit     5, (ix+S_DOOR_DATA.DoorType)
        jp      nz, .CloseDoor          ; Jump if door opening - Close door

        ret

; Door tile contains enemy
.DoorTileContainsEntity:
; - Check whether door closed
        bit     4, (ix+S_DOOR_DATA.DoorType)
        jp      nz, .OpenDoor          ; Jump if door closed - Open door

        bit     3, (ix+S_DOOR_DATA.DoorType)
        jp      nz, .OpenDoor          ; Jump if door closing - Open door

        ret

.OpenDoor:
; Update door type
        ld      a, (ix+S_DOOR_DATA.DoorType)
        res     4, a                    ; Door - Clear closed flag
        res     3, a                    ; Door - Clear closing flag
        set     5, a                    ; Door - Set opening flag
        ld      (ix+S_DOOR_DATA.DoorType), a
        
        ret

.CloseDoor:
; Update door type
        ld      a, (ix+S_DOOR_DATA.DoorType)
        res     6, a                    ; Door - Reset open flag
        res     5, a                    ; Door - Reset opening flag
        set     3, a                    ; Door - Set closing flag
        ld      (ix+S_DOOR_DATA.DoorType), a

        ret

;-------------------------------------------------------------------------------------
; Door - Play door animations
; Params:
; ix = S_DOOR_DATA
DoorPlayAnimation:
        ld      a, (ix+S_DOOR_DATA.DoorType)

; Check whether door opening
        bit     5, a
        jp      nz, .DoorOpening        ; Jump if door opening

; Check whether door closing
        bit     3, a
        jp      nz, .DoorClosing        ; Jump if door closing

        ret

; Process door opening
.DoorOpening:
        ld      bc, (ix+S_DOOR_DATA.TileBlockOffset)    ; Parameter - Tile block offset
        ld      d, 0                                    ; Parameter - Direction - Animate forward
        ld      a, (ix+S_DOOR_DATA.TileBlockCounter)
        ld      e, a                                    ; Parameter - Animation counter
        ld      hl, (ix+S_DOOR_DATA.TilePattern)        ; Parameter - Door pattern reference

        call    UpdateTileMaps                          ; Update block within block tilemap & update screen tilemap as appropriate

        ld      (ix+S_DOOR_DATA.TileBlockCounter), a    ; Return - Update counter

        ld      a, b                                    ; Return - Animation status
        cp      1
        ret     nz                                      ; Return if animation has not finished

; Animation Finished - Update door type
        ld      a, (ix+S_DOOR_DATA.DoorType)
        set     6, a                            ; Set open door
        res     5, a                            ; Reset opening door
        ld      (ix+S_DOOR_DATA.DoorType), a
        
        ret

; Process door closing
.DoorClosing:
        ld      bc, (ix+S_DOOR_DATA.TileBlockOffset)    ; Parameter - Tile block offset
        ld      d, 1                                    ; Parameter - Direction - Animate backward
        ld      a, (ix+S_DOOR_DATA.TileBlockCounter)
        ld      e, a                                    ; Parameter - Animation counter

        ld      hl, (ix+S_DOOR_DATA.TilePattern)        ; Parameter - Door pattern reference

        call    UpdateTileMaps                          ; Update block within block tilemap & update screen tilemap as appropriate

        ld      (ix+S_DOOR_DATA.TileBlockCounter), a    ; Return - Update counter

        ld      a, b                                    ; Return - Animation status
        cp      1
        ret     nz                                      ; Jump if animation has not finished

; Animation Finished - Update door type
        ld      a, (ix+S_DOOR_DATA.DoorType)
        set     4, a                            ; Set close door
        res     3, a                            ; Reset closing door
        ld      (ix+S_DOOR_DATA.DoorType), a
        
        ret

;-------------------------------------------------------------------------------------
; Door - Update block within block tilemap + Update tiles within screen tilemap
; Params:
; bc - Tile Block Offset
; hl - Tile block Pattern Reference
; d - Direction - 0 - Forward, 1 - Back
; e - Counter
; Return:
; a - Counter
; b - Animation complete (0=Incomplete, 1 = Complete)
UpdateTileMaps:        
        push    hl

        ld      hl, (LevelTileMap)
        add     hl, bc
        ld      bc, hl                  ; Point to block within block tilemap
        ;add     bc, (LevelTileMap)       ; Point to block within block tilemap
        
        pop     hl

        ld      a, e                    ; Obtain counter
        cp      0
        jp      z, .ProcessAnimation    ; Jump if counter = 0

; Decrement counter and don't update block/tile
        dec     a                       ; Decrement counter - Return - Counter
        ld      b, 0                    ; Return - Incomplete animation
        ret

.ProcessAnimation:
        ld      a, d                    ; Obtain direction
        cp      1
        jp      z, .AnimateBack         ; Jump if animate back

; --- Animate Forward
        inc     hl
        inc     hl                      ; Point to end block

        ld      a, (bc)                 ; Obtain block
        cp      (hl)                    ; Compare block with end block
        jp      nz, .IncrementTile      ; Jump if block != end block

; End of animation reached
        inc     hl                      ; Point to loop value
        
        ld      a, (hl)                 ; Obtain loop value
        cp      0
        jp      z, .DoNotLoop           ; Jump if animation should not loop

; Loop Animation - TODO - If required
        ret

; Point to next block in animation
.IncrementTile:
        inc     a                       ; Increment block
        ld      (bc), a                 ; Update block tilemap

        push    ix, hl
        ld      h, (ix+S_DOOR_DATA.TileBlockOffsetX)
        ld      l, (ix+S_DOOR_DATA.TileBlockOffsetY)
        ld      de, (ix+S_DOOR_DATA.TileBlockOffset)
        call    UpdateScreenTileMap     ; Check/update tiles within screen tilemap
        pop     hl, ix

; - Check whether door has been updated/visible on screen
        ld      a, (BackupByte)
        cp      0                       
        jp      z, .BypassSound         ; Jump if door not updated/visible on screen

; Play audio effect
        push    af, ix, hl

        ld      a, AyFXDoorOpen
        call    AFX1Play

        pop     hl, ix, af

.BypassSound:
        dec     hl
        dec     hl                      ; Point to counter

        ld      a, (hl)                 ; Return - Start counter
        ld      b, 0                    ; Return - Incomplete animation
        ret

; --- Animate Back
.AnimateBack:
        inc     hl                      ; Point to first block

        ld      a, (bc)                 ; Obtain block
        cp      (hl)                    ; Compare block with first block
        jp      nz, .DecrementTile      ; Jump if block != start block

; End of animation reached
        inc     hl
        inc     hl                      ; Point to loop value
        
        ld      a, (hl)                 ; Obtain loop value
        cp      0
        jp      z, .DoNotLoop           ; Jump if animation should not loop

; Loop Animation - TODO - If required
        ret

; Point to next block in animation
.DecrementTile:
        dec     a                       ; Decrement block
        ld      (bc), a                 ; Update block tilemap

        push    ix, hl
        ld      h, (ix+S_DOOR_DATA.TileBlockOffsetX)
        ld      l, (ix+S_DOOR_DATA.TileBlockOffsetY)
        ld      de, (ix+S_DOOR_DATA.TileBlockOffset)
        call    UpdateScreenTileMap     ; Check/update tiles within screen tilemap
        pop     hl, ix

        dec     hl                      ; Point to counter

        ld      a, (hl)                 ; Return - Start counter
        ld      b, 0                    ; Return - Incomplete animation
        ret

.DoNotLoop:
        ld      a, 0                    ; Return - Counter = 0
        ld      b, 1                    ; Return - Complete animation

        ret

;-------------------------------------------------------------------------------------
; Check/Update screen tilemap with tiles from specified block within block tilemap
; Params:
; hl - h = BlockXOffset, l = BlockYOffset
; de - BlockOffset
; Return:
; BackupByte - 0 = Screen not updated, 1 = Screen updated
UpdateScreenTileMap:
; Assume screen is not updated - Used for audio checks
        ld      a, 0
        ld      (BackupByte), a

; 1. Check tile block is visible on screen
; - Check X Position
        ld      a, (ScrollTileMapBlockXPointer)
        ld      b, a
        ld      a, h                                    ; BlockXOffset
        sub     b
        ret     m                                       ; Return if block offset is negative i.e. block is to the left of the left-screen edge

        cp      TileMapWidth/BlockWidth;-1
        jp      c, .CheckY                              ; Jump if TileMapWidth/BlockWidth > block Offset i.e. Block is to the left of the right-screen edge

        ret                                             ; Block not visible on screen, so don't update screen tiles

; - Check Y Position
.CheckY:
        ld      h, a                                    ; Save x block Offset

        ld      a, (ScrollTileMapBlockYPointer)
        ld      b, a
        ld      a, l                                    ; BlockYOffset
        sub     b
        ret     m                                       ; Return if block offset is negative i.e. block is above the top-screen edge

        cp      TileMapHeight/BlockHeight;-1
        jp      c, .BlockOnScreen                       ; Jump if TileMapHeight/BlockHeight > block Offset i.e. Block is above the bottom-screen edge

        ret                                             ; Block not visible on screen, so don't update screen tiles

.BlockOnScreen:
; 2. Convert tile block offset to tile screen offset 
        ld      l, a                                    ; Save y block offset
        sla     h                                       ; Multiply x block offset by 2 to get screen offset
        sla     l                                       ; Multiply y block offset by 2 to get screen offset

; 3. Update screen tiles
; - Source - Point to tilemap block to be displayed on screen
        ld      ix, (LevelTileMap)
        add     ix, de                                  ; Add blockoffset to source

; - Destination - Point to tilemap screen address to be written to
        ld      iy, TileMapLocation
        ld      d, TileMapWidth
        ld      a, l
        ld      e, a                                    ; y screen offset
        mul     d, e                                    ; Calculate y offset

        ld      a, h                                    ; x screen offset
        add     de, a                                   ; Add x to y offset

        add     iy, de                                  ; Add offset to screen tilemap address
        
; Copy block tiles to screen tilemap
        ld      d, (ix)                                 ; Block number
        ld      e, BlockTiles                           ; Number of tiles within block
        mul     d, e                                    ; Obtain tile definition reference
        ld      a, e                                    ; a = Starting tile definition

        ld      b, BlockHeight
.BlockTileHeight:                                       ; Height of tiles within block
        push    bc

        ld      b, BlockWidth
.BlockTileWidth:
        ld      (iy), a                                 ; Write new tile to screen tilemap

        inc     a                                       ; Point to next tilemap definition
        inc     iy                                      ; Point to next tilemap screen destination

        djnz    .BlockTileWidth
        
; Move to next tilemap line down
        push    af

        ld      a, TileMapWidth
        sub     BlockWidth

        ld      d, 0
        ld      e, a
        add     iy, de                                  ; Destination - Point to next line down

        pop     af                                      ; Restore current tile map definition

        pop     bc
        djnz    .BlockTileHeight

; Used for audio checks
        ld      a, 1                                    ; Return - Screen updated
        ld      (BackupByte), a
        ret

;-------------------------------------------------------------------------------------
; Replace finish blocks with Enable Finish blocks
; Params:
; 
UpdateFinishBlocks:
; 1. Update Finish Centre
        ld      hl, (LevelTileMap)
	ld	bc, (FinishBlockOffset)
        add     hl, bc                          ; hl = Block to update

	ld	a, FinishEnableCentreBlock
        ld      (hl), a				; Update block

        ld      hl, (FinishBlockXY)
        ld      de, (FinishBlockOffset)

        call    UpdateScreenTileMap

        ret
        
/* 06/05/23 - No longer required
; 2. Update Above Finish Centre
        ld      hl, (LevelTileMap)

	ld	bc, (FinishBlockOffset)
	add	bc, -LevelTileMapMaxWidth 	; Point to line above offset

        add     hl, bc                          ; hl = Block to update
	
	ld	a, FinishEnableSurroundBlock
        ld      (hl), a				; Update block

        ld      hl, (FinishBlockXY)
	dec	l				; Point to line above offset (y=y-1)
        ld      de, bc				; Updated offset

        call    UpdateScreenTileMap

; 3. Update Below Finish Centre
        ld      hl, (LevelTileMap)

	ld	bc, (FinishBlockOffset)
	add	bc, LevelTileMapMaxWidth 	; Point to line below offset

        add     hl, bc                          ; hl = Block to update
	
	ld	a, FinishEnableSurroundBlock
        ld      (hl), a				; Update block

        ld      hl, (FinishBlockXY)
	inc	l				; Point to line below offset (y=y+1)
        ld      de, bc				; Updated offset

        call    UpdateScreenTileMap

; 4. Update Left of Finish Centre
        ld      hl, (LevelTileMap)

	ld	bc, (FinishBlockOffset)
        dec     bc                              ; Point to left of offset

        add     hl, bc                          ; hl = Block to update
	
	ld	a, FinishEnableSurroundBlock
        ld      (hl), a				; Update block

        ld      hl, (FinishBlockXY)
	dec	h				; Point to left of offset (x=x-1)
        ld      de, bc				; Updated offset

        call    UpdateScreenTileMap

; 4. Update Right of Finish Centre
        ld      hl, (LevelTileMap)

	ld	bc, (FinishBlockOffset)
        inc     bc                              ; Point to right of offset

        add     hl, bc                          ; hl = Block to update
	
	ld	a, FinishEnableSurroundBlock
        ld      (hl), a				; Update block

        ld      hl, (FinishBlockXY)
	inc	h				; Point to right of offset (x=x+1)
        ld      de, bc				; Updated offset

        call    UpdateScreenTileMap

	ret
*/

;-------------------------------------------------------------------------------------
; Door - Check/Close Door
; Params:
; de - Entity offset
; Return:
; de - Updated offset
DoorClose:
; Check current entity door offset
        or      a
        ld      hl, 0                           ; 0 = No door offset
        sbc     hl, de
        ret     z                               ; Return if no door offset i.e No door to close

; Find door to close
        ld      iy, DoorData

        ld      b, MaxDoors
.SearchDoorTable:
        or      a
        ld      hl, (iy+S_DOOR_DATA.TileBlockOffset)
        sbc     hl, de
        jp      nz, .NextDoor                   ; Jump if entity offset != door offset i.e No need to process door

; Door Found - Check whether door is open
        ld      a, (iy+S_DOOR_DATA.DoorType)
        bit     6, a
        ret     z                               ; Return if door not open i.e. No need to close - x Return parameter de remains the same

; Check whether door previously locked
        bit     2, (iy+S_DOOR_DATA.DoorType)
        jp      z, .CloseDoor                   ; Jump if door not previously locked

        ld      de, 0                           ; Return parameter
        ret

; Close open door - Only close door if door not previously locked i.e. Don't close an unlocked door
.CloseDoor:
        res     6, a                            ; Reset open door
        set     3, a                            ; Set closing door
        ld      (iy+S_DOOR_DATA.DoorType), a

        ld      de, 0                           ; Return parameter
        ret

.NextDoor:
        push    de

        ld      d, 0
        ld      e, S_DOOR_DATA
        add     iy, de                          ; Point to next entry within door table

        pop     de

        djnz    .SearchDoorTable

        ret

;-------------------------------------------------------------------------------------
; Blocks - Process animations
; Note: Only performs forward animation of blocks; don't use for hazard blocks (processed elsewhere)
; Parameters:
; a - Number of block animations to process
BlockProcessAnimations:
        cp      0
        ret     z                                       ; Return if no animations to process

        ld      ix, BlockAnimations

        ld      b, a
.BlockAnimationLoop:
        push    bc

; Check whether we need to update the blocks
        ld      a, (ix+S_BLOCK_ANIMATION.DelayCounter)
        cp      0
        jp      nz, .UpdateCounter                      ; Jump if we need to update the blocks
        
        call    BlockAnimateForward

        ld      a, (ix+S_BLOCK_ANIMATION.Delay)
        ld      (ix+S_BLOCK_ANIMATION.DelayCounter), a       ; Reset block animation counter

        jp      .NextBlockAnimation

.UpdateCounter:
        dec     a
        ld      (ix+S_BLOCK_ANIMATION.DelayCounter), a

.NextBlockAnimation:
        ld      de, S_BLOCK_ANIMATION
        add     ix, de                                  ; Point to next block animation data

        pop     bc
        djnz    .BlockAnimationLoop

        ret

;-------------------------------------------------------------------------------------
; Blocks - Animate Forward
; Params:
; ix - Block Animation
; Return:
BlockAnimateForward:
; Point to start block tile definitions
        ld      d, BlockSize
        ld      e, (ix+S_BLOCK_ANIMATION.StartBlock)    ; Start block number
        mul     d, e

        ld      iy, TileMapDefLocation
        add     iy, de                                  ; Tilemap definition address for first tile within start block

; 1. DMA copy start block tile definitions into storage area
        ld      (DMABlockAnimationPortA), iy            ; Source

        ld      bc, StartBlockStorage
        ld      (DMABlockAnimationPortB), bc            ; Destination

        ;ld      b, 0
        ld      bc, BlockSize
        ld      (DMABlockAnimationLength), bc           ; DMA copy length = 1 x block
        
        LD      hl, DMABlockAnimation                   ; HL = pointer to DMA program
        LD      b, DMABlockAnimationCopySize            ; B = size of the code
        LD      c, $6B                                  ; C = $6B (zxnDMA port)
        OTIR                                            ; upload DMA program

; 2. DMA copy start block+1 ... end block tile definitions to start block tile definitions location
        ld      (DMABlockAnimationPortB), iy            ; Destination
        
        ld      hl, iy
        add     hl, BlockSize                           ; Source - Start block+1 tile definition
        ld      (DMABlockAnimationPortA), hl            ; Source

        ld      d, BlockSize                            ; 4 x tiles/block
        ld      a, (ix+S_BLOCK_ANIMATION.EndBlock)
        sub     (ix+S_BLOCK_ANIMATION.StartBlock)
        ld      e, a                                    ; Number of blocks to copy
        mul     d, e                                      
        ld      (DMABlockAnimationLength), de           ; DMA copy length = Size of tilemap definitions to copy
        push    de

        LD      hl, DMABlockAnimation                   ; HL = pointer to DMA program
        LD      b, DMABlockAnimationCopySize            ; B = size of the code
        LD      c, $6B                                  ; C = $6B (zxnDMA port)
        OTIR                                            ; upload DMA program

; 3. DMA copy start block tile definitions from storage area into end block tile map definitions
        pop     de
        add     iy, de
        ld      (DMABlockAnimationPortB), iy            ; Destination

        ld      bc, StartBlockStorage
        ld      (DMABlockAnimationPortA), bc            ; Source

        ld      bc, BlockSize                               
        ld      (DMABlockAnimationLength), bc           ; DMA copy length = 1 x block
        
        LD      hl, DMABlockAnimation                   ; HL = pointer to DMA program
        LD      b, DMABlockAnimationCopySize            ; B = size of the code
        LD      c, $6B                                  ; C = $6B (zxnDMA port)
        OTIR                                            ; upload DMA program

        ret

/* - 23/11/22 - Removed as not used
;-------------------------------------------------------------------------------------
; Tile Definitions - Replace Block Tile Definitions in Tile Definition Memory
; Note: Only updates the visual tile definitions, leaves block number intact within block tilemap
; Parameters:
; a - Source Block Tile Definitions to copy
; b - Target Block Tile Definitions to update
ReplaceBlockTileDefinitions:
; Point to source block tile definitions
        ld      d, BlockSize
        ld      e, a                                    ; Source block number
        mul     d, e

        ld      ix, TileMapDefLocation
        add     ix, de                                  ; Source tilemap definition address for first tile within source block

; Point to target block tile definitions
        ld      d, BlockSize
        ld      a, b
        ld      e, a                                    ; Target block number
        mul     d, e

        ld      iy, TileMapDefLocation
        add     iy, de                                  ; Target tilemap definition address for first tile within target block

        ld      b, BlockSize
.TileDefUpdateLoop:
        ld      a, (ix)
        ld      (iy), a

        inc     ix
        inc     iy

        djnz    .TileDefUpdateLoop

        ret
*/
;-------------------------------------------------------------------------------------
; Hazard - Populate Hazard Table
; Parameters:
PopulateHazardData:
        ld      a, (LevelDataHazardNumber)
        cp      0
        ret     z                                       ; Return if no hazards to process

        ld      b, a
        ld      a, MaxHazards
        cp      b
        jp      nc, .ContHazards                        ; Jump if number of hazards <= HazardsMax

        break
        
.ContHazards:
; Copy hazard block data via DMA
        ld      a, (LevelDataHazardNumber)
        ld      d, a
        ld      e, S_HAZARD_DATA
        mul     d, e

        ld      hl, de
        ld      (DMAHazardDataUploadLength), hl          ; DMA copy length
        
        ld      hl, (LevelDataHazardData)
        ld      (DMAHazardDataUploadPortA), hl          ; DMA Source

        LD      hl, DMAHazardDataUpload                 ; HL = pointer to DMA program
        LD      b, DMAHazardDataUploadCopySize          ; B = size of the code
        LD      c, $6B                                  ; C = $6B (zxnDMA port)
        OTIR                                            ; upload DMA program

; Update hazard block table
        ld      ix, HazardBlockData

        ld      a, (LevelDataHazardNumber)
        ld      b, a
.UpdateHazardLoop:
        push    bc

; - Calculate block offsets        
        ld      bc, (ix+S_HAZARD_DATA.XWorldCoordinate)
        ld      hl, (ix+S_HAZARD_DATA.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        
        ld      (ix+S_HAZARD_DATA.TileBlockOffset), bc
        ld      (ix+S_HAZARD_DATA.TileBlockOffsetY), de

; - Obtain Ground block and update tilelevel data (not-visible)
        ld      iy, (LevelTileMap)
        add     iy, bc

        ld      a, (iy)
        ld      (ix+S_HAZARD_DATA.GroundBlock), a

        ld      a, (ix+S_HAZARD_DATA.CurrentBlock)
        ld      (iy), a

/*
; - Obtain and set damage
; Note: Set the same damage across all hazards, as the last processed hazard sets the damage
        ld      a, (ix+S_HAZARD_DATA.Damage)
        ld      (HazardDamage), a
*/
        ld      bc, S_HAZARD_DATA
        add     ix, bc

        pop     bc

        djnz    .UpdateHazardLoop

        ret

;-------------------------------------------------------------------------------------
; Hazard - Animate Hazzard Blocks
; Parameters:
AnimateHazardBlocks:
        ld      ix, HazardBlockData
        
        ld      a, (LevelDataHazardNumber)
        cp      0
        ret     z                               ; Return if no hazards to process

        ld      b, a
.HazardBlockDataLoop:
        push    bc, ix

; Check whether Reverse-Hazard enabled
        ld      a, (ReverseHazardEnabled)
        cp      1
        jp      z, .AnimateHazardBlock                  ; Jump if Reverse-hazard enabled i.e. Bypass normal hazard animation

; Check whether block should be animated or left static
        ld      a, (ix+S_HAZARD_DATA.DelayAnim)
        cp      0
        jp      nz, .ContHazardCheck                    ; Jump if DelayAdnin != 0 i.e. Animate hazard block

; Non-Anim Block
; - Check whether reverse hazard block needs to be updated to normal block
; - Update memory TileMap block (not visible)
        ld      iy, (LevelTileMap)
        ld      de, (ix+S_HAZARD_DATA.TileBlockOffset)
        add     iy, de

        ld      a, (iy)
        cp      ReverseHazardBlock
        jp      nz, .NextHazardBlock                    ; Jump if block not reverse-hazard block

        ld      a, (ix+S_HAZARD_DATA.CurrentBlock)
        ld      (iy), a                                 ; Otherwise restore back to normal hazard block

; - Update screen TileMap block (visible)
        ld      hl, (ix+S_HAZARD_DATA.TileBlockOffsetY)
        call    UpdateScreenTileMap

        jp      .NextHazardBlock

; Anim Block
.ContHazardCheck:
; Check whether we can animate to the next block
        ld      a, (ix+S_HAZARD_DATA.DelayCounter)
        cp      0
        jp      z, .AnimateHazardBlock                  ; Jump if we can animate to the next block

        dec     a
        ld      (ix+S_HAZARD_DATA.DelayCounter), a      ; Otherwise decrement delay counter
        jp      .NextHazardBlock

.AnimateHazardBlock:
; Check current animation direction
        ld      a, (ix+S_HAZARD_DATA.ReverseAnim)
        cp      0
        jp      z, .AnimateForward                      ; Jump if forward animation

        call    AnimateHazardReverse                    ; Otherwise reverse animation

        jp      .NextHazardBlock

.AnimateForward:
        call    AnimateHazardForward

.NextHazardBlock:
        pop     ix

        ld      bc, S_HAZARD_DATA
        add     ix, bc
        
        pop     bc

        djnz    .HazardBlockDataLoop

        ret

;-------------------------------------------------------------------------------------
; Hazard - Animate Hazard/Hazard-Reverse Blocks Forward
; Parameters:
; ix = Hazard Data to animate
AnimateHazardForward:
; Reverse-Hazard
        ld      a, (ReverseHazardEnabled)
        cp      0
        jp      z, .NormalUpdate                        ; Jump if reverse-hazard not enabled i.e. Perform normal animation

        ld      a, ReverseHazardBlock                   ; New reverse-hazard block 
        jp      .UpdateBlock

.NormalUpdate:
; Check status of current hazard block
        ld      a, (ix+S_HAZARD_DATA.CurrentBlock)
        cp      (ix+S_HAZARD_DATA.BlockEnd)
        jp      z, .EndBlock                            ; Jump if hazard=End block          

        cp      (ix+S_HAZARD_DATA.GroundBlock)
        jp      z, .GroundBlock                         ; Jump if hazard=Ground block

; - Normal Block
        inc     a                                       ; Point to next hazard block
        ld      (ix+S_HAZARD_DATA.CurrentBlock), a
        ld      b, a                                    ; Save block reference

        ld      a, (ix+S_HAZARD_DATA.DelayAnim)
        ld      (ix+S_HAZARD_DATA.DelayCounter), a      ; Set standard pause
        
        ld      a, b                                    ; Restore block reference
        jp      .UpdateBlock

; - End Block
.EndBlock:
        ld      a, (ix+S_HAZARD_DATA.DelayPause)
        ld      (ix+S_HAZARD_DATA.DelayCounter), a  ; Set extended pause

        ld      a, (ix+S_HAZARD_DATA.GroundBlock)
        ld      (ix+S_HAZARD_DATA.CurrentBlock), a      ; Point to groundblock

; - Check whether we should show the ground as the last block
        ld      a, (ix+S_HAZARD_DATA.showGround)
        cp      1
        ret     nz                                      ; Return if groundblock should not be shown

        ld      a, (ix+S_HAZARD_DATA.GroundBlock)
        jp      .UpdateBlock                            ; Otherwise show groundblock

; - Ground Block
.GroundBlock:
        ld      a, (ix+S_HAZARD_DATA.DelayAnim)
        ld      (ix+S_HAZARD_DATA.DelayCounter), a  ; Set standard pause

        ld      (ix+S_HAZARD_DATA.ReverseAnim), 1       ; Enable reverse animation

        ld      a, (ix+S_HAZARD_DATA.BlockEnd)
        ld      (ix+S_HAZARD_DATA.CurrentBlock), a      ; Point to endblock

        jp      .UpdateBlock

; Update new hazard block
.UpdateBlock:
; - Update memory TileMap block (not visible)
        ld      iy, (LevelTileMap)
        ld      de, (ix+S_HAZARD_DATA.TileBlockOffset)
        add     iy, de
        ld      (iy), a

; - Update screen TileMap block (visible)
        ld      hl, (ix+S_HAZARD_DATA.TileBlockOffsetY)
        call    UpdateScreenTileMap

        ret

;-------------------------------------------------------------------------------------
; Hazard - Animate Hazard Block Reverse
; Parameters:
; ix = Hazard Data to animate
AnimateHazardReverse:
; Reverse-Hazard
        ld      a, (ReverseHazardEnabled)
        cp      0
        jp      z, .NormalUpdate                        ; Jump if reverse-hazard not enabled i.e. Perform normal animation

        ld      a, ReverseHazardBlock                   ; New reverse-hazard block 
        jp      .UpdateBlock

.NormalUpdate:
        dec     (ix+S_HAZARD_DATA.CurrentBlock)         ; Point to next hazard block

        ld      a, (ix+S_HAZARD_DATA.CurrentBlock)
        ld      b, a                                    ; Save block reference

        cp      (ix+S_HAZARD_DATA.BlockStart)
        jp      nz, .NotStartBlock

        ld      a, (ix+S_HAZARD_DATA.DelayAnim)         
        ld      (ix+S_HAZARD_DATA.DelayCounter), a      ; Set standard pause

        ld      (ix+S_HAZARD_DATA.ReverseAnim), 0       ; Enable forward animation

        ld      a, b                                    ; Restore block reference
        jp      .UpdateBlock

.NotStartBlock:
        ld      a, (ix+S_HAZARD_DATA.DelayAnim)
        ld      (ix+S_HAZARD_DATA.DelayCounter), a  ; Set standard pause

        ld      a, b                                    ; Restore block reference

; Update new hazard block
.UpdateBlock:
; - Update memory TileMap block (not visible)
        ld      iy, (LevelTileMap)
        ld      de, (ix+S_HAZARD_DATA.TileBlockOffset)
        add     iy, de
        ld      (iy), a

; - Update screen TileMap block (visible)
        ld      hl, (ix+S_HAZARD_DATA.TileBlockOffsetY)
        call    UpdateScreenTileMap

        ret

;-------------------------------------------------------------------------------------
; SavePoint - Check/Create SavePoint
; Parameters:
CreateSavePoint:
; Check for savepoint key pressed
        ld      a, (PlayerInputOriginal)
        and     %10000000
        ret     z                                       ; Return if Savepoint key not pressed

; Check whether the player has any savepoint credits
        ld      a, (SavePointCredits)
        cp      0
        ret     z                                       ; Return if player does not have any savepoint credits

; Check for valid tile that can hold savepoint - Check middle of player
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, FinishOverlapPermitted                              ; x offset
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, FinishOverlapPermitted                              ; y offset
        call    ConvertWorldToBlockOffset

        ld      (BackupWord1), bc
        ld      (BackupWord2), de

        push    de

; - Check for standard floor blocks         
        ld      iy, (LevelTileMap)
        add     iy, bc                                  ; Add block offset
        ld      a, (iy)                                 ; Obtain block number

        ld      (BackupWord3), iy

        ld      d, a
 
        ld      a, FloorStandardBlockSaveStart-1 ;FloorStandardBlock-1
        cp      d
        jp      nc, .InValidFloorTile                   ; Jump if tile <= FloorStandardBlock-1

        ld      a, FloorStandardBlockSaveEnd
        cp      d
        jp      c, .InValidFloorTile                    ; Jump if tile > FloorStandardBlockEnd

; - Check for hazard blocks
        pop     de                              

	ld	de, bc                          ; Bock offset of player

        ld      ix, HazardBlockData
        
        ld      a, (LevelDataHazardNumber)
        cp      0
        jp     	z, .ValidTile			; Jump if no hazard blocks to check

        ld      b, a
.HazardBlockDataLoop:
        push    bc

	or	a
        ld      hl, (ix+S_HAZARD_DATA.TileBlockOffset)
	sbc	hl, de
	jp	z, .InvalidHazardTile		; Return if hazard block

        ld      bc, S_HAZARD_DATA
        add     ix, bc
        
        pop     bc

        djnz    .HazardBlockDataLoop

; Valid place for savepoint
.ValidTile:
        ld      a, AyFXSavepointActivated
        call    AFX2Play

; Check whether another Save point exists
        ld      a, (SavePointSavedPlayerEnergy)
        cp      0
        jp      z, .CreateNewSavePoint                  ; Jump if no Save point exists

; Remove old Save point
; - Update screen TileMap block (not visible)
        ld      de, (SavePointSavedBlockOffset)

        ld      iy, (LevelTileMap)
        add     iy, de                                  ; Add block offset
        ld      a, (SavePointOldBlock)
        ld      (iy), a                                 ; Reset to old block tile

; - Update screen TileMap block (visible)
        ld      hl, (PlayerStartXYBlock)
        call    UpdateScreenTileMap

; Create new Save point
.CreateNewSavePoint:
        ld      hl, (ReticuleSprite+S_SPRITE_TYPE.patternRange)
        ld      (SavedPointReticulePattern), hl         ; Save reticule pattern

        ld      de, (BackupWord1)                       ; Original bc
        ld      hl, (BackupWord2)                       ; Original de
        ld      iy, (BackupWord3)

        ld      (PlayerStartXYBlock), hl
        ld      (SavePointSavedBlockOffset), de

        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        ld      (SavePointSavedPlayerEnergy), a
        ld      a, (PlayerFreezeTime)
        ld      (SavePointSavedPlayerFreeze), a

; - Update screen TileMap block (not visible)
        ld      a, FloorSavePointUsedBlock              ; Save fixed used savepoint block
        ;ld      a, (iy)
        ld      (SavePointOldBlock), a                  ; Save old block for restore later
        ld      (iy), SavePointEnabledBlock

; - Update screen TileMap block (visible)
        call    UpdateScreenTileMap

; - Update player credits
        ld      a, (SavePointCredits)
        dec     a
        ld      (SavePointCredits), a

; Update Save point HUD
; - Value sprites
        ld      b, HUDSavePointValueDigits
        ld      d, a
        ld      a, (HUDSavePointValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites                      
        
; - Icon --> Enabled
        ld      iy, (HUDSavePointIconSprite)

        ;;ld      hl, HUDSavePointEnabledPatterns         
        ;;ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl
        ld      bc, HUDSavePointEnabledPatterns 
        call    UpdateSpritePattern

	;;ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for disabled/enabled
        ;;call    UpdateSpritePattern4BitStatus

        ret

; Cannot place savepoint on non-standard floor tile
.InValidFloorTile:
        pop     de

        ret

;Cannot place savepoint on hazard tile
.InvalidHazardTile:
        pop     bc

        ret

/* 17/07/23 - Not used as changes gameplay mechanic; routine not complete
;-------------------------------------------------------------------------------------
; Web - Create web
; Parameters:
CreateWebTile:
; Check for savepoint key pressed
        ;ld      a, (PlayerInputOriginal)
        ;and     %10000000
        ;ret     z                                       ; Return if Savepoint key not pressed

; Check whether the player has any savepoint credits
        ;ld      a, (SavePointCredits)
        ;cp      0
        ;ret     z                                       ; Return if player does not have any savepoint credits

; Check for valid tile that can hold savepoint - Check middle of player
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, FinishOverlapPermitted                              ; x offset
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, FinishOverlapPermitted                              ; y offset
        call    ConvertWorldToBlockOffset

        ld      (BackupWord1), bc
        ld      (BackupWord2), de

        push    de

; - Check for standard floor blocks         
        ld      iy, (LevelTileMap)
        add     iy, bc                                  ; Add block offset
        ld      a, (iy)                                 ; Obtain block number

        ld      (BackupWord3), iy

        ld      d, a
 
        ld      a, FloorStandardBlockSaveStart-1 ;FloorStandardBlock-1
        cp      d
        jp      nc, .InValidFloorTile                   ; Jump if tile <= FloorStandardBlock-1

        ld      a, FloorStandardBlockSaveEnd
        cp      d
        jp      c, .InValidFloorTile                    ; Jump if tile > FloorStandardBlockEnd

; - Check for hazard blocks
        pop     de                              

	ld	de, bc                          ; Bock offset of player

        ld      ix, HazardBlockData
        
        ld      a, (LevelDataHazardNumber)
        cp      0
        jp     	z, .ValidTile			; Jump if no hazard blocks to check

        ld      b, a
.HazardBlockDataLoop:
        push    bc

	or	a
        ld      hl, (ix+S_HAZARD_DATA.TileBlockOffset)
	sbc	hl, de
	jp	z, .InvalidHazardTile		; Return if hazard block

        ld      bc, S_HAZARD_DATA
        add     ix, bc
        
        pop     bc

        djnz    .HazardBlockDataLoop

; Valid place for savepoint
.ValidTile:
        ;ld      a, AyFXSavepointActivated
        ;call    AFX2Play

; Check whether another Save point exists
        ;ld      a, (SavePointSavedPlayerEnergy)
        ;cp      0
        ;jp      z, .CreateNewSavePoint                  ; Jump if no Save point exists

; Remove old Save point
; - Update screen TileMap block (not visible)
        ;ld      de, (SavePointSavedBlockOffset)

        ;ld      iy, (LevelTileMap)
        ;add     iy, de                                  ; Add block offset
        ;ld      a, (SavePointOldBlock)
        ;ld      (iy), a                                 ; Reset to old block tile

; - Update screen TileMap block (visible)
        ;ld      hl, (PlayerStartXYBlock)
        ;call    UpdateScreenTileMap

; Create new Save point
.CreateNewSavePoint:
        ;ld      hl, (ReticuleSprite+S_SPRITE_TYPE.patternRange)
        ;ld      (SavedPointReticulePattern), hl         ; Save reticule pattern

        ld      de, (BackupWord1)                       ; Original bc
        ld      hl, (BackupWord2)                       ; Original de
        ld      iy, (BackupWord3)

        ;ld      (PlayerStartXYBlock), hl
        ;ld      (SavePointSavedBlockOffset), de

        ;ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        ;ld      (SavePointSavedPlayerEnergy), a
        ;ld      a, (PlayerFreezeTime)
        ;ld      (SavePointSavedPlayerFreeze), a

; - Update screen TileMap block (not visible)
        ld      a, (iy)
        ;ld      (DestructableStartBlock), a                  ; Save old block for restore later
        ld      (iy), DestructableStartBlock

; - Update screen TileMap block (visible)
        call    UpdateScreenTileMap

; - Update player credits
        ;ld      a, (SavePointCredits)
        ;dec     a
        ;ld      (SavePointCredits), a

; Update Save point HUD
; - Value sprites
        ;ld      b, HUDSavePointValueDigits
        ;ld      d, a
        ;ld      a, (HUDSavePointValueSpriteNum)
        ;ld      c, a
        ;ld      a, d
        ;call    UpdateHUDValueSprites                      
        
; - Icon --> Enabled
        ;ld      iy, (HUDSavePointIconSprite)

        ;ld      hl, HUDSavePointEnabledPatterns         
        ;ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

	;ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for disabled/enabled
        ;call    UpdateSpritePattern4BitStatus

        ret

; Cannot place savepoint on non-standard floor tile
.InValidFloorTile:
        pop     de

        ret

;Cannot place savepoint on hazard tile
.InvalidHazardTile:
        pop     bc

        ret
*/


