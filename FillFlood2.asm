;-------------------------------------------------------------------------------------
; Reset queue pointers
ResetQueue:
        ld      hl, Queue
        ld      (QueueStart), hl
        ld      (QueueEnd), hl

        ret

;-------------------------------------------------------------------------------------
; Add word to queue
; Parameters:
; - de = Word to store in queue
EnQueue:
        ld      hl, (QueueEnd)
        ld      (hl), de

        inc     hl
        inc     hl
        ld      (QueueEnd), hl

        ret

;-------------------------------------------------------------------------------------
; Remove word from queue
; Return Values:
; de = Word removed from Queue
DeQueue:
        ld      hl, (QueueStart)

        ld      de, (hl)
        ld      bc, $0000
        ld      (hl), bc

        inc     hl
        inc     hl

        ld      (QueueStart), hl

        ret

;-------------------------------------------------------------------------------------
; Peek next word in queue
; Return Values:
; de = Next word in Queue
PeekQueue:
        ld      hl, (QueueStart)
        ld      de, (hl)

        ret