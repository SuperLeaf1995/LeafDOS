;=======================================================================
;
;kernel.asm
;
;do i need to explain what is this?
;
;is the kernel, it is part of io.asm (technicaly).
;
;the only function that the kernel does is providing a nice shell to
;execute programs.
;
;=======================================================================

bits 16
org 0

file_data:
		.filename					db 'KERNEL'	;file name, 6 characters
		.extension					db 'SYS'	;extension, 3 charatcers
		
%include "..\io.inc"
		
call_references:
		jmp io_start												;10
		jmp io_disk_logical_to_hts									;13
		jmp io_disk_read_file										;16
		jmp io_disk_reset											;19
		jmp io_display_clear_text_screen							;22
		jmp io_display_disable_text_mode_cursor						;25
		jmp io_display_enable_text_mode_cursor						;28
		jmp io_display_print_char									;31
		jmp io_display_print_text									;34
		jmp io_display_scroll_down									;37
		jmp io_display_update_text_mode_cursor						;40
		jmp io_keyboard_input										;43
		jmp io_keyboard_keypress									;46
		jmp io_memory_copy											;49
		jmp io_memory_copy_byte										;52
		jmp io_memory_destroy_table									;55
		jmp io_memory_manage										;58
		jmp io_serial_enable										;61
		jmp io_serial_get_byte										;64
		jmp io_serial_ldstp_get_bytes								;67
		jmp io_serial_ldstp_send_bytes								;70
		jmp io_serial_ports_check									;73
		jmp io_serial_send_byte										;76
		jmp io_serial_send_bytes									;79
		jmp io_string_check_character_in_location					;82
		jmp io_string_compare										;85
		jmp io_string_copy											;88
		jmp io_string_has_character									;91
		jmp io_string_is_empty										;94
		jmp io_string_lenght										;97
		jmp io_string_replace_character								;100
		jmp io_string_reverse										;103
		jmp io_string_to_afpfs_filename								;106
		jmp io_string_tokenize										;109
		jmp io_system_reboot										;112
		jmp io_system_timer											;115
		
%include "io.asm"

;display and video routines
global io_display_clear_text_screen
global io_display_enable_text_mode_cursor
global io_display_disable_text_mode_cursor
global io_display_print_char
global io_display_print_text
global io_display_scroll_down
global io_display_update_text_mode_cursor

;keyboard and input routines
global io_keyboard_input
global io_keyboard_keypress

;serial routines
global io_serial_enable
global io_serial_get_byte
global io_serial_ports_check
global io_serial_send_byte
global io_serial_send_bytes

;memory routines
global io_memory_copy
global io_memory_copy_byte
global io_memory_destroy_table
global io_memory_manage

;string routines
global io_string_check_character_in_location
global io_string_compare
global io_string_copy
global io_string_has_character
global io_string_is_empty
global io_string_lenght
global io_string_replace_character
global io_string_reverse
global io_string_tokenize
global io_string_to_afpfs_filename

;system routines
global io_system_reboot
global io_system_timer
		
io_start:
	cli ;flush interrupts
	xor ax, ax ;set stack
	mov ss, ax ;point at stack element 0
	mov sp, 0ffffh ;stack is placed at the end of our segment's address
	sti ;restore interrupts
	cld ;go up in the ram
	mov ax, __kernel__ ;after this we shouldnt
	mov ds, ax ;bother about segments anymore
	mov es, ax ;well, not yet
	mov fs, ax
	mov gs, ax
	
	push di
	push es
	
	test dl, dl ;is dl zero?
	jz short .old
	
	xor di, di
	mov es, di
	
	mov [disk_drive_number], dl ;save device number
	mov ah, 08h
	int 13h
	and cx, 3fh
	mov [disk_sectors_per_track], cx
	movzx dx, dh
	add dx, 1
	mov [disk_sides], dx
.old:
	xor eax, eax ;needed for older bioses
	
	pop es
	pop di
;kernel init
;this label indicates when the
;name and the version of leafdos are shown
io_kernel_post_start:
	;initialize data
	
	;bochs leaves stuff on screen
	;so we must clean it to make bochs
	;happy >:(
	mov ah, 01bh
	mov al, ' '
	call io_display_clear_text_screen
	
	mov si, text_dos_name ;print os name and version
	call io_display_print_text
	pusha
	mov al, ' ' ;space betwen version and name
	call io_display_print_char
	popa
	mov si, text_dos_version ;version
	call io_display_print_text
	
	push ax
	mov al, __newline__
	call io_display_print_char
	pop ax
		
	;display that io exists
	mov si, text_io_name
	call io_display_print_text
	mov al, ' '
	call io_display_print_char
	mov si, text_dos_version
	call io_display_print_text
	
	push ax
	mov al, __newline__
	call io_display_print_char
	pop ax
	
	mov dx, io_address_com1
	call io_serial_enable
	
	mov dx, io_address_com1
	mov si, text_kernel_filename
	mov cx, 9
	call io_serial_send_bytes
	
io_kernel_main:
	push ax
	mov al, __newline__
	call io_display_print_char
	pop ax
	
	push ax
	push si
	
	mov ah, 07h
	mov al, 'A' ;(a+dev_num) = a or b
	add al, byte [disk_drive_number]
	call io_display_print_char
	mov si, text_drive_letter
	call io_display_print_text
	
	pop si
	pop ax

	push bx
	mov bl, [data_text_x]
	mov bh, [data_text_y]
	call io_display_update_text_mode_cursor
	pop bx

	pusha
	mov ch, 10 ;limit is 9 characters + arguments for program
	mov di, data_keyboard_buffer ;keyboard buffer is keyboard buffer
	call io_keyboard_input ;get keyboard input
	mov si, data_keyboard_buffer ;blank lines are ignored
	lodsb
	cmp al, ' ' ;anything below space char is blank line
	jle short io_kernel_main
	popa
	
	push ax
	mov al, __newline__
	call io_display_print_char
	pop ax
		
	pusha
	mov si, data_keyboard_buffer ;convert keyboard buffer into
	mov di, data_program_to_load ;a useful filename
	call io_string_to_afpfs_filename
	popa
		
	;is it the kernel?
	push si
	push di ;kernel dosent exists.
	mov si, data_program_to_load ;just kidding
	mov di, text_kernel_filename ;it does
	call io_string_compare ;but the user is tricked
	jc short .not_found
	pop di
	pop si
	
	mov si, data_program_to_load ;prepare to find file...
	mov ax, __program__
	call io_disk_read_file
	jnc short .load_binary
	
	jmp short .not_found
	
.load_binary:
	mov ax, __program__     ;make segments point to the program
	mov es, ax              ;extended segment...
	mov ds, ax              ;data segment
	mov gs, ax              ;etc...
	mov fs, ax
		
	xor ax, ax      ; <- return value for programs
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor si, si
	xor di, di
		
	call __program__:__afpfs_default__
		
	mov ax, __kernel__      ;all leaf dos programs resets segments
	mov es, ax                      ;or modifies them in a way that the kernel
	mov ds, ax                      ;could crash, so we have to restore
	mov gs, ax                      ;segments for our kernel
	mov fs, ax
	jmp io_kernel_main
		
.not_found:
	mov al, '<'
	call io_display_print_char
	mov si, data_program_to_load
	call io_display_print_text
	mov al, '>'
	call io_display_print_char
	mov al, 20h
	call io_display_print_char
	mov si, text_error_unknown_command
	call io_display_print_text
	
	jmp io_kernel_main
	
	;kernel general messages
	text_kernel_filename								db 'kernelsys',0 ;prevent user from loading kernel
	text_dos_name										db 'Leaf DOS',0 ;dos name
	text_error_unknown_command							db 'is not a kernel command or a executable program.',0
	text_dos_version									db '0.1.7 beta',0 ;io and dos version
	text_io_name										db 'IO Library',0 ;io name
	text_drive_letter									db ':\rootdir\>',0
	
	;data
	data_sectors_per_track								dw 18
	data_sides											dw 2
	data_text_mode_wide									db 80
	data_text_mode_tall									db 25                   
	data_text_memory									dw 0b800h
	data_graphics_memory								dw 0a000h
	
	;disk data
	disk_drive_number									db 0
	disk_sectors_per_track								db 18
	disk_sides											db 2
	
	;miscellaneous data
	data_ticks_per_second								dw 0
	data_requested_timer								dw 0
	data_keyboard_buffer								times 11 db 0   ;keyboard buffer
	data_program_to_load								times 11 db 0   ;requested program transformed into
	data_text_y											db 0
	data_text_x											db 0
	
	afpfs_eof											dw 0ff8h
