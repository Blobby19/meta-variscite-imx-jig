#! /bin/sh
echo 132 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio132/direction
for i in 1 2 3
do
#Three times load firmware check. If pass then UART soldered well
        killall -q brcm_patchram_plus
        echo 0 > /sys/class/gpio/gpio132/value
        sleep 1
        echo 1 > /sys/class/gpio/gpio132/value

        brcm_patchram_plus --patchram /lib/firmware/bcm/bcm43430a1.hcd  --enable_hci --bd_addr 64:a3:cb:5b:69:f0 --no2bytes --tosleep 1000 /dev/ttymxc1 &

        sleep 10

        hciconfig hci0 up

        hcitool dev
        RET=`hcitool dev | grep hci -c`
        echo $RET
        if [ $RET = "0" ]; then
                echo FAIL Device is not up
                exit
        fi
done
echo PASS
