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

# Setting GPIO1[6] high is requred for GPIO test to pass on VAR-SOM-MX7-5G.
# Otherwise the following GPIO pairs will fail the test: GPIO4[15] -> GPIO4[6]
# and GPIO6[20] -> GPIO4[4]. The reason is that GPIO4[4] and GPIO4[6] are BT RX
# and RTS lines respectively, coming from BT buffer. For GPIO test to pass the
# buffer should be closed using GPIO1[6].
gpio_test_init()
{
	if [ "$WBD" = "true" -a ! -d /sys/class/gpio/gpio6 ]; then
		echo 6  > /sys/class/gpio/export
		echo out > /sys/class/gpio/gpio6/direction
		echo 1   > /sys/class/gpio/gpio6/value
	fi
}

# Setting GPIO1[6] low is requred for BT test to pass on VAR-SOM-MX7-5G.
gpio_test_exit()
{
	if [ "$WBD" = "true" -a -d /sys/class/gpio/gpio6 ]; then
		echo 0 > /sys/class/gpio/gpio6/value
	fi
}

gpio_test_init

gpio_test_pair_bank 2 1		3 26
gpio_test_pair_bank 2 4		2 14
gpio_test_pair_bank 2 9		3 28
gpio_test_pair_bank 2 15	3 24
gpio_test_pair_bank 2 3		3 25
gpio_test_pair_bank 2 2		2 5
gpio_test_pair_bank 2 0		2 13
gpio_test_pair_bank 2 11	3 4
gpio_test_pair_bank 3 27	3 22
gpio_test_pair_bank 2 8		3 5
gpio_test_pair_bank 2 7		3 1
gpio_test_pair_bank 2 6		3 2
gpio_test_pair_bank 3 6		3 3
gpio_test_pair_bank 2 12	3 0
gpio_test_pair_bank 3 7		3 12
gpio_test_pair_bank 3 21	3 13
gpio_test_pair_bank 3 8		3 16
gpio_test_pair_bank 3 17	3 23
gpio_test_pair_bank 2 28	3 11
gpio_test_pair_bank 2 29	3 20
#ETH2 gpio_test_pair_bank 3 18	2 26
#ETH1 gpio_test_pair_bank 7 10	3 15
gpio_test_pair_bank 4 22	3 10
gpio_test_pair_bank 4 21	3 14
gpio_test_pair_bank 4 23	3 9
gpio_test_pair_bank 4 20	3 19
gpio_test_pair_bank 4 13	2 30
gpio_test_pair_bank 5 0		4 12
gpio_test_pair_bank 5 1		1 13
gpio_test_pair_bank 1 10	1 2
gpio_test_pair_bank 1 12	1 0
gpio_test_pair_bank 1 11	6 17
gpio_test_pair_bank 1 7		6 16
gpio_test_pair_bank 1 5		6 22


#Test BT pads
#Disable BT, Switch UART3 pins to GPIO
if [ ! -d "/sys/class/gpio/gpio14" ]; then
	echo 14 > /sys/class/gpio/export
fi
echo out > /sys/class/gpio/gpio14/direction
echo 0 > /sys/class/gpio/gpio14/value
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_CTS_B.MUX_MODE=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_RTS_B.MUX_MODE=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_RX_DATA.MUX_MODE=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_TX_DATA.MUX_MODE=5 &>/dev/null
#Test the pins
gpio_test_pair_bank 4 15        4 6
gpio_test_pair_bank 4 14        4 7
gpio_test_pair_bank 6 20        4 4
gpio_test_pair_bank 6 19        4 5
#Revert the changes BT pins
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_CTS_B.MUX_MODE=0 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_RTS_B.MUX_MODE=0 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_RX_DATA.MUX_MODE=0 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_UART3_TX_DATA.MUX_MODE=0 &>/dev/null
echo 1 > /sys/class/gpio/gpio14/value

gpio_test_exit

echo $STATUS

