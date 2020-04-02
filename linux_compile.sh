#!/bin/sh

#clear past stuff
rm -f bin/*

#compile assembly
cd src
cd boot
echo ":: Assembling Bootloader"
nasm -O0 -fbin -Wall bootloader.asm -o ../../bin/bootloader.boot
cd ..
cd kernel
echo ":: Assembling Kernel"
nasm -O0 -fbin -Wall kernel.asm -o ../../bin/kernel.sys
cd ..
cd ..

for i in src/programs/*.asm
do
	echo ":: Assembling $i"
	nasm -O0 -fbin -Wall $i -o bin/`basename $i .asm`.prg || exit
done

if [ ! -e disk/ldos.flp ]
then
	mkdosfs -C disk/ldos.flp 1440 || exit
fi

#use dd to paste bootloader into disk
dd conv=notrunc if=bin/bootloader.boot of=disk/ldos.flp || exit

rm -rf tmp-loop
mkdir tmp-loop && mount -o loop -t vfat disk/ldos.flp tmp-loop

rm -f bin/bootloader.boot
for i in bin/*
do
	echo ":: Copying $i"
	cp $i tmp-loop || exit
done
sleep 0.2
umount tmp-loop || exit

rm -rf tmp-loop

echo ":: End"
