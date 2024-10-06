MouseCode:
;-------------------------------------------------------------------------------------
; Read Mouse Input Device and update reticule
ProcessMouse:	
        call    ReadMouse
        call    CheckUpdateReticule
        ;call    SetReticuleRotationValue
	
/* - 09/07/23 - No longer used
; Animate reticule
        ld      ix, ReticuleSprAtt
        ld      iy, ReticuleSprite
        ld      bc, RetNormalPatterns
        call    UpdateSpritePattern
*/
        ret

;-------------------------------------------------------------------------------------
; Read and process Mouse Input Device
; Parameters:
; Return:
; NewPosY =  New Y position for reticule 
; NewPosX =  New X position for reticule
; PlayerInput - Updated fire flag 
ReadMouse:	
        ld      bc, $FADF			;FADF Mouse Buttons port

; Check for left mouse button        
        in      a, (c)	                        ;%------LR
	and     %00000010
	jr      nz, .LeftNotClicked

; - Left button clicked
        ld      a, (PlayerInput)
        set     5, a
        ld      (PlayerInput), a

        jp      .CheckRightButton

; - Left button not clicked
.LeftNotClicked:
        ld      a, (PlayerInput)
        res     5, a                            ; Reset fire flag
        ld      (PlayerInput), a

.CheckRightButton:
	in      a, (c)	                        ;%------LR
	and     %00000001
	jr      nz, .RightNotClicked

        ld      a, (GameStatus2)
        bit     3, a
        jp      nz, .RightNotClicked            ; Jump if anti-freeze block hit i.e. Don't freeze

; - Right button clicked
        ld      a, (PlayerInput)
        set     6, a
        ld      (PlayerInput), a

        jp      .ReadMovement

; - Right button not clicked
.RightNotClicked:
        ld      a, (PlayerInput)
        res     6, a                            ; Reset freeze flag
        ld      (PlayerInput), a

; Read mouse x movement
.ReadMovement:
	ld      a, (XMove)                      ; Obtain previous mouseX value
	ld      d, a
	inc     b		                ; Point to mouse X port
	in      a, (c)			        ; FBDF Mouse Xpos - Obtain new MouseX value

        ld      (XMove), a                      ; Store new mouseX value
	sub     d                               ; Subtract previous mouseX from new mouseX

        call    CheckMouseSpeed                 ; Check value <= MouseSpeed
	ld      d, a                            ; DeltaMouseX value

; - Check direction
        cp      0                               
        jp      z, .MouseUPDOWN                 ; Jump if x value has not changed

; - Process mouse X movement
        ld      a, (MouseXDelta)                
        add     d

        ld      (MouseXDelta), a

; Read mouse Y movement
.MouseUPDOWN:
        ld      bc, $FFDF			; Point to mouse Y port

	ld      a, (YMove)                      ; Obtain previous mouseY value
	ld      e, a
	in      a, (c)			        ; FFDF Mouse Ypos - Obtain new MouseY value
	ld      (YMove), a                      ; Store new mouseY value
	sub     e                               ; Subtract previous mouseY from new mouseY

        call    CheckMouseSpeed                 ; Check value <= MouseSpeed
	ld      e, a                            ; DeltaMouseY value

; - Check direction
        cp      0                               
        ret     z                               ; Jump if y value has not changed
	
; - Process mouse Y movement
        ld      a, (MouseYDelta)                
        sub     e

        ld      (MouseYDelta), a

        ret

; - Process mouse down movement
.MouseDown:
	neg					; Flip Ypos - Ensures value increments from top-to-bottom
	ld      e, a                            ; DeltaMouseY value

        ld      a, (MouseYDelta)                
        add     e

        ld      (MouseYDelta), a

        ret

;-------------------------------------------------------------------------------------
; Check/Update reticule in relation to player position, and update sprite
; Parameters:
; MouseXDelta = X gap between reticule and player
; MouseYDelta = Y gap between reticule and player
; Return:
CheckUpdateReticule:
; Reset boundary variable for changing mouse pointer - Default within boundary
        ;;ld      a, 0
        ;;ld      (OutOfBoundary), a

        ld      a, (MouseXDelta)


        ;cp      128
        ;jp      nz, .Cont               ; arg > a TODO - Bug

        ;halt
        ;nop

