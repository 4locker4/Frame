;------------------------------------------------------------------------------
;                           Register watcher
;------------------------------------------------------------------------------

.model tiny
.data 

;------------------------------------------------------------------------------
;					CONSTANTS
;------------------------------------------------------------------------------

VIDEO_MEM 		equ 0b800h
SCREEN_LENGHT_IN_MEM	equ 160
LENGHT_OF_FRAME_MASSIVE equ 10
CENTER_OF_SCREEN_CLMN	equ 11
SCREEN_HIGHT_IN_VISUAL	equ 25

FRAME_COLOR             equ 3ch
FRAME_HIGHT             equ 20
FRAME_LENGHT            equ 30

FRAME_ACTIVATOR         equ 'f'
STOP_FRAME              equ 'q'

CHECK                   db 'checking'

.code

org 100h

PUSH_TO_SAVE_ALL_REGS   macro
                        push es ds sp bp si di dx cx bx ax 

                        endm

POP_SAVED_REGS          macro
                        pop ax bx cx dx di si bp sp ds es

                        endm


Start:
                call OutputRegs

                mov ah, 4ch
                int 21h

                call StartResidentProgramm

                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4
                inc dx

                int 21h

;-------------------------------------------------------------------------------
;
;
;
;
;
;
;-------------------------------------------------------------------------------

StartResidentProgramm proc

;---------------Interrapt 09h---------------------------------------------------
                mov ax, 3509h
                int 21h

                mov Int09Ofs, bx
                mov bx, es
                mov Int09Seg, bx

                push 0
                pop es

                mov bx, 09h * 4
                
                push cs
                pop ax

                cli
                mov es: [bx], offset FrameMaker
                mov es: [bx+2], ax
                sti

;---------------Interrapt 08h---------------------------------------------------
                mov ax, 3508h
                int 21h

                mov Int08Ofs, bx
                mov bx, es
                mov Int08Seg, bx

                push 0
                pop es

                mov bx, 08h * 4

                push cs
                pop ax

                cli
                mov es: [bx], offset Int08StatusScanner
                mov es: [bx+2], ax
                sti

;---------------End programm resident-------------------------------------------
                mov ax, 3100h
                mov dx, offset EOP
                shr dx, 4
                inc dx
                int 21h

                ret
                endp

;-------------------------------------------------------------------------------
;							FRAME MAKER
;Entry: 	BH - hight
;		BL - lenght
;		DH - frame color
;		SI - addres of frame chars
;Retrn: 	none
;Destr:		AX, BX, CX, DX, ES, SI, DI
;-------------------------------------------------------------------------------

FrameMaker	proc

                PUSH_TO_SAVE_ALL_REGS

                mov bh, FRAME_HIGHT
                mov bl, FRAME_LENGHT
                mov dh, FRAME_COLOR
                lea si, FrameMassive

                call TakeFrameCoordinate		        ; DI - coords

                push VIDEO_MEM
                pop es

                xor ax, ax
                mov ah, dh

                push di

                mov cl, bl

                call DrawOneLine				; DrawLine

                pop di
                add di, SCREEN_LENGHT_IN_MEM

                mov cl, bh

;		----------------------------------------
        StartDrawing:
                push di
                push cx

                mov cl, bl

                call DrawOneLine

                pop cx
                sub si, 3
                pop di
                add di, SCREEN_LENGHT_IN_MEM

                loop StartDrawing
;		----------------------------------------

                add si, 3
                mov cl, bl

                call DrawOneLine

                POP_SAVED_REGS

                ret
                endp

;------------------------------------------------------------------------------
;							DRAW ONE LINE
;NOTE!	ES must be b800!
;
;Entry:	
;		CX - lenght of frame
;		AH - color of frame
;		SI - addres of char massive
;		DI - coordinates
;
;Retrn:	        none
;Destr:         CX, SI, DI
;------------------------------------------------------------------------------
DrawOneLine	proc

                lodsb							; add first symbol
                stosw							; move into graphic mem

                lodsb							; take new symbol

                rep stosw						; mul them into graphic mem

                lodsb							; add last symbol
                stosw							; move into graphic mem

                ret
                endp
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;							TAKE COORDINATES
;Entry:		BL - lenght of frame
;		BH - hight of frame
;Retrn:		DI - coordinate
;Destr:		AX, BX, CX, DI
;
;------------------------------------------------------------------------------
TakeFrameCoordinate	proc

                mov ax, SCREEN_HIGHT_IN_VISUAL
                sub al, bh
                sub ax, 2
                shr ax, 1
                mov cx, ax
                shl ax, 5
                shl cx, 3
                add ax, cx
                shl ax, 2

                mov cx, SCREEN_LENGHT_IN_MEM / 2
                sub cl, bl
                shr cx, 1
                shl cx, 1
                
                add ax, cx

                sub ax, 2

                mov di, ax

                ret
                endp
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;                           WITH OR NOT WITH FRAME
;Entry:         
;Retrn:         
;Destr:         
;
;-----------------------------------------------------------------------------
WithOrNotWithFrame      proc

                push ax

                in al, 60h

                cmp al, FRAME_ACTIVATOR
                jne NotActivateSymb

                pop ax

                call FrameMaker

                push ax

                mov ActivateFrame, 1
                jmp ActivateKeyboard

        NotActivateSymb:

                cmp al, STOP_FRAME
                jne NotSpecialSymb

                mov ActivateFrame, 

        ActivateKeyboard:
                in al, 61h                              ; закидываем в al то, что лежит в порте 61h
                mov ah, al                              ; сохраняем
                or al, 80h                              ; разрешаем клавиатуру
                out 61h, al             
                xchg al, ah             
                out 61h, al                             ; выводим значение в порт

                mov al, 20h                             ; Конец прерывания
                out 20h, al

                pop ax

                iret
        
        NotSpecialSymb:
                
                pop ax
                
                db 0eah

                Int09Ofs    dw 0
                Int09Seg    dw 0

                endp

;-----------------------------------------------------------------------------
;                           INT 08 STATUS SCANER
;Enrty:
;Retrn:
;Destr:
;
;-----------------------------------------------------------------------------
Int08StatusScanner      proc

                call WithOrNotWithFrame

                cmp ActivateFrame, 1
                jne NothingToDraw

                PUSH_TO_SAVE_ALL_REGS

                Call OutputRegs

                POP_SAVED_REGS

        NothingToDraw:

                db 0eah

                Int08Ofs dw 0
                Int08Seg dw 0
                
                endp

;-----------------------------------------------------------------------------
;                           OUTPUT REGS
;Entry:         none
;Retrn:         none
;Destr:         none
;
;-----------------------------------------------------------------------------
OutputRegs      proc

                PUSH_TO_SAVE_ALL_REGS
                push cs

                push VIDEO_MEM
                pop es

                mov ah, 4eh
                mov di, 80 * 4 * 2 + 80 - 8 + 1
    
                                
                ret

                endp
        
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------


;-----------------------------------------------------------------------------
;                           WRITE REGISTER
;
;       Warning! ES must be in 0b800h!
;
;Entry:     FIRST_REG_LETTER    - first register`s letter
;           SECOND_REG_LETTER   - second register`s letter
;           AH                  - color of the text
;           DX                  - register`s data
;           DI                  - address in video segment
;Retrn:     DI - address in video segment
;Destr:     AL
;
;-----------------------------------------------------------------------------
WriteRegister   proc

                xor cx, cx

                mov al, FIRST_REG_LETTER
                stosw

                mov al, SECOND_REG_LETTER
                stosw

                mov al, ':'
                stosw

                mov al, ' '
                stosw

                mov cl, dl
                and cl, 0Fh
                call AntiAtoi

                mov cl, dl
                shr cl, 4
                call AntiAtoi

                mov cl, dh
                call AntiAtoi

                mov cl, dh
                shr cl, 4
                call AntiAtoi

                add di, 160 - 8 * 2

                ret 
                endp

;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
;							ANTI ATOI
;Entry:     CX - number to output
;           DI - address in videoseg
;Retrn:     AL - converted number
;Destr:     AL, BX, CX
;
;-----------------------------------------------------------------------------

AntiAtoi    proc

                mov bx, offset HEX_SYMBOLS

                add bx, cx
                mov al, cs:[bx]    

                stosw   

                ret
                endp
;-----------------------------------------------------------------------------

;FrameMassive 	    db 0c9h, 0cbh, 0bbh, 0cch, ' ', 0b9h, 0c8h, 0cah, 0bch
FrameMassive 	    db '1234 6789'

FIRST_REG_LETTER    db 0
SECOND_REG_LETTER   db 0

HEX_SYMBOLS         db '0123456789ABCDEF'
REGIATERS_SEQUENCE  db 'AXBXCXDXSIDIBPSPDSESSSCS'

ActivateFrame       db 1

EOP:

            end Start
