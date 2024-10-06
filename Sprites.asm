SpritesCode:
;-------------------------------------------------------------------------------------
; Setup Level Sprite Configuration
; Parameters:
; a = Memory block containing level tilemap data
;
SetupLevelSprites:
; Map source tilemap level data bank to slot 3
        nextreg $53, a                          

; Reset sprites and attributes - Need to run to ensure at least one non-zero attribute is defined
        ld      a, MaxSprites
        call    ResetSprites

; Setup/Spawn Player sprite
        call    SetupPlayerSprite

; Setup/Spawn Player Upgrade sprite; relative to player sprite
        call    SetupPlayerUpgradeSprite

; Setup/Spawn Reticule sprite
        call    SetupReticuleSprite

; Setup/Spawn Friendly Sprites
        call    SpawnFriendlySprites

; Setup/Spawn WayPoint Sprites
        call    SpawnWayPointSprites
        
; Setup/Spawn Key Sprites
        call    SpawnKeySprites

; Setup/Spawn Turret Sprites
        call    SpawnTurretSprites

; Setup/Spawn Locker Sprites
        call    SpawnLockerSprites

; Re-Map original bank to slot 3
        ld      a, 10                   ; Memory bank (8kb) containing TileMap definition data
        nextreg $53, a                          

        ret
        
;-------------------------------------------------------------------------------------
; Setup Sprite Clipping to use entire screen
; Parameters:
SetupSpriteClipping:
;-------------------------------------------------------------------------------------
; Configure Clip Window
; CLIP WINDOW Sprite Register
; The X coordinates are internally doubled (40x32 mode) or quadrupled (80x32 mode), and origin [0,0] is 32* pixels left and above the top-left ULA pixel
; i.e. Tilemap mode does use same coordinates as Sprites, reaching 32* pixels into "BORDER" on each side.
; It will extend from X1*2 to X2*2+1 horizontally and from Y1 to Y2 vertically.

; Reset to 0 as ProcessScreen routine used to configure values
        nextreg $1c, %0000'0010         ; Reset sprite clip write index
        nextreg $19, 0                  ; X1 Position
        nextreg $19, 0                ; X2 Position
        nextreg $19, 0                  ; Y1 Position
        nextreg $19, 0                ; Y2 Position

        ret

;-------------------------------------------------------------------------------------
; Setup Sprite Clipping to Assist Scrolling
; Parameters:
AdjustSpriteClipping:
;-------------------------------------------------------------------------------------
; Configure Clip Window
; CLIP WINDOW Sprite Register
; The X coordinates are internally doubled, and origin [0,0] is 32* pixels left and above the top-left ULA pixel
; i.e. Sprites use same coordinates as Tilemap mode, reaching 32* pixels into "BORDER" on each side.
; It will extend from X1*2 to X2*2+1 horizontally and from Y1 to Y2 vertically.

; Don't display screen as ProcessScreen routine used to configure values

        nextreg $1c, %0000'0010                 ; Reset tilemap clip write index
        ld      a, TileMapXOffsetLeft           ; Hide left column
        nextreg $19, a                          ; X1 Position
        ld      a, TileMapXOffsetRight          ; Hide right column
        nextreg $19, a                          ; X2 Position
        ld      a, ClearScreenY1Middle          ;TileMapYOffsetTop
        nextreg $19, a                          ; Y1 Position
        ld      a, ClearScreenY2Middle          ;TileMapYOffsetBottom        
        nextreg $19, a                          ; Y2 Position

        ret

;-------------------------------------------------------------------------------------
; Sprites - Upload Sprite Patterns
; Parameters:
; - d = Memory Bank1 containing  sprites 0 - 63
; - e = Memory Bank2 containing  sprites 64 - 127
; - hl = Address of first byte of sprite patterns
; - ixl = Number of sprite patterns to upload (max - 128 * 4-bit sprites or 64 * 8-bit sprites)
UploadSpritePatterns:
; *** Select starting sprite index/slot 0 ***
;  SPRITE STATUS/SLOT SELECT Register
        ld      bc,$303B
        xor     a
        out     (c),a       ; Select slot 0 for patterns/attributes

.SpritesPatterns1:
; *** Map SpritePixelData memory bank 1/2 to slot 3

; MEMORY MANAGEMENT SLOT 6 BANK Register
        ld      a, d
        cp      0       ; Check whether sprite memory bank1 has been specified     
        ret     z
        nextreg $53, a

.SpritePatterns2:
; *** Map SpritePixelData+1 memory bank 2/2 to slot 4
; MEMORY MANAGEMENT SLOT 7 BANK Register
        ld      a, e
        cp      0       ; Check whether sprite memory bank2 has been specified     
        jr      z, .Upload
        nextreg $54, a

.Upload:
; *** Upload sprite pattern data into sprite pattern memory from $C000 via otir opcode below - AUTO-INCREMENTS TO NEXT SPRITE PATTERN SLOT
; SPRITE PATTERN UPLOAD Register
; Note: While uploading sprite pixel data, after sending 256 bytes (1 x sprite pattern) worth of pixels the pattern
; upload slot will auto-increment to point to the next slot and after uploading final "slot 63" data the internal index will wrap around back to "slot 0",
; this will not affect the sprite attribute upload index
        ld      bc,$5B                  ; sprite pattern-upload I/O port, B=0 (inner loop counter), register c only used for import
; Loop for all required sprite patterns
        ld      a,ixl                     ; Number of patterns (outer loop counter), each pattern is 256 bytes long 
.UploadSpritePatternsLoop:
        ; upload 256 bytes of pattern data (otir increments HL and decrements B until zero)
        otir                            ; B=0 ahead, so otir will repeat 256x ("dec b" wraps 0 to 255)
        dec     a
        jr      nz, .UploadSpritePatternsLoop ; Loop around until all 64 sprite patterns have been uploaded

        ret

;-------------------------------------------------------------------------------------
; Sprites - Upload Sprite Patterns - Title Screens
; Note: Used to enable NextDAW to remain loaded into MMU4 ($8000)
; Parameters:
; - d = Memory Bank1 containing  sprites 0 - 63
; - e = Memory Bank2 containing  sprites 64 - 127
; - hl = Address of first byte of sprite patterns
; - ixl = Number of sprite patterns to upload (max - 128 * 4-bit sprites or 64 * 8-bit sprites)
UploadTitleSpritePatterns:
; Obtain memory bank number currently mapped into slots 6 & 7 and save allowing restoration
; - MMU6 - $c000-$dfff
	ld      a,$56                           ; Port to access - Memory Slot 6
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)

	push    af                              ; Save current bank number in slot 6

; - MMU7 - $e000 - $ffff
	ld      a,$57                           ; Port to access - Memory Slot 7
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)

	push    af                              ; Save current bank number in slot 7

; *** Select starting sprite index/slot 0 ***
;  SPRITE STATUS/SLOT SELECT Register
        ld      bc,$303B
        xor     a
        out     (c),a       ; Select slot 0 for patterns/attributes

.SpritesPatterns1:
; *** Map SpritePixelData memory bank 1/2 to slot 6

; MEMORY MANAGEMENT SLOT 6 BANK Register
        ld      a, d
        cp      0       ; Check whether sprite memory bank1 has been specified     
        jp      z, .Exit
        nextreg $56, a

.SpritePatterns2:
; *** Map SpritePixelData+1 memory bank 2/2 to slot 7
; MEMORY MANAGEMENT SLOT 7 BANK Register
        ld      a, e
        cp      0       ; Check whether sprite memory bank2 has been specified     
        jr      z, .Upload
        nextreg $57, a

.Upload:
; *** Upload sprite pattern data into sprite pattern memory from $C000 via otir opcode below - AUTO-INCREMENTS TO NEXT SPRITE PATTERN SLOT
; SPRITE PATTERN UPLOAD Register
; Note: While uploading sprite pixel data, after sending 256 bytes (1 x sprite pattern) worth of pixels the pattern
; upload slot will auto-increment to point to the next slot and after uploading final "slot 63" data the internal index will wrap around back to "slot 0",
; this will not affect the sprite attribute upload index
        ld      bc,$5B                  ; sprite pattern-upload I/O port, B=0 (inner loop counter), register c only used for import
; Loop for all required sprite patterns
        ld      a,ixl                     ; Number of patterns (outer loop counter), each pattern is 256 bytes long 
.UploadSpritePatternsLoop:
        ; upload 256 bytes of pattern data (otir increments HL and decrements B until zero)
        otir                            ; B=0 ahead, so otir will repeat 256x ("dec b" wraps 0 to 255)
        dec     a
        jr      nz, .UploadSpritePatternsLoop ; Loop around until all 64 sprite patterns have been uploaded

.Exit:
; Remap MMU6/MM7 slots
        pop     af
        nextreg $57, a

        pop     af
        nextreg $56, a

        ret

;-------------------------------------------------------------------------------------
; Sprites - Configure player sprite values
; Parameters:
SetupPlayerSprite:
; (1) Configure Sprite Data using Sprite Type values
; Player Sprite - Populate Player Sprite Data from Player Sprite Type
        ld      iy, PlayerSprite
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), 1+MaxHUDSprites
        ld      hl, PlayerSprAtt
        ld      (iy+S_SPRITE_TYPE.AttrOffset), hl

; Player Sprite - Copy remaining sprite type values
        ld      hl, PlayerSprType+S_SPRITE_TYPE.patternRange      ; Source starting with patternCurrent
        ld      de, PlayerSprite+S_SPRITE_TYPE.patternRange    ; Destination starting at patternCurrent
        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange ; Number of values
        ldir

; Calculate world coordinates from block x, y
        ld      hl, (PlayerStartXYBlock)
        call    ConvertBlockToWorldCoord

; (2) Configure Sprite Attributes
; Sprite Attributes - Populate Player Sprite Attributes
        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

; Configure x display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (CameraXWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (ix+S_SPRITE_TYPE.xPosition), hl

        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        or      h                                       ; MSB of the X Position

        ld      (iy+S_SPRITE_ATTR.mrx8), a  

; Configure y display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      de, (CameraYWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (ix+S_SPRITE_TYPE.yPosition), l         ; Update sprite position to accomodate tilemap y offset

        ld      (iy+S_SPRITE_ATTR.y), l                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.Movement2), a         ; Reset to zero to enable bullet spawning offset and orientation to run at start

; Configure player with data from level player data
        push    iy

; - Player Bullet Type
        ld      iy, (LevelDataPlayerData)

        ld      a, (iy+S_PLAYER_DATA.PlayerBulletNumber)
        ld      d, a
        ld      e, S_BULLETUPGRADE_DATA                         
        mul     d, e                                            ; Calculate bullet offset
        add     de, BulletUpgradeTable                          ; Point to bullet offset in table

; - Player Bullet Upgrade Levels
        ld      a, (iy+S_PLAYER_DATA.PlayerBulletUpgrade1)
        ld      (BulletUpgradeLevel1), a
        ld      a, (iy+S_PLAYER_DATA.PlayerBulletUpgrade2)
        ld      (BulletUpgradeLevel2), a
        ld      a, (iy+S_PLAYER_DATA.PlayerBulletUpgrade3)
        ld      (BulletUpgradeLevel3), a

; - Collectable Spawn Frequency
        ld      a, (iy+S_PLAYER_DATA.CollectableSpawnFreq)
        ld      (CollectableSpawnFrequency), a

        push    iy

        ld      iy, de
        ld      hl, (iy+S_BULLETUPGRADE_DATA.BulletUpgrade)
        ld      (PlayerSprite+S_SPRITE_TYPE.BulletType), hl     ; Set bullet to be fired

        add     de, S_BULLETUPGRADE_DATA                        ; Point to next bullet upgrade in table
        ld      iy, de

        ld      a, (iy+S_BULLETUPGRADE_DATA.FriendlyRequired)
        ld      (BulletUpgradeFriendlyNumber), a                ; Store number of friendly required for next bullet upgrade

        ld      (BulletUpgradeTableRef), iy                     ; Store next bullet upgrade table reference

        pop     iy

; - Player Energy
        ld      a, (iy+S_PLAYER_DATA.PlayerEnergy)
        ld      (ix+S_SPRITE_TYPE.Energy), a            ; Set starting energy
        ld      (MaxPlayerEnergy), a

; - Player Freeze Time
        ld      a, (iy+S_PLAYER_DATA.PlayerFreeze)
        ld      (PlayerFreezeTime), a

/* - Set in SetSavePointCredits routine
        ld      a, (iy+S_PLAYER_DATA.FriendlyPerSavePointCredit)
        ld      (SavePointCreditFriendly), a
*/
        ld      a, (iy+S_PLAYER_DATA.hazardDamage)
        ld      (HazardDamage), a

        ld      a, (iy+S_PLAYER_DATA.reverseHazardDamage)
        ld      (ReverseHazardDamage), a

; Check difficulty and override values
        ld      a, (GameStatus2)
        bit     4, a
        jp      z, .BypassHardValues                    ; Jump if not hard difficulty

; - Override with hard values
        ld      a, (iy+S_PLAYER_DATA.CollectableSpawnFreqHard)
        ld      (CollectableSpawnFrequency), a

/* - Set in SetSavePointCredits routine
        ld      a, (iy+S_PLAYER_DATA.FriendlyPerSavePointCreditHard)
        ld      (SavePointCreditFriendly), a
*/
        ld      a, (iy+S_PLAYER_DATA.hazardDamageHard)
        ld      (HazardDamage), a

        ld      a, (iy+S_PLAYER_DATA.reverseHazardDamageHard)
        ld      (ReverseHazardDamage), a

.BypassHardValues:

; - Update player animation definition delay based on energy
/*
        push    hl
        call    UpdatePlayerAnimationDelay
        pop     hl
*/

; - Player Bullet Type - Range within which player can fire
        ld      iy, hl
        ld      a, (iy+S_BULLET_DATA.range)
        ld      (ix+S_SPRITE_TYPE.RotRange), a

        pop     iy

; Configure remaining attributes
        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

        inc     hl                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        cp      64
        jp      c, .ContConfig                         ; Jump if pattern < 64

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

; -- Update based on sprite size
        call    CheckUpdate4BitSprite                   ; TODO - 4Bit

        ;;ld      a, 0
        ;;ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

; Setup orientation values
        ld      iy, PlayerSprite
        ld      ix, PlayerSprAtt
        ;call    UpdateBulletSpawningOrientation
        call    UpdateSpriteOrientation

        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        ld      (PlayerBlockOffset), bc                 ; Obtain block offset position for use with doors
        ld      (PlayerBlockXY), de                     ; Obtain block position for use with enemies


; Set player position/scale for player start animation
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.xPosition)
        add     hl, -8      
        ld      (PlayerSprite+S_SPRITE_TYPE.xPosition), hl

        ld      (ix+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, (ix+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        res     0, a                                    ; Reset 9th x bit
        or      h                                       ; MSB of the X Position
        ld      (ix+S_SPRITE_ATTR.mrx8), a  

        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)
        add     a, -8
        ld      (PlayerSprite+S_SPRITE_TYPE.yPosition), a
        ld      (ix+S_SPRITE_ATTR.y), a                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

; - Scale player sprite
        ld      a, (ix+S_SPRITE_ATTR.Attribute4)
        or      %000'01'01'0                            ; Scale x + y
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5

; Hide player sprite until screen is opened
        ld      a, (PlayerSprAtt+S_SPRITE_ATTR.vpat)
        res     7, a                                    ; Make sprite visible
        ld      (PlayerSprAtt+S_SPRITE_ATTR.vpat), a    ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ret

;-------------------------------------------------------------------------------------
; Player Upgrade Sprite - Spawn Bullet Upgrade Sprite
; Note: Spawn as invisible - Only show when player receives bullet upgrade
; Parameters:
SetupPlayerUpgradeSprite:
; - Spawn sprite
        ld      ix, BulletSprType
        ld      iy, PlayerUpgrade
        ld      a, 1+MaxHUDSprites+1
        ld      b, 1

        call    SpawnNewSprite

        push    iy
        ld      iy, ix
        pop     ix

        ld      bc, PlayerUpgradePatternsStr
        call    UpdateSpritePattern

        push    iy
        ld      iy, ix
        pop     ix

; - Configure relative attributes
        bit     6, (iy+S_SPRITE_ATTR.Attribute4)
        jp      z, .SetAsRelative                       ; Jump if N6 (bit 6) not set

        set     5, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 (bit 5)

.SetAsRelative:
	res	7, (iy+S_SPRITE_ATTR.Attribute4)	; Relative bit
	set	6, (iy+S_SPRITE_ATTR.Attribute4)	; Relative bit
	res	0, (iy+S_SPRITE_ATTR.Attribute4)	; Set PO = 0

        set     4, (iy+S_SPRITE_ATTR.Attribute4)        ; Set XX magnification
        set     2, (iy+S_SPRITE_ATTR.Attribute4)        ; Set YY magnification

        ld      (iy+S_SPRITE_ATTR.x), -22               ; Update X position relative to player anchor sprite
        ld      (iy+S_SPRITE_ATTR.y), -22               ; Update Y position relative to player anchor sprite

; - Set other values
        set     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Set visible on camera flag
        set     3, (ix+S_SPRITE_TYPE.SpriteType1)       ; Set explode flag
        res     7, (iy+S_SPRITE_ATTR.vpat)              ; Set sprite as invisible

	ret

;-------------------------------------------------------------------------------------
; Sprites - ReSpawn/Configure player sprite values
; Parameters:
ReSpawnPlayerSprite:
; Calculate world coordinates from block x, y
        ld      iy, PlayerSprite
        ld      hl, (PlayerStartXYBlock)
        call    ConvertBlockToWorldCoord

; Configure Sprite Attributes
; Sprite Attributes - Populate Player Sprite Attributes
        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

; Configure x display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (CameraXWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (ix+S_SPRITE_TYPE.xPosition), hl

        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        or      h                                       ; MSB of the X Position

        ld      (iy+S_SPRITE_ATTR.mrx8), a  

; Configure y display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      de, (CameraYWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (ix+S_SPRITE_TYPE.yPosition), l         ; Update sprite position to accomodate tilemap y offset

        ld      (iy+S_SPRITE_ATTR.y), l                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.Movement2), a         ; Reset to zero to enable bullet spawning offset and orientation to run at start

; Configure Player Energy with Save point energy
        ld      a, (SavePointSavedPlayerEnergy)
        ld      (ix+S_SPRITE_TYPE.Energy), a            ; Set starting energy

; Configure Player Freeze Time with Save point freeze time
        ld      a, (SavePointSavedPlayerFreeze)
        ld      (PlayerFreezeTime), a

; Configure remaining attributes
        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

        inc     hl                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        cp      64
        jp      c, .ContConfig                         ; Jump if pattern < 64

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

; -- Update based on sprite size
        call    CheckUpdate4BitSprite                   ; TODO - 4Bit

        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        ld      (PlayerBlockOffset), bc                 ; Obtain block offset position for use with doors
        ld      (PlayerBlockXY), de                     ; Obtain block position for use with enemies

; Set player position for player start animation
; Note: Sprite already scaled as part of Save point (disappear)
        ld      hl, (ix+S_SPRITE_TYPE.xPosition)
        add     hl, -8      
        ld      (ix+S_SPRITE_TYPE.xPosition), hl

        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        res     0, a                                    ; Reset 9th x bit
        or      h                                       ; MSB of the X Position
        ld      (iy+S_SPRITE_ATTR.mrx8), a  

        ld      a, (ix+S_SPRITE_TYPE.yPosition)
        add     a, -8
        ld      (ix+S_SPRITE_TYPE.yPosition), a
        ld      (iy+S_SPRITE_ATTR.y), a                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

; Reset FF Values
        ld      a, 0
        ld      (FFQueueContent), a
        ld      (FFNodesPerCallCounter), a
        ld      (FFBuilt), a

; Prevent player from taking damage immediately
        ld      a, RespawnDamageDelay
        ld      (RespawnDamageDelayCounter), a

; Update HUD - Energy & Freeze Time
        ld      a, (SavePointSavedPlayerEnergy)
        ld      b, HUDEnergyValueDigits
        ld      d, a
        ld      a, (HUDEnergyValueSpriteNum)
        ld      c, a
        ld      a, d
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites                      

/*
; TODO - Reticule
        ld      a, (SavePointSavedPlayerFreeze)
        ld      b, HUDFreezeValueDigits
        ld      d, a
        ld      a, (HUDFreezeValueSpriteNum)
        ld      c, a
        ld      a, d
        call    UpdateHUDValueSprites
*/
; Restore Reticule sprite pattern
        ld      iy, ReticuleSprite

        ld      hl, (SavedPointReticulePattern)
        ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

	ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for all states
        call    UpdateSpritePattern4BitStatus

; TODO - Reticule
; Update freeze reticule values
        ld      a, (PlayerFreezeTime)
        ld      b, ReticuleFreezeValueDigits
        ld      d, a
        ld      a, (ReticuleFreezeValueSpriteNum);(HUDFreezeValueSpriteNum)
        ld      c, a
        ld      a, d
        call    UpdateReticuleValueSprites              ; Update reticule values

; Remove Save point
; - Update screen TileMap block (not visible)
        ld      de, (SavePointSavedBlockOffset)

        ld      iy, (LevelTileMap)
        add     iy, de                                  ; Add block offset
; TOOD - Testing
        ld      a, (SavePointOldBlock)
        ld      (iy), a                                 ; Reset to old block tile

; - Update screen TileMap block (visible)
        ld      hl, (PlayerStartXYBlock)
        call    UpdateScreenTileMap

; - HUD Icon --> Disabled
        ld      iy, (HUDSavePointIconSprite)

        ;;ld      hl, HUDSavePointDisabledPatterns         
        ;;ld      (iy+S_SPRITE_TYPE.patternRange), hl     ; Change patternRange to ensure new palette is referenced

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl
        ld      bc, HUDSavePointDisabledPatterns
        call    UpdateSpritePattern

	;;ld	a, (iy+S_SPRITE_TYPE.patternCurrent)    ; No need to change pattern, as same pattern used for disabled/enabled
        ;;call    UpdateSpritePattern4BitStatus

; - Reset saved values
        ld      hl, 0
        ld      (SavePointSavedBlockOffset), hl
        ld      (SavePointSavedPlayerEnergy), hl        ; Reset energy and freeze values

        ld      a, (GameStatus)
        set     5, a                    ; Set play animation flag
        ld      (GameStatus), a

        ret

;-------------------------------------------------------------------------------------
; Sprites - Configure player reticule sprite values
; Parameters:
SetupReticuleSprite:
; (1) Configure Sprite Data using Sprite Type values
; Reticule Sprite - Populate Reticule Sprite Data from Reticule Sprite Type
        ld      iy, ReticuleSprite
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), 0
        ld      hl, ReticuleSprAtt
        ld      (iy+S_SPRITE_TYPE.AttrOffset), hl

; Reticule Sprite - Copy remaining sprite type values
        ld      hl, ReticuleSprType+S_SPRITE_TYPE.patternRange  ; Source starting with patternCurrent
        ld      de, ReticuleSprite+S_SPRITE_TYPE.patternRange  ; Destination starting at patternCurrent
        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange  ; Number of values
        ldir

; (2) Configure Sprite Attributes
; Sprite Attributes - Populate Reticule Sprite Attributes
; Note: Do not need to set x/y positions as these will be configured via offset to player
        ld      ix, ReticuleSprite
        ld      iy, ReticuleSprAtt

; Configure remaining attributes
; -- Set pattern animation delay
        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

; -- Set start pattern
        inc     hl                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (hl)

        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        cp      64
        jp      c, .ContConfig                          ; Jump if pattern < 64

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 4

        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 3 - %1'1'pppppp - visible sprite, 4Byte, sprite pattern

; -- Update based on sprite size
        call    CheckUpdate4BitSprite

        call    UpdateReticulePosition

        ret

;-------------------------------------------------------------------------------------
; Sprites - Configure new sprite rotation values - Turrets and Shooter
; Only required for sprites that rely on rotation e.g. Turrets
; Note: Not required for reticule
; Parameters:
; ix = Sprite storage memory address offset
SetupNewSpriteRotation:
; Configure rotation point
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.RotPointX), bc
        ld      bc, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.RotPointY), bc

; Configure rotation range based on bullet type assigned to turret/shooter
        ld      hl, (ix+S_SPRITE_TYPE.BulletType)
        ld      iy, hl

        ld      a, (iy+S_BULLET_DATA.range)
        cp      0
        jp      nz, .SetRange                           ; Jump if bullet range != 0

        ld      a, (PlayerSprite+S_SPRITE_TYPE.RotRange)
        add     EnemyShooterOffset                      ; Set enemy range and thereby bullet range to Player RotRange+Offset

.SetRange:
        ld      (ix+S_SPRITE_TYPE.RotRange), a

; - Do not need to set RotRadius, as this is set within the sprite definition

; Configure remaining attributes
        bit     5, (ix+S_SPRITE_TYPE.SpriteType2)
        ret     z                               ; Return if not turret

        call    UpdateSpriteRotationPosition    ; Check performed above, as routine caused off screen shooter spawn issues

        ret

;-------------------------------------------------------------------------------------
; Reset Sprites
; Parameters:
; a = Number of sprites to reset (max = 128 * 4-bit sprites or 64 * 8-bit sprites)
ResetSprites:
; Release Sprite Data slots
        push    af
        ld      ix, Sprites

        ld      b, a
