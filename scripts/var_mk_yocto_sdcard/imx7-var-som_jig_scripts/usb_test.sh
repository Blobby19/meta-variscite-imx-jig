#! /bin/sh
modprobe g_ether
sleep 1 
if [ "$(ifconfig -a | grep -c "usb")" -ne "2" ]; then
        echo "FAIL. USB or OTG in not resonding."
        exit 1
fi

rmmod g_ether.ko

echo "PASS"      

