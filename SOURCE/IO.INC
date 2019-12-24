;=======================================================================
;
;io.inc
;
;include file that includes macros, offsets, ports, segments, etc.
;io.asm cannot Work Without io.inc.
;
;=======================================================================

;segments
__program__								equ 4000h ;Where programs are loaded
__kernel__								equ 2000h ;kernel load memorY
__memory_table__						equ 0600h ;table that manages all allocations and free's
__buffer__								equ 6000h ;buffer for everything

;offsets
__afpfs_default__						equ 0009h ;default location for offsets in afpfs

;special characters
__newline__								equ 0dh

;other
__dos_sectors__							equ 18

;serial ports
io_address_com1							equ 03f8h
io_address_com2							equ 02f8h
io_address_com3							equ 03e8h
io_address_com4							equ 02e8h

io_address_ps2_data_port				equ 0060h
io_address_ps2_status_register			equ	0064h
io_address_ps2_command_register			equ	0064h

io_color_default						equ 007h

;memorY_allocation flags
memory_flag_segment_free				equ 0aah
memory_flag_segment_not_free			equ 0eeh
memory_flag_segment_neVer_free			equ 0efh
memory_flag_segment_kernel_module		equ 0ffh
