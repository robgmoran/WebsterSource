FindMe1:        db      0       ; TODO - Remove
FindMe2:        db      0
FindMe3:        db      0
FindMe4:        db      0
FindMe5:        dw      0

;-------------------------------------------------------------------------------------
; Structures
; Structure for sprite attributes
        STRUCT S_SPRITE_ATTR
x               BYTE    0       ; X0:7
y               BYTE    0       ; Y0:7
mrx8            BYTE    0       ; PPPP Mx My Rt X8 (pal offset, mirrors, rotation, X8)
vpat            BYTE    0       ; V 0 NNNNNN (visible, 5B type=off, pattern number 0..63)
Attribute4      BYTE    0
        ENDS

; Structure for sprite type - *** TODO - Add/remove as necessary
        STRUCT S_SPRITE_TYPE
active          BYTE    0       ; Indicates whether sprite slot available (auto-populated)
SpriteNumber    BYTE    0       ; Sprite slot (auto-populated)
AttrOffset      WORD    0       ; Sprite attribute offset (auto-populated)
patternRange    WORD    0       ; Sprite animation pattern range (patternRef); Also start pattern pattern range
patternCurrent  BYTE    0       ; Current Pattern for sprite (auto set as first pattern within patternRef)
animationDelay  BYTE    0       ; Animation - Speed (Set within routine parameters)
animationStr    WORD    0       ; Animation - Horizontal pattern range
animationUp   WORD    0       ; Animation - Vertical pattern range
animationDown   WORD    0       ; Animation - Vertical pattern range
animationOther  WORD    0       ; Animation - Other e.g. Death or explosion
Counter         BYTE    0       ; Counter used for sprite changes
xPosition       WORD    0       ; X Position (update inline with sprite attr)
yPosition       BYTE    0       ; Y Position (update inline with sprite attr)
XWorldCoordinate  WORD    0     ; X Position within the world
YWorldCoordinate  WORD    0     ; Y Position within the world
Rotation        BYTE    0       ; Rotation value 0 - 255 (360 degrees)
RotationReset   BYTE    0       ; Rotation value 0 - 255 (360 degrees) - Used to reset turret
RotRadius       BYTE    0       ; Radius to rotation point
RotPointX       WORD    0       ; Rotation point x
RotPointY       WORD    0       ; Rotation point y
RotRange        BYTE    0       ; Rotation range for bullets (value applicable to x and y; max = 127 due to divisor issue)
SpriteType1     BYTE    0       ; Sprite type - Used for processing within code
                                ; %PEVBEDRK
                                ; P - Player, E - Enemy, V - Sprite Visible (non-player), B - Bullet
                                ; E - Sprite Exploding/disabled, D - Delete Sprite, R - Reticule, K - Key
SpriteType2     BYTE    0       ; Sprite type - Used for processing within code
                                ; %1STUDLRE
                                ; 1 - Key1, S - Enemy spawn animation playing, T - Turret, U - TurretUp, D - TurretDown, L - TurretLeft, R - TurretRight, E - Enemy Bullet Source
SpriteType3     BYTE    0       ; Sprite type - Used for processing within code
                                ; %FORBWITS
                                ; F - Friendly, O - Following, R - Rescued, B - Bullet Destroyed SpawnPoint, W - Waypoint enemy, I - Indestructable, T - Terminator, S - Shooter
SpriteType4     BYTE    0       ; Sprite type - Used for processing within code
                                ; %PTALDCEW
                                ; P - Player bullet hit disabled turret, T - Turret Rotating, A - Turret Anti-Clockwise, L - Locker, D - Not destroyed by player, C - Collectable, E - Energy Upgrade, W - Destroyed by waypoint enemy
SpriteType5     BYTE    0       ; Sprite type - Used for processing within code
                                ; %DIF2SMER
                                ; D - Don't move in next frame, I - Ignore sprite, F - Fleeing type enemy, 2 - Flee status, S - Spawn type enemy, M - Movement status, E - Scale explosion, R - Do not rotate/Flip sprites
Speed           BYTE    0       ; 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
Damage          BYTE    0       ; Damage caused by sprite
Energy          BYTE    0       ; Energy of sprite
Delay           BYTE    0       ; E.g. Delay between firing bullets; set within bullet sprite structure
DelayCounter    BYTE    0       ; Counter use for delay - Set in code
BulletType      WORD    0       ; Bullet type to be fired - Set in code
BulletSpriteSource BYTE    0    ; Number of sprite firing bullet - Set in code
DoorHorBlockOffset WORD    0       ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
DoorVerBlockOffset WORD    0       ; Door vertical offset for door just opened; used to close door afterwards - Set in code
Width           BYTE    0       ; Sprite width
Height          BYTE    0       ; Sprite height
BoundaryX       BYTE    0       ; Collision Boundary Box - x offset
BoundaryY       BYTE    0       ; Collision Boundary Box - y offset
BoundaryWidth   BYTE    0       ; Collision Boundary Box - Width
BoundaryHeight  BYTE    0       ; Collision Boundary Box - Height
MoveToTarget    BYTE    0       ; Enemy/Friendly - Enabled when travelling to player - Set in code
MoveToBlock     WORD    0       ; Enemy/Friendly - Block to be occupied - Set in code
MoveToBlockXY   WORD    0       ; Enemy/Friendly - Block offset X/Y to be occupied - Set in code
MoveTargetX     WORD    0       ; Enemy/Friendly - Target world X position - Set in code
MoveTargetY     WORD    0       ; Enemy/Friendly - Target world Y position - Set in code
Movement        BYTE    %00000000       ; Current movement - ---UDLR (UP, DOWN, LEFT, RIGHT)
Movement2       BYTE    %00000000       ; Previous movement - ---UDLR (UP, DOWN, LEFT, RIGHT)
Movement3       BYTE    %00000000       ; Saved movement - ---UDLR (UP, DOWN, LEFT, RIGHT)
SprCollision    BYTE    0       ; Sprite collision - Set in code
SprContactSide  BYTE    0       ; Side of sprite hit by target sprite %----UDLR - Set in code
MovementDelay   BYTE    0       ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
EnemyWayPoint   WORD    0       ; Used to hold target waypoint for waypoint enemies - Set in code
EnemySpawnPoint       WORD    0 ; Used to link enemy to spawn point (i.e. Manage re-spawning)
                                ; Also used on waypoint enemies to hold previous EnemyWayPoint 
EnergyReset        BYTE    0       ; Used to reset energy for indestructable enemies, also used for locker freeze upgrade value
EnemyDisableTimeOut     BYTE    0       ; Pause before re-enabling indestructable enemies or time for enemy to flee
InvulnerableCounter     BYTE    0       ; Used as enemy invulnerability counter
Range           WORD    0       ; Used for spawned enemies to check within player range - Set in code 
        ENDS

; Structure for sprite patterns
        STRUCT S_SPRITE_PATTERN
AnimDelay       BYTE    0       ; Value
FirstPattern    BYTE    0       ; Pattern Number (0 - 127)
LastPattern     BYTE    0       ; Pattern Number (0 - 127)
BitPatOffset    BYTE    0       ; B---PPPP - B=1 (4bit), B=0 (8bit), PPPP = 4bit Palette Offset (0-16)
        ENDS

; Structure for door types
        STRUCT S_DOOR_TYPE
TileStartValue          BYTE    0       ; Tile start value for door 
TileEndValue            BYTE    0       ; Tile end value for door 
DoorType                BYTE    0       ; %H'OPCV'L21 - Set in code
                                        ; H - 1 = Horizontal, 0 = Vertical
                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
TilePattern             WORD    0       ; Tile animation pattern
        ENDS

; Structure for door attributes
        STRUCT S_DOOR_DATA
TileBlockOffset         WORD    0       ; Tile block Offset within block tilemap - Set in code 
TileBlockOffsetX        BYTE    0       ; Block Tile Offset x - Set in code
TileBlockOffsetY        BYTE    0       ; Block Tile Offset y - Set in code
DoorType                BYTE    0       ; %H'OPCV'L21 - Set in code
                                        ; H - 1 = Horizontal, 0 = Vertical
                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
TileBlockStartValue     BYTE    0       ; Tile block value for first tile block in tile pattern - Set in code
TileBlockEndValue       BYTE    0       ; Tile block value for end tile block in tile pattern - Set in code
TilePattern             WORD    0       ; Tile pattern for animation
TileBlockCounter        BYTE    0       ; Tile block counter used for animation - Set in code
        ENDS

; Structures for TriggerSource attributes
        STRUCT S_TRIGGERSOURCEASM_DATA  ; ASM Source format
xWorld                  WORD    0       ; X world position of TriggerSource
yWorld                  WORD    0       ; Y world position of TriggerSource
TriggerTargetID         WORD    0       ; Key used to search TriggerTargetData for TriggerTargetID - Set in code
DoorLockdown            BYTE    0       ; Used to configure doorlockdown - Set in code
        ENDS

        STRUCT S_TRIGGERSOURCE_DATA     ; Working data format
TileBlockOffset         WORD    0       ; Key used by TriggerSource to search TriggerSourceData - Set in code 
TriggerTargetIDAddress  WORD    0       ; Memory location for TriggerTargetID - Set in code
DoorLockdown            BYTE    0       ; Used to configure doorlockdown - Set in code
        ENDS

; Structures for TriggerTarget attributes
        STRUCT S_TRIGGERTARGETASM_DATA ; ASM Source format
xWorld                  WORD    0       ; X world position of TriggerTarget
yWorld                  WORD    0       ; Y world position of TriggerTarget
TriggerTargetID         WORD    0       ; Key Used by TriggerSource to search TriggerTargetData - Set in code
TriggerSourceNumber	BYTE	0	; Number of TriggerSource events required to trigger target action - Set in code
        ENDS

        STRUCT S_TRIGGERTARGET_DATA     ; Working data format
TileBlockOffset         WORD    0       ; Key used by TriggerTarget to search TriggerTargetData - Set in code  
TriggerTargetID         WORD    0       ; Reference key - Set in code
TriggerSourceNumber	BYTE	0	; Number of TriggerSource events required to trigger target action - Set in code
        ENDS

; Structure for block animation
        STRUCT S_BLOCK_ANIMATION
Delay                   BYTE    0       ; Delay between animating blocks
DelayCounter            BYTE    0       ; Working counter for delay - Set in code 
StartBlock              BYTE    0       ; Start block in animation
EndBlock                BYTE    0       ; End block in animation
        ENDS

; Structure for populating bullet sprite
        STRUCT S_BULLET_DATA
bulletSprite 	WORD	; Link to S_SPRITE_TYPE object to be updated
patternStr      WORD	; Populates patternRange for straight sprites
patternDiag      WORD	; Populates patternRange for diagonal sprites
animationExp    WORD    ; Populates animationExp
audioRef        BYTE    ; Populates AYFX sound to play
range		BYTE	; Populates rotRange - Max 127
speed		BYTE	; Populates Speed
movementDelay   BYTE    ; Populates delay counter for movement
Damage		BYTE	; Populates Damage
Delay		BYTE	; Populates Delay - Delay between firing bullets
Width		BYTE	; Populates Width
Height		BYTE	; Populates Height
BoundaryX	BYTE	; Populates BoundaryX
BoundaryY	BYTE	; Populates BoundaryY
BoundaryWidth	BYTE	; Populates BoundaryWidth
BoundaryHeight	BYTE	; Populates BoundaryHeight
        ENDS

/*
; Structure for spawn point types
        STRUCT S_SPAWNPOINT_TYPE
TileValue               BYTE    0       ; Objects tilemap tile value for spawn point
EnemyType		WORD    0       ; Spawned enemy type reference
MaxEnemies		BYTE	0	; Maximum number of enemies that can be spawned
SpawnDelay		BYTE	0	; Delay between spawning enemies
Reuse                   BYTE    0       ; 0 = Only spawn MaxEnemies once, 1 = Continuous spawn
        ENDS
*/

; Structure for spawn point data
        STRUCT S_SPAWNPOINTASM_DATA     ; ASM Source format
Active                  BYTE    0       ; Indicates whether spawn point is active
WorldX                  WORD    0       ; World X Coordinate
WorldY                  WORD    0       ; World Y Coordinate
TileBlockOffset         WORD    0       ; Tile block Offset within block tilemap - Set in code 
TileBlockOffsetY        BYTE    0       ; Block Tile Offset y - Set in code
TileBlockOffsetX        BYTE    0       ; Block Tile Offset x - Set in code
EnemyType		WORD    0       ; Spawned enemy type reference
BulletType              WORD    0       ; Bullet to be assigned to spawned shooter
EnemyPlayerRange        WORD    0       ; Player-to-spawnedEnemy range --- If out of range, destroy spawned enemy
PlayerRange             WORD    0       ; Player-to-spawnpoint range --- If in range try and spawn enemy
MaxEnemies		BYTE	0	; Maximum number of enemies that can be spawned
MaxEnemiesHard		BYTE	0	; Maximum number of enemies that can be spawned
MaxEnemiesCounter	BYTE	0	; Number of enemies spawned counter
SpawnDelay		BYTE	0	; Delay between spawning enemies
SpawnDelayHard		BYTE	0	; Delay between spawning enemies
SpawnDelayCounter	BYTE	0	; Spawn delay counter
EnemyEnergy             BYTE    0       ; Energy for spawned enemies
EnemyEnergyHard         BYTE    0       ; Energy for spawned enemies
EnemyDamage             BYTE    0       ; Damage inflicted by enemies
EnemyDamageHard         BYTE    0       ; Damage inflicted by enemies
EnemyDisableTimeout     BYTE    0       ; Pause before re-enabling indestructable enemies 
EnemyDisableTimeoutHard BYTE    0       ; Pause before re-enabling indestructable enemies 
Energy                  WORD    0       ; Energy for spawnpoint
EnergyHard              WORD    0       ; Energy for spawnpoint
Reuse                   BYTE    0       ; 0 = Only spawn MaxEnemies once, 1 = Continuous spawn
DisableAtStart          BYTE    0       ; Whether spawnpoint should be disabled at start - Should be used when spawnpoint is a TriggerTarget
RecordSpawned           BYTE    0       ; Whether spawned enemy numbers are recorded - Should be enabled when configuring door lockdown
Flee                    BYTE    0       ; Whether enemy should flee when hit
Spawn                   BYTE    0       ; Whether enemy should spawn in different directions
        ENDS

        STRUCT S_SPAWNPOINT_DATA        ; Working data format
Active                  BYTE    0       ; Indicates whether spawn point is active
WorldX                  WORD    0       ; World X Coordinate
WorldY                  WORD    0       ; World Y Coordinate
TileBlockOffset         WORD    0       ; Tile block Offset within block tilemap - Set in code 
TileBlockOffsetY        BYTE    0       ; Block Tile Offset y - Set in code
TileBlockOffsetX        BYTE    0       ; Block Tile Offset x - Set in code
EnemyType		WORD    0       ; Spawned enemy type reference
BulletType              WORD    0       ; Bullet to be assigned to spawned shooter
EnemyPlayerRange        WORD    0       ; Player-to-spawnedEnemy range --- If out of range, destroy spawned enemy
PlayerRange             WORD    0       ; Player-to-spawnpoint range --- If in range try and spawn enemy
MaxEnemies		BYTE	0	; Maximum number of enemies that can be spawned
MaxEnemiesCounter	BYTE	0	; Number of enemies spawned counter
SpawnDelay		BYTE	0	; Delay between spawning enemies
SpawnDelayCounter	BYTE	0	; Spawn delay counter
EnemyEnergy             BYTE    0       ; Energy for spawned enemies
EnemyDamage             BYTE    0       ; Damage inflicted by enemies
EnemyDisableTimeout     BYTE    0       ; Pause before re-enabling indestructable enemies 
Energy                  WORD    0       ; Energy for spawnpoint
Reuse                   BYTE    0       ; 0 = Only spawn MaxEnemies once, 1 = Continuous spawn
DisableAtStart          BYTE    0       ; Whether spawnpoint should be disabled at start - Should be used when spawnpoint is a TriggerTarget
RecordSpawned           BYTE    0       ; Whether spawned enemy numbers are recorded - Should be enabled when configuring door lockdown
Flee                    BYTE    0       ; Whether enemy should flee when hit
Spawn                   BYTE    0       ; Whether enemy should spawn in different directions
        ENDS

; Structure for waypoint data
        STRUCT S_WAYPOINT_DATA
SpawnEnemy              BYTE    0       ; Indicates enemy can be spawned at waypoint
EnemyType               WORD    0       ; Spawned enemy type reference
BulletType              WORD    0       ; Bullet to be assigned to spawned shooter
RotRange                BYTE    0       ; Range of waypoint; overrides assigned bullet range
EnemyDamage             BYTE    0       ; Damage performed by enemy
XWorldCoordinate        WORD    0       ; X Position within the world
YWorldCoordinate        WORD    0       ; Y Position within the world
CurrentWayPoint         WORD    0       ; Current waypoint
NextWayPoint            WORD    0       ; Next waypoint after reaching this waypoint
        ENDS

; Structure for friendly data
        STRUCT S_FRIENDLY_DATA
FriendlyType            WORD    0       ; Spawned friendly type reference
Energy                  BYTE    0       ; Spawned friendly energy
EnableAtStart           BYTE    0       ; 0 = Disabled (Normal) , 1 = Enabled 
XWorldCoordinate        WORD    0       ; X Position within the world
YWorldCoordinate        WORD    0       ; Y Position within the world
        ENDS

; Structure for key data
        STRUCT S_KEY_DATA
KeyType                 WORD    0       ; Spawned key type reference
XWorldCoordinate        WORD    0       ; X Position within the world
YWorldCoordinate        WORD    0       ; Y Position within the world
        ENDS

; Structure for turret data
        STRUCT S_TURRET_DATA         
TurretType              BYTE    0       ; Spawned turret type - ----UDLR
BulletType              WORD    0       ; Bullet type for turret
RotationReset           BYTE    0       ; Initial/Reset Rotation value
AntiClockwise           BYTE    0       ; Rotate anti-clockwise for non-directional turret
RotRange                BYTE    0       ; Range of turret; overrides assigned bullet range
Energy                  BYTE    0       ; Energy for turret                  
EnergyHard              BYTE    0       ; Energy for turret                  
DisableTimeOut          BYTE    0       ; Disable Timeout
DisableTimeOutHard      BYTE    0       ; Disable Timeout
DoubleSpeed             BYTE    0       ; 0 = Normal Rotation Speed, 2 = Double Rotation Speed
XWorldCoordinate        WORD    0       ; X Position within the world
YWorldCoordinate        WORD    0       ; Y Position within the world
        ENDS

; Structure for hazard data
        STRUCT S_HAZARD_DATA
DelayAnim               BYTE    0       ; Delay between animating blocks
DelayPause              BYTE	0	; Pause at end of forward or reverse animation	
DelayCounter            BYTE    0       ; Working counter for delay - Set in code 
BlockStart              BYTE    0       ; Start block in animation
BlockEnd                BYTE    0       ; End block in animation
CurrentBlock	        BYTE	0	; Current visible block
GroundBlock		BYTE	0	; Block displayed at end of reverse animation i.e. Safe block
ReverseAnim	        BYTE    0       ; Working counter for animation direction - Set in code
showGround	        BYTE    0       ; Show ground as last block at end of animation
XWorldCoordinate        WORD    0       ; X Position within the world
YWorldCoordinate        WORD    0       ; Y Position within the world
TileBlockOffset         WORD    0       ; Tile block Offset within block tilemap - Set in code 
TileBlockOffsetY        BYTE    0       ; Block Tile Offset y - Set in code
TileBlockOffsetX        BYTE    0       ; Block Tile Offset x - Set in code
        ENDS


; Structure for player data
        STRUCT S_PLAYER_DATA
PlayerWorldX                    WORD    0       ; Player starting World X Coordinate
PlayerWorldY                    WORD    0       ; Player starting World Y Coordinate
PlayerBulletNumber              BYTE    0       ; Player starting bullet number to be assigned to player
PlayerBulletUpgrade1            BYTE    0       ; Friendly to rescue for player bullet upgrade
PlayerBulletUpgrade2            BYTE    0       ; Friendly to rescue for player bullet upgrade
PlayerBulletUpgrade3            BYTE    0       ; Friendly to rescue for player bullet upgrade
CollectableSpawnFreq            BYTE    0       ; Number of enemies to destroy before spawning collectable
CollectableSpawnFreqHard        BYTE    0       ; Number of enemies to destroy before spawning collectable
PlayerEnergy                    BYTE    0       ; Player starting energy
PlayerFreeze                    BYTE    0       ; Player starting freeze time 
FriendlyPerSavePointCredit      BYTE    0       ; Number of friendly to be rescued for a Save point credit
FriendlyPerSavePointCreditHard  BYTE    0       ; Number of friendly to be rescued for a Save point credit
hazardDamage                    BYTE    0       ; Damage inflicted by hazard
hazardDamageHard                BYTE    0       ; Damage inflicted by hazard on Hard difficulty
reverseHazardDamage             BYTE    0       ; Damage inflicted to enemy via reverse-hazard
reverseHazardDamageHard         BYTE    0       ; Damage inflicted to enemy via reverse-hazard on Hard difficulty
        ENDS

; Structure for locker data
        STRUCT S_LOCKER_DATA
DefaultFreeze           BYTE    0       ; Indicates whether locker starts as a freeze locker (0=false, 1=true)
EnergyUpgrade           BYTE    0       ; Energy Upgrade for player                  
FreezeUpgrade           BYTE    0       ; Bomb upgrade for player
XWorldCoordinate        WORD    0       ; X Position within the world
YWorldCoordinate        WORD    0       ; Y Position within the world
        ENDS

; Structure for Player Bullet Upgrade data
        STRUCT S_BULLETUPGRADE_DATA
