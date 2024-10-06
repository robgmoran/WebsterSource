CollisionCode:
;-------------------------------------------------------------------------------------
; Check Player to Hazard/Reverse-Hazard Collision - Sprite to Block
; Parameters:
CheckPlayerHazardCollision:
; Reset player damage and Reverse-Hazard enabled player variables
        ld      a, 0
        ld      (PlayerDamage), a
        ld      (ReverseHazardEnabledPlayer), a

        ld      ix, PlayerSprite

; Hazard - Top-Right Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardRightOffset                                 ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardTopOffset                                   ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        ld      d, a

; - Reverse-Hazard - Check
        ld      a, ReverseHazardEnableBlock
        cp      d
        jp      z, .ReverseHazardEnableHit                      ; Jump if block = ReverseHazardEnableBlock

; - Hazard - Lower Check
        ld      a, HazardStart-1
        cp      d
        jp      nc, .CheckBottomLeft                            ; Jump if Block <= HazardStart-1

; - Hazard - Upper Check
        ld      a, HazardEnd
        cp      d
        jp      c, .CheckBottomLeft                             ; Jump if block > HazardEnd

        ld      a, 1
        ld      (PlayerDamage), a

        ld      a, (HazardDamage)
        ld      b, a
        call    PlayerTakeDamage

        ret                                                     ; Only need to take damage once

.CheckBottomLeft:
; Hazard - Bottom-Left Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardLeftOffset                                  ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardBottomOffset                                ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        ld      d, a

; - Reverse-Hazard - Check
        ld      a, ReverseHazardEnableBlock
        cp      d
        jp      z, .ReverseHazardEnableHit                      ; Jump if block = ReverseHazardEnableBlock

; - Hazard - Lower Check
        ld      a, HazardStart-1
        cp      d
        jp      nc, .CheckBottomRight                           ; Jump if Block <= HazardStart-1

; - Hazard - Upper Check
        ld      a, HazardEnd
        cp      d
        jp      c, .CheckBottomRight                            ; Jump if block > HazardEnd

        ld      a, 1
        ld      (PlayerDamage), a

        ld      a, (HazardDamage)
        ld      b, a
        call    PlayerTakeDamage

        ret                                                     ; Only need to take damage once

.CheckBottomRight:
; Hazard - Left Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardRightOffset                                 ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardBottomOffset                                ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        ld      d, a

; - Reverse-Hazard - Check
        ld      a, ReverseHazardEnableBlock
        cp      d
        jp      z, .ReverseHazardEnableHit                      ; Jump if block = ReverseHazardEnableBlock

; - Hazard - Lower Check
        ld      a, HazardStart-1
        cp      d
        jp      nc, .CheckTopLeft                               ; Return if Block <= HazardStart-1

; - Hazard - Upper Check
        ld      a, HazardEnd
        cp      d
        jp      c, .CheckTopLeft                                ; Return if block > HazardEnd

        ld      a, 1
        ld      (PlayerDamage), a

        ld      a, (HazardDamage)
        ld      b, a
        call    PlayerTakeDamage

        ret                                                     ; Only need to take damage once

.CheckTopLeft:
; Hazard - Left Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardLeftOffset                                  ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardTopOffset                                   ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        ld      d, a

; - Reverse-Hazard - Check
        ld      a, ReverseHazardEnableBlock
        cp      d
        jp      z, .ReverseHazardEnableHit                      ; Jump if block = ReverseHazardEnableBlock

; - Hazard - Lower Check
        ld      a, HazardStart-1
        cp      d
        ret     nc                                              ; Return if Block <= HazardStart-1

; - Hazard - Upper Check
        ld      a, HazardEnd
        cp      d
        ret     c                                               ; Return if block > HazardEnd

        ld      a, 1
        ld      (PlayerDamage), a

        ld      a, (HazardDamage)
        ld      b, a
        call    PlayerTakeDamage

        ret                                                     ; Only need to take damage once

; Reverse-Hazard Enable Block Hit - Reverse all hazards
.ReverseHazardEnableHit:
        ld      a, 1
        ld      (ReverseHazardEnabled), a
        ld      (ReverseHazardEnabledPlayer), a                 ; Indicates player and not player bullet hit Reverse-hazard enable block

        ld      a, ReverseHazardDelay
        ld      (ReverseHazardCounter), a

        ret

