CircleCode:
;-------------------------------------------------------------------------------------
; Obtain position on the edge of a circle
; Parameters:
; Radius =  Store the radius in this variable before calling 
; a = Angle (0 - 255)
; bc = y center of the circle (rotation point)
; de = x center of the circle (rotation point)
; Return:
; bc = x position on the circle
; de = y position on the circle
;
; Based on:
; - 256 angles - 360/256 gives an angle step of ~1.4 degrees
; - 4 quadrants containing 64 angles/quadrant
;   (1)0-63, (2)64-127, (3)128-191, (4)192 - 255
;   Note: The figures do not represent exact angles only the stepped angles within the quadrant
ObtainPosOnCircle:
; Determine quadrant containing angle
        cp      64        
        jp      c, .A_0_63      ; Jump if angle in quadrant 1    
        cp      128        
        jp      c, .A_64_127    ; Jump if angle in quadrant 2    
        cp      192        
        jp      c, .A_128_191   ; Jump if angle in quadrant 3    

        jp      .a_192_255      ; Otherwise angle in quadrant 4

; --- Quadrant 1
.A_0_63:
        push    bc              ; Save y center
        push    de        	; Save x center

; Obtain sine and cosine values
        call    GetSinCos       ; Get the cos and sin for this angle

; Update and return x and y positions
        pop     hl              ; Get x center    
        add     hl, bc          ; Add sin result
        ld      bc, hl          ; Set as x return pos

        pop     hl              ; Get y center
        sub     hl, de          ; Add cos result   
        ld      de, hl          ; Set as y return pos

        ret

; --- Quadrant 2
.A_64_127:
; Update angle - Go down curve
        push    bc              ; Save y center

        sub     63              ; Subtract 63 making it 0-63
        ld      b, a            ; Reverse the angle i.e. Need to read bottom part of the wave
        ld      a, 64
        sub     b               ; Change to 63-0

        push    de              ; Save x center

; Obtain sine and cosine values
        call    GetSinCos       ; Get the cos and sin for this angle

; Update and return x and y positions
        pop     hl              ; Get x center  
        add     hl, bc          ; Add sin result
        ld      bc, hl          ; Set as x return pos

        pop     hl              ; Get y center
        add     hl, de          ; Add cos result  
        ld      de, hl          ; Set as y return pos

        ret  

; --- Quadrant 3
.A_128_191:
; Update angle - Gp up curve
        sub     128             ; Subtract 127 making it 0-63

        push    bc              ; Save y center
        push    de              ; Save x center    

; Obtain sine and cosine values
        call    GetSinCos       ; Get the cos and sin for this angle

; Update and return x and y positions
        pop     hl              ; Get x center
        sub     hl, bc          ; Subtract sin result
        ld      bc, hl          ; Set as x return pos

        pop     hl              ; Get y center
        add     hl, de          ; Add the cos result
        ld      de, hl          ; Set as y return pos

        ret  

; --- Quadrant 4
.a_192_255:
        push    bc              ; Save y center

; Reverse angle
        sub     191             ; Subtract 191 making it 0-63
        ld      b, a            ; Reverse the angle i.e. Need to read bottom part of the wave
        ld      a, 64        
        sub     b               ; Change to 63-0

        push    de              ; Save x center  

; Obtain sine and cosine values
        call    GetSinCos       ; Get the cos and sin for this angle

; Update and return x and y positions
        pop     hl              ; Get x center  
        sub     hl,bc           ; Subtract sin result
        ld      bc,hl           ; Set as x return pos

        pop     hl              ; Get y center
        sub     hl, de          ; Subtract the cos result 
        ld      de, hl          ; Set as y return pos

        ret          

;-------------------------------------------------------------------------------------
; Calculate the x y pos
; Parameters:
; a = Angle (0 - 255)
;
; Return:
; bc = x position
; de = y position
GetSinCos:
; Obtain/Calculate Sine Value
        call    GetSinValue     ; Obtain sin(angle) - Return:  e

        ld      hl, Radius    
        ld      d, (hl)
        mul     d, e            ; Multiply sin value by radius    

        ld      b, 6            ; Sin value originally represented as 2.6 fixed point 
        bsrl    de, b           ; Divide by 64 (amplitude) to obtain coordinate value
        push    de              ; Save as x pos

; Obtain/Calculate Cosine Value
        call    GetCosValue     ; Obtain Cos(angle) - Return: e

        ld      hl, Radius    
        ld      d, (hl)        
        mul     d, e            ; Multiply sin value by radius    

        ld      b, 6            ; Cos value originally represented as 2.6 fixed point 
        bsrl    de, b           ; Divide by 64 (amplitude) to obtain coordinate value

        pop     bc              ; Restore the x pos

        ret  

;-------------------------------------------------------------------------------------
; Obtain sin value
; Parameters:
; a = Angle (0 - 255)
;
; Return:
; e = sin 2.6 format
GetSinValue:
        ld      h, 0            
        ld      l, a            ; Angle
        ld      de, SinTable    
        add     hl, de          ; Add angle to get index into sin Table
        ld      e, (hl)         ; Obtain sin value
        ret          

;-------------------------------------------------------------------------------------
; Obtain cos value
; Parameters:
; a = Angle (0 - 255)
;
; Return:
; e = cos 2.6 format
GetCosValue:    
        ld      h,0             
        ld      l,a             ; Angle
        ld      de, CosTable      
        add     hl, de          ; Add angle to get index into cos Table
        ld      e, (hl)         ; Obtain cos value
        ret          