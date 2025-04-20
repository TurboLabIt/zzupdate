#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzupdate
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🔃 zzupdate Proxmox edition 🔃"
rootCheck
fxConfigLoader "$1"

## update every script by TurboLab.it
ZZSCRIPT_DIRS=($(find $INSTALL_DIR_PARENT -maxdepth 1 -type d))

for ZZSCRIPT_DIR in "${ZZSCRIPT_DIRS[@]}"; do

  ZZSCRIPT_DIR_NAME=$(basename "${ZZSCRIPT_DIR}")

  if [ "${ZZSCRIPT_DIR}/" = "$SCRIPT_DIR" ] || [ ! -d "${ZZSCRIPT_DIR}/.git" ] || [ "${ZZSCRIPT_DIR_NAME}" = "bash-fx" ]; then
    continue
  fi

  fxTitle "***** Update ${ZZSCRIPT_DIR}... *****"
  git -C "$ZZSCRIPT_DIR" reset --hard
  git -C "$ZZSCRIPT_DIR" pull --no-rebase

  if [ -f "${ZZSCRIPT_DIR}/setup-if-stale.sh" ]; then

    bash "${ZZSCRIPT_DIR}/setup-if-stale.sh"

  elif [ -f "${ZZSCRIPT_DIR}/setup.sh" ]; then

    bash "${ZZSCRIPT_DIR}/setup.sh"
  fi

done


## run a custom update script (if configured)
if [ ! -z "${ADDITIONAL_UPDATE_SCRIPT}" ]; then
  fxTitle "💨 Running ${ADDITIONAL_UPDATE_SCRIPT}..."
  bash "$ADDITIONAL_UPDATE_SCRIPT"
fi

fxTitle "ℹ️ Current, pre-update version"
pveversion


fxTitle "🧹 Cleanup local cache"
apt-get clean

fxTitle "🔍 Update available packages informations"
apt-get update

fxTitle "📦 UPGRADE PACKAGES"
apt dist-upgrade -y


fxTitle "🧹 Packages cleanup (autoremove unused packages)"
apt-get autoremove -y

fxTitle "ℹ️ Current, post-update version"
pveversion

if [ "$REBOOT" = "1" ]; then

  fxTitle "🔌 Rebooting"
  fxCountdown "$REBOOT_TIMEOUT"
  bash -c "sleep 3; reboot"&
fi

fxEndFooter
