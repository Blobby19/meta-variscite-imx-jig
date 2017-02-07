RESULT=0
for i in 1 2 3 5 6 
do
#Three times load firmware check. If pass then UART soldered well
	killall -q brcm_patchram_plus 
	echo 0 > /sys/class/gpio/gpio14/value
	sleep 1
	echo 1 > /sys/class/gpio/gpio14/value
        sleep 1

	brcm_patchram_plus --patchram /lib/firmware/bcm/bcm43430a1.hcd  --enable_hci --bd_addr 64:a3:cb:5b:69:f0 --no2bytes --tosleep 1000 /dev/ttymxc2 &

        sleep 5

	hciconfig hci0 up

	hcitool dev
	RET=`hcitool dev | grep hci -c`
	echo $RET
	if [ $RET = "0" ]; then
		RESULT=0
	else
                RESULT=$(($RESULT+1))
		if [ $RESULT = "3" ]; then
			echo PASS
			exit 0
		fi
	fi
done

echo FAIL

