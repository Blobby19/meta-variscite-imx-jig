#!/bin/bash

# WBD is set as true by JIG Excel script for VAR-SOM-MX7-5G
if [ "$WBD" = "true" ]; then
        FIRMWARE=/lib/firmware/bcm/bcm4339.hcd
else
        FIRMWARE=/lib/firmware/bcm/bcm43430a1.hcd
fi

# Configute BT reset GPIO
if [ ! -d /sys/class/gpio/gpio14 ]; then
	echo 14 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio14/direction
fi

RESULT=0
STATUS=FAIL
HCIDEV=

# Check that BT firmware can be loaded successfully 3 times in a row
for i in 1 2 3 4 5; do

	# Stop after 3 successes in a row
	if [ $RESULT -eq 3 ]; then
		STATUS=PASS
		break
	fi

	# Stop if at least one of first 3 attempts failed
	if [ $i -gt 3 -a $RESULT -eq 0 ]; then
		break;
	fi

	# Down BT device and unload BT firmware
	[ ! -z "$HCIDEV" ] && hciconfig $HCIDEV down
	killall -q brcm_patchram_plus

	# Reset BT device
	echo 0 > /sys/class/gpio/gpio14/value
	sleep 1
	echo 1 > /sys/class/gpio/gpio14/value
	sleep 1

	# Load BT firmware
	brcm_patchram_plus --patchram ${FIRMWARE} \
		--enable_hci --bd_addr 64:a3:cb:5b:69:f0 \
		--no2bytes --baudrate 3000000 \
		--tosleep 1000 /dev/ttymxc2 &

        sleep 10

	# Check that BT device exists
	HCIDEV=`hciconfig | grep UART | cut -d: -f1`
	[ -z "$HCIDEV" ] && continue

	# Start BT device and check that it's UP
	hciconfig $HCIDEV up
	hcitool dev
	RET=`hcitool dev | grep hci -c`
	echo $RET
	if [ $RET -eq 0 ]; then
		RESULT=0
	else
                RESULT=$(($RESULT+1))
	fi
done

# Down BT device and unload BT firmware
[ ! -z "$HCIDEV" ] && hciconfig $HCIDEV down
killall -q brcm_patchram_plus

echo $STATUS