.DisableSpriteLoop:
        ld      (ix+S_SPRITE_TYPE.active), 0    ; Clear active flag
        ld      (ix+S_SPRITE_TYPE.AttrOffset), 0
        
        ld      de, S_SPRITE_TYPE
        add     ix, de                           ; Point to next sprite

        djnz    .DisableSpriteLoop

; Disable sprite in sprite attribute table
        pop     af
        push    af

        ld      iy, SpriteAtt

        ld      b, a
.DisableAttributeLoop:
        ;ld      a, (iy+S_SPRITE_ATTR.vpat) 
        ld      a, 0                                    ; Hide sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        ld      de, S_SPRITE_ATTR
        add     iy, de                                  ; Point to next sprite

        djnz    .DisableAttributeLoop
        
; Upload sprite attributes
        pop     af

        call    UploadSpriteAttributesDMA

        ret

/* - Replaced with DMA version
;-------------------------------------------------------------------------------------
; Sprites - Upload Multiple Sprite Attributes
; Parameters:
; - a = Number of sprites to upload (max - 128 * 4-bit sprites or 64 * 8-bit sprites)
UploadSpriteAttributes:
        ld      d, a    ; Number of sprites
        ld      e, 5    ; Number of attributes within each sprite 
        mul     d, e    ; Total number of sprite attributes to upload
; Populate sprite attributes
        ld      bc, $303B
        xor     a
        out     (c),a           ; select slot 0 for sprite attributes

; First loop based on register e
        ld      b, e            ; Number of attributes to copy
        ld      hl,SpriteAtt    ; Location containing sprite attributes
        ld      c, $57          ; Sprite pattern-upload I/O port
        otir                    ; Out required number of sprite attributes
    
; Check/second loop based on register d
        ld      a, d
        cp      0
        ret     z               ; Return if no more than 255 attributes

        dec     a               ; Note: 0 will result in a loop of 256
        ld      b, a
        otir                    ; Out required number of sprite attributes
        
        ret
*/

;-------------------------------------------------------------------------------------
; Sprites - Upload Multiple Sprite Attributes via DMA
; Parameters:
; - a = Number of sprites to upload (max - 128 * 4-bit sprites or 64 * 8-bit sprites)
UploadSpriteAttributesDMA:
        ld      d, a                                    ; Number of sprites
        ld      e, 5                                    ; Number of attributes within each sprite 
        mul     d, e                                    ; Total number of sprite attributes to upload

; Populate sprite attributes
        ld      bc, $303B
        xor     a
        out     (c),a                                   ; select slot 0 for sprite attributes

        ld      (DMASpriteAttUploadLength), de          ; DMA copy length
        
        LD      hl, DMASpriteAttUpload                  ; HL = pointer to DMA program
        LD      b, DMASpriteAttUploadCopySize           ; B = size of the code
        LD      c, $6B                                  ; C = $6B (zxnDMA port)
        OTIR                                            ; upload DMA program

        ret

;-------------------------------------------------------------------------------------
; Sprites - Spawn New Sprites
; Parameters:
; ix = Sprite type
; iy = Sprite storage memory address offset
; a = Sprite attribute offset
; b = Max number of sprite type that can be spawned
; h = x block coordinate
; l = y block coordinate
; Return:
; a = 0 - Sprite not spawned, 1 - Sprite spawned
SpawnNewSprite:
        push    hl
; (1) Find spare sprite slot
        ld      c, a                            ; Sprite count to identify sprite attribute position; offset based on sprite type passed into routine
.FindAvailableSpriteSlot:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .FoundSpriteSlot
        inc     c                               ; Increment sprite count for next sprite number (used for attributes)
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Not found so point to next sprite slot
        djnz    .FindAvailableSpriteSlot

        pop     hl

        ld      a, 0                           ; Return: No spare sprite slot found

        ret                                     

; (2) Configure sprite values
.FoundSpriteSlot:
; Sprite - Populate Sprite Data from Sprite Type
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), c

; Sprite - Copy remaining sprite type values
        ld      a, S_SPRITE_TYPE.patternRange
        ld      hl, ix
        add     hl, a                                                   ; Source starting with patternCurrent
        ld      de, iy                                  
        add     de, a                                                   ; Destination starting at patternCurrent
        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange          ; Number of values
        
        ldir

        pop     hl                                                  ; Restore X, Y block coordinates

/* - No longer required
; Set sprite world coordinates
        bit     4, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .ConvertBlock                                        ; Jump if not bomb

; - Set bomb world coordinates from player sprite
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        ld      (iy+S_SPRITE_TYPE.XWorldCoordinate), hl
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        ld      (iy+S_SPRITE_TYPE.YWorldCoordinate), hl
        
        jp      .PopulateAttributes

; - Calculate non-bomb world coordinates from block x, y
.ConvertBlock:
*/
        call    ConvertBlockToWorldCoord

; Sprite Attributes - Populate Sprite Attributes
.PopulateAttributes:
        ld      ix, iy                                                  ; Source - Sprite data
        ld      d, S_SPRITE_ATTR
        ld      e, (ix+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                                    ; Calculate sprite attribute offset
        ld      iy, SpriteAtt
        add     iy, de                                                  ; Destination - Sprite Attributes

        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.AttrOffset), hl                       ; Store sprite attribute offset

; Initially set to display coordinates of 0, 0; updated later when sprite in camera boundary
; -- Set Coordinates
        ld      (iy+S_SPRITE_ATTR.x), 0                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      (iy+S_SPRITE_ATTR.y), 0                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        ld      a, %0000'0'0'0'0                        ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        ld      (iy+S_SPRITE_ATTR.mrx8), a              ; MSB of the X Position
        
; -- Set Start Pattern
        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

        inc     hl                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (hl)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        cp      64
        jp      c, .ContConfig                         ; Jump if pattern < 64

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
; -- Initially make sprite invisible; updated later when sprite in camera boundary
        res     7, a                                    ; Make sprite invisible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'1'000000 - Invisible sprite, 4Byte, sprite pattern

; -- Update based on sprite size
        call    CheckUpdate4BitSprite                   ; TODO - 4Bit

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)      ; Indicate sprite not visible

        ld      a, (GameStatus2)
        bit     1, a
        jp      nz, .FinaliseSprite                    ; Jump if spawning Title sprites

; Enemy/Friendly Sprites - Populate MoveToBlock; used for enemy wayfinding
        bit     6, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .EnemyFriendly                      ; Jump if enemy

        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .EnemyFriendly                      ; Jump if friendly

        jp      .FinaliseSprite

.EnemyFriendly:
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      
        ;push    bc                                      ; Save current block offset 

        ld      de, bc
        call    EnemySetBlockMapBit                     ; Set EnemyMovementBlock

        ;ld      a, (iy)                                 ; Get EnemyMovementBlockMap byte

        ;pop     bc                                      ; Restore current block offset
        ;ld      iy, FriendlyMovementBlockMap
        ;add     iy, bc
        ;ld      (iy), a                                 ; Set FriendlyMovementBlockMap

.FinaliseSprite:
; Check camera boundary
        call    CheckSpriteCameraBoundary               ; Check whether sprite should be made visible

        ld      a, 1                                    ; Return: Sprite spawned

        ret

;-------------------------------------------------------------------------------------
; Sprites - Spawn New Bullet Sprite
; Parameters:
; ix = Bullet type
; iy = Sprite storage memory address offset
; a = Sprite attribute offset
; b = Max bullets; Number of sprite entries to search through
; c = Bullet rotation
; hl = x world coordinate
; de = y world coordinate
; Return:
; a = 0 Bullet not spawned, 1 Bullet spawned
SpawnNewBulletSprite:
        push    bc, hl, de
; (1) Find spare sprite slot
        ld      c, a                            ; Sprite count to identify sprite attribute position; offset based on sprite type passed into routine (player sprite is 0)
.FindAvailableSpriteSlot:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .FoundSpriteSlot
        inc     c                               ; Increment sprite count for next sprite number (used for attributes)
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Not found so point to next sprite slot
        djnz    .FindAvailableSpriteSlot

        pop     de, hl, bc

        ld      a, 0                            ; Return - 0 = Bullet not spawned

        ret                                     ; No spare sprite slot found so return

; (2) Configure sprite values
.FoundSpriteSlot:
; Sprite - Populate Sprite Data from Sprite Type
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), c

; Sprite - 1. Copy sprite template data to new sprite via DMA
        push    ix                              ; Save bullet data pointer

        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange  ; Number of values
        ld      (DMASpriteDataUploadLength), bc                 ; DMA copy length

        ld      a, S_SPRITE_TYPE.patternRange
        ld      hl, (ix+S_BULLET_DATA.bulletSprite)             ; Map to sprite bullet template
        ;ld      hl, ix
        add     hl, a                                           ; Source starting with patternCurrent
        ld      (DMASpriteDataUploadPortA), hl

        ld      de, iy                                  
        add     de, a                                           ; Destination starting at patternCurrent
        ld      (DMASpriteDataUploadPortB), de

        LD      hl, DMASpriteDataUpload                         ; HL = pointer to DMA program
        LD      b, DMASpriteDataUploadCopySize                  ; B = size of the code
        LD      c, $6B                                          ; C = $6B (zxnDMA port)
        OTIR                                                    ; upload DMA program

        pop     ix                              ; Restore bullet data pointer

; Sprite - 2. Copy bullet data to new sprite
        ld      hl, 0
        ld      (iy+S_SPRITE_TYPE.patternRange), hl
        ld      hl, (ix+S_BULLET_DATA.patternStr)
        ld      (iy+S_SPRITE_TYPE.animationStr), hl
        ld      hl, (ix+S_BULLET_DATA.patternDiag)
        ld      (iy+S_SPRITE_TYPE.animationUp), hl
        ld      hl, (ix+S_BULLET_DATA.animationExp)
        ld      (iy+S_SPRITE_TYPE.animationOther), hl
        ld      a, (ix+S_BULLET_DATA.range)
        ld      (iy+S_SPRITE_TYPE.RotRange), a
        ld      a, (ix+S_BULLET_DATA.speed)
        ld      (iy+S_SPRITE_TYPE.Speed), a
        ld      a, (ix+S_BULLET_DATA.movementDelay)
        ld      (iy+S_SPRITE_TYPE.MovementDelay), a
        ld      (iy+S_SPRITE_TYPE.Counter), a
        ld      a, (ix+S_BULLET_DATA.Damage)
        ld      (iy+S_SPRITE_TYPE.Damage), a
        ld      a, (ix+S_BULLET_DATA.Delay)
        ld      (iy+S_SPRITE_TYPE.Delay), a
        ld      a, (ix+S_BULLET_DATA.Width)
        ld      (iy+S_SPRITE_TYPE.Width), a
        ld      a, (ix+S_BULLET_DATA.Height)
        ld      (iy+S_SPRITE_TYPE.Height), a
        ld      a, (ix+S_BULLET_DATA.BoundaryX)
        ld      (iy+S_SPRITE_TYPE.BoundaryX), a
        ld      a, (ix+S_BULLET_DATA.BoundaryY)
        ld      (iy+S_SPRITE_TYPE.BoundaryY), a
        ld      a, (ix+S_BULLET_DATA.BoundaryWidth)
        ld      (iy+S_SPRITE_TYPE.BoundaryWidth), a
        ld      a, (ix+S_BULLET_DATA.BoundaryHeight)
        ld      (iy+S_SPRITE_TYPE.BoundaryHeight), a

/*
; Check type of projectile
        bit     4, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NotBomb                                             ; Jump if bullet


; - Bomb - Update bomb range to match current bullet range
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.BulletType)             ; Current player bullet type
        ld      ix, hl

        ld      a, (ix+S_BULLET_DATA.range)
        ld      (iy+S_SPRITE_TYPE.RotRange), a

.NotBomb:
*/

; Sprite Attributes - Populate Sprite Attributes
        ld      ix, iy                                                  ; Source - Sprite data
        ld      d, S_SPRITE_ATTR
        ld      e, (ix+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                                    ; Calculate sprite attribute offset
        ld      iy, SpriteAtt
        add     iy, de                                                  ; Destination - Sprite Attributes

        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.AttrOffset), hl                       ; Store sprite attribute offset

        pop     de, hl, bc                                              ; Restore X, Y world coordinates, and direction

; Populate world coordinates
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), de

; Populate rotation values
        ld      (ix+S_SPRITE_TYPE.RotPointX), hl
        ld      (ix+S_SPRITE_TYPE.RotPointY), de

        ld      (ix+S_SPRITE_TYPE.RotRadius), 0         ; Start at centre

        ;ld      a, (ReticuleRotation)
        ld      (ix+S_SPRITE_TYPE.Rotation), c        

; Initially set to display coordinates of 0, 0; updated later when sprite in camera boundary
        ld      (iy+S_SPRITE_ATTR.x), 0                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      (iy+S_SPRITE_ATTR.y), 0                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - X.msb=0
        

; Set sprite pattern based on orientation (rotation)
        push    ix, iy
        ld      hl, ix
        ld      ix, iy
        ld      iy, hl
        call    UpdateBulletSpriteOrientation
        pop     iy, ix

        ;ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ;ld      a, (hl)
        ;ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

        ;inc     hl                                      ; Point to start pattern in sprite animation pattern range
        ;ld      a, (hl)
        ;ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

; Initially make sprite invisible; updated later when sprite in camera boundary
        ld      a, (ix+S_SPRITE_TYPE.patternCurrent)    ; Set animation first pattern

        cp      64
        jp      c, .ContConfig                         ; Jump if pattern < 63

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
        res     7, a                                    ; Make sprite invisible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'1'000000 - Invisible sprite, 4Byte, sprite pattern

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)      ; Indicate sprite not visible

; Update based on sprite size
        call    CheckUpdate4BitSprite

        ld      a, 1                                    ; Return - Bullet spawned

        ret

/* - No longer used - Replaced by spawning locker collectable
;-------------------------------------------------------------------------------------
; Sprites - Spawn New Collectable Sprite
; Parameters:
; ix = Sprite type to spawn
; iy = Sprite storage memory address offset
; a = Sprite attribute offset
; b = Max collectables; Number of sprite entries to search through
; hl = x world coordinate
; de = y world coordinate
SpawnNewCollectableSprite:
        push    bc, hl, de
; (1) Find spare sprite slot
        ld      c, a                            ; Sprite count to identify sprite attribute position; offset based on sprite type passed into routine (player sprite is 0)
.FindAvailableSpriteSlot:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .FoundSpriteSlot
        inc     c                               ; Increment sprite count for next sprite number (used for attributes)
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Not found so point to next sprite slot
        djnz    .FindAvailableSpriteSlot

        pop     de, hl, bc
        ret                                     ; No spare sprite slot found so return

; (2) Configure sprite values
.FoundSpriteSlot:
; Sprite - Populate Sprite Data from Sprite Type
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), c

; Sprite - 1. Copy sprite template data to new sprite via DMA

        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange  ; Number of values
        ld      (DMASpriteDataUploadLength), bc                 ; DMA copy length

        ld      a, S_SPRITE_TYPE.patternRange
        ;ld      hl, CollectableSprType                          ; Map to collectable sprite template
        ld      hl, ix                                          ; Map to collectable sprite template
        add     hl, a                                           ; Source starting with patternCurrent
        ld      (DMASpriteDataUploadPortA), hl

        ld      de, iy                                  
        add     de, a                                           ; Destination starting at patternCurrent
        ld      (DMASpriteDataUploadPortB), de

        LD      hl, DMASpriteDataUpload                         ; HL = pointer to DMA program
        LD      b, DMASpriteDataUploadCopySize                  ; B = size of the code
        LD      c, $6B                                          ; C = $6B (zxnDMA port)
        OTIR                                                    ; upload DMA program

; Sprite - 2. Update other collectable data on new sprite
        ld      a, LockerCollectableEnergy
        ld      (iy+S_SPRITE_TYPE.Energy), a

        ld      a, CollectableAlive
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a              ; Set countdown for deletion of sprite

; Sprite Attributes - Populate Sprite Attributes
        ld      ix, iy                                                  ; Source - Sprite data
        ld      d, S_SPRITE_ATTR
        ld      e, (ix+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                                    ; Calculate sprite attribute offset
        ld      iy, SpriteAtt
        add     iy, de                                                  ; Destination - Sprite Attributes

        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.AttrOffset), hl                       ; Store sprite attribute offset

        pop     de, hl, bc                                              ; Restore X, Y world coordinates, and direction

; Populate world coordinates
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), de

; Initially set to display coordinates of 0, 0; updated later when sprite in camera boundary
        ld      (iy+S_SPRITE_ATTR.x), 0                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      (iy+S_SPRITE_ATTR.y), 0                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - X.msb=0

; -- Set Start Pattern
        ld      hl, LockerCollectablePatterns
        ld      (ix+S_SPRITE_TYPE.patternRange), hl

        ld      a, (LockerCollectablePatterns+S_SPRITE_PATTERN.FirstPattern)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        cp      64
        jp      c, .ContConfig                         ; Jump if pattern < 64

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
; Initially make sprite invisible; updated later when sprite in camera boundary
        ;;ld      a, (ix+S_SPRITE_TYPE.patternCurrent)    ; Set animation first pattern

        res     7, a                                    ; Make sprite invisible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'1'000000 - Invisible sprite, 4Byte, sprite pattern

; -- Update based on sprite size
        call    CheckUpdate4BitSprite                   ; TODO - 4Bit

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)      ; Indicate sprite not visible

        ret
*/

;-------------------------------------------------------------------------------------
; Sprites - Spawn New Locker Collectable Sprite
; Parameters:
; ix = Sprite type to spawn
; iy = Sprite storage memory address offset
; a = Sprite attribute offset
; b = Max lockers; Number of sprite entries to search through
; hl = x world coordinate
; de = y world coordinate
SpawnNewLockerCollectableSprite:
        push    bc, hl, de
; (1) Find spare sprite slot
        ld      c, a                            ; Sprite count to identify sprite attribute position; offset based on sprite type passed into routine (player sprite is 0)
.FindAvailableSpriteSlot:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .FoundSpriteSlot
        inc     c                               ; Increment sprite count for next sprite number (used for attributes)
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Not found so point to next sprite slot
        djnz    .FindAvailableSpriteSlot

        pop     de, hl, bc
        ret                                     ; No spare sprite slot found so return

; (2) Configure sprite values
.FoundSpriteSlot:
; Sprite - Populate Sprite Data from Sprite Type
        ld      (iy+S_SPRITE_TYPE.active), 1
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), c

; Sprite - 1. Copy sprite template data to new sprite via DMA
        ld      bc, S_SPRITE_TYPE - S_SPRITE_TYPE.patternRange  ; Number of values
        ld      (DMASpriteDataUploadLength), bc                 ; DMA copy length

        ld      a, S_SPRITE_TYPE.patternRange
        ld      hl, ix                                          ; Map to collectable sprite template
        add     hl, a                                           ; Source starting with patternCurrent
        ld      (DMASpriteDataUploadPortA), hl

        ld      de, iy                                  
        add     de, a                                           ; Destination starting at patternCurrent
        ld      (DMASpriteDataUploadPortB), de

        LD      hl, DMASpriteDataUpload                         ; HL = pointer to DMA program
        LD      b, DMASpriteDataUploadCopySize                  ; B = size of the code
        LD      c, $6B                                          ; C = $6B (zxnDMA port)
        OTIR                                                    ; upload DMA program

; Sprite - 2. Update other collectable data on new sprite
        ld      a, LockerCollectableEnergy
        ld      (iy+S_SPRITE_TYPE.Energy), a

        ld      a, LockerCollectableFreeze
        ld      (iy+S_SPRITE_TYPE.EnergyReset), a

        ld      a, CollectableAlive
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a              ; Set countdown for deletion of sprite

; Sprite Attributes - Populate Sprite Attributes
        ld      ix, iy                                                  ; Source - Sprite data
        ld      d, S_SPRITE_ATTR
        ld      e, (ix+S_SPRITE_TYPE.SpriteNumber)
        mul     d, e                                                    ; Calculate sprite attribute offset
        ld      iy, SpriteAtt
        add     iy, de                                                  ; Destination - Sprite Attributes

        ld      hl, iy
        ld      (ix+S_SPRITE_TYPE.AttrOffset), hl                       ; Store sprite attribute offset

        pop     de, hl, bc                                              ; Restore X, Y world coordinates, and direction

; Populate world coordinates
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), de

; Initially set to display coordinates of 0, 0; updated later when sprite in camera boundary
        ld      (iy+S_SPRITE_ATTR.x), 0                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      (iy+S_SPRITE_ATTR.y), 0                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        ;;;res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - X.msb=0

        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        and     %1111'000'0                             ; Attribute byte 3 - Reset Mirror/Rotation, X.msb=0
        ld      (iy+S_SPRITE_ATTR.mrx8), a

; - Set animation delay
        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)                                 ; Obtain animation delay

        ld      (ix+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

; -- Check/Set Start Pattern based on player energy
        ld      a, (PlayerFreezeTime)
        cp      PlayerFreezeMax
        jp      z, .EnergyCollectable                   ; Jump if freeze time = Freeze max

        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        cp      CollectableEnergyThreshold+1
        jp      c, .EnergyCollectable                   ; Jump if player energy < CollectableEnergyThreshold

; --- Spawn Freeze Collectable
        res     1, (ix+S_SPRITE_TYPE.SpriteType4)

        ld      hl, LockerFreezeCollectablePatterns
        ld      (ix+S_SPRITE_TYPE.patternRange), hl    ; Otherwise set animation pattern to freeze pattern

        ld      a, LockerCollectableFreezeStartPattern
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    

        jp      .ContPatternCheck

.EnergyCollectable:
; --- Spawn Energy Collectable
        set     1, (ix+S_SPRITE_TYPE.SpriteType4)

        ld      hl, LockerEnergyCollectablePatterns
        ld      (ix+S_SPRITE_TYPE.patternRange), hl    ; Set animation pattern to energy pattern

        ld      a, LockerCollectableEnergyStartPattern
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    

.ContPatternCheck:
        cp      64
        jp      c, .ContConfig                         ; Jump if pattern < 64

        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.ContConfig:
; Initially make sprite invisible; updated later when sprite in camera boundary
        res     7, a                                    ; Make sprite invisible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'1'000000 - Invisible sprite, 4Byte, sprite pattern

; -- Update based on sprite size
        call    CheckUpdate4BitSprite                   ; TODO - 4Bit

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)      ; Indicate sprite not visible

        ret

;-------------------------------------------------------------------------------------
; Friendly Spawner - Spawn Friendly Sprites
; Parameters:
SpawnFriendlySprites:
	ld	a, 0
        ld      (FriendlyInLevel), a		; Reset friendly sprite count

        ld      a, (LevelDataFriendlyNumber)
        cp      0
        ret     z                               ; Return if no friendly to be spawned

        ld      b, a

        ld      ix, (LevelDataFriendlyData)
.SpawnFriendlyLoop:
        push    bc, ix

; Calculate block offsets        
        ld      bc, (ix+S_FRIENDLY_DATA.XWorldCoordinate)
        ld      hl, (ix+S_FRIENDLY_DATA.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ex      de, hl                          ; hl = Block coordinates

        ld      de, (ix+S_FRIENDLY_DATA.FriendlyType)
        ld      ix, de
        ld      iy, FriendlySpritesStart
        ld      a, FriendlyAttStart
        ld      b, MaxFriendly
        call    SpawnNewSprite

        ld      iy, ix                          ; iy = Sprite data

        pop     ix                              ; ix = friendly structure

        cp      0
        jp      z, .NextFriendly                ; Jump if sprite cannot be spawned

        ld      a, (ix+S_FRIENDLY_DATA.Energy)
        ld      (iy+S_SPRITE_TYPE.Energy), a            ; Update spawned friendly - Energy
        ld      (iy+S_SPRITE_TYPE.EnergyReset), a       ; Used to reset friendly energy

; Set delay counter used to prevent friendly taking damage for short period
        ld      (iy+S_SPRITE_TYPE.DelayCounter), FriendlyDamageDelay

        ld      a, (ix+S_FRIENDLY_DATA.EnableAtStart)
        cp      1
        jp      nz, .Continue                   ; Jump if friendly not enabled at start

        set     6, (iy+S_SPRITE_TYPE.SpriteType3)       ; Set friendly to follow player at start

.Continue:
        ld      a, (FriendlyInLevel)
        inc     a
        ld      (FriendlyInLevel), a

.NextFriendly:
        ld      bc, S_FRIENDLY_DATA
        add     ix, bc

        pop     bc

        djnz    .SpawnFriendlyLoop

        ret

;-------------------------------------------------------------------------------------
; WayPoint Enemy Spawner - Spawn Enemy WayPoint Sprites
; Parameters:
SpawnWayPointSprites:
        ld      a, (LevelDataWayPointNumber)
        cp      0
        ret     z                               ; Return if no waypoints sprites to be spawned

        ld      hl, (LevelDataWayPointData)     ; Source - WayPoint data
        call    CopyWayPointData

        ld      ix, LevelWayPointData

        ld      b, a

.WayPointLoop:
        push    bc

        ld      a, (ix+S_WAYPOINT_DATA.SpawnEnemy)
        cp      0
        jp      z, .NextWayPoint                                ; Jump if waypoint not a spawn point

; - Spawn waypoint enemy
        ld      bc, (ix+S_WAYPOINT_DATA.XWorldCoordinate)
        ld      hl, (ix+S_WAYPOINT_DATA.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      hl, de                                          ; Return value - x, y block offset

        ld      de, (ix+S_WAYPOINT_DATA.EnemyType)
        ld      iy, EnemySpritesStart
        ld      a, EnemyAttStart
        ld      b, MaxEnemy

        push    ix
        ld      ix, de
        call    SpawnNewSprite
        ld      iy, ix        
        pop     ix

        cp      0
        jp      z, .NextWayPoint                                ; Jump if sprite cannot be spawned

        ld      a, (ix+S_WAYPOINT_DATA.EnemyDamage)
        ld      (iy+S_SPRITE_TYPE.Damage), a                    ; Update waypoint enemy - Damage

        bit     0, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .PostShooter                                 ; Jump if enemy not shooter

        ld      hl, (ix+S_WAYPOINT_DATA.BulletType)
        ld      (iy+S_SPRITE_TYPE.BulletType), hl               ; Update waypoint enemy - Bullet Type

        push    ix, iy
        ld      ix, iy
        call    SetupNewSpriteRotation;nz, SetupNewSpriteRotation                      ; Call if shooter sprite
        pop     iy, ix

; Override bullet range; always place after SetupNewSpriteRotation
        ld      a, (ix+S_WAYPOINT_DATA.RotRange)
        ld      (iy+S_SPRITE_TYPE.RotRange), a

.PostShooter:
; - Configure enemy with target waypoint data
        ld      hl, (ix+S_WAYPOINT_DATA.CurrentWayPoint)
        ld      (iy+S_SPRITE_TYPE.EnemySpawnPoint), hl          ; Assign current waypoint
        ld      hl, (ix+S_WAYPOINT_DATA.NextWayPoint)
        ld      (iy+S_SPRITE_TYPE.EnemyWayPoint), hl            ; Assign target waypoint
        push    ix

        ld      ix, hl
        ld      hl, (ix+S_WAYPOINT_DATA.XWorldCoordinate)       
        ld      (iy+S_SPRITE_TYPE.MoveTargetX), hl              ; Assign target x world coordinate
        ld      hl, (ix+S_WAYPOINT_DATA.YWorldCoordinate)
        ld      (iy+S_SPRITE_TYPE.MoveTargetY), hl              ; Assign target y world coordinate

; - Configure enemy with initial movement direction
        ld      bc, (iy+S_SPRITE_TYPE.YWorldCoordinate)         ; Enemy y coordinate
        or      a
        sbc     hl, bc                                          ; hl = target waypoint, bc = enemy
        jp      z, .CheckHorizontal                             ; Jump if enemy and target waypoint at same y coordinate

        jp      c, .MoveUp                                      ; Jump if target waypoint is above enemy

        ld      (iy+S_SPRITE_TYPE.Movement), %00000100          ; Otherwise move enemy down
        jp      .Continue

.MoveUp:
        ld      (iy+S_SPRITE_TYPE.Movement), %00001000          ; Move enemy up
        jp      .Continue

.CheckHorizontal:
        ld      bc, (iy+S_SPRITE_TYPE.XWorldCoordinate)         ; Enemy y coordinate
        ld      hl, (ix+S_WAYPOINT_DATA.XWorldCoordinate)       ; Target waypoint coordinate

        or      a
        sbc     hl, bc                                          ; hl = target waypoint, bc = enemy
        jp      c, .MoveLeft                                    ; Jump if target waypoint is left of enemy

        ld      (iy+S_SPRITE_TYPE.Movement), %00000001          ; Otherwise move enemy right
        jp      .Continue

.MoveLeft:
        ld      (iy+S_SPRITE_TYPE.Movement), %00000010          ; Move enemy left

.Continue:
        pop     ix

.NextWayPoint:
        pop     bc

        ld      de, S_WAYPOINT_DATA
        add     ix, de

        dec     b
        ld      a, b
        cp      0
        jp      nz, .WayPointLoop

        ret

;-------------------------------------------------------------------------------------
; Key Spawner - Spawn Key Sprites
; Parameters:
SpawnKeySprites:
        ld      a, (LevelDataKeyNumber)
        cp      0
        ret     z                               ; Return if no keys to be spawned

        ld      b, a

        ld      ix, (LevelDataKeyData)
.SpawnKeyLoop:
        push    bc, ix

; Calculate block offsets        
        ld      bc, (ix+S_KEY_DATA.XWorldCoordinate)
        ld      hl, (ix+S_KEY_DATA.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ex      de, hl                          ; hl = Block coordinates

        ld      de, (ix+S_KEY_DATA.KeyType)
        ld      ix, de
        ld      iy, KeySpritesStart
        ld      a, KeyAttStart
        ld      b, MaxKeys
        call    SpawnNewSprite

.NextKey:
        pop     ix

        ld      bc, S_KEY_DATA
        add     ix, bc

        pop     bc

        djnz    .SpawnKeyLoop

        ret

;-------------------------------------------------------------------------------------
; Locker Spawner - Spawn Locker Sprites
; Parameters:
SpawnLockerSprites:
        ld      a, (LevelDataLockerNumber)
        cp      0
        ret     z                               ; Return if no lockers to be spawned

        ld      b, a

        ld      ix, (LevelDataLockerData)
.SpawnLockerLoop:
        push    bc, ix

; Calculate block offsets        
        ld      bc, (ix+S_LOCKER_DATA.XWorldCoordinate)
        ld      hl, (ix+S_LOCKER_DATA.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ex      de, hl                          ; hl = Block coordinates

        ld      ix, LockerSprType
        ld      iy, LockerSpritesStart
        ld      a, LockerAttStart
        ld      b, MaxLockers
        call    SpawnNewSprite

        ld      iy, ix                          ; ix = sprite data 
        
        pop     ix                              ; ix = Locker data

        cp      0
        jp      z, .NextLocker                  ; Jump if sprite cannot be spawned

; - Set animation delay - Ensures bullets change pattern correctly
        ld      hl, (iy+S_SPRITE_TYPE.patternRange)
        ld      a, (hl)                                 ; Obtain animation delay

        ld      (iy+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay

; - Set locker sprite with energy value
        ld      a, (ix+S_LOCKER_DATA.EnergyUpgrade)
        ld      (iy+S_SPRITE_TYPE.Energy), a

; - Set locker sprite with freeze value
        ld      a, (ix+S_LOCKER_DATA.FreezeUpgrade)
        ld      (iy+S_SPRITE_TYPE.EnergyReset), a

; - Check/Set locker sprite with default locker status (energy or freeze)       
        ld      a, (ix+S_LOCKER_DATA.DefaultFreeze)
        cp      0
        jp      z, .NextLocker                          ; Jump if locker is an energy locker

; -- Set locker to freeze locker
        res     1, (iy+S_SPRITE_TYPE.SpriteType4)

        ld      hl, LockerFreezePatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), hl      ; Set animation range

        ld      a, LockerFreezeStartPattern
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        call    UpdateSpritePattern4BitStatus           ; TODO - 4Bit

.UpdateSpriteAttributes:
; - Sprite Attributes - Update Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      iy, bc                                  ; Destination - Sprite Attributes

        res     7, a                                    ; Make sprite invisible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'1'pppppp - Invisible sprite, 4Byte, sprite pattern

.NextLocker:
        ld      bc, S_LOCKER_DATA
        add     ix, bc

        pop     bc

        djnz    .SpawnLockerLoop

        ret

;-------------------------------------------------------------------------------------
; Turret Spawner - Spawn Turret Sprites
; Parameters:
SpawnTurretSprites:
        ld      a, (LevelDataTurretNumber)
        cp      0
        ret     z                               ; Return if no turrets to spawn

        ld      b, a

        ld      ix, (LevelDataTurretData)

.SpawnTurretLoop:
        push    bc, ix

; Calculate block offsets        
        ld      bc, (ix+S_TURRET_DATA.XWorldCoordinate)
        ld      hl, (ix+S_TURRET_DATA.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ex      de, hl                          ; hl = Block coordinates

        ld      de, TurretSprType
        ld      ix, de
        ld      iy, EnemySpritesStart
        ld      a, EnemyAttStart
        ld      b, MaxEnemy
        call    SpawnNewSprite

        ld      iy, ix                          ; iy = SpriteData

        pop     ix                              ; ix = TurretData

        cp      0
        jp      z, .NextTurret                  ; Jump if sprite cannot be spawned

; Update turret sprite
; - Update Turret Type (----UDLR)
        bit     3, (ix+S_TURRET_DATA.TurretType)
        jp      z, .CheckDown                           ; Jump if not Turret-Up

        set     4, (iy+S_SPRITE_TYPE.SpriteType2)       ; Otherwise set TurretUp flag
        jp      .Cont

.CheckDown:
        bit     2, (ix+S_TURRET_DATA.TurretType)
        jp      z, .CheckLeft                           ; Jump if not Turret-Down

        set     3, (iy+S_SPRITE_TYPE.SpriteType2)       ; Otherwise set TurretDown flag
        jp      .Cont

.CheckLeft:
        bit     1, (ix+S_TURRET_DATA.TurretType)
        jp      z, .CheckRight                            ; Jump if not Turret-Left

        set     2, (iy+S_SPRITE_TYPE.SpriteType2)       ; Otherwise set TurretLeft flag
        jp      .Cont

.CheckRight:
        bit     0, (ix+S_TURRET_DATA.TurretType)
        jp      z, .RotatingTurret                      ; Jump if not Turret-Right i.e. Rotating turret

        set     1, (iy+S_SPRITE_TYPE.SpriteType2)       ; Otherwise set TurretRight flag
        jp      .Cont

; - Configure rotating turret values i.e. Non-directional turrets
.RotatingTurret:
        set     6, (iy+S_SPRITE_TYPE.SpriteType4)       ; Set Turret-Rotating flag

        ld      a, (ix+S_TURRET_DATA.AntiClockwise)
        cp      0
        jp      z, .Cont

        set     5, (iy+S_SPRITE_TYPE.SpriteType4)       ; Set turret anti-clockwise flag
                                                        ; Note: Default = clockwise

; - Set remaining Turret values
.Cont:
        ld      hl, (ix+S_TURRET_DATA.BulletType)
        ld      (iy+S_SPRITE_TYPE.BulletType), hl

        ld      a, (ix+S_TURRET_DATA.RotationReset)
        ld      (iy+S_SPRITE_TYPE.Rotation), a
        ld      (iy+S_SPRITE_TYPE.RotationReset), a

        ld      a, (ix+S_TURRET_DATA.Energy)
        ld      (iy+S_SPRITE_TYPE.Energy), a
        ld      (iy+S_SPRITE_TYPE.EnergyReset), a

        ld      a, (ix+S_TURRET_DATA.DisableTimeOut)
        ld      (iy+S_SPRITE_TYPE.EnemyDisableTimeOut), a

        ld      a, (ix+S_TURRET_DATA.DoubleSpeed)
        ld      (iy+S_SPRITE_TYPE.Speed), a

; Check difficulty and override values
        ld      a, (GameStatus2)
        bit     4, a
        jp      z, .BypassHardValues                    ; Jump if not hard difficulty

; - Override with hard values
        ld      a, (ix+S_TURRET_DATA.DisableTimeOutHard)
        ld      (iy+S_SPRITE_TYPE.EnemyDisableTimeOut), a

        ld      a, (ix+S_TURRET_DATA.EnergyHard)
        ld      (iy+S_SPRITE_TYPE.Energy), a
        ld      (iy+S_SPRITE_TYPE.EnergyReset), a

.BypassHardValues:
        push    ix, iy

        ld      ix, iy                          ; ix = SpriteData
        call    SetupNewSpriteRotation

        pop     iy, ix                              ; ix = TurretData

; Override bullet range; always place after SetupNewSpriteRotation
        ld      a, (ix+S_TURRET_DATA.RotRange)
        ld      (iy+S_SPRITE_TYPE.RotRange), a

.NextTurret:
        ld      bc, S_TURRET_DATA
        add     ix, bc

        pop     bc

        dec     b
        ld      a, b
        cp      0
        jp      nz, .SpawnTurretLoop
        ;djnz    .SpawnTurretLoop

        ret

;-------------------------------------------------------------------------------------
; HUD Spawner - Spawn HUD Sprites
; Parameters:
SpawnHUDSprites:
; TODO - Reticule
; --- Reticule - Freeze Value; need to spawn first after reticule
        call    SpawnReticuleValueSprites

; --- Key Icon and Value
; - Spawn key icon sprite
        ld      ix, Key1SprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        ld      hl, HUDKeyIconXY                       ; XXYY Block Offset
        call    SpawnNewSprite

; - Set sprite pattern and make sprite visible        
        ld      a, (ix+S_SPRITE_TYPE.patternCurrent)
        call    DisplayHUDSprite

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        inc     a                                      ; Point to next sprite number
        ld      (HUDKeyValueSpriteNum), a              ; Store sprite value for first key sprite value

; - Spawn key value sprites
        ld      a, (PlayerType1Keys)
        ld      hl, HUDKeyValueXY
        ld      b, HUDKeyValueDigits
        ld      c, %00000001
        ld      de, $0000                               ; Spawn integer and not string
        call    SpawnHUDValueSprites

; --- Save point Icon and Value
; - Spawn Save point icon sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        ld      hl, HUDSavePointIconXY                       ; XXYY Block Offset
        call    SpawnNewSprite

; - Change sprite pattern and make sprite visible        
        ;res     7, (iy+S_SPRITE_ATTR.Attribute4)        ; Configure 8Bit support
        ;res     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Configure 8Bit support

        set     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Enable sprite visable, required to allow change of pattern

        ld      hl, HUDSavePointDisabledPatterns        ; Set disabled pattern as default
        ld      (ix+S_SPRITE_TYPE.patternRange), hl
        ld      a, (HUDSavePointDisabledPatterns+S_SPRITE_PATTERN.FirstPattern)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a

        ld      hl, ix
        ld      (HUDSavePointIconSprite), hl             ; Store sprite value for Save point icon sprite value

        push    iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy

        call    DisplayHUDSprite

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        inc     a                                       ; Point to next sprite number
        ld      (HUDSavePointValueSpriteNum), a            ; Store sprite value for first friendly sprite value

; - Spawn Save point value sprites
        ld      a, (SavePointCredits)
        ld      hl, HUDSavePointValueXY
        ld      b, HUDSavePointValueDigits
        ld      c, %00000001
        ld      de, $0000                               ; Spawn integer and not string
        call    SpawnHUDValueSprites

; --- Energy Icon and Value
; - Spawn energy icon sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        ld      hl, HUDEnergyIconXY                     ; XXYY Block Offset
        call    SpawnNewSprite

; - Change sprite pattern and make sprite visible        
        ld      a, LockerEnergyStartPattern;LockerCollectableEnergyPattern
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a

        push    iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy

        call    DisplayHUDSprite

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        inc     a                                       ; Point to next sprite number
        ld      (HUDEnergyValueSpriteNum), a            ; Store sprite value for first energy sprite value

; - Spawn energy value sprites
        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        ld      hl, HUDEnergyValueXY
        ld      b, HUDEnergyValueDigits
        ld      c, %00000001
        ld      de, $0000                               ; Spawn integer and not string
        call    SpawnHUDValueSprites

; --- HiScore Value
        ld      a, (HUDEnergyValueSpriteNum)
        add     HUDEnergyValueDigits                    ; Point to next sprite number
        ld      (HUDHiScoreValueSpriteNum), a             ; Store sprite value for first score sprite value

; - Spawn Hiscore value sprites
        ld      hl, HUDHiScoreValueXY
        ld      b, HUDHiScoreValueDigits
        ld      c, %00000100
        ld      de, HiScore                              ; Spawn string and not integer
        call    SpawnHUDValueSprites

; --- Score Value
        ld      a, (HUDHiScoreValueSpriteNum)
        add     HUDHiScoreValueDigits                     ; Point to next sprite number
        ld      (HUDScoreValueSpriteNum), a           ; Store sprite value for first score sprite value

; - Spawn score value sprites
        ld      hl, HUDScoreValueXY
        ld      b, HUDScoreValueDigits
        ld      c, %00000010
        ld      de, Score                               ; Spawn string and not integer
        call    SpawnHUDValueSprites

/* - No longer needed - Placed on reticule
; --- Freeze Icon, Value + Background
; - Spawn freeze icon sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        ld      hl, HUDFreezeIconXY                     ; XXYY Block Offset
        call    SpawnNewSprite

; - Change sprite pattern and make sprite visible        
        ld      a,  LockerFreezeStartPattern;LockerCollectableFreezePattern
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a

        push    iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy

        call    DisplayHUDSprite

        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        inc     a                                       ; Point to next sprite number
        ld      (HUDFreezeValueSpriteNum), a            ; Store sprite value for first freeze sprite value

; Convert value into string
        ld      a, (PlayerFreezeTime)                        ; Value
        ld      hl, HUDFreezeValueXY
        ld      b, HUDFreezeValueDigits
        call    SpawnHUDValueSprites

; - Spawn energy background Sprite-1
        ld      hl, HUDFreezeValueXY
        call    SpawnHUDBackgroundSprite

; - Spawn energy background Sprite-2
        ld      hl, HUDFreezeValueXY+$0100
        call    SpawnHUDBackgroundSprite

*/


/* - No longer needed
; - Spawn Save point background Sprite-1
        ld      hl, HUDSavePointValueXY
        call    SpawnHUDBackgroundSprite

; - Spawn Save point background Sprite-2
        ld      hl, HUDSavePointValueXY+$0100
        call    SpawnHUDBackgroundSprite

*/
        ld      a, (ix+S_SPRITE_TYPE.SpriteNumber)
        inc     a                                       ; Point to next sprite number

        ld      (PauseValueSpriteNum), a                ; Store sprite value for pause sprite

; --- Pause sprite
; - Spawn pause sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        ld      hl, PauseIconXY                         ; XXYY Block Offset
        call    SpawnNewSprite

; - Change sprite pattern and make sprite invisible        
        ld      hl, PausePatterns
        ld      (ix+S_SPRITE_TYPE.patternRange), hl
        ld      a, (PausePatterns+S_SPRITE_PATTERN.FirstPattern)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a

        set     7, (ix+S_SPRITE_TYPE.SpriteType1)       ; Set visible flag as camera routine will not be run against pause sprite

        push    iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy

        call    DisplayHUDSprite

        ld      a, (iy+S_SPRITE_ATTR.vpat)              ; Attribute byte 4 - %1'1'000000 - Visible sprite, 4Byte, sprite pattern
        res     7, a                                    ; Make sprite invisible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - Invisible sprite, 4Byte, sprite pattern

; - Change sprite scale
        ld      a, (iy+S_SPRITE_ATTR.Attribute4)
        or      %000'10'10'0                            ; Scale x + y
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0


        ret

;-------------------------------------------------------------------------------------
; HUD Value Spawner - Spawn HUD Value Sprites
; Note: Called by SpawnHUDSprites and is used to spawn HUD value sprites e.g. Freeze, Friendly...
; Parameters:
; a = Value (integer) to spawn
; b = Number of digits in value
; c = Size/Y Position 
; - Bit 0 = Not Set=Magnify x only, Set=Magnify x & y
; - Bit 1 = Not Set=Do not adjust y position, Set=Move 8 pixels higher
; - Bit 2 = Not Set=Use default colour, Set=Change to pal offset 0
; hl = Position XY for first digit
; de = Address containing value (string) to spawn ($0000 = Spawn value in register a instead)
; Return:
SpawnHUDValueSprites:
        push    af, hl                  ; Save values

        ld      a, c
        ld      (BackupByte), a         ; Save magnify value

; Check for integer or string to convert/spawn
        or      a
        ld      hl, $0000
        sbc     hl, de
        jp      z, .ConvertInteger      ; Jump if integer to convert

; - Convert string to sprite string
        pop     hl, af                  ; Restore values

        push    bc
        call    ConvertStringToSpriteString
        pop     bc

        jp    .ConvertStringDigits  

; - Convert integer to sprite string
.ConvertInteger:
        pop     hl, af                  ; Restore values

        ld      de, SpriteString

        push    hl, bc
        call    ConvertIntToString
        pop     bc, hl

; Loop through string digits
; Note: String digits reference sprite pattern numbers
.ConvertStringDigits:
        ld      de, SpriteString
.SpawnSpriteValue:
        push    bc, hl, de                              ; Save digit count, position and string reference

; 1. Spawn Sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        call    SpawnNewSprite

; 2. Set sprite pattern and make sprite visible
        pop     de                                      ; Restore string reference
        ld      a, (de)                                 ; Obtain string digit value

        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern
        
        ld      bc, HUDNumberDigitPatterns              ; Assign number digits pattern
        ld      (ix+S_SPRITE_TYPE.patternRange), bc     ; Assign pattern with digits 

        push    ix, iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy, ix

        ld      a, (ix+S_SPRITE_TYPE.patternCurrent)    ; Get animation first pattern
        call    DisplayHUDSprite

; 3. Magnify sprites X/Y x 2
        ld      a, (BackupByte)                         ; Restore magnify value
        bit     0, a
        jp      nz, .MagnifyBoth                        ; Jump if no magnify

	set	3, (iy+S_SPRITE_ATTR.Attribute4)	; Set YY = 0
        jp      .FinishMagnify 

.MagnifyBoth:
	set	3, (iy+S_SPRITE_ATTR.Attribute4)	; Set YY = 0
	set	1, (iy+S_SPRITE_ATTR.Attribute4)	; Set XX = 0

.FinishMagnify:
; - Adjust y position up 7 pixels
        bit     1, a
        jp      z, .BypassYUpdate                       ; Jump if do not need to adjust

        ld      a, (iy+S_SPRITE_ATTR.y)
        sub     7
        ld      (iy+S_SPRITE_ATTR.y), a                 ; Move sprite up 7 pixels

.BypassYUpdate:
        ld      a, (BackupByte)                         ; Restore magnify value
        bit     2, a
        jp      z, .BypassPalUpdate                     ; Jump if no palette update

        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        and     %00001111
        ld      (iy+S_SPRITE_ATTR.mrx8), a              ; Update to palette offset 0

.BypassPalUpdate:
        inc     de                                      ; Point to next string digit

        pop     hl                                      ; Restore position
        inc     h                                       ; Point to next x position

        pop     bc                                      ; Restore digit counter
        djnz    .SpawnSpriteValue

        ret

; TODO - Reticule
;-------------------------------------------------------------------------------------
; HUD Reticule Value Spawner - Spawn HUD Reticule Value Sprites (2 x digits only)
; Note: Used for freeze counter; routine should ALWAYS be run before SpawnHUDSprites routine, as value sprites are relative to reticule sprite and need to be defined as the next numbered sprites
; Parameters:
; Return:
SpawnReticuleValueSprites:
; Record sprite number for left-digit of freeze value
        ld      a, 1                                    ; Always spawned after reticule due to reticule being anchor
        ld      (ReticuleFreezeValueSpriteNum), a
        
; Convert value into string
        ld      a, (PlayerFreezeTime)                   ; Value
	ld	b, ReticuleFreezeValueDigits            ; 2 x digits only

        ld      de, SpriteString	
        call    ConvertIntToString
        ld      de, SpriteString

	push	de
; ---Left digit
; - Spawn Sprite
	ld	hl, 0					; Position for XY; not relevant as positon will be relative to reticule anchor sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        call    SpawnNewSprite

; - Set sprite pattern to use small font
        pop     de                                      ; Restore string reference
        ld      a, (de)                                 ; Obtain string digit value
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        ld      bc, HUDNumberDigitPatterns             ; Assign number digits pattern
        ld      (ix+S_SPRITE_TYPE.patternRange), bc     ; Assign pattern with digits 

        push    ix, iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy, ix

; - Set as Relative sprite to Reticule Anchor sprite
; --  Check/Update N6 - Relative sprites used different bit
        bit     6, (iy+S_SPRITE_ATTR.Attribute4)
        jp      z, .SetLeftAsRelative                   ; Jump if N6 (bit 6) not set

        set     5, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 (bit 5)

.SetLeftAsRelative:
	res	7, (iy+S_SPRITE_ATTR.Attribute4)	; Set H = 0
	set	6, (iy+S_SPRITE_ATTR.Attribute4)	; Set N6 = 1
	res	0, (iy+S_SPRITE_ATTR.Attribute4)	; Set PO = 0

; - Display and re-position sprite
        call    DisplayHUDSprite

        ld      (iy+S_SPRITE_ATTR.x), ReticuleFreezeValueX1Offset  ; Update X position relative to reticule anchor sprite
        ld      (iy+S_SPRITE_ATTR.y), ReticuleFreezeValueYOffset  ; Update Y position relative to reticule anchor sprite

        inc     de                                      ; Point to next string digit
	push	de

; ---Right digit
; - Spawn Sprite
	ld	hl, 0					; Position for XY; not relevant as positon will be relative to reticule anchor sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        call    SpawnNewSprite

; - Set sprite pattern to use small font
        pop     de                                      ; Restore string reference
        ld      a, (de)                                 ; Obtain string digit value
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern
        
        ld      bc, HUDNumberDigitPatterns             ; Assign number digits pattern
        ld      (ix+S_SPRITE_TYPE.patternRange), bc     ; Assign pattern with digits

        push    ix, iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy, ix

; - Set as Relative sprite to Reticule Anchor sprite
; -- Check/Update N6 - Relative sprites used different bit
        bit     6, (iy+S_SPRITE_ATTR.Attribute4)
        jp      z, .SetRightAsRelative                  ; Jump if N6 (bit 6) not set

        set     5, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 (bit 5)

.SetRightAsRelative:
	res	7, (iy+S_SPRITE_ATTR.Attribute4)	; Set H = 0
	set	6, (iy+S_SPRITE_ATTR.Attribute4)	; Set N6 = 1
	res	0, (iy+S_SPRITE_ATTR.Attribute4)	; Set PO = 0

; - Display and re-position sprite
        call    DisplayHUDSprite

        ld      (iy+S_SPRITE_ATTR.x), ReticuleFreezeValueX2Offset ; Update X position relative to reticule anchor sprite
        ld      (iy+S_SPRITE_ATTR.y), ReticuleFreezeValueYOffset  ; Update Y position relative to reticule anchor sprite

	ret

;-------------------------------------------------------------------------------------
; Check/Update Sprite 4Bit Attributes
; Parameters:
; ix = Sprite Data
; iy = Sprite Attribute Data
; Return:
CheckUpdate4BitSprite:  ; TODO - 4Bit
; -- Check Sprite Bit size
        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        add     hl, S_SPRITE_PATTERN.BitPatOffset       ; Point to bit/pat bytes

        bit     7, (hl) 
        jp      z, .Sprite8Bit                          ; Jump if 8Bit sprites

; ---- 4Bit Sprite
        set     7, (iy+S_SPRITE_ATTR.Attribute4)        ; Set H = Sprite Pattern 4Bit
        
        ld      a, (hl)
        res     7, a                                    ; Clear 4bit bit
        swapnib                                         ; Swap nibbles in a
        ld      b, a

        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        and     %0000'1111                              ; Reset palette offset        
        add     b                                       ; Add palette offset
        ld      (iy+S_SPRITE_ATTR.mrx8), a              ; Set palette offset

        ret

; ---- 8Bit Sprite
.Sprite8Bit:
        ld      a, %0'0'0'00'00'0
        ld      (iy+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 4 - %0'0'0'00'00'0

        ret

;-------------------------------------------------------------------------------------
; Update Sprite Pattern 4Bit Status Values
; Parameters:
; iy = Sprite Type Table Entry
; a = Sprite Pattern
; Return:
; a = Updated Sprite Pattern
UpdateSpritePattern4BitStatus:
; Check whether new Sprite reference is 4Bit or 8Bit
        ld      hl, (iy+S_SPRITE_TYPE.patternRange)	; Get pattern range
	add	hl, S_SPRITE_PATTERN.BitPatOffset

	bit	7, (hl)
	ret	z					; Return if 8Bit

	push	ix

; Check pattern value
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, bc

	set     7, (ix+S_SPRITE_ATTR.Attribute4)        ; Otherwise configure H=1 - Set as 4Bit

        cp      64
        jp      c, .PatternLessThan64                   ; Jump if pattern < 64
        
; -- Pattern > 63
        set     6, (ix+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit
        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

	jp	.Finish

; -- Pattern < 64 
.PatternLessThan64:
        res     6, (ix+S_SPRITE_ATTR.Attribute4)        ; Reset N6 = 7th pattern bit

.Finish:
        push    af

; Update Palette Offset
        ld      a, (hl)
        res     7, a                                    ; Clear 4bit bit
        swapnib                                         ; Swap nibbles in a
        ld      b, a

        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        and     %0000'1111                              ; Reset palette offset        
        add     b                                       ; Add palette offset
        ld      (ix+S_SPRITE_ATTR.mrx8), a              ; Set palette offset

	pop	af, ix

	ret

/* 23/11/22 - Removed as no longer used
;-------------------------------------------------------------------------------------
; Update Sprite Pattern 4Bit Palette
; Parameters:
; iy = Sprite Attribute Data
; a = Palette Offset
UpdateSpritePattern4BitPaletteOffset:
        swapnib                                         ; Swap nibbles in a
        ld      b, a

        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        and     %0000'1111                              ; Reset palette offset        
        add     b                                       ; Add palette offset
        ld      (iy+S_SPRITE_ATTR.mrx8), a              ; Set palette offset

	ret
*/

;-------------------------------------------------------------------------------------
; Toggle Pause Sprite Display
; Parameters:
; a = Sprite number of pause
; Return:
TogglePauseSprite:        
        push    ix, iy

; Obtain address of pause sprite
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     de 
        ld      ix, Sprites
        add     ix, de                                  ; Point to sprite data for left value sprite

        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      iy, hl                                  ; Point to sprite attribute data for value sprite

; - Toggle sprite visibility
        ld      a, (iy+S_SPRITE_ATTR.vpat)              ; Attribute byte 4
        xor     %10000000                               ; Toggle visible bit
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4

        pop     iy, ix

        ret

;-------------------------------------------------------------------------------------
; Update HUD Value Sprites
; Updates sprites patterns only; updated sprites displayed within game loop 
; Parameters:
; a = Value (integer) to spawn
; b = Number of digits in value
; c = Sprite number of first left-most value
; de = Address containing value (string) to spawn ($0000 = Spawn value in register a instead)
; Return:
UpdateHUDValueSprites:        
        push    ix, iy

        push    af, bc                     ; Save valuew

; Check for integer or string to convert/spawn
        or      a
        ld      hl, $0000
        sbc     hl, de
        jp      z, .ConvertInteger      ; Jump if integer to convert

; - Convert string to sprite string
        pop     bc, af                  ; Restore values

        push    bc
        call    ConvertStringToSpriteString
        pop     bc

        jp    .ConvertStringDigits  

; Convert value into string
.ConvertInteger:
        pop     bc, af                     ; Restore value

        ld      de, SpriteString

        push    bc
        call    ConvertIntToString
        pop     bc

.ConvertStringDigits:
; Obtain address of left value sprite data
        ld      a, c
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     de 
        ld      ix, Sprites
        add     ix, de                                  ; Point to sprite data for left value sprite

; Loop through string digits
        ld      de, SpriteString

.UpdateSpriteValue:
; - Set sprite pattern and make sprite visible
        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      iy, hl                                  ; Point to sprite attribute data for value sprite

        ld      a, (de)                                 ; Obtain string digit value
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation next pattern

        cp      64
        jp      c, .PatternLessThan64                   ; Jump if pattern < 64
        
; -- Pattern > 63
        set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit
        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

	jp	.Finish

; -- Pattern < 64 
.PatternLessThan64:
        res     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Reset N6 = 7th pattern bit

.Finish:        
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - Visible sprite, 4Byte, sprite pattern

        inc     de                                      ; Point to next string digit

        push    de

        ld      de, S_SPRITE_TYPE
        add     ix, de                                  ; Point to next value sprite

        pop     de

        djnz    .UpdateSpriteValue

        pop     iy, ix

        ret

/* - 10/07/23 - No longer used
;-------------------------------------------------------------------------------------
; HUD Background Spawner - Spawn HUD Background Sprites
; Note: Called by SpawnHUDSprites and is used to spawn HUD background sprites
; Parameters:
; hl = Position XY for first digit
; Return:
SpawnHUDBackgroundSprite:
; - Spawn background sprite
        ld      ix, LockerCollectableSprType
        ld      iy, HUDSpritesStart
        ld      a, 1
        ld      b, MaxHUDSprites
        call    SpawnNewSprite

; - Set sprite pattern and make sprite visible
        ld      bc, HUDBackgroundPatterns               ; Assign number digits pattern
        ld      (ix+S_SPRITE_TYPE.patternRange), bc     ; Assign pattern with digits 

        inc     bc                                      ; Point to start pattern
        ld      a, (bc)
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation first pattern

        push    ix, iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy, ix

        ld      a, (ix+S_SPRITE_TYPE.patternCurrent)    ; Get animation first pattern
        call    DisplayHUDSprite

        ret
*/

; TODO - Reticule
;-------------------------------------------------------------------------------------
; Update Reticule Value Sprites
; Updates sprites patterns only; updated sprites displayed within game loop 
; Parameters:
; a = New value
; b = Number of digits in value
; c = Sprite number of first left-most value
; Return:
UpdateReticuleValueSprites:        
        push    ix, iy

; Convert value into string
        ld      de, SpriteString

        push    bc
        call    ConvertIntToString
        pop     bc

; Obtain address of left value sprite data
        ld      a, c
        ld      d, a
        ld      e, S_SPRITE_TYPE
        mul     de 
        ld      ix, Sprites
        add     ix, de                                  ; Point to sprite data for left value sprite

; Loop through string digits
        ld      de, SpriteString

.UpdateSpriteValue:
; - Set sprite pattern and make sprite visible
        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      iy, hl                                  ; Point to sprite attribute data for value sprite

        ld      a, (de)                                 ; Obtain string digit value
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a    ; Set animation next pattern

        cp      64
        jp      c, .PatternLessThan64                   ; Jump if pattern < 64
        
; -- Pattern > 63
        set     5, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 (bit 5)

        ;;set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit
        sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

	jp	.Finish

; -- Pattern < 64 
.PatternLessThan64:
        res     5, (iy+S_SPRITE_ATTR.Attribute4)        ; Reset N6 = 7th pattern bit

.Finish:        
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - Visible sprite, 4Byte, sprite pattern

; - Set as Relative sprite to Reticule Anchor sprite
	res	7, (iy+S_SPRITE_ATTR.Attribute4)	; Set H = 0
	set	6, (iy+S_SPRITE_ATTR.Attribute4)	; Set N6 = 1
	res	0, (iy+S_SPRITE_ATTR.Attribute4)	; Set PO = 0

        inc     de                                      ; Point to next string digit

        push    de

        ld      de, S_SPRITE_TYPE
        add     ix, de                                  ; Point to next value sprite

        pop     de

        djnz    .UpdateSpriteValue

        pop     iy, ix

        ret

;-------------------------------------------------------------------------------------
; Sprites - Update Sprite Position Based on Rotation
; Parameters:
; ix = Sprite storage memory address offset
UpdateSpriteRotationPosition:
; Obtain World Coordinates of rotation point
        ld      bc,(ix+S_SPRITE_TYPE.RotPointY)
        ld      de, (ix+S_SPRITE_TYPE.RotPointX)

; Obtain/Store Radius to rotation point
        ld      hl, Radius
        ld      a, (ix+S_SPRITE_TYPE.RotRadius)
        ld      (hl), a

; Obtain Rotation value around rotation point
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        call    ObtainPosOnCircle

        ld      (BackupWord1), bc       ; Save xWorldCoordinate
        ld      (BackupWord2), de       ; Save yWorldCoordinate

; Check whether new turret position is valid i.e. Not wall block
; - Sprite Top-Left - Check for block directly behind
        ld      hl, de

        call    ConvertWorldToBlockOffset

        or      a
        ld      hl, (LevelTileMap)
        adc     hl, bc                  ; Add offset to tilemap

        ld      a, (hl)                 ; Get block type value
        ld      d, a
        ld      a, BlockWallsEnd-TurretNumberOfBlocks ;-1       ; Ensure turret blocks aren't included
        cp      d
        jp      c, .TopLeftNotAWall                             ; Jump if block type is not a wall BLOCK i.e. Value is > BlockWalls

        ld      a, (TurretPreviousRotation)
        ld      (ix+S_SPRITE_TYPE.Rotation), a                  ; Otherwise reset rotation to last good value

        ret

.TopLeftNotAWall:
; - Sprite Bottom-Right - Check for block directly behind
        ld      bc, (BackupWord1)       ; Restore xWorldCoordinate
        add     bc,  15                 ; Point to right sprite row
        ld      hl, (BackupWord2)       ; Restore yWorldCoordinate
        add     hl,  15                 ; Point to bottom sprite column

        call    ConvertWorldToBlockOffset

        or      a
        ld      hl, (LevelTileMap)
        adc     hl, bc                  ; Add offset to tilemap

        ld      a, (hl)                 ; Get block type value

        ld      d, a
        ld      a, BlockWallsEnd-TurretNumberOfBlocks ;-1       ; Ensure turret blocks aren't included
        cp      d
        jp      c, .BottomRightNotAWall                         ; Jump if block type is not a wall BLOCK i.e. Value is > BlockWalls

        ld      a, (TurretPreviousRotation)
        ld      (ix+S_SPRITE_TYPE.Rotation), a                  ; Otherwise reset rotation to last good value

        ret

.BottomRightNotAWall:
; - Otherwise continue moving turret
        ld      bc, (BackupWord1)       ; Restore xWorldCoordinate
        ld      de, (BackupWord2)       ; Restore yWorldCoordinate

; Update sprite values/attributes
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc        
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), de

        push    de                                      ; Save y world coordinate

        ld      de, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      iy, de                                  ; Destination - Sprite Attributes

        ld      hl, bc                                  ; Obtain x world coordinate
        ld      de, (CameraXWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).

        ld      a, h
        cp      1
        jp      z, .RightSetmrx8                        ; Jump if MSB need to be set

        res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

        jp      .SetY

.RightSetmrx8
        set     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

.SetY:
        pop     hl                                      ; Restore y world coordinate

        ld      de, (CameraYWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (iy+S_SPRITE_ATTR.y), l                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        
; Allow turret to fire
        ld      a, (TurretInRange)
        cp      0
        ret     z                                       ; Return if turret not allowed to fire

        push    ix
        call    EnemyFireBullet
        pop     ix

        ret

;-------------------------------------------------------------------------------------
; Display Sprite - Sprite in camera boundary
; Parameters:
; ix = Sprite storage memory address offset
DisplaySprite:
; Sprite Attributes - Populate Sprite Attributes
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)
        ld      iy, bc                                  ; Destination - Sprite Attributes

; Configure x display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (CameraXWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (ix+S_SPRITE_TYPE.xPosition), hl

        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).

        ld      a, h
        cp      1
        jp      z, .RightSetmrx8                        ; Jump if MSB need to be set

        res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

        jp      .SetY

.RightSetmrx8
        set     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

.SetY:
; Configure y display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      de, (CameraYWorldCoordinate)
        call    ConvertWorldToDisplayCoord

        ld      (ix+S_SPRITE_TYPE.yPosition), l

        ld      (iy+S_SPRITE_ATTR.y), l                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        
; Make sprite visible
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        set     7, a                                    ; Make sprite visible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - visible sprite, 4Byte, sprite pattern

        set     5, (ix+S_SPRITE_TYPE.SpriteType1)      ; Indicate sprite now visible

        ret

;-------------------------------------------------------------------------------------
; Display HUD Sprite
; Parameters:
; ix = Sprite storage memory address offset
; iy = Sprite attribute memory address offset
; a = Sprite PatternCurrent value
DisplayHUDSprite:
; Make sprite visible
        set     7, a                                    ; Make sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - Visible sprite, 4Byte, sprite pattern

.SpriteVisible:
        set     7, a                                    ; Make sprite visible

; Set sprite screen position
; - Configure x display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.xPosition), hl

        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).

        ld      a, h
        cp      1
        jp      z, .RightSetmrx8                        ; Jump if MSB need to be set

        res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

        jp      .SetY

.RightSetmrx8
        set     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

.SetY:
; - Configure y display coordinate
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.yPosition), l

        ld      (iy+S_SPRITE_ATTR.y), l                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

        ret

;-------------------------------------------------------------------------------------
; Hide Sprite - Sprite no longer in camera boundary
; Parameters:
; ix = Sprite storage memory address offset
HideSprite:
; Sprite Attributes - Populate Sprite Attributes
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      iy, bc                                  ; Destination - Sprite Attributes

; Set to display coordinates of 0, 0; updated later when sprite in camera boundary
        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.x), a                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - X.msb=0

        ld      a, 0
        ld      (iy+S_SPRITE_ATTR.y), a                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        
; Make sprite invisible; updated later when sprite in camera boundary
        ld      a, (iy+S_SPRITE_ATTR.vpat) 
        res     7, a                                    ; Make sprite invisible
        ld      (iy+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %1'1'000000 - visible sprite, 4Byte, sprite pattern

        res     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Indicate sprite now invisible

        ret

;-------------------------------------------------------------------------------------
; Update Sprite Pattern
; Parameters:
; ix = Sprite Attribute Table Entry
; iy = Sprite Type Table Entry
; bc = Required PatternReference
UpdateSpritePattern:                
; Check whether we are changing the pattern reference
        xor     a
        ld      hl, (iy+S_SPRITE_TYPE.patternRange)
        sbc     hl, bc
        jr      z, .SamePatternReference                ; Jump if pattern same as current pattern 

        ld      (iy+S_SPRITE_TYPE.patternRange), bc     ; Otherwise change pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    ; Set animation delay
        inc     bc                                      ; Point to start pattern in sprite animation pattern range
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    

        call    UpdateSpritePattern4BitStatus

        jp      .UpdateSpriteAttributes

; Update pattern within existing animation pattern reference
.SamePatternReference
        ld      a, (iy+S_SPRITE_TYPE.animationDelay)
        cp      0                                       
        jr      z, .CheckPatternRange                   ; Jump if ready to change pattern

        dec     a                                       ; Otherwise decrement delay
        ld      (iy+S_SPRITE_TYPE.animationDelay), a    
        
        ret

.CheckPatternRange:
; Reset animation delay
        ld      a, (bc)
        ld      (iy+S_SPRITE_TYPE.animationDelay), a

        inc     bc                                      
        inc     bc                                      ; Point to end pattern in sprite animation pattern range
        
        ld      a, (bc)
        cp      (iy+S_SPRITE_TYPE.patternCurrent)
        jr      z, .ResetPattern                        ; Jump if current pattern matches end pattern

; Check sprite type - 4Bit or 8Bit
; 04/02/24 - Removed 8bit check as all sprites are 4bit and it caused issues with relative sprites
        bit     7, (ix+S_SPRITE_ATTR.Attribute4)
        jp      z, .RelativeSprite                      ; Jump if relative sprite
        ;;jp      z, .Sprite8Bit                          ; Jump if sprite 8Bit

; -- 4Bit Sprite
        ld      a, (iy+S_SPRITE_TYPE.patternCurrent)
        cp      64
        jp      c, .SetPatternAbove64                   ; Jump if pattern < 64

; ---- Set pattern below 64
        sub     64
        inc     a                                       
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Point to next pattern

        res     6, (ix+S_SPRITE_ATTR.Attribute4)        ; Reset pattern bit N6

        jp      .UpdateSpriteAttributes

        ;;set     6, (iy+S_SPRITE_ATTR.Attribute4)        ; Otherwise set N6 = 7th pattern bit

        ;;sub     64                                      ; Subtract 64 to enable setting of 6 pattern bits

.SetPatternAbove64:
        add     64
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Point to next pattern

        set     6, (ix+S_SPRITE_ATTR.Attribute4)        ; Set pattern bit N6

        jp      .UpdateSpriteAttributes

; -- 4Bit Relative Sprite
.RelativeSprite:
        ld      a, (iy+S_SPRITE_TYPE.patternCurrent)
        cp      64
        jp      c, .RelSetPatternAbove64                   ; Jump if pattern < 64

; ---- Set pattern below 64
        sub     64
        inc     a                                       
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Point to next pattern

        res     5, (ix+S_SPRITE_ATTR.Attribute4)        ; Reset pattern bit N6

        jp      .UpdateSpriteAttributes

.RelSetPatternAbove64:
        add     64
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Point to next pattern

        set     5, (ix+S_SPRITE_ATTR.Attribute4)        ; Set pattern bit N6

        jp      .UpdateSpriteAttributes

; 04/02/24 - Removed 8bit check as all sprites are 4bit and it caused issues with relative sprites
; -- 8Bit Sprite
/*
.Sprite8Bit:
        inc     (iy+S_SPRITE_TYPE.patternCurrent)       ; Otherwise point to next pattern

        ld      a, (iy+S_SPRITE_TYPE.patternCurrent)

        jp      .UpdateSpriteAttributes
*/


; Pattern matches end pattern
.ResetPattern
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .PlayerSprite                       ; Jump if player sprite

        res     6, (iy+S_SPRITE_TYPE.SpriteType2)       ; Reset spawn animation (if previously set); used for non-player sprites

; Check whether sprite is exploding
        bit     3, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .ContReset                           ; Jump if not exploding

; Sprite Exploding
        set     2, (iy+S_SPRITE_TYPE.SpriteType1)       ; Mark sprite for deletion
        ret

.PlayerSprite:
; Check whether player start/end/dead animation is being played
        ld      a, (GameStatus)
        bit     5, a
        jp      z, .ContReset                           ; Jump if  player start/end/dead animation is not being played

        ld      a, (GameStatus2)
        bit     6, a
        jp      nz, .SavePointDisappear                 ; Jump if Save point (disappear) animation complete

        ld      a, (GameStatus)

; Check whether player has completed level
        bit     4, a
        jp      nz, .LevelCompleteOrDead                ; Jump if level complete

; Check whether player is dead
        bit     3, a
        jp      z, .LevelNotComplete                    ; Jump if player not dead

.LevelCompleteOrDead:
; - Level complete or player dead - Close screen + Hide player
        res     5, a
        ld      (GameStatus), a                         ; Reset Game Start/end/dead animation flag

        ld      a, (PlayerSprAtt+S_SPRITE_ATTR.vpat)    ; Attribute byte 4
        res     7, a                                    ; Make sprite invisible
        ld      (PlayerSprAtt+S_SPRITE_ATTR.vpat), a    ; Attribute byte 4

        ret

.LevelNotComplete:
; - Player start animation complete - Update position, reset scale and change sprite pattern back to player
        res     5, a
        ld      (GameStatus), a                         ; Reset Game Start/end animation flag

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.xPosition)
        add     hl, 8      
        ld      (PlayerSprite+S_SPRITE_TYPE.xPosition), hl

        ld      (ix+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).
        ld      a, (ix+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - +0 palette offset, no mirror/rotation, X.msb=0
        res     0, a                                    ; Reset 9th x bit
        or      h                                       ; MSB of the X Position
        ld      (ix+S_SPRITE_ATTR.mrx8), a  

        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)
        add     a, 8
        ld      (PlayerSprite+S_SPRITE_TYPE.yPosition), a
        ld      (ix+S_SPRITE_ATTR.y), a                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).

        ld      a, (PlayerSprAtt+S_SPRITE_ATTR.Attribute4)
        xor     %000'01'01'0                                    ; Reset scale x + y
        ld      (PlayerSprAtt+S_SPRITE_ATTR.Attribute4), a      ; Attribute byte 5

        ld      bc, PlayerPatternsDown                  ; Sprite pattern range
        jp      UpdateSpritePattern

.SavePointDisappear:
; Save point (disappear) animation complete - Hide player
        ld      a, (GameStatus)
        res     5, a
        ld      (GameStatus), a                         ; Reset Game Start/end/dead animation flag

        ld      a, (GameStatus2)
        res     6, a                                    ; Reset Save point (disappear) flag
        set     5, a                                    ; Set scroll to save point flag
        ld      (GameStatus2), a

        ld      a, (PlayerSprAtt+S_SPRITE_ATTR.vpat)    ; Attribute byte 4
        res     7, a                                    ; Make sprite invisible
        ld      (PlayerSprAtt+S_SPRITE_ATTR.vpat), a    ; Attribute byte 4

; Calculate target scroll values
; 1. Save existing scroll values
        ld      bc, (ScrollTileMapBlockXPointer)

        push    bc                    ; Save ScrollTileMapBlockXPointer & ScrollTileMapBlockYPointer

; 2. Obtain target scroll values
        call    CalcStartingBlockOffsets
        ;call    CameraSetInitialCoords
        ;call    DrawTileMap

        ld      bc, (ScrollTileMapBlockXPointer)
        ld      (SavePointScrollTileMapBlockXPointer), bc       ; Sets both X & Y pointers

; 3. Restore existing scroll values
        pop     bc
        ld      (ScrollTileMapBlockXPointer), bc                ; Sets both X & Y pointers

; 4. Reset Scroll flags
        ld      a, 0
        ld      (SavePointScrollComplete), a          ; Reset ScrollComplete flags

        ret

.ContReset:
; Check sprite status
        bit     5, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .MarkForDeletion                    ; Jump if friendly rescued

        ;bit     4, (iy+S_SPRITE_TYPE.SpriteType3)
        ;jp      nz, .MarkToExplode                      ; Jump if bomb

        jp      .ContReset2
/*        
        bit     4, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .ContReset2                          ; Jump if not bomb


; - Bomb
        ld      a, (iy+S_SPRITE_TYPE.Counter)
        cp      1
        jp      z, .MarkToExplode

        dec     a
        ld      (iy+S_SPRITE_TYPE.Counter), a
        
        jp      .ContReset2
*/
.MarkForDeletion:
        set     2, (iy+S_SPRITE_TYPE.SpriteType1)       ; Mark sprite for deletion
        ret

.MarkToExplode:
; Set Exploding flag - Causes sprite to play explosion animation
        set     3, (iy+S_SPRITE_TYPE.SpriteType1)       ; Mark sprite to explode
        ret

.ContReset2:
        dec     bc                                      ; Point to start pattern in sprite animation pattern range

        ld      a, (bc)
        cp      64
        jp      c, .SetPatternBelow64                 ; Jump if pattern < 64

; -- Pattern above 63 - 
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Point to start pattern

        set     6, (ix+S_SPRITE_ATTR.Attribute4)        ; Set N6 = 7th pattern bit
        sub     64                                      ; Subtract 64 to fit within pattern range

        jp      .UpdateSpriteAttributes

.SetPatternBelow64:
        ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Point to start pattern
        res     6, (ix+S_SPRITE_ATTR.Attribute4)        ; Reset N6 = 7th pattern bit

        ;;ld      a, (bc)                                 
        ;;ld      (iy+S_SPRITE_TYPE.patternCurrent), a    ; Reset to start pattern

.UpdateSpriteAttributes:
; Check sprite type and set sprite visible as required
        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .SpriteVisible                      ; Jump if player

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .ContUpdate                          ; Jump if non-player not visible on camera

.SpriteVisible:
        set     7, a                                    ; Make sprite visible

.ContUpdate:
        set     6, a                                    ; Enable sprite attribute 5
        ld      (ix+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ret

;-------------------------------------------------------------------------------------
; Delete sprite
; Parameters:
; iy = Sprite data
DeleteSprite:
; Obtain location within sprite attribute table and hide sprite
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes

        ld      a, 0                                    ; Hide sprite visible
        set     6, a                                    ; Enable sprite attribute 5
        ld      (ix+S_SPRITE_ATTR.vpat), a              ; Attribute byte 4 - %0'0'000000 - visible sprite, 4Byte, sprite pattern

        ld      a, 0
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

; Release Sprite Data slot
        ld      bc, 0
        ld      (iy+S_SPRITE_TYPE.active), a            
        ld      (iy+S_SPRITE_TYPE.SpriteNumber), a
        ld      (iy+S_SPRITE_TYPE.AttrOffset), bc

; Reset other variables
        ld      (iy+S_SPRITE_TYPE.MoveToBlock), bc
        ld      (iy+S_SPRITE_TYPE.MoveToTarget), a            
        ld      (iy+S_SPRITE_TYPE.SprCollision), a            
        ld      (iy+S_SPRITE_TYPE.SprContactSide), a            

; Update enemy spawn point data
        bit     6, (iy+S_SPRITE_TYPE.SpriteType1)
        ret     z                                               ; Return if sprite not enemy

        ld      hl, (iy+S_SPRITE_TYPE.EnemySpawnPoint)
        ld      ix, hl

; Check whether we need to update the spawned enemy count as part of DoorLockdown
        ld      a, (ix+S_SPAWNPOINT_DATA.RecordSpawned) 
        cp      0
        jp      z, .PostRecordSpawnerCheck

        ld      a, (RecordSpawnedNumber)
        dec     a
        ld      (RecordSpawnedNumber), a                        ; Decrement RecordSpawnedNumber count

.PostRecordSpawnerCheck:

        ld      a, (ix+S_SPAWNPOINT_DATA.Reuse) 
        cp      0
        jp      z, .Cont                                        ; Jump if spawn point set for no reuse

        dec     (ix+S_SPAWNPOINT_DATA.MaxEnemiesCounter)        ; Otherwise decrement max enemy counter to allow respawning of enemy

.Cont:
        ld      (iy+S_SPRITE_TYPE.EnemySpawnPoint), 0

        ;;ld      (iy+S_SPRITE_TYPE.SpriteType1), 0
        ;;ld      (iy+S_SPRITE_TYPE.SpriteType2), 0
        ;res     5, (ix+S_SPRITE_TYPE.SpriteType1)       ; Indicate sprite not visible


        ;bit     0, (iy+S_SPRITE_TYPE.SpriteType2)       ; Check whether enemy was playing death animation
        ;jr      nz, .Cont                               ; Jump if enemy playing death animation

        ;ld      hl, (iy+S_SPRITE_TYPE.EnemyType)        ; Otherwise obtain enemy associated EnemyType
        ;ld      ix, hl
        ;ld      a, (ix+S_ENEMY_TYPE.EnemyMaxCounter)
        ;dec     a                                       ; Decrement counter to enable respawn of new enemy
        ;ld      (ix+S_ENEMY_TYPE.EnemyMaxCounter), a

;.Cont:
        ;res     0, (iy+S_SPRITE_TYPE.SpriteType2)       ; Reset enemy death animation flag

        ret

;-------------------------------------------------------------------------------------
; Sprites - Update Sprite Orientation
; Parameters:
; ix = Sprite attribute memory offset
; iy = Sprite storage memory address offset
UpdateSpriteOrientation:        
; Check whether sprite should change orientation
        bit     0, (iy+S_SPRITE_TYPE.SpriteType5)       ; bit 0 set in sprite data
        jp      z, .ContOrientation                     ; Jump if sprite should change orientation

        ld      bc, (iy+S_SPRITE_TYPE.animationStr)     ; Assumes sprite always plays this animation
        call    UpdateSpritePattern                     ; Play straight animation

        ret

.ContOrientation:
        ld      a, (iy+S_SPRITE_TYPE.Movement)  ; Get current movement flag value
        cp      (iy+S_SPRITE_TYPE.Movement2)    ; Compare with previous movement flag value
        ret     z                               ; Return if no change in movement

; Check movement not 0
        cp      0
        ret     z                               ; Return if no movement; prevents incorrect SpriteMovementValues offset

; Movement different
        ld      (iy+S_SPRITE_TYPE.Movement2), a ; Update previous movement flag
        dec     a                               ; Decrement movement value to allow lookup in data table

        ld      hl, SpriteMovementValues
        add     hl, a                           ; Point to table entry for movement value
        ld      a, (hl)                         ; Obtain table entry
        
        push    af
; Check/Set Sprite Pattern - bits 4, 3
; - Check for Up Pattern
        bit     4, a
        jp      nz, .SetUpPattern

; - Check for Down Pattern
        bit     3, a
        jp      nz, .SetDownPattern

; - Otherwise Right pattern
        ld      bc, (iy+S_SPRITE_TYPE.animationStr)
        call    UpdateSpritePattern             ; Update to straight animation

        jp      .CheckRotation

.SetUpPattern:
        ld      bc, (iy+S_SPRITE_TYPE.animationUp)
        call    UpdateSpritePattern             ; Update to up animation

        jp      .CheckRotation

.SetDownPattern:
        ld      bc, (iy+S_SPRITE_TYPE.animationDown)
        call    UpdateSpritePattern             ; Update to down animation

        jp      .CheckRotation

; Check/Set Sprite Rotation - bit 2
.CheckRotation
        pop     af

        push    af
        bit     2, a                            ; Check whether rotation required
        jr      nz, .SetRotation                ; Jump if rotation required

        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        res     1, a                            ; Reset rotation
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        jp      .CheckMirrorHor

.SetRotation:
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        set     1, a                            ; Set rotation
        ld      (ix+S_SPRITE_ATTR.mrx8), a

; Check/Set Sprite Mirror Horizontal - bit 1
.CheckMirrorHor:
        pop     af

        bit     1, a                            ; Check whether mirror horizontal is required
        jr      nz, .SetMirrorHor               ; Jump if mirror horizontal required

        push    af

        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        res     3, a                            ; Reset mirror horizontal
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        jp      .CheckMirrorVer        

.SetMirrorHor:
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        set     3, a                            ; Set mirror horizontal
        res     2, a                            ; Reset mirror vertical
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        ret                                     ; No need to check mirror vertical

; Check/Set Sprite Mirror Vertical - bit 0
.CheckMirrorVer:
        pop     af

        bit     0, a                            ; Check whether mirror vertical is required
        jr      nz, .SetMirrorVer

        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        res     2, a                            ; Reset mirror vertical
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        ret

.SetMirrorVer:
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        set     2, a                            ; Set mirror vertical
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        ret

;-------------------------------------------------------------------------------------
; Sprites - Update Bullet Sprite Orientation
; Parameters:
; ix = Sprite attribute memory offset
; iy = Sprite storage memory address offset
UpdateBulletSpriteOrientation:        
	ld	a, (iy+S_SPRITE_TYPE.Rotation)
	
; Rotation < 16 - Up - ----U---
	cp	16
	jp	nc, .CheckUpRight		; Jump if rotation >= 16

	ld	a, %0000'1000			; Otherwise set to Up
	jp	.UpdateOrientation

; Rotation < 48 - Up-Right - ----U--R
.CheckUpRight:
	cp	48
	jp	nc, .CheckRight			; Jump if rotation >= 48

	ld	a, %0000'1001			; Otherwise set to Up-Right
	jp	.UpdateOrientation

; Rotation < 80 - Right - -------R
.CheckRight:
	cp	80
	jp	nc, .CheckDownRight             ; Jump if rotation >= 80

	ld	a, %0000'0001			; Otherwise set to Right
	jp	.UpdateOrientation

; Rotation < 112 - Down-Right - -----D-R
.CheckDownRight:
	cp	112
	jp	nc, .CheckDown			; Jump if rotation >= 112

	ld	a, %0000'0101			; Otherwise set to Down-Right
	jp	.UpdateOrientation

; Rotation < 144 - Down - -----D--
.CheckDown:
	cp	144
	jp	nc, .CheckDownLeft              ; Jump if rotation >= 144

	ld	a, %0000'0100			; Otherwise set to Down
	jp	.UpdateOrientation

; Rotation < 176 - Down-Left - -----DL-
.CheckDownLeft:
	cp	176
	jp	nc, .CheckLeft			; Jump if rotation >= 176

	ld	a, %0000'0110			; Otherwise set to Down-Left
	jp	.UpdateOrientation

; Rotation < 208 - Left - ------L-
.CheckLeft:
	cp	208
	jp	nc, .CheckUpLeft                ; Jump if rotation >= 208

	ld	a, %0000'0010			; Otherwise set to Left
	jp	.UpdateOrientation

; Rotation < 240 - Up-Left - ----U-L-
.CheckUpLeft:
	cp	240
	jp	nc, .Up                         ; Jump if rotation >= 240

	ld	a, %0000'1010			; Otherwise set to Up-Left
	jp	.UpdateOrientation

; Otherwise Up - ----U---
.Up:
	ld	a, %0000'1000	                ; Otherwise set to Up

.UpdateOrientation:
        dec     a                               ; Decrement movement value to allow lookup in data table

        ld      hl, SpriteBulletMovementValues
        add     hl, a                           ; Point to table entry for movement value
        ld      a, (hl)                         ; Obtain table entry
        
        push    af
; Check/Set Sprite Pattern - bit 3
        bit     3, a
        jr      nz, .SetDiagonalPattern         ; Jump if bit set

        ld      bc, (iy+S_SPRITE_TYPE.animationStr)
        call    UpdateSpritePattern             ; Update to straight animation

        jp      .CheckRotation

.SetDiagonalPattern:
        ld      bc, (iy+S_SPRITE_TYPE.animationUp)
        call    UpdateSpritePattern             ; Update to diagonal animation

; Check/Set Sprite Rotation - bit 2
.CheckRotation
        pop     af

        push    af
        bit     2, a                            ; Check whether rotation required
        jr      nz, .SetRotation                ; Jump if rotation required

        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        res     1, a                            ; Reset rotation
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        jp      .CheckMirrorHor
.SetRotation:
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        set     1, a                            ; Set rotation
        ld      (ix+S_SPRITE_ATTR.mrx8), a

; Check/Set Sprite Mirror Horizontal - bit 1
.CheckMirrorHor:
        pop     af

        bit     1, a                            ; Check whether mirror horizontal is required
        jr      nz, .SetMirrorHor               ; Jump if mirror horizontal required

        push    af

        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        res     3, a                            ; Reset mirror horizontal
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        jp      .CheckMirrorVer        

.SetMirrorHor:
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        set     3, a                            ; Set mirror horizontal
        res     2, a                            ; Reset mirror vertical
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        ret                                     ; No need to check mirror vertical

; Check/Set Sprite Mirror Vertical - bit 0
.CheckMirrorVer:
        pop     af

        bit     0, a                            ; Check whether mirror vertical is required
        jr      nz, .SetMirrorVer

        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        res     2, a                            ; Reset mirror vertical
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        ret

.SetMirrorVer:
        ld      a, (ix+S_SPRITE_ATTR.mrx8)
        set     2, a                            ; Set mirror vertical
        ld      (ix+S_SPRITE_ATTR.mrx8), a

        ret

/*
;-------------------------------------------------------------------------------------
; Sprites - Update Bullet Spawning Orientation
; Parameters:
; iy = Sprite storage memory address offset
UpdateBulletSpawningOrientation:
        ld      hl, BulletMovementSpawnValues
        ld      d, (iy+S_SPRITE_TYPE.Movement)
        dec     d                               ; Table offset starts at 0
        ld      e, 4
        mul     d, e
        add     hl, de

        ld      bc, (hl) 
        ld      (iy+S_SPRITE_TYPE.BulletXOffset), bc
        
        inc     hl
        inc     hl
        ld      bc, (hl) 
        ld      (iy+S_SPRITE_TYPE.BulletYOffset), bc
        
        ret
*/
;-------------------------------------------------------------------------------------
; Sprites - Process non-player sprites
; Parameters:
; a - Number of sprites to process
ProcessOtherSprites:
        ld      ix, OtherSprites

        ld      b, a

; Check freeze status
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      nz, .SpriteLoop                 ; Jump if freeze enabled i.e. Don't process Reverse-Hazard counters

; Process Reverse-Hazard counter
        ld      a, (ReverseHazardCounter)
        cp      0
        jp      z, .ResetReverseHazard          ; Jump if counter == 0

        dec     a
        ld      (ReverseHazardCounter), a       ; Otherwise decrement

        jp      .SpriteLoop

; - Reverse-Hazard counter expired so reset flag
.ResetReverseHazard:
        ld      a, 0
        ld      (ReverseHazardEnabled), a

.SpriteLoop:
        push    bc

        ld      a, (ix+S_SPRITE_TYPE.active)
        cp      1
        jp      nz, .NextSprite                 ; Jump if sprite not active

; Check sprite types
        bit     5, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .Turret                     ; Jump if sprite a turret

        bit     6, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .Enemy                      ; Jump if sprite an enemy

        bit     4, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .Bullet                     ; Jump if sprite a bullet

        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .Friendly                   ; Jump if sprite a friendly

        bit     2, (ix+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .LockerCollectable          ; Jump if sprite a locker collectable

        bit     4, (ix+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .LockerOrKey                ; Jump if sprite a locker

        bit     0, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .LockerOrKey                ; Jump if sprite a key

        jp      .Other

; --- Locker Sprite
.LockerOrKey:
; - Locker Camera Check
        call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible

        cp      0                               ; Check return value
        jp      z, .NextSprite                  ; Jump if sprite not visible

; -- Otherwise update animation
        push    ix

        ld      hl, ix       
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                          ; Destination - Sprite Attributes
        ld      iy, hl                          ; Destination - Sprite Type

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range - Next frame
        call    UpdateSpritePattern

        pop     ix

        jp      .NextSprite

; --- Locker Collectable Sprite
.LockerCollectable:
        call    ProcessLockerCollectable

; - Locker Collectable Camera Check
        call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible
        cp      0                               ; Check return value
        jp      z, .NextSprite                  ; Jump if sprite not visible

; -- Otherwise update animation
        push    ix

        ld      hl, ix       
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                          ; Destination - Sprite Attributes
        ld      iy, hl                          ; Destination - Sprite Type

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range - Next frame
        call    UpdateSpritePattern

        pop     ix

        jp      .NextSprite
/*
; --- Bomb Sprite
.Bomb: 
        push    ix
        call    ProcessBullet
        pop     ix

        call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible

        jp      .NextSprite
*/
; --- Friendly Sprite
.Friendly:
        push    ix
        call    ProcessFriendly                    
        pop     ix

        cp      0
        jp      z, .NextSprite                  ; Jump if return value a=0

        call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible

        jp      .NextSprite

; --- Bullet Sprite
.Bullet:
; Check freeze status
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      nz, .BypassBulletProcessing     ; Jump if freeze enabled i.e. bypass normal processing

        push    ix
        call    ProcessBullet
        pop     ix

.BypassBulletProcessing:
        call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible

        jp      .NextSprite

; --- Turret Sprite
.Turret:
; Check freeze status
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      nz, .BypassTurretProcessing             ; Jump if freeze enabled i.e. bypass normal processing

        call    ProcessEnemyTurret

.BypassTurretProcessing:
; - Check whether Turret-Rotating
        bit     6, (ix+S_SPRITE_TYPE.SpriteType4)
        jp      z, .NonRotating                         ; Jump if not Turret-Rotating i.e. Directional turret
        
        call    UpdateSpriteRotationPosition            ; Otherwise always call

        jp      .TurretCameraCheck

; Check whether turret visible i.e. Displayed on screen
.NonRotating:
        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        call    nz, UpdateSpriteRotationPosition        ; Call if turret visible

; - Turret Camera Check
.TurretCameraCheck:
        call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible

        jp      .NextSprite

; --- Enemy Sprite
.Enemy:
; Check freeze status
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      z, .FreezeEnemyNotEnabled       ; Jump if freeze not enabled i.e. normal processing

; - Freeze enabled
; Check whether enemy spawning
        bit     6, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      z, .NoSpawnAnimation            ; Jump if enemy not spawning

; Otherwise simply play spawn animation
        push    ix, iy

        ld      hl, ix
        ld      iy, hl
        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern

        pop     iy, ix

        jp      .EnemyCont

.NoSpawnAnimation:
        ld      iy, PlayerSprite

        push    ix, iy
        call    CheckCollision                  ; Check collision between enemy and player
        pop     iy, ix

        jp      .EnemyCont                      ; Bypass normal processing

.FreezeEnemyNotEnabled:
; Check whether enemy spawning
        bit     6, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      z, .NoSpawnAnimation2           ; Jump if enemy not spawning

; Otherwise simply play spawn animation
        push    ix, iy

        ld      hl, ix
        ld      iy, hl
        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)
        ld      ix, hl

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern

        pop     iy, ix

        jp      .EnemyCont

.NoSpawnAnimation2:
        push    ix
        call    ProcessEnemy
        pop     ix

        cp      0
        jp      z, .NextSprite                  ; Jump if return value a=0

; - Enemy Camera Check
.EnemyCont:
        call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible

        jp      .NextSprite

.Other:
; - Sprite Camera Check
       call    CheckSpriteCameraBoundary       ; Check whether sprite should be made visible

.NextSprite:
        ld      de, S_SPRITE_TYPE
        add     ix, de                          ; Point to next sprite data

        pop     bc

        dec     b
        jp      nz, .SpriteLoop

        ret

;-------------------------------------------------------------------------------------
; Sprites - Process Bullet Sprites
; Parameters:
; ix = Bullet sprite storage memory address offset
ProcessBullet:
; Check whether bullet is exploding
        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .ContProcessing              ; Jump if bullet not exploding

; Process explosion animation
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range

        call    UpdateSpritePattern

        ld      ix, iy

; Check whether bullet is marked for deletion i.e. Explode animation complete
        bit     2, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .DeleteBullet                       ; Jump if bullet marked for deletion

        ret

.ContProcessing:
; Check whether bullet should be deleted based on range travelled
        ld      a, (ix+S_SPRITE_TYPE.RotRadius)
        ld      b, (ix+S_SPRITE_TYPE.RotRange)

        cp      b
        jp      nc, .ExplodeBullet                      ; Jump if bullet range <= current bullet range

; ====== Update bullet movement ======
; - Check whether projectile should move this frame e.g. projectile destroying destructable blocks
        bit     7, (ix+S_SPRITE_TYPE.SpriteType5)
        jp      z, .ContMovement                        ; Jump if projectile should move this frame

        res     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Clear don't move flag

        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        jp      .BypassMovement

.ContMovement:
; Check whether bullet can be moved based on movement delay
        ld      a, (ix+S_SPRITE_TYPE.Counter)
        cp      0
        jr      nz, .ContinueMove                       ; Jump if movement counter is not zero and allow bullet to be moved

        ld      a, (ix+S_SPRITE_TYPE.MovementDelay)
        ld      (ix+S_SPRITE_TYPE.Counter), a           ; Otherwise reset bullet movement delay counter and don't move

        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)

        jp      .BypassMovement

.ContinueMove:
        dec     a
        ld      (ix+S_SPRITE_TYPE.Counter), a           ; Decrement move counter and continue to move

; Obtain/Store Radius to rotation point
        ld      hl, Radius
        ld      a, (ix+S_SPRITE_TYPE.RotRadius)
        add     a, (ix+S_SPRITE_TYPE.Speed)             ; Increment radius i.e. Move bullet
        
        ld      (ix+S_SPRITE_TYPE.RotRadius), a
        ld      (hl), a

; Obtain Rotation value around rotation point
        ld      a, (ix+S_SPRITE_TYPE.Rotation)

; Check whether enemy or player bullet
        bit     0, (ix+S_SPRITE_TYPE.SpriteType2)
        call    z, ReticuleToPlayerRotation             ; Call if not enemy bullet; calculates rotation based on reticule position to player, improves bullet accruracy

; Obtain World Coordinates of rotation point
        ld      bc, (ix+S_SPRITE_TYPE.RotPointY)
        ld      de, (ix+S_SPRITE_TYPE.RotPointX)

        call    ObtainPosOnCircle

; Update bullet sprite values/attributes
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc        
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), de

.BypassMovement:
; --- Check block for collision
; Point to middle of bullet
        ld      hl, de
        add     bc, 8                                   
        add     hl, 8

        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                  ; Add block offset
        ld      a, (iy)

        push    af

; ====== Door - Check for door blocks ======
; - Lower Check
        ld      d, a
        ld      a, HorDoorStart-1
        cp      d
        jp      nc, .CheckDestructable                  ; Jump if tile <= HorDoorStart-1

; - Upper Check
        ld      a, VerDoorTrigger;VerDoorsEnd-1                         
        cp      d
        jp      c, .CheckDestructable                   ; Jump if tile > VerDoorTrigger

; - Horizontal door1 open check
        ld      a, HorDoor1End
        cp      d
        jp      z, .CheckDestructable

; - Horizontal door2 open check
        ld      a, HorDoor2End
        cp      d
        jp      z, .CheckDestructable

; - Vertical door1 open check
        ld      a, VerDoor1End
        cp      d
        jp      z, .CheckDestructable

; - Vertical door2 open check
        ld      a, VerDoor2End
        cp      d
        jp      z, .CheckDestructable

; Door detected
        pop     af

        jp      .ExplodeBullet

; ====== Destructable Blocks - Check for destructable blocks ======
.CheckDestructable:
; - Lower Check
        ld      a, DestructableStartBlock-1
        cp      d
        jp      nc, .CheckForWall                       ; Jump if tile <= DestructableStartBlock-1

; - Upper Check
        ld      a, DestructableEndBlock                     
        cp      d
        jp      c, .CheckForWall                        ; Jump if tile > DestructableEndBlock

; Destructable block detected
; 1. Check projectile damage and tile energy
        ld      a, DestBlockTileEnergy-1                ; Destructable block tile damage threshold
        cp      (ix+S_SPRITE_TYPE.Damage)
        jp      nc, .DamageToSmall                      ; Jump if damage <= (DestBlockTileEnergy-1)

        ld      a, DestructableEndBlock
        cp      d
        jp      z, .EndDestTile                        ; Jump if destructable end block

; - Tile != EndTile
        inc     (iy)

        ld      a, (ix+S_SPRITE_TYPE.Damage)
        sub     DestBlockTileEnergy
        ld      (ix+S_SPRITE_TYPE.Damage), a

        set     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Ensure projectile doesn't move next frame

        jp      .Cont

; - Tile = End Tile
.EndDestTile:
        ld      (iy), FloorStandardBlock                ; Replace tile block with floor block

        ld      a, (ix+S_SPRITE_TYPE.Damage)
        sub     DestBlockTileEnergy
        ld      (ix+S_SPRITE_TYPE.Damage), a

        jp      .Cont

; - Damage to small to damage tile
.DamageToSmall:
        ld      (ix+S_SPRITE_TYPE.Damage), 0

        jp      .CheckProjectile

; 2. Check/Update screen tilemap
.Cont:
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)

