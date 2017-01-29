CURR_VER=`sed 's/\Scipts Commit ID is: //g' version.txt`
MACHINE=var-som-mx6
UPDATE_FILENAME=${MACHINE}_jig_scripts_update_${CURR_VER}.tgz
SERVER_IP=192.168.2.1

if ping -c 1 -w 1 ${SERVER_IP} &> /dev/null;
then
	cd /tmp
	if tftp -g -r ${UPDATE_FILENAME} ${SERVER_IP} &> /dev/null;
	then
		echo "Got update: ${UPDATE_FILENAME}"
		if tar xOf ${UPDATE_FILENAME} &> /dev/null;
		then
			cd
			mount -o remount,rw ~ && \
			tar xf /tmp/${UPDATE_FILENAME} && \
			sync && \
			mount -o remount,ro ~ && \
			echo "Update applied" || echo "Error applying update"
		else
			echo "Error applying update"
		fi
		rm -f /tmp/${UPDATE_FILENAME}
		cat version.txt
	else
		echo "No update file found"
	fi
else
	echo "No connection to update server"
fi
