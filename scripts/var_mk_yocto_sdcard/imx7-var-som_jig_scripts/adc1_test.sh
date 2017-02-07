if [ ! -d "/sys/class/gpio/gpio33" ]; then
        echo 33 > /sys/class/gpio/export
fi

echo out > /sys/class/gpio/gpio33/direction
usleep 50000
echo 1 > /sys/class/gpio/gpio33/value

#Read once, the first readings are incorrect
IN0=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage0_raw`
IN1=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage1_raw`
IN2=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage2_raw`
IN3=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage3_raw`
sleep 1
#Read second time, the readings are correct
IN0=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage0_raw`
IN1=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage1_raw`
IN2=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage2_raw`
IN3=`cat /sys/devices/platform/soc/30400000.aips-bus/30610000.adc/iio:device0/in_voltage3_raw`
RESULT="PASS"
if [[ $IN0 < 1450 ]]; then
        if [[ $IN0 > 1350 ]]; then
                echo adc1_in0 test PASS reading is $IN0
        else
                echo adc1_in0 test FAIL reading is $IN0
                RESULT="FAIL"
        fi
else
        echo adc1_in0 test FAIL reading is $IN0
        RESULT="FAIL"
fi

if [[ $IN1 < 1450 ]]; then
        if [[ $IN1 > 1350 ]]; then
                echo adc1_in1 test PASS reading is $IN1
        else
                echo adc1_in1 test FAIL reading is $IN1
                RESULT="FAIL"
        fi
else
        echo adc1_in1 test FAIL reading is $IN1
        RESULT="FAIL"
fi

if [[ $IN2 < 1525 ]]; then
        if [[ $IN2 > 1425 ]]; then
                echo adc1_in2 test PASS  reading is $IN2
        else
                echo adc1_in2 test FAIL reading is $IN2
                RESULT="FAIL"
        fi
else
        echo adc1_in2 test FAIL reading is $IN2
        RESULT="FAIL"
fi

if [[ $IN3 < 1525 ]]; then
        if [[ $IN3 > 1425 ]]; then
                echo adc1_in3 test PASS  reading is $IN3
        else
                echo adc1_in3 test FAIL reading is $IN3
                RESULT="FAIL"
        fi
else
        echo adc1_in3 test FAIL reading is $IN3
        RESULT="FAIL"
fi

echo $RESULT

