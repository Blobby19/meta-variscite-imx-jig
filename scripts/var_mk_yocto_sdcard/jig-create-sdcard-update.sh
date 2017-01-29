#!/bin/bash -e

readonly ABSOLUTE_FILENAME=`readlink -e "$0"`
readonly ABSOLUTE_DIRECTORY=`dirname ${ABSOLUTE_FILENAME}`
readonly SCRIPT_POINT=${ABSOLUTE_DIRECTORY}

readonly JIG_SCRIPTS_PATH=${SCRIPT_POINT}/${MACHINE}_jig_scripts
readonly CALL_DIRECTORY=`pwd`

function usage
{
	echo "Usage: MACHINE=<var-som-mx6|imx6ul-var-dart|imx7-var-som> $0 CURRENT_SD_CARD_COMMIT_ID"
}

if [ "$MACHINE" != "var-som-mx6" ] &&
   [ "$MACHINE" != "imx6ul-var-dart" ] &&
   [ "$MACHINE" != "imx7-var-som" ] ||
   [ "$#" -ne 1 ]; then
	usage
	exit 1
fi

OLD_COMMIT_ID=$1

echo
echo "[34m[1mCreating update containing files changed in ${MACHINE}_jig_scripts in the following commits:[0m"
echo
git log ${OLD_COMMIT_ID}..HEAD

echo
echo
echo "[34m[1mFiles updated:[0m"

UPDATE_FILENAME=${MACHINE}_jig_scripts_update_${OLD_COMMIT_ID}.tgz
rm -f ${UPDATE_FILENAME} &> /dev/null

cd ${JIG_SCRIPTS_PATH}
echo "Scipts Commit ID is:" `git rev-parse HEAD` > version.txt
{ echo version.txt; git diff-tree --no-commit-id --name-only -r --relative ${OLD_COMMIT_ID} HEAD ./ ; } | tar -czvf ${CALL_DIRECTORY}/${UPDATE_FILENAME} -T -
rm -f version.txt

echo
echo "[1m${UPDATE_FILENAME}[34m created.[0m"
echo
