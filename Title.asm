;-------------------------------------------------------------------------------------
; Title Screen - Routines
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     2, $$AyFXBankEnd + 1    ; Slot 2 = $4000..$5FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
;        MMU     2, $$LevelData10 + 1    ; Slot 2 = $4000..$5FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address
        ORG     $4000
;-------------------------------------------------------------------------------------
TitleCode:
; Title Screen Main Loop
; Parameters:
; Return:
TitleScreen:
; Game loaded - Update from CFG file
        ld      a, (GameStatus3)
        bit     3, a                    ; Check game just loaded flag
        jp      z, .BypassJustStarted   ; Jump if flag not set

; Game just started 
.GameJustStarted:
; - Show Presents screen
        call    TitleDisplayPresentsScreen

; - Update data from CFG file
        call    TitleCFGFileRead

; - Write data to CFG file
; -- Primarily required to create a new CFG file if a file doesn't exist.
; -- Thereby preventing a pause in the music when file first created  
        call    TitleCFGFileWrite

        ld      a, (GameStatus3)
        res     3, a                    ; Reset Game just loaded flag
        ld      (GameStatus3), a

.BypassJustStarted:
; Set title mouse speed
        ld      a, MouseSpeedTitle
        ld      (MouseSpeed), a

; Reset Title borders value
        ld      hl, 0
        ld      (TitleBordersLastValue), hl

; Check score against HighScore table, also sets TitleScreenStatus
        call    CheckUpdateHighScoreTable     
        
; Display title borders
; TODO - Title update
        ;;call    TitleDisplayBorders

; Setup NextDAW
; - Initialise
        di
        ld      hl, $0706               ; h = mmu1 to use, l = mmu0 to use
        ld      c, $3                   ; c = mmu2 to use
        call    NextDAW_InitSystem

; - Initialise and play song
        ld      de, SongDataPages       ; Memory banks hosting song
        ld      a, 0                    ; Force AY mono (bits 0,1,2 control AY 1,2,3.  Set to force to mono, otherwise use song default)
        call    NextDAW_InitSong
        call    NextDAW_PlaySong
        ei

.TitleScreenLoop:
        ld      a, (TitleScreenStatus)
        bit     6, a
        call    nz, TitleMainScreen             ; Call if Title-Main flag set

        ld      a, (TitleScreenStatus)
        bit     2, a
        call    nz, TitleHighScoreScreen        ; Call if Title-HighScore flag set

        ld      a, (TitleScreenStatus)
        bit     5, a
        call    nz, TitleInstrScreen            ; Call if Title-Instr flag set

        ld      a, (TitleScreenStatus)
        bit     4, a
        jp      nz, .ExitTitleScreen            ; Jump if Play flag set

        jp      .TitleScreenLoop                

.ExitTitleScreen:
        call    NextDAW_StopSongHard
        call    NextDAW_UpdateSong

        nextreg $07, %000000'11         ; Switch to 28Mhz; prevent changing on machine e.g. via NMI

; Set HighScore from HighScore table
        ld      ix, TitleHighScoreValues
        ld      de, S_HighScore_Values.Value
        add     ix, de                  ; HighScore entry pointer --> Top Score

        ld      hl, ix
        ld      de, HiScore
        ld      b, 0
        ld      c, ScoreLength
        ldir

; Set ClearScreen counters, as title values differ
        ld      hl, (TitleTileMapXOffsetLeftCounter)
        ld      (ClearScreenX1Counter), hl
        ld      hl, (TitleTileMapYOffsetTopCounter)
        ld      (ClearScreenY1Counter), hl

; Exit Title screen
        ld      a, (GameStatus2)
        res     1, a                    ; Reset title screen flag
        ld      (GameStatus2), a
        
        ret

;-------------------------------------------------------------------------------------
; Setup/Display Title-Main Screen
; Parameters:
DisplayTitleMainScreen:
; Check whether returning from HighScore screen
        ld      a, (TitleScreenStatus)
        bit     1, a
        jp      nz, .HighScoreReturn            ; Jump if transitioning from HighScore to Main screen

; Reset title screen counters
        ld      a, 0
        ld      (TitleKeyDelayCounter), a
        
/* 28/11/23 - TitleScrollTileMap routine no longer used
        ld      ix, TitleTilemapScrollDir               ; Set to top entry in table
        ld      (TitleTilemapScrollDirOffset), ix

        ld      a, (ix+S_TITLE_TILEMAPSCROLL.Duration)  ; Get first entry duration
        ld      (TitleTilemapScrollDirCounter), a
*/

; Immediately close tilemap, layer2 and sprite screens
; - Note: Only really needed when game first started, as exiting a game session will close all screens
        ld      a, ClearScreenY1Middle
        ld      (ClearScreenY1Counter), a
        ld      a, ClearScreenY2Middle
        ld      (ClearScreenY2Counter), a

        ld      a, ClearScreenX1Middle
        ld      (ClearScreenX1Counter), a
        ld      a, ClearScreenX2Middle
        ld      (ClearScreenX2Counter), a

        ld      a, 0                            ; Close tilemap & sprite screens
        ld      (BackupByte7), a
        call    UpdateScreen

; Stop Copper
	NEXTREG $62, %00'000'000                ; Stop copper

; --- Layer Priority
; SPRITE AND LAYERS SYSTEM REGISTER
; - LowRes off
; - Sprite rendering flipped i.e. Sprite 0 (Player) on top of other sprites
; - Sprite clipping in over border mode enabled
; - Layer Priority - SUL (Top - Sprites, Layer 2, Enhanced_ULA)
; - Sprites visible and displayed in border
        nextreg $15, %0'1'1'000'1'1

; --- Tilemap ---
; Reset scroll counters to ensure tilemap displayed correctly after level has been played
        ld      bc, 0
        ld      (ScrollTileMapBlockXPointer), bc

; Setup title TileMap data
        ld      a, $$TitleTileMap               ; Memory bank (8kb) containing tilemap data
        call    SetupTitleTileMap

; Draw tilemap
        call    DrawLevelIntroTileMap

; --- Sprites ---
; Set camera starting coordinates; required for spawning sprites at correct locations
        ld      hl, 16
        ld      (CameraXWorldCoordinate), hl
        ld      (CameraYWorldCoordinate), hl

.HighScoreReturn:
; Import Text Sprites
        call    ImportTitleMainSprites
        
        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .BypassCreateReticule        ; Jump if re-open Title-Main screen

; Setup Mouse Reticule
; - Populate initial mouse values
        ld      bc, $FBDF			;FADF Mouse Buttons port
	in      a, (c)			        ; FBDF Mouse Xpos - Obtain new MouseX value
	ld      (XMove), a                      ; Store new mouseX value
	
	ld      b, $FF	                        ; Point to mouse Y position input port
	in      a, (c)			        ; FFDF Mouse Ypos - Obtain new MouseY value
	ld      (YMove), a                      ; Store new mouseY value

 ; - Spawn Reticule Sprite
        call    SetupReticuleSprite

        ld      hl, TitleMouseStartXPosition
        ld      a, TitleMouseStartYPosition
        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a

        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl
        ld      h, 0
        ld      l, a
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleMainReticulePatterns       ; Sprite pattern range
        call    UpdateSpritePattern

        jp      .SpritesContinue

.BypassCreateReticule:
; - Change reticule sprite to new sprite pattern
        ld      ix, ReticuleSprAtt
        ld      iy, ReticuleSprite
        ld      bc, TitleMainReticulePatterns       ; Sprite pattern range
        call    UpdateSpritePattern

.SpritesContinue:
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .BypassL2                    ; Jump if re-open Title-Main screen

; --- Layer2 ---
; - Configure L2 settings
        call    TitleLayer2Setup

; *** Configure Layer 2 and ULA Transparency Colour
; GLOBAL TRANSPARENCY Register
; - Changed for L2 to enable display of black
        nextreg $14,$1         ; Palette entry 1- Ensure palettes are configured correctly

.BypassL2:
; *** Setup Layer-2 *** - Required when re-opening Title-Main screen
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      

; - ReMap ULA Memory bank 10 (16KB) to slot 3; previously remapped when importing sprites
;   Note: Only need to remap slot 3 as slot 4 no longer used when importing sprites
        nextreg $53, 10

; --- Content ---
; Display sprite text for title screen
; - Level text
        ld      ix, TitleLevelText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, %1011'000
        call    PrintSpriteText

; - Spawn Down-Level sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleLevelDownXY       ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 4
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 4
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleLevelDownSpriteNumber), a         
        inc     a                                       ; Point to next sprite number
        ld      (TitleLevelValueSpriteNum), a           ; Store sprite value for level number sprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleUIDownPatterns              ; Sprite pattern range
        call    UpdateSpritePattern

; - Level Value
        ld      de, SpriteString2
        ld      a, (CurrentLevel)
        ld      b, 2                            ; Number of digits
        call    ConvertIntToString2

        ld      hl, TitleLevelNumberValueXY     ; Block position
        ld      ix, SpriteString2               ; Text string
        ld      a, %1011'000
        call    PrintSpriteText

; - Spawn Up-Level sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleLevelUpXY      ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 4
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 4
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleLevelUpSpriteNumber), a         

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleUIUpPatterns          ; Sprite pattern range
        call    UpdateSpritePattern

; - Mode text
        ld      ix, TitleModeText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        ;ld      a, %1011'0000
        call    PrintSpriteText

; - Spawn Down-Mode sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleModeDownXY             ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleModeDownSpriteNumber), a         
        inc     a                                       ; Point to next sprite number
        ld      (TitleModeValueSpriteNum), a            ; Store sprite value for mode sprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleUIDownPatterns              ; Sprite pattern range
        call    UpdateSpritePattern

; - Mode Value
        ld      hl, TitleModeEasyText           ; Assume Easy mode text
        ld      a, (GameStatus2)
        bit     4, a
        jp      z, .DisplayMode                 ; Jump if Easy mode

        ld      hl, TitleModeHardText           ; Otherwise point to Hard mode text

.DisplayMode:
        ld      ix, hl
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Spawn Up-Mode sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleModeUpXY               ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleModeUpSpriteNumber), a         

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleUIUpPatterns           ; Sprite pattern range
        call    UpdateSpritePattern

; - Play text
        ld      ix, TitlePlayText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, %1011'0000
        call    PrintSpriteText

; - Spawn Left-Start sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleStartLeftXY            ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 11
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 11
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitlePlaySpriteNumber), a         

        push    ix
        ld      ix, iy
        pop     iy

; - Check whether to display play or locked sprite
        ld      a, (GameStatus3)
        bit     6, a
        jp      nz, .SetLockedSprite            ; Jump if level locked

; - Set play sprite
        ld      bc, TitlePlayPatterns           ; Sprite pattern range
        call    UpdateSpritePattern

        jp      .SpawnHighScoreSprite

; - Set locked sprite
.SetLockedSprite:
        ld      bc, TitleLockedPatterns         ; Sprite pattern range
        call    UpdateSpritePattern

.SpawnHighScoreSprite:
; - Spawn HighScore-Screen sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleHighScoreScreenXY      ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 11
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 11
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleHighScoreSpriteNumber), a         

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleUIHighScorePatterns       ; Sprite pattern range
        call    UpdateSpritePattern

; - Spawn Instr-Screen sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleInstrScreenXY          ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 11
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 11
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleInstrSpriteNumber), a         

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleUIInstrPatterns       ; Sprite pattern range
        call    UpdateSpritePattern

; - Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ret

;-------------------------------------------------------------------------------------
; Setup Title Tilemap
; Parameters:
; a = Memory block containing title tilemap data
;
SetupTitleTileMap:
; Setup tilemap level data              
; - Map source tilemap level data bank to slot 3
        nextreg $53, a                          

; - Copy source TileMap data to working TileMap data location
        ld      hl, TitleTileMapData            ; Tilemap for title screen (skip width, height bytes)
        add     hl, 2
        call    CopyIntroTileMapData

; Setup TileMap palette/screen/definitions
; - Obtain bank number currently mapped into slot 7; required to be restored later
	ld      a,$57                           ; Port to access - Memory Slot 7
        ld      bc,$243B                        ; TBBlue Register Select
        out     (c),a                           ; Select NextReg $1F

        inc     b                               ; TBBlue Register Access
        in      a, (c)
        
        push    af                              ; Save current bank number in slot 7
        
; - Setup Tilemap Palette
        ld      a, $$TitleTileMapDefPal         ; Memory bank (8kb) containing tilemap palette data        
        ld      hl, TitleTileMapDefPal          ; Address of first byte of layer 2 palette data
        ld      b, TitleTileMapDefPalRows       ; Number of rows in palette
        call    SetupTileMapPalette

; - Setup Tilemap Screen config
        call    SetupTitleTileMapConfig

; - Upload TileMap Definitions - Blocks (Title scrolling background)
        ld      a, $$TitleTileMapDef1           ; Memory bank (8kb) containing tilemap definition data
        ld      b, TitleTileMapDefBlocks        ; Number of blocks to upload
        call    UploadTileBlockPatterns

; - Upload TileMap Definitions - Patterns (Title text)
        ld      a, $$TitleTileMapDef2           ; Memory bank (8kb) containing tilemap definition data
        ld      de, (TitleTextTileMapDefsStart) ; Destination = After tile pattern blocks 
        call    UploadTileDefPatterns

; Configure tilemap palette offset and replace tilemap definition 0
        call    TitleTileMapPalDefinition

; Re-Map Slot 7 to original bank number
        pop     af

        nextreg $57, a                          ; Re-map memory bank

        ret

;-------------------------------------------------------------------------------------
; Setup Title Tilemap Configuration
; Parameters:
SetupTitleTileMapConfig:
; ULA CONTROL Register
        ld      a, %1'00'0'1'0'0'0      ; Disable ULA , no stencil mode, other bits to default 0 configs
        nextreg $68, a

;-------------------------------------------------------------------------------------
; Configure TileMap Memory Locations
; Map memory bank to slot 7 ($e000)
; MEMORY MANAGEMENT SLOT 7 BANK Register
; - Map ULA Memory banks 10/11 (16KB) to slots 3/4)
        nextreg $53, 10
        ;nextreg $54, 11

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
; Setup Title-Main Sprites - Import sprite patterns and reset sprite attributes
; Parameters
ImportTitleMainSprites:
; Import Sprite Palette
        ld      a, $$TitleSpritePalette     ; Memory bank (8kb) containing sprite palette data        
        ld      hl, TitleSpritePalette      ; Address of first byte of sprite palette data
        call    SetupSpritePalette
        
; Upload Sprite Patterns
        ld      d, $$TitleSprites1         ; Memory bank (8kb) containing sprite data 0-63   - 8kb
        ld      e, $$TitleSprites2         ; Memory bank (8kb) containing sprite data 64-127 - 8kb
        ld      hl, TitleSprites1          ; Address of first byte of sprite patterns
        ld      ixl, 64                 ; Number of sprite patterns to upload
        call    UploadTitleSpritePatterns

