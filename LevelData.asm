;-------------------------------------------------------------------------------------
; Level Data Variables - Common to all levels
; - Populated during level setup with level data
LevelDataMemBank:               db      0
LevelDataReference:             dw      0
; --- Tile Map
LevelDataTileMapDefMemBank:     db      0
LevelDataTileMapDefPalData:     dw      0
LevelDataPalOffset:             db      0
LevelDataPalOffset2:            db      0
LevelDataPalOffset3:            db      0
LevelDataTileMapData:           dw      0
; --- Player
LevelDataPlayerData:            dw      0
; --- WayPoints
LevelDataWayPointNumber:        db      0
LevelDataWayPointData:          dw      0
; --- SpawnPoints
LevelDataSpawnPointNumber:      db      0
LevelDataSpawnPointData:        dw      0
; --- Friendly
LevelDataFriendlyNumber:        db      0
LevelDataFriendlyData:          dw      0
; --- Keys
LevelDataKeyNumber:             db      0
LevelDataKeyData:               dw      0
; --- Turrets
LevelDataTurretNumber:          db      0
LevelDataTurretData:            dw      0
; --- Hazards
LevelDataHazardNumber:          db      0
LevelDataHazardData:            dw      0
; --- Lockers
LevelDataLockerNumber:          db      0
LevelDataLockerData:            dw      0
; --- Trigger Source
LevelDataTriggerSourceNumber:   db      0
LeveldataTriggerSourceData:     dw      0
; --- Triggers Target
LevelDataTriggerTargetNumber:   db      0
LevelDataTriggerTargetData:     dw      0
; --- L2 Data
LevelDataL2Data:                dw      0
LevelDataL2PaletteData:         dw      0

;-------------------------------------------------------------------------------------
; Level Data - Defines tilemaps and other level data for each level
LevelTotal:     equ      10              ; Number of levels
LevelData:
Level1      S_LEVEL_REFERENCE {
                $$LevelData1,                   ; Memory bank hosting level data
                Level1Data                      ; Link to level data
                }         
Level2      S_LEVEL_REFERENCE {
                $$LevelData2,                   ; Memory bank hosting level data
                Level2Data                      ; Link to level data
                }         
Level3      S_LEVEL_REFERENCE {
                $$LevelData3,                   ; Memory bank hosting level data
                Level3Data                      ; Link to level data
                }         
Level4      S_LEVEL_REFERENCE {
                $$LevelData4,                   ; Memory bank hosting level data
                Level4Data                      ; Link to level data
                }         
Level5      S_LEVEL_REFERENCE {
                $$LevelData5,                   ; Memory bank hosting level data
                Level5Data                      ; Link to level data
                }         
Level6      S_LEVEL_REFERENCE {
                $$LevelData6,                   ; Memory bank hosting level data
                Level6Data                      ; Link to level data
                }         
Level7      S_LEVEL_REFERENCE {
                $$LevelData7,                   ; Memory bank hosting level data
                Level7Data                      ; Link to level data
                }         
Level8      S_LEVEL_REFERENCE {
                $$LevelData8,                   ; Memory bank hosting level data
                Level8Data                      ; Link to level data
                }         
Level9      S_LEVEL_REFERENCE {
                $$LevelData9,                   ; Memory bank hosting level data
                Level9Data                      ; Link to level data
                }         
Level10     S_LEVEL_REFERENCE {
                $$LevelData10,                   ; Memory bank hosting level data
                Level10Data                      ; Link to level data
                }         
EndOfLevelData: