;-------------------------------------------------------------------------------------
; Assembler and CSpect Setup code
;
; Allow the Next paging and instructions
        DEVICE ZXSPECTRUMNEXT
        SLDOPT COMMENT WPMEM, LOGPOINT, ASSERTION
        
; Generate a map file (debugging) for use with Cspect
        CSPECTMAP "webster/output/Main.map"

; include symbolic names for "magic numbers" like NextRegisters and I/O ports
        INCLUDE "constants.i.asm"

; Macros
        MACRO break
           db   $dd, $01     
        ENDM

; Memory Map - *** Refer/update from OneNote attachment ***
; ----------
; $0000 - $1FFF - GameCode (12)
; $2000 - $3FFF - GameCode (13)
; $4000 - $5FFF - GameCode (14) --- 1,042 bytes free
; $6000 - $7FFF - TileMap Screen/Definitions (10)
; -Assembly Time
;	Sprites (24/25) - Wrap around bank
;	Sprite palette (26)
;	TileMap+init values (29) - Multiple banks for different levels (Refer to Level Data Bank Template)
; -Runtime
;	Sprite palette - Temp
;	Sprites 1/2 - Temp
;	TileMap+init value - Temp - Dynamically Mapped based on bank hosting level data
; $8000 - $9FFF - TileMap Definitions (11) --- 3,840 bytes free
; $A000 - $BFFF - Boot Loader/Game Data (5-Default)
; $C000 - $9FFF - Game Data (0-Default)
; $E000 - $FFFF - Game Data (1-Default) --- 2,664 bytes free
; -Runtime
;	Tilemap definitions+tilemap palette (27/28) - Temp

; Display
; -------
; SUL - Sprites - Enhanced ULA/Tilemap (ULA over Tilemap), Layer 2
; - xEnhanced ULA - Could be used to display text or extra graphics
; - Tilemap - Use to display foreground level

; Audio
; -----
; TitleB
; - AY Chip-1 - 3 x Channels - NextDAW - Music???
; - AY Chip-2 - 3 x Channels - NextDAW - Music???
; - AY Chip-3 - 3 x Channels ---
; Game
; - AY Chip-1 - 3 x Channels ---
; - AY Chip-2 - 3 x Channels - AYFX - Sound Effects
; - AY ChipB-3 - 3 x Channels - AYFX - Sound Effects

;-------------------------------------------------------------------------------------
; Boot Loader
; Required to mount memory banks for hosting code
        org  $a000

BootLoader:
        di      

; Save MMU0 bank reference - $0000-$1fff
	ld      a, $50                           ; Port to access - Memory Slot 0
	ld      bc,$243B                        ; TBBlue Register Select
	out     (c),a                           ; Select NextReg $1F

	inc     b                               ; TBBlue Register Access
	in      a, (c)
	ld      (ROM_Bank), a                   ; Save current bank number in slot 0

; Swap memory banks
        nextreg $50, Code_Bank          ; $0000-$1FFF
        nextreg $51, Code_Bank+1        ; $2000-$3FFF
        nextreg $52, Code_Bank+2        ; $4000-$5FFF

        rst     $00                     ; Call game code

;-------------------------------------------------------------------------------------
; Data Area
;-------------------------------------------------------------------------------------
; Stack Location
; Required to aid Dezog debugging and label (stack_top) added to launch.json
; Reserves area for stack
stack_bottom:
        DS      127, 0

stack_top:
        dw 0

        include "webster/data.asm"

EndofData2:
;-------------------------------------------------------------------------------------
; Code Area
; Note: At assembly time need to map ALL memory banks that will contain code.
; Note: This is required as the include commands will add the code at assembly time to the
;       memory banks mapped at their memory location. Therefore at runtime when the memory
;       bank are mapped, the correct code is available.
; - Assembly Time - Map bank 12 into MMU 0 using sjasmplus MMU directive and 8kb references
        MMU     0, 12
        ; Slot 0 = $0000..$1FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Assembly Time - Map bank 13 into MMU 1 using sjasmplus MMU directive and 8kb references
        MMU     1, 13           
        ; Slot 0 = $2000..$3FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Assembly Time - Map bank 14 into MMU 2 using sjasmplus MMU directive and 8kb references
        MMU     2, 14           
        ; Slot 0 = $4000..$5FFF ("n" wrap option not used), 8kb bank reference (16kb refx2)
; - Assembly Time - Map bank 11 into MMU 4 using sjasmplus MMU directive and 8kb references
        MMU     4, 11           
        ; Slot 0 = $8000..$9fff ("n" wrap option not used), 8kb bank reference (16kb refx2)


; - Runtime - Map bank 12 to MMU 0 using nextreg (see above)
; - Point to MMU 0 memory address
        ORG     $0000

        include "webster/GameCode.asm"

;-------------------------------------------------------------------------------------
; Nex File Export

; This sets the name of the project, the start address, 
; and the initial stack pointer.
        SAVENEX OPEN "webster/output/Webster.nex", BootLoader, stack_top, 0, 2 ; V1.2 enforced
        SAVENEX CORE 3,0,0      ; core 3.0.0 required
; This sets the border colour while loading,
; what to do with the file handle of the nex file when starting (0 = 
; close file handle as we're not going to access the project.nex 
; file after starting.  See sjasmplus documentation), whether
; we preserve the next registers (0 = no, we set to default), and 
; whether we require the full 2MB expansion (0 = no we don't).
        SAVENEX CFG 0,0,0,0     ; Set colour to 0 - transparent
; Generate the Nex file by scanning all device memory for any non-zero values,
; and then dump every relevent 16ki bank to the NEX file based on these values
        SAVENEX AUTO 
        SAVENEX CLOSE