FriendlyRequired        BYTE    0       ; Number of friendly to rescue
BulletUpgrade           WORD    0       ; Bullet upgrade
        ENDS

; Structure for level reference
        STRUCT S_LEVEL_REFERENCE
TileMapMemBank          BYTE    0       ; Memory bank hosting level data
LevelDataReference      WORD    0       ; Link to level data references
        ENDS

; Structure for level data
        STRUCT S_LEVEL_DATA
TileMapDefMemBank       BYTE    0       ; Memory bank hosting tilemap definition data
TileMapDefPalAddress    WORD    0       ; Tilemap palette location
TileMapPalOffset        BYTE    0       ; Tilemap palette offset - Main palette                
TileMapPalOffset2       BYTE    1       ; Tilemap palette offset - Alternate palette
TileMapPalOffset3       BYTE    1       ; Tilemap palette offset - Level Complete
TileMapData             WORD    0       ; TileMap data location
PlayerData              WORD    0       ; Player data location
WayPoints               BYTE    0       ; Number of waypoints
WayPointData            WORD    0       ; Waypoint data location
SpawnPoints             BYTE    0       ; Number of spawnpoints
SpawnPointData          WORD    0       ; Spawnpoint data location
Friendlys               BYTE    0       ; Number of friendlys
FriendlyData            WORD    0       ; Friendly data location
Keys                    BYTE    0       ; Number of keys
KeyData                 WORD    0       ; Key data location
Turrets                 BYTE    0       ; Number of turrets
TurretData              WORD    0       ; Turret data location
Hazards                 BYTE    0       ; Number of hazards
HazardData              WORD    0       ; Hazard data location
Lockers                 BYTE    0       ; Number of lockers
LockerData              WORD    0       ; Locker data location
TriggerSource           BYTE    0       ; Number of triggersource
TriggerSourceData       WORD    0       ; TriggerSource data location
TriggerTarget           BYTE    0       ; Number of triggertarget
TriggerTargetData       WORD    0       ; TriggerTarget data location
L2Data                  WORD    0       ; L2 Background data
L2PaletteData           WORD    0       ; L2 Palette data
        ENDS

; Structure for level reference
        STRUCT S_TITLE_TILEMAPSCROLL
XUpdate         BYTE    0       ; X scroll update
YUpdate         BYTE    0       ; Y scroll update
Duration        BYTE    0       ; Update duration
        ENDS

;-------------------------------------------------------------------------------------
; GameStatus Variables
GameStatus:                     db      0               ; Indicates Game Status - Set in code
                                                        ; %FCSNGPOX
                                                        ; F - Finish Enabled, C - Level Complete, S - Play player start/end/dead animation, N - Start Next Level
                                                        ; G - Game Over, P - Game Paused, O - Open Screen, X - Close Screen
GameStatus2:                    db      0               ; Indicates Game Status - Set in code
                                                        ; %PDSHAKIR
                                                        ; P - Player Spawn Sound Played, D - Save point (disappear), S - Save point (scroll), H - Hard Difficulty, A - Anti-Freeze block hit
                                                        ; K - Disable pause function, I - Display title screen, R - Replay level
GameStatus3:                    db      0               ; Indicates Game Status - Set in code
                                                        ; %HLSAFNU-
                                                        ; H - Update HiScore, L - Current level locked, S - Spawn Text Scroll Sprite, A - Spawn animated Text Sprite
                                                        ; F - Game just loaded, N - Play NextDAW, U - Bullet Upgrade

;-------------------------------------------------------------------------------------
; Various
BackupByte:     db      0       ; Used as spare storage
BackupByte2:    db      0       ; Used as spare storage
BackupByte3:    db      0       ; Used as spare storage
BackupByte4:    db      0       ; Used as spare storage
BackupByte5:    db      0       ; Used as spare storage
BackupByte6:    db      0       ; Used as spare storage
BackupByte7:    db      0       ; Used as spare storage
BackupWord1:    dw      0       ; Used as spare storage
BackupWord2:    dw      0       ; Used as spare storage
BackupWord3:    dw      0       ; Used as spare storage

;-------------------------------------------------------------------------------------
; Sprite Types Table
; - Used to populate instantiated sprite settings - TODO - Update as necessary
PlayerSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                FriendlyPatternsRes,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                PlayerPatternsStr,      ; Animation - Straight pattern range
                PlayerPatternsUp;PlayerPatternsStr,      ; Animation - Up pattern range
                PlayerPatternsDown;PlayerPatternsStr,      ; Animation - Down pattern range
                PlayerPatternsStr,      ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue) <-- Populated via S_BULLET_DATA data
                %10000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                0,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite
                0,      ; Energy of sprite - Set in code
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired - Set in code
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range
ReticuleSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                RetNormalPatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                RetNormalPatterns,      ; Animation - Straight pattern range
                RetNormalPatterns,      ; Animation - Up pattern range
                RetNormalPatterns,      ; Animation - Down pattern range
                RetNormalPatterns,      ; Animation - Strafe Enabled
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255 - Set elsewhere for reticule
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point - Set elsewhere for reticule
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %00100010,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000001,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                0,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite
                0,      ; Energy of sprite
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                6,      ; Collision Boundary Box - x offset 
                6,      ; Collision Boundary Box - y offset
                4,      ; Collision Boundary Box - Width
                4,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000001,;Current Movement
                %00000001,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

FriendlySprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                FriendlyPatternsDisabled,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                FriendlyPatternsStr,      ; Animation - Straight pattern range
                FriendlyPatternsUp,     ; Animation - Up pattern range
                FriendlyPatternsDown,     ; Animation - Down pattern range
                BulletPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %00000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %10000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                1,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite
                0,      ; Energy of sprite - Set via Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                100,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

; Bullet template populated with S_BULLET_DATA values during spawning
BulletSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                0,      ; Sprite animation pattern range (patternRef) <-- Populated via S_BULLET_DATA data
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                0,      ; Animation - Straight pattern range
                0,      ; Animation - Diagonal pattern range
                0,      ; Animation - Not Used
                0,      ; Animation - Death/Explosion range <-- Populated via S_BULLET_DATA data
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for bullet (value applicable to x and y; max = 127 due to divisor issue) <-- Populated via S_BULLET_DATA data
                %00010000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                0,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Populated via S_BULLET_DATA data
                0,      ; Energy of sprite - Set in code
                0,      ; Delay e.g. Delay between firing bullets <-- Populated via S_BULLET_DATA data
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired - Set in code
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                0,      ; Sprite width - Populated via S_BULLET_DATA data
                0,      ; Sprite height - Populated via S_BULLET_DATA data
                0,      ; Collision Boundary Box - x offset <-- Populated via S_BULLET_DATA data
                0,      ; Collision Boundary Box - y offset <-- Populated via S_BULLET_DATA data
                0,      ; Collision Boundary Box - Width <-- Populated via S_BULLET_DATA data
                0,      ; Collision Boundary Box - Height <-- Populated via S_BULLET_DATA data
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

LockerSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                LockerEnergyPatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                0,      ; Animation - Straight pattern range
                0,      ; Animation - Not used
                0,      ; Animation - Not used
                0,      ; Animation - Not used
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %00000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00010010,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000001,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                0,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite
                0,      ; Energy of sprite - Used for EnergyUpgrade - Set in Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

LockerCollectableSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                LockerEnergyPatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                LockerEnergyPatterns,      ; Animation - Straight pattern range
                0,      ; Animation - Not used
                0,      ; Animation - Not used
                0,      ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %00000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00010100,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000001,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                0,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite
                0,      ; Energy of sprite - Used for EnergyUpgrade - Set in Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

EnemySprFollowNormalType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                FriendlyPatternsRes,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                EnemyFollowerPatternsStr,      ; Animation - Straight pattern range
                EnemyFollowerPatternsUp,      ; Animation - Up pattern range
                EnemyFollowerPatternsDown,      ; Animation - Down pattern range
                EnemyPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                1,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Set via Tiled
                0,      ; Energy of sprite - Set via Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                3;5,     ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies - Set via Tiled
                0,      ; Pause before re-enabling indestructable enemies  - Set via Tiled
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range - Set in Tiled

EnemySprFollowFastType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                FriendlyPatternsRes,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                EnemyFastPatternsStr,      ; Animation - Straight pattern range
                EnemyFastPatternsUp,      ; Animation - Up pattern range
                EnemyFastPatternsDown,      ; Animation - Down pattern range
                EnemyPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                2,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Set via Tiled
                0,      ; Energy of sprite - Set via Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                1,     ; Used to delay enemy 0 = Don't move; higher value quicker
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies - Set via Tiled
                0,      ; Pause before re-enabling indestructable enemies - Set via Tiled
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range - Set in Tiled
EnemySprTerminatorType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                FriendlyPatternsRes,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                EnemyTermPatternsStr,      ; Animation - Straight pattern range
                EnemyTermPatternsUp,      ; Animation - Up pattern range
                EnemyTermPatternsDown,      ; Animation - Down pattern range
                EnemyPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000010,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000010,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                1,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Set via Tiled
                0,      ; Energy of sprite - Set via Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                20;10;100,     ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies - Set via Tiled
                0,      ; Pause before re-enabling indestructable enemies - Set via Tiled
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

EnemyWayPointNormalSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                EnemyWayPatternsStr,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                EnemyWayPatternsStr,      ; Animation - Straight pattern range
                EnemyWayPatternsUp,      ; Animation - Up pattern range
                EnemyWayPatternsDown,      ; Animation - Down pattern range
                BulletPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00001100,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                1,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Set via Tiled
                0,      ; Energy of sprite - Not applicable
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired - Set via Tiled
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                10,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range
EnemyWayPointFastSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                EnemyWayPatternsStr,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                EnemyWayPatternsStr,      ; Animation - Straight pattern range
                EnemyWayPatternsUp,      ; Animation - Up pattern range
                EnemyWayPatternsDown,      ; Animation - Down pattern range
                BulletPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00001100,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                2,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Set via Tiled
                0,      ; Energy of sprite - Not applicable
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired - Set via Tiled
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                10      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

EnemyWayPointShooterSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                EnemyWayShooterPatternsStr,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                EnemyWayShooterPatternsStr,      ; Animation - Straight pattern range
                EnemyWayShooterPatternsUp,      ; Animation - Up pattern range
                EnemyWayShooterPatternsDown,      ; Animation - Down pattern range
                BulletPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00001101,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                1,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Set via Tiled
                0,      ; Energy of sprite - Not applicable
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired - Set via Tiled
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                10,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies - Set via Tiled
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range

EnemySprShooterType   S_SPRITE_TYPE {      
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                FriendlyPatternsRes,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                EnemyShooterPatternsStr,      ; Animation - Straight pattern range
                EnemyShooterPatternsStr,      ; Animation - Up pattern range
                EnemyShooterPatternsStr,      ; Animation - Down pattern range
                EnemyPatternsExp, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for current bullet (value applicable to x and y; max = 127 due to divisor issue)
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000001,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000001,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                2,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite - Set via Tiled
                0,      ; Energy of sprite - Set via Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired - Set via Tiled
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                3,      ; Collision Boundary Box - x offset 
                3,      ; Collision Boundary Box - y offset
                10,      ; Collision Boundary Box - Width
                10,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                10,     ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range - Set in Tiled

TurretSprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                TurretEnablePatterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                TurretEnablePatterns,      ; Animation - Straight pattern range
                TurretEnablePatterns,      ; Animation - Up pattern range
                TurretEnablePatterns,      ; Animation - Down pattern range
                TurretDisablePatterns, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                16,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for turret (value applicable to x and y; max = 127 due to divisor issue) <-- Populated via S_BULLET_DATA data
                %01000000,      ; Sprite type - Used for processing within code e.g. Movement
                %00100000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                0,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets - Set in code
                0,      ; Damage caused by sprite - Set via BulletType
                0,      ; Energy of sprite - Set via Tiled
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired - Set via Tiled
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                2,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                12,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000101,;Current Movement
                %00000101,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,     ; Used to reset energy for indestructable enemies - Set via Tiled
                0,    ; Pause before re-enabling indestructable enemies - Set via Tiled
                0,      ; Used as enemy invulnerability counter
                0}      ; Used for spawned enemies to check within player range
Key1SprType   S_SPRITE_TYPE {
                0,      ; Indicates whether sprite slot available (auto-populated)
                0,      ; Sprite slot (auto-populated)
                0,      ; Sprite attribute offset (auto-populated)
                Key1Patterns,      ; Sprite animation pattern range (patternRef)
                0,      ; Current Pattern for sprite (auto set as first pattern within patternRef)
                0,      ; Animation delay (Set within routine parameters)
                Key1Patterns,      ; Animation - Straight pattern range
                Key1Patterns,      ; Animation - Not used
                Key1Patterns,      ; Animation - Not used
                Key1Patterns, ; Animation - Death/Explosion range
                0,      ; Timer used for sprite changes e.g. Delay before dropping rock
                0,      ; X Position (Set within routine parameters)
                0,      ; Y Position (Set within routine parameters)
                0,      ; X World Position (Set within routine parameters)
                0,      ; Y World Position (Set within routine parameters)
                0,      ; Rotation 0 - 255
                0,      ; Rotation Reset value 0 - 255 (360 degrees) - Used to reset turret
                0,      ; Radius to rotation point
                0,      ; Rotation point x
                0,      ; Rotation point y
                0,      ; Rotation range for turret (value applicable to x and y; max = 127 due to divisor issue)
                %00000001,      ; Sprite type - Used for processing within code e.g. Movement
                %10000000,      ; Sprite type2 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type3 - Used for processing within code e.g. Movement
                %00000000,      ; Sprite type4 - Used for processing within code e.g. Movement
                %00000001,      ; Sprite type5 - Used for processing within code e.g. Movement - Set in Tiled/Code
                0,      ; Speed: 1 = normal speed, 2 = double-speed, 3+ Only applicable to bullets
                0,      ; Damage caused by sprite
                0,      ; Energy of sprite
                0,      ; Delay e.g. Delay between firing bullets
                0,      ; Delay Counter - Set in code
                0,      ; Bullet type to be fired
                0,      ; Number of sprite firing bullet - Set in code
                0,      ; Door horizontal offset for door just opened; used to close door afterwards - Set in code
                0,      ; Door vertical offset for door just opened; used to close door afterwards - Set in code
                16,     ; Sprite width
                16,     ; Sprite height
                4,      ; Collision Boundary Box - x offset 
                2,      ; Collision Boundary Box - y offset
                8,      ; Collision Boundary Box - Width
                12,      ; Collision Boundary Box - Height
                0       ; Enemy - Enabled when enemy travelling to player - Set in code
                0       ; Enemy - Block to be occupied by enemy - Set in code
                0       ; Enemy - Block offset X/Y to be occupied by enemy - Set in code
                0       ; Enemy - Target world X position - Set in code
                0       ; Enemy - Target world Y position - Set in code
                %00000000,;Current Movement
                %00000000,;Previous Movement
                %00000000,;Saved Movement
                0,      ; Location of target sprite in collision - Set in code
                0,      ; Side of sprite hit by target sprite - Set in code
                0,      ; Used to delay enemy 0 = Don't move; higher value quicker - Set in code
                0,      ; Used to hold target waypoint for waypoint enemies - Set in code
                0,      ; Used to link enemy to enemy type - Set in code
                0,      ; Used to reset energy for indestructable enemies
                0,      ; Pause before re-enabling indestructable enemies 
                0}      ; Used for spawned enemies to check within player range

; Sprite Animation Pattern Ranges
; -- 4Bit Patterns
PlayerPatternsStr:              db      4, 1, 2, %1'000'0000         ; Animation delay, First pattern, Last pattern
PlayerPatternsUp:               db      4, 66, 67, %1'000'0000         ; Animation delay, First pattern, Last pattern
PlayerPatternsDown:             db      4, 4, 5, %1'000'0000         ; Animation delay, First pattern, Last pattern
PlayerUpgradePatternsStr:       db      10, 111, 112, %1'000'1000       ; Animation delay, First pattern, Last pattern
; Reticule
; Same pattern used for normal/mid/low energy - Only difference is palette offset
RetNormalPatterns:              db      0, 0, 0, %1'000'0000       
RetMidEnergyPatterns:           db      0, 0, 0, %1'000'0001       
RetLowEnergyPatterns:           db      0, 0, 0, %1'000'0010       
;
FriendlyPatternsStr:            db      4, 1, 2, %1'000'0001         ; Animation delay, First pattern, Last pattern
FriendlyPatternsUp:             db      4, 66, 67, %1'000'0001         ; Animation delay, First pattern, Last pattern
FriendlyPatternsDown:           db      4, 4, 5, %1'000'0001         ; Animation delay, First pattern, Last pattern
FriendlyPatternsDisabled:       db      4, 69, 69, %1'000'0001       ; Animation delay, First pattern, Last pattern
FriendlyPatternsRes:            db      8, 6, 71, %1'000'0001       ; Animation delay, First pattern, Last pattern
;
EnemyFollowerPatternsStr:       db      4, 8, 9, %1'000'0010;12, 15, %1'000'0010         ; Animation delay, First pattern, Last pattern
EnemyFollowerPatternsUp:        db      4, 73, 74, %1'000'0010;12, 15, %1'000'0010         ; Animation delay, First pattern, Last pattern
EnemyFollowerPatternsDown:      db      4, 11, 12, %1'000'0010;12, 15, %1'000'0010         ; Animation delay, First pattern, Last pattern
;
EnemyFastPatternsStr:           db      2, 76, 77, %1'000'0011         ; Animation delay, First pattern, Last pattern
EnemyFastPatternsUp:            db      2, 14, 15, %1'000'0011         ; Animation delay, First pattern, Last pattern
EnemyFastPatternsDown:          db      2, 79, 80, %1'000'0011         ; Animation delay, First pattern, Last pattern
;
EnemyShooterPatternsStr:        db      4, 17, 83, %1'000'0100         ; Animation delay, First pattern, Last pattern
;EnemyShooterPatternsUp:         db      4, 22, 87, %1'000'0100         ; Animation delay, First pattern, Last pattern
;EnemyShooterPatternsDown:       db      4, 22, 87, %1'000'0100         ; Animation delay, First pattern, Last pattern
;
EnemyTermPatternsStr:           db      5, 20, 85, %1'000'0101         ; Animation delay, First pattern, Last pattern
EnemyTermPatternsUp:            db      5, 22, 87, %1'000'0101         ; Animation delay, First pattern, Last pattern
EnemyTermPatternsDown:          db      5, 24, 89, %1'000'0101         ; Animation delay, First pattern, Last pattern
;
EnemyWayPatternsStr:            db      4, 26, 90, %1'000'0110         ; Animation delay, First pattern, Last pattern
EnemyWayPatternsUp:             db      4, 27, 91, %1'000'0110         ; Animation delay, First pattern, Last pattern
EnemyWayPatternsDown:           db      4, 28, 92, %1'000'0110         ; Animation delay, First pattern, Last pattern
;
EnemyWayShooterPatternsStr:     db      6, 29, 93, %1'000'0110         ; Animation delay, First pattern, Last pattern
EnemyWayShooterPatternsUp:      db      6, 30, 94, %1'000'0110         ; Animation delay, First pattern, Last pattern
EnemyWayShooterPatternsDown:    db      6, 31, 95, %1'000'0110         ; Animation delay, First pattern, Last pattern
;
TurretEnablePatterns:           db      10, 32, 96, %1'000'0111         ; Animation delay, First pattern, Last pattern
TurretDisablePatterns:          db      10, 33, 33, %1'000'0111         ; Animation delay, First pattern, Last pattern
;
BulletPlayerType0PatternsStr:   db      0, 98, 98, %1'000'1000       ; Animation delay, First pattern, Last pattern
BulletPlayerType0PatternsDiag:  db      0, 35, 35, %1'000'1000       ; Animation delay, First pattern, Last pattern
BulletPlayerType1PatternsStr:   db      0, 99, 99, %1'000'1000       ; Animation delay, First pattern, Last pattern
BulletPlayerType1PatternsDiag:  db      0, 36, 36, %1'000'1000       ; Animation delay, First pattern, Last pattern
BulletPlayerType2PatternsStr:   db      0, 100, 100, %1'000'1000       ; Animation delay, First pattern, Last pattern
BulletPlayerType2PatternsDiag:  db      0, 37, 37, %1'000'1000       ; Animation delay, First pattern, Last pattern
BulletPlayerType3PatternsStr:   db      0, 101, 101, %1'000'1000       ; Animation delay, First pattern, Last pattern
BulletPlayerType3PatternsDiag:  db      0, 38, 38, %1'000'1000       ; Animation delay, First pattern, Last pattern
; BombPlayerType0PatternsStr:     db      0, 102, 102, %1'000'1000       ; Animation delay, First pattern, Last pattern
;BombPlayerType0PatternsDiag:    db      0, 39, 39, %1'000'1000       ; Animation delay, First pattern, Last pattern
;
BulletEnemyTurret0PatternsStr:    db      0, 111, 111, %1'000'1100       ; Animation delay, First pattern, Last pattern
BulletEnemyTurret1PatternsStr:    db      0, 48, 48, %1'000'1100       ; Animation delay, First pattern, Last pattern
BulletEnemyTurret2PatternsStr:    db      0, 112, 112, %1'000'1100       ; Animation delay, First pattern, Last pattern
BulletEnemyShooter0PatternsStr:   db      0, 49, 49, %1'000'1100       ; Animation delay, First pattern, Last pattern
BulletEnemyShooter1PatternsStr:   db      0, 113, 113, %1'000'1100       ; Animation delay, First pattern, Last pattern
;
BulletPatternsExp:              db      3, 103, 41, %1'000'1001       ; Animation delay, First pattern, Last pattern
BulletEnemyPatternsExp:         db      3, 103, 41, %1'000'1001       ; Animation delay, First pattern, Last pattern
PlayerPatternsExp:              db      8, 105, 45, %1'000'1010       ; Animation delay, First pattern, Last pattern
EnemyPatternsExp:               db      6, 109, 47, %1'000'1011       ; Animation delay, First pattern, Last pattern
;
LockerEnergyPatterns:            db     10, LockerEnergyStartPattern, LockerEnergyEndPattern,  %1'000'1101      ; Animation delay, First pattern, Last pattern
LockerFreezePatterns:            db     10, LockerFreezeStartPattern, LockerFreezeEndPattern,  %1'000'1101      ; Animation delay, First pattern, Last pattern
LockerEnergyCollectablePatterns: db     10, LockerCollectableEnergyStartPattern, LockerCollectableEnergyEndPattern,  %1'000'1101      ; Animation delay, First pattern, Last pattern
LockerFreezeCollectablePatterns: db     10, LockerCollectableFreezeStartPattern, LockerCollectableFreezeEndPattern,  %1'000'1101      ; Animation delay, First pattern, Last pattern

