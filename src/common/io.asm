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

use16
cpu 8086
org 0C00h

	jmp start

	jmp get_PS2_controller_response
	jmp get_PS2_device_poll
	
	jmp send_PS2_controller_command
	jmp send_PS2_controller_next_command
	jmp send_PS2_port_one
	jmp send_PS2_port_two
	
	jmp initialize_PS2
	
	jmp enable_A20
	jmp enable_A20_PS2
	jmp testA20

start:
	;call initialize_PS2 ; Initialize PS/2 devices
	
	mov al, 0F4h
	call send_PS2_port_one
	
	mov al, 0F4h
	call send_PS2_port_two
	
	; Get PS/2 key loop
	mov ah, 0Eh
.loop:
	call get_PS2_device_poll
	
	int 10h
	
	jmp .loop
	
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
	
ps2_deb_1	db "Disabling PS/2 devices",0Dh,0Ah,00h
ps2_deb_2	db "Flushing output buffer",0Dh,0Ah,00h
ps2_deb_3	db "Doing controller self test",0Dh,0Ah,00h
ps2_deb_4	db "Enabling PS/2 devices",0Dh,0Ah,00h
ps2_deb_5	db "Resetting PS/2 devices",0Dh,0Ah,00h
ps2_deb_6	db "Finished initialization",0Dh,0Ah,00h

initialize_PS2:
	push ax
	push bx

	cli
	
	xor bx, bx
	
	push si
	mov si, ps2_deb_1
	call printf
	pop si
	
	; Disable PS/2 devices
	mov al, 0ADh ; Disable PS/2 device 1
	call send_PS2_controller_command
	jc .error
	
	mov al, 0A7h ; Disable PS/2 device 2
	call send_PS2_controller_command
	jc .error
	
	push si
	mov si, ps2_deb_2
	call printf
	pop si
	
	; Flush output buffer
	in al, 060h
	
	; Set correct controller configuration byte
	mov al, 020h ; Read old controller value
	call send_PS2_controller_command
	jc .error
	call get_PS2_controller_response
	jc .error
	
	and al, 01000011b ; Set new controller value (disable translation and IRQs)
	
	xchg al, ah ; AH <--> AL
	mov al, 060h ; AH is the next byte, send command 060h!
	call send_PS2_controller_next_command
	jc .error
	xchg al, ah ; Reverse stuff again, now AH is in AL
	
	mov byte [configuration_byte], al ; Save old configuration byte (for hardware support)
	
	test al, 00100000b ; Test if there is a dual channel PS/2 port
	jnz short .dual
.single:
	or bl, 00000001b ; Set bit 0 in bl
	jmp short .do_self_test
.dual:
	or bl, 00000011b ; Set both bits in bl
.do_self_test:
	push si
	mov si, ps2_deb_3
	call printf
	pop si

	; Do controller self test
	mov al, 0AAh
	call send_PS2_controller_command
	jc .error
	call get_PS2_controller_response
	jc .error
	
	cmp al, 055h ; Check that controller passed self test
	jne .error
	
	; On some old hardware, the controller byte of the PS/2 controller
	; is reset to their defaults, to avoid this, the controller byte
	; is set again
	mov ah, byte [configuration_byte]
	mov al, 060h
	call send_PS2_controller_next_command
	jc .error
	
	; Perform interface tests, test the PS/2 ports and see wich one works
	mov al, 0ABh
	call send_PS2_controller_command
	jc .error
	call get_PS2_controller_response
	jc .error
	
	test al, al ; If 00h, then test passed
	jnz .first_device_fail
	
	test bl, 00000010b ; Does PS/2 controller has 2 devices?
	jnz .check_second_device
	
	jmp short .enable_device
.check_second_device:
	mov al, 0A9h
	call send_PS2_controller_command
	jc .error
	call get_PS2_controller_response
	jc .error
	
	test al, al ; If 00h, then test passed
	jnz .second_device_fail
	jmp short .enable_device
.first_device_fail:
	and bl, 00000001b
.second_device_fail:
	and bl, 00000010b
.enable_device:
	push si
	mov si, ps2_deb_4
	call printf
	pop si

	test bl, 00000001b ; Do not enable failing first device
	jz .reset_second_device ; Use second instead (if possible)
	
	mov al, 0AEh ; Send enable command
	call send_PS2_controller_command
	jc .error
	
	test bl, 00000010b ; Is here more devices?
	jnz .enable_second_device
	
	jmp short .reset_device
.enable_second_device:
	test bl, 00000010b ; Is device 2 even working?
	jnz .enable_second_device
	
	; Ok all set, enable second device
	mov al, 0A8h
	call send_PS2_controller_command
	jc .error
	
.reset_device:
	push si
	mov si, ps2_deb_5
	call printf
	pop si

	test bl, 00000001b
	jz .reset_second_device
	
	mov al, 0FFh
	call send_PS2_port_one
	jc .error
	call get_PS2_device_poll ; Get response
	jc .error
	
	cmp al, 0FAh
	jne .error

	test bl, 00000010b
	jnz .reset_second_device
	
	jmp short .end
.reset_second_device:
	mov al, 0FFh
	call send_PS2_port_two
	jc .error
	call get_PS2_device_poll ; Get response
	jc .error
	
	cmp al, 0FAh
	jne .error
.end:
	push si
	mov si, ps2_deb_6
	call printf
	pop si

	sti
	
	pop bx ; Restore registers
	pop ax
	
	ret
	
.error:
	jmp short .end
	
configuration_byte		db 0

;
; Gets data from PS/2 device using polling method
;
get_PS2_device_poll:
	push ax
	push cx
	mov cx, 2000h
.poll: ; Poll for status register (is PS/2 device sending data)
	in al, 064h ; Get register status byte
	
	test al, 00000001b ; Check if bit 0 is set
	jnz .do_out
	
	loop .poll
	jmp .error
.do_out:
	pop cx
	pop ax
	
	in al, 060h ; Get the data
.end:
	clc
	
	ret
	
.error:
	pop cx
	pop ax
	
	stc
	
	jmp short .end

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
	ret

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
	jnz .do_in
	
	test al, 10000000b ; Check if there was a parity error
	jnz .error
	
	test al, 01000000b ; Check for timeout-error
	jnz .error
	
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
