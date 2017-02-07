#!/bin/sh

OCOTP_MEM0="0x021BC480"

VAL=`devmem2 ${OCOTP_MEM0} w | grep "Read at address  ${OCOTP_MEM0}" | cut -d' ' -f7`
let "VAL = (VAL >> 6) & 0x3"

case $VAL in
0)
	echo "Commercial (0 to 95C)"
	;;
1)
	echo "Extended Commercial (-20 to 105C)"
	;;
2)
	echo "Industrial (-40 to 105C)"
	;;
3)
	echo "Automotive (-40 to 125C)"
	;;
esac

