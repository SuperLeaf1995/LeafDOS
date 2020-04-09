#!/bin/sh

#clear past stuff
rm -f bin/*

if [ ! -e disk ]
then
	mkdir disk || exit
fi

if [ ! -e bin ]
then
	mkdir bin || exit
fi

#compile assembly

echo "ASSEMBLY :: Bootloader"
nasm -O0 -fbin -t -Wall src/boot/bootloader.asm -o bin/bootloader.boot

for i in src/programs/*.asm
do
	echo "ASSEMBLY :: $i"
	nasm -O0 -fbin -t -Wall $i -o bin/`basename $i .asm`.com || exit
done

for i in src/kernel/*.asm
do
	echo "ASSEMBLY :: $i"
	nasm -O0 -fbin -t -Wall $i -o bin/`basename $i .asm`.sys || exit
done

for i in src/common/*.asm
do
	echo "ASSEMBLY :: $i"
	nasm -O0 -fbin -t -Wall $i -o bin/`basename $i .asm`.lib || exit
done

for i in src/common/*.lss
do
	cp $i bin/`basename $i` || exit
done

if [ ! -e disk/ldos.flp ]
then
	mkdosfs -C disk/ldos.flp 1440 || exit
fi

#use dd to paste bootloader into disk
dd conv=notrunc if=bin/bootloader.boot of=disk/ldos.flp || exit

rm -rf tmp-loop
mkdir tmp-loop && mount -o loop -t vfat disk/ldos.flp tmp-loop

#do not put bootloader in floppy image (double boot??? what?)
rm -f bin/bootloader.boot
for i in bin/*
do
	echo "COPYING :: $i"
	cp $i tmp-loop || exit
done
sleep 0.2
umount tmp-loop || exit

rm -rf tmp-loop

echo ":: End"
