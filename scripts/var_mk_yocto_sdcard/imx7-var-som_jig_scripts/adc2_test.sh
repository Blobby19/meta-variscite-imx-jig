#Read once, the first readings are incorrect
IN0=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage0_raw`
IN1=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage1_raw`
IN2=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage2_raw`
IN3=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage3_raw`
sleep 1
#Read second time, the readings are correct
IN0=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage0_raw`
IN1=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage1_raw`
IN2=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage2_raw`
IN3=`cat /sys/devices/platform/soc/30400000.aips-bus/30620000.adc/iio:device1/in_voltage3_raw`
RESULT="PASS"
if [[ $IN0 < 751 ]]; then
        if [[ $IN0 > 689 ]]; then
                echo adc2_in0 test PASS reading is $IN0
        else
                echo adc2_in0 test FAIL reading is $IN0
                RESULT="FAIL"
        fi
else
        echo adc2_in0 test FAIL reading is $IN0
        RESULT="FAIL"
fi

if [[ $IN1 < 751 ]]; then
        if [[ $IN1 > 689 ]]; then
                echo adc2_in1 test PASS reading is $IN1
        else
                echo adc2_in1 test FAIL reading is $IN1
                RESULT="FAIL"
        fi
else
        echo adc2_in1 test FAIL reading is $IN1
        RESULT="FAIL"
fi

if [[ $IN2 < 751 ]]; then
        if [[ $IN2 > 689 ]]; then
                echo adc2_in2 test PASS  reading is $IN2
        else
                echo adc2_in2 test FAIL reading is $IN2
                RESULT="FAIL"
        fi
else
        echo adc2_in2 test FAIL reading is $IN2
        RESULT="FAIL"
fi

if [[ $IN3 < 751 ]]; then
        if [[ $IN3 > 689 ]]; then
                echo adc2_in3 test PASS  reading is $IN3
        else
                echo adc2_in3 test FAIL reading is $IN3
                RESULT="FAIL"
        fi
else
        echo adc2_in3 test FAIL reading is $IN3
        RESULT="FAIL"
fi

echo $RESULT

