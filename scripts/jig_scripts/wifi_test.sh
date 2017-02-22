#! /bin/sh

LIMIT=$1
if [ -z "$1" ]; then
        LIMIT="55"
fi

SSID=$2
if [ -z "$2" ]; then
        SSID="VarisciteLTD"
fi

ifconfig wlan0 up

MIN=1000

for i in 1 2 3 4 5 6 7 8
do
        NUM_VAR=`iw wlan0 scan ssid $SSID | grep signal |cut -d' ' -f2|cut -d. -f1|cut -d- -f2`
        if [ -n "$NUM_VAR" ]; then
                if [[ $NUM_VAR < $LIMIT ]]; then
                        echo PASS! Signal is -$NUM_VAR.00 dBm
                        exit 1
                fi
        fi
        echo Signal: -$NUM_VAR dBm

        ifconfig wlan0 up
        sleep 2
done
echo FAIL.
