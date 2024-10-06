TitleData:
;-------------------------------------------------------------------------------------
; Structures
; Structure for HighScore Table Values
        STRUCT S_HighScore_Values
y               BYTE    0       ; Y
x               BYTE    0       ; X
Value           TEXT    6       ; 6 x bytes
Terminator      BYTE    0       ; 0
        ENDS

; Structure for HighScore Table Names
        STRUCT S_HighScore_Names
y               BYTE    0       ; Y
x               BYTE    0       ; X
Name            TEXT    3       ; 3 x bytes
Terminator      BYTE    0       ; 0
        ENDS

; Structure for Title Layer2 Borders
        STRUCT S_Title_L2Borders
TopMemBank      BYTE    0       ; Memory bank hosting top border
TopAddress      WORD    0       ; Top border memory location
BottomMemBank   BYTE    0       ; Memory bank hosting bottom border
BottomAddress   WORD    0       ; Bottom border memory location
LeftMemBank     BYTE    0       ; Memory bank hosting left border
LeftAddress     WORD    0       ; Left border memory location
RightMemBank    BYTE    0       ; Memory bank hosting right border
RightAddress    WORD    0       ; Right border memory location
        ENDS

;-------------------------------------------------------------------------------------
; Title Screen Settings
;
; - Sprite Text - TODO

; - Tilemap - TODO
TitleTileMapData:               equ     $6000   ; Address of title source tilemap data
TitleTileMapWidth:              equ     20      ; Maximum width for title tilemap
TitleTileMapHeight:             equ     16      ; Maximum height for title tilemap
; - Palette Cycle - TODO



; Sprite Animation Pattern Ranges
; -- 4Bit Patterns
; --- Title-Main Sprites (Different pattern numbers)
TitleSpriteTextPatterns:        db      0, 0, 0, %1'000'1111            ; Only byte 4 relevant
TitleUIDownPatterns:            db      20, 93, 30, %1'000'0000         ; Animation delay, First pattern, Last pattern, Palette
TitleUIUpPatterns:              db      20, 94, 31, %1'000'0000         ; Animation delay, First pattern, Last pattern, Palette
TitleMainReticulePatterns:      db      0, 32, 32, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitlePlayPatterns:              db      20, 33, 97, %1'000'1010          ; Animation delay, First pattern, Last pattern, Palette
TitleLockedPatterns:            db      0, 96, 96, %1'000'1000          ; Animation delay, First pattern, Last pattern, Palette
TitleUIInstrPatterns:           db      50, 46, 110, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitleUIHighScorePatterns:       db      50, 54, 118, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitleAnimatedPatterns:
TitlePlayerStrPatterns:         db      5, 35, 36, %1'000'0000        ; Animation delay, First pattern, Last pattern, Palette
TitleFriendlyStrPatterns:       db      5, 35, 36, %1'000'0001        ; Animation delay, First pattern, Last pattern, Palette
; --- Title-Instructions Sprites (Different pattern numbers)
TitleInstrReticulePatterns:     db      0, 0, 0, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrUIRightPatterns:      db      20, 2, 66, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrUIHomePatterns:       db      50, 68, 5, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrPlayerPatterns:       db      4, 3, 4, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrFriendlyEnPatterns:   db      4, 3, 4, %1'000'0001          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrFriendlyDisPatterns:  db      4, 71, 71, %1'000'0001          ; Animation delay, First pattern, Last pattern, Palette
TitleInstResPointEmptyPatterns: db      20, 101, 38, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstResPointFullPatterns:  db      20, 102, 102, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstFinPointFullPatterns:  db      20, 42, 106, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeyWPatterns:          db      20, 43, 43, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeyQPatterns:          db      20, 107, 107, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeyAPatterns:          db      20, 44, 44, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeySPatterns:          db      20, 108, 108, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeyDPatterns:          db      20, 45, 45, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeySpace1Patterns:     db      20, 109, 109, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeySpace2Patterns:     db      20, 46, 46, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeySpace3Patterns:     db      20, 110, 110, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstKeyRPatterns:          db      20, 47, 47, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstMouseClickPatterns:    db      30, 111, 48, %1'000'1100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstNoFreezeBlockPatterns: db      30, 33, 33, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstLockerEnergy1Patterns: db      10, 112, 113, %1'000'1101          ; Animation delay, First pattern, Last pattern, Palette
TitleInstLockerEnergy2Patterns: db      0, 112, 112, %1'000'1101          ; Animation delay, First pattern, Last pattern, Palette
TitleInstLockerTimePatterns:    db      10, 50, 51, %1'000'1101          ; Animation delay, First pattern, Last pattern, Palette
TitleInstPickupEnergyPatterns:  db      10, 115, 116, %1'000'1101          ; Animation delay, First pattern, Last pattern, Palette
TitleInstPickupTimePatterns:    db      10, 53, 54, %1'000'1101          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsGrnHorPatterns:  db      10, 56, 56, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsGrnVerPatterns:  db      10, 120, 120, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsRedHorPatterns:  db      10, 57, 57, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsRedVerPatterns:  db      10, 121, 121, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsKey1Patterns:    db      10, 118, 119, %1'000'1110          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsKey2Patterns:    db      0, 118, 118, %1'000'1110          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsBlueHorPattens:  db      20, 58, 122, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDoorsBlueVerPatterns: db      20, 59, 123, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrTriggerFloorPatterns: db      20, 32, 32, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrSavePointsInPatterns: db      20, 34, 34, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrSavePointsAcPatterns: db      20, 98, 98, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDisplayRetWhPatterns: db      0, 124, 124, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDisplayRetYlPatterns: db      0, 124, 124, %1'000'0001          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrDisplayRetRdPatterns: db      0, 124, 124, %1'000'0010          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrHazardsDesPatterns:   db      0, 60, 60, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrHazardsHazPatterns:   db      20, 35, 100, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrHazardsHazSwPatterns: db      20, 126, 126, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrHazardsHazRvPatterns: db      20, 127, 127, %1'000'0001          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrHazardsSPLPatterns:   db      20, 40, 104, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrHazardsSPUPatterns:   db      20, 39, 103, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrHazardsSPDeatterns:   db      20, 41, 41, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesGrtPatterns:   db      4, 11, 12, %1'000'0010          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesGrtFPatterns:  db      3, 79, 80, %1'000'0011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesShootPatterns: db      6, 17, 83, %1'000'0100          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesTermPatterns:  db      5, 24, 89, %1'000'0101          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesWayPatterns:   db      4, 26, 90, %1'000'0110          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesWaySPatterns:  db      4, 29, 93, %1'000'0110          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesTurrPatterns:  db      20, 8, 9, %1'000'1011          ; Animation delay, First pattern, Last pattern, Palette
TitleInstrEnemiesTurr2Patterns: db      10, 73, 10, %1'000'0110          ; Animation delay, First pattern, Last pattern, Palette
; --- Title-HighScore Sprites (Different pattern numbers)
TitleHighScoreUIHomePatterns:   db      50, 100, 37, %1'000'0000        ; Animation delay, First pattern, Last pattern, Palette
TitlePlayerDownPatterns:        db      5, 38, 39, %1'000'0000          ; Animation delay, First pattern, Last pattern, Palette

;-------------------------------------------------------------------------------------
; Title-Main Sprite Data
; Note: Refer to PrintSpriteText routine for Text string format
; --- Level
TitleLevelText:                 db      $08, $04, "LEVEL", 0  
TitleLevelNumberValueXY:        equ     $0c08   ; Block position for calculated value
TitleLevelDownXY:               equ     $0a08   ; Block position for sprite
TitleLevelUpXY:                 equ     $0f08   ; Block position for sprite
TitleLevelValueDigits:          equ     2       ; Number of digits in level value
TitleLevelValueSpriteNum:       db      0       ; Sprite number for left-most level sprite value - Set in code
; --- Mode
TitleModeText:                  db      $0a, $05, "MODE", 0  
TitleModeDownXY:                equ     $0a0a                   ; Block position for sprite
TitleModeUpXY:                  equ     $0f0a                   ; Block position for sprite
TitleModeEasyText:              db      $0a, $0b,"EASY", 0
TitleModeHardText:              db      $0a, $0b,"HARD", 0
TitleModeValueXY:               equ     $0b0a                   ; Block position for calculated value
TitleModeValueDigits:           equ     4                       ; Number of digits in mode value
TitleModeValueSpriteNum:        db      0                       ; Sprite number for left-most mode sprite value - Set in code
; --- Start
TitlePlayText:                  db      $0b, $09, "PLAY", 0  
TitleStartLeftXY:               equ     $080b                   ; Block position for sprite
TitleHighScoreScreenXY:         equ     $0e0b                   ; Block position for sprite
TitleInstrScreenXY:             equ     $0f0b                   ; Block position for sprite
; --- Scroll Text
TitleScrollText:                db      $0e, $14, 102, 0, "WELCOME TO WEBSTER AND THE SPIDER-BOTS "     ; First 2 x bytes = block offset --- Scroll text
                                db      102, 1, "CODING BY ROB MORAN ", 102, 0, "GRAPHICS BY EMCEE FLESHER & ROB MORAN "
                                db      102, 1, "MUSIC BY DARRYL SLOAN ", 102, 0, "MUSIC SHORTS BY SMITHCODER, VOODO, DEV & JRRS "
                                db      102, 1, "SPECIAL THANKS TO ADRIAN SINCLAIR & BRET BAPSTARCADE PRITCHARD FOR TESTING "
                                db      102, 0, "FINALLY THANKS FOR DOWNLOADING AND PLAYING; IF YOU ENJOYED PLAYING PLEASE ALSO CHECK OUT DOUGIE DO! AVAILABLE FROM "
                                db      "HTTPS://ROBGM.ITCH.IO/ - THANKS AGAIN AND GOOD LUCK IN THE WORLD OF THE SPIDER-BOTS...... ", 0
TitleScrollHighScoreText:       db      $0e, $14, 102, 0, "WELL DONE NEW HIGH-SCORE - PLEASE ENTER NAME   ", 0        ; First 2 x bytes = block offset --- Scroll text
TitleScrollTextPointer:         dw      0                       ; Pointer to character within scroll text
TitleScrollSpawnDelay:          equ     16                      ; Delay between scrolling text sprites
TitleScrollSpawnDelayCounter:   db      0
TitleScrollSpritesAttStart:     equ     EnemyBulletAttStart+MaxEnemyBullets+20                  ; Text Scroll sprites start at this Sprite attribute offset
TitleScrollSpritesStart:        equ     Sprites + TitleScrollSpritesAttStart*S_SPRITE_TYPE      ; Test Scroll sprite data
TitleScrollNumSprites:          equ     30                      ; Number of scroll text sprites
TitleScrollTypeTextPointer:     dw      0                       ; Points to title scroll text - either normal text or HighScore entry text - Set in code

;-------------------------------------------------------------------------------------
; Title-HighScore Sprite Data
; Note: Refer to PrintSpriteText routine for Text string format
; - Screen Positions
TitleHighScoreHomeScreenXY:     equ     $0e0b           ; Block position for sprite
TitleHighScoreWebsterTableRow:  equ     4               ; Row size in bytes     
TitleHighScoreWebsterTable:
TitleHighScoreWebsterXY1:       dw      $0a07, $0e07    ; Left block position, Right block position
TitleHighScoreWebsterXY2:       dw      $0a08, $0e08    ; Left block position, Right block position
TitleHighScoreWebsterXY3:       dw      $0a09, $0e09    ; Left block position, Right block position
TitleHighScoreWebsterXY4:       dw      $0a0a, $0e0a    ; Left block position, Right block position
TitleHighScoreWebsterXY5:       dw      $0a0b, $0e0b    ; Left block position, Right block position
TitleHighScoreTotalEntries:     equ     5
; - HighScore Values - Contains default values
TitleHighScoreValues:
                                db      $07, $04, "064730", 0
                                db      $08, $04, "049380", 0
                                db      $09, $04, "031460", 0
                                db      $0a, $04, "015780", 0
                                db      $0b, $04, "002250", 0
; - HighScore Names - Contains default values
TitleHighScoreNames:
                                db      $07, $0b, "ROB", 0
                                db      $08, $0b, "BAR", 0
                                db      $09, $0b, "GRA", 0
                                db      $0a, $0b, "MOL", 0
                                db      $0b, $0b, "BIL", 0
; - Other
NewScore:                       ds      6               ; Temp storage for OldScore
OldScore:                       ds      6               ; Temp storage for NewScore
NewHighScoreEntry:              db      0               ; Number of updated HighScore entry (top = 5, bottom = 1)
NameLength:                     equ     3
NewNameBlank:                   defb    "   "           ; Managed as string due to required value greater than word
NewName:                        ds      NameLength      ; Temp storage for OldName
OldName:                        ds      NameLength      ; Temp storage for NewName

;-------------------------------------------------------------------------------------
; CFG File Settings
FileCFGName:            db      "Webster.cfg", 0
FileCFGHandle:          db      0                               ; Set in code
FileCFGSize:            equ     46
; FileCFGBuffer moved to data.asm to ensure it isn't overwritten when restoring
; data after esxdos read routine

;-------------------------------------------------------------------------------------
; Keyboard Input Variables
TitleHighScoreKeyboardMatrixTable:
; "-" = Ignore key
; "[" = Enter key
; "]" = Delete key - Not in table below - Set in code
; "~" = Caps-Shift
Matrix8:	db	$fe, "~", "Z", "X", "C", "V"	; Port upper byte, key bit 0, 1, 2, 3
; Note: Keep Matrix8 at the top, as we need to check for Caps Shift (bit 0) key combinations before
;       individual keys. This is required due to some emulators/keyboards not sending extended codes
;       e.g. CSpect: Delete key sends Caps Shift+0 (http://slady.net/Sinclair-ZX-Spectrum-keyboard/)
Matrix1:        db      $7f, " ", "-", "M", "N", "B"	; Port upper byte, key bit 0, 1, 2, 3
Matrix2:        db	$bf, "[", "L", "K", "J", "H"	; Port upper byte, key bit 0, 1, 2, 3
Matrix3:	db	$df, "P", "O", "I", "U", "Y"	; Port upper byte, key bit 0, 1, 2, 3
Matrix4:	db	$ef, "0", "9", "8", "7", "6"	; Port upper byte, key bit 0, 1, 2, 3
Matrix5:	db	$f7, "1", "2", "3", "4", "5"	; Port upper byte, key bit 0, 1, 2, 3
Matrix6:	db	$fb, "Q", "W", "E", "R", "T"	; Port upper byte, key bit 0, 1, 2, 3
Matrix7:	db	$fd, "A", "S", "D", "F", "G"	; Port upper byte, key bit 0, 1, 2, 3
TitleHighScoreNameCounter:      db      0               ; Indicates current letter when entering HighScore name

;-------------------------------------------------------------------------------------
; Mouse Variables
TitleMouseStartXPosition:       EQU     168;160;166;144     ; Mouse starting position
TitleMouseStartYPosition:       EQU     152;144;154;144     ; Mouse starting position
; Note: Offsets should be less than 128-MouseSpeed, otherwise chance offset could be interpreted in wrong direction
TitleMouseHorLeftMaxOffset:     EQU     104;112;104;96      ; Max offset mouse can travel from start position
TitleMouseHorRightMaxOffset:    EQU     74;82;90;106     ; Max offset mouse can travel from start position
TitleMouseVerTopMaxOffset:      EQU     30;20;8      ; Max offset mouse can travel from start position
TitleMouseVerBotMaxOffset:      EQU     34;40      ; Max offset mouse can travel from start position
MouseSpeedTitle:                equ     10       ; Speed of in title mouse - Higher Value = Faster - Set in code

; --- Collision Variables (UI)
; - Title Main Screen
TitleLevelDownSpriteNumber:     db      0       ; Set in code
TitleLevelUpSpriteNumber:       db      0       ; Set in code
TitleModeDownSpriteNumber:      db      0       ; Set in code
TitleModeUpSpriteNumber:        db      0       ; Set in code
TitlePlaySpriteNumber:          db      0       ; Set in code
TitleInstrSpriteNumber:         db      0       ; Set in code
TitleHighScoreSpriteNumber:     db      0       ; Set in code
; - Title Instructions Screen
TitleInstrHomeSpriteNumber:     db      0       ; Set in code
TitleInstrLeftSpriteNumber:     db      0       ; Set in code
TitleInstrRightSpriteNumber:    db      0       ; Set in code
; - Title HighScore Screen
TitleHighScoreHomeSpriteNumber: db      0       ; Set in code

;-------------------------------------------------------------------------------------
; Scrolling Tilemap
; --- Table for tilemap tile shown on title page based on CurrentLevel 
TitleTilemapValues:             equ     TitleTilemapTileLevel2-TitleTilemapTileLevel1
TitleTilemapTile:
TitleTilemapTileLevel1:         db      0, 1    ; Palette offset, tile number
TitleTilemapTileLevel2:         db      0, 1    ; Palette offset, tile number
TitleTilemapTileLevel3:         db      0, 1    ; Palette offset, tile number
TitleTilemapTileLevel4:         db      1, 2    ; Palette offset, tile number
TitleTilemapTileLevel5:         db      1, 2    ; Palette offset, tile number
TitleTilemapTileLevel6:         db      1, 2    ; Palette offset, tile number
TitleTilemapTileLevel7:         db      2, 3    ; Palette offset, tile number
TitleTilemapTileLevel8:         db      2, 3    ; Palette offset, tile number
TitleTilemapTileLevel9:         db      3, 4    ; Palette offset, tile number
TitleTilemapTileLevel10:        db      3, 4    ; Palette offset, tile number
TitleTilemapTileLocked:         db      4, 5    ; Palette offset, tile number
; --- Variables controlling tilemap scroll
/* - 28/11/23 - TitleScrollTileMap routine no longer used
; Table of tilemap scroll movements
TitleTilemapScrollDir:          
                                db      1, -1, 50       ; X update, Y update, Duration for updates
                                db      1, 0, 10      ; X update, Y update, Duration for updates
                                db      1, 1, 50      ; X update, Y update, Duration for updates
                                db      0, 1, 10       ; X update, Y update, Duration for updates
                                db      -1, 1, 50      ; X update, Y update, Duration for updates
                                db      -1, 0, 10      ; X update, Y update, Duration for updates
                                db      -1, -1, 50      ; X update, Y update, Duration for updates
                                db      0, -1, 10      ; X update, Y update, Duration for updates


                                db      99              ; End of table
TitleTilemapScrollDirOffset:    dw      0       ; Table location offset
TitleTilemapScrollDirCounter:   db      0       ; X/Y scroll duration counter
*/
TitleTilemapScrollXValue:       db      0       ; X offset
TitleTilemapScrollYValue:       db      0       ; Y offset
TitleTileMapScrollBypass:       db      0

;-------------------------------------------------------------------------------------
; Title-Layer2 Borders
; - Lookup table
; -- Offset Reference = (LevelNumber-1) * 2
TitleBordersTable:
; Levels: 1, 2, 3
        dw      TitleBorders1To3, TitleBorders1To3, TitleBorders1To3    
; Levels: 4, 5, 6
        dw      TitleBorders4To6, TitleBorders4To6, TitleBorders4To6    
; Levels: 7, 8
        dw      TitleBorders7To8, TitleBorders7To8                      
; Levels: 9, 10
        dw      TitleBorders9To10, TitleBorders9To10                    
; Levels: Locked
TitleBordersTableLockedOffset:
        dw      TitleBordersLocked                                      
TitleBordersLastValue:  dw      0       ; Used to limit update of borders - Set in code

; - Data
TitleBorders1To3        S_Title_L2Borders {
        $$Layer2Top1To3,        ; Memory bank hosting top border 
        Layer2Top1To3,          ; Top border memory location
        $$Layer2Bottom1To3,     ; Memory bank hosting bottom border 
        Layer2Bottom1To3,       ; Bottom border memory location
        $$Layer2LeftRight1To3,  ; Memory bank hosting left border 
        Layer2LeftRight1To3,    ; Left border memory location
        $$Layer2LeftRight1To3,  ; Memory bank hosting right border 
        Layer2LeftRight1To3}    ; Right border memory location
TitleBorders4To6        S_Title_L2Borders {
        $$Layer2Top4To6,        ; Memory bank hosting top border 
        Layer2Top4To6,          ; Top border memory location
        $$Layer2Bottom4To6,     ; Memory bank hosting bottom border 
        Layer2Bottom4To6,       ; Bottom border memory location
        $$Layer2Left4To6,       ; Memory bank hosting left border 
        Layer2Left4To6,         ; Left border memory location
        $$Layer2Right4To6,      ; Memory bank hosting right border 
        Layer2Right4To6}        ; Right border memory location
TitleBorders7To8        S_Title_L2Borders {
        $$Layer2Top7To8,        ; Memory bank hosting top border 
        Layer2Top7To8,          ; Top border memory location
        $$Layer2Bottom7To8,     ; Memory bank hosting bottom border 
        Layer2Bottom7To8,       ; Bottom border memory location
        $$Layer2Left7To8,       ; Memory bank hosting left border 
        Layer2Left7To8,         ; Left border memory location
        $$Layer2Right7To8,      ; Memory bank hosting right border 
        Layer2Right7To8}        ; Right border memory location
TitleBorders9To10       S_Title_L2Borders {
        $$Layer2Top9To10,        ; Memory bank hosting top border 
        Layer2Top9To10,          ; Top border memory location
        $$Layer2Bottom9To10,     ; Memory bank hosting bottom border 
        Layer2Bottom9To10,       ; Bottom border memory location
        $$Layer2Left9To10,       ; Memory bank hosting left border 
        Layer2Left9To10,         ; Left border memory location
        $$Layer2Right9To10,      ; Memory bank hosting right border 
        Layer2Right9To10}        ; Right border memory location
TitleBordersLocked      S_Title_L2Borders {
        $$Layer2TopLocked,        ; Memory bank hosting top border 
        Layer2TopLocked,          ; Top border memory location
        $$Layer2BottomLocked,     ; Memory bank hosting bottom border 
        Layer2BottomLocked,       ; Bottom border memory location
        $$Layer2LeftLocked,       ; Memory bank hosting left border 
        Layer2LeftLocked,         ; Left border memory location
        $$Layer2RightLocked,      ; Memory bank hosting right border 
        Layer2RightLocked}        ; Right border memory location

;-------------------------------------------------------------------------------------
; Title-Instructions - Sprite Data
; Note: Refer to PrintSpriteText routine for Text string format
; --- Arrows
TitleInstrHomeScreenXY:         equ     $0d0b                   ; Block position for sprite
TitleInstrLeftScreenXY:         equ     $0e0b                   ; Block position for sprite
TitleInstrRightScreenXY:        equ     $0f0b                   ; Block position for sprite

;-------------------------------------------------------------------------------------
; Title-Instructions - Tilemap Instructions
;
; --- Text Setup - Common to all Instruction Screens
TitleTextTileMapDefsStart:      dw      0       ; Memory location where text tilemap definitions should be uploaded
                                                ; Note: Loaded after block tilemap definitions
TitleTextPalOffset:             equ     5       ; Tilemap palette offset for text definitions
TitleTextDelta:                 equ     32-(TitleTileMapDefBlocks*4)    ; Delta to subtract to obtain correct text tile
                                                                        ; Note: Text tilemap definitions loaded after block tilemap definitions
; - Title instructions Tilemap colour cycle
TitleCycleTMLoopPause:          equ     100      ; Frames to wait after complete Col Cycle
TitleCycleTMLoopPauseCounter:   db      0
TitleCycleTMColCycles:          equ     7       ; Number of cycles for a complete col cycle 
TitleCycleTMColCyclesCounter:   db      0
TitleCycleTMColourDelay:        equ     10      ; Number of frames to wait between each cycle
; --- Text Content - Instruction Screen
; Note: Text stored in additional memory bank
TitleInstrNumberPages:          equ     11      ; Number of title instructions pages
TitleMMU7MemoryBank:            db      0       ; Used to enable original MMU7 memory bank to be mapped back in                      
; --- Sprite Content - Instruction Screen
; Note: Sprite data stored in additional memory bank
TitleInstrSpriteBlockXY:        dw      0       ; Updated in code
TitleInstrSpriteXY:             dw      0       ; Updated in code
TitleInstrSpritePattern:        dw      0       ; Updated in code
TitleInstrSpriteMirror:         db      0       ; Updated in code

;-------------------------------------------------------------------------------------
; Title-Instructions - Copper Lists
; --- Copper List - Instruction Screen-Common
TitleInstrHeadingCycleCopperList50EndScanline:     equ     %00101111       ; 303 (Lower eight bits)
TitleInstrHeadingCycleCopperList60EndScanline:     equ     %00000101       ; 261 (Lower eight bits)

TitleInstrHeadingCycleCopperList:
        db      %1'0000000, 0           ; Wait - Column 0, line 0
        db      %0'1101100, %0101'0000  ; Move - Purple - Set tilemap palette offset ($6c)

        db      %1'0000000, 239         ; Wait - Column 0, line 239
        db      %0'1101100, %1001'0000  ; Move - Cycle - Set tilemap palette offset ($6c)

TitleInstrHeadingCycleCopperListEndScanLine:
        db      %1'0000001, %00000101   ; Wait - Column 0, line - Set in code depending on speed
        db      %0'1101100, %0101'0000  ; Move - Cycle - Set tilemap palette offset ($6c)

        db      $FF, $FF                ; HALT
TitleInstrHeadingCycleCopperListSize = $-TitleInstrHeadingCycleCopperList

;-------------------------------------------------------------------------------------
; Other
TitlePresentsStartPause:        EQU     10      ; 50/<value> = Frames per Second --> Before pause
TitlePresentsPreSpritePause:    EQU     75      ; 50/<value> = Frames per Second --> Before pause
TitlePresentsDancePause:        EQU     30      ; Number of frames to dance
TitlePresentsEndPause:          EQU     75      ; 50/<value> = Frames per Second --> Before pause
TitlePresentsFadePause:         EQU     7       ; 50/<value> = Frames per Second --> Fade in/out pause
TitlePresentsSpriteStopX:       EQU     212     ; X position to pause sprite
TitlePresentsSpriteOffScreenX:  EQU     280     ; X position to pause sprite
TitlePresentsSpriteXOffsetRight:        EQU     138     ; X right offset for sprite window   
TitleHUDSpriteDigit0Pattern:    EQU     8       ; Pattern for sprite digit 0
TitleHUDSpriteDigit1Pattern:    EQU     72      ; Pattern for sprite digit 1
TitleKeyDelay:                  EQU     7;10;5      ; Delay between accepting keyboard input
TitleKeyDelayCounter:           db      0       ; Counter - Set in code
TitleHighScoreKeyDelayCounter:  db      0       ; Counter - Set in code
TitleScreenStatus:              db      0       ; %OMIPJHTN
                                                ; O - Open title/highscore Screen 1st time, M - Main Screen, I - Instructions Screen
                                                ; P - Play Clicked, J - Open Instructions Screen 1st time
                                                ; H - High Score Table, T - Transition from HighScore to Main Screen
                                                ; N - Enter HighScore Name  
TitleInstrStatus:               db      0       ; Instruction Screen number

TitleDataEnd:
;-------------------------------------------------------------------------------------
; Memory Bank Data
;
;-------------------------------------------------------------------------------------
; Title Screen - NextDAW Binary
; NextDAW Player
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     4, $$TitleCodeEnd + 1    ; Slot 2 = $8000..$9FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include NextDAW player
        ORG     $8000   ; Assumes tilemap data not required between $8000-$8499 

NextDAWPlayer:  INCBIN  "webster/assets/audio/NextDAW_RuntimePlayer_8000.bin"

; Title Screen - NextDAW Music Data
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     6 n, $$NextDAWPlayer + 1    ; Slot 0 = $0000..$1fff, 8kb bank reference (16kb refx2)
; - Point to slot 0 memory address and include song data
        ORG     $c000
Song1:
        INCBIN "webster/assets/audio/tracks/sprint.ndr";Zombie Genocide.ndr";sprint.ndr"
Song1End:

;-------------------------------------------------------------------------------------
; Intro Screen - Sprite/Tilemap Palette Data
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3 n, $$Song1End + 1       ; Slot 3 = $6000..$7FFF, "n" option to wrap (around slot 3) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include sprite data
        ORG     $6000
; --- Sprite Palettes
TitlePaletteData:
TitleSpritePalette:
        INCBIN  "webster/assets/titlesprites.pal"

; --- Tilemap Palettes
; TODO - Title Update based on final tilemap definitions
TitleTileMapDefPalRows: equ     10
TitleTileMapDefPalSize: equ     TitleTileMapDefPalRows*32    ; Per palette size
; Note:   8 (rows within palette) * 32 bytes (16 colours per row * 2) -- Need to x 2 as each colour is stored in 2 x bytes   
TitleTileMapDefPal:
        INCBIN  "webster/assets/TitleTiles.pal",,TitleTileMapDefPalSize
TitleL2Palette:
; Note: When imported, palette configured to display black and not use for transparency
        INCBIN  "webster/assets/L2/TitleEmpty.nxp"
TitlePaletteDataEnd:

;-------------------------------------------------------------------------------------
; Title Screen - Tilemap Definitions
; Notes: Tilemap data in different memory bank
TitleTileMapDefinitions:
TitleTileMapDefBlocks:  equ     6;54              ; Blocks start from 0, so a value of 10 would upload blocks 0-9
; Note: Restricted to 54 blocks as we only have 6912 bytes free between $6500 (start of tilemap def memory) & $8000 (NextDAW driver)
;       As 1 x block = 32 (bytes per tile) x 4 tiles per block 
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     7 n, $$TitlePaletteDataEnd + 1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include tilemap definition data
        ORG     $E000
TitleTileMapDefSource:
TitleTileMapDef1:       ; Title-Main Screen
; A total number of x block definitions (4 x tile defs/block=24 tile defs) will be loaded
; Data: Block 0 will be empty, and the remaining 5 blocks will contain tilemap definition data
        INCBIN  "webster/assets/TitleTiles1.til",,TitleTileMapDefBlocks*128    ; Number of blocks * 128 bytes (per block)
TitleTileMapDef2:       ; Title-Instructions Screen
; A total number of 96 tile definitions (8x8) will be loaded
; Data: Block 0 will be empty, and the remaining 5 blocks will contain tilemap definition data
        INCBIN  "webster/assets/TitleTiles2.til",,96*32    ; Number of defs * 32 bytes (4bit)
TitleTileMapDef2End:
TitleTileMapDefinitionsEnd:

;-------------------------------------------------------------------------------------
; Title Screen - Tilemap Data
; Note: Tilemap def & palette in different memory banks
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$TitleTileMapDefinitionsEnd + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
TitleTileMap:           ; Title-Main Screen
        INCBIN  "webster/assets/LevelTitle-TileMap.bin"
TitleTileMapEnd:

;-------------------------------------------------------------------------------------
; Title Screen - Sprite Data
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     6 n, $$TitleTileMapEnd + 1    ; Slot 3 = $c000..$dFFF, "n" option to wrap (around slot 6) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include sprite data
        ORG     $c000
TitleSprites1:          ; Title-Main Screen (Text)
        INCBIN  "webster/assets/TitleSprites4bit1.spr",,64*128     ; Number of 4bit sprites * 128 bytes
TitleSprites2:          ; Title-Main+Instructions Screens (Game sprites)
        INCBIN  "webster/assets/TitleSprites4bit2.spr",,64*128     ; Number of 4bit sprites * 128 bytes
TitleSprites3:          ; Title-Instructions Screen (Tilemap sprites)
        INCBIN  "webster/assets/TitleSprites4bit3.spr",,64*128     ; Number of 4bit sprites * 128 bytes
TitleSpritesEnd:

;-------------------------------------------------------------------------------------
; Title Instructions - Text
        MMU     7 n, $$TitleSpritesEnd+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include instruction text 
        ORG     $E000
; - Text format = x, y, line width, "<Text>", 0 (1=carriage return)
; -- Line width includes hidden columns 0 + 1. Therefore max of 38 (2 x hidden + 36 visible)
TitleInstrText:
; --- Background ---
TitleInstrBackgroundTextXY:     db      $02, $02, 38
                                db      "BACKGROUND", 1, 1
                                db      "The world of the Spider-bots was", 1
                                db      "once a peaceful world. this was", 1
                                db      "until one day a new Botsoft security"
                                db      "patch was released.", 1, 1
                                db      "Being very security conscious, all ", 1
                                db      "bots installed the patch, but the", 1 
                                db      "upgrade failed corrupting the bots.", 1, 1
                                db      "Fortunately Webster and his friends", 1
                                db      "were offline. Upon boot-up webster", 1
                                db      "noticed this corruption and ignored", 1
                                db      "the patch.", 1, 1
                                db      "Unfortunately the only fix for the", 1
                                db      "corruption was destruction! The", 1
                                db      "problem now was how to rescue his", 1
                                db      "friends whilst avoiding the", 1
                                db      "homicidal infected bots!!", 1, 1, 1
                                db      "V1.0",0
; --- Purpose ---
TitleInstrPurposeSprites:       dw      $0104, $0000, TitleInstrFriendlyEnPatterns         ; BlockXY, AddXY, Pattern
                                db      1                                               ; Mirror
                                dw      $0204, $0000, TitleInstrPlayerPatterns                  ; BlockXY, AddXY, Pattern
                                db      1                                               ; Mirror
                                dw      $0304, $0800, TitleInstResPointEmptyPatterns         ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0205, $0008, TitleInstResPointFullPatterns          ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0207, $0008, TitleInstrFriendlyDisPatterns        ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0209, $0008, TitleInstFinPointFullPatterns          ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      0
TitleInstrPurposeTextXY:        db      $02, $02, 38
                                db      "PURPOSE", 1, 1
                                db      "Help Webster rescue the remaining", 1
                                db      "friendly bots by activating and", 1
                                db      "leading them to a rescue point.", 1, 1, 1, 1, 1
                                db      "     Please note, each rescue point", 1
                                db      "     can only be used once and will", 1
                                db      "     then be disabled.", 1, 1
                                db      "     Sounds easy, but enemies can", 1
                                db      "     disable the bots, requiring", 1
                                db      "     them to be re-activated.", 1, 1
                                db      "     Once all friendly bots have", 1
                                db      "     been rescued, find the level", 1
                                db      "     exit to complete the level.",0
; --- Level Status ---
TitleInstrLevelStatusCopperList:
        db      %1'0000000, 0           ; Wait - Column 0, line 0
        db      %0'1101100, %0101'0000  ; Move - Purple - Set tilemap palette offset ($6c) to 4
        db      %1'0000000, 16          ; Wait - Column 0, line 16
        db      %0'1101100, %0110'0000  ; Move - Blue - Set tilemap palette offset ($6c) to 5
        db      %1'0000000, 32          ; Wait - Column 0, line 32
        db      %0'1101100, %0111'0000  ; Move - Red - Set tilemap palette offset ($6c) to 5
        db      %1'0000000, 64          ; Wait - Column 0, line 64
        db      %0'1101100, %1000'0000  ; Move - Green - Set tilemap palette offset ($6c) to 5
        db      %1'0000000, 88          ; Wait - Column 0, line 88
        db      %0'1101100, %0101'0000  ; Move - Set tilemap palette offset ($6c) to 5
        db      %1'0000000, 239         ; Wait - Column 0, line 239
        db      %0'1101100, %1001'0000  ; Move - Cycle - Set tilemap palette offset ($6c) to 5
TitleInstrLevelStatusHeadingCycleCopperListEndScanLine:
        db      %1'0000001, %00000101   ; Wait - Column 0, line - Set in code depending on speed
        db      %0'1101100, %0101'0000  ; Move - Cycle - Set tilemap palette offset ($6c)
        db      $FF, $FF                ; HALT
TitleInstrLevelStatusCopperListSize = $-TitleInstrLevelStatusCopperList

TitleInstrLevelStatusTextXY:    db      $02, $02, 38
                                db      "LEVEL STATUS", 1, 1
                                db      "The colour of certain wall lights", 1
                                db      "indicate the level status:",1 ,1
                                db      "BLUE = Normal - Rescue Friendly bots", 1
                                db      "RED  = Door Lockdown - ALL doors are"
                                db      "       locked, all spawn points and", 1
                                db      "       enemies must be destroyed", 1, 1
                                db      "GREEN= Level Complete - Find the", 1
                                db      "       level exit", 1, 1
                                db      "When a level is completed the next", 1
                                db      "level will be unlocked. This new", 1
                                db      "level can then be selected when", 1
                                db      "starting a new game.", 0
; --- Abilities ---
TitleInstrAbilitiesSprites:     dw      $0209, $0008, TitleInstNoFreezeBlockPatterns    ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      0
TitleInstrAbilitiesTextXY:      db      $02, $02, 38
                                db      "ABILITIES", 1, 1
                                db      "Webster has both a weapon and the", 1
                                db      "ability to slow-down time; the", 1
                                db      "weapon is automatically upgraded", 1
                                db      "when rescuing friendly bots.", 1, 1
                                db      "The slow-down time ability allows", 1
                                db      "Webster to slow down hazards and", 1
                                db      "enemies whilst allowing Webster", 1
                                db      "and the friendly bots to travel at", 1
                                db      "normal speed.", 1, 1
                                db      "Please note, slow-down has limited", 1
                                db      "time, but you can top-up through", 1
                                db      "both lockers and pickups.", 1, 1
                                db      "     Note: You cannot activate", 1
                                db      "     slow-down when moving over", 1
                                db      "     this block, so be careful.", 0
; --- Lockers ---
TitleInstrLockersSprites:       dw      $0204, $0000, TitleInstLockerEnergy1Patterns     ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0b04, $0000, TitleInstLockerTimePatterns       ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0208, $0000, TitleInstPickupEnergyPatterns     ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0b08, $0000, TitleInstPickupTimePatterns       ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      0
TitleInstrLockersTextXY:        db      $02, $02, 38
                                db      "LOCKERS/PICKUPS", 1, 1
                                db      "LOCKERS can be collected to increase"
                                db      "energy or slow-down time. Shooting a"
                                db      "locker will toggle the locker type.", 1, 1, 1
                                db      "     Energy Locker     Time Locker", 1, 1
                                db      "PICKUPS are dropped when a certain", 1
                                db      "number of enemies have been", 1
                                db      "destroyed, and will disappear after", 1
                                db      "a short time.", 1, 1, 1
                                db      "     Energy Pickup     Time Pickup", 1, 1
                                db      "Collecting a pickup will grant a", 1
                                db      "smaller amount of energy or time.", 1
                                db      "Pressing the [Q] key will toggle", 1
                                db      "the pickup between energy and time.", 0
; --- Door Types ---
TitleInstrDoorTypesSprites:     dw      $0204, $0000, TitleInstrDoorsGrnHorPatterns   ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0304, $0000, TitleInstrDoorsGrnVerPatterns   ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0205, $0008, TitleInstrDoorsRedHorPatterns     ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0305, $0008, TitleInstrDoorsRedVerPatterns     ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0f05, $0008, TitleInstrDoorsKey1Patterns        ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0207, $0000, TitleInstrDoorsBlueHorPattens    ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0307, $0000, TitleInstrDoorsBlueVerPatterns    ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0209, $0000, TitleInstrTriggerFloorPatterns    ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      0
TitleInstrDoorTypesTextXY       db      $02, $02, 38
                                db      "DOOR TYPES", 1, 1
                                db      "Throughout the level Webster will", 1
                                db      "encounter a number of different door"
                                db      "types, including:", 1, 1, 1
                                db      "      Unlocked", 1, 1, 1
                                db      "      Locked - Opened using    keys", 1, 1
                                db      "      Trigger Locked - Opened by", 1
                                db      "      triggering an event", 1
                                db      "      e.g. Rescuing friendly bots", 1, 1
                                db      "      This floor pattern will", 1
                                db      "      sometimes point to the event", 1
                                db      "      required to open the door,", 1
                                db      "      otherwise explore", 0
; --- Save-Points ---
TitleInstrSavePointsSprites:    dw      $0208, $0000, TitleInstrSavePointsInPatterns     ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0b08, $0000, TitleInstrSavePointsAcPatterns     ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      0
TitleInstrSavepointsTextXY:     db      $02, $02, 38
                                db      "SAVE-POINTS", 1, 1
                                db      "Webster will return to an active", 1
                                db      "save-point when destroyed, restoring"
                                db      "both the energy & slow-down time", 1
                                db      "to the amount when the save-point", 1
                                db      "was activated.", 1, 1
                                db      "Activating a save-point can be", 1
                                db      "performed either by pressing", 1
                                db      "<Space> to CREATE a save-point, or", 1
                                db      "automatically by passing over an", 1
                                db      "inactive save-point.", 1, 1
                                db      "     InActive          Activated", 1
                                db      "     Save-Point        Save-Point", 1, 1
                                db      "Please note, a save-point credit is", 1
                                db      "required to CREATE a save-point;", 1
                                db      "credits are granted when rescuing a", 1
                                db      "number of friendly bots.", 0
; --- Hazards ---
TitleInstrHazardsSprites:       dw      $0101, $0008, TitleInstrHazardsDesPatterns      ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0103, $0000, TitleInstrHazardsHazPatterns      ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0104, $0008, TitleInstrHazardsHazSwPatterns    ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0106, $0000, TitleInstrHazardsHazRvPatterns    ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0108, $0000, TitleInstrHazardsSPUPatterns      ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $0109, $0008, TitleInstrHazardsSPLPatterns      ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      $010a, $0008, TitleInstrHazardsSPDeatterns      ; BlockXY, AddXY, Pattern
                                db      0                                               ; Mirror
                                dw      0
TitleInstrHazardsTextXY:        db      $02, $02, 38
                                db      "HAZARDS", 1, 1
                                db      "   Harmless - Shoot to destroy", 1, 1
                                db      "   Hazard - Dangerous, cannot be", 1
                                db      "   destroyed", 1, 1
                                db      "   Switch - Shoot or touch to", 1
                                db      "   reverse all hazards", 1, 1
                                db      "   Reversed-Hazard - Safe to Webster"
                                db      "   but dangerous to enemies", 1, 1
                                db      "SPAWN POINTS", 1, 1
                                db      "   Spawns enemies until destroyed", 1, 1
                                db      "   Spawns limited number of enemies", 1
                                db      "   and is destroyed automatically", 1, 1
                                db      "   Inactive or destroyed", 0
; --- Enemies ---
TitleInstrEnemiesSprites:       dw      $0101, $0008, TitleInstrEnemiesGrtPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0103, $0000, TitleInstrEnemiesGrtFPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0104, $0008, TitleInstrEnemiesShootPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0106, $0000, TitleInstrEnemiesTermPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0107, $0008, TitleInstrEnemiesWayPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0109, $0002, TitleInstrEnemiesWaySPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $010a, $0009, TitleInstrEnemiesTurrPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $010a, $0e08, TitleInstrEnemiesTurr2Patterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      0
TitleInstrEnemiesTextXY:        db      $02, $02, 38
                                db      "ENEMIES", 1, 1
                                db      "   Crawler - Awkward in numbers", 1, 1, 1           
                                db      "   Skippy - Fast and persistent", 1, 1, 1
                                db      "   Spitter - Deadly and persistent", 1, 1, 1
                                db      "   Vampire - Invulnerable???", 1, 1, 1
                                db      "   Weaver - Invulnerable", 1, 1, 1
                                db      "   Weaver Spitter - Invulnerable", 1, 1, 1
                                db      "    Spinner - Can only be stunned", 0
; --- Controls ---
TitleInstrControlsSprites:      dw      $0606, $0800, TitleInstKeyWPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0607, $0800, TitleInstKeySPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0507, $0800, TitleInstKeyAPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0707, $0800, TitleInstKeyDPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0406, $0800, TitleInstKeyQPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0806, $0800, TitleInstKeyRPatterns         ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0509, $0800, TitleInstKeySpace1Patterns        ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0609, $0800, TitleInstKeySpace2Patterns        ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0709, $0800, TitleInstKeySpace3Patterns        ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0c09, $0800, TitleInstMouseClickPatterns       ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      0
TitleInstrControlsTextXY:       db      $02, $02, 38
                                db      "CONTROLS", 1, 1
                                db      "Webster is controlled using both a", 1
                                db      "keyboard and a Kempston mouse.", 1, 1
                                db      "The keyboard is used to move, whilst"
                                db      "the mouse is used to move the weapon"
                                db      "reticule and fire/slow-down time.", 1, 1
                                db      "           Up", 1
                                db      " Toggle", 1
                                db      " Pickup          Pause", 1, 1
                                db      "     Left      Right", 1
                                db      "          Down", 1, 1
                                db      "                   Fire  Slow-Down", 1
                                db      "                         Time", 1
                                db      "        Activate", 1
                                db      "       Save-Point", 0
; --- Display ---
TitleInstrDisplaySprites:       dw      $0203, $0808, TitleInstrDoorsKey2Patterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0903, $0008, TitleInstrSavePointsInPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0b03, $0008, TitleInstrSavePointsAcPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $1003, $0808, TitleInstLockerEnergy2Patterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0605, $0808, TitleInstrSavePointsInPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0606, $0808, TitleInstrSavePointsAcPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0209, $0808, TitleInstrDisplayRetWhPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0809, $0808, TitleInstrDisplayRetYlPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      $0e09, $0808, TitleInstrDisplayRetRdPatterns             ; BlockXY, AddXY, Pattern
                                db      0                                       ; Mirror
                                dw      0
TitleInstrDisplayTextXY:        db      $02, $02, 38
                                db      "DISPLAY", 1, 1
                                db      "The display at the top of the screen"
                                db      "provides the following information:", 1, 1
                                db      "                  or", 1, 1
                                db      "  Keys        Save-Point     Energy", 1
                                db      "Collected  Status & Credits", 1, 1
                                db      "             =Save-Point not Active", 1, 1
                                db      "             =Save-Point Active", 1, 1
                                db      "MOUSE RETICULE", 1, 1
                                db      "Colour summarises the energy level:", 1, 1
                                db      "     High        Medium      Low", 1, 1
                                db      "Number is Remaining slow-down time.", 0

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Presents Message
; ***Layer 2 Screen Data ***
        MMU     6 n, $$TitleInstrDisplayTextXY+1    ; Slot 6 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $C000
Layer2Presents:          ; Presents Screen
        INCBIN  "webster/assets/l2/Presents.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2PresentsEnd:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Basic Layout
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2PresentsEnd+2    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; Note: First memory bank MUST be EVEN
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2Picture:          ; Title-Main Screen
        INCBIN  "webster/assets/l2/TitleEmpty.nxi",0,320*256

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2PictureEnd:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Top Rows
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2PictureEnd+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2Top1To3:          
        INCBIN  "webster/assets/l2/Top-1-3.nxi"
Layer2Top4To6:          
        INCBIN  "webster/assets/l2/Top-4-6.nxi"
Layer2Top7To8:          
        INCBIN  "webster/assets/l2/Top-7-8.nxi"
Layer2Top9To10:          
        INCBIN  "webster/assets/l2/Top-9-10.nxi"
; Note: Added 1 x byte to ensure Layer2TopLocked starts at $E001
;       This is to ensure the address check passs when comparing with
;       address from previous nxi file
        nop     
Layer2TopLocked:          
        INCBIN  "webster/assets/l2/Top-Locked.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2TopEnd:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Bottom
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2TopEnd+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2Bottom1To3:          
        INCBIN  "webster/assets/l2/Bottom-1-3.nxi"
Layer2Bottom4To6:          
        INCBIN  "webster/assets/l2/Bottom-4-6.nxi"
Layer2Bottom7To8:          
        INCBIN  "webster/assets/l2/Bottom-7-8.nxi"
Layer2Bottom9To10:          
        INCBIN  "webster/assets/l2/Bottom-9-10.nxi"
Layer2BottomLocked:          
        INCBIN  "webster/assets/l2/Bottom-Locked.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2BottomEnd:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Columns1
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2BottomEnd+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2LeftRight1To3:          
        INCBIN  "webster/assets/l2/LeftRight-1-3.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2Columns1End:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Columns2
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2Columns1End+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2Left4To6:          
        INCBIN  "webster/assets/l2/Left-4-6.nxi"
Layer2Right4To6:          
        INCBIN  "webster/assets/l2/Right-4-6.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2Columns2End:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Columns3
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2Columns2End+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2Left7To8:          
        INCBIN  "webster/assets/l2/Left-7-8.nxi"
Layer2Right7To8:          
        INCBIN  "webster/assets/l2/Right-7-8.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2Columns3End:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Columns4
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2Columns3End+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2Left9To10:          
        INCBIN  "webster/assets/l2/Left-9-10.nxi"
Layer2Right9To10:          
        INCBIN  "webster/assets/l2/Right-9-10.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)
Layer2Columns4End:

;-------------------------------------------------------------------------------------
; Layer 2 Pixel Data - Columns5
; ***Layer 2 Screen Data ***
        MMU     7 n, $$Layer2Columns4End+1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include image pixel data 
        ORG     $E000
Layer2LeftLocked:          
        INCBIN  "webster/assets/l2/Left-Locked.nxi"
Layer2RightLocked:          
        INCBIN  "webster/assets/l2/Right-Locked.nxi"

; Note: the assembler will automatically wrap around $E000 with the next 8k bank until the requested amount of bytes is included and all banks are populated 16kb 9, 10, 11 (8k banks: 18, 19, 20, 21, 22, 23)