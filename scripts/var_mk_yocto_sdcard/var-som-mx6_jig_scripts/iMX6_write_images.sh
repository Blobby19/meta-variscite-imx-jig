#!/bin/sh

function my_cmp
{
	if cmp $1 $2 || [[ `cmp $1 $2 2>&1 | grep -c EOF` == "1" ]]; then
		return 0
	fi
	return 1
}

function run_cmd
{
	echo "# $@"
	eval $@
	local status=$?
	if [ $status -ne 0 ]; then
		if [ "$1" = "kobs-ng" ] && [ $NAND_SIZE -eq 1024 ]; then
			echo "WARNING: $1 has FAILED"
		else
			echo "FAIL!"
			exit $status
		fi
	fi
}

cd /tmp

if [[ ! -z ${OS} ]]; then
	echo "Default images"

	NAND_LINUX_SPL="SPL-nand-2013.10"
	NAND_LINUX_UBOOT="u-boot-nand-2013.10.img"

	NAND_ANDROID_SPL="SPL-nand-2013.10"
	NAND_ANDROID_UBOOT="u-boot-android-nand-2009.08.img"

	EMMC_LINUX_SPL="SPL-sd-2015.04"
	EMMC_LINUX_UBOOT="u-boot-sd-2015.04.img"

	EMMC_ANDROID_SPL="SPL-sd-2015.04"
	EMMC_ANDROID_UBOOT="u-boot-android-sd-2015.04.img"

	DARTMX6_LINUX_SPL="SPL-sd-2013.10"
	DARTMX6_LINUX_UBOOT="u-boot-sd-2013.10.img"

	DARTMX6_ANDROID_SPL="SPL-sd-2013.10"
	DARTMX6_ANDROID_UBOOT="u-boot-android-sd-2014.04.img"

	if [[ $BOOT_DEV == "EMMC" ]]; then
		if [[ $OS == "LINUX" ]]; then
			if [[ $SOMTYPE == "DART-MX6" ]]; then
				SPL=${DARTMX6_LINUX_SPL}
				UBOOT=${DARTMX6_LINUX_UBOOT}
			else
				SPL=${EMMC_LINUX_SPL}
				UBOOT=${EMMC_LINUX_UBOOT}
			fi
		elif [[ $OS == "ANDROID" ]]; then
			if [[ $SOMTYPE == "DART-MX6" ]]; then
				SPL=${DARTMX6_ANDROID_SPL}
				UBOOT=${DARTMX6_ANDROID_UBOOT}
			else
				SPL=${EMMC_ANDROID_SPL}
				UBOOT=${EMMC_ANDROID_UBOOT}
			fi
		fi
		if [[ ! -z ${SPL} && ! -z ${UBOOT} && ! -z ${EMMCBLK} ]]; then
			echo
			echo "Writing ${SPL} and ${UBOOT} to /dev/mmcblk${EMMCBLK}"
			run_cmd dd if=${HOME}/images/default/${SPL} of=/dev/mmcblk${EMMCBLK} bs=1K seek=1
			sync
			run_cmd dd if=${HOME}/images/default/${UBOOT} of=/dev/mmcblk${EMMCBLK} bs=1K seek=69
			sync
			sync; sleep 1; echo 3 > /proc/sys/vm/drop_caches
			run_cmd dd if=/dev/mmcblk${EMMCBLK} of=/tmp/SPL.tmp bs=1K skip=1 count=$(expr `wc -c < ${HOME}/images/default/${SPL}` \/ 1024 + 1)
			run_cmd dd if=/dev/mmcblk${EMMCBLK} of=/tmp/u-boot.img.tmp bs=1K skip=69 count=$(expr `wc -c < ${HOME}/images/default/${UBOOT}` \/ 1024 + 1)
			run_cmd my_cmp /tmp/SPL.tmp ~/images/default/${SPL}
			run_cmd my_cmp /tmp/u-boot.img.tmp ~/images/default/${UBOOT}
			rm -f /tmp/SPL.tmp /tmp/u-boot.img.tmp
		else
			echo "FAIL! Variables are missing"
			exit 1
		fi

	else # BOOT_DEV == "NAND"
		if [[ $OS == "LINUX" ]]; then
			SPL=${NAND_LINUX_SPL}
			UBOOT=${NAND_LINUX_UBOOT}
		elif [[ $OS == "ANDROID" ]]; then
			SPL=${NAND_ANDROID_SPL}
			UBOOT=${NAND_ANDROID_UBOOT}
		fi

		if [[ ! -z ${SPL} && ! -z ${UBOOT} && ! -z ${SEARCH_EXP} ]]; then
			echo
			echo "Writing ${SPL} and ${UBOOT} to NAND flash (search_exponent=${SEARCH_EXP})"
			run_cmd flash_erase /dev/mtd0 0 0
			run_cmd kobs-ng init -x ~/images/default/${SPL} --search_exponent=${SEARCH_EXP} -v
			run_cmd flash_erase /dev/mtd1 0 0
			run_cmd nandwrite -p /dev/mtd1 ~/images/default/${UBOOT}
			sync; sleep 1; echo 3 > /proc/sys/vm/drop_caches
			run_cmd nanddump -f /tmp/u-boot.img.tmp -l `wc -c < ~/images/default/${UBOOT}` /dev/mtd1
			run_cmd my_cmp /tmp/u-boot.img.tmp ~/images/default/${UBOOT}
			rm -f /tmp/u-boot.img.tmp
		else
			echo "FAIL! Variables are missing"
			exit 1
		fi
	fi
else
	echo "Special burning"

	node=/dev/mmcblk${EMMCBLK}
	part=p
	mountdir_prefix=/run/media/mmcblk${EMMCBLK}${part}

	function delete_emmc_device
	{
		echo
		echo "Deleting current partitions"
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

	function create_emmc_parts
	{
		echo
		echo "Creating new partitions"
		if [[ $BOOT_DEV == "EMMC" ]]; then
			SECT_SIZE_BYTES=`cat /sys/block/mmcblk${EMMCBLK}/queue/hw_sector_size`
			PART1_FIRST_SECT=`expr 4 \* 1024 \* 1024 \/ $SECT_SIZE_BYTES`
			PART2_FIRST_SECT=`expr $((4 + 8)) \* 1024 \* 1024 \/ $SECT_SIZE_BYTES`
			PART1_LAST_SECT=`expr $PART2_FIRST_SECT - 1`

			(echo n; echo p; echo $bootpart; echo $PART1_FIRST_SECT; echo $PART1_LAST_SECT; echo t; echo c; \
				echo n; echo p; echo $rootfspart; echo $PART2_FIRST_SECT; echo; \
				echo p; echo w) | fdisk -u $node > /dev/null
		else
			(echo n; echo p; echo $rootfspart; echo; echo; echo p; echo w) | fdisk -u $node > /dev/null
		fi
		sync; sleep 1
		fdisk -u -l $node
	}

	function format_emmc_boot_part
	{
		echo
		echo "Formatting BOOT partition"
		run_cmd mkfs.vfat ${node}${part}${bootpart} -n BOOT-VARSOM
		sync; sleep 1
	}

	function format_emmc_rootfs_part
	{
		echo
		echo "Formatting rootfs partition"
		run_cmd mkfs.ext4 ${node}${part}${rootfspart} -L rootfs
		sync; sleep 1
	}

	function install_bootloader_emmc
	{
		echo
		echo "Installing booloader"
		run_cmd dd if=${HOME}/images/${FIRST_BOOTLOADER} of=${node} bs=1K seek=1
		sync
		sync; sleep 1; echo 3 > /proc/sys/vm/drop_caches
		run_cmd dd if=${node} of=/tmp/first_bootloader.tmp bs=1K skip=1 count=$(expr `wc -c < ${HOME}/images/${FIRST_BOOTLOADER}` \/ 1024 + 1)
		run_cmd my_cmp /tmp/first_bootloader.tmp ~/images/${FIRST_BOOTLOADER}
		rm -f /tmp/first_bootloader.tmp
		if [[ ! -z ${SECOND_BOOTLOADER} ]]; then
			run_cmd dd if=${HOME}/images/${SECOND_BOOTLOADER} of=${node} bs=1K seek=69
			sync
			sync; sleep 1; echo 3 > /proc/sys/vm/drop_caches
			run_cmd dd if=${node} of=/tmp/second_bootloader.tmp bs=1K skip=69 count=$(expr `wc -c < ${HOME}/images/${SECOND_BOOTLOADER}` \/ 1024 + 1)
			run_cmd my_cmp /tmp/second_bootloader.tmp ~/images/${SECOND_BOOTLOADER}
			rm -f /tmp/second_bootloader.tmp
		fi
	}

	function install_kernel_emmc
	{
		echo
		echo "Installing kernel to BOOT partition"
		mkdir -p ${mountdir_prefix}${bootpart}
		run_cmd mount -t vfat ${node}${part}${bootpart} ${mountdir_prefix}${bootpart}
		run_cmd tar xvpf ~/images/${EMMC_BOOT_PART_ARCHIVE} -C ${mountdir_prefix}${bootpart}
		sync
		run_cmd umount ${node}${part}${bootpart}
	}

	function install_rootfs_emmc
	{
		echo
		echo "Installing rootfs"
		mkdir -p ${mountdir_prefix}${rootfspart}
		run_cmd mount ${node}${part}${rootfspart} ${mountdir_prefix}${rootfspart}
		run_cmd "cat ~/images/${EMMC_ROOTFS_ARCHIVE}* | tar xzp -C ${mountdir_prefix}${rootfspart}"
		sync
		run_cmd umount ${node}${part}${rootfspart}
	}


	if [[ $BOOT_DEV == "EMMC" ]]; then
		bootpart=1
		rootfspart=2

		case $VSMTAG in
			VSM-DT6-302-STG)
				FIRST_BOOTLOADER="stages/VSM-DT6-302-STG/SPL.mmc"
				SECOND_BOOTLOADER="stages/VSM-DT6-302-STG/u-boot.img.mmc"
				EMMC_BOOT_PART_ARCHIVE="stages/VSM-DT6-302-STG/BOOT-VARSOM.tar.gz"
				EMMC_ROOTFS_ARCHIVE="stages/VSM-DT6-302-STG/rootfs.tar.gz"
				;;
			*)
				echo "FAIL! Invalid VSMTAG: $VSMTAG"
				exit 1
				;;
		esac

	else # BOOT_DEV == "NAND"
		bootpart=none
		rootfspart=1

		case $VSMTAG in
			VSM-MX6-B06-TG1)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="taoglas/VSM-MX6-B06-TG1/openwrt-imx6-zrm500-SPL"
				SECOND_BOOTLOADER="taoglas/VSM-MX6-B06-TG1/openwrt-imx6-zrm500-u-boot.img"
				;;
			VSM-MX6-G11-TG2)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="taoglas/VSM-MX6-G11-TG2/openwrt-imx6-zrm500-SPL"
				SECOND_BOOTLOADER="taoglas/VSM-MX6-G11-TG2/openwrt-imx6-zrm500-u-boot.img"
				;;
			VSM-MX6-C0D-TN1)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="Technolution/VSM-MX6-C0D-TN1/SPL"
				SECOND_BOOTLOADER="Technolution/VSM-MX6-C0D-TN1/u-boot.img"
				;;
			VSM-MX6-C0D-TN2 | VSM-MX6-C0H-TN2)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="Technolution/VSM-MX6-C0D-TN2/SPL"
				SECOND_BOOTLOADER="Technolution/VSM-MX6-C0D-TN2/u-boot.img"
				;;
			VSM-MX6-H23-KP1)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="keyprocessor/VSM-MX6-H23-KP1/SPL"
				SECOND_BOOTLOADER="keyprocessor/VSM-MX6-H23-KP1/u-boot-dtb.img"
				ENV_IMG="keyprocessor/VSM-MX6-H23-KP1/environment.bin"
				ENV_PART_NUM="0"
				ENV_ADDR="0x180000"
				;;
			VSM-MX6-H23-KP2)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="keyprocessor/VSM-MX6-H23-KP2/SPL"
				SECOND_BOOTLOADER="keyprocessor/VSM-MX6-H23-KP2/u-boot-dtb.img"
				ENV_IMG="keyprocessor/VSM-MX6-H23-KP2/environment.bin"
				ENV_PART_NUM="0"
				ENV_ADDR="0x180000"
				;;
			VSM-MX6-C84-TS)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="adelco/VSM-MX6-C84-TS/SPL"
				SECOND_BOOTLOADER="adelco/VSM-MX6-C84-TS/u-boot.img"
				;;
			VSM-MX6-B30-EK1)
				SEARCH_EXP=1
				FIRST_BOOTLOADER="elka/VSM-MX6-B30-EK1/u-boot_ELKA_TFTP_BOOT_2014_07_11.bin"
				;;
			VSM-DUAL-208-GB1 | VSM-DUAL-211-GB1)
				FIRST_BOOTLOADER="grossenbacher/VSM-DUAL-208-GB1/SPL"
				SECOND_BOOTLOADER="grossenbacher/VSM-DUAL-208-GB1/u-boot.img"
				;;
			*)
				echo "FAIL! Invalid VSMTAG: $VSMTAG"
				exit 1
				;;
		esac

		MAX_PART_NUM=0
		if [[ ! -z ${SECOND_BOOTLOADER} ]]; then
			MAX_PART_NUM=1
		fi
		if [[ ! -z ${ENV_PART_NUM} && ${ENV_PART_NUM} > ${MAX_PART_NUM} ]]; then
			MAX_PART_NUM=${ENV_PART_NUM}
		fi

		for i in `seq 0 ${MAX_PART_NUM}`; do
			echo
			echo "Erasing /dev/mtd${i}"
			run_cmd flash_erase /dev/mtd${i} 0 0
		done

		echo
		echo "Writing ${FIRST_BOOTLOADER} to NAND flash (search_exponent=${SEARCH_EXP})"
		run_cmd kobs-ng init -x ~/images/${FIRST_BOOTLOADER} --search_exponent=${SEARCH_EXP} -v

		if [[ ! -z ${SECOND_BOOTLOADER} ]]; then
			echo
			echo "Writing ${SECOND_BOOTLOADER} to /dev/mtd1"
			run_cmd nandwrite -p /dev/mtd1 ~/images/${SECOND_BOOTLOADER}
			sync; sleep 1; echo 3 > /proc/sys/vm/drop_caches
			run_cmd nanddump -f /tmp/u-boot.img.tmp -l `wc -c < ~/images/${SECOND_BOOTLOADER}` /dev/mtd1
			run_cmd my_cmp /tmp/u-boot.img.tmp ~/images/${SECOND_BOOTLOADER}
			rm -f /tmp/u-boot.img.tmp
		fi

		if [[ ! -z ${ENV_IMG} && ! -z ${ENV_PART_NUM} && ! -z ${ENV_ADDR} ]]; then
			echo
			echo "Writing ${ENV_IMG} to /dev/mtd${ENV_PART_NUM} at offset ${ENV_ADDR}"
			run_cmd nandwrite -p -s ${ENV_ADDR} /dev/mtd${ENV_PART_NUM} ~/images/${ENV_IMG}
			sync; sleep 1; echo 3 > /proc/sys/vm/drop_caches
			run_cmd nanddump -s ${ENV_ADDR} -f /tmp/env.bin.tmp -l `wc -c < ~/images/${ENV_IMG}` /dev/mtd${ENV_PART_NUM}
			run_cmd my_cmp /tmp/env.bin.tmp ~/images/${ENV_IMG}
			rm -f /tmp/env.bin.tmp
		fi
	fi

	if [[ ! -z ${EMMC_BOOT_PART_ARCHIVE} || ! -z ${EMMC_ROOTFS_ARCHIVE} ]]; then
		delete_emmc_device
		create_emmc_parts
		if [[ ! -z ${EMMC_ROOTFS_ARCHIVE} ]]; then
			format_emmc_rootfs_part
			install_rootfs_emmc
		fi

		if [[ $BOOT_DEV == "EMMC" ]]; then
			install_bootloader_emmc
			if [[ ! -z ${EMMC_BOOT_PART_ARCHIVE} ]]; then
				format_emmc_boot_part
				install_kernel_emmc
			fi
		fi
	fi
fi

sync; sleep 1

echo "PASS"
