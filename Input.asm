InputCode:
;-------------------------------------------------------------------------------------
; Read Input Devices - Game
ReadPlayerInput:
/*
; Read Kempston port first, will also clear the inputs
        in      a,(KEMPSTON_JOY1_P_1F)
        ld      e,a             ; E = the Kempston/MD joystick inputs (---FUDLR)

; Mix the joystick inputs with keyboard controls
*/
; Reset keyboard bits
        ld      d,$FF           ; keyboard reading bits are 1=released, 0=pressed -> $FF = no key

; Check whether game paused
        ld      a, (GameStatus)
        bit     2, a
        jp      nz, .BypassMovement     ; Jump if game paused

; Check whether the player can press the savepoint key
        ld      a, (SavePointKeyDelayCounter)
        cp      0
        jp      nz, .ProcessSavePointCounter    ; Jump if the player cannot press the savepoint key

; Check eighth row of matrix (<space><symbol shift>MNB) - SAVEPOINT
        ld      a,~(1<<7)       ; Rotate 1 to the left 7 times and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (space) into Fcarry

        jp      c, .ProcessCollectableKey       ; Jump if Savepoint key not pressed

        rl      d
        ld      e, 4
        mul     d, e            ; Set savepoint flag in register d

        ld      a, SavePointKeyDelay            ; Reset savepoint key counter

.ProcessSavePointCounter:
        dec     a
        ld      (SavePointKeyDelayCounter), a

.ProcessCollectableKey:
; Check whether the player can press the collectable switch key
        ld      a, (LockerCollectibleSwitchDelayCounter)
        cp      0
        jp      nz, .BypassCollectibleSwitch

; Check third row of matrix (QWERT) - SWITCH
        ld      a,~(1<<2)       ; Rotate 1 to the left 2 times and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (q) into Fcarry
        rl      d               ; Store result - Rotate d left including rotation of Fcarry (space) into d (bit 0)

        jp      .CheckKeys

; - Update collectable switch counter
.BypassCollectibleSwitch
        dec     a
        ld      (LockerCollectibleSwitchDelayCounter), a

.CheckKeys:
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

.BypassMovement:
; Check whether the pause status can be changed
        ld      a, (PauseDelayCounter)
        cp      0
        jp      nz, .ProcessPauseCounter        ; Jump if the player cannot change pause status

; Check eighth row of matrix (<Enter>LKJH) - PAUSE
        or      a
        ld      a,~(1<<2);~(1<<6)       ; Rotate 1 to the left 6 times and complement i.e. Inverse bits
        in      a,(ULA_P_FE)    ; Port Number - a = High byte, $fe = low byte 
        rrca                    ; Rotate bit 0 (q) into Fcarry
        rrca                    ; Rotate bit 0 (w) into Fcarry
        rrca                    ; Rotate bit 0 (e) into Fcarry
        rrca                    ; Rotate bit 0 (e) into Fcarry

        jp      c, .BypassPause ; Jump if pause not pressed

; - Pause key pressed
        ld      a, (GameStatus2)
        bit     2, a
        jp      nz, .BypassPause        ; Jump if pause function cannot be set i.e. Start of level screen, game over screen

        ld      a, (GameStatus)
        xor     %00000100               ; Toggle Pause bit
        ld      (GameStatus), a
        
        ld      a, (PauseValueSpriteNum)
        call    TogglePauseSprite

        ld      a, PauseDelay
        ld      (PauseDelayCounter), a  ; Reset pause counter

; Reset keyboard/joystick input
        ld      d,$FF           ; keyboard reading bits are 1=released, 0=pressed -> $FF = no key
        ld      e, 0            ; joystick $00 = no input

        jp      .BypassPause

.ProcessPauseCounter:
        dec     a
        ld      (PauseDelayCounter), a

; Reset keyboard/joystick input
        ld      d,$FF           ; keyboard reading bits are 1=released, 0=pressed -> $FF = no key
        ;ld      e, 0            ; joystick $00 = no input

.BypassPause:
        ld      a, d

; Combine keyboard and joystick input
        cpl                     ; a is inverted i.e If key pressed, bit stored as 0; now invert the readings, now 1 = pressed, 0 = no key
        ;or      e               ; mix the keyboard and joystick readings together i.e. Keyboard (---FUDLR) and joystick (---FUDLR)

        ld      (PlayerInput), a                ; store the combined player input

        ;call    CheckPlayerDoubleTap

; Check pause status and whether mouse can be processed 
        ld      a, (GameStatus)
        bit     2, a
        call    z, ProcessMouse                 ; Call routine if game not paused

        ld      a, (PlayerInput)
        ld      (PlayerInputOriginal), a        ; Save unchanged playerinput, used during enemy collision detection

; Check whether collectable switch key pressed
        bit     4, a
        ret     z                                               ; Return if switch key not pressed

        ld      a, LockerCollectibleSwitchDelay
        ld      (LockerCollectibleSwitchDelayCounter), a        ; Otherwise reset counter

        ret

/* - No longer used
;-------------------------------------------------------------------------------------
; Check for Double-Tap
; Note: PlayerInput - Input for current frame
; Note: PlayerInput2 - Input from previous frame
CheckPlayerDoubleTap:
; Check whether countdown has started and we need to delay checking for second tap
        ld      a, (PlayerInputDelayCounter)
        cp      0
        jp      z, .CheckForTap         ; Jump if input delay has finished

        dec     a                       ; Otherwise decrement delay countdown
        ld      (PlayerInputDelayCounter), a

        ld      a, 0
        ld      (PlayerInput2), a

        ret

.CheckForTap:
        ld      a, (PlayerInput)
        bit     4, a
        jp      nz, .Fire1True          ; Jump if PlayerInput = fire

; --- Scenario - PlayerInput != fire
.Fire1False:
        ld      a, (StrafeCountDownCounter)
        cp      255
        jp      z, .ExitRoutine         ; Jump if countdown has not started

; Countdown Started - Check whether we are now outside the window for tap-2
        cp      StrafeCountDownEnd
        jp      z, .StopCountDown       ; Jump if outside window

        dec     a                       ; Otherwise decrement countdown
        ld      (StrafeCountDownCounter), a

        jp      .ExitRoutine

.Fire1True:
; Check whether fire was also pressed in previous frame
        ld      a, (PlayerInput2)
        bit     4, a
        jp      z, .Fire1TrueFire2False ; Jump if fire not previously pressed

; --- Scenario - PlayerInput2 = fire && PlayerInput = fire
        jp      .StopCountDown

; --- Scenario - PlayerInput2 != fire && PlayerInput = fire
.Fire1TrueFire2False:
        ld      a, (StrafeCountDownCounter)
        cp      255
        jp      z, .StartCountdown      ; Jump if countdown has not started

; Countdown In-progress - Check whether we are now inside the window for tap-2
        cp      StrafeCountdownStart
        jr      c, .ToggleStrafe        ; Jump if strafeCountDown < StrafeCountDownStart
        ; Continuing indicates fire has been held down since first pressing fire

; Countdown Stopped
.StopCountDown:
        ld      a, 255
        ld      (StrafeCountDownCounter), a    ; Reset countdown
        jp      .ExitRoutine

; Countdown Started
.StartCountdown:
        ld      a, StrafeCountdownStart
        ld      (StrafeCountDownCounter), a    ; Start countdown

        ld      a, PlayerInputDelay
        ld      (PlayerInputDelayCounter), a   ; Set delay

        jp      .ExitRoutine
        
; Second tap registered
.ToggleStrafe:
        ld      a, (StrafeEnabled)
        cpl                             ; Invert i.e. Enable=Disable and vice-versa
        ld      (StrafeEnabled), a

        ld      ix, ReticuleSprAtt
        ld      iy, ReticuleSprite

        cp      0
        jp      nz, .StrafeEnabled      ; Jump if strafe enabled

        ld      bc, (iy+S_SPRITE_TYPE.animationStr)
        call    UpdateSpritePattern

        jp      .Cont

.StrafeEnabled:
        ld      bc, (iy+S_SPRITE_TYPE.animationOther)
        call    UpdateSpritePattern

.Cont:
        ld      a, 255
        ld      (StrafeCountDownCounter), a    ; Reset countdown
        jp      .ExitRoutine

.ExitRoutine:
        ld      a, (PlayerInput)
        ld      (PlayerInput2), a

        ret
*/

