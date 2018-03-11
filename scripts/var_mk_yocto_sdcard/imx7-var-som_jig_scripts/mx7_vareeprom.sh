#!/bin/sh

# params:
# 1: i2c bus
# 2: chip addr
# 3: data addr
# 4: value
write_i2c_byte()
{
	i2cset -r -y $1 $2 $3 $4 > /dev/null
	VAL=`i2cget -y $1 $2 $3`
	if [ "$VAL" != "$4" ]; then
		echo "FAIL! EEPROM VERIFY ADDRESS $3 SHOULD BE $4. READ $VAL."
		exit 1
	fi
}


# This func doesn't write a trailing
# zero at the end of the string
#
# params:
# 1: i2c bus
# 2: chip addr
# 3: data addr
# 4: value
write_i2c_string()
{
	DATA_ADDR=$3
	A=`echo $4 | awk NF=NF FS=`
	for i in $A
	do
		B=`printf '0x%x' "'$i"`
		write_i2c_byte $1 $2 $DATA_ADDR $B
		let DATA_ADDR="$DATA_ADDR + 1"
	done
}

# Zero the relevant erea in the EEPROM
for i in `seq 2 29`
do
	write_i2c_byte 0 0x50 $i 0x00
done

PART_NUM=${1#VSM-MX7-} # Remove the VSM-MX7- prefix
ADDR=2
LEN=8
# Use the first $LEN characters
PART_NUM=${PART_NUM::$LEN}
write_i2c_string 0 0x50 $ADDR $PART_NUM


ASSEMBLY=${2#AS} # Remove the AS prefix
let ADDR="10"
LEN=11
# Use the first $LEN characters
ASSEMBLY=${ASSEMBLY::$LEN}
write_i2c_string 0 0x50 $ADDR $ASSEMBLY


DATE=$3
let ADDR="21"
LEN=9
#Remove spaces
DATE=`echo $DATE | tr -d '[:space:]'`
# Use the first $LEN characters
DATE=${DATE::$LEN}
write_i2c_string 0 0x50 $ADDR $DATE

echo "PASS"
