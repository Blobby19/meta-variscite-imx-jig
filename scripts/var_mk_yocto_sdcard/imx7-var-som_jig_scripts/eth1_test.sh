rmmod fec
echo 119 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio119/direction
echo 1 > /sys/class/gpio/gpio119/value
modprobe fec
ifconfig eth1 down
echo 0 > /sys/class/gpio/gpio119/value
sleep 1
ifconfig eth1 hw ether 00`hexdump /dev/urandom -n5 -v -e '1/1 "%02X"'`
ifconfig eth1 up

while [ `ifconfig eth1 | grep -c RUNNING` -ne 0 ]
do
        usleep 1000
done

while [ `ifconfig eth1 | grep -c RUNNING` -ne 1 ]
do
        usleep 1000
done
sleep 3
udhcpc -i eth1

echo "Pinging $1..."
RESULT=`ping $1 -w 5 | grep -c "received, 0% packet loss"`
if [ $RESULT -ne 1 ] ; then
        echo FAIL ETH1 TEST
else
	echo PASS ETH1 TEST
fi
ifconfig eth1 down
rmmod fec
echo PASS
echo in > /sys/class/gpio/gpio119/direction
echo 119 > /sys/class/gpio/unexport

