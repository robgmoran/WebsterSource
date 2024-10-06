LevelManagerCode:
;-------------------------------------------------------------------------------------
; Start New Game - Setup Environment
; Parameters:
StartNewGame:
        ld      a, (CurrentLevel)
        call    SetupLevelReferences            ; Setup data variables

        call    ResetScore

        call    DisplayLevelStartText

; Check whether we should exit to title screen
        ld      a, (GameStatus2)
        bit     1, a
        ret     nz                              ; Return if exit selected

        call    ImportLevelSprites
        call    ConfigGameValues                ; Reset game variables
        call    SetupLevelData                  ; Setup TileMap, Sprites, Player, Enemies...
        call    SpawnHUDSprites

        ret

;-------------------------------------------------------------------------------------
; Start Next Level - Setup Environment
; Parameters:
StartNextLevel:
; Check if completed all levels
        ld      a, (CurrentLevel)
        cp      LevelTotal
        jp      nz, .NextLevel                  ; Jump if final level hasn't been completed

        ld      a, 0                            ; Reset back to first level

.NextLevel:
        inc     a
        ld      (CurrentLevel), a
        call    SetupLevelReferences            ; Setup data variables

        call    DisplayLevelStartText

; Check whether we should exit to title screen
        ld      a, (GameStatus2)
        bit     1, a
        ret     nz                              ; Return if exit selected

        call    ImportLevelSprites
        call    ConfigGameValues                ; Reset game variables
        call    SetupLevelData                  ; Setup TileMap, Sprites, Player, Enemies...
        call    SpawnHUDSprites

        ret

;-------------------------------------------------------------------------------------
; Setup/Display Level Start Text Screen
; Parameters:
DisplayLevelStartText:
; Reset Variables
        ld      a, (GameStatus3)
        and     %10000000               ; Assume highscore flag to be retained
        ld      (GameStatus3), a

        ld      a, (GameStatus)
        bit     4, a
        jp      nz, .BypassReset        ; Jump if starting next level

        ld      a, 0
        ld      (GameStatus3), a           ; Otherwise reset highscore flag

.BypassReset
        ld      a, 0
        ld      (PlayerInput), a
        ld      (GameStatus), a         ; Reset game status for use within routine

        ld      a, (GameStatus2)
        set     2, a                    ; Disable use of pause function
        ld      (GameStatus2), a

; Reset scroll counters to ensure tilemap displayed correctly after level has been played
        ld      bc, 0
        ld      (ScrollTileMapBlockXPointer), bc

 ; Set Tilemap index of end colour for cycling palette
        ld      a, DoorLockdownPalCycleDisabled
        ld      (DoorLockdownPalCycleOffset), a
 
; Set camera starting coordinates; required for spawning sprites at correct locations
        ld      hl, 16
        ld      (CameraXWorldCoordinate), hl
        ld      (CameraYWorldCoordinate), hl

; Set ClearScreen variables to ensure ProcesScreen routine works at double-speed
; Note: Setting tilemap/sprite screen to open borders
        ld      a, TileMapYOffsetTop
        ld      (ClearScreenY1Counter), a
        ld      a, TileMapYOffsetBottom
        ld      (ClearScreenY2Counter), a

        ld      a, TileMapXOffsetLeft
        ld      (ClearScreenX1Counter), a
        ld      a, TileMapXOffsetRight
        ld      (ClearScreenX2Counter), a

; Close Screen
        ld      a, %00000001
        ld      (GameStatus), a                 ; Close Screen

.CloseScreenLoop:
        ld      a, 0                            ; Tilemap+sprite areas
        call    ProcessScreen

        halt

        ld      a, (GameStatus)
        bit     0, a
        jp      nz, .CloseScreenLoop            ; Jump if screen still closing

; Reset counter to ensure screens close successfully
        ld      a, 0
        ld      (TitleTileMapYOffsetTopCounter), a

        call    SetCommonLayerSettings          ; Required as changed within title screen
 
; Disable Layer 2
; - Note: Alias for Layer 2 Access Port ($123B / 4667) bit 1)
        nextreg $69, %0'0'000000      

; Setup Intro TileMap
        ld      a, (LevelDataMemBank)           ; Memory bank (8kb) containing tilemap data
        call    SetupLevelIntroTileMap

; - 23/01/24 - No longer required, intro tilemap to be disabled and left blank
; - Draw tilemap
        call    DrawLevelIntroTileMap

; Disable tilemap
; - TILEMAP CONTROL Register
        ;ld      a, %0'0'1'0'0'0'0'1     ; Disable tilemap, 40x32, no attributes, primary pal, 256 mode, Tilemap over ULA (can be overidden by tile attribute)
        ;nextreg $6b, a

; Import/Display Text Sprites
        call    SetupTextSprites

; - ReMap ULA Memory banks 10/11 (16KB) to slots 3/4; previously remapped when importing sprites
        nextreg $53, 10
        nextreg $54, 11

; Display sprite text for level
; - Level text
        ld      ix, LevelNumberText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 1
        call    PrintSpriteText

; - Level Value
        ld      de, SpriteString2
        ld      a, (CurrentLevel)
        ld      b, 2                            ; Number of digits
        call    ConvertIntToString2

        ld      hl, LevelNumberValueXY          ; Block position
        ld      ix, SpriteString2               ; Text string
        ld      a, 1
        call    PrintSpriteText

; - Level Friendly text
        ld      ix, LevelFriendlyText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Level Friendly Value
        ld      de, SpriteString2
        ld      a, (LevelDataFriendlyNumber)
        ld      b, 2                            ; Number of digits
        call    ConvertIntToString2

        ld      hl, LevelFriendlyValueXY        ; Block position
        ld      ix, SpriteString2               ; Text string
        ld      a, 0
        call    PrintSpriteText

; - Spawn Friendly sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelFriendlySpriteXY       ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, FriendlySpriteTextPatterns
        call    UpdateSpritePattern

; - Level Savepoint credit text
        ld      ix, LevelSavePointCreditText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

        ld      ix, LevelSavePointCreditText2
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Level Savepoint credit Value
        ld      de, SpriteString2
        ld      a, (SavePointCreditFriendly)
        ld      b, 2                            ; Number of digits
        call    ConvertIntToString2

        ld      hl, LevelSavePointCreditValueXY ; Block position
        ld      ix, SpriteString2               ; Text string
        ld      a, 0
        call    PrintSpriteText

; - Spawn Friendly sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelSavePointCreditSpriteXY; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, FriendlySpriteTextPatterns
        call    UpdateSpritePattern

; - Level Mode text
        ld      ix, LevelModeEasyText           ; Assume Easy mode

        ld      a, (GameStatus2)
        bit     4, a
        jp      z, .BypassHardText

        ld      ix, LevelModeHardText

.BypassHardText:
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Spawn Mouse left-click sprite-1 - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelStartMouseSprite1XY     ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, MouseSpriteTextPatterns     ; Sprite pattern range
        call    UpdateSpritePattern

; - Spawn Mouse right-click sprite-2 - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelStartMouseSprite2XY     ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, MouseSpriteTextPatterns     ; Sprite pattern range
        call    UpdateSpritePattern

        set     3, (ix+S_SPRITE_ATTR.mrx8)      ; Horizontally mirror sprite i.e. Reuse existing mouse sprites

; - Click play/exit text
        ld      ix, LevelClickToStartText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; Fade-in palette
        ld      a, 7
        ld      b, %0'010'0'0'0'1               ; Sprites first palette + write auto-increment
        ld      c, 48
        call    FadeInPalette

; Open Screen
        ld      a, %00000010
        ld      (GameStatus), a                 ; Open Screen

; Setup Sprite Palette Cycle Values
        ld      a, LevelIntroCycleDelayBetweenCycles
        ld      (BackupByte4), a                        ; Frame delay between complete cycles
        ld      a, LevelIntroCycleColours           
        ld      (BackupByte5), a                        ; Colours for complete cycle
        ld      a, LevelIntroCycleDelayBetweenFrames
        ld      (BackupByte6), a                        ; Frame delay within complete cycle

; Audio
; - Map AyFX memory bank into slot 4 and play audio
        ld      a, $$AyFXBankLevelIntro
        nextreg $54, $$AyFXBankLevelIntro

        ld       hl, AyFXBankLevelIntro ; AyFX bank containing sound effects
        call    SetupAYFXNonGame

        ld      a, 0                    ; Only play once when screen opened
        call    AFX1Play
        ld      a, 1                    ; Only play once when screen opened
        call    AFX2Play
        ld      a, 2                    ; Only play once when screen opened
        call    AFX3Play

