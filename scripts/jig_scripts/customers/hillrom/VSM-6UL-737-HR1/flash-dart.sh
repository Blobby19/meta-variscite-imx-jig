#!/usr/bin/env sh
set -e

SCRIPT_DIR=`dirname $0`
SCRIPT_PATH=`cd -P -- "${SCRIPT_DIR}" && pwd -P`

echo "Install Yocto image..."
$SCRIPT_PATH/install_hillrom_yocto.sh -i hillrom-qt5-image.tar.gz -d imx6ul-var-dart-emmc_wifi-geyser.dtb -a appfs.tar.gz

sync; sleep 1
echo "PASS: DART has been flashed."
