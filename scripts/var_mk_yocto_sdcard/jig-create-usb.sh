#!/bin/bash
echo "Variscite Make i.MX6 Jig SDCARD utility version 01"
echo "==================================================="
#check if the disk size is bigger than 20GB. If yes it can be HDD so exit.
SIZE=`lsblk $1 -b -d -n | awk '{print $4}'`
if (( 20000000000 < $SIZE )); then
	echo The size of the disk is bigger than 20GB are remove this check from script if you want to use SD cards bigger than 20GB.
        echo this check protects you from erasing root hard drive
	exit
fi

# check the if root?
userid=`id -u`
if [ $userid -ne "0" ]; then
	echo "you're not root?"
	exit
fi

sudo umount $1?
dd if=/dev/zero of=$1 bs=1024k count=20

sfdisk --force $1 < ../sources/meta-variscite-imx-jig/scripts/var_mk_yocto_sdcard/partition_tables/usb.partition
mkfs.ext4 $1"1" -Lrootfs
mkfs.vfat $1"2" -nscripts

echo "flashing yocto "
echo "==============="

mkdir -p ./var_tmp/rootfs
mkdir -p ./var_tmp/scripts
sync

echo "flashing rootfs ..."    
mount $1"1"  ./var_tmp/rootfs
mount $1"2"  ./var_tmp/scripts

tar xf tmp/deploy/images/imx6ul-var-dart/core-image-minimal-imx6ul-var-dart.tar.bz2 -C ./var_tmp/rootfs/ 
cp -r ../sources/meta-variscite-imx-jig/scripts/jig_scripts/customers/ ./var_tmp/scripts/customers/
cp ../sources/meta-variscite-imx-jig/scripts/jig_scripts/* ./var_tmp/scripts/
#Create a directory for mount point of the USB second partition
mkdir -p ./var_tmp/rootfs/media/jig
echo "Scipts Commit ID is:" `git --git-dir ../sources/meta-variscite-imx-jig/.git/ rev-parse HEAD` > ./var_tmp/scripts/version.txt
sync

umount ./var_tmp/rootfs
umount ./var_tmp/scripts

rm -rf ./var_tmp/rootfs
rm -rf ./var_tmp/scripts
echo Done!!!


