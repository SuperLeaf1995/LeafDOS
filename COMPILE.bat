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
nasm -t -D__FLOPPY_160__ ^
-O0 -f bin -o ..\..\BIN_DUMP\BOOT_160K.FLOPPY.IRK BOOT.ASM
echo 360K Floppy
nasm -t -D__FLOPPY_360__ ^
-O0 -f bin -o ..\..\BIN_DUMP\BOOT_360K.FLOPPY.IRK BOOT.ASM
echo 720K Floppy
nasm -t -D__FLOPPY_720__ ^
-O0 -f bin -o ..\..\BIN_DUMP\BOOT_720K.FLOPPY.IRK BOOT.ASM
echo 1440K Floppy
nasm -t -D__FLOPPY_1440__ ^
-O0 -f bin -o ..\..\BIN_DUMP\BOOT_1440K.FLOPPY.IRK BOOT.ASM
echo 2880K Floppy
nasm -t -D__FLOPPY_2880__ ^
-O0 -f bin -o ..\..\BIN_DUMP\BOOT_2880K.FLOPPY.IRK BOOT.ASM

cd..
cd KERNEL
echo Kernel:
nasm -t -D__FLOPPY_2880__ -Wall ^
-O0 -f bin -o ..\..\BIN_DUMP\KERNEL_2880.FLOPPY.SYS KERNEL.ASM
nasm -t -D__FLOPPY_1440__ -Wall ^
-O0 -f bin -o ..\..\BIN_DUMP\KERNEL_1440.FLOPPY.SYS KERNEL.ASM
nasm -t -D__FLOPPY_720__ -Wall ^
-O0 -f bin -o ..\..\BIN_DUMP\KERNEL_720.FLOPPY.SYS KERNEL.ASM
nasm -t -D__FLOPPY_360__ -Wall ^
-O0 -f bin -o ..\..\BIN_DUMP\KERNEL_360.FLOPPY.SYS KERNEL.ASM
nasm -t -D__FLOPPY_160__ -Wall ^
-O0 -f bin -o ..\..\BIN_DUMP\KERNEL_160.FLOPPY.SYS KERNEL.ASM
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

echo Creating 5.25 160k floppy
bin_app %CD%\BIN_DUMP\BOOT_160K.FLOPPY.IRK %CD%\DISK\LEAF_DOS_5.25_160K.FLOPPY --shut-up-mode
echo Creating 3.5 360k floppy
bin_app %CD%\BIN_DUMP\BOOT_360K.FLOPPY.IRK %CD%\DISK\LEAF_DOS_5.25_360K.FLOPPY --shut-up-mode
echo Creating 3.5 720k floppy
bin_app %CD%\BIN_DUMP\BOOT_720K.FLOPPY.IRK %CD%\DISK\LEAF_DOS_3.5_720K.FLOPPY --shut-up-mode
echo Creating 3.5 1440k floppy
bin_app %CD%\BIN_DUMP\BOOT_1440K.FLOPPY.IRK %CD%\DISK\LEAF_DOS_3.5_1440K.FLOPPY --shut-up-mode
echo Creating 3.5 2880k floppy
bin_app %CD%\BIN_DUMP\BOOT_2880K.FLOPPY.IRK %CD%\DISK\LEAF_DOS_3.5_2880K.FLOPPY --shut-up-mode

adj512 BIN_DUMP\KERNEL.SYS
bin_app BIN_DUMP\KERNEL_160.FLOPPY.SYS DISK\LEAF_DOS_5.25_160K.FLOPPY --shut-up-mode
bin_app BIN_DUMP\KERNEL_360.FLOPPY.SYS DISK\LEAF_DOS_5.25_360K.FLOPPY --shut-up-mode
bin_app BIN_DUMP\KERNEL_720.FLOPPY.SYS DISK\LEAF_DOS_3.5_720K.FLOPPY --shut-up-mode
bin_app BIN_DUMP\KERNEL_1440.FLOPPY.SYS DISK\LEAF_DOS_3.5_1440K.FLOPPY --shut-up-mode
bin_app BIN_DUMP\KERNEL_2880.FLOPPY.SYS DISK\LEAF_DOS_3.5_2880K.FLOPPY --shut-up-mode

for %%i in (BIN_DUMP\*.EXE) do adj512 %CD%\%%i
for %%i in (BIN_DUMP\*.EXE) do echo %%i Was adjusted to 512 boundary
for %%i in (BIN_DUMP\*.EXE) do bin_app %CD%\%%i %CD%\DISK\LEAF_DOS_5.25_160K.FLOPPY --shut-up-mode

echo =======================================================================
echo Creating varying floppy disks
echo =======================================================================

echo Padding disks...
fill %CD%\DISK\LEAF_DOS_5.25_160K.FLOPPY 163840
fill %CD%\DISK\LEAF_DOS_5.25_360K.FLOPPY 368640
fill %CD%\DISK\LEAF_DOS_3.5_720K.FLOPPY 737280
fill %CD%\DISK\LEAF_DOS_3.5_1440K.FLOPPY 1474560
fill %CD%\DISK\LEAF_DOS_3.5_2880K.FLOPPY 2949120

echo Converting to img...
for %%i in (DISK\*.FLOPPY) do copy %CD%\%%i %CD%\%%i.IMG
for %%i in (DISK\*.FLOPPY) do del %CD%\%%i

echo =======================================================================
echo =======================================================================