;-------------------------------------------------------------------------------------
; Check Player to Finish Collision - Sprite to Block
; Parameters:
CheckPlayerFinishCollision:
        ld      a, (GameStatus)
        bit     6, a
        ret     nz                      ; Return if level complete

; Check for enable finish block once i.e. in middle of player
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, FinishOverlapPermitted                              ; x offset
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, FinishOverlapPermitted                              ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                                  ; Add block offset
        ld      a, (iy)                                                 ; Obtain block number

        ld      d, a
 
        ld      a, FinishEnableCentreBlock
        cp      d
        ret     nz

; Finish Enable Centre Block Hit - Complete Level
        ld      a, (GameStatus)
        set     6, a                                                    ; Set Level Complete flag
        ld      (GameStatus), a

; Play sound effect
        ld      a, AyFXPlayerSpawnFinish
        call    AFX2Play

        ret

;-------------------------------------------------------------------------------------
; Check friendly to Hazard/Rescue Collision - Sprite to Block
; Parameters:
; ix = Friendly sprite data
; Return:
CheckFriendlyHazardRescueCollision:
; Hazard - Top-Right Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardRightOffset                                 ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardTopOffset                                   ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        call    CheckFriendlyHazardBlocks

        cp      1
        ret     z                                               ; Return if hazard block

; Hazard - Bottom-Left Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardLeftOffset                                  ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardBottomOffset                                ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        call    CheckFriendlyHazardBlocks

        cp      1
        ret     z                                               ; Return if hazard block

; Hazard - Bottom-Right Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardRightOffset                                 ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardBottomOffset                                ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        call    CheckFriendlyHazardBlocks

        cp      1
        ret     z                                               ; Return if hazard block

; Hazard - Top-Left - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardLeftOffset                                  ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardTopOffset                                   ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        call    CheckFriendlyHazardBlocks

        cp      1
        ret     z                                               ; Return if hazard block

; Otherwise - Check for rescue block once i.e. in middle of friendly
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, RescueOverlapPermitted                      ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, RescueOverlapPermitted                      ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number


        ld      (BackupWord1), de               ; Save block x, y
        ld      d, a

        ld      a, RescueStart
        cp      d
        ret     nz

/* - Use if need to check for rescue block range i.e. Rescue block animates between blocks
; Rescue - Lower Check
        ld      a, RescueStart-1
        cp      d
        ret	nc                              ; Return if Block <= RescueStart-1

; Rescue - Upper Check
        ld      a, RescueEnd
        cp      d
        ret	c                               ; Return if block > RescueEnd
*/
; - Rescue - Rescue Friendly
        ld      de, (BackupWord1)               ; Restore block x, y
        call    FriendlyRescued

        ret

;-------------------------------------------------------------------------------------
; Check Player to Anti-Freeze Collision - Sprite to Block
; Parameters:
CheckPlayerAntiFreezeCollision:
; Reset Anti-Freeze setting
        ld      a, (GameStatus2)
        res     3, a
        ld      (GameStatus2), a

; Anti-Freeze - Top-Right Offset - Check for Block directly behind at offset
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardRightOffset                                 ; x offset
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardTopOffset                                   ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        cp      AntiFreeze
	jp	z, .AntiFreezeHit

; Anti-Freeze - Bottom-Left Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardLeftOffset                                  ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardBottomOffset                                ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        cp      AntiFreeze
	jp	z, .AntiFreezeHit

; Anti-Freeze - Left Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardRightOffset                                 ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardBottomOffset                                ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        cp      AntiFreeze
	jp	z, .AntiFreezeHit

; Anti-Freeze - Left Offset - Check for Block directly behind at offset
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, HazardLeftOffset                                  ; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, HazardTopOffset                                   ; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        cp      AntiFreeze
	ret	nz

.AntiFreezeHit:
; Anti-Freeze block hit
        ld      a, (GameStatus2)
        set     3, a
        ld      (GameStatus2), a                                ; Set anti-freeze flag

        ret

;-------------------------------------------------------------------------------------
; Check friendly to Hazard Collision Subroutine - Sprite to Block
; Parameters:
; ix = Friendly sprite data
; a = Block number to check
; Return:
; a = 0 (Block not matched, continue processing friendly), 1 (Block matched, stop processing friendly)
CheckFriendlyHazardBlocks:
        ld      d, a

; Hazard - Lower Check
        ld      a, HazardStart-1
        cp      d
        ret     nc                              ; Return if Block <= HazardStart-1

; Hazard - Upper Check
        ld      a, HazardEnd
        cp      d
        ret     c                               ; Return if block > HazardEnd

; - Hazard - Take damage
        ld      iy, ix

        ld      a, (HazardDamage)
        ld      b, a
        call    FriendlyTakeDamage

	ld	a, 1				; Return - Stop processing friendly
	ret

;-------------------------------------------------------------------------------------
; Check Player to Save Point Collision - Sprite to Block
; Parameters:
CheckPlayerSavePointCollision:
; Check for Save point block once i.e. in middle of player
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, FinishOverlapPermitted                              ; x offset
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, FinishOverlapPermitted                              ; y offset
        call    ConvertWorldToBlockOffset

        push    bc, de

        ld      iy, (LevelTileMap)
        add     iy, bc                                                  ; Add block offset
        ld      a, (iy)                                                 ; Obtain block number

        ld      d, a
 
        ld      a, SavePointDisabledBlock
        cp      d
        jp      z, .UpdateSavePoints                                    ; Jump if disabled Save point

        pop     de, bc

        ret

; Disabled Save point found
.UpdateSavePoints:
        ld      a, AyFXSavepointActivated
        call    AFX2Play

; - Check whether there is a saved Save point
        ld      hl, (SavePointSavedBlockOffset)
        or      a
        ld      bc, 0
        sbc     hl, bc
        jp      z, .UpdateNewSavePoint                                  ; Jump if no saved Save point

; Saved Save point found - Reset
; - Update screen TileMap block (visible)
        adc     hl, bc                                                  ; Restore hl value

        ld      de, (SavePointSavedBlockOffset)

        ld      iy, (LevelTileMap)
        add     iy, de                                                  ; Add block offset
        ld      a, (SavePointOldBlock)
        ld      (iy), a                                                 ; Reset to standard floor tile

; - Update screen TileMap block (visible)
        ld      hl, (PlayerStartXYBlock)
        call    UpdateScreenTileMap

; Save new Save point
.UpdateNewSavePoint:
; - Save new Save point block values
        pop     hl, de                                                  ; Original Push bc, de

        ld      (PlayerStartXYBlock), hl
        ld      (SavePointSavedBlockOffset), de

        ld      a, (PlayerSprite+S_SPRITE_TYPE.Energy)
        ld      (SavePointSavedPlayerEnergy), a
        ld      a, (PlayerFreezeTime)
        ld      (SavePointSavedPlayerFreeze), a

; - Update screen TileMap block (visible)
        ld      iy, (LevelTileMap)
        add     iy, de
        ld      (iy), SavePointEnabledBlock

; - Update screen TileMap block (visible)
        call    UpdateScreenTileMap

        ld      a, FloorSavePointUsedBlock
        ld      (SavePointOldBlock), a

; Update player HUD values
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

; TODO - Reuse for player to block collision e.g. Block to reverse hazard blocks?
/*
;-------------------------------------------------------------------------------------
; Check bomb to Spawn Point Collision - Sprite to Block
; Parameters:
; ix = Bomb sprite data
; Return:
CheckBombSpawnPointCollision:
; Check for spawn point block once i.e. in middle of bomb
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, SpawnPointOverlapPermitted         		; x offset
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, SpawnPointOverlapPermitted             	; y offset
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain block number

        ld      (BackupWord1), de               ; Save block x, y

        ld      d, a
; Spawn Point - Lower Check
        ld      a, SpawnPointStartBlock-1
        cp      d
        ret	nc                              ; Return if Block <= SpawnPointStart-1

; Spawn Point - Upper Check
        ld      a, SpawnPointEndBlock
        cp      d
        ret	c                               ; Return if block > SpawnPointEnd

; Spawn Point found
        ld      de, (BackupWord1)               ; Restore block x, y
        ld      a, SpawnPointDisabledBlock
        call    SpawnPointDisabled

	ret
*/
;-------------------------------------------------------------------------------------
; Check Bullet for Collision
; Parmeters:
; ix - Sprite data (projectile)
; Return Values:
; a = 0 - Don't delete source sprite, 1 - Delete source sprite
CheckBulletForCollision:
; --- Player & Enemy Bullets
; - Check bullet against enemies
        ld      iy, EnemySpritesStart           
        ld      a, MaxEnemy          ; Number of sprite entries to search through
        ld      b, a
.FindActiveEnemySprite:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .NextEnemySprite                     ; Jump if sprite not active

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .NextEnemySprite                     ; Jump if sprite not visible

        bit     6, (iy+S_SPRITE_TYPE.SpriteType5)
        jp      nz, .NextEnemySprite                    ; Jump if sprite should be ignored e.g. exploding
        
        bit     0, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      z, .Cont                                ; Jump if not enemy bullet i.e. Player bullet

; ====== Check Sprite Collision ======
; - Enemy Bullet checks - Bullet
        ld      a, (ix+S_SPRITE_TYPE.BulletSpriteSource)
        cp      (iy+S_SPRITE_TYPE.SpriteNumber)
        jp      z, .NextEnemySprite                     ; Jump if target same as enemy that fired bullet i.e. Don't check shooter

        ;bit     0, (iy+S_SPRITE_TYPE.SpriteType3)
        ;jp      nz, .NextEnemySprite                    ; Jump if target enemy shooter i.e. Don't check shooter

        ;bit     5, (iy+S_SPRITE_TYPE.SpriteType2)
        ;jp      nz, .NextEnemySprite                    ; Jump if target enemy turret i.e. Don't check turret

.Cont:
        push    bc, ix, iy
        call    CheckCollision                          ; Check collision between sprites; return - a
        pop     iy, ix, bc

; - Check whether we should continue checking bullet against sprites
        cp      0
        jr      z, .NextEnemySprite                  ; Jump if not deleting bullet - i.e. Bullet did not hit sprite

        ;push    af, bc, de, hl, ix
        ;ld      a, AyFXEnemyDead
        ;call    AFXPlay       
        ;pop     ix, hl, de, bc, af

; - Check whether the bullet should be deleted
        cp      1                               
        ret     z                               ; Return value - Bullet to be deleted - i.e. Bullet hit sprite and damage = 0

; - Check whether the bullet should not be deleted
        ld      a, 0                            ; Return value - Don't delete bullet - i.e. Bullet hit sprite and damage != 0
 
        ret

.NextEnemySprite:
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite
        djnz    .FindActiveEnemySprite

; - Check type of bullet - Player or Enemy
        bit     0, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      nz, .EnemyBullet                ; Jump if enemy bullet

; --- Player Bullet
; - Check bullet against lockers
        ld      iy, LockerSpritesStart
        ld      a, MaxLockers                   ; Number of sprite entries to search through
        ld      b, a
.FindActiveLockerSprite:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .NextLockerSprite                    ; Jump if sprite not active

        bit     5, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      z, .NextLockerSprite                    ; Jump if sprite not visible

        bit     3, (iy+S_SPRITE_TYPE.SpriteType1)
        jp      nz, .NextLockerSprite                   ; Jump if sprite already exploding

        push    bc, ix, iy
        call    CheckCollision                          ; Check collision between sprites; return - a
        pop     iy, ix, bc

        cp      0
        jr      z, .NextLockerSprite                  ; Jump if not deleting locker

        ;push    af, bc, de, hl, ix
        ;ld      a, AyFXEnemyDead
        ;call    AFXPlay       
        ;pop     ix, hl, de, bc, af

        ld      a, 1                            ; Return value - Bullet to be deleted

        ret

.NextLockerSprite:
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite
        djnz    .FindActiveLockerSprite

        ld      a, 0                            ; Return value - Don't delete bullet sprite

        ret
        
; --- Enemy Bullet
.EnemyBullet:
        ld      a, 0                            ; Return value - Assume no bullet deletion

        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        ret     nz                              ; Return if sprite already exploding

; - Check bullet against player
        ld      iy, PlayerSprite

        push    ix, iy
        call    CheckCollision                  ; Check collision between sprites; return - a
        pop     iy, ix

        cp      1
        ret     z                               ; Return if bullet should be deleted

; - Check bullet against friendly
        push    ix, iy

        ld      iy, FriendlySpritesStart
        ld      b, MaxFriendly        
.FriendlyLoop:
        ld      a, (iy+S_SPRITE_TYPE.active)    
        cp      0
        jp      z, .NextFriendly                ; Jump if friendly not active

        push    bc
        call    CheckCollision                  ; Check collision between sprites; return - a
        pop     bc

        cp      1
        jp      z, .Exit                        ; Return if bullet should be deleted

.NextFriendly:
        ld      de, S_SPRITE_TYPE
        add     iy, de
        
        djnz    .FriendlyLoop

        ld      a, 0                            ; Don't delete bullet

.Exit:
        pop     iy, ix

        ret

/* - No longer required
;-------------------------------------------------------------------------------------
; Check Bomb for Collision
; Parmeters:
; ix - Sprite data
; Return Values:
CheckBombForCollision:
; - Check bullet against enemies
        ld      iy, EnemySpritesStart           
        ld      a, MaxEnemy                     ; Number of sprite entries to search through
        ld      b, a
.FindActiveSprite:
        ld      a, (iy+S_SPRITE_TYPE.active)
        cp      0
        jp      z, .NextSprite                  ; Jump if sprite not active

        push    bc, ix, iy
        call    CheckCollision                  ; Check collision between sprites; return - a
        pop     iy, ix, bc

        ;push    af, bc, de, hl, ix
        ;ld      a, AyFXEnemyDead
        ;call    AFXPlay       
        ;pop     ix, hl, de, bc, af

.NextSprite:
        ld      de, S_SPRITE_TYPE               
        add     iy, de                          ; Point to next sprite
        djnz    .FindActiveSprite

        ret
*/

;-------------------------------------------------------------------------------------
; Obtain target sprite Collision Sides when hit by source sprite
; Parameters:
; ix - Source Sprite data
; iy - Target Sprite data
; Return Values:
; iy+S_SPRITE_TYPE.SprContactSide - Target sprte collision sides
GetTargetCollisionSides:
; Check original unchanged player input and call opposite collision code
; i.e. Player moves up, check enemy bottom colliison
; - First check whether player has provided input
        ld      a, (PlayerInputOriginal)
        cp      0
        jp      nz, .GetCollision       ; Jump if player provided input

        ld      a, %00001111            ; Otherwise check UDLR for collision

.GetCollision:
        ld      b, a

; - Reset enemy collision sides; don't need to reset player as player is cumulative with other enemies
        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.SprContactSide), a

        bit     3, b
        call    nz, .CheckSourceBottom

        bit     2, b
        call    nz, .CheckSourceTop

        bit     1, b
        call    nz, .CheckSourceRight

        bit     0, b
        call    nz, .CheckSourceLeft

        ret

.CheckSourceTop:
; Top Check 1 - source.y > target.y
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
	ld	a, (ix+S_SPRITE_TYPE.BoundaryY)	
	add	de, a

        ld      hl, (iy+S_SPRITE_TYPE.YWorldCoordinate)
	ld	a, (iy+S_SPRITE_TYPE.BoundaryY)
	add	hl, a
	ld	(BackupWord1), hl		; Save target.y+BoundaryY

	or	a
	sbc	hl, de
        ret     nc                              ; Return if target (hl) >= source (de)

; Top Check 2 - source.y <= target.y+height
	ld	hl, (BackupWord1)		; Restore target.y+BoundaryY
	ld	a, (iy+S_SPRITE_TYPE.BoundaryHeight)
	add	hl, a                           ; = target.y+BoundaryY+BoundaryHeight

	or	a
	sbc	hl, de
	ret     c                               ; Return if target (hl) < source (de) 

	set	2, (iy+S_SPRITE_TYPE.SprContactSide)	; Flag player bottom collision
	set	2, (ix+S_SPRITE_TYPE.SprContactSide)	; Flag enemy bottom collision

        ld      a, 0
        ld      b, a                            ; Indicate collision found, so don't check any more input

        ret

