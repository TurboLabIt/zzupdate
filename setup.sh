#!/usr/bin/env bash
echo ""
SCRIPT_NAME=zzupdate

## bash-fx
sudo apt update && sudo apt install curl -y
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

sudo bash /usr/local/turbolab.it/bash-fx/setup/start.sh ${SCRIPT_NAME}
fxLinkBin ${INSTALL_DIR}${SCRIPT_NAME}.sh
sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}
