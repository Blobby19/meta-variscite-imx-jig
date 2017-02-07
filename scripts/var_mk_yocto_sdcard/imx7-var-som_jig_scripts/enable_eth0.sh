rmmod fec
killall udhcpc
echo 119 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio119/direction
echo 1 > /sys/class/gpio/gpio119/value
insmod `find /lib/modules/ -name fec.ko`
echo 0 > /sys/class/gpio/gpio119/value
sleep 1 
rmmod fec
insmod `find /lib/modules/ -name fec.ko`
ifconfig eth0 down
echo 1 > /sys/class/gpio/gpio119/value
sleep 1
ifconfig eth0 hw ether 00`hexdump /dev/urandom -n5 -v -e '1/1 "%02X"'`
ifconfig eth0 up

while [ `ifconfig eth0 | grep -c RUNNING` -ne 0 ]
do
        usleep 1000
done

while [ `ifconfig eth0 | grep -c RUNNING` -ne 1 ]
do
	usleep 1000
done
sleep 3 
udhcpc -ieth0