; Disable/Hide all sprites 
; - Reset sprites and attributes - Need to run to ensure at least one non-zero attribute is defined
        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .KeepReticule        ; Jump if re-open Title-Main screen

        ld      a, MaxSprites
        call    ResetSprites

        ret

.KeepReticule:
; Reset all sprites except reticule and scroller sprites
        ld      a, TitleScrollSpritesAttStart-2
        call    TitleResetSprites

        ret

;-------------------------------------------------------------------------------------
; Setup Title-Instruction Sprites - Import sprite patterns and reset sprite attributes
; Parameters
ImportTitleInstrSprites:
; Disable/Hide all sprites 
; - Reset all sprites except reticule
        ld      a, MaxSprites-1
        call    TitleResetSprites

; Import Sprite Palette
        ld      a, $$TitleSpritePalette ; Memory bank (8kb) containing sprite palette data        
        ld      hl, TitleSpritePalette  ; Address of first byte of sprite palette data
        call    SetupSpritePalette
        
; Upload Sprite Patterns
        ld      d, $$TitleSprites2      ; Memory bank (8kb) containing sprite data 0-63   - 8kb
        ld      e, $$TitleSprites3      ; Memory bank (8kb) containing sprite data 64-127 - 8kb
        ld      hl, TitleSprites2       ; Address of first byte of sprite patterns
        ld      ixl, 64                 ; Number of sprite patterns to upload
        call    UploadTitleSpritePatterns

        ret

;-------------------------------------------------------------------------------------
; Read Input Devices - Title Screen
; Parameters:
TitleReadPlayerInput:
        ld      a, 0
        ld      (PlayerInput), a

; Reset keyboard bits
        ld      d,$FF           ; keyboard reading bits are 1=released, 0=pressed -> $FF = no key

; Check third row of matrix (QWERT) - UP
        ld      a,~(1<<2)       ; Rotate 1 to the left 2 times and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (q) into Fcarry
        rrca                    ; Rotate bit 0 (w) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (w) into d (bit 0)

; Check second row of matrix (ASDFG) - DOWN
        ld      a,~(1<<1)       ; Rotate 1 to the left 1 time and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (a) into Fcarry
        rrca                    ; Rotate bit 0 (s) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (a) into d (bit 0)

; Check second row of matrix (ASDFG) - LEFT
        ld      a,~(1<<1)       ; Rotate 1 to the left 1 time and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (a) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (a) into d (bit 0)

; Check second row of matrix (ASDFG) - RIGHT
        ld      a,~(1<<1)       ; Rotate 1 to the left 1 time and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (a) into Fcarry
        rrca                    ; Rotate bit 0 (s) into Fcarry
        rrca                    ; Rotate bit 0 (d) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (a) into d (bit 0)

        ld      a, d

; Combine keyboard and joystick input
        cpl                     ; a is inverted i.e If key pressed, bit stored as 0; now invert the readings, now 1 = pressed, 0 = no key

        ld      (PlayerInput), a                ; store the combined player input

	call	ReadMouse

; Check whether player can provide input based on delay, but keep mouse movement
        ld      a, (TitleKeyDelayCounter)
        cp      0
        jp      z, .CheckInput                  ; Jump if no delay required

        dec     a
        ld      (TitleKeyDelayCounter), a       ; Otherwise decrement delay

        ld      a, 0
        ld      (PlayerInput), a                ; Reset input

        ret

.CheckInput:
; Check whether player provided input
        ld      a, (PlayerInput)
        cp      0
        ret     z                               ; Return if player not provided input

        ld      a, TitleKeyDelay
        ld      (TitleKeyDelayCounter), a       ; Otherwise set delay

        ret

;-------------------------------------------------------------------------------------
; Check/Update Reticule Position Values - Title Screen
; Note: Mouse offset values always relative to mouse starting position        
; Parameters:
TitleCheckUpdateReticule:
; XPosition
        ld      a, (MouseXDelta)
	or      a
	jp      m, .LeftOfStartPosition         ; Jump if negative offset

; Positive offset i.e. Right of start position
        ld      b, TitleMouseHorRightMaxOffset  
        call    TitleCheckMaxOffset             ; Check against max offset

        ld      a, c                            ; Return value
        ld      (MouseXDelta), a

        ld      b, 0
        ld      c, a
        ld      hl, TitleMouseStartXPosition
        add     hl, bc

        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl
        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl

        jp      .CheckYPosition

; Negative offset i.e. Left of start position
.LeftOfStartPosition:
        neg                                     ; Convert to positive value
        ld      b, TitleMouseHorLeftMaxOffset
        call    TitleCheckMaxOffset             ; Check against max offset

        ld      a, c                            ; Return value
        neg                                     ; Convert back to negative value
        ld      (MouseXDelta), a
        neg                                     ; Convert to postive value to allow subtraction

        ld      b, 0
        ld      c, a
        or      a
        ld      hl, TitleMouseStartXPosition
        sbc     hl, bc

        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl
        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl

; YPosition
.CheckYPosition:
        ld      a, (MouseYDelta)
	or      a
	jp      m, .TopOfStartPosition          ; Jump if negative offset

; Positive offset i.e. Below start position
        ld      b, TitleMouseVerBotMaxOffset
        call    TitleCheckMaxOffset             ; Check against max offset

        ld      a, c                            ; Return value
        ld      (MouseYDelta), a

        ld      b, a
        ld      a, TitleMouseStartYPosition
        add     b
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a

        ld      h, 0
        ld      l, a
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl

        ret

.TopOfStartPosition:
        neg                                     ; Convert to positive value
        ld      b, TitleMouseVerTopMaxOffset    ; -16 due to yposition being measured on top position of sprite
        call    TitleCheckMaxOffset             ; Check against max offset

        ld      a, c                            ; Return value
        neg                                     ; Convert back to negative value
        ld      (MouseYDelta), a

        ld      b, a
        ld      a, TitleMouseStartYPosition
        add     b
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a

        ld      h, 0
        ld      l, a
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl

        ret

;-------------------------------------------------------------------------------------
; Check/Update offset in relation to provided max mouse offset  - Title Screen
; Parameters:
; a = Mouse Delta value to check i.e. X or Y
; b = Max mouse offset
; Return:
; c = Updated Delta value
TitleCheckMaxOffset:
        ld      c, a                            ; Return value

	ld      a, b
        cp      c                               ; Compare with max offset
        jp      c, .ResetToMaxOffset            ; Jump if Mouse Delta > max offset

        ret
        
.ResetToMaxOffset:
        ld      a, b
        ld      c, b                            ; Return value

        ret

;-------------------------------------------------------------------------------------
; Update Level Number - Title Screen
; Parameters:
; a = 0 - Decrease Level, 1 - Increase Level
TitleUpdateLevelNumber:
; - Level Value
        cp      1
        jp      z, .IncreaseLevelNumber

; Decrease Level Number        
        ld      a, (CurrentLevel)
        cp      1
        ret     z                               ; Return if already lowest level

        dec     a
        ld      (CurrentLevel), a

        ld      b, a
        ld      a, (UnlockedLevel)
        cp      b
        jp      nc, .LevelUnlocked              ; Jump if current level <= max unlocked level

; - Current level locked
        ld      a, (GameStatus3)
        set     6, a
        ld      (GameStatus3), a                ; Set level locked flag

        jp      .DisplayLevelNumber

.IncreaseLevelNumber:
        ld      a, (CurrentLevel)
        cp      LevelTotal
        jp      z, .BypassLevelIncrease         ; Jump if current level at max

        inc     a
        ld      (CurrentLevel), a               ; Otherwise increase current level

.BypassLevelIncrease:
        ld      b, a
        ld      a, (UnlockedLevel)
        cp      b
        jp      nc, .LevelUnlocked              ; Jump if current level <= max unlocked level

; - Current level locked
        ld      a, (GameStatus3)
        set     6, a
        ld      (GameStatus3), a                ; Set level locked flag

        jp      .DisplayLevelNumber

; - Current level unlocked
.LevelUnlocked:
        ld      a, (GameStatus3)
        res     6, a
        ld      (GameStatus3), a                ; Reset level locked flag

