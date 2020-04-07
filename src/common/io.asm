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
	
	;jmp initialize_PS2
	
	jmp enable_A20
	jmp enable_A20_PS2
	jmp testA20
	
	keymap		db 01h ; Use en-US keymap as default

start:
	mov ah, 0Eh
	mov al, '%'
	int 10h

	;call initialize_PS2 ; Initialize PS/2 devices
	;call get_PS2_info	; Get device info of PS/2 devices
	
	; Get PS/2 key loop
.loop:
	call wait_for_key
	
	jmp short .loop
	
printf:
	push ax
	push si
	
	mov ah, 0Eh
.loop:
	lodsb
	
	test al, al
	jz short .end
	
	int 10h
	
	jmp short .loop
.end:
	pop si
	pop ax
	ret

;=======================================================================
; UNUSED
;=======================================================================

;
; Enables IRQs
;
enableIRQ:
	push ax
	
	mov al, 0FDh ; Master PIC
	out 021h, al
	mov al, 0FFh ; Slave PIC
	out 0A1h, al
	
	sti ; Enable IRQ generation
	
	pop ax
	ret

;
; Remaps the PIC, with offs1 (BL) and offs2 (BH)
;
remapPIC:
	push ax
	push bx

	in al, 021h ; Save the PIC masks
	mov [.master_PIC_mask], al ; Master
	in al, 0A1h
	mov [.slave_PIC_mask], al ; Slave
	
	mov al, 011h
	out 020h, al ; Start PIC initialization
	out 0A0h, al
	
	mov al, bl ; Set master PIC offset
	out 021h, al
	mov al, bh ; Set slave PIC offset
	out 0A1h, al
	
	mov al, 4 ; Tell master PIC about slave PIC in IRQ2
	out 021h, al
	mov al, 2 ; Tell slave PIC its cascade identity
	out 0A1h, al
	
	mov al, 1 ; Set master PIC in 8086 mode
	out 021h, al
	mov al, 1 ; Set slave PIC in 8086 mode
	out 0A1h, al
	
	mov al, [.master_PIC_mask] ; Restore master PIC mask
	out 021h, al
	mov al, [.slave_PIC_mask] ; Restore slave PIC mask
	out 0A1h, al
	
	pop bx
	pop ax
	ret
	
.master_PIC_mask	db 0
.slave_PIC_mask		db 0

configuration_byte	db 0

setIRQ:
	push ax
	push bx
	push di
	push es
	
	xor ax, ax
	mov es, ax
	
	xor bx, bx ; Set IRQ0 >> Timer PIT
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ0 ; Set offset
	
	mov bx, 1*4 ; Set IRQ1 >> PS/2 First device output
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ1 ; Set offset
	
	mov bx, 2*4 ; Set IRQ2 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ2 ; Set offset
	
	mov bx, 3*4 ; Set IRQ3 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ3 ; Set offset
	
	mov bx, 4*4 ; Set IRQ4 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ4 ; Set offset
	
	mov bx, 5*4 ; Set IRQ5 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ5 ; Set offset
	
	mov bx, 6*4 ; Set IRQ6 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ6 ; Set offset
	
	mov bx, 7*4 ; Set IRQ7 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ7 ; Set offset
	
	mov bx, 8*4 ; Set IRQ8 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ8 ; Set offset
	
	mov bx, 9*4 ; Set IRQ9 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ9 ; Set offset
	
	mov bx, 10*4 ; Set IRQ10 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ10 ; Set offset
	
	mov bx, 11*4 ; Set IRQ11 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ11 ; Set offset
	
	mov bx, 12*4 ; Set IRQ12 >> PS/2 Second device output
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ12 ; Set offset
	
	mov bx, 13*4 ; Set IRQ13 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ13 ; Set offset
	
	mov bx, 14*4 ; Set IRQ14 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ14 ; Set offset
	
	mov bx, 15*4 ; Set IRQ15 >> Unknown
	mov word [es:bx+00h], cs ; Set segment
	mov word [es:bx+02h], IRQ15 ; Set offset
	
	pop es
	pop di
	pop bx
	pop ax
	ret
	
IRQ0:
	push bx
	push ax
	
	mov ax, [.timer_fractions]
	mov bx, [.timer_ms]
	add [.timer_sys_fractions], ax
	adc [.timer_sys_ms], bx
	
	mov al, 020h
	out 020h, al
	
	pop ax
	pop bx
	iret

.timer_fractions		dw 0
.timer_ms				dw 0
.timer_sys_fractions	dw 0
.timer_sys_ms			dw 0

IRQ1:
	push ax
	
	in al, 060h
	mov [PS2Buffer+00h], al
	
	mov ah, 0Eh
	int 10h
	
	mov al, 020h
	out 020h, al
	
	pop ax
	iret
	
IRQ2:
	push ax
	
	mov al, 020h
	out 020h, al
	
	pop ax
	iret
	
IRQ3:
	push ax
	
	mov al, 020h
	out 020h, al
	
	pop ax
	iret
	
IRQ4:
	push ax
	
	mov al, 020h
	out 020h, al
	
	pop ax
	iret

IRQ5:
	push ax
	
	mov al, 020h
	out 020h, al
	
	pop ax
	iret
	
IRQ6:
	push ax
	
	mov al, 020h
	out 020h, al
	
	pop ax
	iret

IRQ7:
	push ax
	
	mov al, 020h
	out 020h, al
	
	pop ax
	iret

IRQ8:
	push ax
	
	mov al, 020h
	out 0A0h, al ; Send 020h to both ports of the PIT
	out 020h, al
	
	pop ax
	iret
	
IRQ9:
	push ax
	
	mov al, 020h
	out 0A0h, al ; Send 020h to both ports of the PIT
	out 020h, al
	
	pop ax
	iret
	
IRQ10:
	push ax
	
	mov al, 020h
	out 0A0h, al ; Send 020h to both ports of the PIT
	out 020h, al
	
	pop ax
	iret
	
IRQ11:
	push ax
	
	mov al, 020h
	out 0A0h, al ; Send 020h to both ports of the PIT
	out 020h, al
	
	pop ax
	iret

IRQ12:
	push ax
	
	in al, 060h
	mov [PS2Buffer+01h], al
	
	mov ah, 0Eh
	int 10h
	
	mov al, 020h
	out 0A0h, al
	out 020h, al
	
	pop ax
	iret
	
PS2Buffer		times 2	db 0

IRQ13:
	push ax
	
	mov al, 020h
	out 0A0h, al ; Send 020h to both ports of the PIT
	out 020h, al
	
	pop ax
	iret
	
IRQ14:
	push ax
	
	mov al, 020h
	out 0A0h, al ; Send 020h to both ports of the PIT
	out 020h, al
	
	pop ax
	iret
	
IRQ15:
	push ax
	
	mov al, 020h
	out 0A0h, al ; Send 020h to both ports of the PIT
	out 020h, al
	
	pop ax
	iret
	
;=======================================================================
; END OF UNUSED
;=======================================================================

wait_for_key:
	push ax
.loop:
	call get_key
	
	cmp al, 128
	je short .loop
	
	mov ah, 0Eh
	int 10h
	
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
