;
; IO.ASM
;
; General Input/Output library
;
; This file is part of LeafDOS
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

%define _QEMU_

use16
cpu 8086
org 0100h

	jmp start

	jmp get_PS2_controller_response
	jmp get_PS2_device_poll
	jmp send_PS2_controller_command
	jmp send_PS2_controller_next_command
	jmp send_PS2_port_one
	jmp send_PS2_port_two
	jmp enable_A20
	jmp enable_A20_PS2
	jmp testA20
	
	jmp putc
	jmp printf
	jmp scroll
	
	jmp wait_for_key
	
	jmp sleep
	
	jmp putc
	
	keymap		db 01h ; Use en-US keymap as default

start:
	;call initialize_PS2 ; Initialize PS/2 devices
	;call get_PS2_info	; Get device info of PS/2 devices
	
	; Get PS/2 key loop
.loop:
	call wait_for_key
	
	jmp short .loop
	
putc:
	push si
	push di
	push ax
	push es
	push bx
	
	mov ah, [text_attr]
	
	cmp al, 0Dh ; Check for newline
	je .newline
	
	cmp al, 0Ah
	je .return
	
	cmp al, 08h
	je .back
	
	push ax
	
	mov ax, [text_seg] ; Segmentate
	mov es, ax ; To text location
	
	mov ax, word [text_y] ; See if it is time to scroll
	cmp ax, word [text_h]
	jge .do_scroll
	
	mov ax, [text_w] ; y*w
	mov bx, [text_y]
	mul bx ; Result now in ax
	add ax, word [text_x] ; Add x to ax
	shl ax, 1
	mov bx, ax
	
	pop ax
	
	mov word [es:bx], ax ; Put char with attrib
	
	inc word [text_x]
.end:
	pop bx ; Restore registers
	pop es
	pop ax
	pop di
	pop si
	ret
.do_scroll:
	pop ax
	
	call scroll
	
	mov ax, [text_h]
	dec ax
	mov word [text_y], ax
	
	jmp short .end

.newline:
	push ax
	mov ax, word [text_y] ; See if it is time to scroll
	cmp ax, word [text_h]
	jge .do_scroll
	pop ax

	inc word [text_y] ; Increment y
.return:
	mov word [text_x], 0 ; Return to 0
	jmp short .end
.back:
	dec word [text_x] ; Decrement char
	jmp short .end

scroll:
	push ax
	
	dec word [text_y] ; Decrease y
	dec word [text_y]
	
	mov ax, [text_seg] ; Set segments
	mov es, ax ; To text location
	
	mov cx, word [text_w] ; Bytes to copy
	mov ax, word [text_h] ; (Size of screen - 1 scanline)
	dec ax
	mul cx
	mov cx, ax ; Transfer to counter register
	
	xor di, di ; DI starts at line 0
	
	mov si, [text_w]
	shl si, 1 ; Shift to left to align with word
.move_lines:
	mov ax, word [es:si]
	mov word [es:di], ax
	
	add di, 2
	add si, 2
	
	loop .move_lines
	
	mov di, [text_w] ; Position of last scanline
	mov ax, [text_h]
	dec ax
	mul di
	mov di, ax ; Transfer to di
	shl di, 1 ; Align to word by shifting to left
	
	mov cx, word [text_w]
	
	mov ah, byte [text_attr]
	mov al, ' '
.clear_last: ; Clear bottomest line of the text memory
	mov word [es:di], ax
	
	add di, 2
	
	loop .clear_last
	
	pop ax
	ret
	
clrscr:
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

printf:
	push ax
	push si
.loop:
	lodsb
	
	test al, al ; Is character zero?
	jz short .end ; Yes, end

	call putc

	jmp short .loop
.end:
	pop si
	pop ax
	ret

text_seg	dw 0B800h
text_w		dw 80
text_h		dw 25
text_x		dw 0
text_y		dw 0
text_attr	dw 01Bh

wait_for_key:
	push ax
.loop:
	call get_key
	
	cmp al, 128
	je short .loop
	
	call putc
	
	pop ax
	ret

;
; Gets a key from the keyboard, sends key in (AL)
;
get_key:
	push bx
	push si
	
	mov bh, ah
	
	call get_PS2_device_poll
.mask:
	mov si, caps
	cmp byte [si], 00h ; Is shift on?
	je short .lower
	
	; Do uppercase
	mov si, en_us.upper
.transform:
	xor ah, ah ; Transform key into the keymap
	add si, ax
	
	mov al, byte [si]
	mov ah, bh
	
	cmp al, 09h
	je short .toggle
.end:
	pop si
	pop bx
	ret
.lower:
	mov si, en_us.lower
	jmp short .transform
.toggle:
	mov si, caps
	neg byte [si]
	
	jmp short .end
	
;01 = ESC		02 = BACK		03 = TAB
;04 = ENTER		05 = LCTRL		06 = LSHIFT
;07 = RSHIFT	08 = LALT		09 = CAPSLOCK
;0A = F1		0B = F2			0C = F3
;0D = F4		0E = F5			0F = F6
;81 = F7		82 = F8			83 = F9
;84 = F10		85 = NUMLOCK	86 = SCROLLOCK
;87 = F11		88 = F12		89 = RALT

caps	db 0 ; Shift boolean for doing upper/lower casing

en_us:
		db "en-us  ",0
	.lower:
		db '?',01h,"1234567890-=",02h,03h,
		db "qwertyuiop[]",04h,05h,"asdfghjkl;'`",06h,
		db "\zxcvbnm,./",07h,'*',08h,' ',09h,0Ah,0Bh,
		db 0Ch,0Dh,0Eh,0Fh,81h,82h,83h,84h,85h,86h,
		db "789-456+1230.",'?','?','?',87h,88h,'?'
		db '?','?','?',128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,'?',
		db '?','?',128,128,'?','?','?','?','?','?',
		db '?','?','?','?','?','?','?','?','?','?',
		db '?','?','?','?','?','?','?','?','?','?',
		db '?','?','?','?','?','?',128,'?','?',89h,
		db '?','?','?'
	.upper:
		db '?',01h,"1234567890_+",02h,03h,
		db "QWERTYUIOP{}",04h,05h,"ASDFGHJKL:@¬",06h,
		db "\ZXCVBNM<>?",07h,'*',08h,' ',09h,0Ah,0Bh,
		db 0Ch,0Dh,0Eh,0Fh,81h,82h,83h,84h,85h,86h,
		db "789-456+1230.",'?','?','?',87h,88h,'?'
		db '?','?','?',128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,128,
		db 128,128,128,128,128,128,128,128,128,'?',
		db '?','?',128,128,'?','?','?','?','?','?',
		db '?','?','?','?','?','?','?','?','?','?',
		db '?','?','?','?','?','?','?','?','?','?',
		db '?','?','?','?','?','?',128,'?','?',89h,
		db '?','?','?'
;
; Gets data from PS/2 device using polling method
;
get_PS2_device_poll:
; QEMU for some reason dosen't supports polling
%ifndef _QEMU_
	push cx
	mov cx, 03h ; 3 tries before giving up
.poll: ; Poll for status register (is PS/2 device sending data)
	in al, 064h ; Get register status byte
	
	test al, 00000001b ; Check if bit 0 is set
	jnz short .do_in
	
	mov ax, 1000h
	call sleep
	
	loop .poll
	jmp short .error
.do_in:
	in al, 060h ; Get the data
	clc
.end:
	pop cx
%endif
%ifdef _QEMU_
	in al, 060h
	clc
%endif
	ret
	
%ifndef _QEMU_
.error:
	stc
	jmp short .end
%endif

;
; Sleeps for (AX) milliseconds
;
sleep:
	push cx
	push ax
	
	xchg ax, cx
.sleep:
	loop .sleep
.end:
	pop ax
	pop cx
	
	ret

;
; Sends data (AL) to the second PS/2 device
;
send_PS2_port_two:
	push cx
	push ax
	
	mov al, 0D4h
	call send_PS2_controller_command
	
	mov cx, 2000h ; Give poller about 255 ms to get data
.poll: ; Poll for status register (is PS/2 controller ready for write?)
	in al, 064h ; Get register status byte
	
	test al, 00000010b ; Check if bit 1 is clear
	jz .do_out
	
	loop .poll
	jmp .error
.do_out:
	pop cx
	pop ax
	
	out 060h, al ; Write data
	
	clc
.end:
	ret
	
.error:
	pop cx
	pop ax
	
	stc
	
	jmp short .end

;
; Sends data (AL) to first PS/2 device
;
send_PS2_port_one:
	push cx
	push ax
	mov cx, 2000h ; Give poller about 255 ms to get data
.poll: ; Poll for status register (is PS/2 controller ready for write?)
	in al, 064h ; Get register status byte
	
	test al, 00000010b ; Check if bit 1 is clear
	jz .do_out
	
	loop .poll
	jmp .error
.do_out:
	pop cx
	pop ax
	
	out 060h, al ; Write data
	
	clc
.end:
	ret
	
.error:
	pop cx
	pop ax
	
	stc
	
	jmp short .end
	ret

;
; Writes a command (AL) to PS/2 controller
;
send_PS2_controller_command:
	out 064h, al
	ret
	
;
; Gets PS/2 controller response (stored in AL)
;
get_PS2_controller_response:
.poll: ; Poll for status register (is PS/2 controller ready for read?)
	in al, 064h ; Get register status byte
	
	test al, 00000001b ; Check if bit 0 is set
	jnz short .do_in
	
	test al, 10000000b ; Check if there was a parity error
	jnz short .error
	
	test al, 01000000b ; Check for timeout-error
	jnz short .error
	
	jmp short .poll
.do_in:
	in al, 060h ; Get response byte
	
	clc
.end:
	ret
	
.error:
	pop ax
	
	stc
	
	jmp short .end
	
;
; Writes a command (AL) and command 2 (AH) to PS/2 controller (double-byte command!)
;
send_PS2_controller_next_command:
	out 064h, al ; Write first command byte
	
	push ax
.poll: ; Poll for status register (is PS/2 controller ready for write?)
	in al, 064h ; Get register status byte
	
	test al, 00000010b ; Check if bit 1 is clear
	jz .do_out
	
	test al, 10000000b ; Check if there was a parity error
	jnz .error
	
	test al, 01000000b ; Check for timeout-error
	jnz .error
	
	jmp short .poll
.do_out:
	pop ax
	
	xchg al, ah
	out 060h, al ; Write second command
	xchg al, ah
	
	clc
.end:
	ret
	
.error:
	pop ax
	
	stc
	
	jmp short .end

enable_A20:
	push ax
	
	call testA20
	
	cmp ax, 1
	je .A20_enabled
.enable_A20_kb:
	call enable_A20_PS2
	
	call testA20
	
	cmp ax, 1
	je .A20_enabled
	
	stc ; Set carry flag
	
	jmp short .end
.A20_enabled:
	clc ; Clear carry flag
.end:
	pop ax
	ret
	
enable_A20_PS2:
	cli
	
	call PS2_wait_send
	mov al, 0ADh
	out 064h, al
	
	call PS2_wait_send
	mov al, 0D0h
	out 064h, al
	
	call PS2_wait_get
	in al, 060h
	
	push ax
	
	call PS2_wait_send
	mov al, 0D1h
	out 064h, al
	
	pop ax
	
	call PS2_wait_send
	or al, 2
	out 060h, al
	
	call PS2_wait_send
	mov al, 0AEh
	out 064h, al
	
	call PS2_wait_send
	sti
	ret

PS2_wait_send:
	in al,0x64
	test al,2
	jnz PS2_wait_send
	ret

PS2_wait_get:
	in al,0x64
	test al,1
	jz PS2_wait_get
	ret

testA20:
	push si ; Save flags and register
	push di
	push ds
	push es
	
	cli
	
	push ax
	mov ah, 0Eh
	mov al, '+'
	int 10h
	pop ax
	
	xor ax, ax ; AX = 0
	mov es, ax ; Lowest segment (0000h)
	
	not ax ; AX = 0FFFFh
	mov ds, ax ; Top segment (64k)
	
	mov di, 0500h
	mov si, 0510h
	
	mov al, byte [es:di]
	push ax
	
	mov al, byte [ds:si]
	push ax
	
	mov byte [es:di], 000h
	mov byte [ds:si], 0FFh
	
	cmp byte [es:di], 0FFh
	
	pop ax
	mov byte [ds:si], al
	
	pop ax
	mov byte [es:di], al
	
	mov ax, 0
	je .end
	
	mov ax, 1
.end:
	pop es
	pop ds
	pop di
	pop si
	ret
