;=======================================================================
;kernel.asm
;
;do i need to explain what is this?
;is the kernel, it is part of io.asm (technicaly).
;the only function that the kernel does is providing a nice shell to
;execute programs.
;=======================================================================
%define __sdef_kernel__
%include "..\io.inc"
	
[segment .text]
	
istruc file
	at	f_name,			db 'KERNEL'
	at	f_extension,	db 'SYS'
iend
	
call_references:
		;~~ IO 0.1.8 ~~
		jmp io_start
		jmp io_disk_logical_to_hts
		jmp io_disk_read_file
		jmp io_disk_reset
		jmp io_display_clear_text_screen
		jmp io_display_disable_text_mode_cursor
		jmp io_display_enable_text_mode_cursor
		jmp io_display_print_char
		jmp io_display_print_text
		jmp io_display_scroll_down
		jmp io_display_update_text_mode_cursor
		jmp io_keyboard_input
		jmp io_keyboard_keypress
		jmp io_memory_copy
		jmp io_memory_copy_byte
		jmp io_serial_enable
		jmp io_serial_get_byte
		jmp io_serial_ldstp_get_bytes
		jmp io_serial_ldstp_send_bytes
		jmp io_serial_ports_check
		jmp io_serial_send_byte
		jmp io_serial_send_bytes
		jmp io_string_check_character_in_location
		jmp io_string_compare
		jmp io_string_copy
		jmp io_string_has_character
		jmp io_string_is_empty
		jmp io_string_lenght
		jmp io_string_replace_character
		jmp io_string_reverse
		jmp io_string_to_afpfs_filename
		jmp io_string_tokenize
		jmp io_system_reboot
		jmp io_system_timer
		
		;~~ IO 0.1.9 ~~
		jmp io_disk_get_file_list
		jmp io_disk_read_sector
		jmp io_display_check_video_adapters
		jmp io_display_get_current_video_mode
		jmp io_display_get_pixel
		jmp io_display_print_pixel
		jmp io_display_set_video_mode
		jmp io_memory_check_low_memory
		jmp io_parallel_ports_check
		
%include "io.asm"
	
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
	
	test dl, dl ;is dl zero?
	jz short .old
	
	mov [disk_drive_number], dl ;save device number
	mov ah, 08h
	int 13h
	and cx, 3fh
	mov [disk_sectors_per_track], cx
	movzx dx, dh
	add dx, 1
	mov [disk_sides], dx
.old:
	xor ax, ax ;needed for older bioses
;kernel init
;this label indicates when the
;name and the version of leafdos are shown
io_kernel_post_start:
	;initialize data
	
	;determine address of text video mode
	;is it colour?
	call io_display_get_current_video_mode
	cmp al, 0ffh
	jne .no_monitor_change
	
	;we have a colour monitor!
	push ax
	
	mov ax, 0b800h
	mov word [data_text_memory], ax ;point at colour text memory
	
	pop ax
.no_monitor_change:
	
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
	mov ch, 11 ;limit is 9 characters + arguments for program
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
	mov bx, __program__
	call io_disk_read_file
	jnc short .load_binary
	
	jmp short .not_found
	
.load_binary:
	xor ax, ax		; <- return value for programs
	xor bx, bx
	xor cx, cx
	xor dx, dx
	
	xor si, si
	xor di, di
		
	call near __program__	;call the program, now
							;the program controls everything
	
	jmp io_kernel_main
		
.not_found:
	mov al, '<'
	call near io_display_print_char
	mov si, data_program_to_load
	call near io_display_print_text
	mov al, '>'
	call near io_display_print_char
	mov al, 20h
	call near io_display_print_char
	mov si, text_error_unknown_command
	call near io_display_print_text
	
	jmp io_kernel_main
	
[segment .data]
	;data
	data_sectors_per_track								dw 18
	data_sides											dw 2
	
	;text and display values
	data_text_mode_wide									db 80 ;may change during video modes switching
	data_text_mode_tall									db 25                   
	data_text_memory									dw 0b000h
	
	;vga/cga/tandy/hercules friendly stuff
	data_graphics_mode_wide								dw 320 ;changes acording to actual mode
	data_graphics_mode_tall								dw 200
	data_graphics_memory								dw 0a000h
	
	;disk data
	disk_drive_number									db 0
	disk_sectors_per_track								db 18
	disk_sides											db 2
	
[segment .bss]
	data_ticks_per_second								resw 1
	data_requested_timer								resw 1
	
	data_text_y											resb 1
	data_text_x											resb 1
	
	data_keyboard_buffer								resb 32		;keyboard buffer
	data_program_to_load								resb 32		;requested program transformed into
	
[segment .rodata]
	;kernel general messages
	text_kernel_filename								db 'KERNELSYS',0 ;prevent user from loading kernel
	text_dos_name										db 'Leaf DOS',0 ;dos name
	text_error_unknown_command							db 'not found',0
	text_dos_version									db '0.1.9 (Beta Release)',0 ;io and dos version
	text_io_name										db 'IO Library',0 ;io name
	text_drive_letter									db ':\>',0
	
	;eof
	eof													dw 0ff8h