;-------------------------------------------------------------------------------------
; Update Player Based on Input
CheckPlayerInput:
; Update tilemap palette based on freeze selection
        ld      a, (PlayerInput)
        and     %01000000
        jp      nz, .ByPassPaletteReset         ; Jump if freeze not pressed

; - Change back to current non-freeze palette
        ld      a, (CurrentTileMapPal)          ; Reset after freeze
        call    SelectTileMapPalOffset

; - Change back to L2 game palette
        nextreg $43,%0'001'0'0'0'1  ; Layer 2 - First palette

.ByPassPaletteReset:
; Check freeze status
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      z, .ContInput                   ; Jump if freeze not enabled

; - Freeze enabled
        dec     a
        ld      (FreezeEnableCounter), a

        cp      0
        jp      nz, .BypassDelayCounter         ; Jump if freeze != 0

; - End of freeze - Set freeze disable delay counter
        ld      a, FreezeDisableDuration
        ld      (FreezeDisableCounter), a

        jp      .ContInput

; - Freeze still enabled - Prevent player launching projectiles
.BypassDelayCounter:
        ld      a, (PlayerInputOriginal)
        res     6, a                            ; Reset player freeze input
        res     5, a                            ; Reset player bullet input
        ld      (PlayerInputOriginal), a

.ContInput:
; Check/update player damage delay counter - required per game loop
        ld      a, (PlayerDamageDelayCounter)
        cp      0
        jp      z, .ContPlayerInput                             ; Jump if counter not set

        dec     a
        ld      (PlayerDamageDelayCounter), a                   ; Otherwise decrement

.ContPlayerInput:
; Check/update player respawn damage delay counter - required per game loop
        ld      a, (GameStatus)
        bit     5, a
        jp      nz, .ContPlayerInput2                           ; Return if animation flag set i.e. Start, respawn

        ld      a, (RespawnDamageDelayCounter)
        cp      0
        jp      z, .ContPlayerInput2                            ; Jump if counter not set

        dec     a
        ld      (RespawnDamageDelayCounter), a                  ; Otherwise decrement

.ContPlayerInput2:
; Reset player moved flag
        ld      a, 0
        ld      (PlayerMoved), a

; Update player input based on sprite collision
        ld      a, (PlayerInputOriginal)
        ld      b, a

        ld      a, (PlayerSprite+S_SPRITE_TYPE.SprContactSide)
        cpl

        and     b       ; Combine PlayerInputOriginal and SprContactSide to determine permitted movement

        ld      (PlayerInput), a

        ld      a, 0
        ld      (PlayerSprite+S_SPRITE_TYPE.SprContactSide), a

