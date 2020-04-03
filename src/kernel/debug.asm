;@name:			dumpregs
;@desc:			prints all registers and debug stuff
;@param:		n/a
;@return:		n/a
_dumpregs:
	push ax
	
	push dx
	push cx
	push bx
	push ax
	push di
	push si
	
	mov si, .si
	call near _printf
	pop ax ;si
	call near print_word
	mov al, ' '
	call near _putc
	
	mov si, .di
	call near _printf
	pop ax ;di
	call near print_word
	mov al, ' '
	call near _putc
	
	mov si, .ax
	call near _printf
	pop ax ;ax
	call near print_word
	mov al, ' '
	call near _putc
	
	mov si, .bx
	call near _printf
	pop ax ;bx
	call near print_word
	mov al, ' '
	call near _putc
	
	mov si, .cx
	call _printf
	pop ax ;cx
	call near print_word
	mov al, ' '
	call near _putc
	
	mov si, .dx
	call near _printf
	pop ax ;dx
	call near print_word
	
	mov si, .nl
	call near _printf
	
	pop ax
	ret
	
.ax			db "AX: ",0
.bx			db "BX: ",0
.cx			db "CX: ",0
.dx			db "DX: ",0
.si			db "SI: ",0
.di			db "DI: ",0
.es			db "ES: ",0
.ds			db "DS: ",0
.nl			db 13,0

;@name:			dissasembly
;@desc:			dissasemblies instruction in memory
;@param:		si: memory
;@return:		n/a
_dissasembly: ;super basic dissasembly
	push si
	push ax
	
	lodsb ;get first byte
	
	;first check byte-opcodes
	cmp al, 037h ;aaa
	je .its_aaa
	
	cmp al, 098h ;cbw
	je .its_cbw
	
	cmp al, 0F8h ;clc
	je .its_clc
	
	cmp al, 0FCh ;cld
	je .its_cld
	
	cmp al, 0FAh ;cli
	je .its_cli
	
	cmp al, 0F5h ;cmc
	je .its_cmc
	
	cmp al, 0A6h ;cmpsb
	je .its_cmpsb
	
	cmp al, 0A7h ;cmpsw
	je .its_cmpsw
	
	cmp al, 099h ;cwd
	je .its_cwd
	
	cmp al, 027h ;daa
	je .its_daa
	
	cmp al, 02Fh ;das
	je .its_das
	
	cmp al, 048h ;dec ax
	je .its_dec_ax
	
	cmp al, 04Ch ;dec bp
	je .its_dec_bp
	
	cmp al, 04Ah ;dec bx
	je .its_dec_bx
	
	cmp al, 049h ;dec cx
	je .its_dec_cx
	
	cmp al, 04Fh ;dec di
	je .its_dec_di
	
	cmp al, 04Dh ;dec si
	je .its_dec_si
	
	cmp al, 04Bh ;dec sp
	je .its_dec_sp
	
	cmp al, 0F4h ;hlt
	je .its_hlt
	
	cmp al, 0ECh ;in al, dx
	je .its_in_al_dx
	
	cmp al, 0EDh ;in ax, dx
	je .its_in_ax_dx
	
	cmp al, 040h ;inc ax
	je .its_inc_ax
	
	cmp al, 045h ;inc bp
	je .its_inc_bp
	
	cmp al, 043h ;inc bx
	je .its_inc_bx
	
	cmp al, 041h ;inc cx
	je .its_inc_cx
	
	cmp al, 047h ;inc di
	je .its_inc_di
	
	cmp al, 046h ;inc si
	je .its_inc_si
	
	cmp al, 044h ;inc sp
	je .its_inc_sp
	
	cmp al, 042h ;inc dx
	je .its_inc_dx
	
	cmp al, 0CCh ;int
	je .its_int_3
	
	cmp al, 0CEh ;into
	je .its_into
	
	cmp al, 0CFh ;iret
	je .its_iret
	
	cmp al, 09Fh ;lahf
	je .its_lahf
	
	cmp al, 0ACh ;lodsb
	je .its_lodsb
	
	cmp al, 0ADh ;lodsw
	je .its_lodsw
	
	cmp al, 0A4h ;movsb
	je .its_movsb
	
	cmp al, 0A5h ;movsw
	je .its_movsw
	
.unknown:
	mov si, .unknown_op
	jmp .end
.its_aaa:
	mov si, .aaa
	jmp .end
.its_cwd:
	mov si, .cwd
	jmp .end
.its_cbw:
	mov si, .cbw
	jmp .end
.its_clc:
	mov si, .clc
	jmp .end
.its_cld:
	mov si, .cld
	jmp .end
.its_cli:
	mov si, .cli
	jmp .end
.its_cmc:
	mov si, .cmc
	jmp .end
.its_cmpsb:
	mov si, .cmpsb
	jmp .end
.its_cmpsw:
	mov si, .cmpsw
	jmp .end
.its_daa:
	mov si, .daa
	jmp .end
.its_das:
	mov si, .das
	jmp .end
.its_dec_ax:
	mov si, .dec
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .ax
	jmp .end
.its_dec_bx:
	mov si, .dec
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .bx
	jmp .end
.its_dec_cx:
	mov si, .dec
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .cx
	jmp .end
.its_dec_bp:
	mov si, .dec
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .bp
	jmp .end
.its_dec_sp:
	mov si, .dec
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .sp
	jmp .end
.its_dec_si:
	mov si, .dec
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .si
	jmp .end
.its_dec_di:
	mov si, .dec
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .di
	jmp .end
.its_hlt:
	mov si, .hlt
	jmp .end
.its_in_al_dx:
	mov si, .in
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .al
	call near _printf
	mov al, ','
	call near _putc
	mov si, .dx
	jmp .end
.its_in_ax_dx:
	mov si, .in
	call near _printf
	mov si, .ax
	call near _printf
	mov al, ','
	call near _putc
	mov si, .dx
	jmp .end
.its_inc_ax:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .ax
	jmp .end
.its_inc_bx:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .bx
	jmp .end
.its_inc_cx:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .cx
	jmp .end
.its_inc_bp:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .bp
	jmp .end
.its_inc_dx:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .dx
	jmp .end
.its_inc_sp:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .sp
	jmp .end
.its_inc_si:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .si
	jmp .end
.its_inc_di:
	mov si, .inc
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .di
	jmp .end
.its_int_3:
	mov si, .int
	call near _printf
	mov al, ' '
	call near _putc
	mov si, .three
	jmp .end
.its_into:
	mov si, .into
	jmp .end
.its_iret:
	mov si, .iret
	jmp .end
.its_lahf:
	mov si, .lahf
	jmp .end
.its_lodsb:
	mov si, .lodsb
	jmp .end
.its_lodsw:
	mov si, .lodsw
	jmp .end
.its_movsb:
	mov si, .movsb
	jmp .end
.its_movsw:
	mov si, .movsw
	jmp .end
.end:
	call near _printf
	pop ax
	pop si
	ret
	
.three			db "3",0
.aaa			db "AAA",0
.cbw			db "CBW",0
.cwd			db "CWD",0
.clc			db "CLC",0
.cld			db "CLD",0
.cli			db "CLI",0
.cmc			db "CMC",0
.cmpsb			db "CMPSB",0
.cmpsw			db "CMPSW",0
.daa			db "DAA",0
.das			db "DAS",0
.dec			db "DEC",0
.inc			db "INC",0
.hlt			db "HLT",0
.in				db "IN",0
.int			db "INT",0
.into			db "INTO",0
.iret			db "IRET",0
.lahf			db "LAHF",0
.lodsb			db "LODSB",0
.lodsw			db "LODSW",0
.movsb			db "MOVSB",0
.movsw			db "MOVSW",0
.unknown_op		db "UNKNOWN OPCODE",0

.al				db "AL",0
.ah				db "AH",0
.ax				db "AX",0
.bx				db "BX",0
.bp				db "BP",0
.cx				db "CX",0
.di				db "DI",0
.dx				db "DX",0
.si				db "SI",0
.sp				db "SP",0
