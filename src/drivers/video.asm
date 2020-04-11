;  VIDEO.ASM
;
;  General VGA/CGA/etc Video driver
;
;  Redistribution and use in source and binary forms, with or without
;  modification, are permitted provided that the following conditions are
;  met:
;  
;  * Redistributions of source code must retain the above copyright
;    notice, this list of conditions and the following disclaimer.
;  * Redistributions in binary form must reproduce the above
;    copyright notice, this list of conditions and the following disclaimer
;    in the documentation and/or other materials provided with the
;    distribution.
;  * Neither the name of the  nor the names of its
;    contributors may be used to endorse or promote products derived from
;    this software without specific prior written permission.
;  
;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
;  

use16
cpu 8086
org 7000h

;
; Driver header
;
commonDriverJumptable:
	jmp start			; Used when driver is loaded as a program
	jmp initVideo		; Initialize video driver
	jmp detectVideoMode	; Detect video mode
	jmp stub			; Plot a pixel
	jmp putCharacter	; Plot a character
	jmp stub			; Set video mode
	jmp stub			; Get video mode
	jmp stub			; Get a pixel
	jmp stub			; Get a character
	jmp stub			; Plug 'n Play Video (Correctly set video mode)
	jmp stub			; Change attribute for character
	jmp gotoXandY		; Goto X and Y (No effect on graphical mode)
	jmp clearScreen		; Clear screen
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved
	jmp stub			; Reserved

;
; Common Driver Metadata
; Useful data for driver-loaders
;
commonDriverMetadata:
	versionMajor		db 1 ; Major version 
	versionMinor		db 2 ; Minor version
	versionBuild		db 2 ; Build version
	name				db "VIDEO_DS" ; Name of the driver
	reserved			db 0
	osVersion			db 1
	checksum			dw 6969h ; Magic number
	deviceType			dw 0000h ; Set device type as "VIDEO DRIVER"
	reserved			times 32 db 0

;
; Stub for driver (put some text here and return)
;
start:
	mov ah, 0Eh
	mov al, '?'
	int 10h
	ret
	
;
; Stub function
; Returns clear carry to advise caller that function is not supported
;
stub:
	clc
	ret
	
;
; Initializes driver data
;
initialize:
	ret

;
; Detects video mode
; Returns value in AX (see below for value meanings!)
;
detectVideoMode:
	push es
	push ax
	push bx
	
	xor ax, ax ; Get information from BDA
	mov es, ax
	mov bx, 410h
	
	mov ax, word [es:bx] ; Get word from BDA
	
	and ax, 30h ; Mask out some bits
	
	; Now the return value with contain any of those:
	; 00h = No video (?)
	; 20h = Colour
	; 30h = Monochrome
	; Any other value should be treated as "error"
	
	stc
	
	pop bx
	pop ax
	pop es
	ret

;
; Puts a character in screen
; AL = Character
;
putCharacter:
	push si
	push di
	push ax
	push es
	push bx
	
	mov ah, [text_attr]
	
	cmp al, 0Dh
	je .newline
	
	cmp al, 0Ah
	je .return
	
	cmp al, 08h
	je .back
	
	push ax
	
	mov ax, [text_seg] ;segmentate
	mov es, ax ;to text location
	
	mov ax, word [text_y] ;see if it is time to scroll
	cmp ax, word [text_h]
	jge .do_scroll
	
	mov ax, [text_w] ;y*w
	mov bx, [text_y]
	mul bx ;result now in ax
	add ax, word [text_x] ;add x to ax
	shl ax, 1
	mov bx, ax
	
	pop ax
	
	mov word [es:bx], ax ;put char with attrib
	
	inc word [text_x]
.end:
	pop bx
	pop es
	pop ax
	pop di
	pop si
	ret
.do_scroll:
	pop ax
	
	call _scroll
	
	mov ax, [text_h]
	dec ax
	mov word [text_y], ax
	
	jmp short .end
.newline:
	inc word [text_y] ;increment y
	
	push ax
	mov ax, word [text_y] ;see if it is time to scroll
	cmp ax, word [text_h]
	jge .do_scroll_new
	pop ax
.return:
	mov word [text_x], 0 ;return to 0
	jmp short .end
.back:
	dec word [text_x] ;decrement char
	jmp short .end
	
.do_scroll_new:
	pop ax
	
	call _scroll
	
	mov ax, [text_h]
	dec ax
	mov word [text_y], ax
	
	jmp short .return
	
;
; Goto X and Y
; AX = X
; BX = Y
;
gotoXandY:
	push ax
	push bx
	
	mov word [text_x], ax
	mov word [text_y], bx
	
	pop bx
	pop ax
	ret
	
;
; Scrolls screen by one
; No parameters
;
scrollScreen:
	push ax
	
	dec word [text_y] ;decrease y
	dec word [text_y]
	
	mov ax, [text_seg] ;set segments
	mov es, ax ;to text location
	
	mov cx, word [text_w] ;bytes to copy
	mov ax, word [text_h] ;(size of screen - 1 scanline)
	dec ax
	mul cx
	mov cx, ax ;transfer to counter register
	
	xor di, di ;di starts at line 0
	
	mov si, [text_w]
	shl si, 1 ;shift to left to align with word
.move_lines:
	mov ax, word [es:si]
	mov word [es:di], ax
	
	add di, 2
	add si, 2
	
	loop .move_lines
	
	mov di, [text_w] ;position of last scanline
	mov ax, [text_h]
	dec ax
	mul di
	mov di, ax ;transfer to di
	shl di, 1 ;align to word by shifting to left
	
	mov cx, word [text_w]
	
	mov ah, byte [text_attr]
	mov al, ' '
.clear_last: ;clear bottomest line of the text memory
	mov word [es:di], ax
	
	add di, 2
	
	loop .clear_last
	
	pop ax
	ret
	
;
; Clears the screen
; No parameters
;
clearScreen:
	push ax
	push bx
	push cx
	push es
	push di
	
	mov ax, [text_seg] ;segmentate
	mov es, ax ;to text location
	
	mov bx, [text_w] ;total size of thing
	mov ax, [text_h]
	mul bx
	mov cx, ax ;place in the counter
	
	mov ah, [text_attr]
	mov al, ' '
	xor di, di
.loop:
	mov word [es:di], ax
	
	add di, 2 ;skip a full word
	
	loop .loop
	
	pop di
	pop es
	pop cx
	pop bx
	pop ax
	ret
