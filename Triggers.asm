TriggersCode:
;-------------------------------------------------------------------------------------
; Initialise TriggerSource and TriggerTarget data
; Parameters:
; a = Memory block containing level tilemap data
;
InitTriggers:
; Obtain trigger level data
; - Map trigger data bank to slot 3
        ;ld      a, $$TileMapDataLevel1           ; Memory bank (8kb) containing tilemap data
        nextreg $53, a                          

; 1. Convert/Copy source TriggerTarget data --> Working TriggerTarget data
        ld      a, (LevelDataTriggerTargetNumber)
        cp      0
        ret     z                               ; Return if no TriggerTarget data

        ld      a, (LevelDataTriggerTargetNumber)
        ld      b, a
        ld      a, MaxTriggerTarget
        cp      b
        ret     c                               ; Return if TriggerTargetNumber > MaxTriggerTarget

        ld      ix, (LevelDataTriggerTargetData)        ; Source - ASM TriggerTarget data
        ld      iy, TriggerTargetData                   ; Dest   - Working TriggerTarget data

        ld      a, (LevelDataTriggerTargetNumber)
        ld      b, a
.CopyTriggerTargetLoop:
        push    bc

; - Convert world coordinates to tilemap block offset
        ld      bc, (ix+S_TRIGGERTARGETASM_DATA.xWorld)
        ld      hl, (ix+S_TRIGGERTARGETASM_DATA.yWorld)

        ld      de, 16
        or      a
        sbc     hl, de                                                  ; Tiled Y starts at 16, so subtract 16

        call    ConvertWorldToBlockOffset

; - Copy values
        ld      (iy+S_TRIGGERTARGET_DATA.TileBlockOffset), bc           ; Return value
        ld      hl, (ix+S_TRIGGERTARGETASM_DATA.TriggerTargetID)
        ld      (iy+S_TRIGGERTARGET_DATA.TriggerTargetID), hl
        ld      a, (ix+S_TRIGGERTARGETASM_DATA.TriggerSourceNumber)
        ld      (iy+S_TRIGGERTARGET_DATA.TriggerSourceNumber), a

        ld      de, S_TRIGGERTARGETASM_DATA
        add     ix, de

        ld      de, S_TRIGGERTARGET_DATA
        add     iy, de

        pop     bc

        djnz    .CopyTriggerTargetLoop

; 2. Convert/Copy source TriggerSource data --> Working TriggerSource data
        ld      a, (LevelDataTriggerSourceNumber)
        cp      0
        ret     z                               ; Return if no TriggerSource data

        ld      a, (LevelDataTriggerSourceNumber)
        ld      b, a
        ld      a, MaxTriggerSource
        cp      b
        ret     c                               ; Return if TriggerSourceNumber > MaxTriggerSource

        ld      ix, (LeveldataTriggerSourceData)        ; Source - ASM TriggerSource data
        ld      iy, TriggerSourceData                   ; Dest   - Working TriggerSource data

        ld      a, (LevelDataTriggerSourceNumber)
        ld      b, a
.CopyTriggerSourceLoop:
        push    bc

; - Convert world coordinates to tilemap block offset
        ld      bc, (ix+S_TRIGGERSOURCEASM_DATA.xWorld)
        ld      hl, (ix+S_TRIGGERSOURCEASM_DATA.yWorld)

        ld      de, 16
        or      a
        sbc     hl, de                                                  ; Tiled Y starts at 16, so subtract 16

        call    ConvertWorldToBlockOffset

; - Copy values
        ld      (iy+S_TRIGGERSOURCE_DATA.TileBlockOffset), bc           ; Return value

; - Search TriggerTargetData for TriggerTargetID Address
        push    iy

        ld      iy, TriggerTargetData                                   ; Source to search

        ld      a, (LevelDataTriggerTargetNumber)
        ld      b, a
.SearchTriggerTarget:
        ld      hl, (ix+S_TRIGGERSOURCEASM_DATA.TriggerTargetID)        ; Search item
        ld      de, (iy+S_TRIGGERTARGET_DATA.TriggerTargetID)           ; Target item

        or      a
        sbc     hl, de
        jp      nz, .NextTriggerTarget

        ld      hl, iy                                                  ; Get address and not content
        jp      .ContTriggerSource

.NextTriggerTarget:
        ld      de, S_TRIGGERTARGET_DATA
        add     iy, de

        djnz    .SearchTriggerTarget

        ld      hl, 0                                                   ; 0 = TriggerTargetID not found

.ContTriggerSource:
        pop     iy

; - Configure TriggerTargetID address
        ld      (iy+S_TRIGGERSOURCE_DATA.TriggerTargetIDAddress), hl

; - Configure DoorLockdown value
        ld      a, (ix+S_TRIGGERSOURCEASM_DATA.DoorLockdown)
        ld      (iy+S_TRIGGERSOURCE_DATA.DoorLockdown), a

        ld      de, S_TRIGGERSOURCEASM_DATA
        add     ix, de

        ld      de, S_TRIGGERSOURCE_DATA
        add     iy, de

        pop     bc

        djnz    .CopyTriggerSourceLoop
        
        ret

;-------------------------------------------------------------------------------------
; Update TriggerTarget data - Used for TriggerSource condition
; Parameters:
; hl = TileBlockOffset for search
; Return:
UpdateTriggerTargetData:
; Search for corresponding TriggerSource entry
        ld      ix, TriggerSourceData                                   ; Source to search

        ld      a, (LevelDataTriggerSourceNumber)
        cp      0
        ret     z               ; Return if no Trigger source entries

        ld      b, a
.SearchTriggerSource:
        ld      de, (ix+S_TRIGGERSOURCE_DATA.TileBlockOffset)           ; Target item to check

        or      a
        sbc     hl, de
        add     hl, de                                                  ; Restore register for next search (if required)
        jp      nz, .TriggerSourceNotFound

; TriggerSource Found - Update corresponding TriggerTarget entry
        push    ix

; Check DoorLockdown status
        ld      a, (DoorLockdown)
        cp      1
        jp      z, .ProcessTrigger                                      ; Jump if DoorLockdown is already enabled

        ld      a, 0
        cp      (ix+S_TRIGGERSOURCE_DATA.DoorLockdown)
        jp      z, .ProcessTrigger                                      ; Jump if DoorLockdown not required

; - Enable DoorLockdown
        ld      a, 1
        ld      (DoorLockdown), a                                       ; Lock all doors

        ld      (DoorLockdownTileOffset), hl                            ; TileOffset - Used for key Trigger Target

        ld      a, 0
        ld      (RecordSpawnedNumber), a                                ; Reset enemy counter

; - Change to lockdown palette
        ld      a, (LevelDataPalOffset2)
        ld      (CurrentTileMapPal), a
        call    SelectTileMapPalOffset

        ld      a, DoorLockdownPalCycleEnabled
        ld      (DoorLockdownPalCycleOffset), a

; - Lock entry door
        push    iy

        ld      iy, (LastDoorPlayerUnlocked)

        ld      a, (iy+S_DOOR_DATA.DoorType)
        res     6, a                            ; Reset open door
        set     3, a                            ; Set closing door
        ld      (iy+S_DOOR_DATA.DoorType), a

        pop     iy

.ProcessTrigger:
        ld      de, (ix+S_TRIGGERSOURCE_DATA.TriggerTargetIDAddress)    ; Get TriggerTarget addresss
        ld      ix, de
        dec     (ix+S_TRIGGERTARGET_DATA.TriggerSourceNumber)           ; Decrement source number

        pop     ix

.TriggerSourceNotFound:
        ld      de, S_TRIGGERSOURCE_DATA
        add     ix, de

        djnz    .SearchTriggerSource

        ret

;-------------------------------------------------------------------------------------
; Check TriggerTarget data - Used for TriggerTarget condition
; Parameters:
; hl = TileBlockOffset for search
; Return:
; a = 0 (TriggerSourceNumber value != 0, or TriggerTarget not found) = Don't trigger event, 1 (TriggerSourceNumber value = 0 = Trigger event)
CheckTriggerTargetData:
; Search for corresponding TriggerTarget entry
        ld      ix, TriggerTargetData                                   ; Source to search

        ld      a, (LevelDataTriggerTargetNumber)
        ld      b, a
