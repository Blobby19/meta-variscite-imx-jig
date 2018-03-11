#!/bin/bash

#### Exports Variables ####
#### global variables ####
readonly ABSOLUTE_FILENAME=`readlink -e "$0"`
readonly ABSOLUTE_DIRECTORY=`dirname ${ABSOLUTE_FILENAME}`
readonly SCRIPT_POINT=${ABSOLUTE_DIRECTORY}

readonly YOCTO_ROOT="${SCRIPT_POINT}/../../../../"
readonly YOCTO_BUILD=${YOCTO_ROOT}/build_fb
readonly JIG_SCRIPTS_PATH=${SCRIPT_POINT}/${MACHINE}_jig_scripts
readonly YOCTO_IMGS_PATH=${YOCTO_BUILD}/tmp/deploy/images/${MACHINE}

YOCTO_RECOVERY_ROOTFS_PATH=${YOCTO_IMGS_PATH}
YOCTO_DEFAULT_IMAGE=core-image-base

echo "==============================================="
echo "= Variscite i.MX6 jig SD card creation script ="
echo "==============================================="

function help
{
	bn=`basename $0`
	echo " Usage: MACHINE=<var-som-mx6|imx6ul-var-dart|imx7-var-som> $bn <option> device_node"
	echo
	echo " options:"
	echo " -h		displays this Help message"
	echo
}

if [[ $EUID -ne 0 ]] ; then
	echo "This script must be run with super-user privileges"
	exit 1
fi

if [[ $MACHINE == var-som-mx6 ]] ; then
	P1_VOLNAME=BOOT-VARMX6
elif [[ $MACHINE == imx6ul-var-dart ]] ; then
	P1_VOLNAME=BOOT-VAR6UL
elif [[ $MACHINE == imx7-var-som ]] ; then
	P1_VOLNAME=BOOT-VARMX7
else
	help
	exit 1
fi

# parse command line
moreoptions=1
node="na"

while [ "$moreoptions" = 1 -a $# -gt 0 ]; do
	case $1 in
	    -h) help; exit ;;
	    *)  moreoptions=0; node=$1 ;;
	esac
	[ "$moreoptions" = 0 ] && [ $# -gt 1 ] && help && exit 1
	[ "$moreoptions" = 1 ] && shift
done

if [ ! -e ${node} ]; then
	echo "Error: Wrong path to the block device!"
	echo
	help
	exit 1
fi

part=""
if [[ $node == *mmcblk* ]] || [[ $node == *loop* ]] ; then
	part="p"
fi

echo "Device:  ${node}"
echo "==============================================="
read -p "Press Enter to continue"


P2_VOLNAME=rootfs
P3_VOLNAME=JIG_SCRIPTS

TEMP_DIR=./var_tmp
P1_MOUNT_DIR=${TEMP_DIR}/${P1_VOLNAME}
P2_MOUNT_DIR=${TEMP_DIR}/${P2_VOLNAME}
P3_MOUNT_DIR=${TEMP_DIR}/${P3_VOLNAME}


function delete_device
{
	echo
	echo "Deleting current partitions"
	for ((i=0; i<=10; i++))
	do
		if [[ -e ${node}${part}${i} ]] ; then
			dd if=/dev/zero of=${node}${part}${i} bs=512 count=1024 2> /dev/null || true
		fi
	done
	sync

	((echo d; echo 1; echo d; echo 2; echo d; echo 3; echo d; echo w) | fdisk $node &> /dev/null) || true
	sync

	dd if=/dev/zero of=$node bs=1M count=4
	sync; sleep 1
}

function create_parts
{
	echo
	echo "Creating new partitions"
	(echo n; echo p; echo 1; echo 15252; echo 61007; \
	 echo n; echo p; echo 2; echo 61008; echo 7229447; \
	 echo n; echo p; echo 3; echo 7229448; echo; \
	 echo t; echo 1; echo b; \
	 echo t; echo 2; echo 83; \
	 echo t; echo 3; echo c; \
	 echo w ) | fdisk $node > /dev/null

	sync; sleep 1
	fdisk -l $node
}

function format_parts
{
	echo
	echo "Formating partitions"
	mkfs.vfat ${node}${part}1 -n ${P1_VOLNAME}
	mkfs.ext4 ${node}${part}2 -L ${P2_VOLNAME}
	mkfs.vfat ${node}${part}3 -n ${P3_VOLNAME}
	sync; sleep 1
}

function install_bootloader
{
	echo
	echo "Installing U-Boot"
	dd if=${YOCTO_IMGS_PATH}/SPL-sd of=${node} bs=1K seek=1; sync
	dd if=${YOCTO_IMGS_PATH}/u-boot.img-sd of=${node} bs=1K seek=69; sync
}

function mount_parts
{
	mkdir -p ${P1_MOUNT_DIR}
	mkdir -p ${P2_MOUNT_DIR}
	mkdir -p ${P3_MOUNT_DIR}
	sync
	mount ${node}${part}1 ${P1_MOUNT_DIR}
	mount ${node}${part}2 ${P2_MOUNT_DIR}
	mount ${node}${part}3 ${P3_MOUNT_DIR}
}

function unmount_parts
{
	umount ${P1_MOUNT_DIR}
	umount ${P2_MOUNT_DIR}
	umount ${P3_MOUNT_DIR}
	rm -rf ${TEMP_DIR}
}

function install_yocto
{
	echo
	echo "Installing boot partition"
	cp ${YOCTO_IMGS_PATH}/?Image-imx*.dtb		${P1_MOUNT_DIR}/
	rename 's/.Image-//' ${P1_MOUNT_DIR}/?Image-*

	pv ${YOCTO_IMGS_PATH}/?Image >			${P1_MOUNT_DIR}/`cd ${YOCTO_IMGS_PATH}; ls ?Image`
	sync

	echo
	echo "Installing root file system"
	pv ${YOCTO_IMGS_PATH}/${YOCTO_DEFAULT_IMAGE}-${MACHINE}.tar.bz2 | tar -xj -C ${P2_MOUNT_DIR}/
}

function copy_jig_scripts
{
	echo
	echo "Installing jig scripts partition"
	cp -a --no-preserve=ownership ${JIG_SCRIPTS_PATH}/*	${P3_MOUNT_DIR}/
	echo "Scipts Commit ID is:" `git --git-dir ${SCRIPT_POINT}/../../.git/ rev-parse HEAD` > ${P3_MOUNT_DIR}/version.txt
}

umount ${node}${part}*  2> /dev/null || true

delete_device
create_parts
format_parts
install_bootloader
mount_parts
install_yocto
copy_jig_scripts

echo
echo "Syncing"
sync | pv -t

unmount_parts
sleep 1

echo "Done"

exit 0