; Check whether bullets counter needs to be decremented
        ld      a, (FreezeEnableCounter)
        cp      0
        jp      nz, .CheckFreezeDelay                   ; Jump if freeze enabled i.e. Don't decrement counter

        ld      a, (PlayerSprite+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      z, .CheckFreezeDelay                    ; Jump if bullet delay not set

        dec     a
        ld      (PlayerSprite+S_SPRITE_TYPE.DelayCounter), a    ; Otherwise decrement

.CheckFreezeDelay:
; Check whether freeze counter needs to be decremented
        ld      a, (FreezeDisableCounter)
        cp      0
        jp      z, .CheckInput                          ; Jump if freeze disable delay not set

        dec     a
        ld      (FreezeDisableCounter), a               ; Otherwise decrement

.CheckInput:
; Reset reticule scrolled variable
        ld      a, 0
        ld      (Scrolled), a

; Check whether only fire pressed
        ld      a, (PlayerInput)
        cp      %00100000
        jp      z, .FireBullet                          ; Jump if only fire pressed; retain movement flag

; Check whether only freeze pressed
        cp      %01000000
        jp      z, .EnableFreeze                        ; Jump if only freeze pressed; retain movement flag

; Check whether only switch pressed
        cp      %00010000
        ret     z                                       ; Return if only switch pressed; retain movement flag

; Check whether no input received
        cp      %00000000
        jp      z, .UpdateSpriteOrientation     ; Jump if no player input

        ld      bc, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        ld      (PlayerBlockOffset), bc                 ; Obtain block offset position for use with doors
        ld      (PlayerBlockXY), de                     ; Obtain block XY position for use with enemies

        ld      a, 0
        ld      (PlayerSprite+S_SPRITE_TYPE.Movement), a        ; Reset player movement flag
        
;----------------
; Move Right
.CheckPlayerRight:
        ld      a, (PlayerInput)
        and     %00000001               
        jp      z, .CheckPlayerLeft

        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

; Set movement flag
        set     0, (ix+S_SPRITE_TYPE.Movement)  ; Set right

/*
; Check whether strafe is enabled
        ld      a, (StrafeEnabled)
        cp      255
        jp      z, .NoFixedFireRight            ; Jump if strafe enabled

; Check whether fire and direction pressed; only if strafe not enabled
        ld      a, (PlayerInput)
        bit     4, a
        jp      nz, .CheckPlayerDown    ; Jump if fire pressed

.NoFixedFireRight:
*/

; Check whether player is at the horizontal edge of a block
        ld      de, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        call    CheckDivisableBy16

        cp      1
        jp      nz, .ContRight                                  ; Jump if player not at horizontal edge of a block - No need to check block type

; At horizontal edge of block - Obtain block
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        inc     bc                                              ; Point to block directly to right

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain tile number

        push    af, iy;af, bc, iy

; Check whether player is at the vertical edge of a block
        ld      h, a                                            ; Save register

        push    bc
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    CheckDivisableBy16
        pop     bc

        ld      (PlayerAt16Position), a

        ld      a, h                                            ; Restore register

; Door - Check for vertical door tiles - Block directly to right
; Vertical Door - Lower Check
        ld      d, a
        ld      a, VerDoorStart-1
        cp      d
        jp      nc, .DoorRightCheck2                             ; Jump if tile <= VerDoorStart-1

; Vertical Door - Upper Check
        ld      a, VerDoorTrigger
        cp      d
        jp      c, .DoorRightCheck2                              ; Jump if tile > VerticalDoorTrigger

        jp      .DoorRightDetected

.DoorRightCheck2:
; Door - Check for vertical door tiles - Block directly behind
        dec     iy                                              ; Point to block directly behind
        dec     bc                                              ; Update inline with iy
        ld      a, (iy)                                         ; Obtain tile number

; Vertical Door - Lower Check
        ld      d, a
        ld      a, VerDoorStart-1
        cp      d
        jp      nc, .CheckRightCloseDoor                        ; Jump if tile <= VerDoorStart-1

; vertical Door - Upper Check
        ld      a, VerDoorTrigger
        cp      d
        jp      c, .CheckRightCloseDoor                         ; Jump if tile > VerDoorEnd

.DoorRightDetected:
; Check whether player at vertical 16 divisable position
        ld      a, (PlayerAt16Position)
        cp      0
        jp      nz, .ContDoorRight                              ; Jump if at vertical divisable position

        pop     iy, af

; - Otherwise move player up towards door
        ld      a, (PlayerInput)
        bit     2, a
        jp      nz, .CheckPlayerDown                            ; Jump if player pressing down i.e. don't move up automatically

        set     3, a                                            ; Otherwise set player to move up
        ld      (PlayerInput), a

        jp      .CheckPlayerUp                                  


.ContDoorRight:
; Door - Detected, check door type
        push    ix
        call    DoorCheckType                                  ; Return a = Ability to move through door, bc = Door offset
        pop     ix

; Check door offset against last player door offset
        push    af, bc

        ld      de, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)       ; Parameter - de
        or      a
        ld      hl, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)
        sbc     hl, bc
        call    nz, DoorClose                                   ; Call routine if player door offset != new door offset i.e. Close previous door

        pop     bc, af

        ld      (ix+S_SPRITE_TYPE.DoorVerBlockOffset), bc       ; Return bc = New door offset

        cp      1
        jp      z, .CheckRightWall                              ; Jump if player can move through door

        pop     iy, af

        jp      .CheckPlayerDown

.CheckRightCloseDoor:
        ld      de, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorVerBlockOffset), de       ; Return - de

; Wall - Check for wall tiles
.CheckRightWall:
        pop     iy, af;iy, bc, af

        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      c, .CheckRightBelowTile                         ; Jump if block type is not a wall i.e. Value is > BlocksWalls

        ld      a, (PlayerAt16Position)
        cp      1
        jp      z, .CheckPlayerDown                             ; Jump if player at divisable 16 position i.e. Wall hit, no further testing

; - Otherwise check tile right+below
        ld      bc, BlockTileMapWidth
        add     iy, bc                                          ; Point to block directly below previous block
        ld      a, (iy)

; Door - Check for vertical door tiles - Block directly to right
; Vertical Door - Lower Check
        ld      d, a
        ld      a, VerDoorStart-1
        cp      d
        jp      nc, .CheckRightBelowForWall                     ; Jump if tile <= VerDoorStart-1

; Vertical Door - Upper Check
        ld      a, VerDoorTrigger
        cp      d
        jp      c, .CheckRightBelowForWall                      ; Jump if tile > VerticalDoorTrigger

        jp      .RightMoveDown

; Door - Check for wall tiles - Block directly to right
.CheckRightBelowForWall:
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .CheckPlayerDown                            ; Jump if block type is a wall i.e. Value is <= BlocksWalls - Don't move right

; - Otherwise move player down towards door/gap
.RightMoveDown:
        ld      a, (PlayerInput)
        bit     3, a
        jp      nz, .CheckPlayerUp                              ; Jump if player pressing up i.e. don't move down automatically

        set     2, a                                            ; Otherwise set player to move down
        ld      (PlayerInput), a

        jp      .CheckPlayerDown

        ;;;jp      nc, .CheckPlayerDown                            ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move right

.CheckRightBelowTile:
; Check whether player is at the vertical edge of a block
        ld      a, (PlayerAt16Position)
        cp      1
        jr      z, .ContRight                                   ; Jump if player at vertical edge of a block - No need to check below block type

; - Otherwise check tile right+below
        ld      bc, BlockTileMapWidth
        add     iy, bc                                          ; Point to block directly below previous block
        ld      a, (iy)
        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      c, .ContRight                            ; Jump if block type is not a wall i.e. Value is > BlocksWalls - Move right

; - Otherwise move player up towards space
        ld      a, (PlayerInput)
        bit     2, a
        jp      nz, .CheckPlayerDown                            ; Jump if player pressing down i.e. don't move up automatically

        set     3, a                                            ; Otherwise set player to move up
        ld      (PlayerInput), a

        jp      .CheckPlayerUp                                  

        ;;;jp      nc, .CheckPlayerDown                            ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move right

.ContRight:
; Check/Close horizontal door as player may be automatically moving through
        ld      de, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorHorBlockOffset), de       ; Return - de

; Set player moved flag to enable animation
        ld      a, 1
        ld      (PlayerMoved), a

; Update player world coordinate
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        inc     bc
        
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc

        ld      iy, PlayerSprAtt
; Obtain 9-bit x value
        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        and     %00000001
        ld      h, a
        ld      l, (iy+S_SPRITE_ATTR.x)         ; hl = 9-bit x value
        ld      de, hl                          ; Backup x position

        ld      bc, ScreenMiddleX
        sbc     hl, bc
        jr      nz, .MoveRight                  ; Jump if player not at X middle position

; At X middle postion
        push    ix, iy
        call    CheckScrollRight                ; Try and scroll right
        pop     iy, ix

        cp      1                              ; Return value
        jp      nz, .MoveRight                   ; Jump if not scrolled

        ld      a, (Scrolled)                   
        set     0, a                            
        ld      (Scrolled), a                   ; Set variable  controlling mouse movement

        jp      z, .CheckPlayerDown                   ; Return if scrolled, otherwise move left