.DisplayLevelNumber:
; Update level value
        ld      a, (CurrentLevel)
        ld      b, TitleLevelValueDigits
        ld      d, a
        ld      a, (TitleLevelValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites                      

; Update play/locked sprite
; - Get play/lock sprite locations
        ld      a, (TitlePlaySpriteNumber)
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     d, e

        ld      iy, Sprites
        add     iy, de

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

; Configure tilemap palette offset and replace tilemap definition 0
        call    TitleTileMapPalDefinition

; Update title borders (tilemap)
; TODO - Title update
        ;;push    ix, iy
        ;;call    TitleDisplayBorders
        ;;pop     iy, ix

; - Check level status
        ld      a, (GameStatus3)
        bit     6, a
        jp      nz, .SetLockedSprite            ; Jump if level locked

; - Set play sprite
        ld      bc, TitlePlayPatterns           ; Sprite pattern range
        call    UpdateSpritePattern
        
        ret

; - Set locked sprite
.SetLockedSprite:
        ld      bc, TitleLockedPatterns         ; Sprite pattern range
        call    UpdateSpritePattern

        ret

;-------------------------------------------------------------------------------------
; Update Mode - Title Screen
; Parameters:
; a = 0 - Decrease Mode, 1 - Increase Mode
TitleUpdateMode:
; - Mode Value
        cp      1
        jp      z, .SetHardMode

; Set Easy mode
        ld      a, (GameStatus2)
        bit     4, a
        ret     z                       ; Return if already Easy mode

        call    .ClearModeSprites

; - Update sprites
        ld      ix, TitleModeEasyText
        ld      hl, (ix)                ; Block position
        inc     ix
        inc     ix                      ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Set new mode
        ld      a, (GameStatus2)
        res     4, a
        ld      (GameStatus2), a

        ret

; Set Hard mode
.SetHardMode:
        ld      a, (GameStatus2)
        bit     4, a
        ret     nz                      ; Return if already Hard mode

        call    .ClearModeSprites

        ld      ix, TitleModeHardText
        ld      hl, (ix)                ; Block position
        inc     ix
        inc     ix                      ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Set new mode
        ld      a, (GameStatus2)
        set     4, a
        ld      (GameStatus2), a
        ret

; Clear active flag for mode sprites
.ClearModeSprites:
; - Get address of first mode sprite
        ld      a, (TitleModeValueSpriteNum)
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     d, e                    ; de = Offset for first sprite

        ld      ix, Sprites
        add     ix, de                  ; Point to first mode sprite

; - Clear active flag for all mode sprites
        ld      a, TitleModeValueDigits
        ld      b, a

        ld      de, S_SPRITE_TYPE               
.ClearLoop:
        ld      (ix+S_SPRITE_TYPE.active), 0

        add     ix, de                  ; Point to next sprite

        djnz    .ClearLoop

        ret

;-------------------------------------------------------------------------------------
; UI Collision - Title-Main Screen
; Parmeters:
; Return Values:
TitleMainUICollision:
        ld	ix, ReticuleSprite

; Check which Title UI to check
        ld      a, (TitleScreenStatus)
        bit     5, a
        jp      nz, .CheckInstrUI       ; Jump if title-instructions flag set

        ld      a, (TitleScreenStatus)
        bit     2, a
        jp      nz, .CheckHighScoreUI   ; Jump if title-HighScore flag set

; --- Check Title-Main UI
; Check Level-Down Sprite UI
        ld      a, (TitleLevelDownSpriteNumber)
        call    TitleUICheckCollision

        cp      0                       ; Return value
        jp      z, .CheckLevelUp        ; Jump if no collision

; - Update level number
        ld      a, 0                    ; Decrease level
        call    TitleUpdateLevelNumber

        ret

; Check Level-Up Sprite UI
.CheckLevelUp:
        ld      a, (TitleLevelUpSpriteNumber)
        call    TitleUICheckCollision

        cp      0                       ; Return value
        jp      z, .CheckModeDown       ; Jump if no collision

; - Update level number
        ld      a, 1                    ; Increase level
        call    TitleUpdateLevelNumber

        ret

; Check Mode-Down Sprite UI
.CheckModeDown:
        ld      a, (TitleModeDownSpriteNumber)
        call    TitleUICheckCollision

        cp      0                       ; Return value
        jp      z, .CheckModeUp         ; Jump if no collision

; - Update mode
        ld      a, 0                    ; Decrease mode
        call    TitleUpdateMode

        ret

; Check Mode-Up Sprite UI
.CheckModeUp:
        ld      a, (TitleModeUpSpriteNumber)
        call    TitleUICheckCollision

        cp      0                       ; Return value
        jp      z, .CheckStart          ; Jump if no collision

; - Update mode
        ld      a, 1                    ; Increase mode
        call    TitleUpdateMode

        ret

; Check Start Sprite UI
.CheckStart:
        ld      a, (TitlePlaySpriteNumber)
        call    TitleUICheckCollision

        cp      0                       ; Return value
        jp      z, .CheckInstrScreen    ; Jump if no collision

; - Start clicked
        ld      a, (GameStatus3)
        bit     6, a
        ret     nz                      ; Return if current level locked

        ld      a, (TitleScreenStatus)
        res     6, a                    ; Reset Title-Main flag
        set     4, a                    ; Set Play Clicked flag
        ld      (TitleScreenStatus), a
        ret

; Check Instr-Screen Sprite UI
.CheckInstrScreen:
        ld      a, (TitleInstrSpriteNumber)
        call    TitleUICheckCollision

        cp      0                       ; Return value
        jp      z, .CheckHighScoreScreen   ; Jump if no collision

; - Instr-Screen Clicked
        ld      a, (TitleScreenStatus)
        res     6, a                    ; Reset Title-Main flag
        set     5, a                    ; Set Title-Instr flag
        ld      (TitleScreenStatus), a

        ld      a, (TitleInstrStatus)
        ld      a, 1                    ; Set Instr1 screen
        ld      (TitleInstrStatus), a
        ret

; Check HighScore-Screen Sprite UI
.CheckHighScoreScreen:
        ld      a, (TitleHighScoreSpriteNumber)
        call    TitleUICheckCollision

        cp      0                       ; Return value
        ret     z                       ; Return if no collision

; - HighScore-Screen Clicked
        ld      a, (TitleScreenStatus)
        res     6, a                    ; Reset Title-Main flag
        set     2, a                    ; Set Title-HighScore flag
        ld      (TitleScreenStatus), a

        ret

; --- Check Title-Instructions UI
.CheckInstrUI:
; Check Home-Screen Sprite UI
        ld      a, (TitleInstrHomeSpriteNumber)
        call    TitleUICheckCollision

        cp      0                               ; Return value
        jp      z, .CheckInstrLeftScreen        ; Jump if no collision

; - Home-Screen Clicked
        ld      a, (TitleScreenStatus)
        set     6, a                            ; Set Title-Main flag
        res     5, a                            ; Reset Title-Instr flag
        ld      (TitleScreenStatus), a

        ld      a, 0                            ; Reset instr screen status
        ld      (TitleInstrStatus), a
        ret

; Check Left-Screen Sprite UI
.CheckInstrLeftScreen:
        ld      a, (TitleInstrStatus)
        cp      1
        jp      z, .CheckInstrRightScreen       ; Jump instruction screen 1

        ld      a, (TitleInstrLeftSpriteNumber)
        call    TitleUICheckCollision

        cp      0                               ; Return value
        jp      z, .CheckInstrRightScreen       ; Jump if no collision

; - Left-Screen Clicked
        ld      a, (TitleInstrStatus)
        cp      1
        jp      nz, .PreviousInstr              ; Jump if not Instr1 screen

        ld      a, (TitleScreenStatus)
        set     6, a                            ; Set Title-Main flag
        res     5, a                            ; Reset Title-Instr1 flag
        ld      (TitleScreenStatus), a

        ld      a, 0                            ; Reset instr screen status
        ld      (TitleInstrStatus), a
        ret

.PreviousInstr:
        dec     a
        ld      (TitleInstrStatus), a           ; Set to previous Instr screen
        ret

; Check Right-Screen Sprite UI
.CheckInstrRightScreen:
        ld      a, (TitleInstrStatus)
        cp      TitleInstrNumberPages
        ret     z                              ; Return if on last instruction screen

        ld      a, (TitleInstrRightSpriteNumber)
        call    TitleUICheckCollision

        cp      0                               ; Return value
        ret     z                               ; Return if no collision

; - Right-Screen Clicked
        ld      a, (TitleInstrStatus)
        inc     a
        ld      (TitleInstrStatus), a           ; Set to next Instr screen
        ret

; --- Check Title-HighScore UI
.CheckHighScoreUI:
; Check Home-Screen Sprite UI
        ld      a, (TitleHighScoreHomeSpriteNumber)
        call    TitleUICheckCollision

        cp      0                               ; Return value
        ret     z                               ; Return if no collision

; - Home-Screen Clicked
        ld      a, (TitleScreenStatus)
        set     6, a                            ; Set Title-Main flag
        res     2, a                            ; Reset Title-HighScore flag
        set     1, a                            ; Set Title-HighScore to Main transition flag
        ld      (TitleScreenStatus), a

        ret

;-------------------------------------------------------------------------------------
; Check Reticule to UI Sprite Collision - Title Screen
; Parmeters:
; a = UI Sprite Number
; Return Values:
; a = 0 - No collision, 1 - Collision
TitleUICheckCollision:
        ld      iy, Sprites

        ld      d, S_SPRITE_TYPE
        ld      e, a
        mul     d, e

        add     iy, de

        call    CheckCollision          ; Check collision between reticule and UI sprite; return = a

        ret

;-------------------------------------------------------------------------------------
; Scroll Text Sprites - Title Screen
; Parameters:
; Return Values:
TitleScrollTextSprites:
; Set scroll text pointer
        ld      hl, TitleScrollText                     ; Assume standard title scroll text

        ld      a, (TitleScreenStatus)
        bit     0, a
        jp      z, .BypassChange                        ; Jump if not entering HighScore name

        ld      hl, TitleScrollHighScoreText

.BypassChange:
        ld      (TitleScrollTypeTextPointer), hl

; Check whether we should delay spawning new sprite
        ld      a, (TitleScrollSpawnDelayCounter)
        cp      0
        jp      z, .SpawnNewTextSprite                  ; Jump if delay counter = 0

; Don't Spawn new sprite but scroll sprites
        dec     a
        ld      (TitleScrollSpawnDelayCounter), a       

.ScrollSprites:
; Scroll sprites
        ld      iy, TitleScrollSpritesStart

        ld      b, TitleScrollNumSprites
.ScrollLoop:
        push    bc

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .NextScrollSprite

        ld      hl, (iy+S_SPRITE_TYPE.xPosition)
        ld      de, 0
        or      a
        sbc     hl, de
        jp      nz, .UpdateXPosition                    ; Jump if sprite x!=0

; Delete scroll sprite
        call    DeleteSprite

        jp      .NextScrollSprite

.UpdateXPosition:
; Scroll to the left
        dec     hl
        ld      (iy+S_SPRITE_TYPE.xPosition), hl                
        ld      (iy+S_SPRITE_TYPE.XWorldCoordinate), hl         

        ld      ix, iy

        push    iy
        call    DisplaySprite
        pop     iy

.NextScrollSprite:
        ld      de, S_SPRITE_TYPE
        add     iy, de                                  ; Point to next scroll sprite

        pop     bc

        djnz    .ScrollLoop

        ret

; Spawn new text sprite
.SpawnNewTextSprite:
        ld      a, (GameStatus3)
        set     5, a
        ld      (GameStatus3), a                ; Set flag to ensure sprite spawned at correct offset
        
        ld      ix, (TitleScrollTypeTextPointer)    ; Point to correct scroll text

        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      de, (TitleScrollTextPointer)    ; Point to text character
        add     ix, de
        ld      a, 0
        call    PrintSpriteText

        ld      a, (GameStatus3)
        res     5, a
        ld      (GameStatus3), a                ; Reset text scroll flag

        ld      de, (TitleScrollTextPointer)

; Check for animated sprite
        bit     4, a
        jp      nz, .AnimatedSprite             ; Jump if spawned animated text sprite

.BypassAnimatedSprite:
; Check whether end of scroll text reached
        ld      a, (ix)                         ; Obtain current text character
        cp      0
        jp      nz, .UpdateScrollCounter        ; Jump if end of scroll text not reached

; - End of text string reached
        ld      de, 0
        ld      (TitleScrollTextPointer), de    ; Reset pointer to first text character

        jp      .SpawnNewTextSprite

.AnimatedSprite:
        res     4, a                                    ; Reset spawned animated text flag
        ld      (GameStatus3), a

        inc     de                                      ; Update pointer to point past animated sprite pattern reference
.UpdateScrollCounter:
        inc     de                                      ; Update pointer to next text character
        ld      (TitleScrollTextPointer), de            ; Save updated text character pointer

        ld      a, TitleScrollSpawnDelay
        ld      (TitleScrollSpawnDelayCounter), a       ; Reset scroll delay counter

        jp      .ScrollSprites

        ret

;-------------------------------------------------------------------------------------
; Configure tilemap palette offset + tilemap definition 0 - Title Screen
; - Note: Configured based on CurrentLevel
; Parameters:
; Return Values:
TitleTileMapPalDefinition:
; Configure TileMap palette offset based on CurrentLevel
        ld      a, (GameStatus3)
        bit     6, a
        jp      z, .LevelUnlocked               ; Jump if CurrentLevel not locked

        ld      hl, TitleTilemapTileLocked      ; Obtain locked palette offset 

        jp      .LevelCommon

.LevelUnlocked:
        ld      a, (CurrentLevel)
        dec     a                       ; Decrement as we offset table from 0
	
        ld      d, a                    ; CurrentLevel-1
        ld      e, TitleTilemapValues   ; Size of table entries
        mul     d, e                    ; Calculate offset into TitleTilemapTile table

        ld      hl, TitleTilemapTile
        add     hl, de                  ; Table location

.LevelCommon:
	push	hl			; Save table location

        ld      a, (hl)                 ; Obtain palette offset
        call    SelectTileMapPalOffset

; Configure/Copy TileMap tile definition based on CurrentLevel
; Note:	Tilemap display configured with definition 0.
;	Therefore copies appropriate level definition (128 bytes) into definition 0
	pop	hl			; Restore table location

	inc	hl			; Point to tilemap number in table

        ld      d, (hl)
        ld      e, 128
        mul     d, e			; Calculate tilemap definition offset

        add     de, TileMapDefLocation
        ld      hl, de                  ; Source: CurrentLevel tilemap definition

        ld      de, TileMapDefLocation	; Destination: Tilemap definition 0

        ld      bc, 128
        ldir    			; Replace tilemap definition 0 with level tilemap definition

	ret

;-------------------------------------------------------------------------------------
; Scroll Tilemap - Title Screen
; Note: Scrolls tilemap based on entries within TitleTilemapScrollDir table
; 28/11/23 - No longer used
; Parameters:
TitleScrollTileMap:
/*
; Scroll tilemap background
        ld      hl, (TitleTilemapScrollDirOffset)       ; Obtain current table location

        ld      a, (TitleTilemapScrollDirCounter)
        cp      0
        jp      nz, .ContTilemapScroll                  ; Jump if duration counter > 0

; - Access new table entry
        add     hl, S_TITLE_TILEMAPSCROLL               ; Point to new table line

        ld      a, (hl)                                 ; Get new table line first entry
        cp      99                                      ; 99 indicates end of table
        jp      nz, .StoreNewTableLocation              ; Jump if not at end of table

        ld      hl, TitleTilemapScrollDir               ; Otherwise reset back to top of table

.StoreNewTableLocation:
        ld      (TitleTilemapScrollDirOffset), hl       ; Store new table location

        ld      ix, hl
        ld      a, (ix+S_TITLE_TILEMAPSCROLL.Duration)  ; Get new duration value

.ContTilemapScroll:
        dec     a
        ld      (TitleTilemapScrollDirCounter), a       ; Update duration counter

        ld      ix, hl

        ld      hl, (ix)                                ; Get table X & Y updates
        ld      de, (TitleTilemapScrollXValue)          ; Get current X & Y scroll values

; - Update X scroll values
        ld      a, e
        nextreg $2f, 0
        nextreg $30, a

        add     a, l
        ld      (TitleTilemapScrollXValue), a

; - Update Y scroll value
        ld      a, d
        nextreg $31, a

        add     a, h
        ld      (TitleTilemapScrollYValue), a

*/
        ret

;-------------------------------------------------------------------------------------
; Configure Layer2 settings - Title Screen
; Parameters:
TitleLayer2Setup:
; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      

; *** Configure Layer 2 Memory Bank ***
;  LAYER 2 RAM PAGE REGISTER
; - References 16kb memory banks
        nextreg $12, $$Layer2Picture/2 

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

; Import L2 palette
        ld      a, $$TitleL2Palette     ; Memory bank (8kb) containing L2 palette data        
        nextreg $53, a

        ld      hl, TitleL2Palette      ; Address of first byte of L2 palette data
        call    SetupLayer2Pal

        ret

;-------------------------------------------------------------------------------------
; Configure Layer2 settings - Presents Screen
; Parameters:
TitlePresentsLayer2Setup:
; *** Setup Layer-2 ***
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      

; *** Configure Layer 2 Memory Bank ***
;  LAYER 2 RAM PAGE REGISTER
; - References 16kb memory banks
        nextreg $12, L2Start_16_Bank

; *** Setup Layer 2 Resolution
; LAYER 2 CONTROL REGISTER
; - Layer 2 screen resolution - 320 x 256 x8bpp - L2 palette offset +0
        nextreg $70, %00'01'0000        

; *** Reset Scrolling Offset Registers ***
; LAYER 2 X OFFSET REGISTER
        ld      a, L2ScrollOffsetX
        nextreg $16, a 
; LAYER 2 X OFFSET MSB REGISTER
        nextreg $71, %0000000'0
; LAYER 2 Y OFFSET REGISTER
        ld      a, L2ScrollOffsetY
        nextreg $17, a

; Obtain reference to L2 palette
        ld      a, $$TitleL2Palette     ; Memory bank (8kb) containing L2 palette data        
        nextreg $53, a

; Clear L2 palette
; *** Select Layer 2 Palette and Palette Index ***
; ENHANCED ULA CONTROL REGISTER
        nextreg $43, %0'001'0'0'0'1  ; Layer 2 - First palette
; PALETTE INDEX REGISTER
        nextreg $40,0               ; Start with color index 0

; *** Clear Layer 2 Palette Data
; ENHANCED ULA PALETTE EXTENSION REGISTER
; - Two consecutive writes are needed to write the 9 bit colour:
; - 1st write: bits 7-0 = RRRGGGBB
; - 2nd write: bits 7-1 are reserved, must be 0 (except bit 7 for Layer 2), bit 0 = lsb B
        ld      b, 0                 ; 256 colors (loop counter)
.ClearPaletteLoop:
        ld      a, 0
        nextreg $44,a
        nextreg $44,a
        djnz    .ClearPaletteLoop

        ret

;-------------------------------------------------------------------------------------
; Print String via Tiles across multiple lines - Title Screen
; Parameters
; ix = Pointer to -- x, y, width, Text to display suffixed by 0
;       x starting position - (0 to 39)
;       y starting position - (0 to 31)
;       Width of line - Measured from screen x=0 position
TitlePrintTileStringLines:
; Calculate starting location        
        ld      a, (ix+1)               ; y starting position
        ld      d, a
        ld      e, TileMapWidth
        mul     d, e

        ld      hl, TileMapLocation
        add     hl, de
        ld      (BackupWord3), hl       ; Save start address of 1st line

        ld      a, (ix)                 ; x starting position
        add     hl, a                   ; Calculate first tile location

        ld      b, a                    ; Set line character counter
        ld      (BackupByte4), a        ; Save x starting position

        ld      a, (ix+2)           
        ld      c, a                    ; Obtain line width

        inc     ix
        inc     ix
        inc     ix                      ; Point to text
.PrintTileLoop:
        ld      a, (ix)
        cp      0
        ret     z                       ; Terminate when end character reached

        cp      1
        jp      z, .NextLine            ; Jump if carriage return indicator

        sub     TitleTextDelta          ; Calculate tile definition position

        ld      (hl), a                 ; Write tile to tilemap
        
        inc     b                       ; Increment characters written to line
        inc     hl                      ; Point to next tilemap location

        ld      a, b                    ; Get number of characters written to line
        cp      c
        jr      nz, .NextTile           ; Jump if number of characters doesn't exceed line width

.NextLine:
        ld      hl, (BackupWord3)       ; Restore memory address for start of current line
        ld      a, TileMapWidth
        add     hl, a                   ; Point to memory address for start of next line
        ld      (BackupWord3), hl

        ld      a, (BackupByte4)
        add     hl, a                   ; Add x starting position to ensure new line starts below first

        ld      b, a                    ; Reset character line character counter

.NextTile:
        inc     ix                      ; Point to next character in string
        jr      .PrintTileLoop

        ret

;-------------------------------------------------------------------------------------
; Title-Main Screen - Title Screen
; Parameters
TitleMainScreen:
; Check whether opening Title-Main screen for the first time
        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .ReOpenTitleScreen           ; Jump if not opening Title-Main screen for 1st time

; Display Title-Main Screen for 1st time
        call    DisplayTitleMainScreen

        ld      hl, 0
        ld      (TitleScrollTextPointer), hl    ; Only reset the 1st time and not when moving between title screens

        ld      a, (TitleScreenStatus)
        res     7, a                             ; Reset open Title-Main screen 1st time
        ld      (TitleScreenStatus), a

; - Open Screen
        ld      a, %00000010
        ld      (GameStatus), a                 ; Open Screen

.ScreenLoop:
        halt

        ld      a, 0                            ; Tilemap/Layer2+Sprite areas
        call    ProcessScreen

        ld      a, (GameStatus)
        bit     1, a
        jp      nz, .ScreenLoop                 ; Jump if screen still opening

        jp      .TitleMainLoop

; Re-Opening Title-Main screen after highscore or instruction screens
.ReOpenTitleScreen:
        call    DisplayTitleMainScreen

; - Check whether transitioning from HighScore to Main screen
        ld      a, (TitleScreenStatus)
        bit     1, a
        jp      nz, .HighScoreReturn            ; Jump if returning from HighScore screen

; Immediately open tilemap, layer2 and sprite screens
        ld      a, TileMapYOffsetTop
        ld      (ClearScreenY1Counter), a
        ld      a, TileMapYOffsetBottom
        ld      (ClearScreenY2Counter), a

        ld      a, TileMapXOffsetLeft
        ld      (ClearScreenX1Counter), a
        ld      a, TileMapXOffsetRight
        ld      (ClearScreenX2Counter), a

        ld      a, 0                            ; Open tilemap & sprite screens
        ld      (BackupByte7), a
        call    UpdateScreen

.HighScoreReturn:
        ld      a, (TitleScreenStatus)
        res     1, a                            ; Reset HighScore to Main Screen transition flag
        ld      (TitleScreenStatus), a

; Title-Main Functionality
.TitleMainLoop:
        halt

        call    TitleScrollTextSprites

; Animate Friendly sprites
        ld      iy, Sprites

        ld      b, MaxSprites
.AnimateLoop:
        push    bc

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .NextSprite

        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NextSprite                  ; Jump if sprite not friendly

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern
        
.NextSprite
        ld      bc, S_SPRITE_TYPE
        add     iy, bc

        pop     bc

        djnz    .AnimateLoop

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Scroll every alternate frame
        ld      a, (TitleTileMapScrollBypass)
        cp      0
        jp      z, .Scroll                      ; Jump if bypass not set

        dec     a
        ld      (TitleTileMapScrollBypass), a   ; Set scroll bypass
        jp      .BypassScroll

.Scroll:
/* - 06/03/24 - Removed scroll based on mouse input
; Scroll tilemap background based on mouse movement
; - Update X scroll values
        ld      a, (MouseXDelta)
        bit     7, a
        jp      nz, .LeftScroll                 ; Jump if moving to left

        ld      a, (TitleTilemapScrollXValue)
        inc     a
        ld      (TitleTilemapScrollXValue), a   ; Scroll to right
        
        jp      .ScrollX

*/
.LeftScroll:
        ld      a, (TitleTilemapScrollXValue)
        dec     a
        ld      (TitleTilemapScrollXValue), a   ; Scroll to left

.ScrollX:
        nextreg $2f, 0
        nextreg $30, a

/* - 06/03/24 - Removed scroll based on mouse input
; - Update Y scroll values
        ld      a, (MouseYDelta)
        bit     7, a
        jp      nz, .UpScroll                   ; Jump if moving up

        ld      a, (TitleTilemapScrollYValue)
        inc     a
        ld      (TitleTilemapScrollYValue), a   ; Scroll down
        
        jp      .ScrollY

*/
.UpScroll:
        ld      a, (TitleTilemapScrollYValue)
        dec     a
        ld      (TitleTilemapScrollYValue), a   ; Scroll up

.ScrollY:
        nextreg $31, a

        ld      a, 1
        ld      (TitleTileMapScrollBypass), a   ; Bypass scroll next frame

.BypassScroll:        
; Mouse input
        call    TitleReadPlayerInput
        call    TitleCheckUpdateReticule
        call    UpdateReticulePosition          ; Display reticule at updated position

; Check player input
; - Check reticule to UI sprite collision
        ld      a, (PlayerInput)
        bit     5, a
        jp      z, .TitleMainLoop               ; Jump if LMB not pressed

; - Check reticule-to-UI elements
        call    TitleMainUICollision

; - Check whether we should continue on the Start-Main screen
        ld      a, (TitleScreenStatus)
        bit     6, a
        jp      nz, .TitleMainLoop              ; Jump if Title-Main flag set

	ret
        
;-------------------------------------------------------------------------------------
; Title-Instructions Screen - Title Screen
; Parameters
DisplayTitleInstrScreen:
; --- Tilemap ---
; Note: Tilemap patterns and palette already setup within Title-Main routine 
        ld      a, 24                           ; 'space'
        call    ClearTileMapScreen

; - Reset scroll registers to ensure tile shown at correct offset
        nextreg $2f, 0
        nextreg $30, 0
        nextreg $31, 0

; --- Tilemap ---
; Note: Required to ensure palette cycling is reset for each instruction screen
; - Setup Tilemap Palette
        ld      a, $$TitleTileMapDefPal         ; Memory bank (8kb) containing tilemap palette data        
        ld      hl, TitleTileMapDefPal          ; Address of first byte of layer 2 palette data
        ld      b, TitleTileMapDefPalRows       ; Number of rows in palette
        call    SetupTileMapPalette

; Reset Tilemap Cycle Counters
	ld	a, 0
	ld	(TitleCycleTMLoopPauseCounter), a

        ld      a, TitleCycleTMColCycles
        ld      (TitleCycleTMColCyclesCounter), a

        ld      a, 0
	ld	(CycleTMColourDelayCounter), a

; Expand tilemap
        nextreg $1c, %0000'1000                 ; Reset tilemap clip write index
        ld      a, TileMapXOffsetLeft
        nextreg $1b, a                          ; X1 Position
        ld      a, TileMapXOffsetRight       
        nextreg $1b, a                          ; X2 Position

        ld      a, TileMapYOffsetTop     
        nextreg $1b, a                          ; Y1 Position
        ld      a, TileMapYOffsetBottom            
        nextreg $1b, a                          ; Y2 Position

; --- Sprites ---
        call    ImportTitleInstrSprites

; - ReMap ULA Memory bank 10 (16KB) to slot 3; previously remapped when importing palettes
;   Note: Only need to remap slot 3 as slot 4 no longer used when importing sprites
        nextreg $53, 10
        
; - Change reticule sprite to new sprite pattern
        ld      ix, ReticuleSprAtt
        ld      iy, ReticuleSprite
        ld      bc, TitleInstrReticulePatterns  ; Sprite pattern range
        call    UpdateSpritePattern

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Check whether opening Title-Instructions screen for the first time
        ld      a, (TitleScreenStatus)
        bit     3, a
        jp      z, .BypassUISprites             ; Jump if not opening Title-Instructions screen for 1st time

        res     3, a
        ld      (TitleScreenStatus), a

; - Spawn UI sprites
; -- Spawn Home-Screen sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleInstrHomeScreenXY      ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 11
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 11
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleInstrHomeSpriteNumber), a         

        set     6, (ix+S_SPRITE_TYPE.SpriteType5)       ; Ensure sprite not reset
        set     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Ensure not hidden when reset in instructions screen

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleInstrUIHomePatterns    ; Sprite pattern range
        call    UpdateSpritePattern

