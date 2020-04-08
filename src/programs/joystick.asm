;
; JOYSTICK.ASM
;
; Used for testing joystick (Game port)
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
org 5000h

jmp short start

start:
	
.do_loop:
	call get_joy
	call display_joy
	
	jmp short .do_loop
	
	ret

get_joy:
	mov dx, 0201h
	in al, dx
	out dx, al
	
	mov byte [joyStat], al
	ret
	
display_joy:
	mov al, byte [joyStat]
	
	test al, 00010000b ; A button
	jz .a_btn

.aa_btn:
	test al, 00100000b ; B button
	jz .b_btn
	
.bb_btn:
	test al, 01000000b ; C button
	jz .c_btn
	
.cc_btn:
	test al, 10000000b ; D button
	jz .d_btn
	
.dd_btn:
	test al, 11110000b ; D button
	jnz .no_btn
	
	jmp short .end
.a_btn:
	mov si, a_btn
	jmp short .aa_btn
.b_btn:
	mov si, b_btn
	jmp short .bb_btn
.c_btn:
	mov si, c_btn
	jmp short .cc_btn
.d_btn:
	mov si, d_btn
	jmp short .dd_btn
.no_btn:
	mov si, no_mov
.end:
	call printf
	ret

no_mov		db "NO MOVEMENT",0Dh,0Ah,0
a_btn		db "[A] BUTTON",0Dh,0Ah,0
b_btn		db "[B] BUTTON",0Dh,0Ah,0
c_btn		db "[C] BUTTON",0Dh,0Ah,0
d_btn		db "[D] BUTTON",0Dh,0Ah,0

printf:
	push si
	push ax
	
	mov ah, 0Eh
.loop:
	lodsb

	test al, al
	jz short .end
	
	int 10h
	
	jmp short .loop
.end:
	pop ax
	pop si
	ret

joyStat	db 0