.MoveRight:
        ld      hl, de                          ; Restore x position
        inc     hl

        ld      (iy+S_SPRITE_ATTR.x), l         ; Store bits 0-8
        ld      (ix+S_SPRITE_TYPE.xPosition), hl; Store 9-bit value

        or      a                               ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .RightSetmrx8               ; Setmrx8 if hl >=256

        ; Update sprite attributes
        res     0, (iy+S_SPRITE_ATTR.mrx8)      ; Store bit 9

        jp      .CheckPlayerDown

.RightSetmrx8
        ; Update sprite attributes
        set     0, (iy+S_SPRITE_ATTR.mrx8)      ; Store bit 9

        jp      .CheckPlayerDown

;----------------
; Move Left
.CheckPlayerLeft:
        ld      a, (PlayerInput)
        and     %00000010
        jp      z, .CheckPlayerDown

        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

; Set movement flag
        set     1, (ix+S_SPRITE_TYPE.Movement)  ; Set left

/*
; Check whether strafe is enabled
        ld      a, (StrafeEnabled)
        cp      255
        jp      z, .NoFixedFireLeft            ; Jump if strafe enabled

; Check whether fire and direction pressed; only if strafe not enabled
        ld      a, (PlayerInput)
        bit     4, a
        jp      nz, .CheckPlayerDown    ; Jump if fire pressed

.NoFixedFireLeft:
*/

; Check whether player is at the horizontal edge of a block
        ld      de, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        call    CheckDivisableBy16

        cp      1
        jp      nz, .ContLeft                                   ; Jump if player not at horizontal edge of a block - No need to check block type

; At horizontal edge of block - Obtain block and check type
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        add     bc, 15                                          ; Point to far right of player
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        dec     bc                                              ; Point to block directly to left

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)

        push    af, iy;af, bc, iy

; Check whether player is at the vertical edge of a block
        ld      h, a                                            ; Save register
        push    bc
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    CheckDivisableBy16
        pop     bc

        ld      (PlayerAt16Position), a

        ld      a, h                                            ; Restore register
; Door - Check for vertical door tiles - Block Directly to left
; Vertical Door - Lower Check
        ld      d, a
        ld      a, VerDoorStart-1
        cp      d
        jp      nc, .DoorLeftCheck2                              ; Jump if tile <= VerDoorStart-1

; Vertical Door - Upper Check
        ld      a, VerDoorTrigger
        cp      d
        jp      c, .DoorLeftCheck2                               ; Jump if tile > VerDoorTrigger

        jp      .DoorLeftDetected

.DoorLeftCheck2:
; Door - Check for vertical door tiles - Block Directly behind
        inc     iy                                              ; Point to block directly behind
        inc     bc                                              ; Update inline with iy
        ld      a, (iy)                                         ; Obtain tile number

; Vertical Door - Lower Check
        ld      d, a
        ld      a, VerDoorStart-1
        cp      d
        jp      nc, .CheckLeftCloseDoor                         ; Jump if tile <= VerDoorStart-1

; Vertical Door - Upper Check
        ld      a, VerDoorTrigger
        cp      d
        jp      c, .CheckLeftCloseDoor                          ; Jump if tile > VerDoorEnd

.DoorLeftDetected:
; Check whether player at vertical 16 divisable position
        ld      a, (PlayerAt16Position)
        cp      0
        jp      nz, .ContDoorLeft                               ; Jump if at vertical divisable position

        pop     iy, af

; - Otherwise move player up towards door
        ld      a, (PlayerInput)
        bit     2, a
        jp      nz, .CheckPlayerDown                            ; Jump if player pressing down i.e. don't move up automatically

        set     3, a                                            ; Otherwise set player to move up
        ld      (PlayerInput), a

        jp      .CheckPlayerUp                                  

.ContDoorLeft:
; Door - Detected, check door type
        push    ix
        call    DoorCheckType                                  ; Return a = Ability to move through door, bc = Door offset
        pop     ix

; Check door offset against last player door offset
        push    af, bc

        ld      de, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)       ; Parameter - de
        or      a
        ld      hl, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)
        sbc     hl, bc
        call    nz, DoorClose                                   ; Call routine if player door offset != new door offset i.e. Close previous door

        pop     bc, af

        ld      (ix+S_SPRITE_TYPE.DoorVerBlockOffset), bc       ; Return bc = Door offset

        cp      1
        jp      z, .CheckLeftWall                               ; Jump if player can move through door

        pop     iy, af

        jp      .CheckPlayerDown
        
.CheckLeftCloseDoor:
        ld      de, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorVerBlockOffset), de       ; Return - de

; Wall - Check for wall tiles
.CheckLeftWall:
        pop     iy, af;iy, bc, af

        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      c, .CheckLeftBelowTile                          ; Jump if block type is not a wall i.e. Value is > BlocksWalls

        ld      a, (PlayerAt16Position)
        cp      1
        jp      z, .CheckPlayerDown                             ; Jump if player at divisable 16 position i.e. Wall hit, no further testing

; - Otherwise check tile right+below
        ld      bc, BlockTileMapWidth
        add     iy, bc                                          ; Point to block directly below previous block
        ld      a, (iy)

; Door - Check for vertical door tiles - Block directly to left
; Vertical Door - Lower Check
        ld      d, a
        ld      a, VerDoorStart-1
        cp      d
        jp      nc, .CheckLeftBelowForWall                     ; Jump if tile <= VerDoorStart-1

; Vertical Door - Upper Check
        ld      a, VerDoorTrigger
        cp      d
        jp      c, .CheckLeftBelowForWall                       ; Jump if tile > VerticalDoorTrigger

        jp      .LeftMoveDown

; Door - Check for wall tiles - Block directly to left
.CheckLeftBelowForWall:
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .CheckPlayerDown                            ; Jump if block type is a wall i.e. Value is <= BlocksWalls - Don't move left

; - Otherwise move player down towards door/gap
.LeftMoveDown:
        ld      a, (PlayerInput)
        bit     3, a
        jp      nz, .CheckPlayerUp                              ; Jump if player pressing up i.e. don't move down automatically

        set     2, a                                            ; Otherwise set player to move down
        ld      (PlayerInput), a

        jp      .CheckPlayerDown

        ;;;jp      nc, .CheckPlayerDown                            ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move left

.CheckLeftBelowTile:
; Check whether player is at the vertical edge of a block
        ld      a, (PlayerAt16Position)
        cp      1
        jr      z, .ContLeft                                    ; Jump if player at vertical edge of a block - No need to check adjacent block type

; - Otherwise check tile left+below
        ld      bc, BlockTileMapWidth
        add     iy, bc                                          ; Point to block directly below previous block
        ld      a, (iy)
        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
; TOOD - SpaceUpdate
        jp      c, .ContLeft                            ; Jump if block type is not a wall i.e. Value is > BlocksWalls - Move left 
        ;;;jp      nc, .CheckPlayerDown                            ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move left

