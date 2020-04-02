# LeafDOS
LeafDOS is a monotasking, real-mode 16-bit operating system.

## Compilation
Run ``mkdir disk && mkdir bin`` to create needed directories.
Then run ``sudo bash compile_linux.sh`` to assemble everything with NASM

## Running
``qemu-system-i386 -soundhw pcspk -fda disk/ldos.flp -m 1``
