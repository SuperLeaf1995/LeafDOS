@echo off
cd EMULATOR
bochs-win64 -q -f bochsrc.bxrc -noconsole
cd ..