; - Otherwise move player up towards space
        ld      a, (PlayerInput)
        bit     2, a
        jp      nz, .CheckPlayerDown                            ; Jump if player pressing down i.e. don't move up automatically

        set     3, a                                            ; Otherwise set player to move up
        ld      (PlayerInput), a

        jp      .CheckPlayerUp                                  

.ContLeft:
; Check/Close horizontal door as player may be automatically moving through
        ld      de, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorHorBlockOffset), de       ; Return - de

; Set player moved flag to enable animation
        ld      a, 1
        ld      (PlayerMoved), a

; Update player world coordinate
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        dec     bc
        ld      (ix+S_SPRITE_TYPE.XWorldCoordinate), bc

        ld      iy, PlayerSprAtt

; Obtain 9-bit x value
        ld      a, (iy+S_SPRITE_ATTR.mrx8)
        and     %00000001
        ld      h, a
        ld      l, (iy+S_SPRITE_ATTR.x)         ; hl = 9-bit x value
        ld      de, hl                          ; Backup x position

        ld      bc, ScreenMiddleX
        sbc     hl, bc
        jr      nz, .MoveLeft                  ; Jump if player not at X middle position

; At X middle postion
        push    ix, iy
        call    CheckScrollLeft                 ; Try and scroll left
        pop     iy, ix

        cp      1                              ; Return value
        jp      nz, .MoveLeft                   ; Jump if not scrolled

        ld      a, (Scrolled)           
        set     1, a
        ld      (Scrolled), a                   ; Set variable controlling mouse movement

        jp      z, .CheckPlayerDown                   ; Return if scrolled, otherwise move left

.MoveLeft:
        ld      hl, de                          ; Restore x position
        dec     hl
        
        ld      (iy+S_SPRITE_ATTR.x), l         ; Store bits 0-8
        ld      (ix+S_SPRITE_TYPE.xPosition), hl; Store 9-bit value

        or      a                               ; Clear carry flag
        ld      bc, 256
        sbc     hl, bc
        jr      nc, .LeftSetmrx8                ; Setmrx8 if hl >=256

        ; Update sprite attributes
        res     0, (iy+S_SPRITE_ATTR.mrx8)      ; Store bit 9

        jr      .CheckPlayerDown

.LeftSetmrx8
        ; Update sprite attributes
        set     0, (iy+S_SPRITE_ATTR.mrx8)      ; Store bit 9

;----------------
; Move Down
.CheckPlayerDown:
        ld      a, (PlayerInput)
        and     %00000100
        jp      z, .CheckPlayerUp

        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

; Set movement flag
        set     2, (ix+S_SPRITE_TYPE.Movement)  ; Set down

/*
; Check whether strafe is enabled
        ld      a, (StrafeEnabled)
        cp      255
        jp      z, .NoFixedFireDown            ; Jump if strafe enabled

; Check whether fire and direction pressed; only if strafe not enabled
        ld      a, (PlayerInput)
        bit     4, a
        jp      nz, .CheckPlayerFire    ; Jump if fire pressed

.NoFixedFireDown:
*/

; Check whether player is at the vertical edge of a block
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    CheckDivisableBy16

        cp      1
        jp      nz, .ContDown                                   ; Jump if player not at vertical edge of a block - No need to check block type

; At vertical edge of block - Obtain block and check type
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    ConvertWorldToBlockOffset
        add     bc, BlockTileMapWidth                           ; Point to block directly below

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)

        push     af, iy;af, bc, iy
; Check whether player is at the horizontal edge of a block
        ld      h, a

        push    bc
        ld      de, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        call    CheckDivisableBy16
        pop     bc

        ld      (PlayerAt16Position), a

        ld      a, h                                            ; Restore register
; Door - Check for horizontal door tiles - Block directly below
; Horizontal Door - Lower Check
        ld      d, a
        ld      a, HorDoorStart-1
        cp      d
        jp      nc, .DoorDownCheck2                              ; Jump if tile <= HorDoorStart-1

; Horizontal Door - Upper Check
        ld      a, HorDoorTrigger
        cp      d
        jp      c, .DoorDownCheck2                               ; Jump if tile > HorDoorTrigger

        jp      .DoorDownDetected

.DoorDownCheck2:
; Door - Check for horizontal door tiles - Block directly behind
        ld      iy, (LevelTileMap)
        add     bc, -BlockTileMapWidth                          ; Point to block directly behind
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)                                         ; Obtain tile number

; Horizontal Door - Lower Check
        ld      d, a
        ld      a, HorDoorStart-1
        cp      d
        jp      nc, .CheckDownCloseDoor                         ; Jump if tile <= HorDoorStart-1

; Horizontal Door - Upper Check
        ld      a, HorDoorsEnd                                  ; Don't need to check for trigger door
        cp      d
        jp      c, .CheckDownCloseDoor                          ; Jump if tile > HorDoorTrigger

.DoorDownDetected:
; Check whether player at horizontal 16 divisable position
        ld      a, (PlayerAt16Position)
        cp      0
        jp      nz, .ContDoorDown                              ; Jump if at horizontal divisable position

        pop     iy, af

; - Otherwise move player left towards door
        ld      a, (PlayerInput)
        bit     0, a
        jp      nz, .CheckPlayerFire                            ; Jump if player pressing right i.e. don't move left automatically

        bit     1, a
        jp      nz, .CheckPlayerFire                            ; Jump if player already pressing left i.e. don't move left automatically

        set     1, a                                            ; Otherwise set player to move left
        res     2, a                                            ; Reset down flag to prevent loop
        ld      (PlayerInput), a

        jp      .CheckPlayerLeft

.ContDoorDown:
; Door - Detected, check door type
        push    ix
        call    DoorCheckType                                  ; Return a = Ability to move through door, bc = Door offset
        pop     ix

; Check door offset against last player door offset
        push    af, bc

        ld      de, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)      ; Parameter - de
        or      a
        ld      hl, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)
        sbc     hl, bc
        call    nz, DoorClose                                   ; Call routine if player door offset != new door offset i.e. Close previous door

        pop     bc, af

        ld      (ix+S_SPRITE_TYPE.DoorHorBlockOffset), bc      ; Return bc = Door offset

        cp      1
        jp      z, .CheckDownWall                               ; Jump if player can move through door

        pop     iy, af

        jp      .CheckPlayerFire

.CheckDownCloseDoor:
        ld      de, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorHorBlockOffset), de       ; Return - de

; Wall - Check for wall tiles
.CheckDownWall:
        pop     iy, af;iy, bc, af

        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      c, .CheckDownRightTile                          ; Jump if block type is not a wall i.e. Value is > BlocksWalls

        ld      a, (PlayerAt16Position)
        cp      1
        jp      z, .CheckPlayerFire                             ; Jump if player at divisable 16 position i.e. Wall hit, no further testing

; - Otherwise check tile to right
        inc     iy                              ; Point to block to right of previous block
        ld      a, (iy)

