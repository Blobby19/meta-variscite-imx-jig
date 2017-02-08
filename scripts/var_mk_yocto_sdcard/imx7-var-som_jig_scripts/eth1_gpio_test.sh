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
	A=$((($1-1)*32+$2))
	B=$((($3-1)*32+$4))

        if [ ! -d "/sys/class/gpio/gpio$A" ]; then
                echo $A > /sys/class/gpio/export
        fi
        if [ ! -d "/sys/class/gpio/gpio$B" ]; then
                echo $B > /sys/class/gpio/export
        fi
        echo in > /sys/class/gpio/gpio$B/direction
        echo out > /sys/class/gpio/gpio$A/direction

        echo 0 > /sys/class/gpio/gpio$A/value
        grep -q 0 /sys/class/gpio/gpio$B/value || fail "set 0 gpio$1[$2]($A) -> gpio$3[$4]($B) $FAIL"

        echo 1 > /sys/class/gpio/gpio$A/value
	grep -q 1 /sys/class/gpio/gpio$B/value || fail "set 1 gpio$1[$2]($A) -> gpio$3[$4]($B) $FAIL"

        echo in > /sys/class/gpio/gpio$A/direction
        echo in > /sys/class/gpio/gpio$B/direction
}

gpio_test_pair_bank()
{
	echo "Testing GPIO$1[$2] to GPIO$3[$4] raising and falling"
	gpio_test_pair_num $1 $2 $3 $4
}

#Switch ETH1 pins to GPIO
echo 119 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio119/direction
echo 0 > /sys/class/gpio/gpio119/value

/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_GDSP=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDCE2=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDCE3=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_GDCLK=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_GDOE=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_GDRL=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDCE1=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDCLK=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDLE=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDOE=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDSHR=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_EPDC_SDCE0=5 &>/dev/null


#Test the pins
gpio_test_pair_bank 2 16	2 17
gpio_test_pair_bank 2 18	2 19
gpio_test_pair_bank 2 20	2 21
gpio_test_pair_bank 2 22        2 23
gpio_test_pair_bank 2 24        2 27
gpio_test_pair_bank 2 25        2 27

echo in > /sys/class/gpio/gpio119/direction
echo 119 > /sys/class/gpio/unexport

echo $STATUS