; -- Spawn Left-Screen sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleInstrLeftScreenXY      ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 11
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 11
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleInstrLeftSpriteNumber), a         

; --- Vertically mirror sprite
        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        set     3, a
        ld      (iy+S_SPRITE_ATTR.mrx8), a

        set     6, (ix+S_SPRITE_TYPE.SpriteType5)       ; Ensure sprite not reset
        set     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Ensure not hidden when reset in instructions screen

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleInstrUIRightPatterns   ; Sprite pattern range
        call    UpdateSpritePattern

; -- Spawn Right-Screen sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, TitleInstrRightScreenXY     ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 11
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 11
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleInstrRightSpriteNumber), a         

        set     6, (ix+S_SPRITE_TYPE.SpriteType5)       ; Ensure sprite not reset
        set     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Ensure not hidden when reset in instructions screen

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleInstrUIRightPatterns   ; Sprite pattern range
        call    UpdateSpritePattern

.BypassUISprites:
; --- Layer2 ---
; DISPLAY CONTROL 1 REGISTER
; - Disable Layer 2
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %0'0'000000      

; --- Content ---
; Obtain memory bank number currently mapped into slot 7 and save allowing restoration
; - Slot to be used to map title instruction text into memory
; - MMU7 - $e000-$ffff
	ld      a,$57                           ; Port to access - Memory Slot 7
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
	ld      (TitleMMU7MemoryBank), a        ; Save current bank number in slot 7

; - Swap instruction text memory bank into slot 7
	ld      a, $$TitleInstrText             ; Instruction text memory bank
	nextreg $57, a                          ; Swap memory bank

; - Update copper based on machine speed
        ld      ix, TitleInstrHeadingCycleCopperListEndScanLine
        ld      (ix+1), TitleInstrHeadingCycleCopperList60EndScanline   ; Assume update for 60hz

        ld      iy, TitleInstrLevelStatusHeadingCycleCopperListEndScanLine
        ld      (iy+1), TitleInstrHeadingCycleCopperList60EndScanline   ; Assume update for 60hz

        ld      a, $05
        call    ReadNextReg

        bit     2, a
        jp      nz, .DisplayScreen              ; Jump if 60hz

        ld      (ix+1), TitleInstrHeadingCycleCopperList50EndScanline   ; Otherwise update for 50hz
        ld      (iy+1), TitleInstrHeadingCycleCopperList50EndScanline   ; Assume update for 60hz

.DisplayScreen:
; - Check which instruction screen to show
        ld      a, (TitleInstrStatus)
        cp      1
        call    z, DisplayTitleInstrBackground
        cp      2
        call    z, DisplayTitleInstrPurpose
        cp      3
        call    z, DisplayTitleInstrLevelStatus
        cp      4
        call    z, DisplayTitleInstrAbilities
        cp      5
        call    z, DisplayTitleInstrLockers
        cp      6
        call    z, DisplayTitleInstrDoorTypes
        cp      7
        call    z, DisplayTitleInstrSavePoints
        cp      8
        call    z, DisplayTitleInstrHazards
        cp      9
        call    z, DisplayTitleInstrEnemies
        cp      10
        call    z, DisplayTitleInstrDisplay
        cp      11
        call    z, DisplayTitleInstrControls

; - Swap original memory bank back into slot 7
	ld      a, (TitleMMU7MemoryBank)        ; Restore original memory bank
	nextreg $57, a                          ; Swap memory bank

; Reset Tilemap Cycle Counters
	;ld	a, 0
	;ld	(TitleCycleTMLoopPauseCounter), a

        ;ld      a, TitleCycleTMColCycles
        ;ld      (TitleCycleTMColCyclesCounter), a

        ;ld      a, 0
	;ld	(CycleTMColourDelayCounter), a

        ret

;-------------------------------------------------------------------------------------
; Reset Sprites - Title Screen
; Note: Resets all sprites except reticule (0) and scrolling text sprites
; Parameters:
; a = Number of sprites to reset (max = 128 * 4-bit sprites or 64 * 8-bit sprites)
TitleResetSprites:
; Release Sprite Data slots
        ld      ix, Sprites+S_SPRITE_TYPE       ; Start from sprite 1 (not sprite 0=reticule)
        ld      iy, SpriteAtt+S_SPRITE_ATTR     ; Start from sprite 1 (not sprite 0=reticule)

        ld      b, a
.DisableSpriteLoop:
        ld      a, (ix+S_SPRITE_TYPE.SpriteType5) 
        bit     6, a
        jp      z, .DisableSprite                       ; Jump if not text scroll or instructions UI sprite

        bit     7, a
        jp      z, .HideSprite                          ; Jump if not instructions UI sprite

        ld      a, (TitleScreenStatus)
        bit     5, a
        jp      nz, .BypassDisable                      ; Jump if on instructions screen

.HideSprite:
        res     7, (iy+S_SPRITE_ATTR.vpat)              ; Hide sprite

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Reset visible flag

        jp      .BypassDisable

.DisableSprite:
        ld      (ix+S_SPRITE_TYPE.active), 0            ; Clear active flag
        ld      (ix+S_SPRITE_TYPE.AttrOffset), 0

        ld      a, 0                                    ; Hide sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

.BypassDisable:
        ld      de, S_SPRITE_TYPE
        add     ix, de                                  ; Point to next sprite

        ld      de, S_SPRITE_ATTR
        add     iy, de                                  ; Point to next sprite

        djnz    .DisableSpriteLoop

        ld      a, MaxSprites
        call    UploadSpriteAttributesDMA

        ret

;-------------------------------------------------------------------------------------
; Reset Scrolling Text Sprites - Title Screen
; Note: Resets scrolling text sprites only
; Parameters:
; a = Number of sprites to reset (max = 128 * 4-bit sprites or 64 * 8-bit sprites)
TitleResetScrollingTextSprites:
; Release Sprite Data slots
        ld      ix, Sprites+S_SPRITE_TYPE       ; Start from sprite 1 (not sprite 0=reticule)
        ld      iy, SpriteAtt+S_SPRITE_ATTR     ; Start from sprite 1 (not sprite 0=reticule)

        ld      b, a
.DisableSpriteLoop:
        ld      a, (ix+S_SPRITE_TYPE.SpriteType5) 
        bit     6, a
        jp      z, .BypassDisable                       ; Jump if not text scroll sprite

        ld      (ix+S_SPRITE_TYPE.active), 0            ; Clear active flag
        ld      (ix+S_SPRITE_TYPE.AttrOffset), 0

        ld      a, 0                                    ; Hide sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

.BypassDisable:
        ld      de, S_SPRITE_TYPE
        add     ix, de                                  ; Point to next sprite

        ld      de, S_SPRITE_ATTR
        add     iy, de                                  ; Point to next sprite

        djnz    .DisableSpriteLoop

        ld      a, MaxSprites
        call    UploadSpriteAttributesDMA

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions Screen - Title Screen
; Parameters
TitleInstrScreen:
; Display required Title-Instr Screen
        call    DisplayTitleInstrScreen

; Title-Instr Functionality - Common to all instruction screens
.TitleInstrLoop:
        halt

; - Cycle TileMap Colours
; -- Outer loop controlling pause after complete col cycle
        ld      a, (TitleCycleTMLoopPauseCounter)
        cp      0
        jp      nz, .BypassCycle

; --- Loop controlling complete col cycle
        ld      a, (TitleCycleTMColCyclesCounter)
        cp      0
        jp      nz, .ColCycle                   ; Jump if not performed complete col cycle

        ld      a, TitleCycleTMColCycles
        ld      (TitleCycleTMColCyclesCounter), a

        ld      a, TitleCycleTMLoopPause
        ld      (TitleCycleTMLoopPauseCounter), a
        
        jp      .ContAfterCycle

.ColCycle:
; ---- Loop controlling col cycle
        ld      a, (CycleTMColourDelayCounter)
        cp      0
        jp      nz, .UpdateCycleTMCounter       ; Jump if delay between col cycle

        ld      a, 152                          ; Index of end colour
        ld      b, 6                            ; Number of colours to cycle-1
        ld      d, %1'011'0'0'0'1               ; Tilemap first palette
        call    CyclePalette

        ld      a, (TitleCycleTMColCyclesCounter)
        dec     a
        ld      (TitleCycleTMColCyclesCounter), a

        ld      a, TitleCycleTMColourDelay+1

.UpdateCycleTMCounter:
        dec     a
        ld      (CycleTMColourDelayCounter), a

        jp      .ContAfterCycle

.BypassCycle:
        dec     a
        ld      (TitleCycleTMLoopPauseCounter), a

.ContAfterCycle:
; Animate Friendly sprites
        ld      iy, Sprites

        ld      b, MaxSprites
.AnimateLoop:
        push    bc

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .NextSprite

        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NextSprite                          ; Jump if sprite not friendly

        bit     7, (iy+S_SPRITE_TYPE.SpriteType5)
        jp      nz, .ProcessSprite                      ; Jump if UI sprite

        bit     6, (iy+S_SPRITE_TYPE.SpriteType5)
        jp      nz, .NextSprite                         ; Jump if text scroll sprite (currently not visible)

.ProcessSprite:
        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern
        
.NextSprite
        ld      bc, S_SPRITE_TYPE
        add     iy, bc

        pop     bc

        djnz    .AnimateLoop

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Mouse input
        call    TitleReadPlayerInput
        call    TitleCheckUpdateReticule
        call    UpdateReticulePosition          ; Display reticule at updated position

; Check player input
; - Check reticule to UI sprite collision
        ld      a, (PlayerInput)
        bit     5, a
        jp      z, .TitleInstrLoop               ; Jump if LMB not pressed

; - Check reticule-to-UI elements
        ld      a, (TitleInstrStatus)
        push    af                              ; Save old copy

        call    TitleMainUICollision

        ld      a, (TitleInstrStatus)
        ld      b, a                            ; Obtain new copy

        pop     af

; - Check whether we should continue on the Start-Instr screen
        cp      b
        jp      z, .TitleInstrLoop              ; Jump if old=new i.e. No change

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions Screen Upload Copper - Title Screen
; Parameters
; hl - Copper List
; bc - Copper List Size
TitleInstrUploadCopper:
; Stop copper and set data upload index to 0
	nextreg $61, %00000000
	nextreg $62, %00000000

; Copy copper list parameters into DMA code
	ld      (DMACopperUploadStart), hl
	ld      (DMACopperUploadLength), bc

; We want to upload to NEXTREG $63, select it with $243B port
	ld      a, $63
	ld      bc, $243B
	out     (c), a

; Upload DMA instructions to DMA memory
	ld      hl, DMACopperUpload             ; hl = pointer to DMA program
	ld      b, DMACopperUploadCopySize	; b = size of the code
	ld      c, $6B		                ; C = $6B (DMA port)
	otir			                ; upload DMA program

; Finally start copper using mode %11
	nextreg $61, %00000000          ; Reset copper index to 0
	NEXTREG $62, %11'000'000        ; Auto-reset CPC to 0 on vertical blank

	ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Background Screen - Title Screen
; Parameters
DisplayTitleInstrBackground:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrBackgroundTextXY
        call    TitlePrintTileStringLines

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Purpose Screen - Title Screen
; Parameters
DisplayTitleInstrPurpose:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrPurposeTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrPurposeSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Controls Screen - Title Screen
; Parameters
DisplayTitleInstrControls:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrControlsTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrControlsSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Level Status Screen - Title Screen
; Parameters
DisplayTitleInstrLevelStatus:
; - Implement Copper List
        ld       hl, TitleInstrLevelStatusCopperList
        ld       bc, TitleInstrLevelStatusCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrLevelStatusTextXY
        call    TitlePrintTileStringLines

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Abilities Screen - Title Screen
; Parameters
DisplayTitleInstrAbilities:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrAbilitiesTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrAbilitiesSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Lockers Screen - Title Screen
; Parameters
DisplayTitleInstrLockers:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrLockersTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrLockersSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Door Types Screen - Title Screen
; Parameters
DisplayTitleInstrDoorTypes:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrDoorTypesTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrDoorTypesSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Save Points Screen - Title Screen
; Parameters
DisplayTitleInstrSavePoints:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrSavepointsTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrSavePointsSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Hazards Screen - Title Screen
; Parameters
DisplayTitleInstrHazards:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrHazardsTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrHazardsSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Enemies Screen - Title Screen
; Parameters
DisplayTitleInstrEnemies:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrEnemiesTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrEnemiesSprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions-Display Screen - Title Screen
; Parameters
DisplayTitleInstrDisplay:
; - Implement Copper List
        ld       hl, TitleInstrHeadingCycleCopperList
        ld       bc, TitleInstrHeadingCycleCopperListSize
        call    TitleInstrUploadCopper

; Update UI Sprites
        call    DisplayTitleInstrUI

; Display Text
        ld      ix, TitleInstrDisplayTextXY
        call    TitlePrintTileStringLines

; Display Sprites
        ld      ix, TitleInstrDisplaySprites
        call    DisplayTitleInstrSprites

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions UI Visibility - Title Screen
; Parameters
DisplayTitleInstrUI:
; Home-Screen Sprite
        ld      a, (TitleInstrHomeSpriteNumber)
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     d, e

        ld      ix, Sprites
        add     ix, de                                  
        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)
        ld      iy, hl

; - Show Home-Screen sprite
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        set     7, a                                    ; Make sprite visible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - visible sprite, 4Byte, sprite pattern

        set     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Set visible flag, required for sprite animation

; Left-Screen Sprite
        ld      a, (TitleInstrLeftSpriteNumber)
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     d, e

        ld      ix, Sprites
        add     ix, de                                  
        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)
        ld      iy, hl

        ld      a, (TitleInstrStatus)
        cp      1
        jp      z, .HideLeftScreenSprite                ; Jump if on 1st instruction screen

; - Show Left-Screen sprite
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        set     7, a                                    ; Make sprite visible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - visible sprite, 4Byte, sprite pattern

        set     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Set visible flag, required for sprite animation

        jp      .RightScreenSprite

; - Hide Left-Screen sprite
.HideLeftScreenSprite:
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        res     7, a                                    ; Make sprite invisible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - visible sprite, 4Byte, sprite pattern

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Reset visible flag, required for sprite animation

; Right-Screen Sprite
.RightScreenSprite:
        ld      a, (TitleInstrRightSpriteNumber)
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     d, e

        ld      ix, Sprites
        add     ix, de                                  
        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)
        ld      iy, hl

        ld      a, (TitleInstrStatus)
        cp      TitleInstrNumberPages
        jp      z, .HideRightScreenSprite               ; Jump if on last instruction screen

; - Show Right-Screen sprite
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        set     7, a                                    ; Make sprite visible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - visible sprite, 4Byte, sprite pattern

        set     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Set visible flag, required for sprite animation

        ret

; - Hide Right-Screen sprite
.HideRightScreenSprite:
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        res     7, a                                    ; Make sprite invisible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - visible sprite, 4Byte, sprite pattern

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Reset visible flag, required for sprite animation

        ret

;-------------------------------------------------------------------------------------
; Title-Instructions Display Sprites - Title Screen
; Parameters
; ix - Sprite Table
DisplayTitleInstrSprites:
.SpriteLoop:
; Obtain Sprite Data
; - Check for end of table
	ld	hl, (ix)			; Get Block y, Block x
	ld	a, l
	cp	0
	ret	z                               ; Return if 0

	push	ix

; - Store table entries
	ld	(TitleInstrSpriteBlockXY), hl
	ld	hl, (ix+2)			; Get Add. x, Add. y 
	ld	(TitleInstrSpriteXY), hl
	ld	hl, (ix+4)			; Get Pattern
	ld	(TitleInstrSpritePattern), hl
        ld      a, (ix+6)                       ; Get mirror flag
        ld      (TitleInstrSpriteMirror), a

; - Spawn Sprite
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
	ld	hl, (TitleInstrSpriteBlockXY)   ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

; - Adjust Position
	ld	de, (TitleInstrSpriteXY)        ; Restore Add. x and Add. y

	ld	a, d	
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
	add	hl, a
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl

	ld	a, e
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
	add	hl, a
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

        call    DisplaySprite

        ld      a, (TitleInstrSpriteMirror)
        cp      0
        jp      z, .BypassMirror

        set     3, (iy+S_SPRITE_ATTR.mrx8)              ; Set mirror horizontal

.BypassMirror:
        push    ix
        ld      ix, iy
        pop     iy

; - Change Sprite Pattern
	ld	bc, (TitleInstrSpritePattern)   ; Restore Sprite pattern range
        call    UpdateSpritePattern

	pop	ix

        ld      bc, 7
	add	ix, bc

	jp	.SpriteLoop


;-------------------------------------------------------------------------------------
; Title-HighScore Screen - HighScore Screen
; Parameters
TitleHighScoreScreen:
; Check whether opening Title-HighScore screen for the first time
        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .ReOpenHighScoreScreen       ; Jump if not opening Title-HighScore screen as 1st screen

; Display Title-HighScore Screen as 1st screen
; - Reset HighScore counters
        ld      a, 0
        ld      (TitleHighScoreKeyDelayCounter), a

        call    DisplayTitleHighScoreScreen

        ld      hl, 0
        ld      (TitleScrollTextPointer), hl    ; Only reset the 1st time and not when moving between title screens

        ld      a, (TitleScreenStatus)
        res     7, a                            ; Reset open Title-HighScore screen 1st time
        ld      (TitleScreenStatus), a

; - Open Screen
        ld      a, %00000010
        ld      (GameStatus), a                 ; Open Screen

.ScreenLoop:
        halt

        ld      a, 0                            ; Tilemap/Layer2+Sprite areas
        call    ProcessScreen

        ld      a, (GameStatus)
        bit     1, a
        jp      nz, .ScreenLoop                 ; Jump if screen still opening

        jp      .TitleHighScoreLoop

; Re-Opening Title-HighScore screen
.ReOpenHighScoreScreen:
        call    DisplayTitleHighScoreScreen

; Immediately open tilemap, layer2 and sprite screens
        ld      a, TileMapYOffsetTop
        ld      (ClearScreenY1Counter), a
        ld      a, TileMapYOffsetBottom
        ld      (ClearScreenY2Counter), a

        ld      a, TileMapXOffsetLeft
        ld      (ClearScreenX1Counter), a
        ld      a, TileMapXOffsetRight
        ld      (ClearScreenX2Counter), a

        ld      a, 0                            ; Open tilemap & sprite screens
        ld      (BackupByte7), a
        call    UpdateScreen

; Title-HighScore Functionality
.TitleHighScoreLoop:
        ld      a, (TitleScreenStatus)
        bit     0, a
        jp      z, .BypassNameEntry                     ; Jump if name entry flag not set 

; HighScore Name entry
        call    TitleHighScoreReadPlayerInput

; - Check/Update input
        cp      0
        jp      z, .BypassNameEntry                     ; Jump if no input

        push    af

        ld      a, TitleKeyDelay
        ld      (TitleHighScoreKeyDelayCounter), a      ; Otherwise set input delay

        ld      a, 1                                    ; Assume we want to update letter position after sprite updated
        ld      (BackupByte), a

        pop     af

; -- Check whether delete key pressed
        cp      "]"
        jp      nz, .CheckEnterKey                      ; Jump if delete not pressed

        ld      a, (TitleHighScoreNameCounter)
        cp      0
        jp      z, .BypassNameEntry                     ; Jump if first letter in name

; --- Delete key pressed
        dec     a
        ld      (TitleHighScoreNameCounter), a          ; Move left one letter

        ld      a, 0                                    ; Indicate we don't want to change letter position after sprite updated
        ld      (BackupByte), a

        ld      a, " "                                  ; Replace letter with " "                         

        jp      .BypassEnter

; -- Check whether enter key pressed
.CheckEnterKey:
        cp      "["
        jp      nz, .BypassEnter                        ; Jump if enter not pressed

; --- Enter key pressed
; -- Set position in score name table
        ld      iy, TitleHighScoreNames

        ld      a, (NewHighScoreEntry)
        ld      b, a                    ; Restore HighScore entry number

        ld      a, TitleHighScoreTotalEntries
        sub     b

        ld      d, a
        ld      e, S_HighScore_Names    ; Size of each name entry
        mul     d, e                    ; Position in name table
        add     iy, de
        inc     iy
        inc     iy                      ; Point to name data

; -- Copy Newname to HighScore Name table
        ld      hl, NewName
        ld      de, iy
        ld      b, 0
        ld      c, NameLength
        ldir

; -- Update CFG file
        call    TitleCFGFileWrite       ; Update CFG file

; -- Reset status
        ld      a, (TitleScreenStatus)
        res     0, a                                    ; Reset HighScore entry flag
        ld      (TitleScreenStatus), a

; -- Reset scrolling text
        ld      a, MaxSprites
        call    TitleResetScrollingTextSprites              ; Reset scrolling text sprites

        ld      a, 0
        ld      (TitleScrollTextPointer), a             ; Reset scroll message to beginning

; -- Show Home sprite
        ld      a, (TitleHighScoreHomeSpriteNumber) 
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     d, e

        ld      ix, Sprites
        add     ix, de

        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)
        ld      iy, hl

        set     7, (iy+S_SPRITE_ATTR.vpat)              ; Hide sprite
        set     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Reset visible flag

        jp      .BypassNameEntry

.BypassEnter:
; -- Check whether end of name reached
        ld      (BackupByte2), a                        ; Save letter entered

        ld      a, (TitleHighScoreNameCounter)
        cp      NameLength
        jp      z, .BypassNameEntry                     ; Jump if all letters have been entered

; -- Store letter in NewName
        ld      a, (TitleHighScoreNameCounter)
        ld      hl, NewName
        add     hl, a

        ld      a, (BackupByte2)                ; Restore letter entered
        ld      (hl), a                         ; Store letter in NewName

; - Convert ASCII value to sprite pattern value 
        sub     ASCIIDelta                      ; Set ASCII values to start from 0 and not 32 
        sra     a
        
        jp      nc, .LessThan64                 ; Jump if carry not set i.e. value even

        add     64                              ; Value odd so update value

.LessThan64:
        push    af                              ; Save new sprite pattern number

; - Calculate sprite number/address for name sprite
        ld      a, (NewHighScoreEntry)
        ld      d, a
        ld      e, NameLength
        mul     d, e

        ld      a, (TitleHighScoreHomeSpriteNumber)
        sub     e

        ld      d, a                            ; Sprite number

        ld      a, (TitleHighScoreNameCounter)  ; Add current letter offset within name e.g. 0 = First letter
        add     a, d
        ld      d, a

        ld      e, S_SPRITE_TYPE                ; Size of sprite entry
        mul     d, e                            ; Sprite offset

        ld      ix, Sprites
        add     ix, de                          ; Sprite data

        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)
        ld      iy, hl                          ; Sprite attribute data

; - Update Sprite Pattern
        pop     af                                      ; Restore new sprite pattern number

        res     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Assumption: Reset N6 = 7th pattern bit

        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern
        cp      64
        jp      c, .ContConfig                          ; Jump if pattern < 64

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, MaxSprites
        call    UploadSpriteAttributesDMA

; - Update letter position in name
        ld      a, (BackupByte)
        cp      0
        jp      z, .BypassNameEntry                     ; Jump if we don't want to update letter position i.e. Delete pressed

        ld      a, (TitleHighScoreNameCounter)
        cp      NameLength                              ; Values 0 - 3 (0, 1, 2 = Actual letters)
        jp      z, .BypassNameEntry                     ; Jump if last letter in name

        inc     a                                       
        ld      (TitleHighScoreNameCounter), a          ; Point to next letter within name

.BypassNameEntry:
        halt

        call    TitleScrollTextSprites

; Animate Friendly sprites
        ld      iy, Sprites

        ld      b, MaxSprites
.AnimateLoop:
        push    bc

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .NextSprite

        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NextSprite                  ; Jump if sprite not friendly

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern
        
.NextSprite
        ld      bc, S_SPRITE_TYPE
        add     iy, bc

        pop     bc

        djnz    .AnimateLoop

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Scroll every alternate frame
        ld      a, (TitleTileMapScrollBypass)
        cp      0
        jp      z, .Scroll                      ; Jump if bypass not set

        dec     a
        ld      (TitleTileMapScrollBypass), a   ; Set scroll bypass
        jp      .BypassScroll

.Scroll:
/* - 06/03/24 - Removed scroll based on mouse input
; Scroll tilemap background based on mouse movement
; - Update X scroll values
        ld      a, (MouseXDelta)
        bit     7, a
        jp      nz, .LeftScroll                 ; Jump if moving to left

        ld      a, (TitleTilemapScrollXValue)
        inc     a
        ld      (TitleTilemapScrollXValue), a   ; Scroll to right
        
        jp      .ScrollX
*/
.LeftScroll:
        ld      a, (TitleTilemapScrollXValue)
        dec     a
        ld      (TitleTilemapScrollXValue), a   ; Scroll to left

.ScrollX:
        nextreg $2f, 0
        nextreg $30, a

/* - 06/03/24 - Removed scroll based on mouse input
; - Update Y scroll values
        ld      a, (MouseYDelta)
        bit     7, a
        jp      nz, .UpScroll                   ; Jump if moving up

        ld      a, (TitleTilemapScrollYValue)
        inc     a
        ld      (TitleTilemapScrollYValue), a   ; Scroll down
        
        jp      .ScrollY
*/
.UpScroll:
        ld      a, (TitleTilemapScrollYValue)
        dec     a
        ld      (TitleTilemapScrollYValue), a   ; Scroll up

.ScrollY:
        nextreg $31, a

        ld      a, 1
        ld      (TitleTileMapScrollBypass), a   ; Bypass scroll next frame

.BypassScroll:
; Mouse input
        call    TitleReadPlayerInput
        call    TitleCheckUpdateReticule
        call    UpdateReticulePosition          ; Display reticule at updated position

; Check player input
; - Check reticule to UI sprite collision
        ld      a, (PlayerInput)
        bit     5, a
        jp      z, .TitleHighScoreLoop          ; Jump if LMB not pressed

        ld      a, (TitleScreenStatus)
        bit     0, a
        jp      nz, .TitleHighScoreLoop         ; Jump if entering name i.e. Don't perform UI check

; - Check reticule-to-UI elements
        call    TitleMainUICollision

; - Check whether we should continue on the Start-HighScore screen
        ld      a, (TitleScreenStatus)
        bit     2, a
        jp      nz, .TitleHighScoreLoop              ; Jump if Title-HighScore flag set

	ret

;-------------------------------------------------------------------------------------
; Setup/Display Title-HighScore Screen
; Parameters:
DisplayTitleHighScoreScreen:
; Check whether opening Title-HighScore screen as the first title screen
        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .ReOpenHighScoreScreen       ; Jump if not opening Title-HighScore screen as the first screen

; Reset title screen counters
        ld      a, 0
        ld      (TitleKeyDelayCounter), a
        
; Immediately close tilemap, layer2 and sprite screens
; - Note: Only really needed when game first started, as exiting a game session will close all screens
        ld      a, ClearScreenY1Middle
        ld      (ClearScreenY1Counter), a
        ld      a, ClearScreenY2Middle
        ld      (ClearScreenY2Counter), a

        ld      a, ClearScreenX1Middle
        ld      (ClearScreenX1Counter), a
        ld      a, ClearScreenX2Middle
        ld      (ClearScreenX2Counter), a

        ld      a, 0                            ; Close tilemap & sprite screens
        ld      (BackupByte7), a
        call    UpdateScreen

; Stop Copper
	NEXTREG $62, %00'000'000                ; Stop copper

; --- Layer Priority
; SPRITE AND LAYERS SYSTEM REGISTER
; - LowRes off
; - Sprite rendering flipped i.e. Sprite 0 (Player) on top of other sprites
; - Sprite clipping in over border mode enabled
; - Layer Priority - SUL (Top - Sprites, Layer 2, Enhanced_ULA)
; - Sprites visible and displayed in border
        nextreg $15, %0'1'1'000'1'1

; --- Tilemap ---
; Reset scroll counters to ensure tilemap displayed correctly after level has been played
        ld      bc, 0
        ld      (ScrollTileMapBlockXPointer), bc

; Setup title TileMap data
        ld      a, $$TitleTileMap               ; Memory bank (8kb) containing tilemap data
        call    SetupTitleTileMap

; Draw tilemap
        call    DrawLevelIntroTileMap

; --- Sprites ---
; Set camera starting coordinates; required for spawning sprites at correct locations
        ld      hl, 16
        ld      (CameraXWorldCoordinate), hl
        ld      (CameraYWorldCoordinate), hl

.ReOpenHighScoreScreen:
; Import Text Sprites
        call    ImportTitleMainSprites
        
; - ReMap ULA Memory bank 10 (16KB) to slot 3; previously remapped when importing sprites
;   Note: Only need to remap slot 3 as slot 4 no longer used when importing sprites
        nextreg $53, 10

        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .BypassCreateReticule        ; Jump if re-opening Title-Main screen

; Setup Mouse Reticule
; - Populate initial mouse values
        ld      bc, $FBDF			;FADF Mouse Buttons port
	in      a, (c)			        ; FBDF Mouse Xpos - Obtain new MouseX value
	ld      (XMove), a                      ; Store new mouseX value
	
	ld      b, $FF	                        ; Point to mouse Y position input port
	in      a, (c)			        ; FFDF Mouse Ypos - Obtain new MouseY value
	ld      (YMove), a                      ; Store new mouseY value

 ; - Spawn Reticule Sprite
        call    SetupReticuleSprite

        ld      hl, TitleMouseStartXPosition
        ld      a, TitleMouseStartYPosition
        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a

        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl
        ld      h, 0
        ld      l, a
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleMainReticulePatterns       ; Sprite pattern range
        call    UpdateSpritePattern

        jp      .SpritesContinue

.BypassCreateReticule:
; - Change reticule sprite to new sprite pattern
        ld      ix, ReticuleSprAtt
        ld      iy, ReticuleSprite
        ld      bc, TitleMainReticulePatterns       ; Sprite pattern range
        call    UpdateSpritePattern

.SpritesContinue:
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ld      a, (TitleScreenStatus)
        bit     7, a
        jp      z, .BypassL2                    ; Jump if re-opening Title-HighScore screen

; --- Layer2 ---
; - Configure L2 settings
        call    TitleLayer2Setup

; *** Configure Layer 2 and ULA Transparency Colour
; GLOBAL TRANSPARENCY Register
; - Changed for L2 to enable display of black
        nextreg $14,$1         ; Palette entry 1- Ensure palettes are configured correctly

; *** Setup Layer-2 *** - Required when re-opening Title-Main screen
; DISPLAY CONTROL 1 REGISTER
; - Enable Layer 2
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %1'0'000000      

.BypassL2:
; Reset all sprites except reticule and scroller sprites
        ld      a, TitleScrollSpritesAttStart-2
        call    TitleResetSprites

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; --- Content ---
; - Spawn HighScore value sprites
        ld      ix, TitleHighScoreValues
        ld      b, TitleHighScoreTotalEntries

.PrintHighScoreValues:
        push    bc, ix

        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, %1011'000'0
        call    PrintSpriteText

        pop     ix, bc

        ld      de, S_HighScore_Values
        add     ix, de

        djnz    .PrintHighScoreValues

; - Spawn HighScore name sprites
        ld      ix, TitleHighScoreNames
        ld      b, TitleHighScoreTotalEntries

.PrintHighScoreNames:
        push    bc, ix

        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, %1011'000'0
        call    PrintSpriteText

        pop     ix, bc

        ld      de, S_HighScore_Names
        add     ix, de

        djnz    .PrintHighScoreNames

; - Spawn Main-Screen sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                                    ; Spawn at first sprite attribute position
        ld      hl, TitleHighScoreHomeScreenXY          ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 11
        ld      (iy+S_SPRITE_ATTR.y), a

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 11
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), a

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        ld      (TitleHighScoreHomeSpriteNumber), a         

; - Check whether entering name, so to hide title screen sprite
        ld      a, (TitleScreenStatus)
        bit     0, a
        jp      z, .BypassHideSprite                    ; Jump if not entering name

        res     7, (iy+S_SPRITE_ATTR.vpat)              ; Hide sprite
        res     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Reset visible flag

.BypassHideSprite:
        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitleHighScoreUIHomePatterns        ; Sprite pattern range
        call    UpdateSpritePattern

; - Check whether entering name to spawn Webster sprites
        ld      a, (TitleScreenStatus)
        bit     0, a
        jp      z, .UpdateSprites                       ; Jump if not entering name

; -- Spawn Webster sprite Left side of new HighScore - Animated
; --- Calculate display block position
        ld      ix, TitleHighScoreWebsterTable

        ld      a, (NewHighScoreEntry)
        ld      b, a
        ld      a, TitleHighScoreTotalEntries
        sub     b

        ld      d, a
        ld      e, TitleHighScoreWebsterTableRow        ; Number of bytes within row
        mul     d, e                                    ; Calculate table offset
        
        add     ix, de

        ld      hl, (ix)                                ; XXYY Block position
        inc     ix
        inc     ix                                      ; Point to right sprite block

        push    ix                                      ; Save TitleHighScoreWebsterTable position

        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                                    ; Spawn at first sprite attribute position

        ld      b, MaxSprites
        call    SpawnNewSprite

        set     6, (ix+S_SPRITE_TYPE.SpriteType5)       ; Set ignore flag, so reset when name entered

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 9
        ld      (iy+S_SPRITE_ATTR.y), a

        dec     (iy+S_SPRITE_ATTR.x)

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitlePlayerDownPatterns             ; Sprite pattern range
        call    UpdateSpritePattern

; -- Spawn Webster sprite Right side of new HighScore - Animated
        pop     ix                                      ; Restore TitleHighScoreWebsterTable position

        ld      hl, (ix)                                ; XXYY Block position

        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                                    ; Spawn at first sprite attribute position
        ld      b, MaxSprites
        call    SpawnNewSprite

        set     6, (ix+S_SPRITE_TYPE.SpriteType5)       ; Set ignore flag, so reset when name entered

        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, 9
        ld      (iy+S_SPRITE_ATTR.y), a

        dec     (iy+S_SPRITE_ATTR.x)

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, TitlePlayerDownPatterns          ; Sprite pattern range
        call    UpdateSpritePattern

.UpdateSprites:
        ld      a, MaxSprites           	        ; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ret

;-------------------------------------------------------------------------------------
; Check/Update HighScore Table
; Parameters:
CheckUpdateHighScoreTable:
        ld      ix, TitleHighScoreValues
        ld      de, S_HighScore_Values.Value
        add     ix, de                  ; HighScore entry pointer --> Top Score

        ld      iy, Score               ; Score pointer

; Check whether score should be entered into HighScore table
; - HighScore Entry - Loop
        ld      b, TitleHighScoreTotalEntries   ; Number of HighScore table entries 

.HighScoreEntryLoop:
        ld      a, b
        ld      (BackupByte), a         ; Backup HighScore entry counter

        ld      (BackupWord1), ix       ; Backup HighScore table entry pointer

; - HighScore Entry - Digit Loop
        ld      b, ScoreLength
.DigitLoop:
        ld      a, (iy)
        ld      d, (ix)
        cp      d
        jp      c, .NextHighScoreEntry  ; Jump if HiScore digit > Score digit

        jr      nz, .NewHiScore         ; Jump if HiScore digit != Score Digit

.NextDigit:
        inc     ix                      ; Point to next HighScore digit
        inc     iy                      ; Point to next Score digit
        djnz    .DigitLoop

; -- Score <= HighScore entry
.NextHighScoreEntry:
        ld      ix, (BackupWord1)       ; Restore HighScore entry pointer
        ld      iy, Score               ; Restore Score pointer

        ld      de, S_HighScore_Values
        add     ix, de                  ; Point to next HighScore entry

        ld      a, (BackupByte)
        ld      b, a

        djnz    .HighScoreEntryLoop

; -- Score < all HighScore entries
; Set intial title screen value --> Title Main Screen
        ld      a, %11001000            ; Set Title-Main screen 1st time flags & Instruction screen 1st time flags
        ld      (TitleScreenStatus), a

        ret

; Add Score to HighScore table
.NewHiScore
; - Save Score to NewScore
        ld      hl, Score
        ld      de, NewScore
        ld      b, 0
        ld      c, ScoreLength
        ldir

; - Save blank name to NewName
        ld      hl, NewNameBlank
        ld      de, NewName
        ld      b, 0
        ld      c, NameLength
        ldir
        
; - Set registers
; -- Set position in score value table
        ld      ix, (BackupWord1)       ; Restore HighScore pointer

        ld      a, (BackupByte)
        ld      (NewHighScoreEntry), a  ; Save for use when adding name

        ld      b, a                    ; Restore HighScore entry number

; -- Set position in score name table
        ld      iy, TitleHighScoreNames

        ld      a, TitleHighScoreTotalEntries
        sub     b

        ld      d, a
        ld      e, S_HighScore_Names    ; Size of each name entry
        mul     d, e                    ; Position in name table
        add     iy, de
        inc     iy
        inc     iy                      ; Point to name data

; -- Result: ix = HighScore Score table entry, iy = HighScore Name table entry, b = HighScore table entry position

.UpdateHighScoreTableLoop:
        push    bc