; Door - Check for horizontal door tiles - Block to right
; Vertical Door - Lower Check
        ld      d, a
        ld      a, HorDoorStart-1
        cp      d
        jp      nc, .CheckDownRightForWall                     ; Jump if tile <= VerDoorStart-1
        ;jp      nc, .CheckPlayerFire                             ; Jump if tile <= HorDoorStart-1

; Vertical Door - Upper Check
        ld      a, HorDoorTrigger
        cp      d
        jp      c, .CheckDownRightForWall                      ; Jump if tile > VerticalDoorTrigger
        ;jp      c, .CheckPlayerFire                              ; Jump if tile > HorDoorTrigger

        jp      .DownMoveRight

; Door - Check for wall tiles - Block directly to right
.CheckDownRightForWall:
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .CheckPlayerFire                            ; Jump if block type is a wall i.e. Value is <= BlocksWalls - Don't move right

; - Otherwise move player right towards door/gap
.DownMoveRight:
        ld      a, (PlayerInput)
        bit     1, a
        jp      nz, .CheckPlayerFire                            ; Jump if player pressing left i.e. don't move right automatically

        bit     0, a
        jp      nz, .CheckPlayerFire                            ; Jump if player already pressing right i.e. don't move right automatically

        set     0, a                                            ; Otherwise set player to move right
        res     2, a                                            ; Reset down flag to prevent loop
        ld      (PlayerInput), a

        jp      .CheckPlayerRight

        ;;;jp      nc, .CheckPlayerFire                             ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move down

.CheckDownRightTile:
; Check whether player is at the horizontal edge of a block
        ld      a, (PlayerAt16Position)
        cp      1
        jr      z, .ContDown                                    ; Jump if player at horizontal edge of a block - No need to check adjacent block type

; - Otherwise check tile to right
        inc     iy                                              ; Point to block directly to the right of the previous block
        ld      a, (iy)
        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      c, .ContDown                            ; Jump if block type is not a wall i.e. Value is > BlocksWalls - Move down
        ;;;jp      nc, .CheckPlayerFire                             ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move down

; - Otherwise move player left towards gap
        ld      a, (PlayerInput)
        bit     0, a
        jp      nz, .CheckPlayerFire                            ; Jump if player pressing right i.e. don't move left automatically

        bit     1, a
        jp      nz, .CheckPlayerFire                            ; Jump if player already pressing left i.e. don't move left automatically

        set     1, a                                            ; Otherwise set player to move left
        res     2, a                                            ; Reset down flag to prevent loop
        ld      (PlayerInput), a

        jp      .CheckPlayerLeft

.ContDown:
; Check/Close horizontal door as player may be automatically moving through
        ld      de, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorVerBlockOffset), de       ; Return - de

; Set player moved flag to enable animation
        ld      a, 1
        ld      (PlayerMoved), a

; Update player world coordinate
        ld      bc, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        inc     bc
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), bc

        ld      iy, PlayerSprAtt
; Obtain 8-bit x value
        ld      a, (iy+S_SPRITE_ATTR.y)
        ld      b, a                            ; Backup x position

        cp      ScreenMiddleY
        jr      nz, .MoveDown                  ; Jump if player not at Y middle position

; At Y middle postion
        push    ix, iy
        call    CheckScrollDown                ; Try and scroll down
        pop     iy, ix

        cp      1                              ; Return value
        jp      nz, .MoveDown                   ; Jump if not scrolled

        ld      a, (Scrolled)           
        set     2, a
        ld      (Scrolled), a                   ; Set variable controlling mouse movement

        jp      z, .CheckPlayerFire                   ; Return if scrolled, otherwise move down

.MoveDown:
        ld      a, b                           ; Restore x position
        inc     a

        ld      (iy+S_SPRITE_ATTR.y), a
        ld      (ix+S_SPRITE_TYPE.yPosition), a ; Store 8-bit value
        
        jp      .CheckPlayerFire

;----------------
; Move Up
.CheckPlayerUp:
        ld      a, (PlayerInput)
        and     %00001000
        jp      z, .CheckPlayerFire

        ld      ix, PlayerSprite
        ld      iy, PlayerSprAtt

; Set movement flag
        set     3, (ix+S_SPRITE_TYPE.Movement)  ; Set up

/*
; Check whether strafe is enabled
        ld      a, (StrafeEnabled)
        cp      255
        jp      z, .NoFixedFireUp               ; Jump if strafe enabled

; Check whether fire and direction pressed; only if strafe not enabled
        ld      a, (PlayerInput)
        bit     4, a
        jp      nz, .CheckPlayerFire            ; Jump if fire pressed

.NoFixedFireUp:
*/

; Check whether player is at the vertical edge of a block
        ld      de, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        call    CheckDivisableBy16

        cp      1
        jp      nz, .ContUp                                     ; Jump if player not at vertical edge of a block - No need to check block type

; At vertical edge of block - Obtain block and check type
        ld      bc, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        ld      hl, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        add     hl, 15                                          ; Point to bottom right of player
        call    ConvertWorldToBlockOffset
        add     bc, -BlockTileMapWidth                          ; Point to block directly above

        ld      iy, (LevelTileMap)
        add     iy, bc                                          ; Add block offset
        ld      a, (iy)

        push    af, iy;af, bc, iy
; Check whether player is at the horizontal edge of a block
        ld      h, a

        push    bc
        ld      de, (ix+S_SPRITE_TYPE.XWorldCoordinate)
        call    CheckDivisableBy16
        pop     bc

        ld      (PlayerAt16Position), a

        ld      a, h                                            ; Restore register
; Door - Check for horizontal door tiles - Block directly above
; Horizontal Door - Lower Check
        ld      d, a
        ld      a, HorDoorStart-1
        cp      d
        jp      nc, .DoorUpCheck2                              ; Jump if tile <= HorDoorStart-1

; Horizontal Door - Upper Check
        ld      a, HorDoorTrigger
        cp      d
        jp      c, .DoorUpCheck2                               ; Jump if tile > HorDoorTrigger

        jp      .DoorUpDetected

.DoorUpCheck2:
; Door - Check for horizontal door tiles - Block directly behind
        ld      iy, (LevelTileMap)
        add     bc, BlockTileMapWidth                          ; Point to block directly behind
        add     iy, bc                                         ; Add block offset
        ld      a, (iy)                                        ; Obtain tile number

; Horizontal Door - Lower Check
        ld      d, a
        ld      a, HorDoorStart-1
        cp      d
        jp      nc, .CheckUpCloseDoor                          ; Jump if tile <= HorDoorStart-1

; Horizontal Door - Upper Check
        ld      a, HorDoorsEnd
        cp      d
        jp      c, .CheckUpCloseDoor                           ; Jump if tile > HorDoorTrigger

.DoorUpDetected:        
; Check whether player at horizontal 16 divisable position
        ld      a, (PlayerAt16Position)
        cp      0
        jp      nz, .ContDoorUp                                 ; Jump if at horizontal divisable position

        pop     iy, af

; - Otherwise move player left towards door
        ld      a, (PlayerInput)
        bit     0, a
        jp      nz, .CheckPlayerFire                            ; Jump if player pressing right i.e. don't move left automatically

        bit     1, a
        jp      nz, .CheckPlayerFire                            ; Jump if player already pressing left i.e. don't move left automatically

        set     1, a                                            ; Otherwise set player to move left
        res     2, a                                            ; Reset down flag to prevent loop
        ld      (PlayerInput), a

        jp      .CheckPlayerLeft

.ContDoorUp:
; Door - Detected, check door type
        push    ix
        call    DoorCheckType                                  ; Return a = Ability to move through door, bc = Door offset
        pop     ix

; Check door offset against last player door offset
        push    af, bc

        ld      de, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)      ; Parameter - de
        or      a
        ld      hl, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)
        sbc     hl, bc
        call    nz, DoorClose                                   ; Call routine if player door offset != new door offset i.e. Close previous door

        pop     bc, af

        ld      (ix+S_SPRITE_TYPE.DoorHorBlockOffset), bc      ; Return bc = Door offset

        cp      1
        jp      z, .CheckUpWall                                 ; Jump if player can move through door

        pop     iy, af

        jp      .CheckPlayerFire

.CheckUpCloseDoor:
        ld      de, (ix+S_SPRITE_TYPE.DoorHorBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorHorBlockOffset), de       ; Return - de

; Wall - Check for wall tiles
.CheckUpWall:
        pop     iy, af;iy, bc, af

        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      c, .CheckUpRightTile        ; Jump if block type is not a wall i.e. Value is > BlocksWalls

        ld      a, (PlayerAt16Position)
        cp      1
        jp      z, .CheckPlayerFire             ; Jump if player at divisable 16 position i.e. Wall hit, no further testing

; - Otherwise check tile to right 
        inc     iy                              ; Point to block to right of previous block
        ld      a, (iy)

; Door - Check for horizontal door tiles - Block to right
; Vertical Door - Lower Check
        ld      d, a
        ld      a, HorDoorStart-1
        cp      d
        jp      nc, .CheckUpRightForWall                     ; Jump if tile <= VerDoorStart-1
        ;jp      nc, .CheckPlayerFire                             ; Jump if tile <= HorDoorStart-1

; Vertical Door - Upper Check
        ld      a, HorDoorTrigger
        cp      d
        jp      c, .CheckUpRightForWall                      ; Jump if tile > VerticalDoorTrigger
        ;jp      c, .CheckPlayerFire                              ; Jump if tile > HorDoorTrigger

        jp      .UpMoveRight

; Door - Check for wall tiles - Block directly to right
.CheckUpRightForWall:
        ld      a, BlockWallsEnd                                   
        cp      d
        jp      nc, .CheckPlayerFire                            ; Jump if block type is a wall i.e. Value is <= BlocksWalls - Don't move right

; - Otherwise move player right towards door/gap
.UpMoveRight:
        ld      a, (PlayerInput)
        bit     1, a
        jp      nz, .CheckPlayerFire                            ; Jump if player pressing left i.e. don't move right automatically

        bit     0, a
        jp      nz, .CheckPlayerFire                            ; Jump if player already pressing right i.e. don't move right automatically

        set     0, a                                            ; Otherwise set player to move right
        res     3, a                                            ; Reset up flag to prevent loop
        ld      (PlayerInput), a

        jp      .CheckPlayerRight

        ;;;jp      nc, .CheckPlayerFire                                  ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move up

.CheckUpRightTile:
; Check whether player is at the horizontal edge of a block
        ld      a, (PlayerAt16Position)
        cp      1
        jr      z, .ContUp                                      ; Jump if player at horizontal edge of a block - No need to check adjacent block type

; - Otherwise check tile to right
        inc     iy                                              ; Point to block directly to the right of the previous block
        ld      a, (iy)
        ld      b, a
        ld      a, BlockWallsEnd                                   
        cp      b
        jp      c, .ContUp                                      ; Jump if block type is not a wall i.e. Value 
        ;jp      nc, .CheckPlayerFire                                  ; Jump if block type is a wall i.e. Value is <=BlocksWalls - Do not move up

; - Otherwise move player left towards gap
        ld      a, (PlayerInput)
        bit     0, a
        jp      nz, .CheckPlayerFire                            ; Jump if player pressing right i.e. don't move left automatically

        bit     1, a
        jp      nz, .CheckPlayerFire                            ; Jump if player already pressing left i.e. don't move left automatically

        set     1, a                                            ; Otherwise set player to move left
        res     3, a                                            ; Reset down flag to prevent loop
        ld      (PlayerInput), a

        jp      .CheckPlayerLeft

.ContUp:
; Check/Close horizontal door as player may be automatically moving through
        ld      de, (ix+S_SPRITE_TYPE.DoorVerBlockOffset)       ; Parameter - de
        call    DoorClose                                       ; Check/Close door
        ld      (ix+S_SPRITE_TYPE.DoorVerBlockOffset), de       ; Return - de

; Set player moved flag to enable animation
        ld      a, 1
        ld      (PlayerMoved), a

; Update player world coordinate
        ld      bc, (ix+S_SPRITE_TYPE.YWorldCoordinate)
        dec     bc
        ld      (ix+S_SPRITE_TYPE.YWorldCoordinate), bc

        ld      iy, PlayerSprAtt

; Obtain 8-bit x value
        ld      a, (iy+S_SPRITE_ATTR.y)
        ld      b, a                         ; Backup x position

        cp      ScreenMiddleY
        jr      nz, .MoveUp                  ; Jump if player not at Y middle position

; At Y middle postion
        push    ix, iy
        call    CheckScrollUp                ; Try and scroll up
        pop     iy, ix

        cp      1                              ; Return value
        jp      nz, .MoveUp                     ; Jump if not scrolled

        ld      a, (Scrolled)           
        set     3, a
        ld      (Scrolled), a                   ; Set variable controlling mouse movement

        jp      z, .CheckPlayerFire                   ; Return if scrolled, otherwise move down

.MoveUp:
        ld      a, b                         ; Restore x position
        dec     a

        ld      (iy+S_SPRITE_ATTR.y), a
        ld      (ix+S_SPRITE_TYPE.yPosition), a ; Store 8-bit value

;----------------
; Fire
.CheckPlayerFire:
        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite

        ld      a, (PlayerInput)
        and     %00100000
        jp      z, .CheckPlayerFreeze             ; Jump if fire not pressed

;----------------
; Bullet
.FireBullet:
; Reset fire flag as it would cause a sprite orientation issue
        ld      a, (PlayerInputOriginal)
        res     5, a                            ; %--FBUDLR
        ld      (PlayerInputOriginal), a