;LockerAllPatterns:              db      LockerToggleBullets, LockerEnergyStartPattern, LockerBulletsPattern, %1'000'1101   ; Animation delay, First pattern, Last pattern
;LockerNoBulletPatterns:         db      LockerToggleBullets, LockerEnergyStartPattern, LockerFreezeStartPattern, %1'000'1101     ; Animation delay, First pattern, Last pattern
;LockerCollectablePatterns:      db      0, LockerCollectableEnergyStartPattern, LockerCollectableFreezeStartPattern, %1'000'1101        ; Animation delay, First pattern, Last pattern
;
Key1Patterns:                   db      10, 125, 126, %1'000'1110       ; Animation delay, First pattern, Last pattern
;Key2Patterns:                   db      0, 52, 52, %1'000'1101       ; No longer used - Animation delay, First pattern, Last pattern
;
PausePatterns:                  db      30, 63, 127, %1'000'1110
;HUDBackgroundPatterns           db      0, 50, 50, %1'000'1111            ; Only byte 4 relevant
HUDNumberDigitPatterns:         db      0, 0, 0, %1'000'1111            ; Only byte 4 relevant
; HUD Save Points
; Same pattern used for disabled/enabled - Only difference is palette offset
HUDSavePointDisabledPatterns:   db      0, 102, 102, %1'000'1000
HUDSavePointEnabledPatterns:    db      0, 39, 39, %1'000'1000
; Sprite Text
SpriteTextPatterns:             db      0, 0, 0, %1'000'0000            ; Only byte 4 relevant
FriendlySpriteTextPatterns:     db      4, 93, 94, %1'000'0000         ; Animation delay, First pattern, Last pattern
MouseSpriteTextPatterns:        db      30, 31, 95, %1'000'0000         ; Animation delay, First pattern, Last pattern

;FriendlyPatternsInactiveStr:    db      0, 8, 8, 0         ; Animation delay, First pattern, Last pattern
;FriendlyPatternsInactiveDiag:   db      0, 8, 8, 0         ; Animation delay, First pattern, Last pattern
;BulletTurretPatternsExp:        db      3, 116, 117, %1'000'0000       ; Animation delay, First pattern, Last pattern

;-------------------------------------------------------------------------------------
; Spawned Sprites Movement Values
; - Used to set sprite based on movement value
SpriteMovementValues:
.Right:          db %0'0'1'0'0'0'0'0    ; 1 - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical
.Left:           db %0'0'1'0'0'0'1'0    ; 2 - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical
.Move3:          db 0            ; 3 - Not used
.Down:           db %0'0'0'0'1'0'0'0    ; 4 - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical
.DownRight:      db %0'0'1'0'0'0'0'0     ; 5 - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical
.DownLeft:       db %0'0'1'0'0'0'1'0     ; 6 - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical
.Move7:          db 0            ; 7 - Not used
.Up:             db %0'0'0'1'0'0'0'0    ; 8 - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical
.UpRight:        db %0'0'1'0'0'0'0'0     ; 9 - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical
.UpLeft:         db %0'0'1'0'0'0'1'0     ; a - %--PPPRHV = Pattern (Right), Pattern (Up), Pattern (Down), Rotate, Mirror Horizontal, Mirror Vertical

;-------------------------------------------------------------------------------------
; Spawned Sprite Bullets Movement Values
; - Used to set sprite bullets based on movement value
SpriteBulletMovementValues:
.Right:          db %0'0'0'0'0'0'0'0    ; 1 - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical
.Left:           db %0'0'0'0'0'0'1'0    ; 2 - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical
.Move3:          db 0            ; 3 - Not used
.Down:           db %0'0'0'0'0'1'0'0    ; 4 - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical
.DownRight:      db %0'0'0'0'1'0'0'0     ; 5 - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical
.DownLeft:       db %0'0'0'0'1'1'0'0     ; 6 - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical
.Move7:          db 0            ; 7 - Not used
.Up:             db %0'0'0'0'0'1'0'1    ; 8 - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical
.UpRight:        db %0'0'0'0'1'0'0'1     ; 9 - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical
.UpLeft:         db %0'0'0'0'1'1'0'1     ; a - %----PRHV = Pattern (0=Straight, 1=Diagonal), Rotate, Mirror Horizontal, Mirror Vertical

/*
;-------------------------------------------------------------------------------------
; Spawned Bullets Offset Values
; - Used to set offset on spawned bullets based on movement value
BulletMovementSpawnValues:
RightSpawn:     dw 16, 0        ; 1
LeftSpawn:      dw -16, 0       ; 2
Move3Spawn:     dw 0, 0         ; 3
DownSpawn:      dw 0, 16        ; 4 - Not used
DownRightSpawn: dw 16, 16       ; 5
DownLeftSpawn:  dw -16, 16      ; 6
Move7Spawn:     dw 0, 0         ; 7 - Not used
UpSpawn:        dw 0, -16       ; 8  
UpRightSpawn:   dw 16, -16      ; 9
UpLeftSpawn:    dw -16, -16     ; a
*/
;-------------------------------------------------------------------------------------
; Reticule Rotation
ReticuleRotation:       db      0       ; Current reticule rotation value (0 - 255) - Set in code
ReticuleRadius:         db      16      ; Rotation radius around player
; - Used to lookup rotation value based on player movement input 
; Note: Player movement input = "----UDLR"; decremented by 1 as table starts at 0
; Note: Rotation values 0 - 255; 0 - Top (0 degrees)- Running clockwise to 255 (~358 degrees) 
PlayerMovementToRotationValues:
MovementRight:          db      64      ; 1 - Movement 
MovementLeft:           db      192     ; 2 - Movement
Movement3:              db      0       ; 3 - Not used
MovementDown:           db      128     ; 4 - Movement
MovementDownRight:      db      96      ; 5 - Movement
MovementDownLeft:       db      160     ; 6 - Movement
Movement7:              db      0       ; 7 - Not used
MovementUp:             db      0       ; 8 - Movement
MovementUpRight:        db      32      ; 9 - Movement
MovementUpLeft:         db      224     ; a - Movement

/*
; - Used to lookup sprite offset (x, y) based on rotation value
; Note: Based on Radius of 16 pixels around player sprite
; Note: Rotation values 0 - 15; 0 - Top (0 degrees)- Running clockwise to 15 (337 degrees) 
RotationToOffsetXY:
RotationOff0:              dw      0, -16
RotationOff1:              dw      6, -15
RotationOff2:              dw      11, -11
RotationOff3:              dw      15, -6
RotationOff4:              dw      16, 0
RotationOff5:              dw      15, 6
RotationOff6:              dw      11, 11
RotationOff7:              dw      6, 15
RotationOff8:              dw      0, 16
RotationOff9:              dw      -6, 15
RotationOff10:             dw      -11, 11
RotationOff11:             dw      -15, 6
RotationOff12:             dw      -16, 0
RotationOff13:             dw      -15, 6
RotationOff14:             dw      -11, -11
RotationOff15:             dw      -6, -15
*/

/*
; - Used to lookup sprite movement (x, y) based on rotation value
; Note: Based on Radius of 2 pixels to minimise values
; Note: Rotation values 0 - 15; 0 - Top (0 degrees)- Running clockwise to 15 (337 degrees) 
RotationToMovementXY:
RotationMov0:             dw      0, -2
RotationMov1:             dw      1, -2
RotationMov2:             dw      2, -2
RotationMov3:             dw      2, -1
RotationMov4:             dw      2, 0
RotationMov5:             dw      2, 1
RotationMov6:             dw      2, 2
RotationMov7:             dw      1, 2
RotationMov8:             dw      0, 2
RotationMov9:             dw      -1, 2
RotationMov10:            dw      -2, 2
RotationMov11:            dw      -2, 1
RotationMov12:            dw      -2, 0
RotationMov13:            dw      -2, -1
RotationMov14:            dw      -2, -2
RotationMov15:            dw      -1, -2
*/
;-------------------------------------------------------------------------------------
; Spawned Sprites Attribute Table
; - Used to store instantiated sprites - sprite attribute data
; NOTE: Don't change sprite values as this could impact currently configured levels
; NOTE: If updated, also check/update Level Spreadsheet
;               -Key Components Worksheet - Update Values
;               -Levels worksheets - Check Values
MaxSprites:             EQU     1+MaxHUDSprites+1+1+MaxPlayerBullets+MaxKeys+MaxFriendly+MaxEnemy+MaxEnemyBullets+MaxLockers;MaxPlayerBombs+MaxCollectables ; Includes Player+Reticule
MaxHUDSprites:          EQU     22;16;12;21;20;22     ; Includes Pause sprite
MaxPlayerBullets:       EQU     7;10;15
;MaxPlayerBombs:         EQU     12;8;3
MaxKeys:                EQU     11;12
MaxFriendly:            EQU     12;15
MaxEnemy:               EQU     38;36;25
MaxEnemyBullets:        EQU     7;10
MaxLockers:             EQU     8
;MaxCollectables:        EQU     5
SpriteAtt:
; Note: Sprite order dictates sprite display priority. i.e. Last sprite displayed behind all other sprites
; Sprite Attribute Storage
                        DS      MaxSprites * S_SPRITE_ATTR;MaxSprites * S_SPRITE_ATTR, 0          ; Storage for 128 * 4-bit sprites or 64 * 8-bit sprites
ReticuleSprAtt:         EQU     SpriteAtt + 0*S_SPRITE_ATTR     ; Player reticule attribute data starts at this address
HUDSprAtt:              EQU     SpriteAtt + 1*S_SPRITE_ATTR     ; HUD attribute data starts at this address
PlayerSprAtt:           EQU     HUDSprAtt + MaxHUDSprites*S_SPRITE_ATTR ;SpriteAtt + 1*S_SPRITE_ATTR     ; Player sprite attribute data starts at this address
PlayerUpgradeAtt:       EQU     PlayerSprAtt + 1*S_SPRITE_ATTR 
OtherSprAtt:            EQU     PlayerUpgradeAtt + 1*S_SPRITE_ATTR ;SpriteAtt + 2*S_SPRITE_ATTR     ; ALL other sprite attribute data starts at this address

; Sprite Numbers
BulletAttStart:         EQU     1+MaxHUDSprites+1+1                     ; Player bullet sprites start at this sprite number
EnemyBulletAttStart:    EQU     BulletAttStart+MaxPlayerBullets	        ; Enemy bullet sprites start at this sprite number
;BombAttStart:		EQU     EnemyBulletAttStart+MaxEnemyBullets     ; Bomb Sprites start at this Sprite offset
EnemyAttStart:          EQU     EnemyBulletAttStart+MaxEnemyBullets;BombAttStart+MaxPlayerBombs             ; Enemy Sprites start at this Sprite attribute offset
; -- Keep together - Used as sequence within player collison routine
FriendlyAttStart:       EQU     EnemyAttStart+MaxEnemy                  ; Friendly Sprites start at this Sprite offset
;CollectableAttStart:    EQU     FriendlyAttStart+MaxFriendly            ; Collectable Sprites start at this Sprite offset
KeyAttStart:            EQU     FriendlyAttStart+MaxFriendly;CollectableAttStart+MaxCollectables     ; Key Sprites start at this Sprite offset
LockerAttStart:         EQU     KeyAttStart+MaxKeys                     ; Locker Sprites start at this Sprite offset attribute offset
; --

;-------------------------------------------------------------------------------------
; Spawned Sprites Table
; - Used to store instantiated sprites - non-sprite attribute data
Sprites:
                                DS      MaxSprites * S_SPRITE_TYPE;MaxSprites * S_SPRITE_TYPE
ReticuleSprite:                 EQU     Sprites + 0*S_SPRITE_TYPE                       ; Player reticule sprite data
HUDSpritesStart:                EQU     ReticuleSprite + 1*S_SPRITE_TYPE ;Sprites + 1*S_SPRITE_TYPE                       ; HUD sprite data
PlayerSprite:                   EQU     HUDSpritesStart + MaxHUDSprites*S_SPRITE_TYPE ;1*S_SPRITE_TYPE                       ; Player sprite data
PlayerUpgrade:                  EQU     PlayerSprite + 1*S_SPRITE_TYPE                  ; Player upgrade sprite
OtherSprites:                   EQU     PlayerUpgrade + 1*S_SPRITE_TYPE;Sprites + 2*S_SPRITE_TYPE                       ; Player sprite data
BulletSpritesStart:             EQU     Sprites + BulletAttStart*S_SPRITE_TYPE          ; Player bullet sprite data
FriendlySpritesStart:           EQU     Sprites + FriendlyAttStart*S_SPRITE_TYPE        ; Friendly sprite data
;CollectableSpritesStart:        EQU     Sprites + CollectableAttStart*S_SPRITE_TYPE     ; Collectable sprite data
KeySpritesStart:                EQU     Sprites + KeyAttStart*S_SPRITE_TYPE             ; Keys sprite data
LockerSpritesStart:             EQU     Sprites + LockerAttStart*S_SPRITE_TYPE          ; Locker sprite data
EnemySpritesStart:              EQU     Sprites + EnemyAttStart*S_SPRITE_TYPE           ; Enemy sprite data
EnemyBulletSpritesStart:        EQU     Sprites + EnemyBulletAttStart*S_SPRITE_TYPE     ; Enemy bullet sprite data
;BombSpritesStart:               EQU     Sprites + BombAttStart*S_SPRITE_TYPE            ; Bomb sprite data

;-------------------------------------------------------------------------------------
; GameCode Memory Bank (8KB)
Code_Bank:      equ     12      ; First 8KB memory bank to store code
ROM_Bank:       db      0       ; Initial memory bank hosted in MMU0

;-------------------------------------------------------------------------------------
; Level Settings
LevelTileMap:           dw      LevelTileMapData                                        ; Address of working Tilemap data
LevelTileMapData:       ds      LevelTileMapMaxWidth*LevelTileMapMaxHeight              ; Working Tilemap data used/updated during level gameplay  
LevelWayPointData:      ds      WayPointsMax * S_WAYPOINT_DATA                          ; Working Waypoint data used during level gameplay  
PlayerType1Keys:        db      0                                                       ; Number of type 1 keys collected - Set in code
PlayerType2Keys:        db      0                                                       ; Number of type 2 keys collected - Set in code

;-------------------------------------------------------------------------------------
; Score Variables
Score:                  defb    "000000", 0     ; Managed as string due to required value greater than word
HiScore:                defb    "000000", 0     ; Managed as string due to required value greater than word - Set in code
ScoreLength:            equ     6
ScoreDestroyEnemy:      defb    2, "10"         ; Number of digits, points
ScoreDisableTurret:     defb    3, "100"        ; Number of digits, points
ScoreDestroySpawnPoint: defb    3, "200"        ; Number of digits, points
ScoreRescueFriendly:    defb    4, "1000"       ; Number of digits, points
ScoreCompleteLevel:     defb    5, "10000"      ; Number of digits, points

;-------------------------------------------------------------------------------------
; Layer 2 Settings
L2Start_16_Bank:        equ     9					
L2Start_8_Bank:         equ     L2Start_16_Bank * 2
L2BANK_8K_SIZE:         EQU     8192
L2NUM_BANKS:            EQU     L2Width * L2Height / L2BANK_8K_SIZE
L2Width:                equ     320
L2Height:               equ     256
L2ScrollOffsetX:        equ     0       ; Starting offset
L2ScrollOffsetY:        equ     0       ; Starting offset
L2ScrollXValue:         db      9       ; Scroll - Controls layer2 x scroll position - Updated in code
L2ScrollYValue:         db      9       ; Scroll - Controls layer2 y scroll position - Updated in code
L2ScrollDelay:          EQU     1       ; L2 Frame delay pause 
L2ScrollDelayCounter:   db      0      

;-------------------------------------------------------------------------------------
; Mouse Variables
XMove:          db      0       ; Used for detecting mouse x movement - Set in code
YMove:          db      0       ; Used for detecting mouse y movement - Set in code
Scrolled:       db      0       ; ----UDLR - Indicates direction of recent scroll, used to help update reticule position - Set in code - TODO - Remove?
MouseXDelta:    db      0       ; X Distance between mouse and player - Set in code
MouseYDelta:    db      0       ; Y followDistance between mouse and player - Set in code
MouseSpeedGame: equ     20      ; Speed of in game mouse - Higher Value = Faster - Set in code
MouseSpeed:     db      0       ; Set in code
;-------------------------------------------------------------------------------------
; Tilemap Settings
TileMapLocation:                equ     $6000
TileMapLocationOffset:          equ     0       ; TileMap slot 256 byte offset
TileMapDefLocation:             EQU     TileMapLocation+TileMapWidth*TileMapHeight      ;$e000+TileMapWidth*TileMapHeight
TileMapDefLocationOffset:       equ     (TileMapWidth*TileMapHeight)    ; TileMap slot 256 byte offset
TileMapWidth:                   EQU     40      ; Tilemap: Value written to port
TileMapHeight:                  EQU     32      ; Tilemap: Value written to port
TileMapXOffsetLeft:             EQU     8       ; X - Hide Left 8 x pixels for scrolling 
TileMapXOffsetRight:            EQU     151     ; X - Hide Right 8 x pixels for scrolling 
TileMapYOffsetTop:              EQU     16      ; Y - Hide Top 8 x pixels for scrolling 
TileMapYOffsetBottom:           EQU     239     ; Y - Hide Bottom 8 x pixels for scrolling 
; Tile definition Settings
TileDefHeight:                  equ     8       ; Tile: Height = Usually 8 pixels
TileDefWidth:                   equ     4       ; Tile: Width = 4 for 4bit tiles
TileEmpty:                      equ     0       ; Tile definition used to clear screen
; Block Settings
BlockWidth:                     equ     2       ; Block: Width = Number of Tiles
BlockHeight:                    equ     2       ; Block: Height = Number of Tiles
BlockSize:                      equ     BlockWidth*BlockHeight*32       ; Tile definition = 32 bytes per tile
BlockTiles:                     equ     BlockHeight*BlockWidth          ; Block: Number of tiles within block
BlockTileMapWidth:              equ     3*20      ; Block: Width in blocks to be displayed within tilemap (3 x screens wide - Dimension in Tiled)
BlockTileMapHeight:             equ     3*16      ; Block: Height in blocks to be displayed within tilemap (3 x screens high - Dimension in Tiled)
BlockTileMapWidthDisplay:       equ     TileMapWidth/BlockWidth ; Block: Max width in blocks that can be displayed on screen
BlockTileMapHeightDisplay:      equ     TileMapHeight/BlockHeight ; Block: Max width in blocks that can be displayed on screen
BlockTileMapXBlocksOffset:      db      0      ; Block: X Offset in blocks to draw blocks onto TileMap (0=Draw first block in first hidden column)
BlockTileMapYBlocksOffset:      db      0      ; Block: Y Offset in blocks to draw blocks onto TileMap (0=Draw first block in first hidden row)
;BlockTileMapXTilesOffset:       equ     BlockTileMapXBlocksOffset*BlockWidth    ; Block: X Offset in tiles to draw blocks onto TileMap
;BlockTileMapYTilesOffset:       equ     BlockTileMapYBlocksOffset*BlockHeight   ; Block: Y Offset in tiles to draw blocks onto TileMap
BlockWidthLoopCounter           db      0       ; Block: Number of blocks to display across screen - Updated in code
BlockWidthSourceCounter:        db      0       ; Block: Offset to add to block source when end of line reached - Updated in code
BlockHeightLoopCounter:         db      0       ; Block: Number of blocks to display down screen - Updated in code
BlockPlayerTopRow:              equ     1                       ; FF Target - Top block row to be checked
BlockPlayerBottomRow:           equ     TileMapHeight/2-2       ; FF Target - Bottom block row to be checked
BlockPlayerLeftCol:             equ     1                       ; FF Target - Far left block column to be checked
BlockPlayerRightCol:            equ     TileMapWidth/2-2        ; FF Target - Far right block column to be checked
LevelTileMapMaxWidth:           equ     60      ; Maximum width for level tilemap
LevelTileMapMaxHeight:          equ     48      ; Maximum height for level tilemap

;-------------------------------------------------------------------------------------
; Title - L2 Data
TitleTileMapXOffsetLeft:                EQU     16;8       ; X - Hide Left 8 x pixels for scrolling 
TitleTileMapXOffsetRight:               EQU     143;151     ; X - Hide Right 8 x pixels for scrolling 
TitleTileMapYOffsetTop:                 EQU     32;16      ; Y - Hide Top 8 x pixels for scrolling 
TitleTileMapYOffsetBottom:              EQU     207;239     ; Y - Hide Bottom 8 x pixels for scrolling 
TitleTileMapXOffsetLeftCounter:         db      0 
TitleTileMapXOffsetRightCounter:        db      0 
TitleTileMapYOffsetTopCounter:          db      0
TitleTileMapYOffsetBottomCounter:       db      0

