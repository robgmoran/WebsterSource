;-------------------------------------------------------------------------------------
; RST $00 - Replacement ROM Routine
        di
        jp      Start
        nop
        nop
        nop
        nop

;-------------------------------------------------------------------------------------
; RST $08 - Replacement ROM Routine
        ret
        nop
        nop
        nop
        nop
        nop
        nop
        nop

;-------------------------------------------------------------------------------------
; RST $10 - Replacement ROM Routine
        ret
        nop
        nop
        nop
        nop
        nop
        nop
        nop

;-------------------------------------------------------------------------------------
; RST $18 - Replacement ROM Routine
        ret
        nop
        nop
        nop
        nop
        nop
        nop
        nop

;-------------------------------------------------------------------------------------
; RST $20 - Replacement ROM Routine
        ret
        nop
        nop
        nop
        nop
        nop
        nop
        nop

;-------------------------------------------------------------------------------------
; RST $28 - Replacement ROM Routine
        ret
        nop
        nop
        nop
        nop
        nop
        nop
        nop

;-------------------------------------------------------------------------------------
; RST $30 - Replacement ROM Routine
        ret
        nop
        nop
        nop
        nop
        nop
        nop
        nop

;-------------------------------------------------------------------------------------
; RST $38 - Replacement IM1 interrupt handler
IM1Handler:
        push    af, bc, de, hl, ix, iy
        
        ld      a, (GameStatus3)
        bit     3, a
        jp      nz, .Exit               ; Return if just starting game

        bit     2, a                    
        jp      z, .GamePlay            ; Jump if not on title screen

; Title Screen
; - NextDAW Music Player
        call    NextDAW_UpdateSong
        jp      .Exit

; Game
.GamePlay:        
; - Player Upgrade Sprite Animation
        bit     1, a                                            
        jp      z, .Exit                                ; Jump if upgrade flag not set

        ld      ix, PlayerUpgradeAtt
        ld      iy, PlayerUpgrade

        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .ContAnimation                       ; Jump if animation not complete

        res     2, (iy+S_SPRITE_TYPE.SpriteType1)       ; Reset deletion flag (indicates end of animation)
        res     7, (ix+S_SPRITE_ATTR.vpat)              ; Set upgrade sprite as invisible

        res     1, a                                    ; Reset upgrade flag
        ld      (GameStatus3), a

        ld      hl, (iy+S_SPRITE_TYPE.patternRange)
        inc     hl
        ld      a, (hl)
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Point back to first pattern for next activation

        jp      .Exit

.ContAnimation:
        ld      bc, PlayerUpgradePatternsStr
        call    UpdateSpritePattern

.Exit:
        pop     iy, ix, hl, de, bc, af

        ei
        reti
        nop
        nop
        nop
        nop
        nop
        nop

Start:
;-------------------------------------------------------------------------------------
; - Reset NextDAW run flag - Required to stop NextDAW as NextDAW MMU not loaded 
	ld	a, (GameStatus3)
	res	2, a
	ld	(GameStatus3), a

;-------------------------------------------------------------------------------------
; Setup Common Settings - Common - Run Once
;
        nextreg $07, %000000'11         ; Switch to 28Mhz

        nextreg $06, %0'0'1'1'1'0'01    ; Disable F8 key to change speed, but enable NMI

        call    SetCommonLayerSettings

; -- Disabled line, as it caused issue with accessing esxDOS from physical Next
        ;nextreg $0a, %00000'0'00        ; Switch mouse to low DPI


; - Leave machine at current speed
        ;nextreg $05, %0000'1'01         ; Change speed to 60Mhz
        ;nextreg $05, %0000'0'01         ; Change speed to 50Mhz
        
;-------------------------------------------------------------------------------------
; Setup Sprites - Common - Run Once
;
        call    SetupSpriteClipping
        call    AdjustSpriteClipping

;-------------------------------------------------------------------------------------
; Setup Audio
        call    SetupAYFXGame               ; Setup and initialise AYFX sound bank

;-------------------------------------------------------------------------------------
; Setup Game Status --> Title Screen
        ld      a, 0
        set     1, a        
        ld      (GameStatus2), a        ; Set title screen flag i.e. Display title screen

        ld      a, 0
        set     3, a
        ld      (GameStatus3), a        ; Set game just loaded flag

        ei
;-------------------------------------------------------------------------------------
; Program loop notes:
; - Ensure all routines that update the screen are run during vblank
; - Ensure all routines execute within a frame
Loop:
; Check whether title screen should be displayed
        ld      a, (GameStatus2)
        bit     1, a
        call    nz, TitleScreenSetup     ; Call routine if title screen should be displayed
        
        nextreg $07, %000000'11         ; Switch to 28Mhz; prevent changing on machine e.g. via NMI

; Play sound effects
        call AFX3Frame
        call AFX2Frame
        call AFX1Frame

; --- Run non-display dependent routines
        ;;ld a, 2
	;;out (#fe), a   ; set the border color

; Check whether FloodFill should be performed
        ld      a, (GameStatus)
        and     %00011000
        cp      0
        jp      nz, .IgnoreFF                           ; Jump if Start new level or Game Over flags set

        ld      a, (GameStatus2)
        and     %01100000
        cp      0
        jp      nz, .IgnoreFF                           ; Jump if player performing Spawnpoint (disappear or scroll)
        
        call    FillFlood                       

.IgnoreFF:
; Process opening/closing of screen
        ld      a, 0                                    ; Tilemap+sprite areas
        call    ProcessScreen

; - Check whether screen is opening/closing
        ld      a, (GameStatus)
        and     %00000011                               
        cp      0
        jp      nz, .BypassPlayerInput                  ; Jump if screen opening/closing

; Check whether Savepoint (scrolling)
        ld      a, (GameStatus2)
        bit     5, a
        jp      nz, .BypassPlayerInput                  ; Jump if Savepoint (scrolling)

; Check whether the player start/end/dead animation is playing
        ld      a, (GameStatus)
        bit     5, a
        jp      z, .GameInProgress                      ; Jump if player not playing animation

; - Otherwise play player spawn animation and don't allow player input
        and     %01011111
        ;and     %11011111
        cp      0
        jp      nz, .NoAudio    ; Jump if other flags are set i.e. Not starting level

        ld      a, (GameStatus2)
        bit     7, a
        jp      nz, .NoAudio                            ; Jump if player spawn sound has already been played

        set     7, a                                    ; Set player spawn sound bit
        ld      (GameStatus2), a

        ld      a, AyFXPlayerSpawnFinish
        call    AFX3Play

.NoAudio:
        ld      iy, PlayerSprite
        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range
        call    UpdateSpritePattern

; Reset movement flags
        ld      a, 0
        ld      (PlayerInput), a
        ld      (PlayerInputOriginal), a
        ld      (PlayerMoved), a
        ld      (iy+S_SPRITE_TYPE.Movement), a          ; Prevent change in sprite orientation
        ld      (iy+S_SPRITE_TYPE.Movement2), a         ; Prevent change in sprite orientation
        ld      (iy+S_SPRITE_TYPE.Movement3), a         ; Prevent change in sprite orientation
        
        jp      .BypassPlayerInput

.GameInProgress:
; Check whether level complete or gameover
        and     %01001000                       ; a = GameStatus
        cp      0
        jp      nz, .BypassPlayerInput          ; Jump if level complete or gameover

        call    ReadPlayerInput

; - Check whether the game is paused
        ld      a, (GameStatus)
        bit     2, a
        jp      z, .GameNotPaused               ; Jump if game not paused

        call    ProcessPause

; -- Wait for vertical sync to ensure pause counter runs correctly
        halt

        jp      Loop

.GameNotPaused:
        call    UpdateReticulePosition

.BypassPlayerInput:
; - Number of non-player sprites to check/animate; subtract player, reticule and HUD sprites
        ld      a, MaxSprites-2-MaxHUDSprites 
        call    ProcessOtherSprites

; - Freeze - Check/Bypass Routines
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      nz, .BypassRoutines             ; Jump if freeze enabled

        ld      a, 3                            ; Number of block animations to process
        call    BlockProcessAnimations

        call    AnimateHazardBlocks

.BypassRoutines:
        call    DoorProcess             ; Process doors

        call    CheckPlayerSpriteCollision
        call    CheckPlayerHazardCollision
        call    CheckPlayerFinishCollision
        call    CheckPlayerSavePointCollision
        call    CheckPlayerAntiFreezeCollision
        
; - Freeze - Check/Bypass Routines
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      nz, .BypassRoutines2    ; Jump if freeze enabled

; - Spawn Enemies
        call    EnemySpawner

.BypassRoutines2:
; - DoorLockdown
        call    CheckEndDoorLockdown

; - Freeze - Check/Bypass Routines
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      nz, .UpdateVideo        ; Jump if freeze enabled

; - Cycle TileMap Colours
        ld      a, (CycleTMColourDelayCounter)
        cp      0
        jp      nz, .UpdateCycleTMCounter

        ld      a, (DoorLockdownPalCycleOffset) ; Index of end colour
        ld      b, 1                            ; Number of colours to cycle-1
        ld      d, %1'011'0'0'0'1               ; Tilemap first palette
        call    CyclePalette

        ld      a, CycleTMColourDelay+1

.UpdateCycleTMCounter:
        dec     a
        ld      (CycleTMColourDelayCounter), a

.UpdateVideo:
; TODO - Raster
        ;ld a, 0
	;out (#fe), a   ; set the border color

; --- Run display dependent routines that need to be run inside vblank i.e. Scroll/Sprite attribute upload
        halt

; TODO - Raster
        ;ld a, 3
	;out (#fe), a   ; set the border color

; Check whether tilemap has scrolled, and scroll Layer2
; Note: Placed before CheckPlayerInput to ensure L2 scrolled when player returning to savepoint
        ld      a, (Scrolled)
        cp      0
        call    nz, Layer2Scroll        ; Scroll Layer2

; - Display Activities = Scrolls tilemap and update player position
        call    CheckPlayerInput		

; - Check/Spawn Savepoint
        call    CreateSavePoint

; - Display Activities = Upload Sprite Attributes
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        call    CheckEndOfLevel

        jp      Loop

        include "webster/TileMaps.asm"
        include "webster/Palettes.asm"
        include "webster/routines.asm"
        include "webster/dma.asm"
        include "webster/sprites.asm"
        include "webster/Layer2.asm"
        include "webster/HUD.asm"
        include "webster/mouse.asm"
        include "webster/audio.asm"
        include "webster/FillFlood.asm"
        include "webster/world.asm"
        include "webster/setup.asm"
EndOfMMU1:

        org     $4000
CodePart2:
; MMU2 ($4000) Mappings
; - On Title Screen - Memory bank hosting title routines maps to MMU2
; - During Gameplay - Memory bank hosting gameplay routines maps to MMU2 (default mapping when game started)

; *** Gameplay Routines
; - Following routines should not be called within Title routines
        include "webster/dma2.asm"
        include "webster/FillFlood2.asm"
        include "webster/maths.asm"
        include "webster/input.asm"
        include "webster/Triggers.asm"
        include "webster/levelmanager.asm"
        include "webster/circle.asm"
        include "webster/Scroll.asm"

CodePart2End:

; Code Part 3
; $8500 --> $a000 (data)
; *** Make sure code doesn't flow over into $a000 ***
        org     TileMapDefLocation+(TileMapDefBlocks*128)       
CodePart3:
        include "webster/collision.asm"
        include "webster/enemy.asm"

CodePart3End:
; *** Title Routines
; Place at end of code to ensure no other code is placed into the title memory banks at assembly time
        include "webster/title.asm"
        include "webster/titledata.asm"

EndOfCode:
