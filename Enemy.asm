EnemyCode:
;-------------------------------------------------------------------------------------
; Process Enemy Turrets
; Parameters:
; ix = Turret sprite storage memory address offset
ProcessEnemyTurret:
; Reset turret flag used to control firing
        ld      a, 0
        ld      (TurretInRange), a

; Check whether turret is currently disabled
        bit     3, (ix+S_SPRITE_TYPE.SpriteType1)
        jp      z, .NotDisabled                         ; Jump if turret not disabled

; ---Turret disabled---
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      z, .ResetTurret                         ; Jump if turret can now be re-enabled 

        dec     a
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      ; Otherwise decrement delay counter

        ret

; ---Turret Enabled---
.NotDisabled:
; Check whether turret visible i.e. not displayed on screen
        bit     6, (ix+S_SPRITE_TYPE.SpriteType4)        
        jp      nz, .Cont                               ; Jump if turret rotating i.e. Always process

        bit     5, (ix+S_SPRITE_TYPE.SpriteType1)
        ret     z                                       ; Otherwise return if turret not visible

.Cont:
; Check enemy energy
        ld      a, (ix+S_SPRITE_TYPE.Energy)
        cp      0
        jp      z, .DisableTurret                       ; Jump if energy = 0

        ;;;or      a
        ;;;jp      m, .DisableTurret                       ; Jump if energy negative

; Animate turret
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.animationStr)     ; Sprite pattern range

        call    UpdateSpritePattern

        ld      ix, iy

; Check whether we need to update DelayCounter used for firing bullets
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      z, .ProcessTurret                       ; Jump if we don't need to update DelayCounter

        dec     a
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      ; Otherwise decrement counter
        
.ProcessTurret:
; Calculate distance vector between player and turret
        call    ObtainTurretDistanceVector            ; Return bc = x value, de = y value
        
; Check whether player in range of turret
; - Check x delta
        ld      a, (ix+S_SPRITE_TYPE.RotRange)
        cp      b
        jp      nc, .CheckYDelta                ; Jump if turret x delta <= range i.e. in range

        ld      a, 0
        jp      .UpdateTurret

; - Check y delta
.CheckYDelta:
        cp      d
        jp      nc, .TurretInRange              ; Jump if turret y delta <= range i.e. in range

        ld      a, 0
        jp      .UpdateTurret

.TurretInRange:
        ld      a, 1

.UpdateTurret:
        bit     4, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      nz, EnemyTurretUp

        bit     3, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      nz, EnemyTurretDown

        bit     2, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      nz, EnemyTurretLeft

        bit     1, (ix+S_SPRITE_TYPE.SpriteType2)
        jp      nz, EnemyTurretRight
        
        jp      EnemyTurretRotating                     ; Jump if turret type not specified

.DisableTurret:
; Play audio effect
        push    ix

        ld      a, AyFXTurretDisabled
        call    AFX2Play

        pop     ix

; Update Score
        push    iy
        ld      iy, ScoreDisableTurret
        call    UpdateScore
        pop     iy

        set     3, (ix+S_SPRITE_TYPE.SpriteType1)       ; Disable turret

        ld      a, (ix+S_SPRITE_TYPE.EnemyDisableTimeOut)
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      ; Set disable timeout

; - Process disable animation
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.animationOther)   ; Sprite pattern range

        call    UpdateSpritePattern

        ld      ix, iy

; - Update LevelTileMap with disabled block
        ld      bc, (ix+S_SPRITE_TYPE.RotPointX)
        ld      hl, (ix+S_SPRITE_TYPE.RotPointY)
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                  ; Add block offset
	ld	(iy), TurretDisabledBlock

; - Update screen memory
        push    ix                                      ; Save sprite pointer
	ex 	de, hl		                        ; hl = x, y Block Offset
	ld	de, bc		                        ; de = Block Offset
        call    UpdateScreenTileMap                     ; Update tiles within screen tilemap
        pop     ix                                      ; Restore sprite pointer

        ret

.ResetTurret:
; Play audio effect
        push    ix

        ld      a, AyFXTurretEnabled
        call    AFX2Play

        pop     ix

        res     3, (ix+S_SPRITE_TYPE.SpriteType1)       ; Enable turret

        ld      a, (ix+S_SPRITE_TYPE.EnergyReset)
        ld      (ix+S_SPRITE_TYPE.Energy), a            ; Reset energy

; - Process enable animation
        ld      iy, ix

        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.animationStr)     ; Sprite pattern range

        call    UpdateSpritePattern

        ld      ix, iy

; - Update LevelTileMap with enabled block
        ld      bc, (ix+S_SPRITE_TYPE.RotPointX)
        ld      hl, (ix+S_SPRITE_TYPE.RotPointY)
        call    ConvertWorldToBlockOffset

        ld      iy, (LevelTileMap)
        add     iy, bc                                  ; Add block offset
	ld	(iy), TurretEnabledStartBlock

; - Update screen memory
        push    ix                                      ; Save sprite pointer
	ex 	de, hl		                        ; hl = x, y Block Offset
	ld	de, bc		                        ; de = Block Offset
        call    UpdateScreenTileMap                     ; Update tiles within screen tilemap
        pop     ix                                      ; Restore sprite pointer

        ret

;-------------------------------------------------------------------------------------
; Process Enemy Turrets - Facing Down
; Parameters:
; bc = x delta between player and turret
; de = y delta between player and turret
; a = Turret in range (1) or turret out of range (0)
EnemyTurretDown:
; Check whether turret is in range
        cp      0
        jp      z, .ResetTurret                 ; Jump if turret out of range

; Check whether player above turret
        ld      a, (PlayerToTurretPosition)
        bit     1, a
        jp      z, .PlayerBelowTurret           ; Jump if player below turret

; - Player above turret
.ResetTurret:
        ld      a, (ix+S_SPRITE_TYPE.RotationReset)     ; Reset turret back to starting position
        call    CheckUpdateSpriteRotation

        ret
        