; Set frame rate for AyFX audio
        ld      a, 0
        ld      (AyFXFrameSkipCounter), a       ; Reset frame counter

        ld      a, AyFXFrameSkip60mhz           ; Assume 60mhz
        ld      (AyFXFrameSkipValue), a

        ld      a, $05
        call    ReadNextReg

        bit     2, a
        jp      nz, .ScreenLoop                 ; Jump if 60hz

        ld      a, AyFXFrameSkip50mhz           ; Otherwise 50mhz
        ld      (AyFXFrameSkipValue), a

.ScreenLoop:
        ld      a, 0                    ; Tilemap+Sprite areas
        call    ProcessScreen

        ;ld      a, (GameStatus)
        ;bit     1, a
        ;jp      nz, .Animate            ; Jump if screen still opening

.Animate:
        halt

; Play sound effects
; - Check whether we should skip a frame
        ld      a, (AyFXFrameSkipCounter)
        cp      0
        jp      z, .BypassAyFX                  ; Jump if skipping frame i.e. 60hz

        cp      AyFXFrameSkip50mhz
        jp      z, .PlayAYFXFrame               ; Jump if 50hz value, i.e. Just play ayfx

; -- Play frame
        dec     a
        ld      (AyFXFrameSkipCounter), a       ; Only for 60hz

.PlayAYFXFrame:        
        call    AFX1Frame
        call    AFX2Frame
        call    AFX3Frame

        jp      .Cont

; -- Bypass frame for 60hz
.BypassAyFX:
        ld      a, (AyFXFrameSkipValue)
        ld      (AyFXFrameSkipCounter), a

.Cont:
        call    CyclePaletteWithDelay           ; Cycle sprite colours

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

; Animate Friendly sprites
        ld      iy, Sprites

.AnimateLoop:
        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NextSprite                  ; Jump if sprite not friendly

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern
        
.NextSprite
        ld      bc, S_SPRITE_TYPE
        add     iy, bc

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      1
        jp      z, .AnimateLoop

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ld      a, (GameStatus)
        bit     1, a
        jp      nz, .ScreenLoop                 ; Jump if screen still opening

; Check mouse input
        ld      a, (PlayerInput)
        bit     5, a
        jp      nz, .BypassMouseInput           ; Jump if mouse left-button already clicked
        bit     6, a
        jp      nz, .ReturnToTitle              ; Jump if mouse right-button already clicked

        call    ReadPlayerInput

        jp      .Animate

.ReturnToTitle:
        ld      a, (GameStatus2)
        set     1, a                            ; Set return to title screen flag
        ld      (GameStatus2), a

.BypassMouseInput:
        call    SetupAYFXGame
        
; Map ULA Memory bank 11 (8KB) back to slot 4; previously remapped for AyFX bank
        nextreg $54, 11

; Fade Tilemap
; Note: Not fading Layer2 as tilemap in-front
        ld      a, 10
        ld      b, %0'011'0'0'0'1               ; TileMap first palette + write auto-increment
        call    FadeOutPalette

; Fade sprites + Reset
        ld      a, 7
        ld      b, %0'010'0'0'0'1               ; Sprites first palette + write auto-increment
        call    FadeOutPalette

; Close screen immediately as we have faded out tilemap/sprites
; Note: Setting tilemap/sprite screen to closed borders
        ld      a, ClearScreenY1Middle
        ld      (ClearScreenY1Counter), a
        ld      a, ClearScreenY2Middle
        ld      (ClearScreenY2Counter), a

        ld      a, ClearScreenX1Middle
        ld      (ClearScreenX1Counter), a
        ld      a, ClearScreenX2Middle
        ld      (ClearScreenX2Counter), a

        ld      a, 0                            ; Close tilemap, layer2 & sprite screens
        ld      (BackupByte7), a
        call    UpdateScreen

; Reset sprites and attributes - Need to run to ensure at least one non-zero attribute is defined
        ld      a, MaxSprites
        call    ResetSprites

        ld      a, (GameStatus2)
        res     2, a                    ; Enable use of pause function
        ld      (GameStatus2), a

        ret

;-------------------------------------------------------------------------------------
; Setup/Display Level Complete Text Screen
; Parameters:
DisplayLevelCompleteText:
        call    SetupLevelCompleteGameOver

        ld      a, (GameStatus2)
        set     2, a                    ; Disable use of pause function
        ld      (GameStatus2), a

; Display sprite text for level
; - Level text
        ld      ix, LevelNumberText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 1
        call    PrintSpriteText

; - Level Value
        ld      de, SpriteString2
        ld      a, (CurrentLevel)
        ld      b, 2                            ; Number of digits
        call    ConvertIntToString2

        ld      hl, LevelNumberValueXY          ; Block position
        ld      ix, SpriteString2               ; Text string
        ld      a, 1
        call    PrintSpriteText

; Check if completed all levels
        ld      a, (CurrentLevel)
        cp      LevelTotal
        jp      nz, .NextLevel                  ; Jump if final level hasn't been completed

; Game Complete
        ld      ix, GameCompleteText1
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 1
        call    PrintSpriteText

        ld      ix, GameCompleteText2
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Check whether we need to change difficulty
        ld      a, (GameStatus2)
        bit     4, a
        jp      nz, .HardModeComplete           ; Jump if already on hard level

        ld      ix, GameCompleteText3
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

        ld      a, 0
        set     4, a                            ; Set hard difficulty
        ld      (GameStatus2), a

        jp      .BypassHardText

.HardModeComplete:
        ld      ix, GameCompleteText4
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

.BypassHardText:
        ld      a, LevelTotal
        ld      (UnlockedLevel), a     ; Unlock last level

        jp      .BypassUnlockText

.NextLevel:
; - Level text
        ld      ix, LevelCompleteText1
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 1
        call    PrintSpriteText

; -- Check whether new level unlocked
        ld      a, (CurrentLevel)
        ld      b, a
        ld      a, (UnlockedLevel)

        cp      b
        jp      nz, .BypassUnlockText

        inc     a                               ; Increment unlocked level
        ld      (UnlockedLevel), a

        ld      ix, LevelCompleteText2
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

        ld      ix, LevelCompleteText3
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

        call    CFGFileWrite                    ; Update CFG file with unlocked level

.BypassUnlockText:
; - Spawn Mouse sprite-1 - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelCompletetMouseSprite1XY; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, MouseSpriteTextPatterns     ; Sprite pattern range
        call    UpdateSpritePattern

; - Spawn Mouse sprite-2 - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelCompletetMouseSprite2XY; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, MouseSpriteTextPatterns     ; Sprite pattern range
        call    UpdateSpritePattern

        set     3, (ix+S_SPRITE_ATTR.mrx8)      ; Horizontally mirror sprite i.e. Reuse existing mouse sprites

; - Click text
        ld      ix, LevelClickToResumeText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Fade in text sprites
        ld      a, 7
        ld      b, %0'010'0'0'0'1               ; Sprites first palette + write auto-increment
        ld      c, 16
        call    FadeInPalette

; Setup Sprite Palette Cycle Values
        ld      a, 0                                    ; Cycle immediately
        ld      (BackupByte4), a                        ; Frame delay between complete cycles
        ld      a, LevelIntroCycleColours           
        ld      (BackupByte5), a                        ; Colours for complete cycle
        ld      a, 0                                    ; Cycle immediately
        ld      (BackupByte6), a                        ; Frame delay within complete cycle

; Audio
; - Map AyFX memory bank into slot 4 and play audio
        ld      a, $$AyFXBankLevelComplete
        nextreg $54, $$AyFXBankLevelComplete

        ld       hl, AyFXBankLevelComplete   ; AyFX bank containing sound effects
        call    SetupAYFXNonGame

        ld      a, 0                            ; Only play once when screen opened
        call    AFX1Play
        ld      a, 1                            ; Only play once when screen opened
        call    AFX2Play
        ld      a, 2                            ; Only play once when screen opened
        call    AFX3Play

        ;ld      a, AyFXTriggerTarget                    ; Only play once when sprites faded
        ;call    AFX2Play

.CyclePalette:
        halt

; Play sound effects
        call    AFX1Frame
        call    AFX2Frame
        call    AFX3Frame

        call    CyclePaletteWithDelay                   ; Cycle sprite colours

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

; Animate Friendly sprites
        ld      iy, Sprites

.AnimateLoop:
        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NextSprite                  ; Jump if sprite not friendly

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern
        
.NextSprite
        ld      bc, S_SPRITE_TYPE
        add     iy, bc

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      1
        jp      z, .AnimateLoop

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Check mouse input
        ld      a, (PlayerInput)
        bit     5, a
        jp      nz, .BypassMouseInput           ; Jump if mouse left-button already clicked
        bit     6, a
        jp      nz, .ReturnToTitle              ; Jump if mouse right-button already clicked

        call    ReadPlayerInput

        jp      .CyclePalette

.ReturnToTitle:
        ld      a, (GameStatus2)
        set     1, a                            ; Set return to title screen flag
        ld      (GameStatus2), a

.BypassMouseInput:
        ld      a, (GameStatus)
        bit     4, a
        jp      nz, .Finish                     ; Jump if Start next level bit set

        set     4, a                            ; Set Start next level bit
        set     0, a                            ; Set Close screen bit
        ld      (GameStatus), a

        jp      .CyclePalette

.Finish:
        call    SetupAYFXGame

; Map ULA Memory bank 11 (8KB) back to slot 4; previously remapped for AyFX bank
        nextreg $54, 11

; Fade Layer2
        ld      a, 10
        ld      b, %0'001'0'0'0'1               ; Layer2 first palette + write auto-increment
        call    FadeOutPalette

; Fade Tilemap
        ld      a, 10
        ld      b, %0'011'0'0'0'1               ; TileMap first palette + write auto-increment
        call    FadeOutPalette

; Fade sprites
        ld      a, 7
        ld      b, %0'010'0'0'0'1               ; Sprites first palette + write auto-increment
        call    FadeOutPalette

; Reset sprites and attributes - Need to run to ensure at least one non-zero attribute is defined
        ld      a, MaxSprites
        call    ResetSprites

; - Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ld      a, (GameStatus2)
        res     2, a                    ; Enable use of pause function
        ld      (GameStatus2), a

; No need to close screen as tilemap/sprites faded and start next level routine will close screen

/*
; Close Screen
        ld      a, %00000001
        ld      (GameStatus), a                 ; Close Screen

.CloseScreenLoop:
        ld      a, 0                            ; Tilemap+sprite areas
        call    ProcessScreen

        ld      a, WaitForScanLineVideo
        call    WaitForScanlineUnderUla

        ld      a, (GameStatus)
        bit     0, a
        jp      nz, .CloseScreenLoop           ; Jump if screen still closing

*/
        ret

;-------------------------------------------------------------------------------------
; Setup/Display Game Over Text Screen
; Parameters:
DisplayLevelGameOverText:
        call    SetupLevelCompleteGameOver

        ld      a, (GameStatus2)
        set     2, a                    ; Disable use of pause function
        res     3, a                    ; Reset anti-free restriction i.e. Permit RMB     

        ld      (GameStatus2), a

; Display sprite text for level
; - Level text
        ld      ix, LevelNumberText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 1
        call    PrintSpriteText

; - Level Value
        ld      de, SpriteString2
        ld      a, (CurrentLevel)
        ld      b, 2                            ; Number of digits
        call    ConvertIntToString2

        ld      hl, LevelNumberValueXY          ; Block position
        ld      ix, SpriteString2               ; Text string
        ld      a, 1
        call    PrintSpriteText

; - Level text
        ld      ix, LevelGameOverText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 1
        call    PrintSpriteText

; - Level text
        ld      ix, LevelGameOverFriendlyText1
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

        ld      ix, LevelGameOverFriendlyText2
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Level Friendly Rescued Value
        ld      de, SpriteString2
        ld      a, (FriendlyTotalRescued)
        ld      b, 2                                    ; Number of digits
        call    ConvertIntToString2

        ld      hl, LevelGameOverRescuedValueXY         ; Block position
        ld      ix, SpriteString2                       ; Text string
        ld      a, 0
        call    PrintSpriteText

; - Spawn Friendly sprite - Animated
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                                    ; Spawn at first sprite attribute position
        ld      hl, LevelGameOverFriendlySpriteXY       ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, FriendlySpriteTextPatterns
        call    UpdateSpritePattern

; - Level Friendly Value
        ld      de, SpriteString2
        ld      a, (LevelDataFriendlyNumber)
        ld      b, 2                                    ; Number of digits
        call    ConvertIntToString2

        ld      hl, LevelGameOverFriendlyValueXY        ; Block position
        ld      ix, SpriteString2                       ; Text string
        ld      a, 0
        call    PrintSpriteText

; - Spawn Mouse sprite-1 - Animated - Left-Click
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelMenuMouseSprite1XY     ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, MouseSpriteTextPatterns     ; Sprite pattern range
        call    UpdateSpritePattern
/*
; - Spawn Mouse sprite-2 - Animated - Right-Click
        ld      ix, FriendlySprType
        ld      iy, Sprites
        ld      a, 0                            ; Spawn at first sprite attribute position
        ld      hl, LevelStartMouseSprite2XY     ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        push    ix
        ld      ix, iy
        pop     iy

        ld      bc, MouseSpriteTextPatterns     ; Sprite pattern range
        call    UpdateSpritePattern

        set     3, (ix+S_SPRITE_ATTR.mrx8)      ; Horizontally mirror sprite i.e. Reuse existing mouse sprites
*/
; - Click text
        ld      ix, LevelClickForMenuText
        ld      hl, (ix)                        ; Block position
        inc     ix
        inc     ix                              ; Point to text string
        ld      a, 0
        call    PrintSpriteText

; - Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Fade in text sprites
        ld      a, 7
        ld      b, %0'010'0'0'0'1               ; Sprites first palette + write auto-increment
        ld      c, 32
        call    FadeInPalette

; Setup Sprite Palette Cycle Values
        ld      a, 0                                    ; Cycle immediately
        ld      (BackupByte4), a                        ; Frame delay between complete cycles
        ld      a, LevelIntroCycleColours           
        ld      (BackupByte5), a                        ; Colours for complete cycle
        ld      a, 0                                    ; Cycle immediately
        ld      (BackupByte6), a                        ; Frame delay within complete cycle

; Audio
; - Map AyFX memory bank into slot 4 and play audio
        ld      a, $$AyFXBankGameOver
        nextreg $54, $$AyFXBankGameOver

        ld       hl, AyFXBankGameOver   ; AyFX bank containing sound effects
        call    SetupAYFXNonGame

        ld      a, 0                    ; Only play once when screen opened
        call    AFX1Play
        ld      a, 1                    ; Only play once when screen opened
        call    AFX2Play
        ld      a, 2                    ; Only play once when screen opened
        call    AFX3Play

        ;ld      a, AyFXGameOver                         ; Only play once when screen opened
        ;call    AFX2Play

.CyclePalette:
        halt

; Play sound effects
        call    AFX1Frame
        call    AFX2Frame
        call    AFX3Frame

        call    CyclePaletteWithDelay                   ; Cycle sprite colours

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

; Animate Friendly sprites
        ld      iy, Sprites

.AnimateLoop:
        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NextSprite                  ; Jump if sprite not friendly

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern
        
.NextSprite
        ld      bc, S_SPRITE_TYPE
        add     iy, bc

        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      1
        jp      z, .AnimateLoop

        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Check mouse input
        ld      a, (PlayerInput)
        bit     5, a
        jp      nz, .ReturnToTitle              ; Jump if mouse left-button already clicked
        ;bit     6, a
        ;jp      nz, .ReturnToTitle              ; Jump if mouse right-button already clicked

        call    ReadPlayerInput

        jp      .CyclePalette

/* - 08/01/24 - Disabled left-click replay level
.ReplayLevel:
        ld      a, (GameStatus2)
        set     0, a                            ; Set replay level flag
        ld      (GameStatus2), a

        jp      .ContExit
*/

.ReturnToTitle:
        ld      a, (GameStatus2)
        set     1, a                            ; Set return to title screen flag
        ld      (GameStatus2), a

.ContExit:
        ;ld      a, (GameStatus)
        ;bit     4, a
        ;jp      nz, .Finish                     ; Jump if Start next level bit set

;.Finish:
        call    SetupAYFXGame

; Map ULA Memory bank 11 (8KB) back to slot 4; previously remapped for AyFX bank
        nextreg $54, 11

; Fade Layer2
        ld      a, 10
        ld      b, %0'001'0'0'0'1               ; Layer2 first palette + write auto-increment
        call    FadeOutPalette

; Fade Tilemap
        ld      a, 10
        ld      b, %0'011'0'0'0'1               ; TileMap first palette + write auto-increment
        call    FadeOutPalette

; Fade sprites
        ld      a, 7
        ld      b, %0'010'0'0'0'1               ; Sprites first palette + write auto-increment
        call    FadeOutPalette

; Reset sprites and attributes - Need to run to ensure at least one non-zero attribute is defined
        ld      a, MaxSprites
        call    ResetSprites

; - Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Close screen immediately as we have faded out tilemap/sprites
; Note: Setting tilemap/sprite screen to closed borders
        ld      a, ClearScreenY1Middle
        ld      (ClearScreenY1Counter), a
        ld      a, ClearScreenY2Middle
        ld      (ClearScreenY2Counter), a

        ld      a, ClearScreenX1Middle
        ld      (ClearScreenX1Counter), a
        ld      a, ClearScreenX2Middle
        ld      (ClearScreenX2Counter), a

        ld      a, 0                            ; Close tilemap, layer2 & sprite screens
        ld      (BackupByte7), a
        call    UpdateScreen

        ld      a, (GameStatus2)
        res     2, a                    ; Enable use of pause function
        ld      (GameStatus2), a

        ret

;-------------------------------------------------------------------------------------
; Setup Level Complete/GameOver References
; Parameters:
SetupLevelCompleteGameOver:
; Reset Variables
        ld      a, 0
        ld      (PlayerInput), a
        ld      (GameStatus), a

; Set camera starting coordinates; required for spawning sprites at correct locations
        ld      hl, 16
        ld      (CameraXWorldCoordinate), hl
        ld      (CameraYWorldCoordinate), hl

; Fade sprites + Reset
        ld      a, 3
        ld      b, %0'010'0'0'0'1               ; Sprites first palette + write auto-increment
        call    FadeOutPalette

        ld      a, MaxSprites
        call    ResetSprites

; - Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

; Fade Layer2
        ld      a, 2
        ld      b, %0'001'0'0'0'1               ; Layer2 first palette + write auto-increment
        call    FadeOutPalette

; Fade Tilemap
        ld      a, 2
        ld      b, %0'011'0'0'0'1               ; TileMap first palette + write auto-increment
        call    FadeOutPalette

; Wait for vertical sync to ensure screen not corrupted when loading following sprite memory banks
        halt

; Play sound effects
        call AFX3Frame
        call AFX2Frame
        call AFX1Frame

; Import/Display Text Sprites
        call    SetupTextSprites

; - ReMap ULA Memory banks 10/11 (16KB) to slots 3/4; previously remapped when importing sprites
        nextreg $53, 10
        nextreg $54, 11

        ret

;-------------------------------------------------------------------------------------
; Setup Level References
; Parameters:
; a = Level Number
SetupLevelReferences:
        dec     a                       ; Level reference starts at 0
        
        ld      d, a                    ; Level Number
        ld      e, S_LEVEL_REFERENCE    ; Size of level data
        mul     d, e                    ; de = Level Data Offset

        ld      ix, LevelData
        add     ix, de                  ; ix = Level Data for required level

; Configure level data variables
; - Obtain level data references
        ld      a, (ix+S_LEVEL_REFERENCE.TileMapMemBank)
        ld      (LevelDataMemBank), a

        ld      hl, (ix+S_LEVEL_REFERENCE.LevelDataReference)
        ld      ix, hl

; - Map level data memory bank to slot 3
        nextreg $53, a                          

; - Configure variables
        ld      a, (ix+S_LEVEL_DATA.TileMapDefMemBank)
        ld      (LevelDataTileMapDefMemBank), a

        ld      hl, (ix+S_LEVEL_DATA.TileMapDefPalAddress)
        ld      (LevelDataTileMapDefPalData), hl

        ld      a, (ix+S_LEVEL_DATA.TileMapPalOffset)
        ld      (LevelDataPalOffset), a

        ld      a, (ix+S_LEVEL_DATA.TileMapPalOffset2)
        ld      (LevelDataPalOffset2), a

        ld      a, (ix+S_LEVEL_DATA.TileMapPalOffset3)
        ld      (LevelDataPalOffset3), a

        ld      hl, (ix+S_LEVEL_DATA.TileMapData)
        ld      (LevelDataTileMapData), hl

        ld      hl, (ix+S_LEVEL_DATA.PlayerData)
        ld      (LevelDataPlayerData), hl

        ld      a, (ix+S_LEVEL_DATA.WayPoints)
        ld      (LevelDataWayPointNumber), a
        ld      hl, (ix+S_LEVEL_DATA.WayPointData)
        ld      (LevelDataWayPointData), hl

        ld      a, (ix+S_LEVEL_DATA.SpawnPoints)
        ld      (LevelDataSpawnPointNumber), a
        ld      hl, (ix+S_LEVEL_DATA.SpawnPointData)
        ld      (LevelDataSpawnPointData), hl

        ld      a, (ix+S_LEVEL_DATA.Friendlys)
        ld      (LevelDataFriendlyNumber), a
        ld      hl, (ix+S_LEVEL_DATA.FriendlyData)
        ld      (LevelDataFriendlyData), hl

        ld      a, (ix+S_LEVEL_DATA.Keys)
        ld      (LevelDataKeyNumber), a
        ld      hl, (ix+S_LEVEL_DATA.KeyData)
        ld      (LevelDataKeyData), hl

        ld      a, (ix+S_LEVEL_DATA.Turrets)
        ld      (LevelDataTurretNumber), a
        ld      hl, (ix+S_LEVEL_DATA.TurretData)
        ld      (LevelDataTurretData), hl

        ld      a, (ix+S_LEVEL_DATA.Hazards)
        ld      (LevelDataHazardNumber), a
        ld      hl, (ix+S_LEVEL_DATA.HazardData)
        ld      (LevelDataHazardData), hl

        ld      a, (ix+S_LEVEL_DATA.Lockers)
        ld      (LevelDataLockerNumber), a
        ld      hl, (ix+S_LEVEL_DATA.LockerData)
        ld      (LevelDataLockerData), hl

        ld      a, (ix+S_LEVEL_DATA.TriggerSource)
        ld      (LevelDataTriggerSourceNumber), a
        ld      hl, (ix+S_LEVEL_DATA.TriggerSourceData)
        ld      (LeveldataTriggerSourceData), hl

        ld      a, (ix+S_LEVEL_DATA.TriggerTarget)
        ld      (LevelDataTriggerTargetNumber), a
        ld      hl, (ix+S_LEVEL_DATA.TriggerTargetData)
        ld      (LevelDataTriggerTargetData), hl

        ld      hl, (ix+S_LEVEL_DATA.L2Data)
        ld      (LevelDataL2Data), hl
        ld      hl, (ix+S_LEVEL_DATA.L2PaletteData)
        ld      (LevelDataL2PaletteData), hl

; - ReMap ULA Memory bank 10 to slot 3
        nextreg $53, 10

        ret

;-------------------------------------------------------------------------------------
; Setup new level
; Parameters:
SetupLevelData:
; --- Clear EnemyMovementBlockMap data via DMA - Reset prior to spawning sprites
        ld      iy, EnemyMovementBlockMap                       ; Destination
        ld      a, 0
        ld      (iy), a                                         ; Set intial value to be copied
        LD      HL, DMAEnemyMovementBlockMapDataClear	        ; HL = pointer to DMA program
        LD      B, DMAEnemyMovementBlockMapDataClearCopySize       ; B = size of the code
        LD      C, $6B                                          ; C = $6B (zxnDMA port)
        OTIR                                                    ; upload DMA program

; --- Clear FriendlyMovementBlockMap data via DMA- Reset prior to spawning sprites
        ld      iy, FriendlyMovementBlockMap                    ; Destination
        ld      a, 0
        ld      (iy), a                                         ; Set intial value to be copied
        LD      HL, DMAFriendlyMovementBlockMapDataClear	; HL = pointer to DMA program
        LD      B, DMAFriendlyMovementBlockMapDataClearCopySize ; B = size of the code
        LD      C, $6B                                          ; C = $6B (zxnDMA port)
        OTIR                                                    ; upload DMA program

; --- Setup Trigger Data - Run per Level
        ld      a, (LevelDataMemBank)           ; Memory bank (8kb) containing trigger data
        call    InitTriggers

; --- Setup Level - Run per Level
; - Setup TileMap
        ld      a, (LevelDataMemBank)           ; Memory bank (8kb) containing tilemap data
        call    SetupLevelTileMap

; - Draw tilemap
        call    DrawTileMap

; - Camera
        call    CameraSetInitialCoords

; - Spawn Sprites - Run Per Level
        ld      a, (LevelDataMemBank)   ; Memory bank (8kb) containing tilemap data
        call    SetupLevelSprites

; - Populate Door Data
        call    PopulateDoorData

; - Setup L2 Data; L2 not shown until level starts
        ld      a, (LevelDataMemBank)           ; Memory bank (8kb) containing tilemap data
        call    Layer2SetupLevel

        ret

;-------------------------------------------------------------------------------------
; Setup Game values - Reset Game Values
ConfigGameValues:
        ld      a, 0
        ld      (PlayerDamageDelayCounter), a
        ld      (SavePointSavedPlayerEnergy), a
        ld      (SavePointSavedPlayerFreeze), a
        ld      (SavePointCreditFriendlyCounter), a
        ld      (SavePointCredits), a                   ; Can remove to allow credits to carry between levels
        ld      (PlayerInput), a
        ld      (PlayerInputOriginal), a
        ld      (L2ScrollDelayCounter), a
        ld      (TurretPreviousRotation), a             ; Need to reset, otherwise turret sprites may be placed incorrectly at spawn time

        ld      hl, 0
        ld      (SavePointSavedBlockOffset), hl

        ld      (BulletsPlayerFired), a
        ld      (BulletsEnemyFired), a
        ld      (PlayerSprite+S_SPRITE_TYPE.DelayCounter), a

        ld      (CollectableSpawnCounter), a

        ld      (FriendlyTotalRescued), a

        ld      (ReverseHazardEnabled), a
        ld      (ReverseHazardEnabledPlayer), a

        ld      (PlayerType1Keys), a
        ld      (PlayerType2Keys), a

        ld      (ReticuleRotation), a           ; Set intial reticule rotation to 0

        ld      (FFNodesPerCallCounter), a
        ld      (FFQueueContent), a
        ld      (FFBuilt), a

        ld      (CycleTMColourDelayCounter), a

        ld      (LockerCollectibleSwitchDelayCounter), a

        ld      (DoorLockdown), a
        ld      a, DoorLockdownPalCycleDisabled
        ld      (DoorLockdownPalCycleOffset), a

        ld      (PauseDelayCounter), a

        ld      a, %00100010
        ld      (GameStatus), a         ; Set Game Start bit + Open Screen bit

        ld      a, (GameStatus2)
        and     %00010000               ; Clear except difficulty bit
        ld      (GameStatus2), a        ; Clear Game Status2

        ld      a, ClearScreenY1Middle
        ld      (ClearScreenY1Counter), a
        ld      a, ClearScreenY2Middle
        ld      (ClearScreenY2Counter), a

        ld      a, ClearScreenX1Middle
        ld      (ClearScreenX1Counter), a
        ld      a, ClearScreenX2Middle
        ld      (ClearScreenX2Counter), a

        ld      a, EndOfLevelPause
        ld      (EndOfLevelPauseCounter), a

; Set game mouse speed
        ld      a, MouseSpeedGame
        ld      (MouseSpeed), a

; Reset FloodFill Values
; - Clear FFStorage
        ld      hl, FFStorage
        ld      (hl), FFResetValue                   ; Set intial value to be copied

        LD      HL, DMAFFStorageClear           ; HL = pointer to DMA program
        LD      B, DMAFFStorageClearCopySize    ; B = size of the code
        LD      C, $6B                          ; C = $6B (zxnDMA port)
        OTIR                                    ; upload DMA program

; - Clear controlling values
        ld      a, 0
        ld      (FFQueueContent), a
        ld      (FFNodesPerCallCounter), a
        ld      (FFBuilt), a

        ld      hl, Queue
        ld      (QueueStart), hl

; Populate initial mouse values
        ld      bc, $FBDF			;FADF Mouse Buttons port
	in      a, (c)			        ; FBDF Mouse Xpos - Obtain new MouseX value
	ld      (XMove), a                      ; Store new mouseX value
	
	ld      b, $FF	                        ; Point to mouse Y position input port
	in      a, (c)			        ; FFDF Mouse Ypos - Obtain new MouseY value
	ld      (YMove), a                      ; Store new mouseY value

        ret

;-------------------------------------------------------------------------------------
; Setup Game values - Reset Score
ResetScore:
; Reset score
        ld      hl, Score

        ld      b, ScoreLength
.ResetScoreLoop:
        ld      (hl), 48                ; Reset to ASCII 48 i.e. 0
        inc     hl                      ; Point to next score digit
        djnz    .ResetScoreLoop

        ret
        
;-------------------------------------------------------------------------------------
; Check for end of level conditions - player dead, all friendly rescued
; Parameters:
CheckEndOfLevel:
; Check for player end of level animation playing
        ld      a, (GameStatus)
        bit     5, a
        ret     nz                              ; Return if player end of level animation playing

; Check whether screen is closing
        bit     0, a
        ret     nz                              ; Return if screen closing

; Check whether next level can be started
        bit     4, a
        jp      nz, .NextLevel                  ; Jump if next level can be started

; Check whether game over
        bit     3, a
        jp      nz, .GameOver                   ; Jump if game over

; Check for Level Complete
        bit     6, a
        jp      nz, .LevelComplete              ; Jump if level complete

; Check for Save point (scroll)
        ld      a, (GameStatus2)
        bit     5, a
        jp      nz, .SavePointScroll            ; Jump if Save point (scroll)

; Check player dead - TODO
        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        cp      0
        jp      z, .PlayerDead          ; Jump if energy = 0

; Check all friendly rescued - TODO
        ld      a, (FriendlyTotalRescued)
        ld      b, a
        ld      a, (FriendlyInLevel)
        cp      b
        jp      z, .AllFriendlyRescued  ; Jump if all friendly rescued

        ret

.PlayerDead:    ; TODO        
        ld      a, (SavePointSavedPlayerEnergy)
        cp      0
        jp      nz, .SavePointDisappear ; Jump if savepoint with > 0 energy

; No Save point
; Play audio effect
        ld      a, AyFXPlayerDestroyed
        call    AFX3Play

        ;ld a, 0
	;out (#fe), a   ; set the border color

; Update player position/scale and player dead animation
        ld      a, (GameStatus)

        set     5, a                    ; Set Player Animation flag
        set     3, a                    ; Set Game Over flag
        ld      (GameStatus), a

        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        
        ld      hl, (iy+S_SPRITE_TYPE.xPosition)
        add     hl, -24
        ld      (iy+S_SPRITE_TYPE.xPosition), hl

        ld      (ix+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        or      h                                       ; MSB of the X Position
        ld      (ix+S_SPRITE_ATTR.mrx8), a  

        ld      hl, (iy+S_SPRITE_TYPE.yPosition)
        add     hl, -24
        ld      (iy+S_SPRITE_TYPE.yPosition), l         ; Update sprite position to accomodate tilemap y offset

        ld      (ix+S_SPRITE_ATTR.y), l                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

; - Scale player sprite
        ld      a, (ix+S_SPRITE_ATTR.Attribute4)
        or      %000'10'10'0                            ; Scale x + y
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5

; - Change player sprite pattern
        ld      bc, PlayerPatternsExp                   ; Sprite pattern range
        call    UpdateSpritePattern

        ret

.AllFriendlyRescued:    ; TODO
; - Check whether finish blocks already enabled
        ld      a, (GameStatus)
        bit     7, a
        ret     nz                      ; Return if finish blocks enabled

; - If not, enable finish blocks
        ld      a, AyFXAllRescuedChA
        call    AFX1Play
        ld      a, AyFXAllRescuedChA
        call    AFX2Play
        ld      a, AyFXAllRescuedChB
        call    AFX3Play

        call    UpdateFinishBlocks

        ld      a, (GameStatus)
        set     7, a
        ld      (GameStatus), a         ; Set finish blocks flag

; - Change to level complete palette
        ld      a, (LevelDataPalOffset3)
        ld      (CurrentTileMapPal), a
        call    SelectTileMapPalOffset

        ld      a, FriendlyRescuedPalCycleEnabled
        ld      (DoorLockdownPalCycleOffset), a

        ret

.LevelComplete:         ; TODO
; Update Score
        push    af
        ld      iy, ScoreCompleteLevel
        call    UpdateScore
        pop     af

; Update player position/scale and play level complete animation
        set     5, a                    ; Set Player Animation flag
        set     4, a                    ; Set Next Level flag
        ld      (GameStatus), a

        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        
; - Set player sprite to finish block position
        ld      hl, (FinishBlockXY)
        call    ConvertBlockToWorldCoord

        ld      hl, (iy+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (CameraXWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        add     hl, -8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl

        ld      (ix+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        or      h                                       ; MSB of the X Position
        ld      (ix+S_SPRITE_ATTR.mrx8), a  

        ld      hl, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ld      de, (CameraYWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        add     hl, -8
        ld      (iy+S_SPRITE_TYPE.yPosition), l         ; Update sprite position to accomodate tilemap y offset

        ld      (ix+S_SPRITE_ATTR.y), l                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

; - Scale player sprite
        ld      a, (ix+S_SPRITE_ATTR.Attribute4)
        or      %000'01'01'0                            ; Scale x + y
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5

; - Change player sprite pattern
        ld      bc, FriendlyPatternsRes                 ; Sprite pattern range
        jp      UpdateSpritePattern

        ret

.SavePointDisappear:
; Start Save point move process
        ld      a, (GameStatus2)
        res     7, a                            ; Reset Play sound flag
        set     6, a                            ; Set Save point (disappear) flag
        ld      (GameStatus2), a

; Update player position/scale and play level complete animation
        ld      a, (GameStatus)
        set     5, a                    ; Set Player Animation flag
        ld      (GameStatus), a

        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite
        
; - Set player sprite to finish block position        
        ld      hl, (iy+S_SPRITE_TYPE.xPosition)
        add     hl, -8
        ld      (iy+S_SPRITE_TYPE.xPosition), hl

        ld      (ix+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        or      h                                       ; MSB of the X Position
        ld      (ix+S_SPRITE_ATTR.mrx8), a  

        ;;;ld      hl, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ;;;ld      de, (CameraYWorldCoordinate)
        ;;;call    ConvertWorldToDisplayCoord

        ld      a,(iy+S_SPRITE_TYPE.yPosition)          ; Update sprite position to accomodate tilemap y offset
        add     -8
        ld      (iy+S_SPRITE_TYPE.yPosition), a         ; Update sprite position to accomodate tilemap y offset

        ld      (ix+S_SPRITE_ATTR.y), a                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

; - Scale player sprite
        ld      a, (ix+S_SPRITE_ATTR.Attribute4)
        or      %000'01'01'0                            ; Scale x + y
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5

; - Change player sprite pattern
        ld      bc, FriendlyPatternsRes                 ; Sprite pattern range
        jp      UpdateSpritePattern

.SavePointScroll:
; Scroll to Save point
; Note: Both the scroll tile block and the incremental scroll within the tile block needs to be
;       complete for both X & Y
; - Check scroll X & Y complete
        ld      a, (SavePointScrollComplete)
        cp      %00000011                               ; %------XY
        jp      z, .SavePointScrollComplete             ; Jump if both scroll X & Y are complete

; - Check scroll X block complete
        ld      a, (ScrollTileMapBlockXPointer)
        ld      b, a
        ld      a, (SavePointScrollTileMapBlockXPointer)
        cp      b
        jp      z, .SavePointXEqual                     ; Jump if Scroll X block = Save point block

; - Check scroll X block > Save point
        jp      c, .SavePointScrollLeft                 ; Jump if Scroll X block > Save point block

        call    CheckScrollRight                        ; Otherwise scroll

; - Check/Update for L2 scrolling
        cp      1
        jp      nz, .SavePointCheckY

        ld      a, (Scrolled)
        set     1, a
        ld      (Scrolled), a

        jp      .SavePointCheckY

.SavePointScrollLeft:
        call    CheckScrollLeft

; - Check/Update for L2 scrolling
        cp      1
        jp      nz, .SavePointCheckY

        ld      a, (Scrolled)
        set     0, a
        ld      (Scrolled), a

.SavePointCheckY:
; - Check scroll Y block complete
        ld      a, (ScrollTileMapBlockYPointer)
        ld      b, a
        ld      a, (SavePointScrollTileMapBlockYPointer)
        cp      b
        jp      z, .SavePointYEqual                     ; Jump if Scroll Y block = Save point block

; - Check scroll Y block > Save point
        jp      c, .SavePointScrollUp                   ; Jump if Scroll Y block > Save point block

        call    CheckScrollDown                         ; Otherwise scroll

; - Check/Update for L2 scrolling
        cp      1
        ret     nz

        ld      a, (Scrolled)
        set     3, a
        ld      (Scrolled), a

        ret

.SavePointScrollUp:
        call    CheckScrollUp

; - Check/Update for L2 scrolling
        cp      1
        ret     nz

        ld      a, (Scrolled)
        set     2, a
        ld      (Scrolled), a

        ret

; Scroll X block complete - Check incremental
.SavePointXEqual:
        ld      a, (ScrollXValue)
        cp      0
        jp      z, .SavePointXEqual2                    ; Jump if X incremental equal

        call    CheckScrollLeft                         ; Otherwise scroll left

        jp      .SavePointCheckY

.SavePointXEqual2:
        ld      a, (SavePointScrollComplete)
        set     1, a                                    ; Set X complete flag
        ld      (SavePointScrollComplete), a

        jp      .SavePointCheckY

; Scroll Y block complete - Check incremental
.SavePointYEqual:
        ld      a, (ScrollYValue)
        cp      0                                       
        jp      z, .SavePointYEqual2                    ; Jump if Y incremental equal

        call    CheckScrollUp                           ; Otherwise scroll up
        ret

.SavePointYEqual2:
        ld      a, (SavePointScrollComplete)
        set     0, a                                    ; Set Y complete flag
        ld      (SavePointScrollComplete), a

        ret

.SavePointScrollComplete:
; Scroll X & Y complete to Save point
        ld      a, (GameStatus2)
        and     %00010000               ; Clear except difficulty bit
        ld      (GameStatus2), a        ; Clear Game Status2

        call    ReSpawnPlayerSprite

        ret

; Game Over
.GameOver:             ; TODO        
        ;call    DisplayLevelCompleteText
        ;call    StartNextLevel

; - Pause to allow sound effects to finish
        ld      a, (EndOfLevelPauseCounter)
        cp      0
        jp      z, .GameOverPauseComplete       ; Jump if counter = 0

        dec     a
        ld      (EndOfLevelPauseCounter), a

        ret

.GameOverPauseComplete:
; - Init to stop current sound effects
        call    SetupAYFXGame

        call    DisplayLevelGameOverText

; Check whether we should exit to title screen
        ld      a, (GameStatus2)
        bit     1, a
        ret     nz                              ; Return if exit selected

        ld      a, (GameStatus2)
        set     0, a
        ld      (GameStatus2), a                ; Set replay level flag

        call    StartNewGame

        ret

; Start next level
.NextLevel:             ; TODO
; - Pause to allow sound effects to finish
        ld      a, (EndOfLevelPauseCounter)
        cp      0
        jp      z, .LevelPauseComplete          ; Jump if counter = 0

        dec     a
        ld      (EndOfLevelPauseCounter), a

        ret

.LevelPauseComplete:
; - Init to stop current sound effects
        call    SetupAYFXGame

        call    DisplayLevelCompleteText

; Check whether we should exit to title screen
        ld      a, (GameStatus2)
        bit     1, a
        ret     nz                              ; Return if exit selected

        call    StartNextLevel
        
        ret

;-------------------------------------------------------------------------------------
; Player - Setup level values
; Parameters:
SetupPlayerStartPosition:
; Setup player sprite level starting block 
        ld      ix, (LevelDataPlayerData)
        ld      bc, (ix+S_PLAYER_DATA.PlayerWorldX)     ; Player world x coordinate
        ld      hl, (ix+S_PLAYER_DATA.PlayerWorldY)     ; Player world y coordinate
        call    ConvertWorldToBlockOffset

        ld      (PlayerStartXYBlock), de                ; Set player starting block

        ret

;-------------------------------------------------------------------------------------
; Finish - Find Finish Position - Search Tilemap for Finish Disable Centre block
; Parameters:
FindFinishPosition:
        ld      ix, LevelTileMapData

        ld      b, 0
.HeightLoop:
        push    bc

        ld      b, 0
.WidthLoop:
        ld      a, (ix)
        cp      FinishDisableCentreBlock
        jp      z, .FoundFinishBlock            ; Jump if finish disable block found

        ld      a, b
        cp      LevelTileMapMaxWidth
        jp      z, .NextLine                    ; Jump if end of line

        inc     b                               ; Point to next column
        inc     ix                              ; Point to next tilemap position

        jp      .WidthLoop

.NextLine:
        pop     bc

        ld      a, b
        cp      LevelTileMapMaxWidth
        jp      z, .FinishNotFound              ; Jump if end of tilemap and finish block not found

        inc     b                               ; Point to next line

        jp      .HeightLoop

; - Finish block found
.FoundFinishBlock:
        pop     af                              ; Restore line number (bc)

        ld      l, a                            ; Store finish y position

        ld      d, a
        ld      e, LevelTileMapMaxWidth        
        mul     d, e                            ; Calculate screen height offset

        ld      a, b
        add     de, a                           ; Add screen column to offset

        ld      (FinishBlockOffset), de         ; Store finish offset

        ld      h, a                            ; Store finish x position

        ld      (FinishBlockXY), hl

        ret

; - Finish block not found
.FinishNotFound:
        break

        ret

;-------------------------------------------------------------------------------------
; Player Taking Damage
; Parameters:
; b = Damage
PlayerTakeDamage:   ; TODO
        ;ld a, 3
	;out (#fe), a   ; set the border color

; Check whether player playing animation i.e. start, respawn
        ld      a, (GameStatus)
        bit     5, a                    
        ret     nz                                      ; Return if animation flag set

; Check whether player performing Savepoint (scroll)
        ld      a, (GameStatus2)
        bit     5, a                    
        ret     nz                                      ; Return if Savepoint (scroll) set

; Check whether player respawned and should not be taking damage
        ld      a, (RespawnDamageDelayCounter)
        cp      0
        ret     nz                                      ; Return if player respawned within damage delay window

; Check whether we can take damage based on delay counter
        ld      a, (PlayerDamageDelayCounter)
        cp      0
        ret     nz                                      ; Return if counter != 0

; Reset damage delay counter and take damage if playing player start/end/dead animation
        ld      a, (GameStatus)
        and     %01111111
        cp      0
        ret     nz                       ; Return if any game status flag other than FinishEnabled is set 

; Play audio effect
        push    ix, bc

        ld      a, AyFXPlayerHit
        call    AFX2Play

        pop     bc, ix

        ld      a, PlayerDamageDelay
        ld      (PlayerDamageDelayCounter), a

        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        sub     b                                       ; Subtract damage
        ld      (PlayerSprite+S_SPRITE_TYPE.Energy), a  ; If necessary, target destroyed when target processed

; Update energy HUD values
        push    af

        ld      b, HUDEnergyValueDigits
        ld      d, a
        ld      a, (HUDEnergyValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites                      

; Check/Update Reticule Sprite
        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        cp      ReticuleLowEnergyThreshold+1
        jp      nc, .CheckMidEnergy                     ; Jump if player energy > ReticuleLowEnergyThreshold

; - Low energy - Change to Reticule low energy palette
        ld      iy, ReticuleSprite

        ld      hl, RetLowEnergyPatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

	ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for all states
        call    UpdateSpritePattern4BitStatus

        jp      .Continue

.CheckMidEnergy:
        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        cp      ReticuleMidEnergyThreshold+1
        jp      nc, .Continue                           ; Jump if player energy > ReticuleMidEnergyThreshold

; - Mid energy - Change to Reticule mid energy palette
        ld      iy, ReticuleSprite

        ld      hl, RetMidEnergyPatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

	ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for all states
        call    UpdateSpritePattern4BitStatus

.Continue:
; Update player sprite definition with updated animation delay
        ;;;call    UpdatePlayerAnimationDelay
        pop     af

; Check whether the player energy is negative and we need to set to 0
        jp      c, .EnergyNegative                      ; Jump if energy negative

        ret

.EnergyNegative:
; Set player energy to 0 if energy negative
; Update energy HUD values
        ld      b, HUDEnergyValueDigits
        ld      a, (HUDEnergyValueSpriteNum)
        ld      c, a
        ld      a, 0
        ld      (PlayerSprite+S_SPRITE_TYPE.Energy), a  ; If necessary, target destroyed when target processed
        ld      de, $0000                               ; Do not convert string
        call    UpdateHUDValueSprites                      

        ret

;-------------------------------------------------------------------------------------
; Player Updating Energy
; Parameters:
; b = Additional Energy
PlayerUpdateEnergy:   ; TODO
        ;ld a, 3
	;out (#fe), a   ; set the border color

        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        add     b                                       ; Add energy

        ld      (PlayerSprite+S_SPRITE_TYPE.Energy), a  ; If necessary, target destroyed when target processed

; Update energy HUD values
        push    af

        ld      b, HUDEnergyValueDigits
        ld      d, a
        ld      a, (HUDEnergyValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites                      

        pop     af

        ld      b, a
        ld      a, (MaxPlayerEnergy)
        cp      b
        jp      nc, .UpdateAnimationDelay               ; Jump if updated energy <= max player energy

        ld      (PlayerSprite+S_SPRITE_TYPE.Energy), a  ; Otherwise set to max player energy

; Update energy HUD values
        ld      b, HUDEnergyValueDigits
        ld      d, a
        ld      a, (HUDEnergyValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites                      

.UpdateAnimationDelay:
; Update player sprite definition with updated animation delay
        ;;;call    UpdatePlayerAnimationDelay

; Check/Update Reticule Sprite
        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        cp      ReticuleLowEnergyThreshold+1
        ret     c                                       ; Return if player energy <= ReticuleLowEnergyThreshold

        cp      ReticuleMidEnergyThreshold+1
        jp      nc, .NormalEnergy                       ; Jump if player energy > ReticuleMidEnergyThreshold

; - Mid energy - Change to Reticule mid energy palette
        push    iy

        ld      iy, ReticuleSprite

        ld      hl, RetMidEnergyPatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

	ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for all states
        call    UpdateSpritePattern4BitStatus

        pop     iy

        ret

.NormalEnergy:
; - Normal energy - Change to Reticule normal energy palette
        push    iy

        ld      iy, ReticuleSprite

        ld      hl, RetNormalPatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

	ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for all states
        call    UpdateSpritePattern4BitStatus

        pop     iy

        ;ld a, 0
	;out (#fe), a   ; set the border color

        ret

;-------------------------------------------------------------------------------------
; Player Updating Freeze Time
; Parameters:
; b = Additional Freeze time
; Return:
PlayerUpdateFreeze:
        ;ld a, 3
	;out (#fe), a   ; set the border color

        ld      a, (PlayerFreezeTime)
        add     b                               ; Update freeze time
   
; - Check whether player now has max freeze time
        cp      PlayerFreezeMax+1
        jp      c, .UpdateHUD                   ; Jump if player freeze <= PlayerFreezeMax

        ld      a, PlayerFreezeMax              ; Otherwise reset to maximum freeze time

; Update freeze reticule values
.UpdateHUD:
        ld      (PlayerFreezeTime), a

        push    ix

; TODO - Reticule
; Update freeze reticule values
        ld      b, ReticuleFreezeValueDigits
        ld      d, a
        ld      a, (ReticuleFreezeValueSpriteNum);(HUDFreezeValueSpriteNum)
        ld      c, a
        ld      a, d
        call    UpdateReticuleValueSprites              ; Update reticule values

 /*
        ld      b, HUDFreezeValueDigits
        ld      d, a
        ld      a, (HUDFreezeValueSpriteNum)
        ld      c, a
        ld      a, d
        ;call    UpdateReticuleValueSprites                      
        call    UpdateHUDValueSprites
*/
        pop     ix

        ;ld a, 0
	;out (#fe), a   ; set the border color

        ret

;-------------------------------------------------------------------------------------
; Player Updating Bullet Type
; Parameters:
PlayerUpdateBulletType:   ; TODO
        ;ld a, 3
	;out (#fe), a   ; set the border color

        push    ix

        ld      hl, (BulletUpgradeTableRef)

        ld      ix, hl
        ld      de, (ix+S_BULLETUPGRADE_DATA.BulletUpgrade)
        ld      (PlayerSprite+S_SPRITE_TYPE.BulletType), de     ; Set new bullet to be fired

        add     hl, S_BULLETUPGRADE_DATA                        ; Point to next bullet upgrade in table

; Check whether we have reached the last bullet upgrade
        ld      bc, BulletUpgradeTableEnd
        sbc     hl, bc
        add     hl, bc
        jp      z, .UpdateRange                                 ; Jump if new bullet is the last bullet upgrade

        ld      ix, hl
        
        ld      a, (ix+S_BULLETUPGRADE_DATA.FriendlyRequired)
        ld      (BulletUpgradeFriendlyNumber), a                ; Store number of friendly required for next bullet upgrade

        ld      (BulletUpgradeTableRef), ix                     ; Store next bullet upgrade table reference

.UpdateRange:
        ld      ix, de                                          ; Restore new bullet reference
        ld      a, (ix+S_BULLET_DATA.range)
        ld      (PlayerSprite+S_SPRITE_TYPE.RotRange), a        ; Set new bullet range

        pop     ix

        ld      a, AyFXBulletUpgradeChA
        call    AFX1Play
        ld      a, AyFXBulletUpgradeChB
        call    AFX3Play

; Configure player upgrade sprite
        ld      a, (GameStatus3)
        set     1, a                                            ; Set bullet upgrade flag
        ld      (GameStatus3), a

        ret

;-------------------------------------------------------------------------------------
; Friendly Taking Damage
; Parameters:
; iy = Friendly sprite data
; b = Damage
FriendlyTakeDamage:   ; TODO
        ;ld a, 3
	;out (#fe), a   ; set the border color

; Check whether we can take damage based on delay counter
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        ret     nz                              ; Return if counter != 0

; Take damage
        ld      a, (iy+S_SPRITE_TYPE.Energy)
        sub     b                               ; Subtract damage
        jp      c, .FriendlyNegative

        ld      (iy+S_SPRITE_TYPE.Energy), a    ; If necessary, target destroyed when target processed

        ;ld a, 0
	;out (#fe), a   ; set the border color

        ret

.FriendlyNegative:
        ld      (iy+S_SPRITE_TYPE.Energy), 0    ; Reset negative energy value to 0

        ret

;-------------------------------------------------------------------------------------
; Friendly Rescued
; Parameters:
; ix = Friendly sprite data
; iy = Tilemap block location
; bc = Block Offset
; de = Block x, y
; BackupWord1 = Block x, y
FriendlyRescued:
        push    bc, de                                  ; (bc) Save Block Offset for later Trigger use
                                                        ; (de) Save Block x, y for later explosion use

; Play audio effect
        push    af, ix, hl, bc, de

        ld      a, AyFXFriendlyRescued
        call    AFX2Play

; Update Score
        push    iy
        ld      iy, ScoreRescueFriendly
        call    UpdateScore
        pop     iy

        pop     de, bc, hl, ix, af

; Source Tilemap - Replace rescue block
        ld      a, RescueDisableBlock
        ld      (iy), a                                 

; Screen TileMap - Update display
        ex      de, hl                                  ; hl = block x,y
        ;push    hl                                      ; Save Block x,y for spawning key
        ld      de, bc                                  ; de = block offset
        push    ix                                      ; Save sprite pointer
        call    UpdateScreenTileMap
        pop     ix                                      ; Restore sprite pointer

; Friendly - Set rescued flag - Causes friendly to play rescued animation
        set     5, (ix+S_SPRITE_TYPE.SpriteType3)

; Clear friendly block tracking byte bit
        ld      de, (ix+S_SPRITE_TYPE.MoveToBlock)
        call    EnemyResetBlockMapBit                   ; No need to check result

        ld      de, 0
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), de      ; Required to avoid enemy-to-friendly issue for deleted sprite

; Process friendly animation
; - Friendy just starting to be rescued; set run once settings  - i.e. Set new x, y for scaled explosion to fit within rescue tile
        pop     hl                                      ; (pop de) Restore block x, y

        ld      iy, ix
        call    ConvertBlockToWorldCoord
        
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     hl, -8      
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, -8
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

; - Scale friendly sprite
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      iy, bc                                  ; Destination - Sprite Attributes

        ld      a, (iy+S_SPRITE_ATTR.Attribute4)
        or      %000'01'01'0                            ; Scale x + y
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

; Update level values        
        ld      a, (FriendlyTotalRescued)
        inc     a
        ld      (FriendlyTotalRescued), a

; Check whether we should grant a Save point credit
        ld      a, (SavePointCreditFriendly)
        ld      b, a
        ld      a, (SavePointCreditFriendlyCounter)
        inc     a
        cp      b
        jp      nz, .NoSavePointCredit                  ; Jump if we haven't reached the required value 

        ld      a, 0
        ld      (SavePointCreditFriendlyCounter), a     ; Reset counter

; Award Save point credit
        ld      a, (SavePointCredits)
        inc     a
        ld      (SavePointCredits), a

; - Update player HUD values
        ld      b, HUDSavePointValueDigits
        ld      d, a
        ld      a, (HUDSavePointValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites                      

        jp      .CheckBulletUpgrade

; Do not grant a Save point credit
.NoSavePointCredit:
        ld      (SavePointCreditFriendlyCounter), a

.CheckBulletUpgrade:
; Check/Upgrade to next bullet upgrade
        ld      a, (BulletUpgradeFriendlyNumber)
        cp      0
        jp      z, .CheckTrigger                        ; Jump if friendly required = 0 i.e. No bullet upgrades left

        dec     a                                       ; Decrement friendly required for next bullet upgrade
        ld      (BulletUpgradeFriendlyNumber), a
        cp      0
        call    z, PlayerUpdateBulletType               ; Call if required number of friendly rescued i.e. Upgrade to new bullet upgrade

; Trigger Condition - Update TriggerTarget
.CheckTrigger:
        pop     hl                                      ; (pop bc) Restore block offset

        push    ix
        call    UpdateTriggerTargetData
        pop     ix
        
        ret

;-------------------------------------------------------------------------------------
; Spawn Point Hit
; Parameters:
; iy = Tilemap block location
; bc = Block Offset
; de = Block x, y
; a = Projectile damage
; Return:
; a = Updated projectile damage
SpawnPointHit:
; Find spawn point        
        push    iy, bc, de
        push    af

        ld      iy, SpawnPointData

        ld      de, bc                                  ; de = block offset
        ld      a, (SpawnPointsInLevel)
        ld      b, a
.FindSpawnPoint:
        push    de
        ld      hl, (iy+S_SPAWNPOINT_DATA.TileBlockOffset)
        or      a
        sbc     hl, de
        jp      z, .FoundSpawnPoint                     ; Jump if spawn point found

        ld      de, S_SPAWNPOINT_DATA
        add     iy, de
        
        pop     de

        djnz    .FindSpawnPoint
                
        pop     af
        pop     de, bc, iy

        ret

; Damage spawn point
.FoundSpawnPoint:
        pop     de
	pop	hl	                                ; Restore projectile damage (af)

        ld      (BackupWord1), iy                       ; Save spawnpoint data location

        ld      l, h
        ld      h, 0                                    ; hl = projectile damage
        ld      bc, (iy+S_SPAWNPOINT_DATA.Energy)

	or	a
	sbc	hl, bc
	jr      nc, .DestroySpawnPoint			; Jump if projectile damage >= spawnpoint energy

; Subtract damage from energy
        or      a
        adc     hl, bc                                  ; Restore hl

        ex      de, hl                                  ; de = Projectile damage
        ld      hl, bc                                  ; hl = Spawnpoint energy
        ld      bc, de                                  ; bc = Projectile damage

        or      a
        sbc     hl, bc

        ld      (iy+S_SPAWNPOINT_DATA.Energy), hl

        pop     de, bc, iy

        ld      a, 0                                    ; Return value: Projectile damage = 0

        ret

; Disable spawnpoint
.DestroySpawnPoint:
        ld      a, l
        ld      (BackupByte), a                         ; Return value: Projectile damage
        
        ld      a, 0
        ld      (iy+S_SPAWNPOINT_DATA.Active), a
        ld      (iy+S_SPAWNPOINT_DATA.Energy), a

        pop     de, bc, iy

; Play audio effect
        push    af, ix, bc, de

        ld      a, AyFXSpawnPointDisabled
        call    AFX2Play

; Update Score
        push    iy
        ld      iy, ScoreDestroySpawnPoint
        call    UpdateScore
        pop     iy

        pop     de, bc, ix, af

; Source Tilemap - Replace spawn point  block
        ld      (iy), SpawnPointDisabledBlock                                 

; Screen TileMap - Update display
        ld      hl, de                                  ; Parameter - hl = x block offset, y block offset
        ld      de, bc                                  ; Parameter - de = Block offset

        push    ix, de                                  ; Save sprite pointer, TileMap Offset
        call    UpdateScreenTileMap

; Trigger Condition - Update TriggerTarget
        pop     hl                                      ; (pop de) Restore TileMap offset

        call    UpdateTriggerTargetData

        pop     ix                                      ; Restore sprite pointer

; Update bullet based on destroyed spawnpoint
        ld      iy, (BackupWord1)                       ; Restore spawnpoint data location

        ld      hl, (iy+S_SPAWNPOINT_DATA.WorldX)
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl

        ld      hl, (iy+S_SPAWNPOINT_DATA.WorldY)
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

        set     4, (ix+S_SPRITE_TYPE.SpriteType3)

        ld      a, 0 ;(BackupByte)                       ; Return value

        ret

;-------------------------------------------------------------------------------------
; Spawn Point Destroyed
; Parameters:
; iy = Tilemap block location
; bc = Block Offset
; de = Block x, y
; a = Block to replace spawn block
SpawnPointDisabled:
        push    bc                                      ; Save block offset

; Source Tilemap - Replace spawn point  block
        ld      (iy), a                                 

; Screen TileMap - Update display
        ex      de, hl                                  ; hl = block x,y
        ld      de, bc                                  ; de = block offset
        push    ix                                      ; Save sprite pointer
        call    UpdateScreenTileMap
        pop     ix                                      ; Restore sprite pointer

; Find spawn point
        pop     de                                      ; Restore block offset
        
        ld      iy, SpawnPointData

        ld      a, (SpawnPointsInLevel)
        ld      b, a
.FindSpawnPoint:
        push    de
        ld      hl, (iy+S_SPAWNPOINT_DATA.TileBlockOffset)
        or      a
        sbc     hl, de
        jp      z, .FoundSpawnPoint                     ; Jump if spawn point found

        ld      de, S_SPAWNPOINT_DATA
        add     iy, de
        
        pop     de

        djnz    .FindSpawnPoint
                
        ret

; Disable spawn point
.FoundSpawnPoint:
        pop     de

        ld      a, 0
        ld      (iy+S_SPAWNPOINT_DATA.Active), a

        ret

;-------------------------------------------------------------------------------------
; Pause Routine
; Parameters:
ProcessPause:
; Animate Pause Sprite
; - Obtain address of pause sprite
        ld      a, (PauseValueSpriteNum)
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     de 
        ld      iy, Sprites
        add     iy, de                                  ; Point to sprite data for pause sprite

; - Animate
        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, hl                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range

        call    UpdateSpritePattern

; Display Activities = Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ret

;-------------------------------------------------------------------------------------
; Set Savepoint credit Friendly requirement
; Parameters:
SetSavePointCredits:
        ld      iy, (LevelDataPlayerData)

        ld      a, (iy+S_PLAYER_DATA.FriendlyPerSavePointCredit)
        ld      (SavePointCreditFriendly), a

; Check difficulty and override values
        ld      a, (GameStatus2)
        bit     4, a
        ret     z                       ; Return if not hard difficulty

; - Override with hard values
        ld      a, (iy+S_PLAYER_DATA.FriendlyPerSavePointCreditHard)
        ld      (SavePointCreditFriendly), a

        ret

EndofLevelManagerCode: