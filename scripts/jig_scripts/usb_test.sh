#!/bin/sh
if [ "$(lsusb | grep -c "10c4:ea60")" -ne "1" ]; then
        echo "FAIL. USBHOST device was not found!!! SOM Pins 108,110. CPU is not soldered well."
        exit 1
fi

echo "PASS"


