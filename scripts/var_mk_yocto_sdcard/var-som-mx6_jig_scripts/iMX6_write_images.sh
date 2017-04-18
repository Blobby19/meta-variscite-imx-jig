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
	$@
	local status=$?
	if [ $status -ne 0 ]; then
		if [ $1 = "kobs-ng" ] && [ $NAND_SIZE -eq 1024 ]; then
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
			run_cmd nanddump -f /tmp/u-boot.img.tmp /dev/mtd1
			run_cmd my_cmp /tmp/u-boot.img.tmp ~/images/default/${UBOOT}
			rm -f /tmp/u-boot.img.tmp
		else
			echo "FAIL! Variables are missing"
			exit 1
		fi
	fi
else
	echo "Special burning"

	# BOOT_DEV == "NAND"

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
		run_cmd nanddump -f /tmp/u-boot.img.tmp /dev/mtd1
		run_cmd my_cmp /tmp/u-boot.img.tmp ~/images/${SECOND_BOOTLOADER}
		rm -f /tmp/u-boot.img.tmp
	fi

	if [[ ! -z ${ENV_IMG} && ! -z ${ENV_PART_NUM} && ! -z ${ENV_ADDR} ]]; then
		echo
		echo "Writing ${ENV_IMG} to /dev/mtd${ENV_PART_NUM} at offset ${ENV_ADDR}"
		run_cmd nandwrite -p -s ${ENV_ADDR} /dev/mtd${ENV_PART_NUM} ~/images/${ENV_IMG}
		run_cmd nanddump -s ${ENV_ADDR} -f /tmp/env.bin.tmp /dev/mtd${ENV_PART_NUM}
		run_cmd my_cmp /tmp/env.bin.tmp ~/images/${ENV_IMG}
		rm -f /tmp/env.bin.tmp
	fi
fi

sync; sleep 1

echo "PASS"
