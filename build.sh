#!/bin/sh
xa -M -o elkwss.bin main.asm
dd if=/dev/zero ibs=1 count=16384 > os_basic.ic2
cat elkwss.bin >> os_basic.ic2
mv os_basic.ic2 /Applications/mame0248-x86/roms/electron/os_basic.ic2