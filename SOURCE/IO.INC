;=======================================================================
;io.inc
;
;include file that includes macros, offsets, ports, segments, etc.
;io.asm cannot Work Without io.inc.
;=======================================================================
	
[bits 16]
	
struc file
	f_name:				resb 6
	f_extension:		resb 3
endstruc
	
struc disk
	d_sides				resw 1
	d_tracks			resw 1
	d_bps				resw 1
	d_sectors			resw 1
endstruc
	
%ifdef __sdef_program__
	%ifdef __sdef_kernel__
		%fatal Program+Kernel not allowed
	%elifdef __sdef_boot__
		%fatal Program+Boot not allowed
	%endif
%elifdef __sdef_kernel__
	%ifdef __sdef_program__
		%fatal Kernel+Program not allowed
	%elifdef __sdef_boot__
		%fatal Kernel+Boot not allowed
	%endif
%elifdef __sdef_boot__
	%ifdef __sdef_program__
		%fatal Boot+Program not allowed
	%elifdef __sdef_kernel__
		%fatal Boot+Kernel not allowed
	%endif
%endif

;offsets
__program__								equ 5000h ;Where programs are loaded
__buffer__								equ 2000h ;buffer for everything
	
;special characters
__newline__								equ 0dh

;disk stuff
__dos_sectors__							equ 18
__all_sectors__							equ 18

;port addresses
io_address_com1							equ 03f8h
io_address_com2							equ 02f8h
io_address_com3							equ 03e8h
io_address_com4							equ 02e8h
io_address_ps2_data_port				equ 0060h
io_address_ps2_status_register			equ	0064h
io_address_ps2_command_register			equ	0064h
io_color_default						equ 0007h
	
;segments
__kernel__								equ 0500h ;kernel load memory
	
;etc
__afpfs_default__						equ 9 ;size of filename
	
%ifdef __sdef_program__
	[org __program__-__afpfs_default__]
%elifdef __sdef_kernel__
	[org -__afpfs_default__]
%endif
	
%ifdef __sdef_program__ ;call vectors
		io_start												equ 0
		io_disk_logical_to_hts									equ 3
		io_disk_read_file										equ 6
		io_disk_reset											equ 9
		io_display_clear_text_screen							equ 12
		io_display_disable_text_mode_cursor						equ 15
		io_display_enable_text_mode_cursor						equ 18
		io_display_print_char									equ 21
		io_display_print_text									equ 24
		io_display_scroll_down									equ 27
		io_display_update_text_mode_cursor						equ 30
		io_keyboard_input										equ 33
		io_keyboard_keypress									equ 36
		io_memory_copy											equ 39
		io_memory_copy_byte										equ 42
		io_serial_enable										equ 45
		io_serial_get_byte										equ 48
		io_serial_ldstp_get_bytes								equ 51
		io_serial_ldstp_send_bytes								equ 54
		io_serial_ports_check									equ 57
		io_serial_send_byte										equ 60
		io_serial_send_bytes									equ 63
		io_string_check_character_in_location					equ 66
		io_string_compare										equ 69
		io_string_copy											equ 72
		io_string_has_character									equ 75
		io_string_is_empty										equ 78
		io_string_lenght										equ 81
		io_string_replace_character								equ 84
		io_string_reverse										equ 87
		io_string_to_afpfs_filename								equ 90
		io_string_tokenize										equ 93
		io_system_reboot										equ 96
		io_system_timer											equ 99
		
		io_disk_get_file_list									equ 102
		io_disk_read_sector										equ 105
		io_display_check_video_adapters							equ 108
		io_display_get_current_video_mode						equ 111
		io_display_get_pixel									equ 114
		io_display_print_pixel									equ 117
		io_display_set_video_mode								equ 120
		io_memory_check_low_memory								equ 123
		io_parallel_ports_check									equ 126
		
		io_disk_find_file										equ 129
%endif