.SearchTriggerTarget:
        ld      de, (ix+S_TRIGGERTARGET_DATA.TileBlockOffset)           ; Target item to check

        or      a
        sbc     hl, de
        add     hl, de                                                  ; Restore register for next search (if required)
        jp      z, .TriggerTargetFound

        ld      de, S_TRIGGERTARGET_DATA
        add     ix, de

        djnz    .SearchTriggerTarget

        ld      a, 0                                                    ; Return - TriggerTarget not found

        ret

; Check corresponding TriggerTarget entry
.TriggerTargetFound:
        ld      a, 0
        cp      (ix+S_TRIGGERTARGET_DATA.TriggerSourceNumber)
        ret     nz                                                      ; Return if TriggerSourceNumber != 0

; Play audio effect
        push    ix

        ld      a, AyFXTriggerTarget
        call    AFX1Play

        pop     ix

        ld      a, 1                                                    ; Return - TriggerSourceNumber = 0

        ret

/* 21/06/23 - Not Used
;-------------------------------------------------------------------------------------
; Search TriggerTarget data for tilemap offset
; Parameters:
; hl = TileBlockOffset for search
; Return:
; a = 0 (not found), 1 (found)
SearchTriggerTargetData:
; Search for corresponding TriggerTarget entry
        ld      ix, TriggerTargetData                                   ; Source to search

        ld      a, (LevelDataTriggerTargetNumber)
        ld      b, a
.SearchTriggerTarget:
        ld      de, (ix+S_TRIGGERTARGET_DATA.TileBlockOffset)           ; Target item to check

        or      a
        sbc     hl, de
        add     hl, de                                                  ; Restore register for next search (if required)
        jp      z, .TriggerTargetFound

        ld      de, S_TRIGGERTARGET_DATA
        add     ix, de

        djnz    .SearchTriggerTarget

        ld      a, 0                                                    ; Return - TriggerTarget not found

        ret

; Found corresponding TriggerTarget entry
.TriggerTargetFound:        
        ld      a, 1                                                    ; Return - TriggerTarget found

        ret
*/

;-------------------------------------------------------------------------------------
; Check whether DoorLockdown can be disabled
; Parameters:
; Return:
CheckEndDoorLockdown:
        ld      a, (DoorLockdown)
        cp      0
        ret     z                       ; Return if DoorLockdown not enabled

        ld      a, (RecordSpawnedNumber)
        cp      0
        ret     nz                      ; Return if spawned enemies still active

        ld      hl, (DoorLockdownTileOffset)
        call    CheckTriggerTargetData

        cp      0                       ; Check return value
        ret     z                       ; Return if Counter != 0 i.e. Spawner still active

; Trigger Condition - Update TriggerTarget
        ld      hl, (DoorLockdownTileOffset)
        call    UpdateTriggerTargetData

/* 28/04/23 - No longer nescessary as all doors will remain closed unless opened by player/enemy
; Unlock entry door
        ld      iy, (LastDoorPlayerUnlocked)

        ld      a, (iy+S_DOOR_DATA.DoorType)
        res     4, a                    ; Door - Clear closed flag
        res     3, a                    ; Door - Clear closing flag
        set     5, a                    ; Door - Set opening flag
        ld      (iy+S_DOOR_DATA.DoorType), a
*/

; Mote: Always perform after Trigger condition check above, otherwise DoorLockdown will be set again
        ld      a, 0
        ld      (DoorLockdown), a       ; Disable DoorLockdown

; Change Palette
; - Check whether player has rescued all friendly
        ld      a, (GameStatus)
        bit     7, a
        jp      nz, .LevelCompletePal                   ; Jump if all friendly rescued

; - Revert back to original palette
        ld      a, (LevelDataPalOffset)
        ld      (CurrentTileMapPal), a
        call    SelectTileMapPalOffset

        ld      a, DoorLockdownPalCycleDisabled
        ld      (DoorLockdownPalCycleOffset), a

        ret

.LevelCompletePal:
; - Revert back to level complete palette
        ld      a, (LevelDataPalOffset3)
        ld      (CurrentTileMapPal), a
        call    SelectTileMapPalOffset

        ld      a, FriendlyRescuedPalCycleEnabled
        ld      (DoorLockdownPalCycleOffset), a

        ret