; Point to middle of bullet
        add     bc, 8                                   ; Parameter X world coordinate
        add     hl, 8                                   ; Parameter Y world coordinate
        call    ConvertWorldToBlockOffset

        ld      hl, de                                  ; Parameter - hl = x block offset, y block offset
        ld      de, bc                                  ; Parameter - de = Block offset
        push    ix, iy
        call    UpdateScreenTileMap
        pop     iy, ix

; 3. Check whether projectile should be destroyed
.CheckProjectile:
        pop     af

        ld      a, (ix+S_SPRITE_TYPE.Damage)
        cp      0
        jp      z, .ExplodeBullet                       ; Jump if projectile damage > 0

        ret

; ====== Wall Blocks - Check for wall blocks ======
.CheckForWall:
        pop     af

        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jr      nc, .ExplodeBullet                      ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Explode bullet

; ====== Spawnpoint Blocks - Check spawnpoint collision ======
        bit     0, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .CheckReverseHazard;.CheckSpriteCollision               ; Jump if enemy bullet

; - Lower Check
        ld      a, SpawnPoint1StartBlock-1
        cp      b
        jp      nc, .CheckReverseHazard;.CheckSpriteCollision               ; Jump if tile <= SpawnPointStartBlock-1

; - Upper Check
        ld      a, SpawnPointDisabledBlock-1              
        cp      b
        jp      c, .CheckReverseHazard;.CheckSpriteCollision                ; Jump if tile > SpawnPointDisabledBlock-1

; - Hit/damage spawnpoint
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)

; - Point to middle of bullet
        add     bc, 8                                   ; Parameter X world coordinate
        add     hl, 8                                   ; Parameter Y world coordinate
        call    ConvertWorldToBlockOffset

        ld      a, (ix+S_SPRITE_TYPE.Damage)
        call    SpawnPointHit

        ld      (ix+S_SPRITE_TYPE.Damage), a            ; Return value: a = projectile damage
        cp      0                                       
        jp      z, .ExplodeBullet                       ; Jump if projectile damage > 0

        ret

; ====== Reverse-Hazard - Check for reverse-hazard enable block ======
.CheckReverseHazard:
        ld      a, ReverseHazardEnableBlock
        cp      b
        jp      nz, .CheckSpriteCollision               ; Jump if reverse-hazard enable block not hit

        ld      a, 1
        ld      (ReverseHazardEnabled), a
        ld      a, ReverseHazardDelay
        ld      (ReverseHazardCounter), a

; - Check whether the player has already enabled the reverse-hazard
        ld      a, (ReverseHazardEnabledPlayer)
        cp      0
        jp      z, .ExplodeBullet                       ; Jump if bullet rather than player has triggered reverse-hazard, so explode bullet
                                                        ; Otherwise let the bullet pass through

