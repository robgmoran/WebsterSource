DMACode2:
; Reference - https://wiki.specnext.dev/DMA
;-------------------------------------------------------------------------------------
; DMA Program to copy screen contents right during scroll routine
DMAScrollRight:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW TileMapLocation+2                    ; WR0 par 1&2 - port A start address
        DW (TileMapWidth*TileMapHeight)-2       ; WR0 par 3&4 - transfer length

        DB %0'0'01'0'100                        ; WR1 - A incr., A=memory

        DB %0'0'01'0'000                        ; WR2 - B incr., B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW TileMapLocation                      ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAScrollRightCopySize = $-DMAScrollRight

;-------------------------------------------------------------------------------------
; DMA Program to copy screen contents left during scroll routine
DMAScrollLeft:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW TileMapLocation+(TileMapWidth*TileMapHeight)-3                   ; WR0 par 1&2 - port A start address
        DW (TileMapWidth*TileMapHeight)-2       ; WR0 par 3&4 - transfer length

        DB %0'0'00'0'100                        ; WR1 - A dec., A=memory

        DB %0'0'00'0'000                        ; WR2 - B dec., B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW TileMapLocation+(TileMapWidth*TileMapHeight)-1                      ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAScrollLeftCopySize = $-DMAScrollLeft

;-------------------------------------------------------------------------------------
; DMA Program to copy screen contents right during scroll routine
DMAScrollDown:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        DW TileMapLocation+(TileMapWidth*2)                    ; WR0 par 1&2 - port A start address
        DW (TileMapWidth*(TileMapHeight-2))       ; WR0 par 3&4 - transfer length

        DB %0'0'01'0'100                        ; WR1 - A incr., A=memory

        DB %0'0'01'0'000                        ; WR2 - B incr., B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW TileMapLocation                      ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAScrollDownCopySize = $-DMAScrollDown

;-------------------------------------------------------------------------------------
; DMA Program to copy screen contents up during scroll routine
DMAScrollUp:
        DB %1'00000'11                          ; WR6 - disable DMA

        DB %0'11'11'1'01                        ; WR0 - append length + port A address, A->B
        ;DW TileMapLocation+(TileMapWidth*2)                    ; WR0 par 1&2 - port A start address

        DW TileMapLocation+(TileMapWidth*(TileMapHeight-2))-1   ; WR0 par 1&2 - port A start address
        DW (TileMapWidth*(TileMapHeight-2))     ; WR0 par 3&4 - transfer length

        DB %0'0'00'0'100                        ; WR1 - A dec., A=memory

        DB %0'0'00'0'000                        ; WR2 - B dec., B=memory

        DB %1'01'0'11'01                        ; WR4 - continuous, append port B addres
        DW TileMapLocation+(TileMapWidth*TileMapHeight)-1       ; WR4 par 1&2 - port B address

        DB %10'0'0'0010                         ; WR5 - stop on end of block, CE only

        DB %1'10011'11                          ; WR6 - load addresses into DMA counters
        DB %1'00001'11                          ; WR6 - enable DMA
DMAScrollUpCopySize = $-DMAScrollUp
