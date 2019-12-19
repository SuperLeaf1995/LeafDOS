=======================================================================================
LEAFDOS 0.1 - 1.0 Log
=======================================================================================
Simple TODO for Version 1.0:
=======================================================================================
Glossary:
(+) To be done
(-) On work/almost completed
(*) Done but untested
(^) Buggy
(~) Finished
=======================================================================================
(+) Can load programs:
	(~) that dosent clears screen, and still display stuff
	(+) programs that use kernel drivers I/O
(+) Full AFPFS support:
	(~) read files
	(+) write files
	(+) do not place metadata in memory
(+) Full string library:
	(*) string tokenize
	(*) replace character from string
	(+) string to int
	(+) int to string
	(~) reverse string
	(+) mirror string
	(~) copy string
	(*) check if string null terminates on desired lenght
	(*) string lenght
(+) Kernel driver integration/de-integration:
	(+) being able to load kernel drivers
	(+) being able to also unload them
	(+) special format for kernel drivers
	(+) kernel is not stupid and actually can designate drivers for its main porpouse
(+) Memory library:
	(~) free memory
	(~) memory table
	(~) allocate memory
	(+) swap memory
=======================================================================================
Function uselfulnes
=======================================================================================
Glossary:
(+) - Tested, works
(^) - Tested, works and will be improved
(@) - Tested, but has minor bugs
(!) - Tested, has major errors
(?) - Untested (theory)
(-) - Removed/Deprecated
(R) - Requieres renaming

*V. Int. = Version Introduced/Added
*V. Dep. = Version Removed/Deprecated
*IO.DISK is for AFPFS and general disk routines, IO.FAT12 is for FAT12
*There may be errors on Version Introduced and Deprecated

Table: (0.1.0 to 0.1.4)
=======================================================================================
Symbol	|V. Int |V. Dep. |Group 	|Name of function
=======================================================================================
(+)	|0.1.0	|	 |IO.CONVERSION	|LOGICAL_TO_HTS
(+)	|0.1.2	|	 |IO.CONVERSION	|AFPFS_FILENAME
(-)	|0.1.0	|0.1.1	 |IO.CONVERSION	|FILENAME_TO_FAT12
---------------------------------------------------------------------------------------
(R)	|0.1.0	|	 |IO.DISK	|DISK_ERROR
(@) 	|0.1.4	|	 |IO.DISK	|LOAD_BINARY
(!) 	|0.1.2	|0.1.4	 |IO.DISK	|LOAD_FILE
(R)	|0.1.0	|	 |IO.DISK	|RESET_DISK
---------------------------------------------------------------------------------------
(-)	|0.1.0	|0.1.2	 |IO.DISPLAY	|CLEAR_SCREEN
(+) 	|0.1.0	|	 |IO.DISPLAY	|DISPLAY_PRINT_CHAR
(+) 	|0.1.0	|	 |IO.DISPLAY	|DISPLAY_PRINT_TEXT
(-)	|0.1.0	|0.1.2	 |IO.DISPLAY	|GOTOXY
---------------------------------------------------------------------------------------
(-)	|0.1.0	|0.1.1	 |IO.FAT12	|LOAD_PROGRAM
---------------------------------------------------------------------------------------
(-)	|0.1.0	|0.1.2	 |IO.KEYBOARD	|CHECK_KEYPRESS
(+) 	|0.1.0	|	 |IO.KEYBOARD	|KEYBOARD_INPUT
(?) 	|0.1.0	|	 |IO.KEYBOARD	|KEYBOARD_KEYPRESS
---------------------------------------------------------------------------------------
(+) 	|0.1.4	|	 |IO.MEMORY	|MEMORY_ALLOCATE
(?) 	|0.1.0	|	 |IO.MEMORY	|MEMORY_COPY
(?) 	|0.1.0	|	 |IO.MEMORY	|MEMORY_COPY_BYTE
(?) 	|0.1.4	|	 |IO.MEMORY	|MEMORY_DESTROY_TABLE
(-) 	|0.1.4	|	 |IO.MEMORY	|MEMORY_FREE
(-) 	|0.1.4	|	 |IO.MEMORY	|MEMORY_RESIZE
---------------------------------------------------------------------------------------
(-) 	|0.1.3	|0.1.4	 |IO.PCI	|PCI_CHECK_VENDOR
(-) 	|0.1.3	|0.1.4	 |IO.PCI	|PCI_CONFIGURATION_READ_WORD
(-) 	|0.1.2	|0.1.4	 |IO.PCI	|PCI_CONFIGURE_MECHANISM
---------------------------------------------------------------------------------------
(^) 	|0.1.3	|	 |IO.SERIAL	|SERIAL_ENABLE
(+) 	|0.1.3	|	 |IO.SERIAL	|SERIAL_SEND_BYTE
(@) 	|0.1.3	|	 |IO.SERIAL	|SERIAL_SEND_BYTES
(+) 	|0.1.4	|	 |IO.SERIAL	|SERIAL_PORTS_CHECK
---------------------------------------------------------------------------------------
(-)	|0.1.0	|0.1.1	 |IO.STRING	|DECIMAL_INTEGER_TO_STRING
(?) 	|0.1.3	|	 |IO.STRING	|STRING_CHECK_CHARACTER_IN_LOCATION
(?) 	|0.1.3	|	 |IO.STRING	|STRING_COPY
(?) 	|0.1.3	|	 |IO.STRING	|STRING_HAS_CHARACTER
(?) 	|0.1.3	|	 |IO.STRING	|STRING_IS_EMPTY
(?) 	|0.1.3	|	 |IO.STRING	|STRING_LENGHT
(?) 	|0.1.3	|	 |IO.STRING	|STRING_REPLACE_CHARACTER
(+) 	|0.1.4	|	 |IO.STRING	|STRING_REVERSE
(?)	|0.1.3	|	 |IO.STRING	|STRING_TOKENIZE
---------------------------------------------------------------------------------------
(+)	|0.1.0	|	 |IO.SYSTEM	|SYSTEM_REBOOT

I will start logging EACH function per release. So you will get a list of available
functions per release (0.1.4 and above)

*UF: User Friendly? (usable by programs?)

===================================0.1.4===============================================
UF?	|Notes		 |Group 	|Name of function
=======================================================================================
Yes	|		 |IO.CONVERSION	|LOGICAL_TO_HTS
Yes	|		 |IO.CONVERSION	|AFPFS_FILENAME
---------------------------------------------------------------------------------------
Yes	|		 |IO.DISK	|DISK_ERROR
No 	|		 |IO.DISK	|LOAD_BINARY
Yes	|		 |IO.DISK	|RESET_DISK
---------------------------------------------------------------------------------------
Yes 	|		 |IO.DISPLAY	|DISPLAY_PRINT_CHAR
Yes 	|		 |IO.DISPLAY	|DISPLAY_PRINT_TEXT
---------------------------------------------------------------------------------------
Yes 	|		 |IO.KEYBOARD	|KEYBOARD_INPUT
Yes 	|		 |IO.KEYBOARD	|KEYBOARD_KEYPRESS
---------------------------------------------------------------------------------------
Yes 	|		 |IO.MEMORY	|MEMORY_ALLOCATE
Yes 	|		 |IO.MEMORY	|MEMORY_COPY
Yes 	|		 |IO.MEMORY	|MEMORY_COPY_BYTE
Yes 	|		 |IO.MEMORY	|MEMORY_DESTROY_TABLE
Yes 	|		 |IO.MEMORY	|MEMORY_FREE
Yes 	|		 |IO.MEMORY	|MEMORY_RESIZE
---------------------------------------------------------------------------------------
Yes 	|		 |IO.SERIAL	|SERIAL_ENABLE
Yes 	|		 |IO.SERIAL	|SERIAL_SEND_BYTE
Yes 	|		 |IO.SERIAL	|SERIAL_SEND_BYTES
Yes 	|		 |IO.SERIAL	|SERIAL_PORTS_CHECK
---------------------------------------------------------------------------------------
Yes 	|		 |IO.STRING	|STRING_CHECK_CHARACTER_IN_LOCATION
Yes 	|		 |IO.STRING	|STRING_COPY
Yes 	|		 |IO.STRING	|STRING_HAS_CHARACTER
Yes 	|		 |IO.STRING	|STRING_IS_EMPTY
Yes 	|		 |IO.STRING	|STRING_LENGHT
Yes 	|		 |IO.STRING	|STRING_REPLACE_CHARACTER
Yes 	|		 |IO.STRING	|STRING_REVERSE
Yes	|		 |IO.STRING	|STRING_TOKENIZE
---------------------------------------------------------------------------------------
Yes	|		 |IO.SYSTEM	|SYSTEM_REBOOT

===================================0.1.5===============================================
UF?	|Notes		 |Group 	|Name of function
=======================================================================================
Yes	|		 |IO.CONVERSION	|LOGICAL_TO_HTS
Yes	|		 |IO.CONVERSION	|AFPFS_FILENAME
---------------------------------------------------------------------------------------
Yes	|		 |IO.DISK	|DISK_ERROR
No 	|		 |IO.DISK	|LOAD_BINARY
Yes	|		 |IO.DISK	|RESET_DISK
---------------------------------------------------------------------------------------
Yes 	|		 |IO.DISPLAY	|DISPLAY_PRINT_CHAR
Yes 	|		 |IO.DISPLAY	|DISPLAY_PRINT_TEXT
---------------------------------------------------------------------------------------
Yes 	|		 |IO.KEYBOARD	|KEYBOARD_INPUT
Yes 	|		 |IO.KEYBOARD	|KEYBOARD_KEYPRESS
---------------------------------------------------------------------------------------
Yes 	|		 |IO.MEMORY	|MEMORY_COPY
Yes 	|		 |IO.MEMORY	|MEMORY_COPY_BYTE
Yes 	|		 |IO.MEMORY	|MEMORY_MANAGE
---------------------------------------------------------------------------------------
Yes 	|		 |IO.SERIAL	|SERIAL_ENABLE
Yes 	|		 |IO.SERIAL	|SERIAL_SEND_BYTE
Yes 	|		 |IO.SERIAL	|SERIAL_SEND_BYTES
Yes 	|		 |IO.SERIAL	|SERIAL_PORTS_CHECK
---------------------------------------------------------------------------------------
Yes 	|		 |IO.STRING	|STRING_CHECK_CHARACTER_IN_LOCATION
Yes 	|		 |IO.STRING	|STRING_COPY
Yes 	|		 |IO.STRING	|STRING_HAS_CHARACTER
Yes 	|		 |IO.STRING	|STRING_IS_EMPTY
Yes 	|		 |IO.STRING	|STRING_LENGHT
Yes 	|		 |IO.STRING	|STRING_REPLACE_CHARACTER
Yes 	|		 |IO.STRING	|STRING_REVERSE
Yes	|		 |IO.STRING	|STRING_TOKENIZE
---------------------------------------------------------------------------------------
Yes	|		 |IO.SYSTEM	|SYSTEM_REBOOT

=======================================================================================
Current versions
=======================================================================================
Glossary:
(+) Addition
(-) Deletion
(*) Note
(^) Bug
Organization:
Version - Main feature (always an addition)
*These versions arent github versions, but rather snapshots of
versions wich are important engough to be catalogued as one,
while not being too important and stable to be pushed into github
*Github specific versions will be marked with a ($)
*Releases to be pushed to github will be marked with a (%)
=======================================================================================
0.1.0 - First kernel version
	(+) FAT12 support
	(+) Bootlloader and kernel
	(+) Sample programs
	(^) Could not load files ? (Was it 0.1.0 or 0.1.1?)
	(*) Spaghetti code
	(*) Programs are useless, so it was the OS itself
0.1.1 - Experimental AFPFS support
	(-) FAT12 support
	(-) Stripped out all programs and libraries but IO
	(^) Could not load kernel PROPERLY (readed metadata and it messed up)
0.1.2 - AFPFS Support included
	(+) Bootable AFPFS
	(+) 720k floppy data for bootloader
	(+) 1440k floppy data for bootloader
	(+) 2880k floppy data for bootloader
	(+) PUSH_SEGMENTS, POP_SEGMENTS added as macros
	(+) PUSH_INDEX and POP_INDEX added as macros
	(+) PUSH_REGISTERS and POP_REGISTERS added as macros
	(*) Kernel did nothing but a blinking cursor
	(^) Freezes at first input
0.1.3 - Full blown AFPFS read support
	(+) Serial debug (at COM1)
	(*) All libraries merged into a big, 16 kb IO library
	(+) Can load AFPFS programs properly
	(+) BIN_APP deployed along LeafOS, for writing AFPFS filesystems and such
	(+) Huge additions to the io.string library
	(+) Mass renaming of all functions to show what they really are for
	(+) LOAD_BINARY part of kernel's property, no programs shall use it even if they
	risk their own life, its ugly, designed for a simple kernel thing and its
	useless without kernel data, so dont use it.
0.1.3.1 - PCI support
	(+) Experimental PCI support using mechanism 1
0.1.4 - Memory allocation/deallocation
	(+) Memory table at 2AAA:[0000-FFFF]
	(+) Better file structure
	(+) First AFPFS program: SAMPLE.COM (SAMPLE.ASM)
	(-) PCI support
	(+) A ton of string functions
	(*) Conclusion: AFPFS program metadata can't be removed, it messes the kernel
0.1.5 - Merged memory allocation/deallocation into a single function
	(+) Each memory table entries is 1 byte long, wich allows for segments up to 64k
	(+) Memory entries uses flags
	(+) First sights of kernel modules
	(*) IO.ASM reached 1k lines!
	(+) Memory destruction routine?
	(+) Binary files are properly loaded from kernel
	(+) More serial/parallel ports
	(+) Better serial detection
	(+) Slighty better performance
	(+) Kernel is now loaded at 0x0500 (lower memory) rather than in 0x2000 (med.
	mem)
	(+) Kernel is usable engough to be a functional OS
	(+) New memory table structure (smaller, and capable of more segments)
	(+) PUSH_ALL and POP_ALL, an alternative to PUSHA and POPA
	(+) Bootloader made slighty better
=======================================================================================
Distribution
=======================================================================================
Glossary:
No glossary this time
=======================================================================================
Format		|Size		|Filesystem	|Version
---------------------------------------------------------------------------------------
720k Floppy	|720k		|AFPFS 1.1	|0.1.5
1440k Floppy	|1440k		|AFPFS 1.1	|0.1.5
2880k Floppy	|2880k		|AFPFS 1.1	|0.1.5
---------------------------------------------------------------------------------------
720k Floppy	|720k		|AFPFS 1.0	|0.1.4
1440k Floppy	|1440k		|AFPFS 1.0	|0.1.4
2880k Floppy	|2880k		|AFPFS 1.0	|0.1.4
---------------------------------------------------------------------------------------
720k Floppy	|720k		|AFPFS 1.0	|0.1.3.1
1440k Floppy	|1440k		|AFPFS 1.0	|0.1.3.1
2880k Floppy	|2880k		|AFPFS 1.0	|0.1.3.1
---------------------------------------------------------------------------------------
720k Floppy	|720k		|AFPFS 1.0	|0.1.3
1440k Floppy	|1440k		|AFPFS 1.0	|0.1.3
2880k Floppy	|2880k		|AFPFS 1.0	|0.1.3
---------------------------------------------------------------------------------------
720k Floppy	|720k		|AFPFS 1.0	|0.1.2
1440k Floppy	|1440k		|AFPFS 1.0	|0.1.2
2880k Floppy	|2880k		|AFPFS 1.0	|0.1.2
---------------------------------------------------------------------------------------
1440k Floppy	|1440k		|AFPFS 0.8	|0.1.1
---------------------------------------------------------------------------------------
1440k Floppy	|1440k		|FAT12		|0.1.0
=======================================================================================
LDOSI686
=======================================================================================
LDOSI686 is a custom protocol for interaction between multiple LeafDOS systems

It sends a flag byte before sending data:
0xFE - Handshake (establish connection)
That the other party should answer with:
0xFA - Ok byte
If there is no such answer, it bails out
But if it does, any party can send/receive data, to send data, the sender should check
for any incoming byte:
0xCF - Incoming data
=======================================================================================
AFPFS Specification
=======================================================================================
Now the implementation of a totally arbitrary-guided filesystem may sound a bit crazy,
and even a bit useless, but it totally saves the pain of reading a table, and you
just need to read the entire disk, sector by sector to find the filename AFTER the EOF.

The implementation states that all files must have a 6.3 filename, and binary/executables
should have a jump directive (3 bytes) + nop, before the filename.

At the final of the file there should be a EOF marker (0FF8h) like the one FAT uses.

Thats basicaly all.
=======================================================================================
Memory Management in LeafDOS (0.1.5 - Current version)
=======================================================================================
In LeafDOS, the memory is managed by full segments.

The table has no registry of entries, it just has the entries.

Here is a show of the new memory table:
=======================================================================================
Segment			|Flag
---------------------------------------------------------------------------------------
3000			|01
---------------------------------------------------------------------------------------
3001			|FF
---------------------------------------------------------------------------------------
3002			|AA
---------------------------------------------------------------------------------------
...			|...
Each entry is 1 byte in size, and dictates a flag:
AA - Segment is free
EE - Segment is not free
EF - Segment flagged as never free
FF - Segment used by various/a kernel module/modules
Etc (see IO.INC for more information)
=======================================================================================
Memory Management in LeafDOS (0.1.4)
=======================================================================================
In LeafDOS, the memory is managed by segments, not by addresses.

There is a table in LeafDOS, the first byte (in 2AAA) wich is [2AAA:0000], contains
the number of entries registered in the memory table.

Here is a show of the table:
=======================================================================================
Segment			|Start			|End
---------------------------------------------------------------------------------------
3000			|0000			|FFFF
---------------------------------------------------------------------------------------
3001			|0000			|FFFF
---------------------------------------------------------------------------------------
3002			|0000			|FFFF
---------------------------------------------------------------------------------------
...			|...			|...

And so on...

Each entry is 4 bytes in size.
=======================================================================================
Documentation, tools used and stuff
=======================================================================================
OSDEV - many documentation on stuff
Ralf Brown Interrupt List - having a wide range of interrupts, bugs, and stuff
NASM - assembling everything
Visual Studio 2005 - building the tools that helped me in doing the AFPFS thing
(like bin_app, short for bin append(ing))