; - Player below turret
.PlayerBelowTurret:
; Check whether we have an x delta of 0
        ld      a, b                            ; Load x value into a
        cp      0
        jp      nz, .DownCheckSide              ; Jump if x delta not 0

        ld      a, 128                          ; Otherwise set rotation to 128 (180 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.DownCheckSide:
; Check whether we need to swap vector.x and vector.y
        ld      a, (PlayerToTurretPosition)
        bit     0, a
        jp      nz, .DownPlayerToLeft        ; Jump if player to left of turret

; - Player below/right turret
; Check whether we have a y delta of 0
        ld      a, d                            ; Load y value into a
        cp      0
        jp      nz, .ProcessDownRight        ; Jump if y delta not 0

        ld      a, 64                           ; Otherwise set rotation to 64 (90 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessDownRight:
; Calculate inverse tangent of tangent (distance vector y/x)
        push    bc, de
        pop     bc, de                          ; Swap registers

        call    BC_Div_DE_88                    ; de = result

        call    ConvertTangentToRotation     ; a = Rotation value
        add     64                              ; Add rotation of 64 (90 degrees)
        call    CheckUpdateSpriteRotation


; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

; - Player below/left turret
.DownPlayerToLeft:
; Check whether we have a y delta of 0
        ld      a, d                            ; Load y value into a
        cp      0
        jp      nz, .ProcessDownLeft         ; Jump if y delta not 0

        ld      a, 192                          ; Otherwise set rotation to 192 (180 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessDownLeft:
; Calculate inverse tangent of tangent (distance vector y/x)
        push    bc, de
        pop     bc, de                          ; Swap registers

        call    BC_Div_DE_88                    ; de = result

        call    ConvertTangentToRotation

; Subtract rotation from 64 to ensure result consistent with other side
        ld      b, a
        ld      a, 64
        sub     b

        add     128                             ; Add rotation of 128 (180 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

;-------------------------------------------------------------------------------------
; Process Enemy Turrets - Facing Up
; Parameters:
; bc = x delta between player and turret
; de = y delta between player and turret
; a = Turret in range (1) or turret out of range (0)
EnemyTurretUp:
; Check whether turret is in range
        cp      0
        jp      z, .ResetTurret                 ; Jump if turret out of range

; Check whether player below turret
        ld      a, (PlayerToTurretPosition)
        bit     1, a
        jp      nz, .PlayerAboveTurret           ; Jump if player above turret

        bit     2, a
        jp      nz, .PlayerAboveTurret           ; Jump if player level with turret (Y)

; - Player below turret
.ResetTurret:
        ld      a, (ix+S_SPRITE_TYPE.RotationReset)     ; Reset turret back to starting position
        call    CheckUpdateSpriteRotation

        ret

; - Player above turret
.PlayerAboveTurret:
; Check whether we have an x delta of 0
        ld      a, b                            ; Load x value into a
        cp      0
        jp      nz, .UpCheckSide                ; Jump if x delta not 0

        ld      a, 0                            ; Otherwise set rotation to 0 (0) degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.UpCheckSide:
; Check whether we need to swap vector.x and vector.y
        ld      a, (PlayerToTurretPosition)
        bit     0, a
        jp      nz, .UpPlayerToLeft          ; Jump if player to left of turret

; - Player above/right turret
; Check whether we have a y delta of 0
        ld      a, d                            ; Load y value into a
        cp      0
        jp      nz, .ProcessUpRight          ; Jump if y delta not 0

        ld      a, 64                           ; Otherwise set rotation to 64 (90 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessUpRight:
; Calculate inverse tangent of tangent (distance vector y/x)
        push    bc, de
        pop     bc, de                          ; Swap registers

        call    BC_Div_DE_88                    ; de = result

        call    ConvertTangentToRotation     ; a = Rotation value
        ld      b, a
        ld      a, 64                           ; Add rotation of 64 (90 degrees)
        sub     b
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

; - Player above/left turret
.UpPlayerToLeft:
; Check whether we have a y delta of 0
        ld      a, d                            ; Load y value into a
        cp      0
        jp      nz, .ProcessUpLeft           ; Jump if y delta not 0

        ld      a, 192                          ; Otherwise set rotation to 192 (180 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessUpLeft:
; Calculate inverse tangent of tangent (distance vector y/x)
        push    bc, de
        pop     bc, de                          ; Swap registers

        call    BC_Div_DE_88                    ; de = result

        call    ConvertTangentToRotation

; Subtract rotation from 64 to ensure result consistent with other side
        ld      b, a
        ld      a, 64
        sub     b

        ld      b, a
        ld      a, 0                            ; Subtract from 0 (0 degrees)
        sub     b
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

;-------------------------------------------------------------------------------------
; Process Enemy Turrets - Facing Right
; Parameters:
; bc = x delta between player and turret
; de = y delta between player and turret
; a = Turret in range (1) or turret out of range (0)
EnemyTurretRight:
; Check whether turret is in range
        cp      0
        jp      z, .ResetTurret                 ; Jump if turret out of range

; Check whether player to left of turret
        ld      a, (PlayerToTurretPosition)
        bit     0, a
        jp      z, .PlayerRightTurret           ; Jump if player to right of turret

; - Player to left of turret
.ResetTurret:
        ld      a, (ix+S_SPRITE_TYPE.RotationReset)     ; Reset turret back to starting position
        call    CheckUpdateSpriteRotation

        ret
        
; - Player to right of turret
.PlayerRightTurret:
; Check whether we have a y delta of 0
        ld      a, d                            ; Load y value into a
        cp      0
        jp      nz, .RightCheckSide             ; Jump if y delta not 0

        ld      a, 64                           ; Otherwise set rotation to 64 (90 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.RightCheckSide:
; Check top or bottom
        ld      a, (PlayerToTurretPosition)
        bit     1, a
        jp      z, .RightPlayerBottom        ; Jump if player at bottom of turret

; - Player right/top turret
; Check whether we have an x delta of 0
        ld      a, b                            ; Load x value into a
        cp      0
        jp      nz, .ProcessRightTop            ; Jump if x delta not 0

        ld      a, 0                          ; Otherwise set rotation to 0 (0 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessRightTop:
; Calculate inverse tangent of tangent (distance vector x/y)
        call    BC_Div_DE_88                    ; de = result

        call    ConvertTangentToRotation     ; a = Rotation value

        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

; - Player right/bottom turret
.RightPlayerBottom:
; Check whether we have an x delta of 0
        ld      a, b                            ; Load x value into a
        cp      0
        jp      nz, .ProcessRightBottom         ; Jump if x delta not 0

        ld      a, 128                          ; Otherwise set rotation to 128 (180 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessRightBottom:
; Calculate inverse tangent of tangent (distance vector x/y)
        call    BC_Div_DE_88                    ; de = result
        
        call    ConvertTangentToRotation

; Subtract rotation from 64 to ensure result consistent with other side
        ld      b, a
        ld      a, 64
        sub     b

        add     64                             ; Add rotation of 64 (90 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

;-------------------------------------------------------------------------------------
; Process Enemy Turrets - Facing Left
; Parameters:
; ix = Sprite data
; bc = x delta between player and turret
; de = y delta between player and turret
; a = Turret in range (1) or turret out of range (0)
EnemyTurretLeft:
; Check whether turret is in range
        cp      0
        jp      z, .ResetTurret                 ; Jump if turret out of range

; Check whether player to right of turret
        ld      a, (PlayerToTurretPosition)
        bit     0, a
        jp      nz, .PlayerLeftTurret           ; Jump if player to left of turret

        bit     3, a
        jp      nz, .PlayerLeftTurret          ; Jump if player level with turret (X)

; - Player to right of turret
.ResetTurret:
        ld      a, (ix+S_SPRITE_TYPE.RotationReset)     ; Reset turret back to starting position
        call    CheckUpdateSpriteRotation

        ret
        
; - Player to left of turret
.PlayerLeftTurret:
; Check whether we have a y delta of 0
        ld      a, d                            ; Load y value into a
        cp      0
        jp      nz, .LeftCheckSide              ; Jump if y delta not 0

        ld      a, 192                          ; Otherwise set rotation to 192 (270 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.LeftCheckSide:
; Check top or bottom
        ld      a, (PlayerToTurretPosition)
        bit     1, a
        jp      z, .LeftPlayerBottom            ; Jump if player at bottom of turret

; - Player left/top turret
; Check whether we have an x delta of 0
        ld      a, b                            ; Load x value into a
        cp      0
        jp      nz, .ProcessLeftTop             ; Jump if x delta not 0

        ld      a, 0                          ; Otherwise set rotation to 0 (0 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessLeftTop:
; Calculate inverse tangent of tangent (distance vector x/y)
        call    BC_Div_DE_88                    ; de = result

        call    ConvertTangentToRotation     ; a = Rotation value

        ld      b, a
        ld      a, 0
        sub     b                               ; Subtract rotation from 0 (0 degrees)
        
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

; - Player left/bottom turret
.LeftPlayerBottom:
; Check whether we have an x delta of 0
        ld      a, b                            ; Load x value into a
        cp      0
        jp      nz, .ProcessLeftBottom          ; Jump if x delta not 0

        ld      a, 128                          ; Otherwise set rotation to 128 (180 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

.ProcessLeftBottom:
; Calculate inverse tangent of tangent (distance vector x/y)
        call    BC_Div_DE_88                    ; de = result
        
        call    ConvertTangentToRotation

; Subtract rotation from 64 to ensure result consistent with other side
        ld      b, a
        ld      a, 64
        sub     b

        ld      b, a
        ld      a, 192
        sub     b                               ; Subtract rotation from 192 (270 degrees)
        call    CheckUpdateSpriteRotation

; Allow turret to fire
        ld      a, 1
        ld      (TurretInRange), a

        ret

;-------------------------------------------------------------------------------------
; Process Enemy Turrets - Rotating
; Parameters:
; bc = x delta between player and turret
; de = y delta between player and turret
; a = Turret in range (1) or turret out of range (0)
EnemyTurretRotating:
; Check whether turret in range of player
        cp      0
        jp      z, .ContRotation        ; Jump if turret not in range

        ld      (TurretInRange), a      ; Otherwise set turret to fire at player

.ContRotation:
        ld	a, (ix+S_SPRITE_TYPE.Rotation)
	inc	a
        call    CheckUpdateSpriteRotation

        ret

;-------------------------------------------------------------------------------------
; Enemy Fire Bullet
; Parameters:
; ix = Enemy sprite data
EnemyFireBullet:
; Check whether we can fire
        ld      iy, ix

        ld      a, (iy+S_SPRITE_TYPE.DelayCounter)
        cp      0
        ret     nz                                      ; Return if we can't fire bullets yet

        ld      a, (BulletsEnemyFired)
        cp      MaxEnemyBullets
        ret     z                                       ; Return if all enemy bullets have been fired

        inc     a                                       ; Increment number of bullets fired
        ld      (BulletsEnemyFired), a

; Spawn bullet
        ld      hl, (iy+S_SPRITE_TYPE.BulletType)       ; Bullet to be fired
        ld      ix, hl

        ld      a, (ix+S_BULLET_DATA.audioRef)
        ld      (BackupByte), a                         ; Save bullet audio reference

        ld      de, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ld      hl, (iy+S_SPRITE_TYPE.XWorldCoordinate)

        push    iy                                      ; Save enemy sprite location

        ld      a, (iy+S_SPRITE_TYPE.Rotation)
        ld      c, a
        ld      iy, EnemyBulletSpritesStart
        ld      a, EnemyBulletAttStart
        ld      b, MaxEnemyBullets
        call    SpawnNewBulletSprite

; Play audio effect
        cp      0                                       ; Return value
        jp      z, .NoBullet                            ; Jump if bullet not spawned

        push    af, ix

        ld      a, (BackupByte)
        call    AFX2Play

        pop     ix, af

        set     0, (ix+S_SPRITE_TYPE.SpriteType2)       ; Designate bullet as fired by enemy

; Set bullets delay counter
        ld      a, (ix+S_SPRITE_TYPE.Delay)

        pop     iy                                      ; Restore enemy sprite location

        ld      (iy+S_SPRITE_TYPE.DelayCounter), a

; Check/Set bullets range
        ld      a, (ix+S_SPRITE_TYPE.RotRange)          ; Bullet RotRange    
        cp      0
        jp      nz, .PostRange                          ; Jump if bullet should use it's own range

; - Set Bullet range
        ld      a, (iy+S_SPRITE_TYPE.RotRange)             
        ld      (ix+S_SPRITE_TYPE.RotRange), a          ; Set bullet to use enemy range

; - Check/Set bullet speed
        ld      a, (iy+S_SPRITE_TYPE.RotRange)
        cp      EnemyShooterRange
        jp      c, .PostRange                          ; Jump if EnemyShooterPlayerRange > Enemy shooter RotRange

        ld     (ix+S_SPRITE_TYPE.Speed), 2              ; Otherwise set bullet speed to 2

.PostRange:
; Set bullets source sprite number i.e. Sprite number of enemy firing bullet
        ld      a, (iy+S_SPRITE_TYPE.SpriteNumber)
        ld      (ix+S_SPRITE_TYPE.BulletSpriteSource), a

        ret

; No Bullet Spawned
.NoBullet:
        pop     iy

        ret

;-------------------------------------------------------------------------------------
; Enemy Shooter
; Parameters:
; ix = Enemy sprite data
EnemyShooter:
; Check whether we need to update DelayCounter used for firing bullets
        ld      a, (ix+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      nz, .UpdateDelayCounter         ; Jump if enemy can't fire yet

; Calculate distance vector between player and enemy
        call    ObtainPlayerDistanceVector      ; Return bc = x value, de = y value
        
; Check whether player in range of enemy
; - Check x delta
        ld      a, (ix+S_SPRITE_TYPE.RotRange)
        cp      b
        jp      nc, .CheckYDelta                ; Jump if enemy x delta <= range i.e. in range

        res     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset don't move in next frame flag

        ret                                     ; Return if player not in range

; - Check y delta
.CheckYDelta:
        cp      d
        jp      nc, .ContinueFire               ; Jump if enemy y delta <= range i.e. in range

        res     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset don't move in next frame flag

        ret                                     ; Return if player not in range

.ContinueFire:
        bit     3, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .ContinueFire2                      ; Jump if waypoint enemy i.e. Keep waypoint enemy moving whilst firing

        set     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Otherwise, set don't move in next frame flag i.e. Enemy shooting so don't move

.ContinueFire2:
        call    BC_Div_DE_88                    ; de = result
        call    ConvertTangentToRotation        ; a = Rotation value

; - Check player to enemy position and update rotation value based on whether player above/below/left/right
        ld      b, a                                    ; Save rotation value
        ld      d, 0                                    ; Default offset - Assuming player in quarter1 i.e. above/right

        ld      a, (PlayerToEnemyPosition)
        cp      %00000000
        jp      z, .Quarter2

        cp      %00000001
        jp      z, .Quarter3

        cp      %00000011
        jp      z, .Quarter4                            

; Quarter1
        ld      a, b                                    ; Restore rotation value
        jp      .SpawnBullet                            ; No offset required

.Quarter2:
        ld      a, 128                                  
        sub     b                                       ; 180 degrees - angle
        jp      .SpawnBullet

.Quarter3:
        ld      a, 128
        add     b                                       ; 180 degrees + angle
        jp      .SpawnBullet

.Quarter4:
        ld      a, 255
        sub     b                                       ; 360 degrees - angle

.SpawnBullet:
        ld      (ix+S_SPRITE_TYPE.RotRadius), 0         ; Start at centre
        ld      (ix+S_SPRITE_TYPE.Rotation), a

        push    ix
        call    EnemyFireBullet
        pop     ix

        ret

.UpdateDelayCounter:
        dec     a
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a      ; Otherwise decrement counter

        ret

;-------------------------------------------------------------------------------------
; On Screen Enemy Movement - Using FF
; Note: Friendly should use ProcessOffScreenEnemy
; Parameters:
; ix = Enemy sprite
ProcessOnScreenEnemy:
; Check whether enemy has collided with player
        ld      a, (ix+S_SPRITE_TYPE.SprCollision)
        cp      1
        jp      nz, .NoCollision                        ; Jump if enemy not stopped by collision

; - Enemy stopped by collision, so look at player
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      hl, (PlayerBlockXY)
        ld      (EnemyBlockXY), de                      

        jp      EnemyLookAtEntity

.NoCollision:
; Check whether enemy already travelling to player
        ld      a, (ix+S_SPRITE_TYPE.MoveToTarget)
        cp      1
        jp      z, MoveEnemy                           ; Jump if enemy travelling to player
        
; Check whether enemy can use FF map
; - Check whether FF map has been built
        ld      a, (FFBuilt)
        cp      0
        ret     z                       ; Return if FF map not built

; - Get world block
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      (EnemyBlockOffset), bc                  ; Save current block offset
        ld      (EnemyBlockXY), de                      ; Save Tilemap block XY position
        ld      (ix+S_SPRITE_TYPE.MoveToBlockXY), de    ; Save Tilemap block offset

; - Check whether enemy within FFStorageComplete range
        call    CheckSpriteInFFStorageComplete

        cp      0                                       ; a = Return value
        jp      z, ProcessOffScreenEnemy                ; Jump if enemy not in FFStorageComplete area

; - Reset FF variables used for choosing path
        ld      a, 0
        ld      (FFDirection), a

        ld      a, %00001111
        ld      (FFValidPaths), a               ; Assume all paths are valid %0000UDLR

; - Get FF offset for enemy and get FF value
        ld      hl, FFStorageComplete
        add     hl, de                          ; Obtain FF location

        ld      a, (hl)
        cp      FFResetValue
        jp      z, ProcessOffScreenEnemy        ; Jump if no FF route to player

        cp      0       
        ret     z                               ; Return if current FF block is player block

; FF found, check all directions to find lowest value
        ld      (FFLowestValue), a      ; Save current lowest value

;-----------------------
; Check FF block up
; - Update enemy block offset
        ld      de, (EnemyBlockOffset)  ; Restore enemy block offset
        add     de, -BlockTileMapWidth  ; Point to block directly above
        ld      (EnemyBlockUpdated), de ; Backup updated block number

; - Update enemy FF block offset
        add     hl, -BlockTileMapWidthDisplay   ; Point to FF block above
        ld      (FFOffset), hl                  ; Backup updated FF block number

; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .UpNotPossible       ; Jump if value inaccessible e.g. Wall

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available enemy block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .UpNotPossible       ; Jump if block already occupied with another enemy - Do not move up

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .CheckURBlock        ; Jump if new value (hl) > lowest value (a)
        ;jp      z, .CheckURBlock        ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      hl, (FFOffset)
        ld      a, (hl)
        ld      (FFLowestValue), a      ; Save new lowest value

        ld      a, %00001000            
        ld      (FFDirection), a        ; Set direction - Up

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .CheckURBlock

.UpNotPossible:
        ld      a, (FFValidPaths)
        res     3, a                    ; Reset Up bit to prohibit up movement
        ld      (FFValidPaths), a

;-------------------------
; Check FF block Up Right
.CheckURBlock:
; - Update enemy block offset
        ld      de, (EnemyBlockUpdated) ; Restore enemy block offset
	inc	de			; Point to next column
        ld      (EnemyBlockUpdated), de ; Backup updated block number

	ld	hl, (FFOffset)		; Restore FFOffset
	inc	hl			; Point to next column
        ld      (FFOffset), hl
  
; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .CheckRightBlock     ; Jump if value inaccessible e.g. Wall

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .CheckRightBlock     ; Jump if block already occupied with another enemy - Do not move UR

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .CheckRightBlock     ; Jump if new value (hl) > lowest value (a)
        ;jp      z, .CheckRightBlock     ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      hl, (FFOffset)
        ld      a, (hl)
        ld      (FFLowestValue), a   ; Save new lowest value

        ld      a, %00001001       
        ld      (FFDirection), a                        ; Set direction - UR

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

;-------------------------
; Check FF block Up Right
.CheckRightBlock:
; - Update enemy block offset
        ld      de, (EnemyBlockUpdated) ; Restore enemy block offset
        add     de, BlockTileMapWidth   ; Point to block directly below
        ld      (EnemyBlockUpdated), de ; Backup updated block number

; - Update enemy FF block offset
	ld	hl, (FFOffset)		        ; Restore FFOffset
        add     hl, BlockTileMapWidthDisplay    ; Point to FF block below
        ld      (FFOffset), hl
  
; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .RightNotPossible    ; Jump if value inaccessible e.g. Wall 

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .RightNotPossible       ; Jump if block already occupied with another enemy

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .CheckDRBlock        ; Jump if new value (hl) > lowest value (a)
        ;jp      z, .CheckDRBlock        ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      hl, (FFOffset)
        ld      a, (hl)
        ld      (FFLowestValue), a                      ; Save new lowest value

        ld      a, %00000001        
        ld      (FFDirection), a                        ; Set direction - Right

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .CheckDRBlock

.RightNotPossible:
        ld      a, (FFValidPaths)
        res     0, a                    ; Reset Up bit to prohibit right movement
        ld      (FFValidPaths), a

;-------------------------
; Check FF block Down Right
.CheckDRBlock:
; - Update enemy block offset
        ld      de, (EnemyBlockUpdated) ; Restore enemy block offset
        add     de, BlockTileMapWidth   ; Point to block directly below
        ld      (EnemyBlockUpdated), de ; Backup updated block number

; - Update enemy FF block offset
	ld	hl, (FFOffset)		        ; Restore FFOffset
        add     hl, BlockTileMapWidthDisplay    ; Point to FF block below
        ld      (FFOffset), hl
  
; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .CheckDownBlock       ; Jump if value inaccessible e.g. Wall

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .CheckDownBlock      ; Jump if block already occupied with another enemy - Do not move down

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .CheckDownBlock      ; Jump if new value (hl) > lowest value (a)
        ;jp      z, .CheckDownBlock      ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      hl, (FFOffset)
        ld      a, (hl)
        ld      (FFLowestValue), a                      ; Save new lowest value

        ld      a, %00000101
        ld      (FFDirection), a                        ; Set direction - DR

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

;-------------------------
; Check FF block Down
.CheckDownBlock:
; - Update enemy block offset
        ld      de, (EnemyBlockUpdated) ; Restore enemy block offset
        dec     de                      ; Point to previous column
        ld      (EnemyBlockUpdated), de ; Backup updated block number

; - Update enemy FF block offset
	ld	hl, (FFOffset)		; Restore FFOffset
	dec	hl			; Point to previous column
        ld      (FFOffset), hl
  
; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .DownNotPossible     ; Jump if value inaccessible e.g. Wall 

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .DownNotPossible     ; Jump if block already occupied with another enemy 

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .CheckDLBlock        ; Jump if new value (hl) > lowest value (a)
        ;jp      z, .CheckDLBlock        ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      hl, (FFOffset)
        ld      a, (hl)
        ld      (FFLowestValue), a                      ; Save new lowest value

        ld      a, %00000100
        ld      (FFDirection), a                        ; Set direction - Down

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .CheckDLBlock

.DownNotPossible:
        ld      a, (FFValidPaths)
        res     2, a                    ; Reset Up bit to prohibit down movement
        ld      (FFValidPaths), a

;-------------------------
; Check FF block Down Left
.CheckDLBlock:
; - Update enemy block offset
        ld      de, (EnemyBlockUpdated) ; Restore enemy block offset
        dec     de                      ; Point to previous column
        ld      (EnemyBlockUpdated), de ; Backup updated block number

; - Update enemy FF block offset
	ld	hl, (FFOffset)		; Restore FFOffset
        dec     hl                      ; Point to previous column
        ld      (FFOffset), hl
  
; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .CheckLeftBlock      ; Jump if value inaccessible e.g. Wall

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .CheckLeftBlock      ; Jump if block already occupied with another enemy - Do not move DR

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .CheckLeftBlock      ; Jump if new value (hl) > lowest value (a)
        ;jp      z, .CheckLeftBlock      ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      hl, (FFOffset)
        ld      a, (hl)
        ld      (FFLowestValue), a                      ; Save new lowest value

        ld      a, %00000110
        ld      (FFDirection), a                        ; Set direction - DL

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

;-------------------------
; Check FF block Left
.CheckLeftBlock:
; - Update enemy block offset
        ld      de, (EnemyBlockUpdated) ; Restore enemy block offset
        add     de, -BlockTileMapWidth  ; Point to block directly above
        ld      (EnemyBlockUpdated), de ; Backup updated block number

; - Update enemy FF block offset
	ld	hl, (FFOffset)		        ; Restore FFOffset
        add     hl, -BlockTileMapWidthDisplay   ; Point to FF block above
        ld      (FFOffset), hl
  
; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .LeftNotPossible    ; Jump if value inaccessible e.g. Wall 

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .LeftNotPossible     ; Jump if block already occupied with another enemy 

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .CheckULBlock        ; Jump if new value (hl) > lowest value (a)
        ;jp      z, .CheckULBlock        ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      hl, (FFOffset)
        ld      a, (hl)
        ld      (FFLowestValue), a                      ; Save new lowest value

        ld      a, %00000010
        ld      (FFDirection), a                        ; Set direction - Left

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .CheckULBlock

.LeftNotPossible:
        ld      a, (FFValidPaths)
        res     1, a                    ; Reset Up bit to prohibit Left movement
        ld      (FFValidPaths), a

;-------------------------
; Check FF block Up Left
.CheckULBlock:
; - Update enemy block offset
        ld      de, (EnemyBlockUpdated) ; Restore enemy block offset
        add     de, -BlockTileMapWidth  ; Point to block directly above
        ld      (EnemyBlockUpdated), de ; Backup updated block number

; - Update enemy FF block offset
	ld	hl, (FFOffset)		        ; Restore FFOffset
        add     hl, -BlockTileMapWidthDisplay   ; Point to FF block above
        ld      (FFOffset), hl
  
; - Check for valid FF block
        ld      a, (hl)
        cp      FFResetValue
        jp      z, .FinishCheck         ; Jump if value inaccessible e.g. Wall

; - Check for populated friendly block bit
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

; - Check for available block bit
        ld      de, (EnemyBlockUpdated)
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .FinishCheck		; Jump if block already occupied with another enemy - Do not move UR

; - Check FF block value
        ld      hl, (FFOffset)
        ld      a, (FFLowestValue)      ; Restore current lowest value
        cp      (hl)
        jp      c, .FinishCheck		; Jump if new value (hl) > lowest value (a)
        ;jp      z, .FinishCheck         ; Jump if new value (hl) = lowest value (a)

; - Block available
        ld      a, %00001010
        ld      (FFDirection), a                        ; Set direction - UL

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

; Update enemy target information
.FinishCheck:
; - Update direction based on valid paths
        ld      a, (FFDirection)
        ld      d, a
        ld      a, (FFValidPaths)
        and     d                               ; a = valid paths, d = direction; result equals valid direction 

        cp      0
        jp      nz, .Continue                   ; Jump if enemy has a valid direction

        ld      hl, (EnemyBlockOffset)
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), hl

        ld      hl, (PlayerBlockXY)             ; Parameter for EnemyLoopAtEntity

        jp      EnemyLookAtEntity               ; Enemy can't move so look at player e.g. Enemy at player location or enemy blocked

.Continue:
        ld      (ix+S_SPRITE_TYPE.Movement), a  ; Otherwise set movement direction and continue

; - Check whether movement has changed and target block needs to be updated
        cp      d
        jp      z, .ProcessMovement             ; Jump if movement not changed

; - Update target block offset
        sla     a                                       ; Multiply movement by 2 due to table using words

        ld      hl, EnemyBlockUpdateTable
        add     hl, a                                   ; Add movement as offset to table
        ld      bc, (hl)                                ; Obtain block offset value
        
        ld      hl, (EnemyBlockOffset)
        add     hl, bc                                  ; Add block offset to current block
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), hl      ; Set target block

.ProcessMovement:
; Configure target and move enemy
; - Reset and set new block bits 
        ld      de, (ix+S_SPRITE_TYPE.MoveToBlock)
        call    EnemySetBlockMapBit             ; No need to check result as checks already performed above

        ld      de, (EnemyBlockOffset)
        call    EnemyResetBlockMapBit           ; No need to check result as checks already performed above

        call    ConfigureEnemyTarget
        call    MoveEnemy

        ret

;-------------------------------------------------------------------------------------
; Off Screen Enemy Movement - Not using FF
; Note: Used by enemy and friendly
; Parameters:
; ix = Enemy sprite
ProcessOffScreenEnemy:
; Check whether enemy has collided with player
        ld      a, (ix+S_SPRITE_TYPE.SprCollision)
        cp      1
        jp      nz, .NoCollision                        ; Jump if enemy not stopped by collision

; - Enemy stopped by collision, so look at player
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      hl, (PlayerBlockXY)
        ld      (EnemyBlockXY), de                      

        call    EnemyLookAtEntity

; - Check whether collided enemy should be allowed to flee (if hit by bullet) or stop 
        bit     5, (ix+S_SPRITE_TYPE.SpriteType5)
        ret     z                                       ; Return if enemy not allowed to flee

.NoCollision:
; Check whether enemy already travelling to player
        ld      a, (ix+S_SPRITE_TYPE.MoveToTarget)
        cp      1
        jp      z, MoveEnemy            ; Jump if enemy travelling to player

; Reset FF variables used for choosing path
        ld      a, %00000000
        ld      (NonFFValidPaths), a            ; Assume all paths are invalid %0000UDLR
        ld      (ix+S_SPRITE_TYPE.Movement), a  ; Reset movement     

; Check Enemy to Player horizontal position
; - Check whether enemy is fleeing
	bit	4, (ix+S_SPRITE_TYPE.SpriteType5)
	jp	nz, .FleeX

; Enemy not fleeing - FleeStatus flag not set
.NoFleeX:
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      (EnemyBlockOffset), bc                  ; Save Tilemap block offset
        ld      (EnemyBlockXY), de                      ; Save Tilemap block XY position
        ld      (ix+S_SPRITE_TYPE.MoveToBlockXY), de    ; Save Tilemap block offset

        ld      hl, (PlayerBlockXY)
        ld      a, h
        ld      b, a                    ; Player block
        ld      a, d                    ; Enemy block
        cp      b
        jp      c, .TryMoveRight        ; Jump if Player x position(b) > Enemy x position (d)

        jp      nz, .TryMoveLeft        ; Jump if Player x != Enemy x position

        jp      .TryMoveOnY             ; Otherwise jump as Player x = Enemy x


; - Enemy fleeing - FleeStatus flag set
.FleeX:
; - Check whether Movement flag also set
        bit     2, (ix+S_SPRITE_TYPE.SpriteType5)
        jp      z, .NotStraight                         ; Jump if enemy Movement flag is not set

        call    SpawnFlee

        jp      .FinishCheck

; - Enemy FleeStatus flag set but not Movement flag i.e. Move enemy based on player and not intial spawn direction
.NotStraight:
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      (EnemyBlockOffset), bc                  ; Save Tilemap block offset
        ld      (EnemyBlockXY), de                      ; Save Tilemap block XY position
        ld      (ix+S_SPRITE_TYPE.MoveToBlockXY), de    ; Save Tilemap block offset

        ld      hl, (PlayerBlockXY)
        ld      a, h
        ld      b, a                                    ; Player block
        ld      a, d                                    ; Enemy block
        cp      b
        jp      c, .TryMoveLeft                         ; Jump if Player x position(b) > Enemy x position (d)

        jp      nz, .TryMoveRight                       ; Jump if Player x != Enemy x position
        
; - Player x = Enemy x --- Move either left or right
        ld      a, r
        rrc     a
        jp      nc, .TryMoveRight

        jp      .TryMoveLeft

;----------------
; Left Checks
.TryMoveLeft:
; - Obtain block directly to left of enemy
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        dec     bc                      ; Point to left block

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check
        
.CheckLeftBlocks:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckLeft   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckLeft:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .TryMoveOnY          ; Jump if enemy not permitted to move

; - Update enemy to move left
        set     1, (ix+S_SPRITE_TYPE.Movement)  ; Set left

        ld      a, (NonFFValidPaths)
        set     1, a                    ; Set Left bit to allow left movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated) ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .TryMoveOnY

;----------------
; Right Checks
.TryMoveRight:
; - Obtain block directly to right of enemy
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        inc     bc                      ; Point to right block

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckRightBlocks:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckRight   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckRight:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .TryMoveOnY          ; Jump if enemy not permitted to move

; - Update enemy to move right
        set     0, (ix+S_SPRITE_TYPE.Movement)  ; Set right

        ld      a, (NonFFValidPaths)
        set     0, a                            ; Set Left bit to allow right movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

.TryMoveOnY:
; - Check whether enemy is fleeing
	bit	4, (ix+S_SPRITE_TYPE.SpriteType5)
	jp	nz, .FleeY

; - Enemy not fleeing
.NoFleeY:
; Check Enemy to Player vertical position
        ld      de, (EnemyBlockXY)      ; Restore Tilemap block XY

        ld      hl, (PlayerBlockXY)
        ld      a, l
        ld      b, a                    ; Player block
        ld      a, e                    ; Enemy block
        cp      b
        jp      c, .TryMoveDown         ; Jump if Player y position(b) > Enemy y position (e)

        jp      nz, .TryMoveUp          ; Jump if Player y != Enemy y position

        jp      .FinishCheck            ; Otherwise jump as Player y = Enemy y

; - Enemy fleeing
.FleeY:
; Check Enemy to Player vertical position
        ld      de, (EnemyBlockXY)      ; Restore Tilemap block XY

        ld      hl, (PlayerBlockXY)
        ld      a, l
        ld      b, a                    ; Player block
        ld      a, e                    ; Enemy block
        cp      b
        jp      c, .TryMoveUp           ; Jump if Player y position(b) > Enemy y position (e)

        jp      nz, .TryMoveDown        ; Jump if Player y != Enemy y position

; - Player y = Enemy y --- Move either up or down
        ld      a, r
        rrc     a
        jp      nc, .TryMoveDown

        jp      .TryMoveUp

;----------------
; Up Checks
.TryMoveUp:
; - Obtain block directly above enemy
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        add     bc, -BlockTileMapWidth  ; Point to block directly above

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckUpBlocks:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckUp   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckUp:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .FinishCheck                 ; Jump if enemy not permitted to move

; - Update enemy to move up
        set     3, (ix+S_SPRITE_TYPE.Movement)  ; Set up

        ld      a, (NonFFValidPaths)
        set     3, a                            ; Set Up bit to allow up movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .FinishCheck

;----------------
; Down Checks
.TryMoveDown:
; - Obtain block directly below enemy
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        add     bc, BlockTileMapWidth   ; Point to block directly below

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckDownBlocks:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckDown   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckDown:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .FinishCheck                 ; Jump if enemy not permitted to move

; - Update enemy to move down
        set     2, (ix+S_SPRITE_TYPE.Movement)  ; Set down

        ld      a, (NonFFValidPaths)
        set     2, a                            ; Set Down bit to allow down movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

; Update enemy target information
.FinishCheck:
; - Scenario 1 - Enemy within gap -  Update direction based on valid paths
        ld      a, (ix+S_SPRITE_TYPE.Movement)
        ;ld      d, a
        ;ld      a, (NonFFValidPaths)
        ;and     d                               ; a = valid paths, d = direction; result equals valid direction 

        ;ld      (ix+S_SPRITE_TYPE.Movement), a  ; Set movement direction

        ld      hl, (PlayerBlockXY)             ; Parameter for EnemyLoopAtEntity

        cp      %00000000
        jp      z, EnemyLookAtEntity            ; Jump if enemy cannot move

; - Scenario 2 - Enemy before gap        
        cp      %00001010       ; UpLeft
        jp      z, .CheckULBlock

        cp      %00001001       ; UpRight
        jp      z, .CheckURBlock

        cp      %00000110       ; DownLeft
        jp      z, .CheckDLBlock

        cp      %00000101       ; DownRight
        jp      z, .CheckDRBlock

        jp      .MoveEnemy

.CheckULBlock:
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        add     bc, -BlockTileMapWidth  ; Point to block directly above
        dec     bc                      ; Point to block on the left

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)
        ld      (EnemyBlockUpdated), bc ; Save block offset

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckULRestrictions:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckUL   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckUL:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check

; - Wall - Check for vertical wall tiles - Block Directly to UpLeft
        ;;ld      a, (BackupByte)         ; Restore block content
        ld      d, a
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .ULNotPossible      ; Jump if block type is a wall i.e. Value is <= BlocksWalls

        ld      de, bc ;(EnemyBlockUpdated) ; Parameter - Block number
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .ULNotPossible       ; Jump if block already occupied with another enemy - Do not move UL

        ld      bc, (EnemyBlockUpdated)
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc

        jp      .MoveEnemy

.ULNotPossible:
        res     1, (ix+S_SPRITE_TYPE.Movement)  ; Reset Left bit to prohibit left movement
                                                ; MoveToBlock previously set to up
        jp      .MoveEnemy

.CheckURBlock:
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        add     bc, -BlockTileMapWidth  ; Point to block directly above
        inc     bc                      ; Point to block on the right

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)
        ld      (EnemyBlockUpdated), bc ; Save block offset

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckURRestrictions:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckUR   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckUR:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check

; - Wall - Check for vertical wall tiles - Block Directly to UpRight
        ;;ld      a, (BackupByte)         ; Restore block content
        ld      d, a
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .URNotPossible      ; Jump if block type is a wall i.e. Value is <= BlocksWalls

        ld      de, bc                  ; Parameter - Block number
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .URNotPossible       ; Jump if block already occupied with another enemy - Do not move UR

        ld      bc, (EnemyBlockUpdated)
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc

        jp      .MoveEnemy

.URNotPossible:
        res     0, (ix+S_SPRITE_TYPE.Movement)  ; Reset Right bit to prohibit right movement
                                                ; MoveToBlock previously set to up

        jp      .MoveEnemy

.CheckDLBlock:
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        add     bc, BlockTileMapWidth   ; Point to block directly below
        dec     bc                      ; Point to block on the left

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)
        ld      (EnemyBlockUpdated), bc ; Save block offset

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckDLRestrictions:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckDL   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckDL:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check

; - Wall - Check for vertical wall tiles - Block Directly to DownLeft
        ld      d, a
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .DLNotPossible      ; Jump if block type is a wall i.e. Value is <= BlocksWalls

        ld      de, bc                  ; Parameter - Block number
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .DLNotPossible       ; Jump if block already occupied with another enemy - Do not move DL

        ld      bc, (EnemyBlockUpdated)
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc

        jp      .MoveEnemy

.DLNotPossible:
        res     1, (ix+S_SPRITE_TYPE.Movement)  ; Reset Left bit to prohibit left movement
                                                ; MoveToBlock previously set to down

        jp      .MoveEnemy

.CheckDRBlock:
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        add     bc, BlockTileMapWidth   ; Point to block directly below
        inc     bc                      ; Point to block on the right

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)
        ld      (EnemyBlockUpdated), bc ; Save block offset

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckDRRestrictions:
; Check blocks to permit movement
; - Check whether sprite is a friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassFriendlyCheckDR   ; Jump if sprite is a friendly

; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

.BypassFriendlyCheckDR:
        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check

; - Wall - Check for vertical wall tiles - Block Directly to DownRight
        ld      d, a
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .DRNotPossible      ; Jump if block type is a wall i.e. Value is <= BlocksWalls

        ld      de, bc                  ; Parameter - Block number
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .DRNotPossible       ; Jump if block already occupied with another enemy - Do not move DR

        ld      bc, (EnemyBlockUpdated)
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc

        jp      .MoveEnemy

.DRNotPossible:
        res     0, (ix+S_SPRITE_TYPE.Movement)  ; Reset Right bit to prohibit right movement
                                                ; MoveToBlock previously set to down

; Configure target and move enemy
.MoveEnemy:
; - Reset and set new block bits 
        ld      de, (ix+S_SPRITE_TYPE.MoveToBlock)
        call    EnemySetBlockMapBit             ; No need to check result as checks already performed above

        ld      de, (EnemyBlockOffset)
        call    EnemyResetBlockMapBit           ; No need to check result as checks already performed above

        call    ConfigureEnemyTarget
        call    MoveEnemy

        ret

/*
;-------------------------------------------------------------------------------------
; Waypoint Enemy Movement - Not using FF, and not using Block Maps; moves directly around screen
; Parameters:
; ix = Enemy sprite
ProcessWayPointEnemy:

        ld      a, (ix+S_SPRITE_TYPE.Movement)
        ld      (ix+S_SPRITE_TYPE.Movement3), a ; Required as used by MoveEnemy routine

        call    MoveEnemy

        ld      a, (ix+S_SPRITE_TYPE.Movement)
        cp      0
        ret     nz

; Target waypoint reached - Configure enemy with new target waypoint data
        ld      hl, (ix+S_SPRITE_TYPE.EnemyWayPoint)
        ld      iy, hl

        ld      hl, (iy+S_WAYPOINT_DATA.NextWayPoint)
        ld      (ix+S_SPRITE_TYPE.EnemyWayPoint), hl
        
        ld      hl, (iy+S_WAYPOINT_DATA.XWorldCoordinate)       
        ld      (ix+S_SPRITE_TYPE.MoveTargetX), hl              ; Assign target x world coordinate
        ld      hl, (iy+S_WAYPOINT_DATA.YWorldCoordinate)
        ld      (ix+S_SPRITE_TYPE.MoveTargetY), hl              ; Assign target y world coordinate

; - Configure enemy with initial movement direction
        ld      bc, (ix+S_SPRITE_TYPE.YWorldCoordinate)         ; Enemy y coordinate
        or      a
        sbc     hl, bc                                          ; hl = target waypoint, bc = enemy
        jp      z, .CheckHorizontal                             ; Jump if enemy and target waypoint at same y coordinate

        jp      c, .MoveUp                                      ; Jump if target waypoint is above enemy

        ld      (ix+S_SPRITE_TYPE.Movement), %00000100          ; Otherwise move enemy down
        ret

.MoveUp:
        ld      (ix+S_SPRITE_TYPE.Movement), %00001000          ; Move enemy up
        ret

.CheckHorizontal:
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)         ; Enemy y coordinate
        ld      hl, (iy+S_WAYPOINT_DATA.XWorldCoordinate)       ; Target waypoint coordinate

        or      a
        sbc     hl, bc                                          ; hl = target waypoint, bc = enemy
        jp      c, .MoveLeft                                    ; Jump if target waypoint is left of enemy

        ld      (ix+S_SPRITE_TYPE.Movement), %00000001          ; Otherwise move enemy right
        ret

.MoveLeft:
        ld      (ix+S_SPRITE_TYPE.Movement), %00000010          ; Move enemy left
        ret
*/

;-------------------------------------------------------------------------------------
; Waypoint Enemy Movement - Not using FF, but moves using Block Map
; Parameters:
; ix = Enemy sprite
ProcessWayPointEnemy:
; Check whether enemy has collided with player
        ;;;ld      a, (ix+S_SPRITE_TYPE.SprCollision)
        ;;;cp      1
        ;;;ret     z                                       ; Return if enemy involved in collision

; Check whether enemy already travelling to target tile
        ld      a, (ix+S_SPRITE_TYPE.MoveToTarget)
        cp      1
        jp      z, MoveEnemy                            ; Jump if enemy travelling to waypoint

; Enemy reached tile
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        ld      (EnemyBlockOffset), bc                  ; Save Tilemap block offset

	ld	a, (ix+S_SPRITE_TYPE.Movement)
	cp	%00001000
	jp	z, .TryMoveUp                           ; Jump if enemy currently moving up

	cp	%00000100
	jp	z, .TryMoveDown                         ; Jump if enemy currently moving down

	cp	%00000010
	jp	z, .TryMoveLeft                         ; Jump if enemy currently moving left

;----------------
; Right Checks
.TryMoveRight:
; - Check whether current waypoint reached
        ld      hl, (ix+S_SPRITE_TYPE.EnemyWayPoint)
        ld      iy, hl
        ld      de, (iy+S_WAYPOINT_DATA.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)

        or      a
        sbc     hl, de
        jp      z, .NewWayPoint         ; Jump if enemy reached current waypoint

; - Waypoint not reached, obtain block directly to right of enemy
        inc     bc                      ; Point to right block

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckRightBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .PreviousWayPoint    ; Jump if enemy not permitted to move

; - Update enemy to move right
        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

	jp	.MoveEnemy
;----------------
; Up Checks
.TryMoveUp:
; - Check whether current waypoint reached
        ld      hl, (ix+S_SPRITE_TYPE.EnemyWayPoint)
        ld      iy, hl
        ld      de, (iy+S_WAYPOINT_DATA.YWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)

        or      a
        sbc     hl, de
        jp      z, .NewWayPoint                 ; Jump if enemy reached current waypoint

; - Waypoint not reached, obtain block directly above enemy
        add     bc, -BlockTileMapWidth  ; Point to block directly above

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckUpBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .PreviousWayPoint    ; Jump if enemy not permitted to move

; - Update enemy to move up
        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .MoveEnemy

;----------------
; Down Checks
.TryMoveDown:
; - Check whether current waypoint reached
        ld      hl, (ix+S_SPRITE_TYPE.EnemyWayPoint)
        ld      iy, hl
        ld      de, (iy+S_WAYPOINT_DATA.YWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)

        or      a
        sbc     hl, de
        jp      z, .NewWayPoint                 ; Jump if enemy reached current waypoint

; - Waypoint not reached, obtain block directly below enemy
        add     bc, BlockTileMapWidth   ; Point to block directly below

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckDownBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .PreviousWayPoint    ; Jump if enemy not permitted to move

; - Update enemy to move down
        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

	jp	.MoveEnemy

;----------------
; Left Checks
.TryMoveLeft:
; - Check whether current waypoint reached
        ld      hl, (ix+S_SPRITE_TYPE.EnemyWayPoint)
        ld      iy, hl
        ld      de, (iy+S_WAYPOINT_DATA.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)

        or      a
        sbc     hl, de
        jp      z, .NewWayPoint                 ; Jump if enemy reached current waypoint

; - Waypoint not reached, obtain block directly to left of enemy
        dec     bc                      ; Point to left block

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check
        
.CheckLeftBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .PreviousWayPoint    ; Jump if enemy not permitted to move

; - Update enemy to move left
        ld      bc, (EnemyBlockUpdated) ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .MoveEnemy

; Target waypoint can't be reached - Point back to previous waypoint
.PreviousWayPoint:
        ld      de, (ix+S_SPRITE_TYPE.EnemySpawnPoint)  ; Variable also stores previous waypoint
        ld      iy, de

; - Store target waypoint as new previous waypoint
        ld      hl, (ix+S_SPRITE_TYPE.EnemyWayPoint)
        ld      (ix+S_SPRITE_TYPE.EnemySpawnPoint), hl  

; - Store previous waypoint as new target waypoint
        ld      (ix+S_SPRITE_TYPE.EnemyWayPoint), de

        jp      .SetDirection

; Target waypoint reached - Configure enemy with new target waypoint data
.NewWayPoint:
; - Store current waypoint as new previous waypoint
        ld      hl, (ix+S_SPRITE_TYPE.EnemyWayPoint)
        ld      (ix+S_SPRITE_TYPE.EnemySpawnPoint), hl
        ld      iy, hl

; - Store next waypoint as new target waypoint
        ld      hl, (iy+S_WAYPOINT_DATA.NextWayPoint)
        ld      (ix+S_SPRITE_TYPE.EnemyWayPoint), hl
        ld      iy, hl

; - Configure enemy with initial movement direction
.SetDirection:
        ld      bc, (ix+S_SPRITE_TYPE.YWorldCoordinate)         ; Enemy y coordinate
        ld      hl, (iy+S_WAYPOINT_DATA.YWorldCoordinate)       ; Target waypoint coordinate
        or      a
        sbc     hl, bc                                          ; hl = target waypoint, bc = enemy
        jp      z, .CheckHorizontal                             ; Jump if enemy and target waypoint at same y coordinate

        jp      c, .MoveUp                                      ; Jump if target waypoint is above enemy

        ld      (ix+S_SPRITE_TYPE.Movement), %00000100          ; Otherwise move enemy down
        ret

.MoveUp:
        ld      (ix+S_SPRITE_TYPE.Movement), %00001000          ; Move enemy up
        ret

.CheckHorizontal:
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)         ; Enemy y coordinate
        ld      hl, (iy+S_WAYPOINT_DATA.XWorldCoordinate)       ; Target waypoint coordinate

        or      a
        sbc     hl, bc                                          ; hl = target waypoint, bc = enemy
        jp      c, .MoveLeft                                    ; Jump if target waypoint is left of enemy

        ld      (ix+S_SPRITE_TYPE.Movement), %00000001          ; Otherwise move enemy right
        ret

.MoveLeft:
        ld      (ix+S_SPRITE_TYPE.Movement), %00000010          ; Move enemy left
        ret

; Configure target and move enemy
.MoveEnemy:
; - Reset and set new block bits 
        ld      de, (ix+S_SPRITE_TYPE.MoveToBlock)
        call    EnemySetBlockMapBit             ; No need to check result as checks already performed above

        ld      de, (EnemyBlockOffset)
        call    EnemyResetBlockMapBit           ; No need to check result as checks already performed above

        call    ConfigureEnemyTarget
        call    MoveEnemy

        ret

;-------------------------------------------------------------------------------------
; Check blocks to permit movement - Non-FF
; Params:
; a = TileMapLevel block to check
; bc = EnemyBlockOffset
; ix = Sprite Data
; Return:
; a = 0 (Block enemy move), 1 (Allow enemy to move)
CheckOffScreenBlocks:
        ld      de, bc                  ; Used for block bit check
        ld      (EnemyBlockUpdated), bc ; Backup updated block number

; Check for wall blocks
        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      nc, .EnemyCannotMove	; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move

; Check for locked door blocks 
        ld      a, b
        cp      HorDoor1End+1
        jp      z, .EnemyCannotMove	; Jump if block is locked door

        cp      HorDoorTrigger
        jp      z, .EnemyCannotMove     ; Jump if block is locked door

        cp      VerDoor1End+1
        jp      z, .EnemyCannotMove	; Jump if block is locked door

        cp      VerDoorTrigger
        jp      z, .EnemyCannotMove     ; Jump if block is locked door

; 16/10/23 - Removed Reverse Hazard check as it was causing issue with way points enemies
; Check for Reverse-Hazard - Bypass for Friendly
        bit     7, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassReverseHazardBlock   ; Jump if friendly

; Check for Reverse-Hazard - Bypass for Waypoint
        bit     3, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      nz, .BypassReverseHazardBlock   ; Jump if waypoint

        cp      ReverseHazardBlock
        jp      z, .EnemyCannotMove

.BypassReverseHazardBlock:
; Check for Door Lockdown + Unlocked Door
        ld      d, a

        ld      a, (DoorLockdown)
        cp      0
        jp      z, .CheckBlockMap               ; Jump if DoorLockdown not enabled

        ld      a, d
        cp      HorDoorStart
        jp      z, .EnemyCannotMove

        cp      VerDoorStart
        jp      z, .EnemyCannotMove

.CheckBlockMap:
        ld      de, (EnemyBlockUpdated)         ; Restore Tilemap block number

; Check block map for tile availability        
        call    EnemyCheckBlockMapBit
        cp      0
        jp      z, .EnemyCannotMove	; Jump if block already occupied with another enemy - Do not move

; Otherwise allow enemy to move
	ld	a, 1		; Return value
	ret

; Block enemy move
.EnemyCannotMove:
	ld	a, 0		; Return value
	ret

;-------------------------------------------------------------------------------------
; Configure Enemy Movement Target - FF and Non-FF
; Parameters:
; ix = Enemy sprite
ConfigureEnemyTarget:
        ld      a, (ix+S_SPRITE_TYPE.Movement)
        ld      (ix+S_SPRITE_TYPE.Movement3), a         ; Saved in the event Movement changed at collision/LookatEntity

; - Check Up bit
        bit     3, a
        jp      z, .CheckDownBit                        ; Jump if bit not set

; - Update to move enemy up
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      de, 16
        sub     hl, de                                  ; Point 16 pixels up

        ld      (ix+S_SPRITE_TYPE.MoveTargetY), hl      ; Set target Y position

        jp      .CheckLeftBit

; - Check Up bit
.CheckDownBit:
        bit     2, a
        jp      z, .CheckLeftBit                        ; Jump if bit not set

; - Update to move enemy down
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      de, 16
        add     hl, de                                  ; Point 16 pixels down

        ld      (ix+S_SPRITE_TYPE.MoveTargetY), hl      ; Set target Y position

; - Check Left bit
.CheckLeftBit:
        bit     1, a
        jp      z, .CheckRightBit                       ; Jump if bit not set

        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      de, 16
        sub     hl, de                                  ; Point 16 pixels to the left

        ld      (ix+S_SPRITE_TYPE.MoveTargetX), hl      ; Set target X position

        jp      .FinishUpdate

; - Check Right bit
.CheckRightBit:
        bit     0, a
        jp      z, .FinishUpdate                        ; Jump if bit not set

        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     hl, 16                                  ; Point 16 pixels to the right

        ld      (ix+S_SPRITE_TYPE.MoveTargetX), hl      ; Set target X position

; - Finalise enemy target information
.FinishUpdate:
        ld      a, 1
        ld      (ix+S_SPRITE_TYPE.MoveToTarget), a      ; Set to move to target

        ret

;-------------------------------------------------------------------------------------
; Enemy Movement - FF and Non-FF
; Parameters:
; ix = Enemy sprite
MoveEnemy:
        ld      a, (ix+S_SPRITE_TYPE.Movement3)         
        ld      (ix+S_SPRITE_TYPE.Movement),a           ; Restore saved movement in case its changed via collision/LookAtEntity

; Update enemy sprite orientation
        ld      iy, ix
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        call    UpdateSpriteOrientation
        ld      ix, iy

; Move enemy
        ld      a, (ix+S_SPRITE_TYPE.Movement)

        bit     3, a
        call    nz, .MoveUp                              ; Jump if movement up

        bit     2, a
        call    nz, .MoveDown                            ; Jump if movement down

        bit     1, a
        call    nz, .MoveLeft                            ; Jump if movement left

        bit     0, a
        call    nz, .MoveRight                           ; Jump if movement right

; Check whether animation should be played
        cp      0
        ret     z                                       ; Return if enemy has not moved

; - Otherwise play animation
        push    ix

        ld      iy, ix
        ld      bc, (ix+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        ld      bc, (iy+S_SPRITE_TYPE.patternRange)     ; Sprite pattern range - Keep existing

        call    UpdateSpritePattern

        pop     ix

        ret

.MoveUp:
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      bc, (ix+S_SPRITE_TYPE.MoveTargetY)
        sub     hl, bc
        jp      z, .ResetEnemy                          ; Jump if enemy at target world coordinate

; Move enemy towards target world coordinate
; TODO - Update speed
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        dec     hl

        bit     1, (ix+S_SPRITE_TYPE.Speed)
        jp      z, .UpCont                              ; Jump if speed != 2

        dec     hl

.UpCont:
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

        ret

.MoveDown:
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        ld      bc, (ix+S_SPRITE_TYPE.MoveTargetY)
        sub     hl, bc
        jp      z, .ResetEnemy                          ; Jump if enemy at target world coordinate

; Move enemy towards target world coordinate
; TODO - Update speed
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        inc     hl

        bit     1, (ix+S_SPRITE_TYPE.Speed)
        jp      z, .DownCont                            ; Jump if speed != 2

        inc     hl

.DownCont:
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), hl

        ret

.MoveLeft:
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      bc, (ix+S_SPRITE_TYPE.MoveTargetX)
        sub     hl, bc
        jp      z, .ResetEnemy                          ; Jump if enemy at target world coordinate

; Move enemy towards target world coordinate
; TODO - Update speed
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        dec     hl

        bit     1, (ix+S_SPRITE_TYPE.Speed)
        jp      z, .LeftCont                            ; Jump if speed != 2

        dec     hl

.LeftCont:
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl

        ret

.MoveRight:
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      bc, (ix+S_SPRITE_TYPE.MoveTargetX)
        sub     hl, bc
        jp      z, .ResetEnemy                          ; Jump if enemy at target world coordinate

; Move enemy towards target world coordinate
; TODO - Update speed
        ld      hl, (ix+S_SPRITE_TYPE.XWorldCoordinate)

        inc     hl

        bit     1, (ix+S_SPRITE_TYPE.Speed)
        jp      z, .RightCont                           ; Jump if speed != 2

        inc     hl

.RightCont:
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), hl

        ret

; Reset enemy to enable it to re-check FF map
.ResetEnemy:
        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.MoveToTarget), a      ; Reset target flag

        bit     3, (ix+S_SPRITE_TYPE.SpriteType3)
        ret     nz                                      ; Return if waypoint enemy

        ld      (ix+S_SPRITE_TYPE.Movement), a          ; otherwise reset movement flag

        ret

;-------------------------------------------------------------------------------------
; Enemy Block Tracking - Check block bit
; Parameters:
; de = Tilemap block number
; Return:
; a = Status (0=Occupied, 1=Unoccupied)
EnemyCheckBlockMapBit:
        ld      (BackupWord2), de       ; Backup tilemap block number

        call    EnemyGetBlockMapBit     ; Get updated byte

; Check whether byte has changed i.e. Is the block available
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .Unoccupied          ; Jump if source block bit not set i.e. Unoccupied

.Occupied:
; - Block unavailable i.e. Enemy current occupies block
        bit     3, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      z, .Exit                    		; Jump if not waypoint enemy

; - Waypoint enemy - Find enemy occupying block
        ld      iy, EnemySpritesStart

        ld      a, MaxEnemy
        ld      b, a
.FindEnemyLoop:
        ld      de, (BackupWord2)                       ; Restore tilemap block number
        ld      hl, (iy+S_SPRITE_TYPE.MoveToBlock)

        or      a
        sbc     hl, de
        jp      z, .EnemyFound                 		; Jump if enemy found matching tilemap block number 

        ld      de, S_SPRITE_TYPE
        add     iy, de

        djnz    .FindEnemyLoop

; - Met in the event a friendly and not an enemy occurs the block; friendly map also managed in FriendlyCheckBlockMapBit
        ld      a, 1                                    ; Return unoccupied, so waypoint can move over friendly
	ret

.EnemyFound:
; - Waypoint enemy hit enemy - Destroy immediately
        ld      a, 0
        ld      (iy+S_SPRITE_TYPE.Energy), a

; - Set not destroyed by player flag; used for activities such as ensuring points aren't awarded, or collectibles spawned
        set     3, (iy+S_SPRITE_TYPE.SpriteType4)

; - Reset Disabled flag - Ensures Terminator can be deleted
        res     3, (iy+S_SPRITE_TYPE.SpriteType1)

; - Reset Terminator flag - Ensures Terminator can be deleted
        res     1, (iy+S_SPRITE_TYPE.SpriteType3)

; - Set Destroyed by Waypoint flag - Ensures BlockMapBit is updated via waypoint enemy and not enemy
        set     0, (iy+S_SPRITE_TYPE.SpriteType4)
        jp      .Unoccupied

.Exit:
        ld      a, 0                    ; Return: Failure
        ret

.Unoccupied:
; - Block available
        ld      a, 1                    ; Return: Success
        ret

;-------------------------------------------------------------------------------------
; Friendly Block Tracking - Check block bit
; Parameters:
; de = Tilemap block number
; ix = Enemy/Friendly sprite data
; EnemyBlockOffset
; Return:
; a = Status (0=Occupied, 1=Unoccupied)
FriendlyCheckBlockMapBit:
        ld      (BackupWord2), de        ; Backup tilemap block number

        call    FriendlyGetBlockMapBit  ; Get updated byte

; Check whether byte has changed i.e. Does the block contain a friendly
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .Unoccupied          ; Jump if source block bit not set i.e. Unoccupied

.Occupied:
; Block occupied i.e. Friendly currently occupies block
; - Find friendly occupying block
        ld      iy, FriendlySpritesStart

        ld      a, (FriendlyInLevel)
        ld      b, a
.FindFriendlyLoop:
        ld      de, (BackupWord2)                       ; Restore tilemap block number
        ld      hl, (iy+S_SPRITE_TYPE.MoveToBlock)

        or      a
        sbc     hl, de
        jp      z, .FriendlyFound                       ; Jump if friendly found matching tilemap block number 

        ld      de, S_SPRITE_TYPE
        add     iy, de

        djnz    .FindFriendlyLoop

; - Friendly sprite data not found matching friendly tilemap block number
;   This condition should't be met, as the friendly map indicates a friendly is present 
        jp      .Unoccupied

.FriendlyFound:
        bit     3, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      z, .NotWayPointEnemy                    ; Jump if not waypoint enemy

; - Waypoint enemy hit friendly
        ld      a, (iy+S_SPRITE_TYPE.Energy)
        ld      b, a
        call    FriendlyTakeDamage

        ld      a, 1                    ; Return unoccupied, so waypoint can move over friendly
        ret

; - Point enemy at friendly
.NotWayPointEnemy:
        ld      hl, (iy+S_SPRITE_TYPE.MoveToBlockXY)    ; Friendly block X/Y to look at
        push    iy
        call    EnemyLookAtEntity
        pop     iy
        
.SkipLookAtEntity:
        ld      hl, (EnemyBlockOffset)
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), hl      ; Reset MoveToBlock to ensure enemy pointing back at current block

; - Friendly take damage
        ld      a, (ix+S_SPRITE_TYPE.Damage)
        ld      b, a
        call    FriendlyTakeDamage

.Exit:
        ld      a, 0                    ; Return: Occupied
        ret

.Unoccupied:
; Block unoccupied i.e. Friendly not in block
        ld      a, 1                    ; Return: Unoccupied
        ret

;-------------------------------------------------------------------------------------
; Enemy Block Tracking - Set block bit
; Parameters:
; de = Tilemap block new number
; Return:
; a = Success (0=Failed, block already occupied, 1=Success, Block updated)
EnemySetBlockMapBit:
        ld      (BackupWord2), de       ; Save tilemap block number
        call    EnemyGetBlockMapBit     ; Get updated byte

; Check whether byte has changed i.e. Is the block available
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .Unoccupied          ; Jump if source block bit not set i.e. Unoccupied

.Occupied:
; - Block unavailable i.e. Enemy current occupies block
        ld      a, 0                    ; Return: Failure
        ret

.Unoccupied:
; EnemyMovementBlockMap
; - Block available, so write new block bit byte
        ld      (iy), b                 ; Write new block bit byte to EnemyMovementBlockMap buffer

; FriendlyMovementBlockMap
; - Check whether we also need to update the FriendlyMovementBlockMap
        bit     6, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      z, .Exit                ; Jump if not activate friendly

        ld      de, (BackupWord2)       ; Restore tilemap block number
        call    FriendlyGetBlockMapBit  ; Get updated byte

; - Check whether byte has changed i.e. Is the block available
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .FriendlyUnoccupied  ; Jump if source block bit not set i.e. Unoccupied

; - Block unavailable i.e. Friendly currently occupies block
        ld      a, 0                    ; Return: Failure

        ret

.FriendlyUnoccupied:
; - Block available, so write new block bit byte
        ld      (iy), b                 ; Write new block bit byte to FriendlyMovementBlockMap buffer

.Exit:
        ld      a, 1                    ; Return: Success

        ret

;-------------------------------------------------------------------------------------
; Enemy Block Tracking - Reset block bit (Enemy BlockMap + Friendly BlockMap)
; Parameters:
; de = Tilemap block number
; Return:
; a = Success (0=Failed, block not currently occupied, 1=Success, block now unoccupied)
EnemyResetBlockMapBit:
        ld      (BackupWord2), de       ; Save tilemap block number
        call    EnemyGetBlockMapBit     ; Get updated byte

; Check status of new byte i.e. Has it managed to reset the block bit byte
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .BitNotReset         ; Jump if new block bit is greater i.e. Not able to reset bit

.ResetBit:
; EnemyMovementBlockMap
; - Reset block bit
        ld      (iy), b                 ; Write new block bit byte to EnemyMovementBlockMap buffer

; FriendlyMovementBlockMap
; - Check whether we also need to reset the FriendlyMovementBlockMap
        bit     6, (ix+S_SPRITE_TYPE.SpriteType3)
        jp      z, .Exit                ; Jump if not activated friendly

        ld      de, (BackupWord2)       ; Restore tilemap block number
        call    FriendlyGetBlockMapBit  ; Get updated byte

; - Check status of new byte i.e. Has it managed to reset the block bit byte
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .BitNotReset         ; Jump if new block bit is greater i.e. Not able to reset bit

; - Reset block bit
        ld      (iy), b                 ; Write new block bit byte to FriendlyMovementBlockMap buffer

.Exit:
        ld      a, 1                    ; Return: Success
        ret

.BitNotReset:
; - Source block bit is not set, so can't be reset
        ld      a, 0                    ; Return: Failure
        ret

;-------------------------------------------------------------------------------------
; Friendly Block Tracking - Reset block bit (Friendly BlockMap)
; Parameters:
; de = Tilemap block number
; Return:
; a = Success (0=Failed, block not currently occupied, 1=Success, block now unoccupied)
FriendlyResetBlockMapBit:
        call    FriendlyGetBlockMapBit  ; Get updated byte

; - Check status of new byte i.e. Has it managed to reset the block bit byte
        ld      b, a
        ld      a, (iy)                 ; Source byte
        cp      b
        jp      c, .BitNotReset         ; Jump if new block bit is greater i.e. Not able to reset bit

; - Reset block bit
        ld      (iy), b                 ; Write new block bit byte to FriendlyMovementBlockMap buffer

.Exit:
        ld      a, 1                    ; Return: Success
        ret

.BitNotReset:
; - Source block bit is not set, so can't be reset
        ld      a, 0                    ; Return: Failure
        ret

;-------------------------------------------------------------------------------------
; Enemy Block Tracking - Obtain byte containing block bit
; --- Memory based Solution ---
; Uses a buffer to identify which tilemap blocks contain enemies. To save memory, each byte contains reference to 8 blocks
; i.e. 1 bit per block, resulting in 1/8 of the tilemap memory allocated to the buffer
; Parameters:
; de = Tilemap block number for required block bit 
; Return:
; iy = Pointer to current byte containing block bit 
; a = Updated byte containing block bit; not yet written to buffer
; de = EnemyMovementBlockOffset
EnemyGetBlockMapBit:
; Obtain byte and bit offset within buffer
        push    de              ; Save block number

        ld      iy, EnemyMovementBlockMap
        
; - Calculate byte offset
        ld      b, 3            ; Rotate right by 3 i.e. divide by 8
        bsra    de, b           ; Byte in EnemyBlockMap (de) = block / 8
             
        add     iy, de          ; Return: Add byte offset

        ld      (BackupWord1), de        ; Backup EnemyBlockMap offset

; - Calculate bit within byte
        bsla    de, b           ; de * 8
        
        pop     hl              ; Restore block number

        sub     hl, de          ; Bit in byte (l)

; - Create register with required bit set
	ld	d, 0
	ld	e, 1
	ld	a, l            ; Bit
	ld	b, a
	bsla	de, b	        ; de = new byte with just bit set

; - Obtain updated byte containing bit
	ld	a, (iy)         ; Source byte
	xor	e	        ; Return: a (If bit=0 then block=occupied, bit=1 then block=unoccupied)

        ld      de, (BackupWord1)        ; Return: de (EnemyBlockMap offset)

        ret

;-------------------------------------------------------------------------------------
; Friendly Block Tracking - Obtain byte containing block bit
; --- Memory based Solution ---
; Uses a buffer to identify which tilemap blocks contain friendlies. To save memory, each byte contains reference to 8 blocks
; i.e. 1 bit per block, resulting in 1/8 of the tilemap memory allocated to the buffer
; Parameters:
; de = Tilemap block number for required block bit 
; Return:
; iy = Pointer to current byte containing block bit 
; a = Updated byte containing block bit; not yet written to buffer
; de = FriendlyMovementBlockOffset
FriendlyGetBlockMapBit:
; Obtain byte and bit offset within buffer
        push    de              ; Save block number

        ld      iy, FriendlyMovementBlockMap
        
; - Calculate byte offset
        ld      b, 3            ; Rotate right by 3 i.e. divide by 8
        bsra    de, b           ; Byte in FriendlyBlockMap (de) = block / 8
             
        add     iy, de          ; Return: Add byte offset

        ld      (BackupWord1), de        ; Backup FriendlyBlockMap offset

; - Calculate bit within byte
        bsla    de, b           ; de * 8
        
        pop     hl              ; Restore block number

        sub     hl, de          ; Bit in byte (l)

; - Create register with required bit set
	ld	d, 0
	ld	e, 1
	ld	a, l            ; Bit
	ld	b, a
	bsla	de, b	        ; de = new byte with just bit set

; - Obtain updated byte containing bit
	ld	a, (iy)         ; Source byte
	xor	e	        ; Return: a (If bit=0 then block=occupied, bit=1 then block=unoccupied)

        ld      de, (BackupWord1)        ; Return: de (FriendlyBlockMap offset)

        ret

;-------------------------------------------------------------------------------------
; Point enemy at entity (player/friendly) when enemy cannot move
; Parameters:
; hl = BlockXY to look at (byte1=x, byte2=y)
; EnemyBlockXY
EnemyLookAtEntity:
        ld      a, 0
        ld      (EnemyLookAtEntityPaths), a
        
	ld	de, (EnemyBlockXY)

        ld      a, h
        ld      b, a                    ; Entity block
        ld      a, d                    ; Enemy block
        cp      b
        jp      c, .LookRight        	; Jump if entity x position(b) > Enemy x position (d)

        jp      z, .CheckVertical       ; Jump if entity x position(b) = Enemy x position (d)

; Enemy should look left to entity
        ld      a, (EnemyLookAtEntityPaths)
        add     2                       ; ----UDLR
        ld      (EnemyLookAtEntityPaths), a

	jp	.CheckVertical

.LookRight:
; Enemy should look right to entity
        ld      a, (EnemyLookAtEntityPaths)
        add     1                       ; ----UDLR
        ld      (EnemyLookAtEntityPaths), a

.CheckVertical:
        ld      a, l
        ld      b, a                    ; Player block
        ld      a, e                    ; Entity block
        cp      b
        jp      c, .LookDown		; Jump if entity y position(b) > Enemy y position (e)

        jp      z, .LookAtEntity       ; Jump if entity x position(b) = Enemy x position (d)

; Enemy should look up to entity
        ld      a, (EnemyLookAtEntityPaths)
        add     8                       ; ----UDLR
        ld      (EnemyLookAtEntityPaths), a

	jp	.LookAtEntity

.LookDown:
; Enemy should look down to entity
        ld      a, (EnemyLookAtEntityPaths)
        add     4                       ; ----UDLR
        ld      (EnemyLookAtEntityPaths), a

.LookAtEntity:
        ld      a, (EnemyLookAtEntityPaths)
        cp      0
        ret     z                                       ; Return if no paths i.e. Enemy on same block as player

        ld      (ix+S_SPRITE_TYPE.Movement), a          ; Otherwise point enemy to player

        ld      iy, ix
        ld      bc, (iy+S_SPRITE_TYPE.AttrOffset)       
        ld      ix, bc                                  ; Destination - Sprite Attributes
        call    UpdateSpriteOrientation
        ld      ix, iy

        ret

;-------------------------------------------------------------------------------------
; Spawn Enemy at Spawn Points
; Parameters:
EnemySpawner:
        ld      ix, SpawnPointData

        ld      a, (SpawnPointsInLevel)
        cp      0
        ret     z                               ; Return if no enemy spawn points

        ld      b, a
.SpawnPointLoop:
        push    bc

; 1. Check whether spawn point is active, enabled and in range
        ld      a, (ix+S_SPAWNPOINT_DATA.Active)
        cp      0
        jp      z, .NextSpawnPoint

        ld      a, (ix+S_SPAWNPOINT_DATA.DisableAtStart)
        cp      0
        jp      z, .EnabledSpawnPoint           ; Jump if spawnpoint should be processed

; - SpawnPoint Disabled
; - Trigger Condition - Check TriggerTarget
        ld      hl, (ix+S_SPAWNPOINT_DATA.TileBlockOffset)

        push    ix
        call    CheckTriggerTargetData
        pop     ix

        cp      1
        jp      nz, .NextSpawnPoint             ; Jump if trigger condition not met and cannot enable spawnpoint

; - Enable spawnpoint
; Play audio effect
        push    af, ix

        ld      a, AyFXSpawnPointEnabled
        call    AFX2Play

        pop     ix, af

        ld      a, 0
        ld      (ix+S_SPAWNPOINT_DATA.DisableAtStart), a        ; Enable spawnpoint
        
        ld      hl, (ix+S_SPAWNPOINT_DATA.TileBlockOffset)

; - Source Tilemap - Replace spawn point block
        ld      iy, (LevelTileMap)
        ld      bc, hl
        add     iy, bc                                          ; Add block offset

; -- Check which spawnpoint block to write
        ld      a, (ix+S_SPAWNPOINT_DATA.Reuse)
        cp      1
        jp      z, .SpawnPointType1                     ; Jump if spawnpoint reuse enabled

        ld      a, SpawnPoint2StartBlock
        jp      .WriteSpawnPointBlock

.SpawnPointType1:
        ld      a, SpawnPoint1StartBlock

.WriteSpawnPointBlock:
        ld      (iy), a                                 

; Screen Tilemap - Replace spawn point block
        ld      hl, (ix+S_SPAWNPOINT_DATA.TileBlockOffsetY)     ; Block x,y
        ld      de, bc                                          ; de = Block Offset

        push    ix                                      ; Save sprite pointer
        call    UpdateScreenTileMap
        pop     ix                                      ; Restore sprite pointer

.EnabledSpawnPoint
        ld      bc, (ix+S_SPAWNPOINT_DATA.WorldX)
        ld      de, (ix+S_SPAWNPOINT_DATA.WorldY)
        ld      hl, (ix+S_SPAWNPOINT_DATA.PlayerRange)
        call    CheckEntityInRange
        cp      0
        jp      z, .NextSpawnPoint              ; Return Value: Jump if spawnpoint not in range

; 2. Check spawn delay
        ld      a, (ix+S_SPAWNPOINT_DATA.SpawnDelay)
        cp      (ix+S_SPAWNPOINT_DATA.SpawnDelayCounter)
        jp      z, .SpawnEnemy                  ; Jump if we can spawn enemy

; - Increment spawn delay counter
        inc     (ix+S_SPAWNPOINT_DATA.SpawnDelayCounter)

        jp      .NextSpawnPoint

.SpawnEnemy:
; 3. Check whether max enemies have already been spawned
        ld      a, (ix+S_SPAWNPOINT_DATA.MaxEnemies)
        cp      (ix+S_SPAWNPOINT_DATA.MaxEnemiesCounter)
        jp      z, .NextSpawnPoint              ; Jump if max enemies have not been spawned

; 4. Spawn Enemy
; - Check enemy map to see whether spawn point is already occupied by a sprite
        ld      de, (ix+S_SPAWNPOINT_DATA.TileBlockOffset)

        push    ix
        ld      hl, (ix+S_SPAWNPOINT_DATA.EnemyType)
        ld      ix, hl                  ; Assign enemy to be spawned; used when checking for waypoint enemy flag
        call    EnemyCheckBlockMapBit
        pop     ix
        cp      0                       ; Return value
        jp      z, .NextSpawnPoint      ; Jump if cannot spawn sprite at required blockmap location

; - Spawn enemy
        ld      de, (ix+S_SPAWNPOINT_DATA.EnemyType)
        ld      iy, EnemySpritesStart
        ld      a, EnemyAttStart
        ld      b, MaxEnemy
        ld      hl, (ix+S_SPAWNPOINT_DATA.TileBlockOffsetY)

        push    ix
        ld      ix, de
        call    SpawnNewSprite
        ld      iy, ix        
        pop     ix

        cp      0                       ; Return: a
        jp      z, .NextSpawnPoint      ; Jump if sprite not spawned

; Play audio effect
        push    af, ix

        ld      a, AyFXSpawnEnemy
        call    AFX2Play

        pop     ix, af

        set     6, (iy+S_SPRITE_TYPE.SpriteType2)       ; Set spawn animation flag

; 5. Set/Process Flee/Spawn flags
; - Reset Flee/Spawn flags
        ld      a, (iy+S_SPRITE_TYPE.SpriteType5)
        ld      b, %11'0000'11
        and     b
        
        ld      (iy+S_SPRITE_TYPE.SpriteType5), a

; - Check Spawnpoint Flee flag Property
        ld      a, (ix+S_SPAWNPOINT_DATA.Flee)
        cp      0
        jp      z, .CheckSpawnPointProperty                     ; Jump if Flee flag not set on Spawnpoint

        set     5, (iy+S_SPRITE_TYPE.SpriteType5)               ; Enable Flee flag

; - Check Spawnpoint Spawn flag Property
.CheckSpawnPointProperty:
        ld      a, (ix+S_SPAWNPOINT_DATA.Spawn)
        cp      0
        jp      z, .ProcessFleeSpawnFlags                       ; Jump if Spawn flag not set on Spawnpoint

        set     3, (iy+S_SPRITE_TYPE.SpriteType5)               ; Enable Spawn flag

.ProcessFleeSpawnFlags:
; - Check whether spawned ememy has Spawn flag set - Requires additional settings
        bit     3, (iy+S_SPRITE_TYPE.SpriteType5)
        jp      z, .CheckFleeFlag                              ; Jump if enemy Spawn flag not set

; -- Spawn flag set
; - 1. Set Flee Direction and Movement flag
        ld      hl, SpawnDirection
        ld      a, (SpawnDirectionCounter)
        add     hl, a

        ld      a, (hl)
        cp      0
        jp      nz, .SetFleeDirection                           ; Jump if not at end of direction value table

.ResetCounter:
        ld      (SpawnDirectionCounter), a                      ; Otherwise reset table offset
        ld      a, (SpawnDirection)

.SetFleeDirection:
        ld      (iy+S_SPRITE_TYPE.Movement3), a

        ld      a, (SpawnDirectionCounter)
        inc     a
        ld      (SpawnDirectionCounter), a                      ; Point to next table entry

        set     2, (iy+S_SPRITE_TYPE.SpriteType5)               ; Set Movement flag

; - 2. Set invulnerability timeout
        ld      a, SpawnDelayDamageTime
        ld      (iy+S_SPRITE_TYPE.InvulnerableCounter), a       ; Set invulnerable timeout counter

; - 3. Set FleeStatus flag and timeout
        set     4, (iy+S_SPRITE_TYPE.SpriteType5)               ; Set FleeStatus flag

        call    CalculateFleeTime                               ; Return - a = Flee Time

        bit     1, (iy+S_SPRITE_TYPE.Speed)
        jp      z, .SetFleeCounter                              ; Jump if enemy speed is not 2

        srl     a                                               ; Otherwise divide flee time by 2, as enemy moves 2 positions/frame
	
.SetFleeCounter:
        ld	(iy+S_SPRITE_TYPE.DelayCounter), a              ; Set flee timeout counter

; - Check whether spawned ememy has Flee flag set - Requires additional settings
.CheckFleeFlag:
        bit     5, (iy+S_SPRITE_TYPE.SpriteType5)
        jp      z, .PostSpawnFleeCheck                          ; Jump if enemy Flee flag not set

; -- Flee flag set
; - 1. Set invulnerability timeout
        ld      a, SpawnDelayDamageTime
        ld      (iy+S_SPRITE_TYPE.InvulnerableCounter), a               ; Set invulnerable timeout counter

; - 2. Set FleeStatus flag and timeout
        set     4, (iy+S_SPRITE_TYPE.SpriteType5)               ; Set FleeStatus flag

        ld      a, (ix+S_SPAWNPOINT_DATA.EnemyDisableTimeout)
	ld	(iy+S_SPRITE_TYPE.DelayCounter), a              ; Set flee timeout counter

.PostSpawnFleeCheck:
; Check whether we need to update the spawned enemy count as part of DoorLockdown
        ld      a, (ix+S_SPAWNPOINT_DATA.RecordSpawned)
        cp      0
        jp      z, .ContEnemySpawn                              ; Jump if don't need to record spawned enemies for DoorLockdown

        ld      a, (RecordSpawnedNumber)
        inc     a                                       
        ld      (RecordSpawnedNumber), a                        ; Increment RecordSpawnedNumber count

.ContEnemySpawn:
        ld      a, (ix+S_SPAWNPOINT_DATA.EnemyEnergy)
        ld      (iy+S_SPRITE_TYPE.Energy), a                    ; Update spawned enemy - Energy
        ld      (iy+S_SPRITE_TYPE.EnergyReset), a               ; Update spawned enemy - Energy

        ld      a, (ix+S_SPAWNPOINT_DATA.EnemyDamage)
        ld      (iy+S_SPRITE_TYPE.Damage), a                    ; Update spawned enemy - Damage

        ld      a, (ix+S_SPAWNPOINT_DATA.EnemyDisableTimeout)
        ld      (iy+S_SPRITE_TYPE.EnemyDisableTimeOut), a       ; Update spawned enemy - Disable Timeout

        ld      hl, (ix+S_SPAWNPOINT_DATA.EnemyPlayerRange)
        ld      (iy+S_SPRITE_TYPE.Range), hl                    ; Update spawned enemy - Range

        bit     0, (iy+S_SPRITE_TYPE.SpriteType3)
        jp      z, .PostShooter                                 ; Jump if enemy not shooter

        ld      hl, (ix+S_SPAWNPOINT_DATA.BulletType)
        ld      (iy+S_SPRITE_TYPE.BulletType), hl               ; Update spawned enemy - Bullet Type
        
        push    ix, iy
        ld      ix, iy
        call    nz, SetupNewSpriteRotation                      ; Call if shooter sprite
        pop     iy, ix

.PostShooter:
        ld      hl, ix
        ld      (iy+S_SPRITE_TYPE.EnemySpawnPoint), hl          ; Associate enemy with spawn point

; - Update counters
        inc     (ix+S_SPAWNPOINT_DATA.MaxEnemiesCounter)        

        ld      (ix+S_SPAWNPOINT_DATA.SpawnDelayCounter), 0

; - Check whether max enemies have already been spawned
        ld      a, (ix+S_SPAWNPOINT_DATA.MaxEnemies)
        cp      (ix+S_SPAWNPOINT_DATA.MaxEnemiesCounter)
        jp      nz, .NextSpawnPoint                             ; Jump if max enemies have not been spawned

; - Max enemies have been spawned - Check whether the spawnpoint can be reused
        ld      a, (ix+S_SPAWNPOINT_DATA.Reuse)
        cp      1
        jp      z, .NextSpawnPoint                      ; Jump if spawnpoint can be reused i.e. Don't disable

; -- Disable/Update spawnpoint on tilemap
; Play audio effect
        push    af, ix

        ld      a, AyFXSpawnPointDisabled
        call    AFX2Play

        pop     ix, af

        ld      (ix+S_SPAWNPOINT_DATA.Active), a        ; Disable spawnpoint

        ld      iy, (LevelTileMap)
        ld      bc, (ix+S_SPAWNPOINT_DATA.TileBlockOffset)
        add     iy, bc                                          ; Add block offset

        push    bc                                      ; Save TileBlockOffset

        ld      de, (ix+S_SPAWNPOINT_DATA.TileBlockOffsetY)
        ld      a, SpawnPointDisabledBlock
        call    SpawnPointDisabled

        pop     hl                                      ; Restore TileBlockOffset (bc)

        push    ix
        call    UpdateTriggerTargetData
        pop     ix

.NextSpawnPoint:
        pop     bc

        ld      de, S_SPAWNPOINT_DATA
        add     ix, de                          ; Point to next Spawn Point

        dec     b
        ld      a, b
        cp      0
        jp      nz, .SpawnPointLoop

        ret    

;-------------------------------------------------------------------------------------
; Spawn Type Enemy - Flee Routine
; - Routine for enemy marked with Movement flag
; i.e. Move enemy in initial spawn direction
; Parameters:
SpawnFlee:
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset

        ld      (EnemyBlockOffset), bc                  ; Save Tilemap block offset
        ld      (EnemyBlockXY), de                      ; Save Tilemap block XY position
        ld      (ix+S_SPRITE_TYPE.MoveToBlockXY), de    ; Save Tilemap block offset

; Horizontal Checks - Check Movement3 value
        bit     1, (ix+S_SPRITE_TYPE.Movement3)
        jp      nz, .TryMoveLeft                        ; Jump if enemy configured to move left

        bit     0, (ix+S_SPRITE_TYPE.Movement3)
        jp      nz, .TryMoveRight                       ; Jump if enemy configured to move right

        jp      .TryMoveOnY                             ; Otherwise try and move vertically

;----------------
; Left Checks
.TryMoveLeft:
; - Obtain block directly to left of enemy
        ld      bc, (EnemyBlockOffset)          ; Restore enemy block offset
        dec     bc                              ; Point to left block

        ld      iy, (LevelTileMap)
        add     iy, bc                          ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc               ; Save block offset
        ld      (BackupByte), a                 ; Save block to check
        
.CheckLeftBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .HitObstacle         ; Jump if enemy not permitted to move

; - Update enemy to move left
        set     1, (ix+S_SPRITE_TYPE.Movement)  ; Set left

        ld      a, (NonFFValidPaths)
        set     1, a                    ; Set Left bit to allow left movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated) ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        jp      .TryMoveOnY

;----------------
; Right Checks
.TryMoveRight:
; - Obtain block directly to right of enemy
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        inc     bc                      ; Point to right block

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckRightBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .HitObstacle         ; Jump if enemy not permitted to move

; - Update enemy to move right
        set     0, (ix+S_SPRITE_TYPE.Movement)  ; Set right

        ld      a, (NonFFValidPaths)
        set     0, a                            ; Set Left bit to allow right movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

; Vertical Checks - Check Movement3 value
.TryMoveOnY:
        bit     3, (ix+S_SPRITE_TYPE.Movement3)
        jp      nz, .TryMoveUp                          ; Jump if enemy configured to move up

        bit     2, (ix+S_SPRITE_TYPE.Movement3)
        jp      nz, .TryMoveDown                        ; Jump if enemy configured to move down

        ret

;----------------
; Up Checks
.TryMoveUp:
; - Obtain block directly above enemy
        ld      bc, (EnemyBlockOffset)  ; Restore enemy block offset
        add     bc, -BlockTileMapWidth  ; Point to block directly above

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckUpBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .HitObstacle         ; Jump if enemy not permitted to move

; - Update enemy to move up
        set     3, (ix+S_SPRITE_TYPE.Movement)  ; Set up

        ld      a, (NonFFValidPaths)
        set     3, a                            ; Set Up bit to allow up movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

	ret

;----------------
; Down Checks
.TryMoveDown:
; - Obtain block directly below enemy
        ld      bc, (EnemyBlockOffset)       ; Restore enemy block offset
        add     bc, BlockTileMapWidth   ; Point to block directly below

        ld      iy, (LevelTileMap)
        add     iy, bc                  ; Add block offset
        ld      a, (iy)

        ld      (BackupWord3), bc       ; Save block offset
        ld      (BackupByte), a         ; Save block to check

.CheckDownBlocks:
; Check blocks to permit movement
; - Enemy Sprite - Check for populated friendly block bit
        ld      de, bc
        call    FriendlyCheckBlockMapBit
        cp      0
        ret     z                       ; Jump if friendly block occupied i.e. Don't move enemy

        ld      bc, (BackupWord3)       ; Restore block offset
        ld      a, (BackupByte)         ; Restore block to check
        call    CheckOffScreenBlocks
        cp      0
        jp      z, .HitObstacle         ; Jump if enemy not permitted to move

; - Update enemy to move down
        set     2, (ix+S_SPRITE_TYPE.Movement)  ; Set down

        ld      a, (NonFFValidPaths)
        set     2, a                            ; Set Down bit to allow down movement
        ld      (NonFFValidPaths), a

        ld      bc, (EnemyBlockUpdated)                 ; Restore block number
        ld      (ix+S_SPRITE_TYPE.MoveToBlock), bc      ; Set target block

        ret

; Enemy hit obstacle and should abandon flee
.HitObstacle:
        ld      (Movement3), a                          ; Reset; a == 0 as a result of the failure to move

        ld      a, 0
        ld      (ix+S_SPRITE_TYPE.InvulnerableCounter), a       ; Reset invulnerability counter
        ld      (ix+S_SPRITE_TYPE.DelayCounter), a              ; Reset flee counter

        res     2, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset Straight flag
        res     3, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset Spawn flag
        res     4, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset FleeStatus flag
        res     7, (ix+S_SPRITE_TYPE.SpriteType5)       ; Reset don't move in next frame flag

; TODO - Debug Resolved - Issue above iy instead of ix

        ret

;-------------------------------------------------------------------------------------
; Calculate Flee Time for Spawned Enemy
; - a. Calculate distanceX between player and new enemy
; - b. Calculate distanceY between player and new enemy
; - c. Determine greater of a & b
; - Set Flee Time to lower of Player RotRange and value from c.
; Parameters:
; iy = Enemy sprite data
; Return:
; a = Flee Time
CalculateFleeTime:
; Calculate X Coordinate
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)       ; PlayerX
        ld      de, (iy+S_SPRITE_TYPE.XWorldCoordinate)                 ; EnemyX
        sbc     hl, de

        jp      nc, .YCoordinate        ; Jump if player to right of enemy

; - Player to left of enemy (hl < de)
        or      a
        adc     hl, de

        ex      hl, de

        or      a
        sbc     hl, de          

.YCoordinate:
        ld      bc, hl                  ; bc = Positive Xdifference between player and enemy

; Calculate Y Coordinate
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)       ; PlayerY
        ld      de, (iy+S_SPRITE_TYPE.YWorldCoordinate)                 ; EnemyY
        sbc     hl, de

        jp      nc, .CheckGreaterXY     ; Jump if player below enemy

