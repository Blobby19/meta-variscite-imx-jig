START=`cat /proc/interrupts  | grep ads | cut -d' ' -f12`
if [[ "$START" == "" ]]; then
	START=`cat /proc/interrupts  | grep ads | cut -d' ' -f11`
	if [[ "$START" == "" ]]; then
        	START=`cat /proc/interrupts  | grep ads | cut -d' ' -f10`
	fi
fi

if [ ! -d "/sys/class/gpio/gpio33" ]; then
	echo 33 > /sys/class/gpio/export
fi

echo out > /sys/class/gpio/gpio33/direction
usleep 50000
echo 1 > /sys/class/gpio/gpio33/value
usleep 50000
echo 0 > /sys/class/gpio/gpio33/value
usleep 50000
echo 1 > /sys/class/gpio/gpio33/value
usleep 50000
echo 0 > /sys/class/gpio/gpio33/value
usleep 50000
echo 1 > /sys/class/gpio/gpio33/value
usleep 50000
echo 0 > /sys/class/gpio/gpio33/value
usleep 50000
echo 1 > /sys/class/gpio/gpio33/value
usleep 50000
echo 0 > /sys/class/gpio/gpio33/value
usleep 50000
echo 1 > /sys/class/gpio/gpio33/value
usleep 50000
echo 0 > /sys/class/gpio/gpio33/value
usleep 50000
END=`cat /proc/interrupts  | grep ads | cut -d' ' -f12`
if [[ "$END" == "" ]]; then
        END=`cat /proc/interrupts  | grep ads | cut -d' ' -f11`
	if [[ "$END" == "" ]]; then
        	END=`cat /proc/interrupts  | grep ads | cut -d' ' -f10`
	fi
fi

RESULT=$(($END-$START))

if [ $RESULT -ne 10 ]; then
	echo FAIL
else
	echo PASS
fi