; Clear Screen Settings - Sprite/Tilemap
;-------------------------------------------------------------------------------------
ClearScreenY1Middle:            equ     128     ; Position for top edge of screen
ClearScreenY2Middle:            equ     127     ; Position for bottom edge of screen
ClearScreenY1Counter:           db      0       ; Counter for top edge of screen
ClearScreenY2Counter:           db      0       ; Counter for bottom edge of screen
ClearScreenX1Middle:            equ     80      ; Position for left edge of screen
ClearScreenX2Middle:            equ     79      ; Position for right edge of screen
ClearScreenX1Counter:           db      0       ; Counter for left edge of screen
ClearScreenX2Counter:           db      0       ; Counter for right edge of screen

;-------------------------------------------------------------------------------------
; Tilemap Scroll Settings
ScrollXStart:                   equ     0       ; Scroll - X - Start value when scrolling
ScrollYStart:                   equ     0       ; Scroll - Y - Start value when scrolling
ScrollXValue:                   db      0       ; Scroll - Controls tilemap x scroll position - Updated in code
ScrollYValue:                   db      0       ; Scroll - Controls tilemap y scroll position - Updated in code
ScrollTileMapBlockXPointer:     db      0       ; Scroll - Pointer to X block within tilemap data for screen top-left corner - Updated in code
ScrollTileMapBlockYPointer:     db      0       ; Scroll - Pointer to Y block within tilemap data for screen top-left corner - Updated in code
ScrollYBlock:                   db      0       ; Scroll - Y Block at which tilemap scrolls - Updated in code
ScrollXBlock:                   db      0       ; Scroll - X Block at which tilemap scrolls - Updated in code
LevelScrollWidth:               db      0       ; Scroll - Used to restrict scroll width as level may be smaller than actual tilemap
LevelScrollHeight:              db      0       ; Scroll - Used to restrict scroll height as level may be smaller than actual tilemap

;-------------------------------------------------------------------------------------
; Camera Variables
CameraXWorldCoordinate          dw      0       ; X World coordinate for camera (top-left) - Updated in code
CameraYWorldCoordinate          dw      0       ; Y World coordinate for camera (top-left) - Updated in code
CameraWidth:                    equ     320-(16*2)      ; Hidden columns deducted
CameraHeight:                   equ     256-(16*2)      ; Hidden rows deducted

;-------------------------------------------------------------------------------------
; Level Variables
PlayerMoved:                    db      0               ; Used to indicate player moved so animation can be played
PlayerStartXYBlock:             dw      0               ; Player start X/Y position in blocks- Set in code
ScreenMiddleX:                  equ     (320/2);-8       ; X Position to trigger X scroll (8 - ensure middle of 16 pixel sprite)
ScreenMiddleY:                  equ     (256/2);-8       ; Y Position to trigger Y scroll (8 - ensure middle of 16 pixel sprite)
BulletsPlayerFired:             db      0               ; Nunber of player bullets fired - Set in code
;BombsPlayerFired:               db      0               ; Nunber of player bombs fired - Set in code
BulletsEnemyFired:              db      0               ; Nunber of enemy bullets fired - Set in code
PlayerBlockXY:                  dw      0               ; Tilemap block x/y containing player - Set in code
PlayerBlockOffset:              dw      0               ; Tilemap block offset containing player - Set in code 
FinishBlockXY:                  dw      0               ; Tilemap block x/y containing finish - Set in code
FinishBlockOffset:              dw      0               ; Tilemap block offset containing player - Set in code 
CurrentLevel:                   db      1               ; Current level being played
UnlockedLevel:                  db      1               ; Highest level unlocked; starts at 1
MaxLevels:                      equ     10              ; Maximum levels
EndOfLevelPause:                equ     75;50              ; Number of frames to wait to allow sound to finish at end of level
EndOfLevelPauseCounter:         db      0               ; End Of Level Pause counter - Set in code
;PlayerDroppedBomb:              db      0               ; Flag to indicate player has dropped bomb - Set in code
;PlayerBombAnimCount:            equ     10              ; Number of animation loops before bomb explodes               
;BombExploding:                  db      0               ; Flag to indicate bomb starting to explode - Set in code
FriendlyRescuedPalCycleEnabled: equ     41              ; End palette colour offset - All friendly rescued
TurretInRange:                  db      0               ; Flag used to indicate turret in range and to fire bullet - Set in code
TurretPreviousRotation:         db      0               ; Last rotation value in the event we need to restore i.e. Block behind turret - Set in code
WayPointsMax:                   equ     75             ; Maximum number of waypoints that can be assigned within level
; --- Reverse-Hazard variables
ReverseHazardEnabled:           db      0               ; When set causes hazards to be reverse i.e. safe to player - Set in code
ReverseHazardEnabledPlayer:     db      0               ; When set indicates player is touching reverse-hazard block - Set in code
ReverseHazardDelay:             equ     10               ; Delay to reset ReverseHazardEnabled
ReverseHazardCounter:           db      0               ; Counter for resetting ReverseHazardEnabled - Set in code
ReverseHazardEnableBlock:       equ     62              ; Block to trigger reverse-hazard
ReverseHazardBlock:             equ     63              ; Block to replace hazard blocks
ReverseHazardDamage:            db      0               ; Damage inflicted to enemy via reverse-hazard - Set via Player Tiled
; --- Freeze variables
;PlayerFreezeStart:              equ     99              ; Player freeze time at start of game
PlayerFreezeMax:                equ     99              ; Maximum freeze time player can obtain
PlayerFreezeTime:               db      0               ; Current player freeze time - Set in code
FreezeEnableDuration:           equ     5               ; Number of frames to freeze (>1)
FreezeEnableCounter:            db      0               ; Freeze enable countdown - Set in code
FreezeDisableDuration:          equ     2               ; Number of frames before freeze can be re-used (>1)
FreezeDisableCounter:           db      0               ; Freeze disable countdown - Set in code
; --- Pause variables
PauseDelay:                     EQU     20              ; Number of frames to wait to allow pause key to be registered again
PauseDelayCounter:              db      0               ; Counter - Set in code
; --- Other variables
RespawnDamageDelay:             equ     100             ; Delay before player takes damage when respawned
RespawnDamageDelayCounter:      db      0               ; Counter for RespawnDamageDelay
; --- Reticule/Energy variables
ReticuleMidEnergyThreshold:     equ     60              ; Threshold at which player reticule changes to mid energy palette
ReticuleLowEnergyThreshold:     equ     30              ; Threshold at which player reticule changes to low energy palette

;-------------------------------------------------------------------------------------
; CFG File Settings
; Remaining associated value stored in titledata.asm
FileCFGBuffer:          ds      FileCFGSize, 0                  ; Set in code
                        ;db      <UnlockedLevel> (1 byte)
                        ;db      "<Score><Name>" (9 bytes)
                        ;db      "<Score><Name>" (9 bytes)
                        ;db      "<Score><Name>" (9 bytes)
                        ;db      "<Score><Name>" (9 bytes)
                        ;db      "<Score><Name>" (9 bytes)

;-------------------------------------------------------------------------------------
; Block Identification Data (Block Tiles)
; - Walls & Destructable Blocks...
; Note: 0 - 63 = Visible tiles, 64 - 127 = Object tiles i.e. Non-visible
BlockWallsEnd:                  equ     27;29                              ; Wall blocks start at 0 and go to this value e.g. 2 indicates walls from 0-2; include destructable and turret blocks
DestructableStartBlock:         equ     20;22                              ; Destructable - Start block
DestructableEndBlock:           equ     23;25                              ; Destructable - End block
FloorStandardBlockSaveStart:    equ     29                              ; Start of floor blocks for Save point check
FloorStandardBlock:             equ     31                              ; Destructable - Standard floor block used for replacing destructable end block
FloorSavePointUsedBlock:        equ     29                              ; SavePoint - Floor block to indicate used savepoint 
FloorStandardBlockSaveEnd:      equ     32                              ; End of floor blocks for Save point check
;FloorLockdownBlock:             equ     62                              ; Lockdown - Floor block used to trigger lockdown
TurretEnabledStartBlock:        equ     24;26                              ; Turret - Enabled start block
TurretEnabledEndBlock:          equ     26;28                              ; Turret - Enabled end block
TurretNumberOfBlocks:           equ     TurretDisabledBlock-TurretEnabledStartBlock+1   ; Turret - Number of blocks - Used for wall checks
TurretDisabledBlock:            equ     27;29                              ; Turret - Disabled block
; - Doors
NumberHorDoorTypes:             equ     2                               ; Number of horizontal door types
NumberVerDoorTypes:             equ     2                               ; Number of vertical door types
NumberTriggerDoorTypes:         equ     2                               ; Number of trigger door types
MaxDoorTypes:                   equ     NumberHorDoorTypes+NumberVerDoorTypes+NumberTriggerDoorTypes   ; Total number of door types
TilesInDoorPattern:             equ     3                               ; Number of blocks in each door pattern animation 
HorDoorStart:                   equ     33;35                              ; Horizontal Door - Block Start : All vertical door patterns should follow after all horizontal door patterns 
HorDoor1End:                    equ     35;37                              ; Horizontal Door - Key type1 end block
HorDoor2End:                    equ     38;40                              ; Horizontal Door - Key type2 end block
HorDoorsEnd:                    equ     HorDoorStart+(NumberHorDoorTypes*TilesInDoorPattern)-1  ; Horizontal Door - Block End
VerDoorStart:                   equ     HorDoorsEnd+1                    ; Vertical Door - Block Start
VerDoor1End:                    equ     41;43                              ; Vertical Door - Key type1 end block
VerDoor2End:                    equ     44;46                              ; Vertical Door - Key type2 end block
VerDoorsEnd:                    equ     VerDoorStart+(NumberVerDoorTypes*TilesInDoorPattern)-1   ; Vertical Door - Block End
HorDoorTrigger:                 equ     45                              ; Horizontal Door - Trigger type block
HorDoorTriggerLockedDoor:       equ     HorDoorStart                    ; Used when trigger door unlocked
VerDoorTrigger:                 equ     46                              ; Vertical Door - Trigger type block
VerDoorTriggerLockedDoor:       equ     VerDoorStart                    ; Used when trigger door unlocked
; - Other
AntiFreeze:                     equ     28                              ; Anti-Freeze block
HazardStart:                    equ     51                              ; Hazard - Block Start 
HazardEnd:                      equ     54                              ; Hazard - Block End
RescueStart:                    equ     55                              ; Rescue - Block Start 
;RescueEnd:                      equ     55                              ; Rescue - Block End 
RescueDisableBlock:             equ     56                              ; Rescue - Block used for replacing rescue blocks
FinishDisableCentreBlock:       equ     47;48                              ; Finish - Disabled Centre
;FinishEnableSurroundBlock:      equ     49                              ; Finish - Enabled Surround used for replacing Finish Disabled Surround
FinishEnableCentreBlock:        equ     48;50                              ; Finish - Enabled Centre used for replacing Finish Disabled Centre
SpawnPoint1StartBlock:          equ     57                              ; Enemy Spawn Point Reuse - Block Start 
SpawnPoint1EndBlock:            equ     58                              ; Enemy Spawn Point Reuse - Block End
SpawnPoint2StartBlock:          equ     59                              ; Enemy Spawn Point - Block Start 
SpawnPoint2EndBlock:            equ     60                              ; Enemy Spawn Point - Block End
SpawnPointDisabledBlock:        equ     61                              ; Spawn Point - Block used for replacing disabled (reuse=disabled) spawn point blocks
;SpawnPointDestroyedBlock:       equ     62                              ; Spawn Point - Block used for replacing destroyed spawn point blocks
; Objects Layer Blocks
;-------------------------------------------------------------------------------------
; Door Tile Block Animation Pattern Ranges
Door1HorTypeBlockPattern:       db      3, HorDoorStart, HorDoorStart+TilesInDoorPattern-1, 0   ; Animation delay, First block, Last block, Loop
Door2HorTypeBlockPattern:       db      1, HorDoor1End+1, HorDoor1End+TilesInDoorPattern, 0     ; Animation delay, First block, Last block, Loop - Locked door
;Door3HorTypeBlockPattern:       db      1, HorDoor2End+1, HorDoorsEnd, 0                        ; Animation delay, First block, Last block, Loop - Locked door
Door1VerTypeBlockPattern:       db      3, VerDoorStart, VerDoorStart+TilesInDoorPattern-1, 0   ; Animation delay, First pattern, Last pattern, Loop
Door2VerTypeBlockPattern:       db      1, VerDoor1End+1, VerDoor1End+TilesInDoorPattern, 0     ; Animation delay, First block, Last block, Loop - Locked door
;Door3VerTypeBlockPattern:       db      1, VerDoor2End+1, VerDoorsEnd, 0                        ; Animation delay, First block, Last block, Loop - Locked door

;-------------------------------------------------------------------------------------
; Door Types/Data 
;- Door types used for identifying and populating door data
DoorTypeData:
;;;TriggerDoorType:                equ     %0'0000'011                             ; xor value - Set bit 1, reset bit 0 (if set), keep all other bits the same 
Door1HorType     S_DOOR_TYPE     {
                                HorDoorStart,                           ; Tile start value for door 
                                HorDoorStart+TilesInDoorPattern-1,      ; Tile end value for door 
                                %1'0010'000,                            ; %H'OPCV'L21 - Set in code
                                                                        ; H - 1 = Horizontal, 0 = Vertical
                                                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
                                Door1HorTypeBlockPattern}               ; Tile animation pattern
Door2HorLock1Type S_DOOR_TYPE     {
                                HorDoor1End+1,                          ; Tile start value for door 
                                HorDoor1End+TilesInDoorPattern,         ; Tile end value for door 
                                %1'0010'101,                            ; %H'OPCV'L21 - Set in code
                                                                        ; H - 1 = Horizontal, 0 = Vertical
                                                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
                                Door2HorTypeBlockPattern}               ; Tile animation pattern
Door3HorTriggerType S_DOOR_TYPE     {
                                HorDoorTrigger,                         ; Tile start value for door 
                                HorDoorTrigger,                         ; Tile end value for door 
                                %1'0010'110,                            ; %H'OPCV'L21 - Set in code
                                                                        ; H - 1 = Horizontal, 0 = Vertical
                                                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
                                Door1HorTypeBlockPattern}               ; Tile animation pattern
Door1VerType     S_DOOR_TYPE     {
                                VerDoorStart,                           ; Tile start value for door 
                                VerDoorStart+TilesInDoorPattern-1,      ; Tile end value for door 
                                %0'0010'000,                            ; %H'OPCV'L21 - Set in code
                                                                        ; H - 1 = Horizontal, 0 = Vertical
                                                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
                                Door1VerTypeBlockPattern}               ; Tile animation pattern
Door2VerLock1Type S_DOOR_TYPE     {
                                VerDoor1End+1,                          ; Tile start value for door 
                                VerDoor1End+TilesInDoorPattern,         ; Tile end value for door 
                                %0'0010'101,                            ; %H'OPCV'L21 - Set in code
                                                                        ; H - 1 = Horizontal, 0 = Vertical
                                                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
                                Door2VerTypeBlockPattern}               ; Tile animation pattern
Door3VerTriggerType S_DOOR_TYPE     {
                                VerDoorTrigger,                         ; Tile start value for door 
                                VerDoorTrigger,                         ; Tile end value for door 
                                %0'0010'110,                            ; %H'OPCV'L21 - Set in code
                                                                        ; H - 1 = Horizontal, 0 = Vertical
                                                                        ; O - Open, P, Opening, C - Closed, V - Closing, L - Locked, 2/1 - Key Value
                                Door1VerTypeBlockPattern}               ; Tile animation pattern

; - Door data for the current level
MaxDoors:                       equ     30
DoorsInLevel:                   db      0                               ; Used to hold doors to optimize loops
DoorData:                       ds      MaxDoors *  S_DOOR_DATA

;-------------------------------------------------------------------------------------
; Trigger Source/Target Data 
MaxTriggerSource:               equ     30
TriggerSourceData:              ds      MaxTriggerSource * S_TRIGGERSOURCE_DATA
MaxTriggerTarget:               equ     30
TriggerTargetData:              ds      MaxTriggerTarget * S_TRIGGERTARGET_DATA

;-------------------------------------------------------------------------------------
; Lockdown Data 
DoorLockdown:                   db      0       ; 0=No lockdown, 1=Lockdown - Set in code
DoorLockdownTileOffset:         dw      0       ; Tile offset for tile triggering lockdown - Set in code
DoorLockdownPalCycleOffset:     db      0       ; Palette cycle offset based on DoorLockdown status
DoorLockdownPalCycleDisabled:   equ     9       ; End palette colour offset - DoorLockdown = 0
DoorLockdownPalCycleEnabled:    equ     25      ; End palette colour offset - DoorLockdown = 1
RecordSpawnedNumber:            db      0       ; Counter to record enemies spawned during lockdown - Set in code
LastDoorPlayerUnlocked:         dw      0       ; Memory address of last door player unlocked, used for locking/unlocking door during lockdown       

;-------------------------------------------------------------------------------------
; Enemy spawn point Data 
; - Data copied from level SpawnPointSourceData
MaxSpawnPoints:                 equ     15
SpawnPointsInLevel:             db      0               ; Used to hold spawn points to optimize loops
SpawnPointData:                 DS      MaxSpawnPoints *  S_SPAWNPOINT_DATA

; - Data used for spawned flee based enemies
SpawnFleeTimeAddition           equ     16              ; Number of extra flee frames for enemies marked as spawned; other flee frames calculated via CalculateFleeTime routine
SpawnDelayDamageTime:           equ     6;8              ; Number of frames enemies marked as spawned are invulnerable
SpawnDirection:                 db      %0000'1000, %000'1001, %0000'0001, %000'0101                    ; xxxUDLR - Order of compass points on spawn point for spawned type enemies to spawn from - Part1
                                db      %0000'0100, %000'0110, %0000'0010, %000'1010, %0000'0000        ; xxxUDLR - Order of compass points on spawn point for spawned type enemies to spawn from - Part2
SpawnDirectionCounter:          db      0               ; Counter for SpawnDirection - Set in code
;-------------------------------------------------------------------------------------
; Hazard/Rescue Block Data
; TODO - Level
HazardOverlapPermitted:         equ     6;4;4             ; Hazard - Pixel overlap to permit between player/hazard before registering collision (higher = less chance for collision)
HazardTopOffset:                equ     0+HazardOverlapPermitted        ; Also used for anti-freeze block check
HazardBottomOffset:             equ     15-HazardOverlapPermitted       ; Also used for anti-freeze block check
HazardRightOffset:              equ     15-HazardOverlapPermitted       ; Also used for anti-freeze block check
HazardLeftOffset:               equ     0+HazardOverlapPermitted        ; Also used for anti-freeze block check
HazardDamage:                   db      0       ; Damage inflicted by hazard - Set via Player Tiled
FinishOverlapPermitted:         equ     7       ; Finish - Pixel overlap to permit between player/finish before registering collision (point to middle of sprite)
RescueOverlapPermitted:         equ     7       ; Rescue - Pixel overlap to permit between friendly/rescue before registering collision (point to middle of sprite)
;SpawnPointOverlapPermitted:     equ     7       ; Spawn Point - Pixel overlap to permit between bomb/spawn point before registering collision (point to middle of sprite)

;-------------------------------------------------------------------------------------
; Block Animation Data
; Note: Used for forward animations only; ensure blocks have a repeating pattern when animating
; Note: Do not include hazards, these are animated separately
StartBlockStorage:              ds      BlockSize       ; Temp storage for copying start Block
BlockAnimations:
BlockSpawn1Animation:   S_BLOCK_ANIMATION     {
                        15,                     ; Delay between animating blocks
                        0,                      ; Working counter for delay - Set in code 
                        SpawnPoint1StartBlock,   ; Start block in animation
                        SpawnPoint1EndBlock}     ; End block in animation
BlockSpawn2Animation:   S_BLOCK_ANIMATION     {
                        15,                     ; Delay between animating blocks
                        0,                      ; Working counter for delay - Set in code 
                        SpawnPoint2StartBlock,   ; Start block in animation
                        SpawnPoint2EndBlock}     ; End block in animation

BlockTurretAnimation:   S_BLOCK_ANIMATION     {
                        15,                     ; Delay between animating blocks
                        0,                      ; Working counter for delay - Set in code 
                        TurretEnabledStartBlock,; Start block in animation
                        TurretEnabledEndBlock}  ; End block in animation

;-------------------------------------------------------------------------------------
; Hazard Animation Data
MaxHazards:             equ     111;100;75
HazardBlockData:        ds      MaxHazards * S_HAZARD_DATA

;-------------------------------------------------------------------------------------
; Bullet Data
DestBlockTileEnergy:    equ     10      ; Damage required to destroy a single destructable block tile
                                                ; Note: A destructable block consists of multiple tiles
                                                ; e.g. A destructable block with 4 tiles would take damage of 40 (10*4)
                                                ; before being replaced with a ground tile 
EnemyShooterOffset:     equ     0;16      ; Value used to offset enemy range to enable enemy to stay out of range of player
EnemyShooterRange:      equ     96      ; When enemy shooter RotRange >= EnemyShooterRange, sets enemy shooter bullet Speed to 2 (default is 1) 
DestBlockTilesPerBlock: equ     DestructableEndBlock-DestructableStartBlock+1   ; Number of block tiles within a destructable block
MaxPlayerProjRange:     equ     80;112     ; Maximum range for player projectiles

; --- Bullet Types - Player/Enemy ---
; - Common to all levels
BulletPlayerLevel0:     S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletPlayerType0PatternsStr,      ; Sprite pattern range for bullet when fired - Straight
                        BulletPlayerType0PatternsDiag,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXPlayerBullet,                      ; AYFX sound to play
                        64,                     ; Range of bullet before being destroyed
                        5,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        DestBlockTileEnergy*(DestBlockTilesPerBlock/4), ; Damage inflicted by bullet
                        8,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        5,                      ; Collision - Start BoundaryX
                        5,                      ; Collision - Start BoundaryY
                        6,                     ; Collision - BoundaryWidth
                        6}                     ; Collision - BoundaryHeight
BulletPlayerLevel1:     S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletPlayerType1PatternsStr,      ; Sprite pattern range for bullet when fired - Straight
                        BulletPlayerType1PatternsDiag,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXPlayerBullet,                      ; AYFX sound to play
                        80,                     ; Range of bullet before being destroyed
                        5,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        DestBlockTileEnergy*(DestBlockTilesPerBlock/2), ; Damage inflicted by bullet
                        7,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        4,                      ; Collision - Start BoundaryX
                        2,                      ; Collision - Start BoundaryY
                        8,                     ; Collision - BoundaryWidth
                        12}                     ; Collision - BoundaryHeight
BulletPlayerLevel2:      S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletPlayerType2PatternsStr,      ; Sprite pattern range for bullet when fired - Straight
                        BulletPlayerType2PatternsDiag,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXPlayerBullet,                      ; AYFX sound to play
                        80                     ; Range of bullet before being destroyed
                        5,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        DestBlockTileEnergy*(DestBlockTilesPerBlock/1), ; Damage inflicted by bullet
                        7;5,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        3,                      ; Collision - Start BoundaryX
                        1,                      ; Collision - Start BoundaryY
                        10,                     ; Collision - BoundaryWidth
                        14}                     ; Collision - BoundaryHeight
BulletPlayerLevel3:      S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletPlayerType3PatternsStr,      ; Sprite pattern range for bullet when fired - Straight
                        BulletPlayerType3PatternsDiag,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXPlayerBullet,                      ; AYFX sound to play
                        MaxPlayerProjRange      ; Range of bullet before being destroyed
                        5,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        DestBlockTileEnergy*(DestBlockTilesPerBlock*2), ; Damage inflicted by bullet
                        7,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        2,                      ; Collision - Start BoundaryX
                        2,                      ; Collision - Start BoundaryY
                        12,                     ; Collision - BoundaryWidth
                        12}                     ; Collision - BoundaryHeight
/*
BombPlayer:             S_BULLET_DATA     {
                        BombSprType,            ; Bullet sprite template to be spawned/updated
                        BombPlayerType0PatternsStr,      ; Sprite pattern range for bullet when fired - Straight
                        BombPlayerType0PatternsDiag,      ; Sprite pattern range for bullet when fired - Diagonal
                        BombPatternsExp,        ; Sprite pattern range for bullet when exploding
                        MaxPlayerProjRange      ; Range of bullet before being destroyed
                        4,                      ; Speed of bullet
                        DestBlockTileEnergy*(DestBlockTilesPerBlock*4)   ; Damage inflicted by bullet
                        8;20,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        1,                      ; Collision - Start BoundaryX
                        1,                      ; Collision - Start BoundaryY
                        14,                     ; Collision - BoundaryWidth
                        14}                     ; Collision - BoundaryHeight
*/
BulletTurretLevel0:     S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletEnemyTurret0PatternsStr,      ; Sprite pattern range for bullet when fired
                        BulletEnemyTurret0PatternsStr,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletEnemyPatternsExp;BulletPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXEnemyTurretBullet,                      ; AYFX sound to play
                        0,                     ; Range of bullet before being destroyed
                        2,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        10,                     ; Damage inflicted by bullet
                        40,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        4,                      ; Collision - Start BoundaryX
                        4,                      ; Collision - Start BoundaryY
                        8,                     ; Collision - BoundaryWidth
                        8}                     ; Collision - BoundaryHeight
BulletTurretLevel1:     S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletEnemyTurret1PatternsStr,      ; Sprite pattern range for bullet when fired
                        BulletEnemyTurret1PatternsStr,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletEnemyPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXEnemyTurretBullet,                      ; AYFX sound to play
                        0,                     ; Range of bullet before being destroyed
                        2,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        10,                     ; Damage inflicted by bullet
                        25,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        2,                      ; Collision - Start BoundaryX
                        2,                      ; Collision - Start BoundaryY
                        12,                     ; Collision - BoundaryWidth
                        12}                     ; Collision - BoundaryHeight
BulletTurretLevel2:     S_BULLET_DATA     {     ; ---Turret - Surrounded by destructable blocks
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletEnemyTurret2PatternsStr,      ; Sprite pattern range for bullet when fired
                        BulletEnemyTurret2PatternsStr,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletEnemyPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXEnemyTurretBullet,                      ; AYFX sound to play
                        0,                     ; Range of bullet before being destroyed
                        3;2,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        15,                     ; Damage inflicted by bullet
                        7;10,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        1,                      ; Collision - Start BoundaryX
                        1,                      ; Collision - Start BoundaryY
                        14,                     ; Collision - BoundaryWidth
                        14}                     ; Collision - BoundaryHeight
BulletShooterLevel0:    S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletEnemyShooter0PatternsStr,      ; Sprite pattern range for bullet when fired
                        BulletEnemyShooter0PatternsStr,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletEnemyPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXEnemyShooterBullet,                      ; AYFX sound to play
                        0,                      ; Range of bullet before being destroyed - Set in code
                        2,                      ; Speed of bullet
                        2,                     ; Movement delay : higher = faster
                        10,                     ; Damage inflicted by bullet
                        50;75,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        4,                      ; Collision - Start BoundaryX
                        4,                      ; Collision - Start BoundaryY
                        8,                     ; Collision - BoundaryWidth
                        8}                     ; Collision - BoundaryHeight
BulletShooterLevel1:    S_BULLET_DATA     {
                        BulletSprType,          ; Bullet sprite template to be spawned/updated
                        BulletEnemyShooter1PatternsStr,      ; Sprite pattern range for bullet when fired
                        BulletEnemyShooter1PatternsStr,      ; Sprite pattern range for bullet when fired - Diagonal
                        BulletEnemyPatternsExp,      ; Sprite pattern range for bullet when exploding
                        AyFXEnemyWayBullet,                      ; AYFX sound to play
                        0,                      ; Range of bullet before being destroyed - Set in code
                        2,                      ; Speed of bullet
                        10,                     ; Movement delay : higher = faster
                        10;5,                     ; Damage inflicted by bullet
                        5,                     ; Delay between firing bullets
                        16,                     ; Width of sprite
                        16,                     ; Height of sprite
                        4,                      ; Collision - Start BoundaryX
                        4,                      ; Collision - Start BoundaryY
                        8,                     ; Collision - BoundaryWidth
                        8}                     ; Collision - BoundaryHeight

; --- Bullet Upgrade Table - Player ---
; - Common to all levels
BulletUpgradeFriendlyNumber:	db	0	        ; Working number of friendly to rescue for next bullet upgrade - Set in code
BulletUpgradeTableRef:          dw      0               ; Working reference to BulletUpgrade table - Set in code
BulletUpgradeTable:
			        db	0		        ; Player Bullet Upgrade 0 - Start bullet type
                                dw      BulletPlayerLevel0      ; Player Bullet Upgrade 0 - Bullet reference
                                ; -------
BulletUpgradeLevel1:            db	0		        ; Player Bullet Upgrade 1 - Required number of friendly to rescue - Set in player data
                                dw      BulletPlayerLevel1	; Player Bullet Upgrade 1 - Bullet reference
                                ; -------
BulletUpgradeLevel2:            db	0		        ; Player Bullet Upgrade 2 - Required number of friendly to rescue - Set in player data
                                dw      BulletPlayerLevel2	; Player Bullet Upgrade 2 - Bullet reference
                                ; -------
BulletUpgradeLevel3:            db	0		        ; Player Bullet Upgrade 3 - Required number of friendly to rescue - Set in player data
                                dw      BulletPlayerLevel3      ; Player Bullet Upgrade 3 - Bullet reference
BulletUpgradeTableEnd:

;-------------------------------------------------------------------------------------
; Rotation Data
Radius:                         db  0   ; Radius to rotation point - Set in code 
SinTable:  
; 64 Values representing angles 0 - 90; ~1.40625 degrees between each value
; Values stored as Sine values * 64 (amplitude); allows storing of values based on 2.6 fixed point numbers
    .db  $00,$02,$03,$05,$06,$08,$09,$0b,$0c,$0e
    .db  $10,$11,$13,$14,$16,$17,$18,$1a,$1b,$1d
    .db  $1e,$20,$21,$22,$24,$25,$26,$27,$29,$2a
    .db  $2b,$2c,$2d,$2e,$2f,$30,$31,$32,$33,$34
    .db  $35,$36,$37,$38,$38,$39,$3a,$3b,$3b,$3c
    .db  $3c,$3d,$3d,$3e,$3e,$3e,$3f,$3f,$3f,$40
    .db  $40,$40,$40,$40
CosTable:
; 64 Values representing angles 0 - 90; ~1.40625 degrees between each value
; Values stored as Cosine values * 64 (amplitude); allows storing of values based on 2.6 fixed point numbers
    .db  $40,$40,$40,$40,$40,$40,$3f,$3f,$3f,$3e
    .db  $3e,$3e,$3d,$3d,$3c,$3c,$3b,$3b,$3a,$39
    .db  $38,$38,$37,$36,$35,$34,$33,$32,$31,$30
    .db  $2f,$2e,$2d,$2c,$2b,$2a,$29,$27,$26,$25
    .db  $24,$22,$21,$20,$1e,$1d,$1b,$1a,$18,$17
    .db  $16,$14,$13,$11,$10,$0e,$0c,$0b,$09,$08
    .db  $06,$05,$03,$02
PlayerToTurretPosition:         db      0       ; ----XYUL - Position of player to turret
                                                ; X = 0 Player not level, 1 Player level; Y = 0 Player not level, 1 Player level; U = 0 Player below, 1 Player above; L = 0 Player to right, 1 Player to left - Set in code
ReticuleToPlayerPosition:       db      0       ; ------UL - Position of reticule to player - U = 0 reticule below, 1 reticule above; L = 0 reticule to right, 1 Reticule to left - Set in code
;PlayerToTurretAngle:            db      0       ; Inverse Tangent Angle - Set in code
PlayerToEnemyPosition:          db      0       ; ------UL - Position of player to enemy - U = 0 player below, 1 player above; L = 0 player to right, 1 player to left - Set in code

;-------------------------------------------------------------------------------------
; Flood Fill Data
FFStartxBlock           db      0                                       ; Used to hold player x block offset when starting flood fill
FFStartyBlock           db      0                                       ; Used to hold player y block offset when starting flood fill
FFSourceyPos:           db      0                                       ; Used to hold working y value when performing flood fill
FFSourcexPos:           db      0                                       ; Used to hold working x value when performing flood fill
FFStorage:              ds      BlockTileMapWidthDisplay*BlockTileMapHeightDisplay      ; Working copy - Used to hold Flood file node values during build - Populated at runtime
FFStorageComplete:      ds      BlockTileMapWidthDisplay*BlockTileMapHeightDisplay      ; Complete copy - Used to hold Flood file node values following build; used by enemies- Populated at runtime
FFResetValue:           equ     99                                      ; Value used to reset FFStorage entries
FFSourceOffset:         dw      0                                       ; Points to tilemap - Auto configured at runtime
FFTargetOffset:         dw      0                                       ; Points to FFStorage - Auto configured at runtime
FFTargetyPos:           db      0                                       ; Used to hold working y value when performing flood fill - Populated at runtime
FFTargetxPos:           db      0                                       ; Used to hold working x value when performing flood fill - Populated at runtime
FFNodesPerCall:         equ     10                                      ; Number of nodes to process during each update of FFStorage; used to spread FFStorage population over several frames
                                                                        ; The higher the number the quicker FFStorage is built, but the higher cost in raster time
                                                                        ; Current total number of nodes is ((40/2) * (32/2)) = 320
FFNodesPerCallCounter:  db      0                                       ; Used as working counter for FFNodesPerCall - Populated at runtime
FFQueueContent:         db      0                                       ; Used to indicate FF queue empty - Populated at runtime
FFBuilt:                db      0                                       ; Used to indicate when first FF build - Populated at runtime
FFScrollTileMapBlockXPointerBuilding    db      0                       ; Copy of ScrollTileMapBlockXPointer taken at start of FF routine i.e. Used when FF building
FFScrollTileMapBlockYPointerBuilding    db      0                       ; Copy of ScrollTileMapBlockYPointer taken at start of FF routine i.e. Used when FF building
FFScrollTileMapBlockXPointerBuilt       db      0                       ; Copy of ScrollTileMapBlockXPointer taken at end of FF routine i.e. Used when FF built
FFScrollTileMapBlockYPointerBuilt       db      0                       ; Copy of ScrollTileMapBlockYPointer taken at end of FF routine i.e. Used when FF built
FFValidPaths:           db      0                                       ; Used by enemy to determine valid paths through FF - Updated in code
NonFFValidPaths:        db      0                                       ; Used by enemy to determine valid paths through nonFF - Updated in code
EnemyLookAtEntityPaths: db      0                                       ; Used by enemy to look at player when it cannot move - Updated in code
EnemyMovementBlockMap:          ds      (BlockTileMapWidth*BlockTileMapHeight)/8;(BlockTileMapWidthDisplay*BlockTileMapHeightDisplay)/8  ; Used for marking blocks containing an enemy (0=empty, 1=occupied) - Updated in code
                                                                                        ; Representative of tilemap block size/8 i.e. Each byte represents 8 blocks (1/bit per block) 
FriendlyMovementBlockMap:       ds      (BlockTileMapWidth*BlockTileMapHeight)/8;(BlockTileMapWidthDisplay*BlockTileMapHeightDisplay)/8  ; Used for marking blocks containing a friendly (0=empty, 1=occupied) - Updated in code
                                                                                        ; Representative of tilemap block size/8 i.e. Each byte represents 8 blocks (1/bit per block) 
FFOffset:               dw      0                                       ; Used by FF enemy to determine valid paths through FF - - Updated in code
FFLowestValue:          db      0                                       ; Used by FF enemy to determine valid paths through FF - Updated on code
FFNewLowestValue:       db      0                                       ; Used by FF enemy to determine valid paths through FF - Updated on code
FFDirection:            db      0                                       ; Used by FFenemy to indicate current direction
EnemyBlockOffset:       dw      0                                       ; Used to store current enemy block offset - Updated in code
EnemyBlockXY:           dw      0                                       ; Used to store current enemy block XY - Updated in code
EnemyBlockUpdated:      dw      0                                       ; Used to store updated enemy block position - Updated in code

; Queue Variables used by FF
QueueStart:             dw      0
QueueEnd:               dw      0
; Note: Queue used for FF and also palette fade routine
Queue:                  DS      (BlockTileMapWidthDisplay*BlockTileMapHeightDisplay)*2;300;FFSize*FFSize
; - Table to provide block offset when movement changed (values added) - Referenced via %0000UDLR
; Words used as adding to word value
EnemyBlockUpdateTable:
BlockNone:              dw      0       ; Not used
BlockRight:             dw      1
BlockLeft:              dw      -1
BlockLeftRight:         dw      0       ; Not used
BlockDown:              dw      BlockTileMapWidth
BlockDownRight:         dw      BlockTileMapWidth+1
BlockDownLeft:          dw      BlockTileMapWidth-1
BlockDownLeftRight:     dw      0       ; Not used
BlockUp:                dw      -BlockTileMapWidth
BlockUpRight:           dw      -BlockTileMapWidth+1
BlockUpLeft:            dw      -BlockTileMapWidth-1

;-------------------------------------------------------------------------------------
; Locker/Collectable Data
LockerEnergyStartPattern:               EQU     119     ; Sprite pattern for locker
LockerEnergyEndPattern:                 EQU     120     ; Sprite pattern for locker
LockerFreezeStartPattern:               EQU     57      ; Sprite pattern for locker
LockerFreezeEndPattern:                 EQU     58      ; Sprite pattern for locker
LockerBulletsPattern:                   EQU     114     ; No longer used
LockerCollectableEnergyStartPattern:    EQU     122     ; Sprite pattern for collectable
LockerCollectableEnergyEndPattern:      EQU     123     ; Sprite pattern for collectable
LockerCollectableFreezeStartPattern:    EQU     60      ; Sprite pattern for collectable
LockerCollectableFreezeEndPattern:      EQU     61      ; Sprite pattern for collectable
;
LockerCollectableEnergy:                EQU     5       ; Energy awarded by locker collectable
LockerCollectableFreeze:                EQU     5       ; Freeze time awarded by locker collectable
LockerCollectibleSwitchDelay:           EQU     40      ; Number of frames to wait to allow switch key to be registered again
LockerCollectibleSwitchDelayCounter:    db      0       ; Counter - Set in code
;LockerToggleBullets:            EQU     5-1     ; Number of bullets required to toggle locker content (deduct 1 from desired value)
CollectableAlive:               EQU     255     ; Time between spawning and collectable being deleted
CollectableSpawnFrequency:      DB      0       ; Spawn collectable every x enemies destroyed - Configured via player data
CollectableSpawnCounter:        db      0       ; Count of enemies before spawning collectable - Set in code
CollectableEnergyThreshold:     equ     ReticuleMidEnergyThreshold      ; If player energy < threshold+1, energy collectable is spawned

;-------------------------------------------------------------------------------------
; HUD Data
; --- Keys
HUDKeyIconXY:                   EQU     $0101   ; xxyy for key icon
HUDKeyValueXY:                  EQU     $0201   ; xxyy for key value and background
HUDKeyValueDigits:              EQU     1       ; Number of digits in key value
HUDKeyValueSpriteNum:           db      0       ; Sprite number for left-most key sprite value - Set in code
; --- Save Point
HUDSavePointIconXY:             EQU     $0401   ; xxyy for Save point icon
HUDSavePointValueXY:            EQU     $0501   ; xxyy for Save point value and background
HUDSavePointValueDigits:        EQU     1       ; Number of digits in Save point value
HUDSavePointIconSprite:         dw      0       ; Sprite reference for Save point sprite value - Set in code
HUDSavePointValueSpriteNum:     db      0       ; Sprite number for left-most Save point sprite value - Set in code
; --- Energy
HUDEnergyIconXY:                EQU     $0801   ; xxyy for energy icon
HUDEnergyValueXY:               EQU     $0901   ; xxyy for energy value and background
HUDEnergyValueDigits:           EQU     2;3       ; Number of digits in energy value
HUDEnergyValueSpriteNum:        db      0       ; Sprite number for left-most energy sprite value - Set in code
; --- Score
HUDScoreValueXY:                EQU     $0d02   ; xxyy for score value and background
HUDScoreValueDigits:            EQU     6;3     ; Number of digits in score value
HUDScoreValueSpriteNum:         db      0       ; Sprite number for left-most score sprite value - Set in code
; --- Hi-Score
HUDHiScoreValueXY:              EQU     $0d01   ; xxyy for score value and background
HUDHiScoreValueDigits:          EQU     6;3     ; Number of digits in score value
HUDHiScoreValueSpriteNum:       db      0       ; Sprite number for left-most score sprite value - Set in code
; --- Freeze
ReticuleFreezeValueX1Offset:    EQU     0       ; X digit1 Offset relative to reticule anchor sprite
ReticuleFreezeValueX2Offset:    EQU     8      ; X digit2 Offset relative to reticule anchor sprite
ReticuleFreezeValueYOffset:     EQU     16      ; Y Offset relative to reticule anchor sprite
ReticuleFreezeValueDigits:      EQU     2       ; Number of digits in freeze value
ReticuleFreezeValueSpriteNum:   db      0       ; Sprite number for left-most freeze sprite value - Set in code
;HUDFreezeIconXY:                EQU     $0b01   ; xxyy for freeze icon
;HUDFreezeValueXY:               EQU     $0c01   ; xxyy for freeze value and background
;HUDFreezeValueSpriteNum:        db      0       ; Sprite number for left-most freeze sprite value - Set in code
; --- Pause
PauseIconXY:                    EQU     $0806   ; xxyy for pause icon
PauseValueSpriteNum:            db      0       ; Sprite number for pause sprite value - Set in code
; --- Common
HUDSpriteDigit0Pattern:         EQU     114      ; Pattern for sprite digit 0
HUDSpriteDigit1Pattern:         EQU     51     ; Pattern for sprite digit 1
SpriteString:                   defb    "000000", 0 ; Used to temporarily hold converted integer to string e.g. Freeze time
SpriteString2:                  defb    "00", 0 ; Used to temporarily hold converted integer to string e.g. Freeze time

;-------------------------------------------------------------------------------------
; Other Data
TotalFrames:                    dd      0       ; Use for counting total frames
;NonFFFrameCount:                db      0       ; Use for counting frames before performing NonFF routine - Set in code
;NonFFFrameDelay:                equ     100      ; Number of frames to wait between performing NonFF routine
CycleTMColourDelay:             equ     20      ; Number of frames to wait before cycling tilemap colours
CycleTMColourDelayCounter:      db      0       ; Frame counter - Set in code
CurrentTileMapPal:              db      0       ; Current tilemap palette, used for switching back after freeze
FreezeTileMapPal:               EQU     3       ; Tilemap palette when freeze selected
WaitForScanLineVideo:           EQU     207     ; Scanline to wait for
PlayerInput:                    db      0       ; PFBSUDLR (SPAWNPOINT, FREEZE, BULLET, SWITCH, UP, DOWN, LEFT, RIGHT) - Set in code
PlayerInputOriginal:            db      0       ; PFBSUDLR (SPAWNPOINT, FREEZE, BULLET, SWITCH, UP, DOWN, LEFT, RIGHT) - Set in code
                                                ; Original PlayerInput value upchanged by collision checks - Set in code 
PlayerInput2:                   db      0       ; Double-Tap - Previous frame value for PlayerInput; used for double-tap - Set in code
PlayerInputDelay:               equ     5       ; Double-Tap - Delay before checking for second tap
PlayerInputDelayCounter:        db      0       ; Double-Tap - Counter for PlayerInputDelay - Set in code
;StrafeCountdownStart:           equ     10      ; Double-Tap - Start countdown value - Top Threshold for tap-2 check
;StrafeCountDownEnd:             equ     7       ; Double-Tap - End countdown value - Bottom Threshold for tap-2 check
;StrafeCountDownCounter:         db      0       ; Double-Tap - Used for countdown when toggling strafe - Set in code
;StrafeEnabled:                  db      0       ; Double-Tap - Used to enable/disable strafe - Set in code
PlayerAt16Position:             db      0       ; Used to store result of divisible by 16 routine

PlayerDamage:                   db      0       ; Player - Indicates player should take damage - Set in code
FriendlyInLevel:                db      0       ; Calculated as friendly spawned - Set in code
FriendlyTotalRescued:           db      0       ; Number of friendly rescued by player - Set in code
FriendlyDamageDelay:            equ     50      ; Delay before activated friendly takes damage 
;FriendlyKeyType                 equ     Key1SprType     ; Key type spawned by rescued friendly
MaxPlayerEnergy:                db      0       ; Set via Tiled
PlayerDamageDelay:              equ     30      ; Delay before player takes damage after taking damage
PlayerDamageDelayCounter:       db      0       ; Set in code
;PlayerAnimationDelay:           db      6, 5, 4, 3, 2, 2, 1, 1, 1, 0, 0       ; Used to map player energy to animation delay
                                                                                ; More energy = lower animation delay
RandomNumberSeed:               db      10      ; Random number speed - Updated in code

;-------------------------------------------------------------------------------------
; Save Points
SavePointCreditFriendly:        db      0       ; Number of friendly to rescue for granting Save point credit - Configured from player Tiled data
SavePointCreditFriendlyCounter: db      0       ; Counter for Save point credits - Updated in code
SavePointCredits:               db      0       ; Player credits for rescuing friendly - Updated in code
SavePointDisabledBlock:         equ     49      ; Tile number of disabled Save point (non-activated)
SavePointEnabledBlock:          equ     50      ; Tile number of enabled Save point (non-activated)
; - Saved Values
SavePointSavedBlockOffset:      dw      0       ; Saved Save Point block offset - Set in code
SavePointSavedPlayerEnergy:     db      0       ; Saved Save Point Player Energy - Set in code
SavePointSavedPlayerFreeze:     db      0       ; Saved Save Point Player Freeze time - Set in code
SavePointOldBlock:              db      0       ; Original tile reference where Save point is created - Set in code 
SavedPointReticulePattern:      dw      0       ; Player Reticule pattern
; - Saved Scroll Values
SavePointScrollTileMapBlockXPointer:    db      0       ; Target - Set in code
SavePointScrollTileMapBlockYPointer:    db      0       ; Target - Set in code
SavePointScrollComplete:                db      0        ; Target - Scroll operation complete %------XY
SavePointKeyDelay:              EQU     20              ; Number of frames to wait to savepoint key to be registered again
SavePointKeyDelayCounter:       db      0               ; Counter - Set in code

;-------------------------------------------------------------------------------------
; Level Intro Settings
; - Sprite Text Settings
ASCIIDelta:                     equ     32      ; Value at which ASCII characters start i.e. Space
; Test Format - y, x , <Text>, 0
; - y block positions - (0 to 15)
; - x block positions - (0 to 19)
; - <Text> - Ensure all uppercase
; Standard Level Text
LevelNumberText:        db      2, 2, "LEVEL", 0  
LevelNumberValueXY:     equ     $0e02           ; Block position for calculated value
; - Level Intro Text
LevelFriendlyText:      db      6, 3, "RESCUE    X", 0
LevelFriendlyValueXY:   equ     $0a06           ; Block position for calculated value
LevelFriendlySpriteXY:  equ     $0f06           ; Block position for sprite
LevelSavePointCreditText:       db      8, 2, "SAVEPOINT CREDIT", 0
LevelSavePointCreditText2:      db      9, 4, "EVERY    X", 0
LevelModeEasyText:              db      11, 5, "MODE: EASY", 0
LevelModeHardText:              db      11, 5, "MODE: HARD", 0
LevelSavePointCreditValueXY:    equ     $0a09   ; Block position for calculated value
LevelSavePointCreditSpriteXY:   equ     $0f09   ; Block position for sprite
LevelClickToStartText:          db      13, 4, "PLAY     EXIT", 0
LevelStartMouseSprite1XY:       equ     $030d   ; Block position for sprite
LevelStartMouseSprite2XY:       equ     $0c0d   ; Block position for sprite
LevelCompletetMouseSprite1XY:   equ     $020e   ; Block position for sprite
LevelCompletetMouseSprite2XY:   equ     $0d0e   ; Block position for sprite
LevelClickToResumeText:         db      14, 3, "CONTINUE   EXIT", 0
; - Level Complete Text
LevelCompleteText1:             db      6, 1, "COMPLETED", 0
LevelCompleteText2:             db      9, 5, "NEXT LEVEL", 0
LevelCompleteText3:             db      11, 6, "UNLOCKED", 0
; - Game Complete Text
GameCompleteText1:             db      6, 1, "WELL DONE", 0
GameCompleteText2:             db      9, 3, "GAME COMPLETED", 0
GameCompleteText3:             db      10, 1, "NOW TRY HARD MODE!", 0
GameCompleteText4:             db      10, 2, "ON HARD MODE!!!!", 0

; - Level GameOver Text
LevelGameOverText:              db      6, 1, "GAME OVER", 0;2, 1, "GAME OVER", 0
LevelGameOverFriendlyText1:     db      9, 6, "RESCUED", 0
LevelGameOverFriendlyText2:     db      11, 4, "   X   OF", 0
LevelGameOverRescuedValueXY:   equ     $040b           ; Block position for calculated value
LevelGameOverFriendlySpriteXY: equ     $090b           ; Block position for sprite
LevelGameOverFriendlyValueXY:  equ     $0e0b           ; Block position for calculated value
LevelMenuMouseSprite1XY:       equ     $070e           ; Block position for sprite
LevelClickForMenuText:         db      14, 8, "EXIT", 0

; - Tilemap
LevelIntroTileMapData:          equ     $6000   ; Address of LevelIntro tilemap common to all levels
LevelIntroTileMapWidth:         equ     20      ; Maximum width for level intro tilemap
LevelIntroTileMapHeight:        equ     16      ; Maximum height for level intro tilemap
; - Palette Cycle
LevelIntroCycleDelayBetweenCycles:      equ     75      ; Frame delay between complete cycles
LevelIntroCycleColours:                 equ     7       ; Colours for complete cycle
LevelIntroCycleDelayBetweenFrames:      equ     10      ; Frame delay within cycle
LevelCompleteCycleDelayBetweenCycles:   equ     75;150      ; Frame delay between complete cycles
LevelFadeInFrameDelay:                  equ     3       ; 50/<value> = Frames per Second --> Number of frames to wait when fading in palette
LevelFadeOutFrameDelay:                 equ     5      ; 50/<value> = Frames per Second --> Number of frames to wait when fading out palette

;-------------------------------------------------------------------------------------
; Audio
;-------------------------------------------------------------------------------------
;
; NextDAW
NextDAW:		equ     $8000		        ; Driver code address
NextDAW_InitSong:	equ     NextDAW + $00	        ; Initialize/set song to play
NextDAW_UpdateSong:	equ     NextDAW + $03	        ; Call once per frame (NextDAW will auto update at either 50Hz or 60Hz, depending on the Next's configuration)
NextDAW_PlaySong:	equ     NextDAW + $06	        ; Start song
NextDAW_StopSong:       equ     NextDAW + $09	        ; Stop song - update must still be called each frame as the notes will not release otherwise
NextDAW_StopSongHard:	equ     NextDAW + $0C	        ; Stop song and cut off voices immediately
NextDAW_UpdateSongNoAY  equ	NextDAW + $0f
NextDAW_UpdateAY	equ	NextDAW + $12
NextDAW_InitSystem	equ	NextDAW + $15	
NextDAW_InitSFXBank	equ	NextDAW + $18
NextDAW_PlaySFX		equ	NextDAW + $1b
NextDAW_UpdateSFX	equ	NextDAW + $1e	        ; Call once per frame
NextDAW_GetPSGDataPtr	equ	NextDAW + $21
NextDAW_EnablePSGWrite	equ	NextDAW + $24 	        ; a: 0 = disable, 1 = enable
;SongDataPages:          defb    $$Song1, $$Song1+1      ; Memory banks containing music data
SongDataPages:          defb    $$Song1, $$Song1+1      ; Memory banks containing music data
; AYFX
afx3ChDescCount  equ 3
afx3ChDesc       DS afx3ChDescCount*8
AFX3SMC    	 equ 0
afx2ChDescCount  equ 3
afx2ChDesc       DS afx2ChDescCount*8
AFX2SMC    	 equ 0
afx1ChDescCount  equ 3
afx1ChDesc       DS afx1ChDescCount*8
AFX1SMC    	 equ 0

; -- AyFX bank for game sound effects
AyFXBankGame:   incbin  "webster/assets/audio/Game.afb"
; 26/01/24 - Not required
;/*
AyFXFrameSkipValue:     db      0       ; Number of frames before skipping play - Set in code
AyFXFrameSkipCounter:   db      0       ; Number of frames before skipping play - Set in code
AyFXFrameSkip50mhz:     equ     99      ; 50mhz -- 99 indicates don't skip frames
AyFXFrameSkip60mhz:     equ     6       ; 60mhz -- Skip every 6 frames
;*/

; Effects map to AY Sound FX Editor
AyFXPlayerBullet:       equ     1       ; AY 3
AyFXTriggerTarget:      equ     0       ; AY 1
AyFXDoorOpen:           equ     2       ; AY 1
AyFXEnemyDestroyed:     equ     3       ; AY 3
AyFXSpawnPointEnabled:  equ     4       ; AY 2
AyFXSpawnPointDisabled: equ     5       ; AY 2
AyFXPickupCollLockKey:  equ     6       ; AY 2
AyFXSpawnEnemy:         equ     7       ; AY 2
AyFXFriendlyEnable:     equ     8       ; AY 2
AyFXFriendlyDisable:    equ     9       ; AY 2
AyFXFriendlyRescued:    equ     10      ; AY 2
AyFXTerminatorDisabled: equ     11      ; AY 2

AyFXEnemyShooterBullet: equ     12      ; AY 2
AyFXEnemyWayBullet:     equ     18      ; AY 2
AyFXEnemyTurretBullet:  equ     19      ; AY 2

AyFXTurretDisabled:     equ     13      ; AY 2
AyFXTurretEnabled:      equ     14      ; AY 2
AyFXTerminatorEnabled:  equ     14      ; AY 2
AyFXPlayerHit:          equ     15      ; AY 2
AyFXPlayerSpawnFinish:  equ     16      ; AY 3
AyFXPlayerDestroyed:    equ     17      ; AY 3
AyFXSavepointActivated: equ     20      ; AY 2
AyFXFreezeActivated:    equ     21      ; AY 2
AyFXFreezeNone:         equ     22      ; AY 2
AyFXBulletUpgradeChA:   equ     23      ; AY 1
AyFXBulletUpgradeChB:   equ     24      ; AY 3
AyFXAllRescuedChA:      equ     25      ; AY 1
AyFXAllRescuedChB:      equ     26      ; AY 3

;-------------------------------------------------------------------------------------
; Level Data
        include "webster/LevelData.asm"

EndOfData:

;-------------------------------------------------------------------------------------
; Memory Bank Data
;
;-------------------------------------------------------------------------------------
; Sprite Data - Common (unless different sprites required per level)
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3 n, 28    ; Slot 3 = $6000..$7FFF, "n" option to wrap (around slot 3) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include sprite data
        ORG     $6000
SpriteSet1:
; A total number of 64 sprite patterns (4bit) will be loaded (8kb)
        INCBIN  "webster/assets/Sprites4bit1.spr",,64*128  ; Number of 4bit sprites * 128 bytes
SpriteSet2:
        INCBIN  "webster/assets/Sprites4bit2.spr",,64*128  ; Number of 4bit sprites * 128 bytes
SpriteText:
        INCBIN  "webster/assets/SpritesText4bit.spr",,64*128  ; Number of 4bit sprites * 128 bytes

;-------------------------------------------------------------------------------------
; Palette Data - Sprites + Tilemaps
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3 n, $$SpriteText + 1       ; Slot 3 = $6000..$7FFF, "n" option to wrap (around slot 3) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include sprite data
        ORG     $6000
; --- Sprite Palette
PaletteData:
SpritePalette:
        INCBIN  "webster/assets/sprites.pal"
SpriteTextPalette:
        INCBIN  "webster/assets/spritestext.pal"

; --- Tilemap Palettes
TileMapDefPalRows:      equ     4
TileMapDefPalSize:      equ     TileMapDefPalRows*32;255         ; Per palette size
; Note:   4 (rows within palette) * 32 bytes (16 colours per row * 2) -- Need to x 2 as each colour is stored in 2 x bytes
TileMapDefPal1:
        INCBIN "webster/assets/Tiles1.pal",,TileMapDefPalSize      
TileMapDefPal2:
        INCBIN "webster/assets/Tiles2.pal",,TileMapDefPalSize      
TileMapDefPal3:
        INCBIN "webster/assets/Tiles3.pal",,TileMapDefPalSize      
TileMapDefPal4:
        INCBIN "webster/assets/Tiles4.pal",,TileMapDefPalSize      

;-------------------------------------------------------------------------------------
; Tilemap Definitions
; Notes: Tilemap data in different memory bank
TileMapDefBlocks:       equ     64              ; Blocks start from 0, so a value of 10 would upload blocks 0-9
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     7 n, $$PaletteData + 1    ; Slot 7 = $E000..$FFFF, "n" option to wrap (around slot 7) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 7 memory address and include tilemap definition data
        ORG     $E000
TileMapDefSource:
TileMapDef1:
; A total number of 64 block definitions (4 x tile defs/block=252 tile defs) will be loaded (8kb)
        INCBIN  "webster/assets/Tiles1.til",,TileMapDefBlocks*128 ; Number of blocks * 128 bytes
TileMapDef2:
; A total number of 64 block definitions (4 x tile defs/block=252 tile defs) will be loaded (8kb)
        INCBIN  "webster/assets/Tiles2.til",,TileMapDefBlocks*128 ; Number of blocks * 128 bytes
TileMapDef3:
; A total number of 64 block definitions (4 x tile defs/block=252 tile defs) will be loaded (8kb)
        INCBIN  "webster/assets/Tiles3.til",,TileMapDefBlocks*128 ; Number of blocks * 128 bytes
TileMapDef4:
; A total number of 64 block definitions (4 x tile defs/block=252 tile defs) will be loaded (8kb)
        INCBIN  "webster/assets/Tiles4.til",,TileMapDefBlocks*128 ; Number of blocks * 128 bytes

;-------------------------------------------------------------------------------------
; Tilemap Data - Level 1
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$TileMapDef4 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData1:
; Note: When scrolling don't place anything on the top/bottom lines, and the left/right columns
; as these lines/columns will not be displayed when scrolling
; Contains block references and not individual 8x8 characters
; The file is created using the TileMapLayersToZ80BIN.py script using tile layer data exported from the Tiled utility
; -- Byte1 - LevelScrollWidth
; -- Byte2 - LevelScrollHeight
; -- Background layer - Contains background tiles (visible)
                        INCBIN  "webster/assets/Level1-3Intro-TileMap.bin"
TileMapDataLevel1:      INCBIN  "webster/assets/Level1-TileMap.bin"        
L2DataLevel1:           INCBIN  "webster/assets/LevelTileset1-L2.nxi"
L2PaletteDataLevel1:    INCBIN  "webster/assets/LevelTileset1-L2.nxp"
Level1Data      S_LEVEL_DATA {
                $$TileMapDef1,                  ; Memory bank hosting tilemap definition data
                TileMapDefPal1,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel1,              ; Link to TileMap data
                PlayerDataLevel1,               ; Link to Player data
                WayPointsLevel1,                ; Link to number of WayPoints
                WayPointDataLevel1,             ; Link to WayPoint data
                SpawnPointsLevel1,              ; Link to number of SpawnPoints
                SpawnPointDataLevel1,           ; Link to SpawnPoint data
                FriendlysLevel1,                ; Link to number of Friendly
                FriendlyDataLevel1,             ; Link to Friendly data
                KeysLevel1,                     ; Link to number of Keys
                KeyDataLevel1,                  ; Link to Key data
                TurretsLevel1,                  ; Link to number of Turrets
                TurretDataLevel1,               ; Link to Turret data
                HazardsLevel1,                  ; Link to number of Hazards
                HazardDataLevel1,               ; Link to Hazard data
                LockersLevel1,                  ; Link to number of Lockers
                LockerDataLevel1,               ; Link to Locker data
                TriggerSourceLevel1,            ; Link to number of TriggerSource
                TriggerSourceDataLevel1,        ; Link to TriggerSource data
                TriggerTargetLevel1,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel1         ; Link to TriggerTarget data
                L2DataLevel1                    ; Link to L2 background data
                L2PaletteDataLevel1             ; Link to L2 background data
                }         

; Player data
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; The player data consists of data as per S_PLAYER_DATA
; Note: Update Python script if S_PLAYER_DATA changes or vice-versa
PlayerDataLevel1:       INCLUDE "webster/assets/Level1-Player.asm"

; Waypoint data used by enemies
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each waypoint within the file consists of data as per S_WAYPOINT_DATA
; Note: Update Python script if S_WAYPOINT_DATA changes or vice-versa
WayPointsLevel1:                equ     (WayPointDataEndLevel1-WayPointDataStartLevel1)/S_WAYPOINT_DATA
WayPointDataLevel1:
WayPointDataStartLevel1:        INCLUDE "webster/assets/Level1-Waypoints.asm"
WayPointDataEndLevel1:

; SpawnPoint data used by enemies
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each spawnpoint within the file consists of data as per S_SPAWNPOINT_DATA
; Note: Update Python script if S_SPAWNPOINT_DATA changes or vice-versa
; Note: At runtime SpawnPointSourceData copied to SpawnPointData which is then used as operational data  
; Note: MaxSpawnPoints indicates max amount of spawnpoints that can be created
SpawnPointsLevel1:      equ     (SpawnPointDataEnd1-SpawnPointDataStart1)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel1:
SpawnPointDataStart1:   INCLUDE "webster/assets/Level1-SpawnPoints.asm"
SpawnPointDataEnd1:

; Friendly data for spawning friendly sprites
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each friendly within the file consists of data as per S_FRIENDLY_DATA
; Note: Update Python script if S_FRIENDLY_DATA changes or vice-versa
; Note: MaxFriendly indicates max amount of friendly sprites that can be created
FriendlysLevel1:        equ     (FriendlyDataEnd1-FriendlyDataStart1)/S_FRIENDLY_DATA
FriendlyDataLevel1:
FriendlyDataStart1:     INCLUDE "webster/assets/Level1-Friendly.asm"
FriendlyDataEnd1:

; Key data for spawning key sprites
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each key within the file consists of data as per S_KEY_DATA
; Note: Update Python script if S_KEY_DATA changes or vice-versa
; Note: MaxKeys indicates max amount of keys sprites that can be created
KeysLevel1:     equ     (KeyDataEnd1-KeyDataStart1)/S_KEY_DATA
KeyDataLevel1:
KeyDataStart1:  INCLUDE "webster/assets/Level1-Keys.asm"
KeyDataEnd1:

; Turret data for spawning turret sprites
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each turret within the file consists of data as per S_TURRET_DATA
; Note: Update Python script if S_TURRET_DATA changes or vice-versa
; Note: MaxEnemies indicates max amount of enemy sprites that can be created
TurretsLevel1:          equ     (TurretDataEnd1-TurretDataStart1)/S_TURRET_DATA
TurretDataLevel1:
TurretDataStart1:       INCLUDE "webster/assets/Level1-Turrets.asm"
TurretDataEnd1:

; Hazard data hazard blocks
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each hazard block within the file consists of data as per S_HAZARD_DATA
; Note: MaxHazards indicates max amount of hazards that can be created
; Note: Update Python script if S_HAZARD_DATA changes or vice-versa
HazardsLevel1:          equ     (HazardDataEnd1-HazardDataStart1)/S_HAZARD_DATA
HazardDataLevel1:
HazardDataStart1:       INCLUDE "webster/assets/Level1-Hazards.asm"
HazardDataEnd1:

; Locker data for spawning locker sprites
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each locker within the file consists of data as per S_LOCKER_DATA
; Note: Update Python script if S_LOCKER_DATA changes or vice-versa
LockersLevel1:          equ     (LockerDataEnd1-LockerDataStart1)/S_LOCKER_DATA
LockerDataLevel1:
LockerDataStart1:       INCLUDE "webster/assets/Level1-Lockers.asm"
LockerDataEnd1:

; Trigger data for managing trigger events e.g. Opening locked doors
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each TriggerSource within the file consists of data as per S_TRIGGERSOURCE_DATA
; Note: Update Python script if S_TRIGGERSOURCE_DATA changes or vice-versa
TriggerSourceLevel1:            equ     (TriggerSourceDataEnd1-TriggerSourceDataStart1)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel1:
TriggerSourceDataStart1:        INCLUDE "webster/assets/Level1-TriggerSource.asm"
TriggerSourceDataEnd1:

; Trigger data for managing trigger events e.g. Opening locked doors
; The file is created using the ObjectsToZ80ASM.py script using objectmap data exported from the Tiled utility
; Each TriggerSource within the file consists of data as per S_TRIGGERTARGET_DATA
; Note: Update Python script if S_TRIGGERTARGET_DATA changes or vice-versa
TriggerTargetLevel1:            equ     (TriggerTargetDataEnd1-TriggerTargetDataStart1)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel1:
TriggerTargetDataStart1:        INCLUDE "webster/assets/Level1-TriggerTarget.asm"
TriggerTargetDataEnd1:

;-------------------------------------------------------------------------------------
; Tilemap Data - Level 2
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData1 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData2:
                        INCBIN  "webster/assets/Level1-3Intro-TileMap.bin"
TileMapDataLevel2:      INCBIN  "webster/assets/Level2-TileMap.bin"
L2DataLevel2:           INCBIN  "webster/assets/LevelTileset1-L2.nxi"
L2PaletteDataLevel2:    INCBIN  "webster/assets/LevelTileset1-L2.nxp"
Level2Data  S_LEVEL_DATA {
                $$TileMapDef1                   ; Memory bank hosting tilemap definition data
                TileMapDefPal1,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel2,              ; Link to TileMap data
                PlayerDataLevel2,               ; Link to Player data
                WayPointsLevel2,                ; Link to number of WayPoints
                WayPointDataLevel2,             ; Link to WayPoint data
                SpawnPointsLevel2,              ; Link to number of SpawnPoints
                SpawnPointDataLevel2,           ; Link to SpawnPoint data
                FriendlysLevel2,                ; Link to number of Friendly
                FriendlyDataLevel2,             ; Link to Friendly data
                KeysLevel2,                     ; Link to number of Keys
                KeyDataLevel2,                  ; Link to Key data
                TurretsLevel2,                  ; Link to number of Turrets
                TurretDataLevel2,               ; Link to Turret data
                HazardsLevel2,                  ; Link to number of Hazards
                HazardDataLevel2,               ; Link to Hazard data
                LockersLevel2,                  ; Link to number of Lockers
                LockerDataLevel2,               ; Link to Locker data
                TriggerSourceLevel2,            ; Link to number of TriggerSource
                TriggerSourceDataLevel2,        ; Link to TriggerSource data
                TriggerTargetLevel2,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel2         ; Link to TriggerTarget data
                L2DataLevel2:                   ; Link to L2 background data
                L2PaletteDataLevel2             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel2:       INCLUDE "webster/assets/Level2-Player.asm"

; Waypoint data used by enemies
WayPointsLevel2:                equ     (WayPointDataEndLevel2-WayPointDataStartLevel2)/S_WAYPOINT_DATA
WayPointDataLevel2:
WayPointDataStartLevel2:        INCLUDE "webster/assets/Level2-Waypoints.asm"
WayPointDataEndLevel2:

; SpawnPoint data used by enemies
SpawnPointsLevel2:      equ     (SpawnPointDataEnd2-SpawnPointDataStart2)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel2:
SpawnPointDataStart2:   INCLUDE "webster/assets/Level2-SpawnPoints.asm"
SpawnPointDataEnd2:

; Friendly data for spawning friendly sprites
FriendlysLevel2:        equ     (FriendlyDataEnd2-FriendlyDataStart2)/S_FRIENDLY_DATA
FriendlyDataLevel2:
FriendlyDataStart2:     INCLUDE "webster/assets/Level2-Friendly.asm"
FriendlyDataEnd2:

; Key data for spawning key sprites
KeysLevel2:     equ     (KeyDataEnd2-KeyDataStart2)/S_KEY_DATA
KeyDataLevel2:
KeyDataStart2:  INCLUDE "webster/assets/Level2-Keys.asm"
KeyDataEnd2:

; Turret data for spawning turret sprites
TurretsLevel2:          equ     (TurretDataEnd2-TurretDataStart2)/S_TURRET_DATA
TurretDataLevel2:
TurretDataStart2:       INCLUDE "webster/assets/Level2-Turrets.asm"
TurretDataEnd2:

; Hazard data hazard blocks
HazardsLevel2:          equ     (HazardDataEnd2-HazardDataStart2)/S_HAZARD_DATA
HazardDataLevel2:
HazardDataStart2:       INCLUDE "webster/assets/Level2-Hazards.asm"
HazardDataEnd2:

; Locker data for spawning locker sprites

LockersLevel2:          equ     (LockerDataEnd2-LockerDataStart2)/S_LOCKER_DATA
LockerDataLevel2:
LockerDataStart2:       INCLUDE "webster/assets/Level2-Lockers.asm"
LockerDataEnd2:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel2:            equ     (TriggerSourceDataEnd2-TriggerSourceDataStart2)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel2:
TriggerSourceDataStart2:        INCLUDE "webster/assets/Level2-TriggerSource.asm"
TriggerSourceDataEnd2:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel2:            equ     (TriggerTargetDataEnd2-TriggerTargetDataStart2)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel2:
TriggerTargetDataStart2:        INCLUDE "webster/assets/Level2-TriggerTarget.asm"
TriggerTargetDataEnd2:

;-------------------------------------------------------------------------------------
; Tilemap Data - Level 3
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData2 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData3:
                        INCBIN  "webster/assets/Level1-3Intro-TileMap.bin"
TileMapDataLevel3:      INCBIN  "webster/assets/Level3-TileMap.bin"
L2DataLevel3:           INCBIN  "webster/assets/LevelTileset1-L2.nxi"
L2PaletteDataLevel3:    INCBIN  "webster/assets/LevelTileset1-L2.nxp"
Level3Data  S_LEVEL_DATA {
                $$TileMapDef1                   ; Memory bank hosting tilemap definition data
                TileMapDefPal1,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel3,              ; Link to TileMap data
                PlayerDataLevel3,               ; Link to Player data
                WayPointsLevel3,                ; Link to number of WayPoints
                WayPointDataLevel3,             ; Link to WayPoint data
                SpawnPointsLevel3,              ; Link to number of SpawnPoints
                SpawnPointDataLevel3,           ; Link to SpawnPoint data
                FriendlysLevel3,                ; Link to number of Friendly
                FriendlyDataLevel3,             ; Link to Friendly data
                KeysLevel3,                     ; Link to number of Keys
                KeyDataLevel3,                  ; Link to Key data
                TurretsLevel3,                  ; Link to number of Turrets
                TurretDataLevel3,               ; Link to Turret data
                HazardsLevel3,                  ; Link to number of Hazards
                HazardDataLevel3,               ; Link to Hazard data
                LockersLevel3,                  ; Link to number of Lockers
                LockerDataLevel3,               ; Link to Locker data
                TriggerSourceLevel3,            ; Link to number of TriggerSource
                TriggerSourceDataLevel3,        ; Link to TriggerSource data
                TriggerTargetLevel3,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel3         ; Link to TriggerTarget data
                L2DataLevel3                    ; Link to L2 background data
                L2PaletteDataLevel3             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel3:       INCLUDE "webster/assets/Level3-Player.asm"

; Waypoint data used by enemies
WayPointsLevel3:                equ     (WayPointDataEndLevel3-WayPointDataStartLevel3)/S_WAYPOINT_DATA
WayPointDataLevel3:
WayPointDataStartLevel3:        INCLUDE "webster/assets/Level3-Waypoints.asm"
WayPointDataEndLevel3:

; SpawnPoint data used by enemies
SpawnPointsLevel3:      equ     (SpawnPointDataEnd3-SpawnPointDataStart3)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel3:
SpawnPointDataStart3:   INCLUDE "webster/assets/Level3-SpawnPoints.asm"
SpawnPointDataEnd3:

; Friendly data for spawning friendly sprites
FriendlysLevel3:        equ     (FriendlyDataEnd3-FriendlyDataStart3)/S_FRIENDLY_DATA
FriendlyDataLevel3:
FriendlyDataStart3:     INCLUDE "webster/assets/Level3-Friendly.asm"
FriendlyDataEnd3:

; Key data for spawning key sprites
KeysLevel3:     equ     (KeyDataEnd3-KeyDataStart3)/S_KEY_DATA
KeyDataLevel3:
KeyDataStart3:  INCLUDE "webster/assets/Level3-Keys.asm"
KeyDataEnd3:

; Turret data for spawning turret sprites
TurretsLevel3:          equ     (TurretDataEnd3-TurretDataStart3)/S_TURRET_DATA
TurretDataLevel3:
TurretDataStart3:       INCLUDE "webster/assets/Level3-Turrets.asm"
TurretDataEnd3:

; Hazard data hazard blocks
HazardsLevel3:          equ     (HazardDataEnd3-HazardDataStart3)/S_HAZARD_DATA
HazardDataLevel3:
HazardDataStart3:       INCLUDE "webster/assets/Level3-Hazards.asm"
HazardDataEnd3:

; Locker data for spawning locker sprites

LockersLevel3:          equ     (LockerDataEnd3-LockerDataStart3)/S_LOCKER_DATA
LockerDataLevel3:
LockerDataStart3:       INCLUDE "webster/assets/Level3-Lockers.asm"
LockerDataEnd3:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel3:            equ     (TriggerSourceDataEnd3-TriggerSourceDataStart3)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel3:
TriggerSourceDataStart3:        INCLUDE "webster/assets/Level3-TriggerSource.asm"
TriggerSourceDataEnd3:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel3:            equ     (TriggerTargetDataEnd3-TriggerTargetDataStart3)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel3:
TriggerTargetDataStart3:        INCLUDE "webster/assets/Level3-TriggerTarget.asm"
TriggerTargetDataEnd3:

;-------------------------------------------------------------------------------------
; Tilemap Data - Level 4
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData3 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData4:
                        INCBIN  "webster/assets/Level4-6Intro-TileMap.bin"
TileMapDataLevel4:      INCBIN  "webster/assets/Level4-TileMap.bin"
L2DataLevel4:           INCBIN  "webster/assets/LevelTileset2-L2.nxi"
L2PaletteDataLevel4:    INCBIN  "webster/assets/LevelTileset2-L2.nxp"
Level4Data  S_LEVEL_DATA {
                $$TileMapDef2                   ; Memory bank hosting tilemap definition data
                TileMapDefPal2,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel4,              ; Link to TileMap data
                PlayerDataLevel4,               ; Link to Player data
                WayPointsLevel4,                ; Link to number of WayPoints
                WayPointDataLevel4,             ; Link to WayPoint data
                SpawnPointsLevel4,              ; Link to number of SpawnPoints
                SpawnPointDataLevel4,           ; Link to SpawnPoint data
                FriendlysLevel4,                ; Link to number of Friendly
                FriendlyDataLevel4,             ; Link to Friendly data
                KeysLevel4,                     ; Link to number of Keys
                KeyDataLevel4,                  ; Link to Key data
                TurretsLevel4,                  ; Link to number of Turrets
                TurretDataLevel4,               ; Link to Turret data
                HazardsLevel4,                  ; Link to number of Hazards
                HazardDataLevel4,               ; Link to Hazard data
                LockersLevel4,                  ; Link to number of Lockers
                LockerDataLevel4,               ; Link to Locker data
                TriggerSourceLevel4,            ; Link to number of TriggerSource
                TriggerSourceDataLevel4,        ; Link to TriggerSource data
                TriggerTargetLevel4,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel4         ; Link to TriggerTarget data
                L2DataLevel4                    ; Link to L2 background data
                L2PaletteDataLevel4             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel4:       INCLUDE "webster/assets/Level4-Player.asm"

; Waypoint data used by enemies
WayPointsLevel4:                equ     (WayPointDataEndLevel4-WayPointDataStartLevel4)/S_WAYPOINT_DATA
WayPointDataLevel4:
WayPointDataStartLevel4:        INCLUDE "webster/assets/Level4-Waypoints.asm"
WayPointDataEndLevel4:

; SpawnPoint data used by enemies
SpawnPointsLevel4:      equ     (SpawnPointDataEnd4-SpawnPointDataStart4)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel4:
SpawnPointDataStart4:   INCLUDE "webster/assets/Level4-SpawnPoints.asm"
SpawnPointDataEnd4:

; Friendly data for spawning friendly sprites
FriendlysLevel4:        equ     (FriendlyDataEnd4-FriendlyDataStart4)/S_FRIENDLY_DATA
FriendlyDataLevel4:
FriendlyDataStart4:     INCLUDE "webster/assets/Level4-Friendly.asm"
FriendlyDataEnd4:

; Key data for spawning key sprites
KeysLevel4:     equ     (KeyDataEnd4-KeyDataStart4)/S_KEY_DATA
KeyDataLevel4:
KeyDataStart4:  INCLUDE "webster/assets/Level4-Keys.asm"
KeyDataEnd4:

; Turret data for spawning turret sprites
TurretsLevel4:          equ     (TurretDataEnd4-TurretDataStart4)/S_TURRET_DATA
TurretDataLevel4:
TurretDataStart4:       INCLUDE "webster/assets/Level4-Turrets.asm"
TurretDataEnd4:

; Hazard data hazard blocks
HazardsLevel4:          equ     (HazardDataEnd4-HazardDataStart4)/S_HAZARD_DATA
HazardDataLevel4:
HazardDataStart4:       INCLUDE "webster/assets/Level4-Hazards.asm"
HazardDataEnd4:

; Locker data for spawning locker sprites

LockersLevel4:          equ     (LockerDataEnd4-LockerDataStart4)/S_LOCKER_DATA
LockerDataLevel4:
LockerDataStart4:       INCLUDE "webster/assets/Level4-Lockers.asm"
LockerDataEnd4:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel4:            equ     (TriggerSourceDataEnd4-TriggerSourceDataStart4)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel4:
TriggerSourceDataStart4:        INCLUDE "webster/assets/Level4-TriggerSource.asm"
TriggerSourceDataEnd4:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel4:            equ     (TriggerTargetDataEnd4-TriggerTargetDataStart4)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel4:
TriggerTargetDataStart4:        INCLUDE "webster/assets/Level4-TriggerTarget.asm"
TriggerTargetDataEnd4:
;-------------------------------------------------------------------------------------
; Tilemap Data - Level 5
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData4 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData5:
                        INCBIN  "webster/assets/Level4-6Intro-TileMap.bin"
TileMapDataLevel5:      INCBIN  "webster/assets/Level5-TileMap.bin"
L2DataLevel5:           INCBIN  "webster/assets/LevelTileset2-L2.nxi"
L2PaletteDataLevel5:    INCBIN  "webster/assets/LevelTileset2-L2.nxp"
Level5Data  S_LEVEL_DATA {
                $$TileMapDef2                   ; Memory bank hosting tilemap definition data
                TileMapDefPal2,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel5,              ; Link to TileMap data
                PlayerDataLevel5,               ; Link to Player data
                WayPointsLevel5,                ; Link to number of WayPoints
                WayPointDataLevel5,             ; Link to WayPoint data
                SpawnPointsLevel5,              ; Link to number of SpawnPoints
                SpawnPointDataLevel5,           ; Link to SpawnPoint data
                FriendlysLevel5,                ; Link to number of Friendly
                FriendlyDataLevel5,             ; Link to Friendly data
                KeysLevel5,                     ; Link to number of Keys
                KeyDataLevel5,                  ; Link to Key data
                TurretsLevel5,                  ; Link to number of Turrets
                TurretDataLevel5,               ; Link to Turret data
                HazardsLevel5,                  ; Link to number of Hazards
                HazardDataLevel5,               ; Link to Hazard data
                LockersLevel5,                  ; Link to number of Lockers
                LockerDataLevel5,               ; Link to Locker dataLevel4
                TriggerSourceLevel5,            ; Link to number of TriggerSource
                TriggerSourceDataLevel5,        ; Link to TriggerSource data
                TriggerTargetLevel5,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel5         ; Link to TriggerTarget data
                L2DataLevel5                    ; Link to L2 background data
                L2PaletteDataLevel5             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel5:       INCLUDE "webster/assets/Level5-Player.asm"

; Waypoint data used by enemies
WayPointsLevel5:                equ     (WayPointDataEndLevel5-WayPointDataStartLevel5)/S_WAYPOINT_DATA
WayPointDataLevel5:
WayPointDataStartLevel5:        INCLUDE "webster/assets/Level5-Waypoints.asm"
WayPointDataEndLevel5:

; SpawnPoint data used by enemies
SpawnPointsLevel5:      equ     (SpawnPointDataEnd5-SpawnPointDataStart5)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel5:
SpawnPointDataStart5:   INCLUDE "webster/assets/Level5-SpawnPoints.asm"
SpawnPointDataEnd5:

; Friendly data for spawning friendly sprites
FriendlysLevel5:        equ     (FriendlyDataEnd5-FriendlyDataStart5)/S_FRIENDLY_DATA
FriendlyDataLevel5:
FriendlyDataStart5:     INCLUDE "webster/assets/Level5-Friendly.asm"
FriendlyDataEnd5:

; Key data for spawning key sprites
KeysLevel5:     equ     (KeyDataEnd5-KeyDataStart5)/S_KEY_DATA
KeyDataLevel5:
KeyDataStart5:  INCLUDE "webster/assets/Level5-Keys.asm"
KeyDataEnd5:

; Turret data for spawning turret sprites
TurretsLevel5:          equ     (TurretDataEnd5-TurretDataStart5)/S_TURRET_DATA
TurretDataLevel5:
TurretDataStart5:       INCLUDE "webster/assets/Level5-Turrets.asm"
TurretDataEnd5:

; Hazard data hazard blocks
HazardsLevel5:          equ     (HazardDataEnd5-HazardDataStart5)/S_HAZARD_DATA
HazardDataLevel5:
HazardDataStart5:       INCLUDE "webster/assets/Level5-Hazards.asm"
HazardDataEnd5:

; Locker data for spawning locker sprites

LockersLevel5:          equ     (LockerDataEnd5-LockerDataStart5)/S_LOCKER_DATA
LockerDataLevel5:
LockerDataStart5:       INCLUDE "webster/assets/Level5-Lockers.asm"
LockerDataEnd5:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel5:            equ     (TriggerSourceDataEnd5-TriggerSourceDataStart5)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel5:
TriggerSourceDataStart5:        INCLUDE "webster/assets/Level5-TriggerSource.asm"
TriggerSourceDataEnd5:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel5:            equ     (TriggerTargetDataEnd5-TriggerTargetDataStart5)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel5:
TriggerTargetDataStart5:        INCLUDE "webster/assets/Level5-TriggerTarget.asm"
TriggerTargetDataEnd5:
;-------------------------------------------------------------------------------------
; Tilemap Data - Level 6
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData5 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData6:
                        INCBIN  "webster/assets/Level4-6Intro-TileMap.bin"
TileMapDataLevel6:      INCBIN  "webster/assets/Level6-TileMap.bin"
L2DataLevel6:           INCBIN  "webster/assets/LevelTileset2-L2.nxi"
L2PaletteDataLevel6:    INCBIN  "webster/assets/LevelTileset2-L2.nxp"
Level6Data  S_LEVEL_DATA {
                $$TileMapDef2                   ; Memory bank hosting tilemap definition data
                TileMapDefPal2,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel6,              ; Link to TileMap data
                PlayerDataLevel6,               ; Link to Player data
                WayPointsLevel6,                ; Link to number of WayPoints
                WayPointDataLevel6,             ; Link to WayPoint data
                SpawnPointsLevel6,              ; Link to number of SpawnPoints
                SpawnPointDataLevel6,           ; Link to SpawnPoint data
                FriendlysLevel6,                ; Link to number of Friendly
                FriendlyDataLevel6,             ; Link to Friendly data
                KeysLevel6,                     ; Link to number of Keys
                KeyDataLevel6,                  ; Link to Key data
                TurretsLevel6,                  ; Link to number of Turrets
                TurretDataLevel6,               ; Link to Turret data
                HazardsLevel6,                  ; Link to number of Hazards
                HazardDataLevel6,               ; Link to Hazard data
                LockersLevel6,                  ; Link to number of Lockers
                LockerDataLevel6,               ; Link to Locker dataLevel4
                TriggerSourceLevel6,            ; Link to number of TriggerSource
                TriggerSourceDataLevel6,        ; Link to TriggerSource data
                TriggerTargetLevel6,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel6         ; Link to TriggerTarget data
                L2DataLevel6                    ; Link to L2 background data
                L2PaletteDataLevel6             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel6:       INCLUDE "webster/assets/Level6-Player.asm"

; Waypoint data used by enemies
WayPointsLevel6:                equ     (WayPointDataEndLevel6-WayPointDataStartLevel6)/S_WAYPOINT_DATA
WayPointDataLevel6:
WayPointDataStartLevel6:        INCLUDE "webster/assets/Level6-Waypoints.asm"
WayPointDataEndLevel6:

; SpawnPoint data used by enemies
SpawnPointsLevel6:      equ     (SpawnPointDataEnd6-SpawnPointDataStart6)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel6:
SpawnPointDataStart6:   INCLUDE "webster/assets/Level6-SpawnPoints.asm"
SpawnPointDataEnd6:

; Friendly data for spawning friendly sprites
FriendlysLevel6:        equ     (FriendlyDataEnd6-FriendlyDataStart6)/S_FRIENDLY_DATA
FriendlyDataLevel6:
FriendlyDataStart6:     INCLUDE "webster/assets/Level6-Friendly.asm"
FriendlyDataEnd6:

; Key data for spawning key sprites
KeysLevel6:     equ     (KeyDataEnd6-KeyDataStart6)/S_KEY_DATA
KeyDataLevel6:
KeyDataStart6:  INCLUDE "webster/assets/Level6-Keys.asm"
KeyDataEnd6:

; Turret data for spawning turret sprites
TurretsLevel6:          equ     (TurretDataEnd6-TurretDataStart6)/S_TURRET_DATA
TurretDataLevel6:
TurretDataStart6:       INCLUDE "webster/assets/Level6-Turrets.asm"
TurretDataEnd6:

; Hazard data hazard blocks
HazardsLevel6:          equ     (HazardDataEnd6-HazardDataStart6)/S_HAZARD_DATA
HazardDataLevel6:
HazardDataStart6:       INCLUDE "webster/assets/Level6-Hazards.asm"
HazardDataEnd6:

; Locker data for spawning locker sprites

LockersLevel6:          equ     (LockerDataEnd6-LockerDataStart6)/S_LOCKER_DATA
LockerDataLevel6:
LockerDataStart6:       INCLUDE "webster/assets/Level6-Lockers.asm"
LockerDataEnd6:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel6:            equ     (TriggerSourceDataEnd6-TriggerSourceDataStart6)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel6:
TriggerSourceDataStart6:        INCLUDE "webster/assets/Level6-TriggerSource.asm"
TriggerSourceDataEnd6:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel6:            equ     (TriggerTargetDataEnd6-TriggerTargetDataStart6)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel6:
TriggerTargetDataStart6:        INCLUDE "webster/assets/Level6-TriggerTarget.asm"
TriggerTargetDataEnd6:
;-------------------------------------------------------------------------------------
; Tilemap Data - Level 7
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData6 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData7:
                        INCBIN  "webster/assets/Level7-8Intro-TileMap.bin"
TileMapDataLevel7:      INCBIN  "webster/assets/Level7-TileMap.bin"
L2DataLevel7:           INCBIN  "webster/assets/LevelTileset3-L2.nxi"
L2PaletteDataLevel7:    INCBIN  "webster/assets/LevelTileset3-L2.nxp"
Level7Data  S_LEVEL_DATA {
                $$TileMapDef3                   ; Memory bank hosting tilemap definition data
                TileMapDefPal3,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel7,              ; Link to TileMap data
                PlayerDataLevel7,               ; Link to Player data
                WayPointsLevel7,                ; Link to number of WayPoints
                WayPointDataLevel7,             ; Link to WayPoint data
                SpawnPointsLevel7,              ; Link to number of SpawnPoints
                SpawnPointDataLevel7,           ; Link to SpawnPoint data
                FriendlysLevel7,                ; Link to number of Friendly
                FriendlyDataLevel7,             ; Link to Friendly data
                KeysLevel7,                     ; Link to number of Keys
                KeyDataLevel7,                  ; Link to Key data
                TurretsLevel7,                  ; Link to number of Turrets
                TurretDataLevel7,               ; Link to Turret data
                HazardsLevel7,                  ; Link to number of Hazards
                HazardDataLevel7,               ; Link to Hazard data
                LockersLevel7,                  ; Link to number of Lockers
                LockerDataLevel7,               ; Link to Locker dataLevel4
                TriggerSourceLevel7,            ; Link to number of TriggerSource
                TriggerSourceDataLevel7,        ; Link to TriggerSource data
                TriggerTargetLevel7,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel7         ; Link to TriggerTarget data
                L2DataLevel7                    ; Link to L2 background data
                L2PaletteDataLevel7             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel7:       INCLUDE "webster/assets/Level7-Player.asm"

; Waypoint data used by enemies
WayPointsLevel7:                equ     (WayPointDataEndLevel7-WayPointDataStartLevel7)/S_WAYPOINT_DATA
WayPointDataLevel7:
WayPointDataStartLevel7:        INCLUDE "webster/assets/Level7-Waypoints.asm"
WayPointDataEndLevel7:

; SpawnPoint data used by enemies
SpawnPointsLevel7:      equ     (SpawnPointDataEnd7-SpawnPointDataStart7)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel7:
SpawnPointDataStart7:   INCLUDE "webster/assets/Level7-SpawnPoints.asm"
SpawnPointDataEnd7:

; Friendly data for spawning friendly sprites
FriendlysLevel7:        equ     (FriendlyDataEnd7-FriendlyDataStart7)/S_FRIENDLY_DATA
FriendlyDataLevel7:
FriendlyDataStart7:     INCLUDE "webster/assets/Level7-Friendly.asm"
FriendlyDataEnd7:

; Key data for spawning key sprites
KeysLevel7:     equ     (KeyDataEnd7-KeyDataStart7)/S_KEY_DATA
KeyDataLevel7:
KeyDataStart7:  INCLUDE "webster/assets/Level7-Keys.asm"
KeyDataEnd7:

; Turret data for spawning turret sprites
TurretsLevel7:          equ     (TurretDataEnd7-TurretDataStart7)/S_TURRET_DATA
TurretDataLevel7:
TurretDataStart7:       INCLUDE "webster/assets/Level7-Turrets.asm"
TurretDataEnd7:

; Hazard data hazard blocks
HazardsLevel7:          equ     (HazardDataEnd7-HazardDataStart7)/S_HAZARD_DATA
HazardDataLevel7:
HazardDataStart7:       INCLUDE "webster/assets/Level7-Hazards.asm"
HazardDataEnd7:

; Locker data for spawning locker sprites

LockersLevel7:          equ     (LockerDataEnd7-LockerDataStart7)/S_LOCKER_DATA
LockerDataLevel7:
LockerDataStart7:       INCLUDE "webster/assets/Level7-Lockers.asm"
LockerDataEnd7:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel7:            equ     (TriggerSourceDataEnd7-TriggerSourceDataStart7)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel7:
TriggerSourceDataStart7:        INCLUDE "webster/assets/Level7-TriggerSource.asm"
TriggerSourceDataEnd7:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel7:            equ     (TriggerTargetDataEnd7-TriggerTargetDataStart7)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel7:
TriggerTargetDataStart7:        INCLUDE "webster/assets/Level7-TriggerTarget.asm"
TriggerTargetDataEnd7:

;-------------------------------------------------------------------------------------
; Tilemap Data - Level 8
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData7 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData8:
                        INCBIN  "webster/assets/Level7-8Intro-TileMap.bin"
TileMapDataLevel8:      INCBIN  "webster/assets/Level8-TileMap.bin"
L2DataLevel8:           INCBIN  "webster/assets/LevelTileset3-L2.nxi"
L2PaletteDataLevel8:    INCBIN  "webster/assets/LevelTileset3-L2.nxp"
Level8Data  S_LEVEL_DATA {
                $$TileMapDef3                   ; Memory bank hosting tilemap definition data
                TileMapDefPal3,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel8,              ; Link to TileMap data
                PlayerDataLevel8,               ; Link to Player data
                WayPointsLevel8,                ; Link to number of WayPoints
                WayPointDataLevel8,             ; Link to WayPoint data
                SpawnPointsLevel8,              ; Link to number of SpawnPoints
                SpawnPointDataLevel8,           ; Link to SpawnPoint data
                FriendlysLevel8,                ; Link to number of Friendly
                FriendlyDataLevel8,             ; Link to Friendly data
                KeysLevel8,                     ; Link to number of Keys
                KeyDataLevel8,                  ; Link to Key data
                TurretsLevel8,                  ; Link to number of Turrets
                TurretDataLevel8,               ; Link to Turret data
                HazardsLevel8,                  ; Link to number of Hazards
                HazardDataLevel8,               ; Link to Hazard data
                LockersLevel8,                  ; Link to number of Lockers
                LockerDataLevel8,               ; Link to Locker dataLevel4
                TriggerSourceLevel8,            ; Link to number of TriggerSource
                TriggerSourceDataLevel8,        ; Link to TriggerSource data
                TriggerTargetLevel8,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel8         ; Link to TriggerTarget data
                L2DataLevel8                    ; Link to L2 background data
                L2PaletteDataLevel8             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel8:       INCLUDE "webster/assets/Level8-Player.asm"

; Waypoint data used by enemies
WayPointsLevel8:                equ     (WayPointDataEndLevel8-WayPointDataStartLevel8)/S_WAYPOINT_DATA
WayPointDataLevel8:
WayPointDataStartLevel8:        INCLUDE "webster/assets/Level8-Waypoints.asm"
WayPointDataEndLevel8:

; SpawnPoint data used by enemies
SpawnPointsLevel8:      equ     (SpawnPointDataEnd8-SpawnPointDataStart8)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel8:
SpawnPointDataStart8:   INCLUDE "webster/assets/Level8-SpawnPoints.asm"
SpawnPointDataEnd8:

; Friendly data for spawning friendly sprites
FriendlysLevel8:        equ     (FriendlyDataEnd8-FriendlyDataStart8)/S_FRIENDLY_DATA
FriendlyDataLevel8:
FriendlyDataStart8:     INCLUDE "webster/assets/Level8-Friendly.asm"
FriendlyDataEnd8:

; Key data for spawning key sprites
KeysLevel8:     equ     (KeyDataEnd8-KeyDataStart8)/S_KEY_DATA
KeyDataLevel8:
KeyDataStart8:  INCLUDE "webster/assets/Level8-Keys.asm"
KeyDataEnd8:

; Turret data for spawning turret sprites
TurretsLevel8:          equ     (TurretDataEnd8-TurretDataStart8)/S_TURRET_DATA
TurretDataLevel8:
TurretDataStart8:       INCLUDE "webster/assets/Level8-Turrets.asm"
TurretDataEnd8:

; Hazard data hazard blocks
HazardsLevel8:          equ     (HazardDataEnd8-HazardDataStart8)/S_HAZARD_DATA
HazardDataLevel8:
HazardDataStart8:       INCLUDE "webster/assets/Level8-Hazards.asm"
HazardDataEnd8:

; Locker data for spawning locker sprites

LockersLevel8:          equ     (LockerDataEnd8-LockerDataStart8)/S_LOCKER_DATA
LockerDataLevel8:
LockerDataStart8:       INCLUDE "webster/assets/Level8-Lockers.asm"
LockerDataEnd8:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel8:            equ     (TriggerSourceDataEnd8-TriggerSourceDataStart8)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel8:
TriggerSourceDataStart8:        INCLUDE "webster/assets/Level8-TriggerSource.asm"
TriggerSourceDataEnd8:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel8:            equ     (TriggerTargetDataEnd8-TriggerTargetDataStart8)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel8:
TriggerTargetDataStart8:        INCLUDE "webster/assets/Level8-TriggerTarget.asm"
TriggerTargetDataEnd8:

;-------------------------------------------------------------------------------------
; Tilemap Data - Level 9
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData8 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData9:
                        INCBIN  "webster/assets/Level9-10Intro-TileMap.bin"
TileMapDataLevel9:      INCBIN  "webster/assets/Level9-TileMap.bin"
L2DataLevel9:           INCBIN  "webster/assets/LevelTileset4-L2.nxi"
L2PaletteDataLevel9:    INCBIN  "webster/assets/LevelTileset4-L2.nxp"
Level9Data  S_LEVEL_DATA {
                $$TileMapDef4                   ; Memory bank hosting tilemap definition data
                TileMapDefPal4,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel9,              ; Link to TileMap data
                PlayerDataLevel9,               ; Link to Player data
                WayPointsLevel9,                ; Link to number of WayPoints
                WayPointDataLevel9,             ; Link to WayPoint data
                SpawnPointsLevel9,              ; Link to number of SpawnPoints
                SpawnPointDataLevel9,           ; Link to SpawnPoint data
                FriendlysLevel9,                ; Link to number of Friendly
                FriendlyDataLevel9,             ; Link to Friendly data
                KeysLevel9,                     ; Link to number of Keys
                KeyDataLevel9,                  ; Link to Key data
                TurretsLevel9,                  ; Link to number of Turrets
                TurretDataLevel9,               ; Link to Turret data
                HazardsLevel9,                  ; Link to number of Hazards
                HazardDataLevel9,               ; Link to Hazard data
                LockersLevel9,                  ; Link to number of Lockers
                LockerDataLevel9,               ; Link to Locker dataLevel4
                TriggerSourceLevel9,            ; Link to number of TriggerSource
                TriggerSourceDataLevel9,        ; Link to TriggerSource data
                TriggerTargetLevel9,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel9         ; Link to TriggerTarget data
                L2DataLevel9                    ; Link to L2 background data
                L2PaletteDataLevel9             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel9:       INCLUDE "webster/assets/Level9-Player.asm"

; Waypoint data used by enemies
WayPointsLevel9:                equ     (WayPointDataEndLevel9-WayPointDataStartLevel9)/S_WAYPOINT_DATA
WayPointDataLevel9:
WayPointDataStartLevel9:        INCLUDE "webster/assets/Level9-Waypoints.asm"
WayPointDataEndLevel9:

; SpawnPoint data used by enemies
SpawnPointsLevel9:      equ     (SpawnPointDataEnd9-SpawnPointDataStart9)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel9:
SpawnPointDataStart9:   INCLUDE "webster/assets/Level9-SpawnPoints.asm"
SpawnPointDataEnd9:

; Friendly data for spawning friendly sprites
FriendlysLevel9:        equ     (FriendlyDataEnd9-FriendlyDataStart9)/S_FRIENDLY_DATA
FriendlyDataLevel9:
FriendlyDataStart9:     INCLUDE "webster/assets/Level9-Friendly.asm"
FriendlyDataEnd9:

; Key data for spawning key sprites
KeysLevel9:     equ     (KeyDataEnd9-KeyDataStart9)/S_KEY_DATA
KeyDataLevel9:
KeyDataStart9:  INCLUDE "webster/assets/Level9-Keys.asm"
KeyDataEnd9:

; Turret data for spawning turret sprites
TurretsLevel9:          equ     (TurretDataEnd9-TurretDataStart9)/S_TURRET_DATA
TurretDataLevel9:
TurretDataStart9:       INCLUDE "webster/assets/Level9-Turrets.asm"
TurretDataEnd9:

; Hazard data hazard blocks
HazardsLevel9:          equ     (HazardDataEnd9-HazardDataStart9)/S_HAZARD_DATA
HazardDataLevel9:
HazardDataStart9:       INCLUDE "webster/assets/Level9-Hazards.asm"
HazardDataEnd9:

; Locker data for spawning locker sprites

LockersLevel9:          equ     (LockerDataEnd9-LockerDataStart9)/S_LOCKER_DATA
LockerDataLevel9:
LockerDataStart9:       INCLUDE "webster/assets/Level9-Lockers.asm"
LockerDataEnd9:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel9:            equ     (TriggerSourceDataEnd9-TriggerSourceDataStart9)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel9:
TriggerSourceDataStart9:        INCLUDE "webster/assets/Level9-TriggerSource.asm"
TriggerSourceDataEnd9:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel9:            equ     (TriggerTargetDataEnd9-TriggerTargetDataStart9)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel9:
TriggerTargetDataStart9:        INCLUDE "webster/assets/Level9-TriggerTarget.asm"
TriggerTargetDataEnd9:

;-------------------------------------------------------------------------------------
; Tilemap Data - Level 10
; Note: Tilemap def & palette in different memory bank
; - "$$" is a special operator of sjasmplus to get memory bank of particular label (the 8kiB memory bank), +1 points to next bank
        MMU     3, $$LevelData9 + 1    ; Slot 3 = $6000..$7FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Point to slot 3 memory address and include tilemap data
        ORG     $6000
LevelData10:
                        INCBIN  "webster/assets/Level9-10Intro-TileMap.bin"
TileMapDataLevel10:     INCBIN  "webster/assets/Level10-TileMap.bin"
L2DataLevel10:          INCBIN  "webster/assets/LevelTileset4-L2.nxi"
L2PaletteDataLevel10:   INCBIN  "webster/assets/LevelTileset4-L2.nxp"
Level10Data  S_LEVEL_DATA {
                $$TileMapDef4                   ; Memory bank hosting tilemap definition data
                TileMapDefPal4,                 ; Link to tilemap palette
                0,                              ; Palette Offset - Main Palette
                1,                              ; Palette Offset - Alternate Palette
                2,                              ; Palette Offset - Level Complete
                TileMapDataLevel10,              ; Link to TileMap data
                PlayerDataLevel10,               ; Link to Player data
                WayPointsLevel10,                ; Link to number of WayPoints
                WayPointDataLevel10,             ; Link to WayPoint data
                SpawnPointsLevel10,              ; Link to number of SpawnPoints
                SpawnPointDataLevel10,           ; Link to SpawnPoint data
                FriendlysLevel10,                ; Link to number of Friendly
                FriendlyDataLevel10,             ; Link to Friendly data
                KeysLevel10,                     ; Link to number of Keys
                KeyDataLevel10,                  ; Link to Key data
                TurretsLevel10,                  ; Link to number of Turrets
                TurretDataLevel10,               ; Link to Turret data
                HazardsLevel10,                  ; Link to number of Hazards
                HazardDataLevel10,               ; Link to Hazard data
                LockersLevel10,                  ; Link to number of Lockers
                LockerDataLevel10,               ; Link to Locker dataLevel4
                TriggerSourceLevel10,            ; Link to number of TriggerSource
                TriggerSourceDataLevel10,        ; Link to TriggerSource data
                TriggerTargetLevel10,            ; Link to number of TriggerTarget
                TriggerTargetDataLevel10         ; Link to TriggerTarget data
                L2DataLevel10                    ; Link to L2 background data
                L2PaletteDataLevel10             ; Link to L2 background data
                }         

; Player data
PlayerDataLevel10:       INCLUDE "webster/assets/Level10-Player.asm"

; Waypoint data used by enemies
WayPointsLevel10:                equ     (WayPointDataEndLevel10-WayPointDataStartLevel10)/S_WAYPOINT_DATA
WayPointDataLevel10:
WayPointDataStartLevel10:        INCLUDE "webster/assets/Level10-Waypoints.asm"
WayPointDataEndLevel10:

; SpawnPoint data used by enemies
SpawnPointsLevel10:      equ     (SpawnPointDataEnd10-SpawnPointDataStart10)/S_SPAWNPOINTASM_DATA
SpawnPointDataLevel10:
SpawnPointDataStart10:   INCLUDE "webster/assets/Level10-SpawnPoints.asm"
SpawnPointDataEnd10:

; Friendly data for spawning friendly sprites
FriendlysLevel10:        equ     (FriendlyDataEnd10-FriendlyDataStart10)/S_FRIENDLY_DATA
FriendlyDataLevel10:
FriendlyDataStart10:     INCLUDE "webster/assets/Level10-Friendly.asm"
FriendlyDataEnd10:

; Key data for spawning key sprites
KeysLevel10:     equ     (KeyDataEnd10-KeyDataStart10)/S_KEY_DATA
KeyDataLevel10:
KeyDataStart10:  INCLUDE "webster/assets/Level10-Keys.asm"
KeyDataEnd10:

; Turret data for spawning turret sprites
TurretsLevel10:          equ     (TurretDataEnd10-TurretDataStart10)/S_TURRET_DATA
TurretDataLevel10:
TurretDataStart10:       INCLUDE "webster/assets/Level10-Turrets.asm"
TurretDataEnd10:

; Hazard data hazard blocks
HazardsLevel10:          equ     (HazardDataEnd10-HazardDataStart10)/S_HAZARD_DATA
HazardDataLevel10:
HazardDataStart10:       INCLUDE "webster/assets/Level10-Hazards.asm"
HazardDataEnd10:

; Locker data for spawning locker sprites

LockersLevel10:          equ     (LockerDataEnd10-LockerDataStart10)/S_LOCKER_DATA
LockerDataLevel10:
LockerDataStart10:       INCLUDE "webster/assets/Level10-Lockers.asm"
LockerDataEnd10:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerSourceLevel10:            equ     (TriggerSourceDataEnd10-TriggerSourceDataStart10)/S_TRIGGERSOURCEASM_DATA
TriggerSourceDataLevel10:
TriggerSourceDataStart10:        INCLUDE "webster/assets/Level10-TriggerSource.asm"
TriggerSourceDataEnd10:

; Trigger data for managing trigger events e.g. Opening locked doors
TriggerTargetLevel10:            equ     (TriggerTargetDataEnd10-TriggerTargetDataStart10)/S_TRIGGERTARGETASM_DATA
TriggerTargetDataLevel10:
TriggerTargetDataStart10:        INCLUDE "webster/assets/Level10-TriggerTarget.asm"
TriggerTargetDataEnd10:

;-------------------------------------------------------------------------------------
; AyFX Banks - Non-Game Sound Effects - 1
        MMU     4 n, $$TriggerTargetDataEnd10+1    ; Slot 4 = $8000..$9FFF, "n" option to wrap (around slot 4) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 4 memory address and include AyFX bank data 
        ORG     $8000
AyFXBankLevelIntro:     incbin  "webster/assets/audio/LevelIntro.afb"
;-------------------------------------------------------------------------------------
; AyFX Banks - Non-Game Sound Effects - 2
        MMU     4 n, $$AyFXBankLevelIntro+1     ; Slot 4 = $8000..$9FFF, "n" option to wrap (around slot 4) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 4 memory address and include AyFX bank data 
        ORG     $8000
AyFXBankLevelComplete:  incbin  "webster/assets/audio/LevelComplete.afb"
;-------------------------------------------------------------------------------------
; AyFX Banks - Non-Game Sound Effects - 3
        MMU     4 n, $$AyFXBankLevelComplete+1     ; Slot 4 = $8000..$9FFF, "n" option to wrap (around slot 4) the next bank automatically, 8kb bank reference (16kb refx2)
; - Point to slot 4 memory address and include AyFX bank data 
        ORG     $8000
AyFXBankGameOver:       incbin  "webster/assets/audio/GameOver.afb"
AyFXBankEnd:
; Note: Next memory bank used by title code within Title.asm