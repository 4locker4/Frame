;------------------------------------------------------------------------------
;				    Make a frame
;------------------------------------------------------------------------------

.model tiny
.data
			InpArray 		db 127, 127 dup(?)

			FrameMassive 	db 0c9h, 0cbh, 0bbh, 0cch, ' ', 0b9h, 0c8h, 0cah, 0bch,
							db 03h, 03h, 03h, 03h, ' ', 03h, 03h, 03h, 03h, 
							db '1234 6789',
							db 'xyiI Iloh'

;------------------------------------------------------------------------------
;					CONSTANTS
;------------------------------------------------------------------------------

VIDEO_MEM 				equ 0b800h
SCREEN_LENGHT_IN_MEM	equ 160
LENGHT_OF_FRAME_MASSIVE equ 10
CENTER_OF_SCREEN_CLMN	equ 11
SCREEN_HIGHT_IN_VISUAL	equ 25
;-----------------------------------------------------------------------------

.code

org 100h

Start:		
			cld

			call DataTaker
			call Dispatcher

			mov ah, 4ch
			int 21h

;-----------------------------------------------------------------------------
;							DATA TAKER
;Enrty:
;Retrn:	BH - hight
;		BL - lenght
;		DH - frame color
;		DL - text color
;		DI - addres of text massive
;		SI - addres of frame chars
;Destr: AX, BX, DX, DI, SI
;-----------------------------------------------------------------------------
DataTaker	proc

			mov ah, 0ah
			lea dx, InpArray
			int 21h

			mov di, dx
			add di, 2
			
			call AtoiDec					; take lenght
			push bx

			call AtoiDec					; take hight
			push bx

			call AtoiHex					; take color of text
			push bx

			call AtoiHex					; take color of frame
			push bx

			call AtoiDec					; take num of frame
			
			cmp bx, 0						; switch to frames
			je UsersFrame

			lea ax, FrameMassive
			mov si, ax

			mov ax, bx
			sub ax, 1
			mov bx, LENGHT_OF_FRAME_MASSIVE
			mul bx
			add si, ax

			jmp EndOfFunc

		UsersFrame:
			add di, 1

 			mov si, di							; address of users frame

			add di, LENGHT_OF_FRAME_MASSIVE + 1

		EndOfFunc:	
			add di, 1

			pop ax

			pop dx
			mov dh, al

			pop ax

			pop bx
			mov bh, al

			ret
			endp



;-----------------------------------------------------------------------------
;							DISPATCHER
;Entry: 	BH - hight
;		BL - lenght
;		DH - frame color
;		DL - text color
;		DI - addres of text massive
;		SI - addres of frame chars
;Retrn: 	none
;Destr:		AX, BX, CX, DX, ES, SI, di	---- REFACTOR ----
;------------------------------------------------------------------------------

Dispatcher	proc

			push di									; save addres of text massive

			call TakeFrameCoordinate				; ax - coords

			mov ax, VIDEO_MEM
			mov es, ax
			xor ax, ax
			mov ah, dh

			push di

			mov cl, bl

			call DrawOneLine						; DrawLine

			pop di
			add di, SCREEN_LENGHT_IN_MEM			; magic number

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

			pop di									; take the address of text massive

			call WriteAText

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
;Retrn:	none
;Destr: CX, SI, di
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
;							WRITE A TEXT
;Entry:	DL - text color
;		DH - lenght of frame
;			DI - addres of text massive
;Retrn:		none
;Destr:		AX, CX, DX, DI, SI
;------------------------------------------------------------------------------

WriteAText  proc

			push di
			call Strlen
			pop si

			call TakeCoordinatesOfText

			mov ax, VIDEO_MEM
			mov es, ax

			mov ah, dl
;		----------------------------------------
		Print:
			lodsb								; si - text massive
			stosw								; di

			loop Print
;		----------------------------------------

			ret
			endp

;------------------------------------------------------------------------------
;							TAKE COORDINATES OF TEXT
;Entry:		CX - lenght of text
;Retrn:		DI - address of text
;Destr:		BX, DI
;------------------------------------------------------------------------------
TakeCoordinatesOfText	proc

			mov di, SCREEN_LENGHT_IN_MEM * CENTER_OF_SCREEN_CLMN

			mov bx, SCREEN_LENGHT_IN_MEM / 2
			sub bx, cx
			add bx, 4
			shr bx, 1
			shl bx, 1

			add di, bx
			sub di, 2

			ret
			endp

;------------------------------------------------------------------------------
;							ATOI DEC (char to dec)
;Entry:		DI - addres of symbols
;Retrn: 	BX - number
;Destr:		AX, DI, SI, ES
;------------------------------------------------------------------------------
AtoiDec proc
		xor bx, bx

		mov ax, ds
		mov es, ax

		mov si, di
		add di, 1

;		----------------------------------------
		Cycle:
			mov ax, bx					; mul 10
			shl bx, 3
			shl ax, 1
			add bx, ax

			lodsb
			sub ax, '0'
			add bx, ax

			mov ax, ' '
			scasb
			jne Cycle
;		----------------------------------------
		
		ret
		endp
;------------------------------------------------------------------------------
;							ATOI HEX
;Entry:		DI - addres of symbols
;Retrn: 	BX - number
;Destr:		AX, DI, SI, ES
;------------------------------------------------------------------------------
AtoiHex	proc
		xor bx, bx

		mov ax, ds
		mov es, ax

		mov si, di
		add di, 1

;		----------------------------------------
	TakeNum:
		shl bx, 4

		xor ax, ax
		lodsb
	NUM:
		cmp ax, 'a'
		jae hex
		sub ax, '0'
		jmp RES

	HEX:
		sub ax, 'a'
		add ax, LENGHT_OF_FRAME_MASSIVE + 1

	RES:
		add bx, ax

		mov ax, ' '
		scasb
		jne TakeNum
;		----------------------------------------
		
		ret
		endp			

;------------------------------------------------------------------------------
;							STRLEN
;Entry: 	DI - address of string
;Retrn:		CX - lenght
;Destr:		AX, CX, DI, ES
;
;------------------------------------------------------------------------------
Strlen proc
			mov ax, ds
			mov es, ax

			xor ax, ax
			xor cx, cx
			dec cx
			
			mov al, '$'

			repne scasb

			neg cx
			sub cx, 2

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

			xor cx, cx

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
;------------------------------------------------------------------------------

end Start