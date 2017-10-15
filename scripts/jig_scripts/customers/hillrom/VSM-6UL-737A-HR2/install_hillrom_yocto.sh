#!/bin/sh
set -e

function run_cmd
{
	echo "# $@"
	eval $@
	local status=$?
	if [ $status -ne 0 ]; then
		echo "FAIL!"
		exit $status
	fi
}


delete_emmc()
{
	echo "Deleting current partitions..."
	for ((i=0; i<=10; i++))
	do
		if [[ -e ${node}${part}${i} ]] ; then
			dd if=/dev/zero of=${node}${part}${i} bs=1024 count=1024 2> /dev/null || true
		fi
	done
	sync

	((echo d; echo 1; echo d; echo 2; echo d; echo 3; echo d; echo w) | fdisk $node &> /dev/null) || true
	sync

	run_cmd dd if=/dev/zero of=$node bs=1M count=4
	sync; sleep 1
}

create_emmc_parts()
{
	echo "Creating new partitions..."
	SECT_SIZE_BYTES=`cat /sys/block/${block}/queue/hw_sector_size`

	RESERVED_SIZE_BYTES=$((20 * 1024 * 1024))
	ROOTFS_SIZE_BYTES=$((1024 * 1024 * 1024))
	SERVICE_SIZE_BYTES=$((1024 * 1024 * 1024))

	PART1_START=$((RESERVED_SIZE_BYTES / SECT_SIZE_BYTES))
	PART1_SIZE=$((ROOTFS_SIZE_BYTES / SECT_SIZE_BYTES))
	PART2_START=$((PART1_START + PART1_SIZE))
	PART2_SIZE=$((SERVICE_SIZE_BYTES / SECT_SIZE_BYTES))
	PART3_START=$((PART2_START + PART2_SIZE))

	sfdisk --force -uS ${node} << EOF
	${PART1_START},${PART1_SIZE},83
	${PART2_START},${PART2_SIZE},83
	${PART3_START},,83
EOF

	sync; sleep 1
	fdisk -u -l $node
}

format_emmc_parts()
{
	echo "Formatting partitions..."
	run_cmd mkfs.ext4 ${node}${part}1 -L rootfs
	run_cmd mkfs.ext4 ${node}${part}2 -L service
	run_cmd mkfs.ext4 ${node}${part}3 -L application
	sync; sleep 1
}

install_bootloader_to_emmc()
{
	echo "Installing booloader..."
	run_cmd dd if=${IMGS_PATH}/${SPL_IMAGE} of=${node} bs=1K seek=1; sync
	run_cmd dd if=${IMGS_PATH}/${UBOOT_IMAGE} of=${node} bs=1K seek=69; sync
}

install_recovery_to_emmc()
{
	echo "Installing recovery..."
	run_cmd dd if=${IMGS_PATH}/${KERNEL_DTB} of=${node} bs=1k seek=896; sync
	run_cmd dd if=${IMGS_PATH}/$KERNEL_IMAGE of=${node} bs=1M seek=1; sync
	run_cmd dd if=${IMGS_PATH}/hillrom-initramfs.img of=${node} bs=1M seek=9; sync
}

install_rootfs_to_emmc()
{
	echo "Installing rootfs..."
	mkdir -p ${mountdir_prefix}${rootfspart}
	run_cmd mount ${node}${part}${rootfspart} ${mountdir_prefix}${rootfspart}
	run_cmd "cat ${IMGS_PATH}/${ROOTFS_IMAGE}* | tar xzp -C ${mountdir_prefix}${rootfspart}"
	run_cmd cp ${IMGS_PATH}/fw_env.config_mx6ul_emmc ${mountdir_prefix}${rootfspart}/etc/fw_env.config
	echo "fdt_file=$KERNEL_DTB" > ${mountdir_prefix}${rootfspart}/boot/uEnv.txt
	echo
	sync
}

install_appfs_to_emmc()
{
	if [ "${APPFS_IMAGE}" != "" ]
	then
		echo "Installing appfs..."
		mkdir -p ${mountdir_prefix}${appfspart}
		run_cmd mount ${node}${part}${appfspart} ${mountdir_prefix}${appfspart}
		run_cmd tar xpf ${IMGS_PATH}/${APPFS_IMAGE} -C ${mountdir_prefix}${appfspart}
		sync
	fi
}

install_servicefs_to_emmc()
{
	if [ "${SERVICEFS_IMAGE}" != "" ]
	then
		echo "Installing servicefs..."
		mkdir -p ${mountdir_prefix}${servicefspart}
		run_cmd mount ${node}${part}${servicefspart} ${mountdir_prefix}${servicefspart}
		run_cmd tar xpf ${IMGS_PATH}/${SERVICEFS_IMAGE} -C ${mountdir_prefix}${servicefspart}
		sync
	fi
}


SCRIPT_DIR=`dirname $0`
SCRIPT_PATH=`cd -P -- "${SCRIPT_DIR}" && pwd -P`
IMGS_PATH=$SCRIPT_PATH
KERNEL_IMAGE=zImage
STORAGE_DEV=emmc
IS_SPL=true
block=mmcblk1
node=/dev/${block}
SPL_IMAGE=SPL-sd
UBOOT_IMAGE=u-boot.img-sd
part=p
mountdir_prefix=/run/media/${block}${part}
rootfspart=1
servicefspart=2
appfspart=3
APPFS_IMAGE=""
SERVICEFS_IMAGE=""

while getopts d:i:a:s: OPTION;
do
	case "${OPTION}" in
	d)
		KERNEL_DTB=$OPTARG
		;;
	i)
		ROOTFS_IMAGE=$OPTARG
		;;
	a)
		APPFS_IMAGE=$OPTARG
		;;
	s)
		SERVICEFS_IMAGE=$OPTARG
		;;
	*)
		echo "Invalid option."
		exit 1
		;;
	esac
done

if [ "${KERNEL_DTB}" == "" -o ! -e "${SCRIPT_PATH}/${KERNEL_DTB}" ]
then
	echo "Kernel dtb \"${KERNEL_DTB}\" is not valid."
	exit 1;
fi

if [ "${ROOTFS_IMAGE}" == "" -o  `ls -1 ${SCRIPT_PATH}/${ROOTFS_IMAGE}.* | wc -l` -eq 0 ]
then
	echo "Root file system image  \"${ROOTFS_IMAGE}\" is not valid."
	exit 1;
fi

if [ "${APPFS_IMAGE}" != "" -a ! -e "${SCRIPT_PATH}/${APPFS_IMAGE}" ]
then
	echo "Application file system image  \"${APPFS_IMAGE}\" is not valid."
	exit 1;
fi

if [ "${SERVICEFS_IMAGE}" != "" -a ! -e "${SCRIPT_PATH}/${SERVICEFS_IMAGE}" ]
then
	echo "Service file system image  \"${SERVICEFS_IMAGE}\" is not valid."
	exit 1;
fi

umount ${node}${part}* 2> /dev/null || true

delete_emmc
create_emmc_parts
format_emmc_parts
install_bootloader_to_emmc
install_recovery_to_emmc
install_rootfs_to_emmc
install_appfs_to_emmc
install_servicefs_to_emmc

umount ${node}${part}* 2> /dev/null || true