; - HighScore Values
; -- Save current HighScore table entry to OldScore
        ld      hl, ix
        ld      de, OldScore
        ld      b, 0
        ld      c, ScoreLength
        ldir

; -- Save NewScore to HighScore table entry
        ld      hl, NewScore
        ld      de, ix
        ld      b, 0
        ld      c, ScoreLength
        ldir

; -- Save OldScore to NewScore for next HighScore table entry
        ld      hl, OldScore
        ld      de, NewScore
        ld      b, 0
        ld      c, ScoreLength
        ldir

; - HighScore Names
; -- Save current HighScore table entry to OldName
        ld      hl, iy
        ld      de, OldName
        ld      b, 0
        ld      c, NameLength
        ldir

; -- Save NewName to HighScore table entry
        ld      hl, NewName
        ld      de, iy
        ld      b, 0
        ld      c, NameLength
        ldir

; -- Save OldName to NewName for next HighScore table entry
        ld      hl, OldName
        ld      de, NewName
        ld      b, 0
        ld      c, NameLength
        ldir

        pop     bc

        ld      de, S_HighScore_Values
        add     ix, de                  ; Point to next HighScore value table entry

        ld      de, S_HighScore_Names
        add     iy, de                  ; Point to next HighScore name table entry

        djnz    .UpdateHighScoreTableLoop

; -- Reset Newname to use as target when entering name
        ld      hl, NewNameBlank
        ld      de, NewName
        ld      b, 0
        ld      c, NameLength
        ldir

; Set intial title screen value --> HighScore Screen
        ld      a, %10001101            ; Set Title-HighScore screen 1st time flag, Instruction screen 1st time flag & enter HighScore name flag
        ld      (TitleScreenStatus), a

        ld      a, 0
        ld      (TitleHighScoreNameCounter), a  ; Set name to first letter

        ret

;-------------------------------------------------------------------------------------
; Read Input Devices - Title HighScore Screen
; Parameters:
; Output:
; A = ASCII key value
; Note: 0 = No/Invalid key pressed, "<value>" = Key pressed, "[" = Enter, "]" = Delete
TitleHighScoreReadPlayerInput:
; Check whether player can provide input based on delay
        ld      a, (TitleHighScoreKeyDelayCounter)
        cp      0
        jp      z, .CheckInput                          ; Jump if no delay required

        dec     a
        ld      (TitleHighScoreKeyDelayCounter), a      ; Otherwise decrement delay

        ld      a, 0                                    ; Return = 0

        ret

.CheckInput:
; Check for keyboard matrix keys
        ld      ix, TitleHighScoreKeyboardMatrixTable

        ld      b, 8            ; Number of matrix
.KeyboardMatrixLoop:
        ld      a, b
        ld      (BackupByte), a ; Backup matrix reference count

        ld      a, (ix)
        in      a, (ULA_P_FE)   ; Read key matrix- Port Number - a = High byte, $fe = low byte 

        cpl                     ; Complement - Key pressed is now 1

        inc     ix              ; Point to first key value for matrix 1 in table

        ld      b, 5            ; Number of bits in matrix
.MatrixBitLoop:
        rrca                    ; Shift bit 0 --> Carry
        jp      nc, .NextMatrixBit      ; Jump if carry flag not set

; - Key pressed
        ld      a, (ix)         ; Get key code from matrix table

; - Check whether caps-shift pressed - Used to indicate Delete key (CSpect)
        cp      "~"
        jp      nz, .NotCapsShift       ; Jump if not Caps-Shift

; - Caps Shift pressed - Check for Delete key combination (CSpect) --> Delete = Caps-Shift+0
        ld      a, $ef          ; Matrix4
        in      a, (ULA_P_FE)   ; Read key matrix- Port Number - a = High byte, $fe = low byte 

        cpl                     ; Complement - Key pressed is now 1

        bit     0, a            ; Check for "0"
        jp      z, .NextMatrixBit       ; Jump if Delete not pressed

; - Delete key pressed
        ld      a, "]"          ; Return = Key value
        ret

.NotCapsShift:
        cp      "-"
        ret     nz              ; If acceptable key value --> Return = Key value

; - Key not pressed
.NextMatrixBit:
        inc     ix              ; Point to next entry in matrix table

        djnz    .MatrixBitLoop

        ld      a, (BackupByte) ; Restore matrix reference count
        ld      b, a
        djnz    .KeyboardMatrixLoop

; Check for Extended Keys1 - Delete key
; Note: Not applicable to CSpect, as CSpect doesn't respond to extended keys
        ld      a, $b1
        call    ReadNextReg

        bit     7, a                    ; Check for Delete key
        jp      nz, .DeletePressed      ; Jump if Delete key pressed

        ld      a, 0                    ; Return = 0
        ret

.DeletePressed:
        ld      a, "]"                  ; Return = Key value
        ret

;-------------------------------------------------------------------------------------
; File Management - Open/Read CFG File
; Parameters:
; Output:
TitleCFGFileRead:
        di

; Backup system variable location data
        ld      a, 0                    ; Backup data
        call    TitleSysVarsCopy

; Map ROM hosting esxDOS back into MMU0
        ld      a, (ROM_Bank)
        nextreg $50, a                  ; $0000-$1FFF
        nextreg $51, a                  ; $2000-$3FFF

; Open CFG file
        ld      a,'*'                   ; Use default drive
        ld      ix, FileCFGName
        ld      b, esx_mode_read+esx_mode_write+esx_mode_open_exist
        rst     $08
        defb    f_open
        jp      c, .FailedToRead        ; Jump if CFG file cannot be opened

        ld      (FileCFGHandle), a

; Read file and populate data
; - Read into data buffer
        ld      ix, FileCFGBuffer
        ld      bc, FileCFGSize
        rst     $08
        defb    f_read
        jp      c, .CloseCFGFile        ; Jump if failed to read CFG file

; Close CFG file
        ld      a, (FileCFGHandle)         ; Restore file handle
        rst     $08
        defb    f_close

; Restore system variable location data
        ld      a, 1                            ; Restore data
        call    TitleSysVarsCopy

; Restore Highscore and name data
; - HighScore Values
        ld      hl, FileCFGBuffer
        ld      a, (hl)                 ; Read UnlockedLevel value
; -- Check whether UnlockedLevel is valid i.e. within level range
        cp      MaxLevels+1             
        jp      c, .SetValue            ; Jump if MaxLevels+1 > value

        ld      a, 1                    ; Otherwise set to 1

.SetValue:
        ld      (UnlockedLevel), a
        inc     hl                              ; Source - 1st HighScore value

        ld      de, TitleHighScoreValues        ; Dest - 1st HighScore value

        ld      b, TitleHighScoreTotalEntries
.HighScoreValueLoop:
        push    bc

        push    de

        add     de, S_HighScore_Values.Value    ; Dest - Point to HighScore value
        ld      b, 0
        ld      c, ScoreLength
        ldir

        pop     de

        add     hl, NameLength                  ; Source - Point to next HighScore value
        add     de, S_HighScore_Values          ; Dest - Point to next HighScore line

        pop     bc

        djnz    .HighScoreValueLoop

; - HighScore Names
        ld      hl, FileCFGBuffer
        inc     hl                              
        add     hl, ScoreLength                 ; Source - 1st HighScore name

        ld      de, TitleHighScoreNames         ; Dest - 1st HighScore name

        ld      b, TitleHighScoreTotalEntries
.HighScoreNameLoop:
        push    bc

        push    de

        add     de, S_HighScore_Names.Name    ; Dest - Point to HighScore name
        ld      b, 0
        ld      c, NameLength
        ldir

        pop     de

        add     hl, ScoreLength                 ; Source - Point to next HighScore name
        add     de, S_HighScore_Names           ; Dest - Point to next HighScore name

        pop     bc

        djnz    .HighScoreNameLoop

        jp      .RemapMMU0

.CloseCFGFile:
; Close CFG file
        ld      a, (FileCFGHandle)         ; Restore file handle
        rst     $08
        defb    f_close

.FailedToRead:
; Restore system variable location data
        ld      a, 1                            ; Restore data
        call    TitleSysVarsCopy

; Remap memory bank - Replace ROM in MMU0
.RemapMMU0:
        nextreg $50, Code_Bank          ; $0000-$1FFF
        nextreg $51, Code_Bank+1        ; $2000-$3FFF

        ei
        ret

;-------------------------------------------------------------------------------------
; File Management - Open/Write CFG File; create if file does not exist
; Parameters:
; Output:
TitleCFGFileWrite:        
        di

; Backup system variable location data
        ld      a, 0                    ; Backup data
        call    TitleSysVarsCopy

; Map ROM hosting esxDOS back into MMU0
        ld      a, (ROM_Bank)
        nextreg $50, a                  ; $0000-$1FFF
        nextreg $51, a                  ; $2000-$3FFF

; Open/create CFG file
        ld      a,'*'                   ; Use default drive
        ld      ix, FileCFGName
        ld      b, esx_mode_read+esx_mode_write+esx_mode_open_creat
        rst     $08
        defb    f_open
        jp      c, .RemapMMU0           ; Jump if CFG file cannot be opened/created

        ld      (FileCFGHandle), a

; Create data buffer
; - HighScore Values
        ld      de, FileCFGBuffer
        ld      a, (UnlockedLevel)
        ld      (de), a
        inc     de                              ; Dest - 1st HighScore value

        ld      hl, TitleHighScoreValues        ; Source - 1st HighScore value

        ld      b, TitleHighScoreTotalEntries
.HighScoreValueLoop:
        push    bc

        push    hl

        add     hl, S_HighScore_Values.Value    ; Source - Point to HighScore value
        ld      b, 0
        ld      c, ScoreLength
        ldir

        pop     hl

        add     hl, S_HighScore_Values          ; Source - Point to next HighScore line
        add     de, NameLength                  ; Dest - Point to next HighScore value

        pop     bc

        djnz    .HighScoreValueLoop

; - HighScore Names
        ld      de, FileCFGBuffer
        inc     de                              
        add     de, ScoreLength                 ; Dest - 1st HighScore name

        ld      hl, TitleHighScoreNames         ; Source - 1st HighScore name

        ld      b, TitleHighScoreTotalEntries
.HighScoreNameLoop:
        push    bc

        push    hl

        add     hl, S_HighScore_Names.Name      ; Source - Point to HighScore name
        ld      b, 0
        ld      c, NameLength
        ldir

        pop     hl

        add     hl, S_HighScore_Names           ; Source - Point to next HighScore name
        add     de, ScoreLength                 ; Dest - Point to next HighScore name

        pop     bc

        djnz    .HighScoreNameLoop

; Write data buffer to file
        ld      a, (FileCFGHandle)         ; Restore file handle
        ld      ix, FileCFGBuffer
        ld      bc, FileCFGSize
        rst     $08
        defb    f_write

; Close CFG file
.CloseCFGFile:
        ld      a, (FileCFGHandle)         ; Restore file handle
        rst     $08
        defb    f_close

; Remap memory bank - Replace ROM in MMU0
.RemapMMU0:
        nextreg $50, Code_Bank          ; $0000-$1FFF
        nextreg $51, Code_Bank+1        ; $2000-$3FFF

; Restore system variable location data
        ld      a, 1                    ; Restore data
        call    TitleSysVarsCopy

        ei
        ret

;-------------------------------------------------------------------------------------
; File Management - Backup/Restore System Variable memory locations ($5b52 - $5cb4)
; Note: Required due to potential issue with ESXDOS calls writing to locations
; Parameters:
; a = 0 - Backup, 1 - Restore
TitleSysVarsCopy:
; Check whether data should be restored
        cp      1
        jp      z, .RestoreData         ; Jump if restoring data

; Backup Data
        ld      hl, $5b52               ; Source --- System Variables starting location
        ld      de, FFStorage           ; Target --- Temporary storage
        ld      bc, ($5cb4-$5b52)+1     ; System variables number
        ldir                            ; Copy data

        ret

; Restore Data
.RestoreData:
        ld      hl, FFStorage           ; Source --- Temporary storage
        ld      de, $5b52               ; Target ---- System Variables starting location
        ld      bc, ($5cb4-$5b52)+1     ; System variables number
        ldir                            ; Copy data

        ret

;-------------------------------------------------------------------------------------
; Write data to Layer 2 Memory - 320 x 256 (10 x memory banks)
; Note: Maps memory bank temporarily into MMU3
; Parameters:
; ix = L2 Data
; a = Width size
; b = Height size
; de = X position
; -Note: Results in de = -------b|bbbxxxxx {where b = bank offset, x = x}
; l = Y position
; Return:
TitleLayer2_320_Write:
	push    af, bc

; Obtain memory bank number currently mapped into slot 3 and save allowing restoration
	ld      a,$53                           ; Port to access - Memory Slot 3

	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
	ld      (BackupByte), a                 ; Save current bank number in slot 3

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
	add     a, $$Layer2Picture		; A=bank number to swap in (start bank + bank offset)
	nextreg $53, a                          ; Swap memory bank

	pop	af		        ; Restore width

	ld	b, a

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
	add     a, $$Layer2Picture		; A=bank number to swap in (start bank + bank offset)
	nextreg $53, a                          ; Swap memory bank

.DoNotUpdateMemoryBank:
; - Convert DE (xy) to screen memory location starting at $6000
	push    de                      ; Save memory bank offset (xy)

	ld      a, d                    ; Copy current X to A
        or      $60                     ; Screen starts at $6000
	ld      d, a                    ; D=high byte for $6000 screen memory

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
	nextreg $53, a                  ; Restore memory bank into slot 3 - $6000

        ret

;-------------------------------------------------------------------------------------
; Add Borders to Title Layer2 Screen  - Top, bottom, left, right
; Note: Borders based on current level number
; Note: Maps memory bank temporarily into MMU7
; Parameters:
; LevelNumber
TitleDisplayBorders:
; Obtain memory bank number currently mapped into slot 7 and save allowing restoration
	ld      a,$57                           ; Port to access - Memory Slot 4
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
        push    af

; Calculate TitleBordersTable reference
; - Check whether to display locked borders
        ld      hl, TitleBordersTableLockedOffset       ; Assume level locked

        ld      a, (GameStatus3)
        bit     6, a
        jp      nz, .BypassCalculation                  ; Jump if level locked

	ld	a, (CurrentLevel)
	dec	a
        sla     a                                       ; Required due to table hosting words

        ld      hl, TitleBordersTable
        ld      b, 0
        ld      c, a
        add     hl, bc                                  ; Point to level reference in table
.BypassCalculation:
        ld      bc, (hl)
        ld      ix, bc

; - Layer2 - Top Border
        push    ix

        ld      a, (ix+S_Title_L2Borders.TopMemBank)
        nextreg $57, a

        ld      bc, (ix+S_Title_L2Borders.TopAddress)

