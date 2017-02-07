#!/bin/sh

# MAC address write script for iMX6

fail()
{
	echo -e "FAIL: $@"
	exit 1
}

MAC_=$1
MAC_="${MAC_^^}"

case $MAC_
in
[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F])
	#echo "Valid MAC"
	;;
[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F])
	#echo "Valid MAC"
	MAC_=$(echo $MAC_ | sed 's/\://g')
	;;
*)
	fail 'Invalid MAC address'
	;;
esac


if [[ (! -f /sys/fsl_otp/HW_OCOTP_MAC_ADDR0) || (! -f /sys/fsl_otp/HW_OCOTP_MAC_ADDR1) ]]
then
	fail 'No sysfs files'
fi


if [[ -f /sys/fsl_otp/HW_OCOTP_MAC_ADDR2 ]]
then
	#echo "We have a second MAC"
	if [[ ($((0x$MAC_ % 2)) -ne 0 ) ]]
	then
		fail 'MAC address is not even'
	else
		I=2
		MAC2_=$((0x$MAC_+1))
		MAC2_=$(printf '%012X' $MAC2_)

		MAC[2]=0x$(echo $MAC2_ | cut -c1-8)
		MAC[1]=0x$(echo $MAC2_ | cut -c9-12)$(echo $MAC_ | cut -c1-4)
	fi
else
	I=1
	MAC[1]=0x$(echo $MAC_ | cut -c1-4)
fi
MAC[0]=0x$(echo $MAC_ | cut -c5-12)


for ((i=$I; i>=0; i--))
do
	val=$(< /sys/fsl_otp/HW_OCOTP_MAC_ADDR$i)
	if [[ "$val" -eq 0x0 ]]
	then
		#echo "Read val is 0 - writing new value"
		echo ${MAC[$i]} > /sys/fsl_otp/HW_OCOTP_MAC_ADDR$i
		val=$(< /sys/fsl_otp/HW_OCOTP_MAC_ADDR$i)
		if [[ "$val" -ne "${MAC[$i]}" ]]
		then
			fail 'Error writing value'
		fi
	elif [[ "$val" -ne "${MAC[$i]}" ]]
	then
		fail 'Read value is wrong - aborting'
	fi
done

echo "PASS"
