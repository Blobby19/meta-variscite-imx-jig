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
echo 1 > /sys/class/gpio/gpio119/value

/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_SD2_CD_B=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_SD2_WP=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_TXC=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_TD0=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_TD1=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_TD2=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_TD3=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_TX_CTL=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_RXC=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_RD0=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_RD1=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_RD2=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_RD3=5 &>/dev/null
/unit_tests/memtool IOMUXC.SW_MUX_CTL_PAD_ENET1_RGMII_RX_CTL=5 &>/dev/null


#Test the pins
gpio_test_pair_bank 7 0		7 1
gpio_test_pair_bank 7 2		7 3
gpio_test_pair_bank 7 4		7 5
gpio_test_pair_bank 7 6        	7 7
gpio_test_pair_bank 7 8        	7 11
gpio_test_pair_bank 7 9        	7 11
gpio_test_pair_bank 5 9         5 10

echo in > /sys/class/gpio/gpio119/direction
echo 119 > /sys/class/gpio/unexport

echo $STATUS