;.Cont:


	or      a
	jp      m, .MouseToLeft                    ; Jump if mouse to left of player i.e. MouseXDelta value is negative

; --- Mouse to right of player
; - Check RotRange to player
        ld      a, (MouseXDelta)
        call    CheckRotRange

        ld      a, c                            ; Return value = Updated Delta value
        ld      (MouseXDelta), a

; - Check right border - Displayable screen edge
        ld      b, 0                            ; bc = Updated Delta value
        ld      (BackupWord1), bc                ; Save delta value

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.xPosition)
        add     hl, bc

        xor     a
        ld      bc, 289                         ; 320 - (2 * 16) + 1
        sbc     hl, bc
        jp      nc, .ResetXRight                ; Jump if value >= 289

        add     hl, bc                          ; Otherwise re-add value
	
        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl            ; Update reticule with updated position

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        ld      bc, (BackupWord1)                                        ; Restore delta value
        add     hl, bc
        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl     ; Update reticule with updated position

        jp      .CheckVertical

.ResetXRight:
        ld      hl, 288                                                 ; Reset x to right displayable edge of screen
        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl            ; Update reticule with updated position
        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl    ; Update reticule with updated position

; - Reset Xdelta to difference between right border and player
        ld      hl, 288
        ld      bc, (PlayerSprite+S_SPRITE_TYPE.xPosition)

        sbc     hl, bc

        ld      a, l
        ld      (MouseXDelta), a                                

        jp      .CheckVertical

; --- Mouse to left of player
.MouseToLeft: 
; - Check RotRange to player
        ld      a, (MouseXDelta)
        neg                                     ; Change to positive value
        call    CheckRotRange

        ld      a, c                            ; Return value = Updated Delta value
        neg                                     ; Change back to negative value
        ld      (MouseXDelta), a

; - Check left border - Displayable screen edge
        ld      b, 0                            ; bc = Updated Delta value
        ld      (BackupWord1), bc                ; Save delta value

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.xPosition)

        or      a
        sbc     hl, bc
        jr      c, .ResetXLeft                  ; Jump if value beyond left displayable screen edge

; - Check left border - Border of play area
        ld      bc, 16
        sbc     hl, bc
        jr      c, .ResetXLeft                  ; Jump if value less than 16

        add     hl, bc                          ; Otherwise re-add value

        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl            ; Update reticule with updated position

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.XWorldCoordinate)
        ld      bc, (BackupWord1)                                        ; Restore delta value
        or      a
        sbc     hl, bc
        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl     ; Update reticule with updated position

        jp      .CheckVertical

.ResetXLeft:
        ld      hl, 16                                                  ; Set left border value
        ld      (ReticuleSprite+S_SPRITE_TYPE.xPosition), hl            ; Update reticule with updated position
        ld      (ReticuleSprite+S_SPRITE_TYPE.XWorldCoordinate), hl     ; Update reticule with updated position

; - Reset Xdelta to difference between left border and player
        ld      hl, (PlayerSprite+S_SPRITE_TYPE.xPosition)
        add     hl, -16

        ld      a, l
        neg                                                     ; Make delta negative
        ld      (MouseXDelta), a                                

; Check vertical boundary between Reticule and Player
.CheckVertical:
        ld      a, (MouseYDelta)

	or      a
	jp      m, .MouseAbove                    ; Jump if mouse above player i.e. MouseYDelta value is negative

; --- Mouse below player
; - Check RotRange to player
        ld      a, (MouseYDelta)
        call    CheckRotRange

        ld      a, c                            ; Return value = Updated Delta value
        ld      (MouseYDelta), a

; - Check bottom border - Displayable screen edge        
        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)
        add     c                               ; c = Updated Delta value
        jp      c, .ResetYDown                  ; Jump if value > 255

; - Check bottom border - Border of play area
        cp      225                             ; 256 - (2 * 16) + 1
        jp      nc, .ResetYDown                 ; Jump if 225 <= value
	
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a             ; Update reticule with updated position

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        ld      b, 0                                                    ; bc = Delta value
        add     hl, bc
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl     ; Update reticule with updated position

        ret