.CheckSourceBottom:
; Bottom Check 1 - source.y+height < target.y+height
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
	ld	a, (ix+S_SPRITE_TYPE.BoundaryY)	
	add	de, a

	ld	a, (ix+S_SPRITE_TYPE.BoundaryHeight)
	add	de, a                           ; = source.y+BoundaryY+BoundaryHeight
	ld	(BackupWord1), de		; Save source.y+BoundaryY+BoundaryHeight

        ld      hl, (iy+S_SPRITE_TYPE.YWorldCoordinate)
	ld	a, (iy+S_SPRITE_TYPE.BoundaryY)
	add	hl, a
        ld      (BackupWord2), hl               ; Save target.y+BoundaryY

	ld	a, (iy+S_SPRITE_TYPE.BoundaryHeight)
	add	hl, a                           ; = target.y+BoundaryY+BoundaryHeight

	ex	de, hl
        or      a
        sbc     hl, de
        ret     nc                              ; Return if source (hl) >= target (de)

; Bottom Check 2 - source.y+height >= target.y
	ld	hl, (BackupWord1)		; Restore source.y+BoundaryY+BoundaryHeight

	ld	de, (BackupWord2)		; Save target.y+BoundaryY

	or	a
	sbc	hl, de
	ret     c                               ; Return if source (hl) < target (de)

	set	3, (iy+S_SPRITE_TYPE.SprContactSide)	; Flag player top collision
	set	3, (ix+S_SPRITE_TYPE.SprContactSide)	; Flag enemy top collision

        ld      a, 0
        ld      b, a                            ; Indicate collision found, so don't check any more input
                
        ret

.CheckSourceLeft:
; Left Check 1 - source.x > target.x
        ld      de, (ix+S_SPRITE_TYPE.XWorldCoordinate)
	ld	a, (ix+S_SPRITE_TYPE.BoundaryX)	
	add	de, a                           ; = source.X+BoundaryX

        ld      hl, (iy+S_SPRITE_TYPE.XWorldCoordinate)
	ld	a, (iy+S_SPRITE_TYPE.BoundaryX)
	add	hl, a                           ; = target.X+BoundaryX
	ld	(BackupWord1), hl		; Save target.X+BoundaryX

	or	a
	sbc	hl, de
        ret     nc                              ; Return if target (hl) >= source (de)

; Left Check 2 - source.x <= target.x+width
	ld	hl, (BackupWord1)		; Restore target.x+BoundaryX
	ld	a, (iy+S_SPRITE_TYPE.BoundaryWidth)
	add	hl, a                           ; = target.x+BoundaryX+BoundaryWidth

	or	a
	sbc	hl, de
	ret     c                               ; Return if target (hl) < source (de) 

	set	0, (iy+S_SPRITE_TYPE.SprContactSide)	; Flag player right collision
	set	0, (ix+S_SPRITE_TYPE.SprContactSide)	; Flag enemy right collision

        ld      a, 0
        ld      b, a                            ; Indicate collision found, so don't check any more input

	ret

.CheckSourceRight:
; Right Check 1 - source.x+width < target.x+width
        ld      de, (ix+S_SPRITE_TYPE.XWorldCoordinate)
	ld	a, (ix+S_SPRITE_TYPE.BoundaryX)	
	add	de, a                           ; = source.X+BoundaryX

	ld	a, (ix+S_SPRITE_TYPE.BoundaryWidth)
	add	de, a                           ; = source.x+BoundaryX+BoundaryWidth
	ld	(BackupWord1), de		; Save source.x+BoundaryX+BoundaryWidth

        ld      hl, (iy+S_SPRITE_TYPE.XWorldCoordinate)
	ld	a, (iy+S_SPRITE_TYPE.BoundaryX)
	add	hl, a                           ; = target.X+BoundaryX
        ld      (BackupWord2), hl               ; Save target.X+BoundaryX

	ld	a, (iy+S_SPRITE_TYPE.BoundaryWidth)
	add	hl, a                           ; = target.x+BoundaryX+BoundaryWidth

	ex	de, hl
        or      a
        sbc     hl, de
        ret     nc                              ; Return if source (hl) >= target (de)

; Right Check 2 - source.x+width >= target.x
	ld	hl, (BackupWord1)		; Restore source.x+BoundaryX+BoundaryWidth

	ld	de, (BackupWord2)		; Restore target.x+BoundaryX

	or	a
	sbc	hl, de
	ret	c                               ; Return if source (hl) < target (de)

	set	1, (iy+S_SPRITE_TYPE.SprContactSide)	; Flag player left collision
	set	1, (ix+S_SPRITE_TYPE.SprContactSide)	; Flag enemy left collision

        ld      a, 0
        ld      b, a                            ; Indicate collision found, so don't check any more input

        ret