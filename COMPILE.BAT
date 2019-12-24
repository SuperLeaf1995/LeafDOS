@echo off
path %path%;%CD%\BUILD_PROGRAMS

echo =======================================================================
echo LeafDOS Rapid Assemble, Copy and Paste script
echo =======================================================================

echo Deleting old files
cd BIN_DUMP
del *.* /Q
cd..

echo =======================================================================
echo Compiling
echo =======================================================================

echo Compiling binaries
cd SOURCE\BOOT
echo Bootloaders:

echo 160K Floppy
nasm -t -Wall -O0 -f bin -o ..\..\BIN_DUMP\BOOT.FLOPPY.IRK BOOT.ASM

cd..
cd KERNEL
echo Kernel:
nasm -t -Wall -O0 -f bin -o ..\..\BIN_DUMP\KERNEL.FLOPPY.SYS KERNEL.ASM
cd..
cd PROGRAMS
echo Programs:
for %%i in (*.ASM) do nasm -t -Wall ^
-O0 -f bin -o ..\..\BIN_DUMP\%%i.EXE %%i
cd..
cd..

echo =======================================================================
echo Creating new disk image
echo =======================================================================

echo Deleting old floppy disk image
cd DISK
del LEAF_DOS*.*
cd..

for %%i in (BIN_DUMP\*.*) do adj512 %CD%\%%i

echo Creating 5.25 160k floppy
bin_app %CD%\BIN_DUMP\BOOT.FLOPPY.IRK %CD%\DISK\LEAF_DOS.FLOPPY --shut-up-mode

adj512 BIN_DUMP\KERNEL.SYS
bin_app BIN_DUMP\KERNEL.FLOPPY.SYS DISK\LEAF_DOS.FLOPPY --shut-up-mode

for %%i in (BIN_DUMP\*.EXE) do bin_app %CD%\%%i %CD%\DISK\LEAF_DOS.FLOPPY --shut-up-mode

echo =======================================================================
echo Creating varying floppy disks
echo =======================================================================

echo Padding disks...
fill %CD%\DISK\LEAF_DOS.FLOPPY 1474560

echo Converting to img...
for %%i in (DISK\*.FLOPPY) do copy %CD%\%%i %CD%\%%i.IMG
for %%i in (DISK\*.FLOPPY) do copy %CD%\%%i %CD%\%%i_DISK_2.IMG
for %%i in (DISK\*.FLOPPY) do del %CD%\%%i

echo =======================================================================
echo =======================================================================