.ResetYDown:
        ld      a, 224                                          ; Reset y to bottom displayable edge of screen
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a     ; Update reticule with updated position

        ld      h, 0
        ld      l, a
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl     ; Update reticule with updated position

; - Reset Ydelta to difference between bottom border and player
        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)
        ld      b, a
        ld      a, 224

        sub     b

        ld      (MouseYDelta), a                                

        ret

; --- Mouse above player
.MouseAbove:
; - Check RotRange to player
        ld      a, (MouseYDelta)
        neg                                     ; Change to positive value
        call    CheckRotRange

        ld      a, c                            ; Return value = Updated Delta value
        neg                                     ; Change back to negative value
        ld      (MouseYDelta), a

; - Check top border - Displayable screen edge        
        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)
        sub     c                               ; c = Updated positive Delta value
        jp      c, .ResetYUp                    ; Jump if value negative i.e Off top of screen

; - Check top border - Border of play area
        cp      16                              
        jp      c, .ResetYUp                    ; Jump 16 > value
	
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a             ; Update reticule with updated position

        ld      hl, (PlayerSprite+S_SPRITE_TYPE.YWorldCoordinate)
        ld      b, 0                                                    ; bc = Delta value
        or      a
        sbc     hl, bc
        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl     ; Update reticule with updated position

        ret

.ResetYUp:
        ld      a, 16                                           ; Reset y to top displayable edge of screen
        ld      (ReticuleSprite+S_SPRITE_TYPE.yPosition), a     ; Update reticule with updated position

        ld      (ReticuleSprite+S_SPRITE_TYPE.YWorldCoordinate), hl     ; Update reticule with updated position

; - Reset Ydelta to difference between top border and player
        ld      a, (PlayerSprite+S_SPRITE_TYPE.yPosition)
        sub     16

        neg                                                     ; Make delta negative
        ld      (MouseYDelta), a                                
        
        ret

;-------------------------------------------------------------------------------------
; Check/Update position in relation to player RotRange
; Parameters:
; a = Mouse Delta value to check i.e. X or Y
; Return:
; c = Updated Delta value
CheckRotRange:
        ld      c, a                            ; Return value

	ld      a, (PlayerSprite+S_SPRITE_TYPE.RotRange)
        cp      c                               ; Compare with RotRange
        jp      c, .ResetToRotRange             ; Jump if Mouse Delta > RotRange

        ret
        
.ResetToRotRange:
        ld      a, (PlayerSprite+S_SPRITE_TYPE.RotRange)
        ld      c, a                            ; Return value

        ret

;-------------------------------------------------------------------------------------
; Check/Update position in relation to player RotRange
; Parameters:
; a = Mouse input
; Return:
; a = Updated mouse input
CheckMouseSpeed:
        push    af

        ld      a, (MouseSpeed)
        ld      b, a

        pop     af

        neg                             ; Negate value to set flags
        jp      m, .NegativeValue       ; Jump if value was previously a positive value

; Previous = Negative, Now = Positive
        cp      b
        jp      nc, .PosResetValue      ; Return if mouse input <= Mouse Speed

        neg                             ; Convert value back to a negative value

        ret

.PosResetValue:
        ld      a, b                    ; Limit mouse input
 
        neg                             ; Convert value back to a negative value

        ret

; Previous = Positive, Now = Negative
.NegativeValue:
        neg                             ; Convert value back to a positive value

        inc     b
        cp      b
        ret     c                       ; Return if mouse input <= Mouse Speed

        dec     b
        ld      a, b                    ; Limit mouse input

        ret

/* - Previously created for storing rotation in player data to allow rotation of player to reticule
;-------------------------------------------------------------------------------------
; Set Player Rotation based on Reticule position
; Parameters:
SetReticuleRotationValue:
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
        jp      .SetRotation                            ; No offset required

.Quarter2:
        ld      a, 128                                  
        sub     b                                       ; 180 degrees - angle
        jp      .SetRotation

.Quarter3:
        ld      a, 128
        add     b                                       ; 180 degrees + angle
        jp      .SetRotation

.Quarter4:
        ld      a, 255
        sub     b                                       ; 360 degrees - angle

.SetRotation:
	ld	(PlayerSprite+S_SPRITE_TYPE.Rotation), a

	ret
*/
EndofMouseCode: