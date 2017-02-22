#!/bin/sh +x

# GPIO test script on 'JIG' board, iMX6

RED="\\033[0;31m"
NOCOLOR="\\033[0;39m"
GREEN="\\033[0;32m"
GRAY="\\033[0;37m"
OK="${GREEN}OK$NOCOLOR"
FAIL="${RED}FAIL$NOCOLOR"
STATUS="PASS"


fail()
{
        STATUS="FAIL";
        echo -e "$@"
        #exit 1
}

gpio_test_pair_num()
{
        if [ ! -d "/sys/class/gpio/gpio$1" ]; then
                echo $1 > /sys/class/gpio/export
        fi
        if [ ! -d "/sys/class/gpio/gpio$2" ]; then
                echo $2 > /sys/class/gpio/export
        fi
        echo in > /sys/class/gpio/gpio$2/direction
        echo out > /sys/class/gpio/gpio$1/direction

        echo 0 > /sys/class/gpio/gpio$1/value
        usleep 10000
        grep -q 0 /sys/class/gpio/gpio$2/value || fail "set 0 gpio $1 -> $2 $FAIL"

        echo 1 > /sys/class/gpio/gpio$1/value
        usleep 10000
        grep -q 1 /sys/class/gpio/gpio$2/value || fail "set 1 gpio $1 -> $2 $FAIL"
#	let "EXPECTED = 1 << ($2 % 32)"
#	grep -q $EXPECTED /sys/class/gpio/gpio$2/value || fail "set 1 gpio $1 -> $2 $FAIL"

        echo in > /sys/class/gpio/gpio$1/direction
        echo in > /sys/class/gpio/gpio$2/direction
}

gpio_test_pair_bank()
{
        echo "Testing GPIO$1[$2] to GPIO$3[$4] raising and falling"
        gpio_test_pair_num $((($1-1)*32+$2)) $((($3-1)*32+$4))
}

gpio_test_pair_bank 3 5 3 6 
gpio_test_pair_bank 3 7 3 8 
gpio_test_pair_bank 3 9 3 13 
gpio_test_pair_bank 3 15 3 17 
gpio_test_pair_bank 3 19 3 20 
gpio_test_pair_bank 3 21 3 22 
gpio_test_pair_bank 3 23 3 24 
gpio_test_pair_bank 3 25 3 26 
gpio_test_pair_bank 3 27 3 28 
gpio_test_pair_bank 3 0 5 10 
gpio_test_pair_bank 3 10 5 11 
gpio_test_pair_bank 3 14 3 18 
gpio_test_pair_bank 3 12 3 16 
gpio_test_pair_bank 3 1 3 4 
gpio_test_pair_bank 3 3 3 2 
gpio_test_pair_bank 4 17 4 18 
gpio_test_pair_bank 4 20 4 21 
gpio_test_pair_bank 2 8 2 9 
gpio_test_pair_bank 2 10 2 11 
gpio_test_pair_bank 2 12 2 13 
gpio_test_pair_bank 2 14 2 15 
gpio_test_pair_bank 4 14 5 5 
gpio_test_pair_bank 4 24 4 19 
gpio_test_pair_bank 1 24 1 25 
gpio_test_pair_bank 1 26 1 27 
gpio_test_pair_bank 1 8 1 10 
gpio_test_pair_bank 1 5 5 7 
gpio_test_pair_bank 5 8 5 9 
gpio_test_pair_bank 1 18 1 19 
gpio_test_pair_bank 1 28 1 29 
gpio_test_pair_bank 1 1 1 2 
gpio_test_pair_bank 1 4 1 9 
gpio_test_pair_bank 4 22 1 0 

#Testing SAI1 group. Used only on BC function SOM
gpio_test_pair_bank 4 25 4 26
gpio_test_pair_bank 4 27 4 28

echo $STATUS


