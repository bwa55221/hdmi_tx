#!/bin/bash
mkimage -A arm -O linux -T script -C none -a 0 -e 0 -n "My script" -d bootscript.txt u-boot.scr