@echo off
path %path%;%CD%\BUILD_PROGRAMS
cd BIN_DUMP
del *.* /Q
cd..

nasm -O0 -f bin -o BIN_DUMP\BOOT.IRK SOURCE\BOOT.ASM
nasm -O0 -f bin -o BIN_DUMP\KERNEL.SYS SOURCE\KERNEL.ASM

cd SOURCE\PROGRAMS
for %%i in (*.ASM) do copy %%i ..\..\BIN_DUMP
for %%i in (*.INC) do copy %%i ..\..\BIN_DUMP
cd..
cd..

cd BIN_DUMP
for %%i in (*.ASM) do nasm -O0 -f bin %%i
for %%i in (*.BIN) do del %%i
for %%i in (*.) do ren %%i %%i.EXE
for %%i in (*.ASM) do del %%i
for %%i in (*.INC) do del %%i
cd..

cd DISK
del LEAFOS.*
cd..

partcopy "%CD%\BIN_DUMP\BOOT.IRK" "%CD%\DISK\LEAFOS.IMG" 0h 511d

cd BIN_DUMP
del BOOT.IRK
cd..

dosbox -c "mount c: C:\Users\Admin\Desktop\LeafOS" -c "c:" -c "cd DISK" -c "imgmount b LEAFOS.IMG -size 512,1,1,3" -c "cd.." -c "cd BIN_DUMP" -c "copy *.* b:\ " -c "exit"