; -- Check whether the new border = current border
        or      a
        ld      hl, (TitleBordersLastValue)
        sbc     hl, bc
        jp      nz, .ContBorders                ; Jump if new border != current border

        pop     ix                              ; Otherwise don't update

        jp      .RemapMemBank

        ret

.ContBorders:
        ld      (TitleBordersLastValue), bc

        ld      ix, bc
        ld      a, 0                            ; Block Width -- 256
        ld      b, 16                           ; Block Height
        ld      de, 32
        ld      hl, 16        

        call    TitleLayer2_320_Write

        pop     ix

; - Layer2 - Bottom
        push    ix

        ld      a, (ix+S_Title_L2Borders.BottomMemBank)
        nextreg $57, a

        ld      bc, (ix+S_Title_L2Borders.BottomAddress)
        ld      ix, bc
        ld      a, 0                            ; Block Width
        ld      b, 32                           ; Block Height
        ld      de, 32
        ld      hl, 208        

        call    TitleLayer2_320_Write

        pop     ix

; - Layer2 - Left
        push    ix

        ld      a, (ix+S_Title_L2Borders.LeftMemBank)
        nextreg $57, a

        ld      bc, (ix+S_Title_L2Borders.LeftAddress)
        ld      ix, bc
        ld      a, 16                           ; Block Width
        ld      b, 224                          ; Block Height
        ld      de, 16
        ld      hl, 16        

        call    TitleLayer2_320_Write

        pop     ix

; - Layer2 - Right
        ld      a, (ix+S_Title_L2Borders.RightMemBank)
        nextreg $57, a

        ld      bc, (ix+S_Title_L2Borders.RightAddress)
        ld      ix, bc
        ld      a, 16                           ; Block Width
        ld      b, 224                          ; Block Height
        ld      de, 288
        ld      hl, 16        

        call    TitleLayer2_320_Write

; Map original memory bank back into slot 7
.RemapMemBank:
        pop     af
        nextreg $57, a

        ret

;-------------------------------------------------------------------------------------
; Presents Message Screen
; Note: Maps memory bank temporarily into MMU7
; Parameters:
; Note: MMU switches
;       MMU3 --> L2 Palette data
;       MMU4 --> Sprite data
;       MMU6 --> L2 Presents data 1/2
;       MMU7 --> L2 Presents data 2/2
TitleDisplayPresentsScreen:
; Obtain memory bank numbers currently mapped into:
; - MMU6 - Save allowing restoration - Used for L2 remapping
	ld      a,$56                           ; Port to access - Memory Slot 6
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)

        push    af

; - MMU7 - Save allowing restoration - Used for L2 remapping
	ld      a,$57                           ; Port to access - Memory Slot 7
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
        push    af

; - MMU4 - Save allowing restoration
	ld      a,$54                           ; Port to access - Memory Slot 4
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
        push    af

; Immediately close tilemap, layer2 and sprite screens
; - Note: Only really needed when game first started, as exiting a game session will close all screens
        ld      a, ClearScreenY1Middle
        ld      (ClearScreenY1Counter), a
        ld      a, ClearScreenY2Middle
        ld      (ClearScreenY2Counter), a

        ld      a, ClearScreenX1Middle
        ld      (ClearScreenX1Counter), a
        ld      a, ClearScreenX2Middle
        ld      (ClearScreenX2Counter), a

        ld      a, 0                            ; Close tilemap & sprite screens
        ld      (BackupByte7), a
        call    UpdateScreen

; Pause on empty screen
        ld      b, TitlePresentsStartPause
.PauseLoop:
        halt
        djnz .PauseLoop

; Stop Copper
	NEXTREG $62, %00'000'000                ; Stop copper

; --- Layer Priority
; SPRITE AND LAYERS SYSTEM REGISTER
; - LowRes off
; - Sprite rendering flipped i.e. Sprite 0 (Player) on top of other sprites
; - Sprite clipping in over border mode enabled
; - Layer Priority - SLU
; - Sprites enable
        nextreg $15, %0'1'1'000'1'1

; --- Sprites ---
; Reset sprites and attributes - Need to run to ensure at least one non-zero attribute is defined
        ld      a, MaxSprites
        call    ResetSprites

	call	ImportLevelSprites

; Set camera starting coordinates; required for spawning sprites at correct locations
        ld      hl, 16
        ld      (CameraXWorldCoordinate), hl
        ld      (CameraYWorldCoordinate), hl

; - ReMap ULA Memory banks 10/11 (16KB) to slots 3/4; previously remapped when importing sprites
        nextreg $53, 10

        pop     af
        nextreg $54, a                  ; Remap memory bank previously saved

; --- Layer2 ---
; - Clear L2 memory banks
        ld      a, L2Start_8_Bank       ; Starting 8kb memory bank
        ld      b, L2NUM_BANKS          ; Number of 8kb memory banks hosting L2 data to clear
        call    Layer2Clear

; - Configure L2 settings
        call    TitlePresentsLayer2Setup

; - Configure Layer 2 and ULA Transparency Colour
; -- GLOBAL TRANSPARENCY Register
; --- Changed for L2 to enable display of black
        nextreg $14,$1         ; Palette entry 1- Ensure palettes are configured correctly

; Copy Presents L2 data to L2 banks
        di      ; Need to disable as int uses variable that will be temp mapped out of memory 

; - Map Presents L2 memory banks to MMU6/MMU7
        ld      a, $$Layer2Presents
        nextreg $56, a

        ld      a, $$Layer2Presents+1
        nextreg $57, a

; - Copy data
        ld      ix, Layer2Presents
        ld      a, 232                          ; Block Width
        ld      b, 69                           ; Block Height
        ld      de, 44
        ld      hl, 93        

        call    Layer2_320_Write

; - ReMap MMU slots 7/6
; -- MMU7 - Previously mapped to L2 memory bank
        pop     af
        nextreg $57, a

; -- MMU6 - Previously mapped to L2 memory bank
        pop     af
        nextreg $56, a

        ei

; Immediately open layer2 and sprite screens
        nextreg $1c, %0000'0001                 ; Reset tilemap clip write index
        ld      a, TileMapXOffsetLeft
        nextreg $18, a                          ; X1 Position
        ld      a, TileMapXOffsetRight       
        nextreg $18, a                          ; X2 Position

        ld      a, TileMapYOffsetTop
        nextreg $18, a                          ; Y1 Position
        ld      a, TileMapYOffsetBottom           
        nextreg $18, a                          ; Y2 Position

        nextreg $1c, %0000'0010                 ; Reset tilemap clip write index
        ld      a, TileMapXOffsetLeft           ; Hide left column
        nextreg $19, a                          ; X1 Position
        ld      a, TitlePresentsSpriteXOffsetRight      ; Hide right column
        nextreg $19, a                          ; X2 Position
        ld      a, TileMapYOffsetTop            ; Hide top row
        nextreg $19, a                          ; Y1 Position
        ld      a, TileMapYOffsetBottom         ; Hide bottom row
        nextreg $19, a                          ; Y2 Position

; Fade in L2 palette colours
        ld      a, 7
        ld      b, %0'001'0'0'0'1  ; Layer 2 - First palette
        call    TitleFadeInL2Palette

; Pause
        ld      b, TitlePresentsPreSpritePause
.PauseLoopPreSprite:
        halt
        djnz    .PauseLoopPreSprite

; Spawn/Play spawn sprite animation + sound effect
        ld      ix, PlayerSprType
        ld      iy, PlayerSprite
        ld      a, 1+MaxHUDSprites
        ld      b, 1
        ld      hl, $0907                               ; XXYY Block Offset
        call    SpawnNewSprite

; - Set flags to enable animation to be played and completed
        ld      a, %00100000                            ; Set Player start/end/dead animation flag
                                                        ; Set Gameover flag
        
        ld      (GameStatus), a

        ld      a, (iy+S_SPRITE_ATTR.vpat)              ; Attribute byte 4 - %0'1'000000 - Invisible sprite, 4Byte, sprite pattern

        set     7, a                                    ; Make sprite invisible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'1'000000 - Invisible sprite, 4Byte, sprite pattern

; - Scale player sprite
        ld      a, (iy+S_SPRITE_ATTR.Attribute4)
        or      %000'01'01'0                            ; Scale x + y
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5

; - Set sprite pattern and make sprite visible        
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; - Play AYFX audio sound effect
        push    ix, iy
        ld      a, AyFXPlayerSpawnFinish
        call    AFX1Play
; TODO - Intro
        ;ld      a, AyFXPlayerSpawnFinish
        ;call    AFX2Play
        ;ld      a, AyFXPlayerSpawnFinish
        ;call    AFX3Play
        pop     iy, ix

        push    iy
        ld      iy, ix
        pop     ix

; - Play spawn animation
.SpriteAnimationLoop:
        push    ix
        call    AFX1Frame
        call    AFX2Frame
        call    AFX3Frame
        pop     ix

        halt

        ld      bc, (PlayerSprite+S_SPRITE_TYPE.patternRange)   ; Sprite pattern range
        call    UpdateSpritePattern

        ld      a, MaxSprites           	                ; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ld      a, (GameStatus)
        bit     5, a
        jp      nz, .SpriteAnimationLoop                        ; Jump if animation not complete

; Change to player pattern and move sprite
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.animationStr)   ; Sprite pattern range
        call    UpdateSpritePattern

        ld      a, MaxSprites           	                ; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

; - Reposition player as current values based on scaled sprite
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 8
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     hl, 8
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl

; - Move/Animate sprite
        ld      bc, TitlePresentsSpriteStopX
        call    TitlePresentsScreenMoveSprite

; Dance sprite and play sound effect
; - Play AYFX audio sound effect
        ld      a, AyFXFriendlyRescued
        call    AFX1Play
        ld      a, AyFXFriendlyRescued
        call    AFX2Play
        ld      a, AyFXFriendlyRescued
        call    AFX3Play

        ld      iy, PlayerSprite
        ld      ix, PlayerSprAtt
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.animationDown)   ; Sprite pattern range
        call    UpdateSpritePattern

        ld      b, TitlePresentsDancePause
.SpriteAnimationLoop2:
        push    bc

        push    ix
        call    AFX1Frame
        call    AFX2Frame
        call    AFX3Frame
        pop     ix

        halt

        ld      bc, (PlayerSprite+S_SPRITE_TYPE.patternRange)   ; Sprite pattern range
        call    UpdateSpritePattern

        ld      a, MaxSprites           	                ; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        pop     bc
        djnz    .SpriteAnimationLoop2

; Move/Animate sprite off screen
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.animationStr)   ; Sprite pattern range
        call    UpdateSpritePattern

        ld      bc, TitlePresentsSpriteOffScreenX
        call    TitlePresentsScreenMoveSprite

; Pause
        ld      b, TitlePresentsEndPause
.PauseLoopEnd:
        halt
        djnz    .PauseLoopEnd

; Fade out L2 palette colours
        ld      a, 7
        ld      b, %0'001'0'0'0'1  ; Layer 2 - First palette
        call    FadeOutPalette

        ret

;-------------------------------------------------------------------------------------
; Presents Message Screen - Sprite Movement
; Parameters:
; bc = End Position
TitlePresentsScreenMoveSprite:
        push    bc

        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

.MovementLoop:
        push    ix
        call    AFX1Frame
        call    AFX2Frame
        call    AFX3Frame
        pop     ix

        halt
; - Move sprite
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)

        inc     hl

        ld      (ix+S_SPRITE_TYPE.xPosition), hl                
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl         

        call    DisplaySprite

        push    iy
        ld      iy, ix
        pop     ix

; - Animate sprite
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.patternRange)   ; Sprite pattern range
        call    UpdateSpritePattern

        ld      ix, iy

        ld      a, MaxSprites           	                ; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        or      a
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        pop     bc
        push    bc
        ;ld      bc, 200;304
        sbc     hl, bc
        jr      c, .MovementLoop                ;   Jump if hl < bc      

        pop     bc

        ret

;-------------------------------------------------------------------------------------
; Fade in L2 palette - Title
; Parameters:
; a = Number of fade updates (7 = Fade all colours to black)
; Note: Each colour consists of 3 bits. Therefore it would take 7 updates to go from RRR to ---
; Note: Setting a > 7 will provide a delay post-fade
; b = Palette reference
TitleFadeInL2Palette:
        push    af                      ; Save fade updates

; Select palette
        ld      a, b                    ; Select tilemap palette
        nextreg $43, a

; Obtain current L2 colours
        ld      a, 0                    ; Starting palette index number
        ld      b, 0                    ; 256 colours
        call    FadeReadColours		; Queue = Current L2 colours

; Fade Palette Colours to target colours
        pop     af                      ; Restore fade updates

        ld      b, a                    ; Loop - x times for all palette colours
.ColourBitLoop:
        push    bc

        ld      ix, Queue		; Current L2 colours
	ld	iy, TitleL2Palette	; Target L2 colours

        ld      b, 0                    ; Loop - 256 colours in table
.TableLoop:
        push    bc
        
; Red
	ld	a, (iy)
        and     %11100000
	ld	b, a		; Target colour

        ld      a, (ix)
        and     %11100000       ; Current colour
        cp      b
        jp      z, .CheckGreen  ; Jump if Red target reached

        ld      a, (ix)
        add     %00100000       ; Otherwise increment Red
        ld      (ix), a

; Green
.CheckGreen:
	ld	a, (iy)
        and     %00011100
	ld	b, a		; Target colour

        ld      a, (ix)
        and     %00011100       ; Current colour
        cp      b
        jp      z, .CheckBlue   ; Jump if Green target reached

        ld      a, (ix)
        add     %00000100       ; Otherwise increment Green
        ld      (ix), a

; Blue
.CheckBlue:
        ld      a, (iy+1)
        rr      a               ; Bit 0 copied to carry

        ld      a, (iy)
        rl      a               ; Bit 0 copied from carry; Bit 7 copied to carry
        and     %00000111       
	ld	b, a		; Target colour

        ld      a, (ix+1)
        rr      a               ; Bit 0 copied to carry

        ld      a, (ix)
        rl      a               ; Bit 0 copied from carry; Bit 7 copied to carry

        push    af              ; Save value + flags

        and     %00000111       ; Current colour
        cp      b
        jp      z, .BypassBlue  ; Jump if Blue target reached

        pop     af              ; Restore value + flags

        inc     a               ; Otherwise increment Blue

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
        inc     ix              ; Point to next current colour in queue

        inc     iy
        inc     iy              ; Point to next target colour

        pop     bc

        djnz    .TableLoop

        ld      b, TitlePresentsFadePause
.DelayLoop:
        push    bc

; -- Wait for vertical sync to ensure colours fade correctly
        halt

        pop     bc

        djnz    .DelayLoop

; Write updated palette
        ld      a, 0                    ; Starting palette index number
        ld      b, 0                    ; 256 colours
        call    FadeWriteColours

        pop     bc

        dec     b
        ld      a, b
        cp      0
        jp      nz, .ColourBitLoop

        ret
TitleCodeEnd: