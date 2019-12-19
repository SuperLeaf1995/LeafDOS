@echo off
path %path%;%CD%\BUILD_PROGRAMS
cd BIN_DUMP
del *.* /Q
cd..

echo Compiling binaries
cd SOURCE\BOOT
nasm -O0 -f bin -o ..\..\BIN_DUMP\BOOT.IRK BOOT.ASM
cd..
cd KERNEL
nasm -O0 -f bin -o ..\..\BIN_DUMP\KERNEL.SYS KERNEL.ASM
cd..
cd PROGRAMS
for %%i in (*.ASM) do nasm -O0 -f bin -o ..\..\BIN_DUMP\%%i.EXE %%i
cd..
cd..

echo Deleting old floppy disk image
cd DISK
del LEAFOS.*
cd..

echo Copying bootsector to the first 512 bytes of the floppy disk image
partcopy "%CD%\BIN_DUMP\BOOT.IRK" "%CD%\DISK\LEAFOS.IMG" 0h 511d

echo Using bin_app to append kernel to floppy image
bin_app BIN_DUMP\KERNEL.SYS DISK\LEAFOS.IMG --shut-up-mode

for %%i in (BIN_DUMP\*.EXE) do bin_app %CD%\%%i %CD%\DISK\LEAFOS.IMG --shut-up-mode