CURR_VER=`sed 's/\Scipts Commit ID is: //g' version.txt`
UPDATE_FILENAME=jig_scripts_update_${CURR_VER}.tgz
SERVER_IP=192.168.2.1

if ping -c 1 -w 1 ${SERVER_IP} &>/dev/null;
then
	if tftp -g -r ${UPDATE_FILENAME} 192.168.2.1 &> /dev/null;
	then
		echo Got update: ${UPDATE_FILENAME}
		if tar xOf ${UPDATE_FILENAME} &> /dev/null;
		then
			tar xf ${UPDATE_FILENAME} && sync && echo "Update applied" || echo "Error applying update"
		else
			echo "Error applying update"
		fi
		rm -f ${UPDATE_FILENAME}; sync; cat version.txt
	else
		echo No update file found
	fi
else
	echo "No connection to update server"
fi