; ====== Sprites - Check sprite collision ======
.CheckSpriteCollision:
        call    CheckBulletForCollision

        cp      0                                       ; Check return value
        ret     z                                       ; Return if bullet not to be destroyed

; ====== Bullet Explosions ======
.ExplodeBullet:
        ;push    af, ix
        ;ld      a, AyFXBulletExplode
        ;call    AFXPlay
        ;pop     ix, af

; Set BulletExploding flag - Causes bullet to play explosion animation
        set     3, (ix+S_SPRITE_TYPE.SpriteType1)

; Process explode animation
; - Check for bullet -> Destroyed spawnpoint
        bit     4, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .SpawnPointExplosion                ; Jump if player bullet destroyed spawnpoint

; - Check for bullet -> Disabled terminator/turret
        bit     7, (ix+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .TurretBulletExplosion              ; Jump if player bullet hit disabled terminator/turret

;;;.NotTurret:
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.animationOther)   ; Sprite pattern range

        call    UpdateSpritePattern

        ret

.TurretBulletExplosion:
        ld      iy, ix
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes

        ld      bc, EnemyPatternsExp ;BulletTurretPatternsExp             ; Sprite pattern range
        ld      (iy+S_SPRITE_TYPE.animationOther), bc   ; Change pattern to new explosion

        call    UpdateSpritePattern

        ret

.SpawnPointExplosion:
; TODO - Animation
; - Bullet just starting to explode; set run once settings  - i.e. Set new x, y for scaled explosion to fit within current sprite
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, -8      
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, -8
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

        ld      iy, ix
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes

        ld      a, (ix+S_SPRITE_ATTR.Attribute4)
        or      %000'01'01'0                            ; Scale x + y
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        ld      bc, EnemyPatternsExp ;BulletTurretPatternsExp             ; Sprite pattern range
        ld      (iy+S_SPRITE_TYPE.animationOther), bc   ; Change pattern to new explosion

        call    UpdateSpritePattern

        ret

; ====== Bullet Deletion ======
.DeleteBulletSwap:
        ld      iy, ix
.DeleteBullet:
; Delete bullet sprite
        call    DeleteSprite

; Update Number of bullets left
        bit     0, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      z, .PlayerProjectile            ; Jump if projectile fired by player

; - Enemy Bullet
        ld      a, (BulletsEnemyFired)
        dec     a                               ; Decrement number of bullets fired
        ld      (BulletsEnemyFired), a

        ret

; - Player Bullet
.PlayerProjectile:
/*
; Check type of projectile
        bit     4, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .PlayerBomb                 ; Jump if bomb
*/
; - Player bullet
        ld      a, (BulletsPlayerFired)
        dec     a                               ; Decrement number of bullets fired
        ld      (BulletsPlayerFired), a

        ret

/*
; - Player bomb
.PlayerBomb:
        ld      a, (BombsPlayerFired)
        dec     a                               ; Decrement number of bombs fired
        ld      (BombsPlayerFired), a

        ret
*/


;-------------------------------------------------------------------------------------
; Sprites - Process Enemy Sprites
; Parameters:
; ix = Enemy sprite storage memory address offset
; Return Values:
; a = Process Camera (0=No, 1=Yes)
ProcessEnemy:
; Check whether enemy is shooter
        bit     0, (ix+S_SPRITE_TYPE.SpriteType3)
        call    nz, EnemyShooter                        ; Call if enemy shooter

; Check whether enemy is indestructable
        bit     2, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassEnergyChecks                  ; Jump if enemy Indestructable

; Check whether enemy has touched reverse-hazard block
.CheckReverseHazardBlock:
; - Check enemy block
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                  ; Add block offset
        ld      a, (iy)                                 ; Obtain block number

        cp      ReverseHazardBlock
        jp      nz, .ContChecks                         ; Jump if not on reverse-hazard block

; - Enemy Touched - Check whether enemy not active i.e. Disabled Terminator
        bit     1, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      z, .ActiveEnemy                         ; Jump if not Terminator

        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .ActiveEnemy                         ; Jump if Terminator not disabled or exploding

; - Terminator - Set/Reset delaycounter to ensure disabled Terminator stays disabled whilst being damaged
        ld      a, (ix+S_SPRITE_TYPE.EnemyDisableTimeOut)
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      ; Set disable timeout

        ld      a, 1                                    ; Return value - Process camera

        ret

; - Damage enemy
.ActiveEnemy:
        ld      a, (ReverseHazardDamage)
        ld      b, a
        ld      a, (ix+S_SPRITE_TYPE.Energy)
        sub     b
        jp      nc, .SetActiveEnemyEnergy               ; Jump if energy not negative

        ld      a, 0                                    ; Otherwise reset energy to 0

.SetActiveEnemyEnergy:
        ld      (ix+S_SPRITE_TYPE.Energy), a 

.ContChecks:
; Check whether enemy is a Terminator
        bit     1, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NotTerminator                       ; Jump if enemy not a Terminator

; Terminator enemy
; - Check whether Terminator is currently disabled
        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .CheckTerminatorEnergy               ; Jump if terminator not disabled

; ---Terminator disabled---
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      z, .ResetTerminator                     ; Jump if terminator can now be re-enabled 

        dec     a
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      ; Otherwise decrement delay counter

        ld      a, 1                                    ; Return value - Process camera

        ret

.CheckTerminatorEnergy:
        ld      a, (ix+S_SPRITE_TYPE.Energy)
        cp      0
        jp      z, .DisableTerminator                   ; Jump if energy = 0

        jp      .BypassEnergyChecks

.DisableTerminator:
; Play audio effect
        push    ix

        ld      a, AyFXTerminatorDisabled
        call    AFX2Play

        pop     ix

        set     3, (ix+S_SPRITE_TYPE.SpriteType1)       ; Disable Terminator

        ld      a, (ix+S_SPRITE_TYPE.EnemyDisableTimeOut)
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      ; Set delay countdown

        ld      a, 1                                    ; Return value - Process camera

        ret

.ResetTerminator:
        push    ix

        ld      a, AyFXTerminatorEnabled
        call    AFX2Play

        pop     ix

        res     3, (ix+S_SPRITE_TYPE.SpriteType1)       ; Enable Terminator

        ld      a, (ix+S_SPRITE_TYPE.EnergyReset)
        ld      (ix+S_SPRITE_TYPE.Energy), a            ; Reset energy

        jp      .BypassEnergyChecks

; All enemies - Except waypoint and Terminator
.NotTerminator:
; Check whether enemy is exploding
        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .CheckEnergy                         ; Jump if enemy not exploding

; Process explode animation
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.animationOther)   ; Sprite pattern range

        call    UpdateSpritePattern

; Check whether enemy is marked for deletion i.e. Explode animation complete
        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .DeleteEnemy                        ; Jump if enemy marked for deletion

        ld      ix, iy

        ld      a, 1                                    ; Return value - Process camera
        ret

.CheckEnergy:
; Check whether enemy is still in range; non-visible enemies out-of-range should be destroyed
; - 1. First check whether enemy is visible
        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .ContEnergyCheck                    ; Jump if enemy visible

; - 2. Check whether enemy in range of player        
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.Range)
        call    CheckEntityInRange
        cp      0
        jp      nz, .ContEnergyCheck                    ; Return Value: Jump if enemy in range

; - Set not destroyed by player flag; used for activities such as ensuring points aren't awarded, or collectibles spawned
        set     3, (ix+S_SPRITE_TYPE.SpriteType4)
        jp      .ExplodeEnemyNoSound                    ; Enemy out of range so no audio                       

.ContEnergyCheck:
; Check enemy energy
        ld      a, (ix+S_SPRITE_TYPE.Energy)
        cp      0
        jp      z, .ExplodeEnemy                        ; Jump if energy = 0

.BypassEnergyChecks:
; Check collision with player
        ld      iy, PlayerSprite

        push    ix, iy
        call    CheckCollision                          ; Check collision between sprites; return - a
        pop     iy, ix

; Check whether enemy can be moved based on movement delay
        ld      a, (ix+S_SPRITE_TYPE.Counter)
        cp      0
        jr      nz, .ContinueMove                       ; Jump if movement counter is not zero and allow enemy to be moved

        ld      a, (ix+S_SPRITE_TYPE.MovementDelay)
        ld      (ix+S_SPRITE_TYPE.Counter), a     ; Otherwise reset enemy movement delay counter and don't move

        ld      a, 1                                    ; Return value - Process camera
        ret

.ContinueMove:
        dec     a
        ld      (ix+S_SPRITE_TYPE.Counter), a           ; Decrement move counter and continue to move

; Check Spawn/Flee Counters
; - Check Spawn flag status
        bit     3, (ix+S_SPRITE_TYPE.SpriteType5)
        jp      nz, .UpdateSpawnFleeCounters           ; Jump if Spawn flag set

; - Check FleeStatus flag
        bit     4, (ix+S_SPRITE_TYPE.SpriteType5)
        jp      z, .ContinueMove2                      ; Jump if FleeStatus flag not set

.UpdateSpawnFleeCounters:
; - Check invulnerability counter
        ld      a, (ix+S_SPRITE_TYPE.InvulnerableCounter)
        cp      0
        jp      z, .ResetSpawnFlag

        dec      (ix+S_SPRITE_TYPE.InvulnerableCounter)
        jp      .FleeCounterCheck

.ResetSpawnFlag:
; - Spawn counter = 0, reset Spawn flag
        res     3, (ix+S_SPRITE_TYPE.SpriteType5)       

.FleeCounterCheck:
; - Check Flee counter status
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      z, .ResetFleeStatusFlag                 ; Jump if flee counter = 0

        dec      (ix+S_SPRITE_TYPE.DelayCounter)

        ld      a, 1                                    ; Return value - Process camera

        bit     7, (ix+S_SPRITE_TYPE.SpriteType5)
        jp      nz, .NoMovement                         ; Jump if no move in next frame flag is set

        jp      .OffScreenEnemy

.ResetFleeStatusFlag:
; - Flee counter = 0, reset FleeStatus & Movement flags
        res     4, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset FleeStatus flag
        res     2, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset Movement flag i.e. Allow enemy to choose movement

.ContinueMove2:
        ld      a, 1                                    ; Return value - Process camera

        bit     7, (ix+S_SPRITE_TYPE.SpriteType5)
        jp      nz, .NoMovement                         ; Jump if no move in next frame flag is set

; Check whether waypoint enemy
        bit     3, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .WayPointEnemy                      ; Jump if enemy moving via waypoint

; Check whether enemy visible        
        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .OffScreenEnemy                      ; Jump if enemy off screen
        
        ;;;bit     1, (ix+S_SPRITE_TYPE.Speed)             ; TODO - Comment lines if fast enemy movement needs to change
        ;;;jp      nz, .OffScreenEnemy                     ; Jump if enemy speed = 2

        call    ProcessOnScreenEnemy

        ld      a, 1                                    ; Return value - Process camera
        ret

.WayPointEnemy:
        call    ProcessWayPointEnemy

        ld      a, 1                                    ; Return value - Process camera
        ret

.OffScreenEnemy:
        call    ProcessOffScreenEnemy

        ;call    SpriteTestMoveHor 
        ;call    SpriteTestMoveVer

        ld      a, 1                                    ; Return value - Process camera
        ret

.ExplodeEnemy:
; Play audio effect
        push    af, ix

        ld      a, AyFXEnemyDestroyed
        call    AFX3Play

        pop     ix, af

; Check whether the enemy was destroyed by the player and therefore allocate points
        bit     3, (ix+S_SPRITE_TYPE.SpriteType4) 
        jp      nz, .ExplodeEnemyNoSound                ; Enemy not destroyed by player

; Update Score
        push    iy
        ld      iy, ScoreDestroyEnemy
        call    UpdateScore
        pop     iy

.ExplodeEnemyNoSound:                                   ; Used when enemy destroyed out of range
;TODO - Note: If '3, (iy+S_SPRITE_TYPE.SpriteType4)'' set, then enemy not destroyed by player; use for actions such as not assigning points
        set     6, (ix+S_SPRITE_TYPE.SpriteType5)       ; Set ignore sprite flag

; Check whether enemy destroyed by waypoint enemy
        bit     0, (ix+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .BypassBlockMapBit                  ; Jump if enemy destroyed by waypoint enemy

; Clear enemy block tracking byte bit
        ld      de, (ix+S_SPRITE_TYPE.MoveToBlock)
        call    EnemyResetBlockMapBit                   ; No need to check result

.BypassBlockMapBit:
; Check whether enemy visible
        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .SetExplosion                       ; Jump if enemy visible

        set     2, (ix+S_SPRITE_TYPE.SpriteType1)       ; Otherwise mark sprite for deletion and don't display explosion

        ld      iy, ix

        jp      .DeleteEnemy      

.SetExplosion:
; Set Exploding flag - Causes enemy to play explosion animation
        set     3, (ix+S_SPRITE_TYPE.SpriteType1)

; Process explode animation
; - Enemy just starting to explode; set run once settings
        bit     1, (ix+S_SPRITE_TYPE.SpriteType5)
        jp      z, .EnemyExplosion                      ; Jump if not Terminator

; - Terminator Explosion - Scale
; Set new x, y for scaled explosion to fit within current sprite
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, -8      
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, -8
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

; Scale explosion
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes

        ld      a, (ix+S_SPRITE_ATTR.Attribute4)
        or      %000'01'01'0                            ; Scale x + y
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        jp      .PerformExplosion

.EnemyExplosion:
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes

.PerformExplosion:
        ld      bc, (iy+S_SPRITE_TYPE.animationOther)   ; Sprite pattern range

        call    UpdateSpritePattern

        ld      ix, iy

        ld      a, 1                                    ; Return value - Process camera

        ret

.DeleteEnemy:
; - Check whether locker collectable should be spawned
; -- Check 1 - Destroyed by waypoint enemy
; TODO - Terminator
        bit     0, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .ContSpawn                         ; Jump if destroyed by waypoint enemy  i.e. Try and spawn locker collectable

; -- Check 2 - Not destroyed by player
        bit     3, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .ContDelete                         ; Jump if non-Terminator enemy not destroyed by player i.e. Don't try and spawn locker collectable

.ContSpawn:
        ld      a, (CollectableSpawnCounter)
        inc     a
        ld      (CollectableSpawnCounter), a

        ld      b, a
        ld      a, (CollectableSpawnFrequency)
        cp      b
        jp      nz, .ContDelete                         ; Jump if not enough enemies destroyed to spawn collectable

        ld      a, 0
        ld      (CollectableSpawnCounter), a            ; Reset spawn locker collectable counter

; - Spawn locker collectable
        push    iy

        ld      hl, (iy+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, (iy+S_SPRITE_TYPE.YWorldCoordinate)

        ld      ix, LockerCollectableSprType
        ld      iy, LockerSpritesStart
        ld      a, LockerAttStart
        ld      b, MaxLockers
        call    SpawnNewLockerCollectableSprite

        pop     iy

.ContDelete:
; Delete enemy sprite
        call    DeleteSprite

        ld      ix, iy

; Update enemy values/stats - TODO

        ld      a, 0                                    ; Return value - Do not process camera
        ret

.NoMovement:
; Animate if not moving
        ld      iy, ix
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range - Keep existing

        call    UpdateSpritePattern

        ld      ix, iy


;-------------------------------------------------------------------------------------
; Sprites - Process Friendly Sprites
; Parameters:
; ix = Friendly sprite storage memory address offset
; Return Values:
; a = Process Camera (0=No, 1=Yes)
ProcessFriendly:
        ld      a, 1                                    ; Assume friendly not to be deleted

; Check whether friendly is following player
        bit     6, (ix+S_SPRITE_TYPE.SpriteType3)
        ret     z                                       ; Return if friendly not following player

; Check/Update delay counter used to delay damage to friendly
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      z, .Cont                                ; Jump if counter = 0

        dec     a                                       ; Otherwise decrement counter
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      

.Cont:
; Check whether friendly has been rescued
        bit     5, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      z, .CheckEnergy                         ; Jump if friendly not rescued

; - Process rescued animation
        ld      iy, ix

        ld      hl, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, hl                                  ; Destination - Sprite Attributes
        ld      bc, FriendlyPatternsRes                 ; Sprite pattern range

        call    UpdateSpritePattern

; - Check whether friendly is marked for deletion i.e. Rescue animation complete
        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .DeleteFriendly                        ; Jump if friendly marked for deletion

        ld      ix, iy

        ld      a, 1                                    ; Return value - Process camera
        ret

/*
.CheckExplosion:
; Check whether friendly is exploding
        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .CheckEnergy                         ; Jump if friendly not exploding

; - Process explode animation
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.animationOther)   ; Sprite pattern range

        call    UpdateSpritePattern

; - Check whether friendly is marked for deletion i.e. Explode animation complete
        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .DeleteFriendly                        ; Jump if friendly marked for deletion

        ld      ix, iy

        ld      a, 1                                    ; Return value - Process camera
        ret
*/
.CheckEnergy:
; Check friendly energy
        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.SprCollision), a      ; Assume no collision; fixes waypoint/friendly issue in ProcessOffScreenEnemy

        ld      a, (ix+S_SPRITE_TYPE.Energy)
        cp      0
        jp      z, .CheckResetFriendly			; Jump if energy = 0

        ;;;or      a
        ;;;jp      m, .CheckResetFriendly			; Jump if energy negative

; Friendly Following - Play Animation

/*
        push    ix

        ld      iy, ix
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range - Keep existing

        call    UpdateSpritePattern

        pop     ix
*/

; Check collision with player
        ld      iy, PlayerSprite

        push    ix, iy
        call    CheckCollision                          ; Check collision between sprites; return - a
        pop     iy, ix

        push    ix, iy
        call    CheckFriendlyHazardRescueCollision            ; Check collision between sprites and hazard blocks
        pop     iy, ix

; Check whether friendly has been rescued
        ld      a, 1                                    ; Return value - Assume process camera

        bit     5, (ix+S_SPRITE_TYPE.SpriteType3)
        ret     nz                                      ; Return if friendly rescued

; Check whether friendly can be moved based on movement delay
        ld      a, (ix+S_SPRITE_TYPE.Counter)
        cp      0
        jr      nz, .ContinueMove                       ; Jump if movement counter is not zero and allow friendly to be moved

        ld      a, (ix+S_SPRITE_TYPE.MovementDelay)
        ld      (ix+S_SPRITE_TYPE.Counter), a           ; Otherwise reset friendly movement delay counter and don't move

        ld      a, 1                                    ; Return value - Process camera
        ret

.ContinueMove:
        dec     a
        ld      (ix+S_SPRITE_TYPE.Counter), a     ; Decrement move counter and continue to move

.OffScreenFriendly:
        call    ProcessOffScreenEnemy

        ld      a, 1                                    ; Return value - Process camera
        ret

; Friendly energy <= 0
.CheckResetFriendly:
; Check and move friendly to target block before resetting
        ld      a, (ix+S_SPRITE_TYPE.MoveToTarget)
        cp      0
        jp      z, .ResetFriendly                       ; Jump if friendly at target block

        call    ProcessOffScreenEnemy                   ; Otherwise continue moving

        ld      a, 1                                    ; Return value - Process camera
        ret

.ResetFriendly:
/* - Removed inactive friendly pattern update
; Check/Update to inactive sprite pattern
        xor     a
        ld      hl, (ix+S_SPRITE_TYPE.patternRange)
        ld      bc, (ix+S_SPRITE_TYPE.animationDiag)
        sbc     hl, bc
        jr      z, .DiagonalSpritePattern               ; Jump if current pattern is diagonal 

; - Straight - Inactive friendly sprite pattern
        ld      bc, FriendlyPatternsInactiveStr         ; Sprite pattern range - Inactive Straight

        jp      .SetSpritePattern
; - Diagonal - Inactive friendly sprite pattern
.DiagonalSpritePattern:
        ld      bc, FriendlyPatternsInactiveDiag        ; Sprite pattern range - Inactive Diagonal

; - Set inactive sprite pattern
.SetSpritePattern:
        push    ix

        ld      iy, ix
        ld      hl, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, hl                                  ; Destination - Sprite Attributes
        call    UpdateSpritePattern

        pop     ix

*/
; Play audio effect
        push    af, ix

        ld      a, AyFXFriendlyDisable
        call    AFX2Play

        pop     ix, af

        res     6, (ix+S_SPRITE_TYPE.SpriteType3)       ; Reset following flag

        ld      (ix+S_SPRITE_TYPE.SprCollision), 0      ; Reset collision flag

        ld      de, (ix+S_SPRITE_TYPE.MoveToBlock)
        call    FriendlyResetBlockMapBit                ; Reset friendly block map bit

        ld      a, (ix+S_SPRITE_TYPE.EnergyReset)
        ld      (ix+S_SPRITE_TYPE.Energy), a            ; Reset friendly energy

        ld      (ix+S_SPRITE_TYPE.DelayCounter), FriendlyDamageDelay    ; Reset counter

        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.Movement2), a         ; Reset movement2 flag; required in order to reset orientation when re-enabled by player

; - Reset to disabled friendly animation frame
        ld      iy, ix
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes

        ld      bc, FriendlyPatternsDisabled
        call    UpdateSpritePattern             ; Update to up animation

        ld      ix, iy   

        ret

/*
; Set Exploding flag - Causes friendly to play explosion animation
        set     3, (ix+S_SPRITE_TYPE.SpriteType1)

; Clear friendly block tracking byte bit
        ld      de, (ix+S_SPRITE_TYPE.MoveToBlock)
        call    EnemyResetBlockMapBit                   ; No need to check result

        ld      de, 0
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), de      ; Required to avoid enemy-to-friendly issue for deleted sprite

; Process explode animation
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.animationOther)   ; Sprite pattern range

        call    UpdateSpritePattern

        ld      ix, iy

        ret
*/
.DeleteFriendly:
; Delete friendly sprite
        call    DeleteSprite

        ld      ix, iy

; Update friendly values/stats - TODO


        ld      a, 0                                    ; Return value - Do not process camera
        ret

/*
;-------------------------------------------------------------------------------------
; Sprites - Process Bomb Sprite
; Parameters:
; ix = Bomb sprite storage memory address offset
; Return Values:
; a = Process Camera (0=No, 1=Yes)
ProcessBomb:
; Process animation
        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .ExplodeBomb                        ; Jump if bomb exploding

; - Play detonation animation
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, BombDetonationPatterns                        ; Sprite pattern range

        call    UpdateSpritePattern

        ld      ix, iy

        ld      a, 1                                    ; Return value - Process camera
        ret

.ExplodeBomb:
; Check bomb to enemy collision - Check for each animation frame
        call    CheckBombForCollision

; Check whether the bomb is just starting to explode
        ld      a, (BombExploding)
        cp      1
        jp      z, .BombExploding                       ; Jump if bomb already exploding

; - Bomb just starting to explode; perform run once actions
        push    ix, iy
        call    CheckBombSpawnPointCollision            ; Check collision between bomb and spawn point blocks
        pop     iy, ix

; -- Set new x, y for scaled explosion to fit within current sprite
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, -8      
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc

        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, -8
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

        ld      a, 1
        ld      (BombExploding), a

.BombExploding:
; Process explode animation
        ld      iy, ix
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes

        ld      a, (ix+S_SPRITE_ATTR.Attribute4)        ; Attribute byte 5 - %0'0'0'00'00'0

        or      %000'01'01'0                            ; Scale x + y
        ld      (ix+S_SPRITE_ATTR.Attribute4), a        ; Attribute byte 5 - %0'0'0'00'00'0

        ld      bc, (iy+S_SPRITE_TYPE.animationOther)   ; Sprite pattern range

        call    UpdateSpritePattern
        
; Check whether bomb is marked for deletion i.e. Explode animation complete
        bit     2, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .DeleteBomb                        ; Jump if bomb marked for deletion

        ld      ix, iy

        ld      a, 1                                    ; Return value - Process camera
        ret

.DeleteBomb:
; Delete bomb sprite
        ld      a, 0
        ld      (PlayerDroppedBomb), a                  ; Reset bomb flag
        ld      (BombExploding), a                      ; Reset bomb flag

        call    DeleteSprite

        ld      ix, iy

        ld      a, 0                                    ; Return value - Do not process camera
        ret
*/

;-------------------------------------------------------------------------------------
; Sprites - Process Locker Collectable Sprite
; Parameters:
; ix = Locker sprite storage memory address offset
; Return Values:
; a = Process Camera (0=No, 1=Yes)
ProcessLockerCollectable:
; Check alive countdown
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      z, .DeleteLockerCollectable             ; Jump if counter = 0

        dec     (ix+S_SPRITE_TYPE.DelayCounter)

; Check for collectable switch key pressed
        ld      a, (PlayerInputOriginal)
        bit     4, a
        ret     z                                       ; Return if Switch key not pressed

; - Toggle sprite
        bit     1, (ix+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .LockerSwitchToFreeze

; --- Set to energy locker collectable
        set     1, (ix+S_SPRITE_TYPE.SpriteType4)

        ld      hl, LockerEnergyCollectablePatterns

        jp      .UpdateLocker

; --- Set to freeze locker
.LockerSwitchToFreeze:
        res     1, (ix+S_SPRITE_TYPE.SpriteType4)

        ld      hl, LockerFreezeCollectablePatterns

.UpdateLocker:
        push    ix, iy

        ld      iy, ix
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, hl                                  ; Sprite pattern range - Update
        call    UpdateSpritePattern

        pop     iy, ix


/*
        push    ix, iy

        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range - Keep existing
        call    UpdateSpritePattern

        pop     iy, ix
*/
        ret

.DeleteLockerCollectable:
; Delete collectable sprite
        ld      iy, ix
        call    DeleteSprite

        ld      ix, iy

        ld      a, 0                                    ; Return value - Do not process camera
        ret

/* 21/06/23 - Not Used
;-------------------------------------------------------------------------------------
; Sprites - Update Reticule Sprite Rotation Angle
; Parameters:
UpdateReticule:
; Check exit conditions
        ld      a, (PlayerInput)                        
        cp      0                                       
        ret     z                                       ; Return if no player input i.e. No need to update reticule rotation               

        cp      %00100000
        jp      z, UpdateReticulePosition              ; Jump if only fire pressed and no further player input

        ;ld      a, (StrafeEnabled)
        ;cp      0
        ;jp      nz, UpdateReticulePosition             ; Jump if strafe enabled

; Continue with rotation update
        ld      a, (ReticuleRotation)
        ld      c, a                                    ; Obtain current reticule rotation value

; 1. Obtain rotation value for current player input
        ld      hl, PlayerMovementToRotationValues
        ld      d, 0
        ld      a, (PlayerInput)

        bit     5, a                                    ; Check whether fire pressed
        jp      nz, .FirePressed                        ; Jump if fire pressed

        res     5, a                                    ; Clear fire flag
        dec     a                                       ; Table offset starts at 0, PlayerInput starts at 1
        ld      e, a
        add     hl, de
        ld      a, (hl)
        ld      (ReticuleRotation), a                   ; Just set reticule to current player input
        jp      UpdateReticulePosition

.FirePressed
        res     5, a                                    ; Clear fire flag
        dec     a                                       ; Table offset starts at 0, PlayerInput starts at 1
        ld      e, a
        add     hl, de
        ld      a, (hl)

; 2. Check/Update reticule rotation value
        cp      c
        jp      z, UpdateReticulePosition              ; Jump if current rotation value = new rotation value

        cp      127
        jp      nc, .RotationSecondHalf                 ; Jump if new rotation value > 127

; ---- New rotation value in first half ----
        ld      b, a                                    ; Save new rotation value
        
; 1. Check whether we should immediately change to the new rotation value
        add     a, 128                                  ; Calculate opposite rotation value (128=half of rotation circle)        
        cp      c
        jp      z, .OppositeDirection                   ; Jump if new rotation value opposite of the current rotation value 

; 2. Check whether we should increment/decrement to the new rotation value 
        ld      a, b                                    ; Restore new rotation value
        cp      c
        jp      nc, .IncrementToNewRotation             ; Jump if current rotation value < new rotation value

        add     a, 128                                  ; Calculate opposite rotation value (128=half of rotation circle)        
        cp      c
        jp      nc, .DecrementToNewRotation             ; Jump if old rotation value < opposite of the current rotation value

        jp      .IncrementToNewRotation                 

; ---- New rotation value in second half ----
.RotationSecondHalf:
        ld      b, a                                    ; Save new rotation value
        
; 1. Check whether we should immediately change to the new rotation value
        sub     128                                     ; Calculate opposite rotation value (128=half of rotation circle)        
        cp      c
        jp      z, .OppositeDirection                   ; Jump if new rotation value opposite of the current rotation value 

; 2. Check whether we should increment/decrement to the new rotation value 
        ld      a, b                                    ; Restore new rotation value
        cp      c
        jp      c, .DecrementToNewRotation              ; Jump if current rotation value > new rotation value

        sub     128                                     ; Calculate opposite rotation value (128=half of rotation circle)        
        cp      c
        jp      c, .IncrementToNewRotation              ; Jump if old rotation value > opposite of the current rotation value

        jp      .DecrementToNewRotation                 

; New rotation value opposite of current rotation value, so set rotation immediately to new rotation
.OppositeDirection:
        ld      a, b
        ld      (ReticuleRotation), a
        jp      UpdateReticulePosition

.IncrementToNewRotation:
        ld      a, c                                    ; Restore current rotation value
        inc     a                                       ; Increment current rotation value
        inc     a
        ld      (ReticuleRotation), a

        jp      UpdateReticulePosition

.DecrementToNewRotation:
        ld      a, c                                    ; Restore current rotation value
        dec     a                                       ; Decrement new rotation
        dec     a
        ld      (ReticuleRotation), a

        jp      UpdateReticulePosition
*/

;-------------------------------------------------------------------------------------
; Sprites - Update Reticule Sprite Position Based on Rotation
; Parameters:
UpdateReticulePosition:
/*
; Obtain World Coordinates of rotation point
        ld      bc,(PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        ld      de, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)

; Obtain/Store Radius to rotation point
        ld      hl, Radius
        ld      a, (ReticuleRadius)
        ld      (hl), a

; Obtain Rotation value around rotation point
        ld      a, (ReticuleRotation)
        call    ObtainPosOnCircle

; Update reticule sprite values/attributes
        ld      iy, ReticuleSprAtt                      ; Destination - Sprite Attributes

        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), bc        
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), de

        push    de                                      ; Save y world coordinate

        ld      hl, bc                                  ; Obtain x world coordinate
        ld      de, (CameraXWorldCoordinate)
        call    ConvertWorldToDisplayCoord
*/
        ld      iy, ReticuleSprAtt                      ; Destination - Sprite Attributes

        ld      hl, (ReticuleSprite+S_SPRITE_TYPE.xPosition)
        ld      (iy+S_SPRITE_ATTR.x), l                 ; Attribute byte 1 - Low eight bits of the X position. The MSB is in byte 3 (anchor sprite only).

        ld      a, h
        cp      1
        jp      z, .RightSetmrx8                        ; Jump if MSB need to be set

        res     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

        jp      .SetY

.RightSetmrx8
        set     0, (iy+S_SPRITE_ATTR.mrx8)              ; Attribute byte 3 - MSB of the X Position

.SetY:
        ;pop     hl              ; Restore y world coordinate

        ;ld      de, (CameraYWorldCoordinate)
        ;call    ConvertWorldToDisplayCoord

        ld      a, (ReticuleSprite+S_SPRITE_TYPE.yPosition)
        ld      (iy+S_SPRITE_ATTR.y), a                 ; Attribute byte 2 - Low eight bits of the Y position. The MSB is in optional byte 5 (anchor sprite only).
        
        ret

;-------------------------------------------------------------------------------------
; Check Player Sprites for Collision - Keys/Friendly/Lockers
CheckPlayerSpriteCollision:
        ld      ix, PlayerSprite

; Clear player movement restriction flag
        ld      iy, FriendlySpritesStart
        ld      b, MaxFriendly+MaxKeys+MaxLockers;MaxCollectables+MaxKeys+MaxLockers       ; Number of sprite entries to search through
.FindActiveSprite:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jr      z, .NextSprite                          ; Jump if sprite not active

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .NextSprite                          ; Jump if sprite not visible

        push    bc;, ix, iy
        call    CheckCollision                          ; Check collision between sprites
        pop     bc;iy, ix, bc

.NextSprite
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite
        djnz    .FindActiveSprite

        ret
        
;-------------------------------------------------------------------------------------
; Check Collision
; Parameters:
; ix = Source sprite
; iy = Target sprite
; Return Values:
; a = 0 - Don't delete source sprite, 1 - Delete source sprite, 2 - Don't delete source sprite and stop checking against other sprites
CheckCollision:
/* - TODO
; Check whether target sprite is a spawning enemy
        bit     2, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .NotInRange                 ; Jump if target sprite is spawning

; Check whether target sprite is performing death animation
        bit     0, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .NotInRange                 ; Jump if target sprite is performing death animation
*/

; Obtain source and target 9-bit x coordinates
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      a, (ix+S_SPRITE_TYPE.BoundaryX)
        add     hl, a                           ; Add boundary x offset to source.x
        ld      bc, hl                          ; Backup source.x value
        
        ld      de, (iy+S_SPRITE_TYPE.XWorldCoordinate)
        ld      a, (iy+S_SPRITE_TYPE.BoundaryX)
        add     de, a                           ; Add boundary x offset to target.x
        ld      (BackupWord1), de                ; Backup target.x value

; Box Check 1 - source.x < target.x + width - LEFT
        ld      a, (iy+S_SPRITE_TYPE.BoundaryWidth)
        add     de, a                           ; Add width to target.x value

        or      a
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if source.x (hl) >= target.x + width (de)

; Box Check 2 - source.x + width > target.x - RIGHT
        ld      hl, bc                          ; Restore source.x value
        ld      a, (ix+S_SPRITE_TYPE.BoundaryWidth)
        add     hl, a                           ; Add boundary width to source.x

        ld      de, (BackupWord1)                ; Restore target.x value

        or      a
        ex      hl, de                          ; Swap target.x and source.x
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if target.x (hl) >= source.x + width (de)

; Obtain source and target 8-bit y coordinates
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      a, (ix+S_SPRITE_TYPE.BoundaryY)
        add     hl, a                           ; Add boundary y offset to source.y
        ld      bc, hl                          ; Backup source.x value

        ld      de, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ld      a, (iy+S_SPRITE_TYPE.BoundaryY)
        add     de, a                           ; Add boundary y offset to source.y
        ld      (BackupWord1), de                ; Backup target.x value
        
; Box Check 3 - source.y < target.y + height - TOP
        ld      a, (iy+S_SPRITE_TYPE.BoundaryHeight)
        add     de, a                           ; Add boundary height to target.y

        or      a
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if player.y (hl) >= enemy.y + height (de)

; Box Check 4 - source.y + height > target.y - BOTTOM
        ld      hl, bc                          ; Restore source.y

        ld      a, (ix+S_SPRITE_TYPE.BoundaryHeight)
        add     hl, a                           ; Add boundary height to source.y
        
        ld      de, (BackupWord1)                ; Restore target.y

        or      a
        ex      hl, de                          ; Swap target.x and source.x
        sbc     hl, de
        jp      nc, .NotInRange                 ; Jump if enemy.y (hl) >= player.y + height        

; Collision with sprite - Check Source Sprite - TODO
        ;bit     2, (ix+S_SPRITE_TYPE.SpriteType1)
        ;jr      nz, .EnemySource                ; Jump if source enemy 

        bit     7, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .PlayerSource                       ; Jump if source - Player 

        bit     6, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .EnemySource                        ; Jump if source - Enemy 

        bit     0, (ix+S_SPRITE_TYPE.SpriteType2)       ; Always place before Player Bullet check
        jp      nz, .EnemyBulletSource                  ; Jump if source - Enemy bullet 

        bit     4, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .PlayerProjectileSource                 ; Jump if source - Player bullet 

        ;;bit     4, (ix+S_SPRITE_TYPE.SpriteType3)
        ;;jp      nz, .PlayerProjectileSource                 ; Jump if source - Bomb

        bit     6, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .FriendlySource                     ; Jump if source - Friendly Following

        ;jp      .CheckSides                     ; Jump if not player or enemy

; Check whether routine called from title screen        
        ld      a, (GameStatus2)
        bit     1, a
        jp      nz, .TitleReticuleHitUI         ; Jump if reticule hit UI

; Not on title screen
        ld      a, 0                            ; Return value - Don't destroy sprite

        ret

; Title Screen - Reticule hit UI
.TitleReticuleHitUI:
        ld      a, 1                            ; Return value

        ret

; Enemy hit sprite
.EnemySource:
; Check for existing enemy to player collision 
        ld      a, (ix+S_SPRITE_TYPE.SprCollision)
        cp      1
        jp      z, .ExistingEnemyCollision             ; Jump if existing collision exists

; - New enemy to player collision
        call    GetTargetCollisionSides                 ; Check/set player collision sides

        ld      a, 1
        ld      (ix+S_SPRITE_TYPE.SprCollision), a      ; Set enemy collision flag
        
        jp      .DamagePlayer

; - Existing enemy to player collision - Update player collision sides flag
.ExistingEnemyCollision:
        ld      a, (ix+S_SPRITE_TYPE.SprContactSide)    ; Enemy flag
        or      (iy+S_SPRITE_TYPE.SprContactSide)       ; Combine enemy and player flags

        ld      (iy+S_SPRITE_TYPE.SprContactSide), a    ; Player flag - Set collision sides flag

.DamagePlayer:
; - Damage player
        ld      a, (ix+S_SPRITE_TYPE.Damage)
        ld      b, a
        call    PlayerTakeDamage

        ld      a, 0                            ; Set enemy not to be destroyed
        ret

; Player hit sprite
.PlayerSource:
        bit     0, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .HitKey                     ; Jump if collision with key

        bit     7, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .HitFriendly                ; Jump if collision with friendly

        bit     4, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .HitLocker                  ; Jump if collision with locker + collectable

        ;;bit     2, (iy+S_SPRITE_TYPE.SpriteType4)
        ;;jp      nz, .UpdateEnergy               ; Jump if collision with collectable

        ret

.HitKey:
; Play audio effect
        push    af, ix

        ld      a, AyFXPickupCollLockKey
        call    AFX2Play

        pop     ix, af

; Check key type
        bit     7, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      z, .KeyType2                    ; Jump if key type2

; Key Type1
        ld      hl, PlayerType1Keys
        inc     (hl)

; Update key HUD values
        ld      b, HUDKeyValueDigits
        ld      a, (HUDKeyValueSpriteNum)
        ld      c, a
        ld      a, (hl)
        ld      de, $0000                       ; Do not convert string
        call    UpdateHUDValueSprites              ; Update HUD values

        jp      .DeleteKey

; Key Type2
.KeyType2:
        ld      hl, PlayerType2Keys
        inc     (hl)

; Delete key sprite
.DeleteKey:
; Trigger Condition - Update TriggerTarget
        ld      bc, (iy+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      hl, bc
        push    ix
        call    UpdateTriggerTargetData
        pop     ix

; Delete key
        push    ix
        call    DeleteSprite
        pop     ix

        ret

.HitFriendly:
        bit     6, (iy+S_SPRITE_TYPE.SpriteType3)
        ret     nz              ; Return if friendly already following player

; Play audio effect
        push    af, ix

        ld      a, AyFXFriendlyEnable
        call    AFX2Play

        pop     ix, af

; Set friendly to follow player
        set     6, (iy+S_SPRITE_TYPE.SpriteType3)

/*
; Reset Previous Movement flag to ensure sprite pattern updated
        ld      (iy+S_SPRITE_TYPE.Movement2), 0
*/
        ret

.HitLocker:
; Check status of locker
        bit     1, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .UpdateEnergy               ; Jump if energy locker/collectable

        jp      .UpdateFreeze

.UpdateEnergy:
; Energy Pickup
; - Check whether player already has max energy
        ld      a, (MaxPlayerEnergy)
        ld      b, a
        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        cp      b
        ret     z                               ; Return if player already has max energy

; - Otherwise update energy
; Play audio effect
        push    af, ix

        ld      a, AyFXPickupCollLockKey
        call    AFX2Play

        pop     ix, af

        ld      b, (iy+S_SPRITE_TYPE.Energy)
        call    PlayerUpdateEnergy

        push    ix
        call    DeleteSprite
        pop     ix

        ret

/* - No longer used
.UpdateBullets:
; Bullet Pickup
; - Check whether player already has max bullet upgrades
        ld      hl, (BulletUpgradeTableRef)
        ld      bc, BulletUpgradeTableEnd
        sbc     hl, bc
        ret     z                               ; Return if player already has all bullet upgrades

; - Otherwise update bullet level
        push    iy
        call    PlayerUpdateBulletType
        pop     iy

        push    ix
        call    DeleteSprite
        pop     ix

        ret
*/

.UpdateFreeze:
; - Check whether player already has max freeze time
        ld      a, (PlayerFreezeTime)
        cp      PlayerFreezeMax
        ret     z                               ; Return if player already has max freeze time

; - Otherwise update player freeze time
; Play audio effect
        push    af, ix

        ld      a, AyFXPickupCollLockKey
        call    AFX2Play

        pop     ix, af

        ld      b, (iy+S_SPRITE_TYPE.EnergyReset)
        call    PlayerUpdateFreeze

        push    ix
        call    DeleteSprite                    
        pop     ix

        ret

; ====== Player Projectile hit target - Calculate damage ======
.PlayerProjectileSource:
        bit     3, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .ActiveEnemy                         ; Jump if enemy not disabled or exploding

; Already disabled enemy - Turret, Terminator
        set     7, (ix+S_SPRITE_TYPE.SpriteType4)       ; Set player bullet flag - Bullet hit disabled enemy

; - Set/Reset enemy delaycounter to ensure disabled enemy stays disabled whilst being hit
        ld      a, (iy+S_SPRITE_TYPE.EnemyDisableTimeOut)
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a      ; Set disable timeout

; - Set bullet to position of enemy
        ld      bc, (iy+S_SPRITE_TYPE.XWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc
        ld      bc, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), bc

        jp      .DestroyProjectile

.ActiveEnemy:
; Locker - Check for locker
        bit     4, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .BulletHitLocker                    ; Jump if target is a locker (not collectable)

; Waypoint Enemy - Check for Waypoint Enemy
        bit     3, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .DestroyProjectile                  ; Jump if waypoint enemy

; Check for invulnerable enemy
        ld      a, (iy+S_SPRITE_TYPE.InvulnerableCounter)
        cp      0
        jp      nz, .BulletHitInvulnerableEnemy         ; Jump if enemy currently invulnerable

.CheckDamage:
; Other - Check projectile damage and enemy energy
        ld      a, (iy+S_SPRITE_TYPE.Energy)
        cp      (ix+S_SPRITE_TYPE.Damage)
        jp      nc, .DamageNotGreater                   ; Jump if damage <= energy

; - Damage > Energy
        ld      b, a                                    ; b = Energy
        ld      a, (ix+S_SPRITE_TYPE.Damage)            ; a = Damage
        sub     b

        ld      (ix+S_SPRITE_TYPE.Damage), a            ; Damage -= energy
        ld      (iy+S_SPRITE_TYPE.Energy), 0            ; Energy = 0

        ld      a, 2                                    ; Return value - Don't continue processing bullet
        ret

; - Damage <= Energy
.DamageNotGreater:
        sub     (ix+S_SPRITE_TYPE.Damage)
        ld      (iy+S_SPRITE_TYPE.Energy), a            ; Energy -= damage
        ld      (ix+S_SPRITE_TYPE.Damage), 0            ; Damage = 0

        ld      a, 1                                    ; Return value - Delete bullet

; - Check whether enemy Flee flag is set i.e. Enemy can flee
        bit     5, (iy+S_SPRITE_TYPE.SpriteType5)
        ret     z                                               ; Return if enemy cannot flee

; Set Flee settings
        set     4, (iy+S_SPRITE_TYPE.SpriteType5)               ; Set FleeStatus flag

        ld	a, (iy+S_SPRITE_TYPE.EnemyDisableTimeOut)
	ld	(iy+S_SPRITE_TYPE.DelayCounter), a              ; Set flee timeout counter

; - Set invulnerability settings
        set     3, (iy+S_SPRITE_TYPE.SpriteType5)               ; Set Spawn flag

        ld      a, SpawnDelayDamageTime
        ld      (iy+S_SPRITE_TYPE.InvulnerableCounter), a       ; Set invulnerable timeout counter

        res     7, (iy+S_SPRITE_TYPE.SpriteType5)               ; Reset don't move in next frame flag

        ld      a, 1                                            ; Return value - Delete bullet

        ret

.DestroyProjectile:
        ld      a, 1                                    ; Return value - Destroy bullet sprite
        ret

.BulletHitLocker:
; - Check type of projectile
        ;;bit     4, (ix+S_SPRITE_TYPE.SpriteType3)
        ;;jp      z, .BypassDelayUpdate                   ; Jump if not bomb

        ;;ld      (iy+S_SPRITE_TYPE.animationDelay), 0    ; Otherwise allow bomb to change locker to next item

;;.BypassDelayUpdate:
; - Check whether locker contains bullet upgrade
        ;;bit     1, (iy+S_SPRITE_TYPE.SpriteType4)
        ;;jp      z, .UpdatePattern                      ; Jump if locker doesn't contain bullet upgrade

/* - No longer used
; - Locker contains bullet upgrade - Check whether we should continue to display bullet upgrades
        ld      a, (iy+S_SPRITE_TYPE.patternCurrent)
        cp      LockerBulletsPattern-1                  ; Check for pattern before bullet pattern
        jp      nz, .UpdatePattern                      ; Jump if next pattern is not bullet pattern
        
        ld      hl, (BulletUpgradeTableRef)
        ld      bc, BulletUpgradeTableEnd
        sbc     hl, bc
        jp      nz, .UpdatePattern                      ; Jump if player does not have all bullet upgrades

; - Player has all bullet upgrades, so change to locker without bullet upgrades
        ld      hl, LockerNoBulletPatterns
        ld      (iy+S_SPRITE_TYPE.patternRange), hl
        res     1, (iy+S_SPRITE_TYPE.SpriteType4)
*/
; - Toggle through locker pattern animation
;;.UpdatePattern:
; - Check for locker collectable
        bit     2, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .BulletHitLockerCollectable         ; Jump if target is a locker collectable

; - Locker
        bit     1, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      nz, .LockerSwitchToFreeze

; --- Set to energy locker
        set     1, (iy+S_SPRITE_TYPE.SpriteType4)

        ld      hl, LockerEnergyPatterns

        jp      .UpdateLocker

; --- Set to freeze locker
.LockerSwitchToFreeze:
        res     1, (iy+S_SPRITE_TYPE.SpriteType4)

        ld      hl, LockerFreezePatterns

.UpdateLocker:
        push    ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, hl                                  ; Sprite pattern range - Update
        call    UpdateSpritePattern

        pop     ix

        ld      a, 1                                    ; Return value - Destroy bullet sprite
        ret

.BulletHitInvulnerableEnemy:
        ld      a, 1                                    ; Return value - Destroy bullet sprite
        ret

.BulletHitLockerCollectable:
        ld      a, 0                                    ; Return value - Do not destroy bullet sprite
        ret

; ====== Enemy Bullet hit target - Calculate damage ======
.EnemyBulletSource:
; - Don't take damage if turret
        bit     5, (iy+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .BypassDamage                       ; Jump if target==Turret

; - Don't take damage if waypoint enemy
        bit     3, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassDamage                       ; Jump if target==WayPoint enemy

; - Take damage if active target
        bit     3, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .ActiveTarget                        ; Jump if disabled target

; - Set/Reset enemy delaycounter to ensure disabled enemy stays disabled whilst being hit
        ld      a, (iy+S_SPRITE_TYPE.EnemyDisableTimeOut)
        ld      (iy+S_SPRITE_TYPE.DelayCounter), a      ; Set disable timeout

; - Set bullet to position of enemy
        ld      bc, (iy+S_SPRITE_TYPE.XWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc
        ld      bc, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), bc

        jp      .BypassDamage

.ActiveTarget:
        ld      a, (ix+S_SPRITE_TYPE.Damage)
        ld      b, a

        bit     7, (iy+S_SPRITE_TYPE.SpriteType1)
        call    nz, PlayerTakeDamage                    ; Call if target - Player 

        bit     6, (iy+S_SPRITE_TYPE.SpriteType3)
        call    nz, FriendlyTakeDamage                  ; Call if target - Friendly Following

        ld      a, 1                                    

        bit     6, (iy+S_SPRITE_TYPE.SpriteType1)
        ret     z                                       ; Return if not enemy i.e. Player or Friendly

; - Enemy target
; Check projectile damage and enemy energy
        ld      a, (iy+S_SPRITE_TYPE.Energy)
        cp      (ix+S_SPRITE_TYPE.Damage)
        jp      nc, .EnemyDamageNotGreater              ; Jump if damage <= energy

; - Damage > Energy
        ld      b, a                                    ; b = Energy
        ld      a, (ix+S_SPRITE_TYPE.Damage)            ; a = Damage
        sub     b

        ld      (ix+S_SPRITE_TYPE.Damage), a            ; Damage -= energy
        ld      (iy+S_SPRITE_TYPE.Energy), 0            ; Energy = 0

        set     3, (iy+S_SPRITE_TYPE.SpriteType4)       ; Player did not destroy, so don't allocate points

        ld      a, 2                                    ; Return value - Don't continue processing bullet
        ret

; - Damage <= Energy
.EnemyDamageNotGreater:
        sub     (ix+S_SPRITE_TYPE.Damage)
        ld      (iy+S_SPRITE_TYPE.Energy), a            ; Energy -= damage
        ld      (ix+S_SPRITE_TYPE.Damage), 0            ; Damage = 0

        ld      a, 0
        cp      (iy+S_SPRITE_TYPE.Energy)
        jp      nz, .BypassDamage                       ; Jump if enemy not destroyed

        set     3, (iy+S_SPRITE_TYPE.SpriteType4)       ; Player did not destroy, so don't allocate points

.BypassDamage:
        ld      a, 1                                    ; Return value - Destroy bullet
        ret

; Friendly hit player
.FriendlySource:
        ld      a, 1
        ld      (ix+S_SPRITE_TYPE.SprCollision), a

        ret

.NotInRange:
; Reset sprite collision flags
        ld      a, 0                                    ; Return value - Don't destroy sprite
        ld      (ix+S_SPRITE_TYPE.SprCollision), a
        ld      (ix+S_SPRITE_TYPE.SprContactSide), a
        
        ret

;-------------------------------------------------------------------------------------
; Check and update sprite rotation value with new value
; Parameters:
; ix = Turret sprite storage memory address offset
; a = New rotation value
; Return:
CheckUpdateSpriteRotation:
        cp      (ix+S_SPRITE_TYPE.Rotation)
        ret     z                               ; Return if current rotation value = new rotation value

; Check turret type
        bit     4, (ix+S_SPRITE_TYPE.SpriteType2)       
        jp      nz, .UpTurret                           ; Jump if turret facing up

        bit     3, (ix+S_SPRITE_TYPE.SpriteType2)       
        jp      nz, .DownRightTurret                    ; Jump if turret facing down
        
        bit     2, (ix+S_SPRITE_TYPE.SpriteType2)       
        jp      nz, .LeftTurret                         ; Jump if turret facing left

        bit     1, (ix+S_SPRITE_TYPE.SpriteType2)       
        jp      nz, .DownRightTurret                    ; Jump if turret facing right

; - Rotating Turret i.e. Non-Directional Turret
        bit     5, (ix+S_SPRITE_TYPE.SpriteType4)       
        jp      nz, .DecrementRotation                  ; Jump if anti-clockwise flag set

        jp      .IncrementRotation

; --- Turret Facing Up ---
.UpTurret:
; - Check current value half
        ld      b, a                            ; Backup new rotation value

        ld      a, 64 
        cp      (ix+S_SPRITE_TYPE.Rotation)       
        jp      nc, .UpCurrentRightHalf         ; Jump if current value <= 64 (90 degrees) : Current = Right half

; - Up Current value Left Half
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        cp      b
        jp      c, .IncrementRotation                 ; Jump if new value > current value : Current/New = Left half

; - Check new value half
        ld      a, 191
        cp      b
        jp      c, .DecrementRotation                 ; Jump if new value > 191 (89 degrees) : Current/New = Left half 

        jp      .IncrementRotation                    ; Otherwise decrement : Current/New = Left half 

; - Up Turret Right Half
.UpCurrentRightHalf:
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        cp      b
        jp      c, .UpNewCheckHalf                      ; Jump if new value > current value

        jp      .DecrementRotation                    ; Otherwise decrement current value : Current/New = Right half

; - Check new value half
.UpNewCheckHalf:
        ld      a, 64 
        cp      b       
        jp      nc, .IncrementRotation                ; Jump if new value <= 64 (90 degrees) : Current/New = Right half

        jp      .DecrementRotation                    ; Otherwise decrement : Current = Right half, New = Left half

; --- Turret Facing Left ---
.LeftTurret:
; - 0 rotation New Value Check - Always increment if new value = 0
        cp      0
        jp      z, .IncrementRotation           ; Jump if new value = 0

; - 0 rotation Current Value Check - Always decrement if current value = 0
        ld      b, a                                    ; Save new value
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        cp      0
        jp      nz, .LeftStandardCheck                  ; Jump if current value != 0

        ld      a, b                                    ; Restore new value
        jp      .DecrementRotation                      

.LeftStandardCheck:
; - Check whether turret in range
        ld      a, (TurretInRange)
        cp      1
        jp      z, .LeftNormalRotation                 ; Jump if turret in range i.e. Keep normal rotation logic

; - Turret not in range - Check whether turret in Top-Right quarter
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        cp      65
        jp      c, .DecrementRotation                  ; Jump if current value < 65 i.e. Top-Right quarter so change rotation logic

.LeftNormalRotation:
; - Standard Check
        ld      a, b                                    ; Restore new value
        ld      b, (ix+S_SPRITE_TYPE.Rotation)
        cp      b
        jp      c, .DecrementRotation                   ; Jump if current value > new value

        jp      .IncrementRotation                      ; Otherwise decrement

; --- Turret Facing Down/Right ---
.DownRightTurret:
; - Check whether turret in range
        ld      b, a                                    ; Save target rotation value

        ld      a, (TurretInRange)
        cp      1
        jp      z, .RightNormalRotation                 ; Jump if turret in range i.e. Keep normal rotation logic

; - Turret not in range - Check whether turret in Top-Left quarter
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        cp      200
        jp      nc, .IncrementRotation                  ; Jump if current value >= 200 i.e. Top-Left quarter so change rotation logic

.RightNormalRotation:
        ld      a, b                                    ; Restore target rotation value

        ld      b, (ix+S_SPRITE_TYPE.Rotation)
        cp      b
        jp      c, .DecrementRotation                   ; Jump if current value > new value

        jp      .IncrementRotation                      ; Otherwise decrement

; Decrement current rotation value
.DecrementRotation:
; - Save current last known good rotation value
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        ld      (TurretPreviousRotation), a

        dec     (ix+S_SPRITE_TYPE.Rotation)

        bit     1, (ix+S_SPRITE_TYPE.Speed)
        ret     z                               ; Return if turret not double speed (speed != 2)

        dec     (ix+S_SPRITE_TYPE.Rotation)
        ret

; - Increment current rotation value
.IncrementRotation:
; - Save current last known good rotation value
        ld      a, (ix+S_SPRITE_TYPE.Rotation)
        ld      (TurretPreviousRotation), a

        inc     (ix+S_SPRITE_TYPE.Rotation)

        bit     1, (ix+S_SPRITE_TYPE.Speed)
        ret     z                               ; Return if turret not double speed (speed != 2)

        inc     (ix+S_SPRITE_TYPE.Rotation)
        ret

;-------------------------------------------------------------------------------------
; Calculate Distance Vector between Player and Turret (player (x,y) - enemy (x,y))
; Note: If x or y distance >= 256, then x or y distance set to 255
; Parameters:
; ix = Turret sprite storage memory address offset
; Return:
; b = x - Before decimal point
; c = x - After decimal point
; d = y - Before decimal point
; e = y - After decimal point
; PlayerToTurretPosition
ObtainTurretDistanceVector:
        ld      d, 0                                                    ; Player to turret position - Assume player below/right and not level 

.GetX:
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)       ; Player x world coordinate
        add     hl, 8                                                   ; Point to middle

        ld      bc, (ix+S_SPRITE_TYPE.RotPointX)                        ; Enemy x world coordinate
        add     bc, 8                                                   ; Turret - Point to middle

.CalcX:
        sub     hl, bc
        jp      z, .PlayerXLevel
        jp      p, .CheckXRange                                         ; Jump if positive value

; Negative - Convert to positive value
	ld	bc, hl
	ld	hl, 0

	sub	hl, bc		                                        ; 0 - -value

        set     0, d                                                    ; Player to turret position - Set left

; Check Range  hl <= 255
.CheckXRange:
	ld	a, h
	cp	0
	jp      z, .GetY        ; Jump if value <= 255

	ld	hl, 255		; Otherwise set value to 255

        jp      .GetY

.PlayerXLevel:
        set     3, d                                                    ; Player to turret position - Set X Level

.GetY:
        push    hl

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)       ; Player y world coordinate
        add     hl, 8                                                   ; Point to middle

        ld      bc, (ix+S_SPRITE_TYPE.RotPointY)                        ; Enemy y world coordinate
        add     bc, 8                                                   ; Turret - Point to middle

.CalcY:
        sub     hl, bc
        jp      z, .PlayerYLevel                                        ; Jump if values the same
        jp      p, .CheckYRange                                         ; Jump if postive value

; Negative - Convert to positive value
	ld	bc, hl
	ld	hl, 0

	sub	hl, bc		                                        ; 0 - -value

        set     1, d                                                    ; Player to turret position - Set Up

; Check Range  hl <= 255
.CheckYRange:
	ld	a, h
	cp	0
	jp      z, .SetReturnValues                                     ; Jump if value <= 255

	ld	hl, 255		                                        ; Otherwise set value to 255

        jp      .SetReturnValues

.PlayerYLevel:
        set     2, d                                                    ; Player to turret position - Set Y Level

.SetReturnValues:
        ld      a, d
        ld      (PlayerToTurretPosition), a                             ; Store player to turret position

        pop     de
        ld      b, e                                                    ; x - Before decimal point
        ld      c, 0                                                    ; x - After decimal point
        
        ld      d, l                                                    ; y - Before decimal point
        ld      e, 0                                                    ; y - After decimal point

        ret

;-------------------------------------------------------------------------------------
; Calculate Distance Vector between Reticule and Player (reticule (x,y) - player (x,y))
; Parameters:
; Return:
; b = x - Before decimal point
; c = x - After decimal point
; d = y - Before decimal point
; e = y - After decimal point
; ReticuleToPlayerPosition
ObtainReticuleDistanceVector:
        ld      d, 0                                                    ; Reticule to player position - Assume reticule below and to right

.GetX:
        ld      hl, (ReticuleSprite+S_SPRITE_TYPE.xPosition)            ; Reticule x world coordinate
        add     hl, 8                                                   ; Point to middle

        ld      bc, (PlayerSprite+S_SPRITE_TYPE.xPosition)              ; Player x world coordinate
        add     bc, 8                                                   ; Point to middle

.CalcX:
        sub     hl, bc
        jp      p, .GetY                                                ; Jump if postive value

        ld      a, l
        neg                                                             ; Otherwise convert to positive value
        ld      l, a    

        set     0, d                                                    ; Reticule to player position - Set left
        
.GetY:
        push    hl

        ld      b, 0
        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)               ; Player y world coordinate
        add     8                                                       ; Point to middle
        ld      c, a

        ld      h, 0
        ld      a, (ReticuleSprite+S_SPRITE_TYPE.yPosition)             ; Reticule y world coordinate
        add     8                                                       ; Point to middle
        ld      l, a

.CalcY:
        sub     hl, bc
        jp      p, .SetReturnValues                                     ; Jump if postive value

        ld      a, l
        neg                                                             ; Otherwise convert to positive value
        ld      l, a    

        set     1, d                                                    ; Reticule to player position - Set above

.SetReturnValues:
        ld      a, d
        ld      (ReticuleToPlayerPosition), a                           ; Store player to turret position

        pop     de
        ld      b, e                                                    ; x - Before decimal point
        ld      c, 0                                                    ; x - After decimal point
        

        ld      d, l                                                    ; y - Before decimal point
        ld      e, 0                                                    ; y - After decimal point

        ret

;-------------------------------------------------------------------------------------
; Calculate Distance Vector between Enemy and Player (player (x,y) - enemy (x,y))
; Note: If x or y distance >= 256, then x or y distance set to 255
; Parameters:
; ix = Enemy Sprite Data
; Return:
; b = x - Before decimal point
; c = x - After decimal point
; d = y - Before decimal point
; e = y - After decimal point
; PlayerToEnemyPosition
ObtainPlayerDistanceVector:
        ld      d, 0                                                    ; Player to enemy position - Assume player below and to right

.GetX:
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)       ; Player x world coordinate
        add     hl, 8                                                   ; Point to middle

        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)                 ; Enemy x world coordinate
        add     bc, 8                                                   ; Point to middle

.CalcX:
        sub     hl, bc
        jp      z, .PlayerXLevel
        jp      p, .CheckXRange                                         ; Jump if positive value

; Negative - Convert to positive value
	ld	bc, hl
	ld	hl, 0

	sub	hl, bc		                                        ; 0 - -value

        set     0, d                                                    ; Player to enemy position - Set left

; Check Range  hl <= 255
.CheckXRange:
	ld	a, h
	cp	0
	jp      z, .GetY        ; Jump if value <= 255

	ld	hl, 255		; Otherwise set value to 255

        jp      .GetY

.PlayerXLevel:
        
.GetY:
        push    hl

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)       ; Player y world coordinate
        add     hl, 8                                                   ; Point to middle

        ld      bc, (ix+S_SPRITE_TYPE.YWorldCoordinate)                 ; Enemy y world coordinate
        add     bc, 8                                                   ; Enemy - Point to middle

.CalcY:
        sub     hl, bc
        jp      z, .PlayerYLevel                                        ; Jump if values the same
        jp      p, .CheckYRange                                         ; Jump if postive value

; Negative - Convert to positive value
	ld	bc, hl
	ld	hl, 0

	sub	hl, bc		                                        ; 0 - -value

        set     1, d                                                    ; Player to Enemy position - Set Up

; Check Range  hl <= 255
.CheckYRange:
	ld	a, h
	cp	0
	jp      z, .SetReturnValues                                     ; Jump if value <= 255

	ld	hl, 255		                                        ; Otherwise set value to 255

        jp      .SetReturnValues

.PlayerYLevel:

.SetReturnValues:
        ld      a, d
        ld      (PlayerToEnemyPosition), a                              ; Store enemy to player position

        pop     de
        ld      b, e                                                    ; x - Before decimal point
        ld      c, 0                                                    ; x - After decimal point
        
        ld      d, l                                                    ; y - Before decimal point
        ld      e, 0                                                    ; y - After decimal point

        ret

;-------------------------------------------------------------------------------------
; Calculate whether SpawnPoint/enemy in range of Player (player (x,y) - spawnpoint/enemy (x,y))
; Parameters:
; bc = SpawnPoint/Enemy x World Coordinate
; de = SpawnPoint/Ememy y world Coordinate
; hl = Range
; Return:
; a = 0 (Not in range), 1 (in range)
CheckEntityInRange:
        ld      (BackupWord1), hl               ; Save range

; Check X World Co-ordinates
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)       ; Player x world coordinate
        add     hl, 8                                                   ; Point to middle

        add     bc, 8                                                   ; Enemy x world coordinate --- Point to middle

.CalcX:
        sub     hl, bc
        jp      p, .CheckXRange                                         ; Jump if postive value

; - Convert negative number to positive number
        xor     a
        sub     l
        ld      l, a
        sbc     a, a
        sub     h
        ld      h, a
        
; Check whether spawnpoint in x range of player
.CheckXRange:
        ld      bc, (BackupWord1)               ; Restore range
        inc     bc
        sub     hl, bc
        jp      c, .GetY                                ; Jump if hl < bc (spawnpoint in x range)

        ld      a, 0                                    ; Spawnpoint not in range of player
        ret

; Check Y World Co-ordinates
.GetY:
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)       ; Player y world coordinate
        add     hl, 8                                                   ; Point to middle

        ld      bc, de                                                  ; Enemy y world coordinate
        add     bc, 8                                                   ; Point to middle

.CalcY:
        sub     hl, bc
        jp      p, .CheckYRange                         ; Jump if postive value

; - Convert negative number to positive number
        xor     a
        sub     l
        ld      l, a
        sbc     a, a
        sub     h
        ld      h, a

; Check whether spawnpoint in y range of player
.CheckYRange:
        ld      a, 1                                    ; Assume spawnpoint in y range to player

        ld      bc, (BackupWord1)                       ; Restore range
        inc     bc
        sub     hl, bc
        ret     c                                       ; Return if hl < bc (spawnpoint in y range)

        ld      a, 0                                    ; Spawnpoint not in range of player
        ret


/* No longer used
;-------------------------------------------------------------------------------------
; Update player sprite definition with animation delay based on player energy
; Params:
; Return:
; Update player sprite definition
UpdatePlayerAnimationDelay:
        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        call    a_div_10                                ; Divide energy by 10 for animation delay table lookup
                                                        ; Return a = table offset
        ld      hl, PlayerAnimationDelay
        add     hl, a
        ld      a, (hl)                                 ; Get animation delay from table

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.patternRange)
        ld      (hl), a                                 ; Update player animation definition with new value

        ret
*/

;-------------------------------------------------------------------------------------
; Calculate rotation value of reticule to player
; Params:
; Return:
; a = Rotation value
ReticuleToPlayerRotation:
        call    ObtainReticuleDistanceVector            ; Return bc = x value, de = y value
        call    BC_Div_DE_88                            ; de = result
        call    ConvertTangentToRotation             ; a = Rotation value

; - Check reticule to player position and update rotation value based on whether reticule above/below/left/right
        ld      b, a                                    ; Save rotation value
        ld      d, 0                                    ; Default offset - Assuming reticule in quarter1 i.e. above/right

        ld      a, (ReticuleToPlayerPosition)
        cp      %00000000
        jp      z, .Quarter2

        cp      %00000001
        jp      z, .Quarter3

        cp      %00000011
        jp      z, .Quarter4                            

; Quarter1
        ld      a, b                                    ; Restore rotation value
        ret                                             ; No offset required

.Quarter2:
        ld      a, 128                                  
        sub     b                                       ; 180 degrees - angle
        ret                                             ; No offset required

.Quarter3:
        ld      a, 128
        add     b                                       ; 180 degrees + angle
        ret                                             ; No offset required

.Quarter4:
        ld      a, 255
        sub     b                                       ; 360 degrees - angle

	ret

;-------------------------------------------------------------------------------------
; Setup Sprite Text - Import Text sprite patterns and reset sprite attributes
; Parameters
SetupTextSprites:
; Import Sprite Palette and Patterns
; - Sprite Palette
        ld      a, $$SpriteTextPalette  ; Memory bank (8kb) containing sprite palette data        
        ld      hl, SpriteTextPalette   ; Address of first byte of sprite palette data
        call    SetupSpritePalette
        
; - Upload Sprite Patterns
        ld      d, $$SpriteText         ; Memory bank (8kb) containing sprite data 0-127 - 8kb (0=No memory bank) - 4bit sprites
        ld      e, 0                    ; 0=No memory bank
        ld      hl, SpriteText          ; Address of first byte of sprite patterns
        ld      ixl, 32                 ; Number of sprite patterns to upload; each pattern slot holds 2 x 4 bit sprites
        call    UploadSpritePatterns

; Disable/Hide all sprites 
; - Reset sprites and attributes - Need to run to ensure at least one non-zero attribute is defined
        ld      a, MaxSprites
        call    ResetSprites

        ret

;-------------------------------------------------------------------------------------
; Print String via Sprites
; Note: Title Sprites only - Normally used for spawning text, but can also be used to spawn animated
;       sprites within a text message. The last sprite letter is "Z" ASCII 90; all animated sprites
;       will be represented from 91+ ASCII, and will be spawned as animated sprites. Refer to
;       ZX-Sprites spreadsheet for ASCII sprite references. 
;       The value after the non-text sprite value is the S_SPRITE_PATTERN offset reference
;       e.g. db "THIS IS SOME TEXT ", 102, 0, " THIS IS SOME MORE TEXT", 0
;       This will spawn the sprite with ASCII reference 102 as the first pattern,
;       and then assign the pattern reference TitleAnimatedPatterns + 0*S_SPRITE_PATTERN
;       Regardless of whether you are spawning all text sprites or a combination including
;       animated sprites, the passed text string needs to terminate with 0
; Parameters
; a = %VVVV---M ---> M=0 - Normal, 1 - Magnify, VVVV=Vertical offset
; hl = xxyy block position
; ix = Text to display suffixed by 0
; Return:
PrintSpriteText:
        ld      (BackupByte), a         ; Save magnify status

        ld      (BackupWord2), hl       ; Save XXYY position

; Loop through text
.SpriteTextLoop:
        ld      a, (ix)                 ; Obtain text
        cp      0
        jp      z, .UpdateSpriteAttribs ; Jump if text terminator

        push    ix                      ; Save text pointer

        push    af                      ; Save text value

; Spawn text sprite
        ld      ix, Key1SprType         ; Ignore type, only used to assist with spawning
        ld      iy, Sprites

; - Check whether we are spawning a title scroll sprite
        ld      b, 0                    ; Assume spawn from first sprite attribute position
        ld      a, (GameStatus3)
        bit     5, a
        jp      z, .SpawnSprite         ; Jump if not spawning title scroll sprite

        ld      iy, TitleScrollSpritesStart 
        ld      b, TitleScrollSpritesAttStart   ; Set spawn position for sprite attribute position 
.SpawnSprite:
        ld      a, b                    ; Spawn sprite attribute position
        ld      hl, (BackupWord2)       ; Restore XXYY Block position
        ld      b, MaxSprites
        call    SpawnNewSprite

        pop     af                      ; Restore text value

        ld      b, a                    ; Save text value

; Change sprite pattern and make sprite visible        
; - Convert ASCII value to sprite pattern value 
        sub     ASCIIDelta              ; Set ASCII values to start from 0 and not 32 
        sra     a
        
        jp      nc, .LessThan64         ; Jump if carry not set i.e. value even

        add     64                      ; Value odd so update value

.LessThan64:
        ld      (ix+S_SPRITE_TYPE.patternCurrent), a

; - Check whether spawning letter sprite i.e. non-animated sprite
;   Note: Animated sprites start after ASCII letter "Z"
        push    af                      ; Save updated sprite pattern

        ld      a, b                    ; Restore text value
        cp      "Z"+1
        jp      c, .SpawnLetter         ; Jump if spawning letter

; - Configure animated sprite
        ld      a, (GameStatus3)
        set     4, a
        ld      (GameStatus3), a                        ; Set animated text sprite flag

        set     7, (ix+S_SPRITE_TYPE.SpriteType3)       ; Set friendly flag to enable animation for title sprites

        pop     af                                      ; Restore updated sprite pattern

        ld      bc, ix                                  ; Save sprite pointer

        pop     ix                                      ; Restore text pointer

        inc     ix                                      ; Point to pattern offset value

        ld      d, (ix)                                 ; Obtain pattern offset value
        ld      e, S_SPRITE_PATTERN
        mul     d, e                                    
        ld      hl, TitleAnimatedPatterns
        add     hl, de                                  ; Calculate pattern address

        push    ix                                      ; Save text pointer

        ld      ix, bc                                  ; Restore sprite pointer
        ld      (ix+S_SPRITE_TYPE.patternRange), hl

        jp      .BypassTextSprite

.SpawnLetter:
; - Check whether text to be displayed on title screem
        pop     af                                      ; Restore updated sprite pattern

        ld      bc, SpriteTextPatterns                  ; Assume not title text

        push    af

        ld      a, (GameStatus2)
        bit     1, a
        jp      z, .NotTitleText                        ; Jump if not on title screen

        ld      bc, TitleSpriteTextPatterns             ; Title text

.NotTitleText:
        ld      (ix+S_SPRITE_TYPE.patternRange), bc     ; Assign text pattern; used for palette offset

        pop     af

.BypassTextSprite:
        push    iy

        ld      iy, ix
        call    UpdateSpritePattern4BitStatus

        pop     iy

        call    DisplayHUDSprite

; - Check whether we're spawning a title text scroll sprite
        ld      a, (GameStatus3)
        bit     5, a
        jp      z, .NotScrollText

        set     6, (ix+S_SPRITE_TYPE.SpriteType5)       ; Set Ignore flag; used to ensure text scroll sprites aren't 
                                                        ; reset between title screens

.NotScrollText:
        pop     ix

        ld      hl, (BackupWord2)       ; Restore XXYY position

; - Check and add vertical offset
        ld      a, (BackupByte)

        and     %11110000
        swapnib
        ld      b, a
        ld      a, (iy+S_SPRITE_ATTR.y)
        add     a, b
        ld      (iy+S_SPRITE_ATTR.y), a

; - Check/Magnify sprites X/Y x 2
        ld      a, (BackupByte)
        bit     0, a
        jp      z, .BypassMagnify

	set	3, (iy+S_SPRITE_ATTR.Attribute4)	; Set YY = 0
	set	1, (iy+S_SPRITE_ATTR.Attribute4)	; Set XX = 0

        add      hl, $0200               ; Point to next display block+1

        jp      .Continue

.BypassMagnify:
        add      hl, $0100               ; Point to next display block

.Continue:
        ld      (BackupWord2), hl       ; Save XXYY position
        
; - Check for title scroll sprite
        ld      a, (GameStatus3)
        bit     5, a
        jp      nz, .UpdateSpriteAttribs        ; Jump if spawning title scroll sprite

        res     4, a
        ld      (GameStatus3), a                ; Reset animated text sprite flag (if set)

        inc     ix                              ; Point to next text value

        jp      .SpriteTextLoop

; - Display Activities = Upload Sprite Attributes
.UpdateSpriteAttribs:
        ld      a, MaxSprites           	; Number of sprites to upload
        call    UploadSpriteAttributesDMA       

        ret

;-------------------------------------------------------------------------------------
; Setup Sprites and Palette for Level
; Parameters
ImportLevelSprites:
; Import Sprite Palette
        ld      a, $$SpritePalette  ; Memory bank (8kb) containing sprite palette data        
        ld      hl, SpritePalette   ; Address of first byte of sprite palette data
        call    SetupSpritePalette
        
; Upload Sprite Patterns
        ld      d, $$SpriteSet1         ; Memory bank (8kb) containing sprite data 0-63   - 8kb
        ld      e, $$SpriteSet2         ; Memory bank (8kb) containing sprite data 64-127 - 8kb
        ld      hl, SpriteSet1          ; Address of first byte of sprite patterns
        ld      ixl, 64                 ; Number of sprite patterns to upload
        call    UploadSpritePatterns

        ret

EndofSpritesCode:
