#!/usr/bin/env bash
echo ""
SCRIPT_NAME=zzupdate

## bash-fx
if [ -z "$(command -v curl)" ]; then
  sudo apt update && sudo apt install curl -y
fi
curl -s https://raw.githubusercontent.com/TurboLabIt/bash-fx/master/setup.sh?$(date +%s) | sudo bash
source /usr/local/turbolab.it/bash-fx/bash-fx.sh
## bash-fx is ready

sudo bash /usr/local/turbolab.it/bash-fx/setup/start.sh ${SCRIPT_NAME}

## Symlink (globally-available zzupdate command)
if [ ! -f "/usr/local/bin/${SCRIPT_NAME}" ]; then
  ln -s ${INSTALL_DIR}${SCRIPT_NAME}.sh /usr/local/bin/${SCRIPT_NAME}
fi

sudo bash /usr/local/turbolab.it/bash-fx/setup/the-end.sh ${SCRIPT_NAME}