; Check whether we can fire
        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite

        ld      a, (PlayerSprite+S_SPRITE_TYPE.DelayCounter)
        cp      0
        jp      nz, .CheckPlayerFreeze            ; Jump if we can't fire bullets yet

        ld      a, (BulletsPlayerFired)
        cp      MaxPlayerBullets
        jp      z, .CheckPlayerFreeze             ; Jump if all player bullets have been fired

        inc     a                               ; Increment number of bullets fired
        ld      (BulletsPlayerFired), a

        jp      .FireProjectile

;----------------
; Freeze
.CheckPlayerFreeze:
        ld      a, (PlayerInput)
        and     %01000000
        jp      z, .UpdateSpriteOrientation             ; Jump if freeze not pressed

.EnableFreeze:
; Reset freeze flag as it would cause a sprite orientation issue
        ld      a, (PlayerInputOriginal)
        res     6, a                                    ; %--FBUDLR
        ld      (PlayerInputOriginal), a

; Check whether we can freeze
        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite

        ld      a, (PlayerFreezeTime)
        cp      0
        jp      nz, .FreezeActions                      ; Jump if freeze time left

; - Change back to current non-freeze palette
        ld      a, (CurrentTileMapPal)                  ; Reset after freeze
        call    SelectTileMapPalOffset

; - Change back to L2 game palette
        nextreg $43,%0'001'0'0'0'1  ; Layer 2 - First palette

        ld      a, AyFXFreezeNone
        call    AFX2Play

        jp      .UpdateSpriteOrientation

.FreezeActions:
        ld      a, (FreezeDisableCounter)
        cp      0
        jp      nz, .UpdateSpriteOrientation            ; Jump if we can't enable freeze

; - Change to freeze palette
        ld      a, FreezeTileMapPal
        call    SelectTileMapPalOffset

; - Change back to L2 freeze palette
        nextreg $43,%0'101'0'1'0'1  ; Layer 2 - Second palette

        ld      a, AyFXFreezeActivated
        call    AFX2Play

; Enable freeze
        ld      a, FreezeEnableDuration
        ld      (FreezeEnableCounter), a

        ld      a, (PlayerFreezeTime)
        dec     a
        ld      (PlayerFreezeTime), a                   ; Decrement freeze time

; Update freeze reticule values
        ld      b, ReticuleFreezeValueDigits
        ld      d, a
        ld      a, (ReticuleFreezeValueSpriteNum);(HUDFreezeValueSpriteNum)
        ld      c, a
        ld      a, d
; TODO - Reticule
        call    UpdateReticuleValueSprites              ; Update reticule values
        ;;;call    UpdateHUDValueSprites                   ; Update HUD values

        jp      .UpdateSpriteOrientation

; Spawn projectile
.FireProjectile:
        ;;call    .UpdateSpriteOrientation        
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
        jp      .SpawnProjectile                            ; No offset required

.Quarter2:
        ld      a, 128                                  
        sub     b                                       ; 180 degrees - angle
        jp      .SpawnProjectile

.Quarter3:
        ld      a, 128
        add     b                                       ; 180 degrees + angle
        jp      .SpawnProjectile

.Quarter4:
        ld      a, 255
        sub     b                                       ; 360 degrees - angle


.SpawnProjectile:
/* - No longer required as bomb removed and replaced with freeze
        push    af

; Check type of projectile
        ld      a, (PlayerDroppedBomb)
        cp      0
        jp      z, .SpawnBullet                         ; Jump if bullet fired

; - Spawn Bomb        
        ld      a, 0
        ld      (PlayerDroppedBomb), a                  ; Reset bomb flag
        
        pop     af

        ld      ix, BombPlayer                           ; Bomb type to be dropped

        ld      de, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ld      hl, (iy+S_SPRITE_TYPE.XWorldCoordinate)

        ld      iy, BombSpritesStart
        ld      c, a                                    ; Rotation value
        ld      a, BombAttStart
        ld      b, MaxPlayerBombs


; TODO - BombUpdate
        push    ix, de, hl, iy, bc, af
        add     bc, -3                                  ; First bomb - Set offset to reticule-3
        ;;call    SpawnNewBulletSprite

        pop     af, bc, iy, hl, de, ix
        ;;push    ix, de, hl, iy, bc, af
        add     bc, 3                                   ; Second bomb - Set offset to reticule+3
        ;;call    SpawnNewBulletSprite

        ;;ld      a, (ix+S_SPRITE_TYPE.Delay)
        ;;ld      a, 50
        ;;ld      (BombsPlayerDelayCounter), a

        jp      .UpdateSpriteOrientation

; - Spawn Bullet
.SpawnBullet:
        ;;pop     af
*/

        ld      hl, (iy+S_SPRITE_TYPE.BulletType)       ; Bullet type to be fired
        ld      ix, hl

; Play audio effect
        push    af, ix

        ld      a, (ix+S_BULLET_DATA.audioRef)
        call    AFX3Play

        pop     ix, af

        ld      de, (iy+S_SPRITE_TYPE.YWorldCoordinate)
        ld      hl, (iy+S_SPRITE_TYPE.XWorldCoordinate)

        ld      iy, BulletSpritesStart
        ld      c, a                                    ; Rotation value
        ld      a, BulletAttStart
        ld      b, MaxPlayerBullets

        call    SpawnNewBulletSprite


        ld      a, (ix+S_SPRITE_TYPE.Delay)
        ld      (PlayerSprite+S_SPRITE_TYPE.DelayCounter), a
        
;----------------
; Orientate Player Sprite
.UpdateSpriteOrientation:        
        ld      ix, PlayerSprAtt
        ld      iy, PlayerSprite

        call    UpdateSpriteOrientation

; Animate sprite
        ld      a, (PlayerMoved)
        cp      0
        ret     z                                       ; Return if player not moved i.e. Don't play animation

        ld      bc, (iy+S_SPRITE_TYPE.patternRange)
        call    UpdateSpritePattern

/* - Strafe code no longer used
        ld      a, (StrafeEnabled)
        cp      0
        jp      z, .StrafeDisabled              ; Jump if strafe disabled

        ld      a, (iy+S_SPRITE_TYPE.Movement2)
        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Set current movement flag value to previous as strafe enabled

        ret

.StrafeDisabled
*/

/* - Player orientation no longer required
        ld      a, (PlayerInputOriginal)
        cp      %00000000
        jp      z, .Cont                        ; Jump if no playerinput

        ld      (iy+S_SPRITE_TYPE.Movement), a  ; Otherwise set to player input

.Cont:
        ld      a, (iy+S_SPRITE_TYPE.Movement)  ; Get current movement flag value
        cp      (iy+S_SPRITE_TYPE.Movement2)    ; Compare with previous movement flag value
        ret     z                               ; Return if no change in movement

        call    UpdateSpriteOrientation
*/



        ret

EndofInputCode: