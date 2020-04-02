# LeafDOS
LeafDOS is a monotasking, real-mode 16-bit operating system.

## Compilation
Run ``mkdir disk && mkdir bin`` to create needed directories.
Then run ``sudo bash compile_linux.sh`` to assemble everything with NASM

## Running
``qemu-system-i386 -soundhw pcspk -fda disk/ldos.flp -m 1``

## Goal list
* Being compatible with MS-DOS EXE, COM and MZ programs
* Being POSIX compliant
* Being compatible with various opensource hobby OSes
* Not exceding 1 MB of RAM usage
* Having a native assembler in LeafDOS
* Multitasking
* Tri-support for FAT12, FAT16 and AFPFS
