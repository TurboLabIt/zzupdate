#!/usr/bin/env bash
echo ""
SCRIPT_NAME=zzupdate

## bash-fx
if [ -z $(command -v curl) ]; then sudo apt update && sudo apt install curl -y; fi
# needrestart is suppressed here vvv
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

sudo bash /usr/local/turbolab.it/bash-fx/setup/start.sh ${SCRIPT_NAME}
fxLinkBin ${INSTALL_DIR}${SCRIPT_NAME}.sh

## cron copy
if [ ! -f "/etc/cron.d/zzupdate" ]; then
  sudo cp "${INSTALL_DIR}cron" "/etc/cron.d/zzupdate"
fi

sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}
