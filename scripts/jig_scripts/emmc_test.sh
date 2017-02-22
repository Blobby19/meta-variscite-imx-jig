#!/bin/sh

MIN=$(($1*1000000))
MAX=$(($2*1000000))

fdisk -l /dev/mmcblk1 | grep Disk.*MB

if [ `fdisk -l /dev/mmcblk1 | grep Disk.*MB | cut -d' ' -f5` -lt $MIN ]; then
echo FAIL
exit
fi

if [ `fdisk -l /dev/mmcblk1 | grep Disk.*MB | cut -d' ' -f5` -gt $MAX ]; then
echo FAIL
exit
fi

echo PASS

