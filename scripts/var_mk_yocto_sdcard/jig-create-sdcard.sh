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

umount /$1?
dd if=/dev/zero of=$1 bs=1024k count=20

sfdisk --force $1 < ../sources/meta-variscite-imx-jig/scripts/var_mk_yocto_sdcard/partition_tables/sd.partition
mkfs.vfat $1"1" -nJIG-UL-BOOT

echo "flashing yocto "
echo "==============="

mkdir -p ./var_tmp/JIG-UL-BOOT
sync
ls -l ./var_tmp/JIG-UL-BOOT

echo "flashing U-BOOT ..."    
sudo dd if=tmp/deploy/images/imx6ul-var-dart/u-boot.img of=$1 bs=1K seek=69; sync
sudo dd if=tmp/deploy/images/imx6ul-var-dart/SPL-sd of=$1 bs=1K seek=1; sync

echo "flashing Yocto BOOT partition ..."    
sync
mount $1"1"  ./var_tmp/JIG-UL-BOOT
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ul-var-dart.bin				./var_tmp/JIG-UL-BOOT/jig-zImage
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ul-var-dart-emmc_wifi.dtb		./var_tmp/JIG-UL-BOOT/jig-imx6ul-var-dart-emmc_wifi.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ul-var-dart-nand_wifi.dtb		./var_tmp/JIG-UL-BOOT/jig-imx6ul-var-dart-nand_wifi.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ul-var-dart-nand_wifi_corning.dtb	./var_tmp/JIG-UL-BOOT/jig-imx6ul-var-dart-nand_wifi_corning.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ul-var-dart-sd_emmc.dtb			./var_tmp/JIG-UL-BOOT/jig-imx6ul-var-dart-sd_emmc.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ul-var-dart-sd_nand.dtb			./var_tmp/JIG-UL-BOOT/jig-imx6ul-var-dart-sd_nand.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ull-var-dart-emmc_wifi.dtb		./var_tmp/JIG-UL-BOOT/jig-imx6ull-var-dart-emmc_wifi.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ull-var-dart-nand_wifi.dtb		./var_tmp/JIG-UL-BOOT/jig-imx6ull-var-dart-nand_wifi.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ull-var-dart-sd_emmc.dtb		./var_tmp/JIG-UL-BOOT/jig-imx6ull-var-dart-sd_emmc.dtb
cp tmp/deploy/images/imx6ul-var-dart/zImage-imx6ull-var-dart-sd_nand.dtb		./var_tmp/JIG-UL-BOOT/jig-imx6ull-var-dart-sd_nand.dtb

mkdir -p ./var_tmp/JIG-UL-BOOT/scripts/
cp -r ../sources/meta-variscite-imx-jig/scripts/jig_scripts/uboot_script_images/* 	./var_tmp/JIG-UL-BOOT/scripts/
echo "Scipts Commit ID is:" `git --git-dir ../sources/meta-variscite-imx-jig/.git/ rev-parse HEAD` > ./var_tmp/JIG-UL-BOOT/version.txt
sync
umount ./var_tmp/JIG-UL-BOOT
rm -rf ./var_tmp/
echo DONE!!!
