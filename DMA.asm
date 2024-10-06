DMACode:
;-------------------------------------------------------------------------------------
; DMA Program to copy start block to temporary storage - Block Animation
DMABlockAnimation:
        DB %1'00000'11          ; WR6 - Disable DMA
; ------------------------------------------------------------------------
        DB %0'11'11'1'01        ; WR0 - Block length, Port A address, A->B
DMABlockAnimationPortA:
        DW 0                    ; - WR0 par 1&2 - Port A start address
DMABlockAnimationLength:
        DW 0                    ; - WR0 par 3&4 - Block length
; ------------------------------------------------------------------------
        DB %0'0'01'0'100        ; WR1 - Port A inc., Port A=memory
; ------------------------------------------------------------------------
        DB %0'0'01'0'000        ; WR2 - Port B inc., Port B=memory
; ------------------------------------------------------------------------
        DB %1'01'0'11'01        ; WR4 - Continuous mode, Port B address
DMABlockAnimationPortB:
        DW 0                    ; WR4 par 1&2 - Port B address
; ------------------------------------------------------------------------
        DB %10'0'0'0010         ; WR5 - Stop on end of block, CE only
; ------------------------------------------------------------------------
        DB %1'10011'11          ; WR6 - Load addresses into DMA counters
        DB %1'00001'11          ; WR6 - Enable DMA
DMABlockAnimationCopySize = $-DMABlockAnimation

;-------------------------------------------------------------------------------------
; DMA Program to copy sprite attributes to sprite upload port
DMASpriteAttUpload:
        DB %1'00000'11          ; WR6 - Disable DMA
; ------------------------------------------------------------------------
        DB %0'11'11'1'01        ; WR0 - Block length, Port A address, A->B
DMASpriteAttUploadPortA:
        DW SpriteAtt            ; - WR0 par 1&2 - Port A start address
DMASpriteAttUploadLength:
        DW 0                    ; - WR0 par 3&4 - Block length
; ------------------------------------------------------------------------
        DB %0'0'01'0'100        ; WR1 - Port A inc., Port A=memory
; ------------------------------------------------------------------------
        DB %0'0'10'1'000        ; WR2 - Port B fixed., Port B=I/0
; ------------------------------------------------------------------------
        DB %1'01'0'11'01        ; WR4 - Continuous mode, Port B address
DMASpriteAttUploadPortB:
        DW $57                  ; WR4 par 1&2 - Port B address
; ------------------------------------------------------------------------
        DB %10'0'0'0010         ; WR5 - Stop on end of block, CE only
; ------------------------------------------------------------------------
        DB %1'10011'11          ; WR6 - Load addresses into DMA counters
        DB %1'00001'11          ; WR6 - Enable DMA
DMASpriteAttUploadCopySize = $-DMASpriteAttUpload

;-------------------------------------------------------------------------------------
; DMA Program to copy sprite data
DMASpriteDataUpload:
        DB %1'00000'11          ; WR6 - Disable DMA
; ------------------------------------------------------------------------
        DB %0'11'11'1'01        ; WR0 - Block length, Port A address, A->B
DMASpriteDataUploadPortA:
        DW 0                    ; - WR0 par 1&2 - Port A start address
DMASpriteDataUploadLength:
        DW 0                    ; - WR0 par 3&4 - Block length
; ------------------------------------------------------------------------
        DB %0'0'01'0'100        ; WR1 - Port A inc., Port A=memory
; ------------------------------------------------------------------------
        DB %0'0'01'0'000        ; WR2 - Port B fixed., Port B Address
; ------------------------------------------------------------------------
        DB %1'01'0'11'01        ; WR4 - Continuous mode, Port B address
DMASpriteDataUploadPortB:
        DW 0                    ; WR4 par 1&2 - Port B address
; ------------------------------------------------------------------------
        DB %10'0'0'0010         ; WR5 - Stop on end of block, CE only
; ------------------------------------------------------------------------
        DB %1'10011'11          ; WR6 - Load addresses into DMA counters
        DB %1'00001'11          ; WR6 - Enable DMA
DMASpriteDataUploadCopySize = $-DMASpriteDataUpload

;-------------------------------------------------------------------------------------
; DMA Program to clear FFStorage contents
DMAFFStorageClear:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW FFStorage                            ; WR0 par 1&2 - port A start address
        DW (BlockTileMapWidthDisplay)*(BlockTileMapHeightDisplay)-1       ; WR0 par 3&4 - transfer length

        DB %0'0'11'0'100                        ; WR1 - A fixed., A=memory

        DB %0'0'01'0'000                        ; WR2 - Port B inc., Port B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW FFStorage+1                          ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAFFStorageClearCopySize = $-DMAFFStorageClear

;-------------------------------------------------------------------------------------
; DMA Program to copy FFStorage to FFStorageComplete
DMAFFStorageCopy:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW FFStorage                            ; WR0 par 1&2 - port A start address
        DW (BlockTileMapWidthDisplay)*(BlockTileMapHeightDisplay)       ; WR0 par 3&4 - transfer length

        DB %0'0'01'0'100                        ; WR1 - A dec., A=memory

        DB %0'0'01'0'000                        ; WR2 - Port B inc., Port B=memory

        DB %1'01'0'11'01;11'01                        ; WR4 - continuous, append port B addres
        DW FFStorageComplete                    ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAFFStorageCopySize = $-DMAFFStorageCopy

;-------------------------------------------------------------------------------------
; DMA Program to clear DoorData contents
DMADoorDataClear:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW DoorData                             ; WR0 par 1&2 - port A start address
        DW (MaxDoors*S_DOOR_DATA)-1             ; WR0 par 3&4 - transfer length

        DB %0'0'11'0'100                        ; WR1 - A fixed., A=memory

        DB %0'0'01'0'000                        ; WR2 - Port B inc., Port B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW DoorData+1                           ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMADoorDataClearCopySize = $-DMADoorDataClear

;-------------------------------------------------------------------------------------
; DMA Program to clear SpawnPointData contents
DMASpawnPointDataClear:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW SpawnPointData                       ; WR0 par 1&2 - port A start address
        DW (MaxSpawnPoints*S_SPAWNPOINT_DATA)-1 ; WR0 par 3&4 - transfer length

        DB %0'0'11'0'100                        ; WR1 - A fixed., A=memory

        DB %0'0'01'0'000                        ; WR2 - Port B inc., Port B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW SpawnPointData+1                     ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMASpawnPointDataClearCopySize = $-DMASpawnPointDataClear

;-------------------------------------------------------------------------------------
; DMA Program to Hazard block data
DMAHazardDataUpload:
        DB %1'00000'11          ; WR6 - Disable DMA
; ------------------------------------------------------------------------
        DB %0'11'11'1'01        ; WR0 - Block length, Port A address, A->B
DMAHazardDataUploadPortA:
        DW 0                    ; - WR0 par 1&2 - Port A start address
DMAHazardDataUploadLength:
        DW 0                    ; - WR0 par 3&4 - Block length
; ------------------------------------------------------------------------
        DB %0'0'01'0'100        ; WR1 - Port A inc., Port A=memory
; ------------------------------------------------------------------------
        DB %0'0'01'0'000        ; WR2 - Port B fixed., Port B Address
; ------------------------------------------------------------------------
        DB %1'01'0'11'01        ; WR4 - Continuous mode, Port B address
DMAHazardDataUploadPortB:
        DW HazardBlockData      ; WR4 par 1&2 - Port B address
; ------------------------------------------------------------------------
        DB %10'0'0'0010         ; WR5 - Stop on end of block, CE only
; ------------------------------------------------------------------------
        DB %1'10011'11          ; WR6 - Load addresses into DMA counters
        DB %1'00001'11          ; WR6 - Enable DMA
DMAHazardDataUploadCopySize = $-DMAHazardDataUpload

;-------------------------------------------------------------------------------------
; DMA Program to clear EnemyMovementBlockMap contents
DMAEnemyMovementBlockMapDataClear:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW EnemyMovementBlockMap                ; WR0 par 1&2 - port A start address
        DW ((BlockTileMapWidth*BlockTileMapHeight)/8)-1 ; WR0 par 3&4 - transfer length

        DB %0'0'11'0'100                        ; WR1 - A fixed., A=memory

        DB %0'0'01'0'000                        ; WR2 - Port B inc., Port B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW EnemyMovementBlockMap+1              ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAEnemyMovementBlockMapDataClearCopySize = $-DMAEnemyMovementBlockMapDataClear

;-------------------------------------------------------------------------------------
; DMA Program to clear EnemyMovementBlock contents
DMAFriendlyMovementBlockMapDataClear:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW FriendlyMovementBlockMap             ; WR0 par 1&2 - port A start address
        DW ((BlockTileMapWidth*BlockTileMapHeight)/8)-1 ; WR0 par 3&4 - transfer length

        DB %0'0'11'0'100                        ; WR1 - A fixed., A=memory

        DB %0'0'01'0'000                        ; WR2 - Port B inc., Port B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW FriendlyMovementBlockMap+1           ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAFriendlyMovementBlockMapDataClearCopySize = $-DMAFriendlyMovementBlockMapDataClear

;-------------------------------------------------------------------------------------
; DMA Program to clear 8kb memory bank content
DMAMemoryBankClear:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
DMAMemoryBankUploadPortA:
        DW 0                                    ; WR0 par 1&2 - port A start address

        DW 8192-1                                 ; WR0 par 3&4 - transfer length

        DB %0'0'11'0'100                        ; WR1 - A fixed., A=memory

        DB %0'0'01'0'000                        ; WR2 - Port B inc., Port B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
DMAMemoryBankUploadPortB:
        DW 0                                    ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAMemoryBankClearSize = $-DMAMemoryBankClear

;-------------------------------------------------------------------------------------
; DMA Program to upload copper program
DMACopperUpload:
	DB %10000011		; WR6 - Disable DMA
	DB %01111101		; WR0 - append length + port A address, A->B
DMACopperUploadStart:
	DW 0			; WR0 par 1&2 - port A start address
DMACopperUploadLength:
	DW 0			; WR0 par 3&4 - transfer length
	DB %00010100		; WR1 - A incr., A=memory
	DB %00101000		; WR2 - B fixed, B=I/O
	DB %10101101		; WR4 - continuous, append port B address
	DW $253B		; WR4 par 1&2 - port B address
	DB %10000010		; WR5 - stop on end of block, CE only
	DB %11001111		; WR6 - load addresses into DMA counters
	DB %10000111		; WR6 - enable DMA
DMACopperUploadCopySize = $-DMACopperUpload