; - Player above enemy (hl < de)
        or      a
        adc     hl, de

        ex      hl, de

        or      a
        sbc     hl, de          

; Check which value is greatest
; - bc = X difference, hl = Y difference
.CheckGreaterXY:       
        or      a
        sbc     hl, bc
        jp      nc, .YGreater           ; Jump if Y is greater

        ld      hl, bc
        jp      .CompareWithRotRange

.YGreater:
        or      a
        adc     hl, bc

; Find lower of greatest coordinate and Player RotRange
; - hl = Greatest Coordinate
.CompareWithRotRange:        
        or      a
        ld      a, (PlayerSprite+S_SPRITE_TYPE.RotRange)
        ld      b, 0
        ld      c, a
        sbc     hl, bc
        jp      nc, .ValueFound         ; Jump if coordinate >= RotRange

        or      a
        adc     hl, bc

        ld      a, l                    ; Coordinate < RotRange

.ValueFound:
        add     SpawnFleeTimeAddition   ; Used to allow enemies to flee behind player
        ret                             ; a = Flee Time

;-------------------------------------------------------------------------------------
; Write CFG file
; Note: Called after level completed; placed into enemy.asm to ensure memory bank
;       hosting routine not removed from memory as part of routine
; Parameters:
; Return:
CFGFileWrite:
; Obtain memory bank number currently mapped into slot 2 and save allowing restoration
; - MMU2 - $4000-$5fff
	ld      a,$52                           ; Port to access - Memory Slot 2
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
	ld      (BackupByte6), a                 ; Save current bank number in slot 2

; Map Title routines into slot 2
	ld      a, $$TitleScreen                
	nextreg $52, a                          ; Swap memory bank

        call    TitleCFGFileWrite

; - Swap original memory bank back into slot 2
	ld      a, (BackupByte6)                 ; Restore original memory bank
	nextreg $52, a                          ; Swap memory bank

        ret
