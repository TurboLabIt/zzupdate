#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzupdate
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🔃 zzupdate 🔃"
rootCheck
fxConfigLoader

## Profile requested
if [ ! -z "$1" ]; then

  fxTitle "📋 Profile requested..."

  CONFIGFILE_PROFILE_NAME=${SCRIPT_NAME}.profile.${1}.conf
  CONFIGFILE_PROFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_PROFILE_NAME
  CONFIGFILE_PROFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_PROFILE_NAME

  if [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_ETC" ] && [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_DIR" ]; then

    fxCatastrophicError "Profile config file(s) not found"
    echo "🕳️ $CONFIGFILE_PROFILE_FULLPATH_ETC"
    echo "🕳️ $CONFIGFILE_PROFILE_FULLPATH_DIR"
    echo ""

    fxTitle "How to fix it"
    echo "Create a config file for this profile:"
    echo "sudo cp $CONFIGFILE_FULLPATH_DEFAULT $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo nano $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo chmod u=rwx,go=rx /etc/turbolab.it/zzupdate*"

    fxEndFooter failure
    exit
  fi

  fxLoadConfigFromInput "$CONFIGFILE_PROFILE_FULLPATH_ETC" "$CONFIGFILE_PROFILE_FULLPATH_DIR"

fi

## self-update
HASH_BEFORE=$(fxHashFile "${SCRIPT_FULLPATH}")

fxTitle "Self-update...."
git -C "${SCRIPT_DIR}" pull --no-rebase
bash "${SCRIPT_DIR}setup.sh"

HASH_AFTER=$(fxHashFile "${SCRIPT_FULLPATH}")

fxSelfUpdateHashCheck "${HASH_BEFORE}" "${HASH_AFTER}"


## update every script by TurboLab.it
ZZSCRIPT_DIRS=($(find $INSTALL_DIR_PARENT -maxdepth 1 -type d))

for ZZSCRIPT_DIR in "${ZZSCRIPT_DIRS[@]}"; do

  ZZSCRIPT_DIR_NAME=$(basename "${ZZSCRIPT_DIR}")

  if [ "${ZZSCRIPT_DIR}/" = "$SCRIPT_DIR" ] || [ ! -d "${ZZSCRIPT_DIR}/.git" ] || [ "${ZZSCRIPT_DIR_NAME}" = "bash-fx" ]; then
    continue
  fi

  fxTitle "***** Update ${ZZSCRIPT_DIR}... *****"
  git -C "$ZZSCRIPT_DIR" pull --no-rebase

  if [ -f "${ZZSCRIPT_DIR}/setup.sh" ]; then
    bash "${ZZSCRIPT_DIR}/setup.sh"
  fi

done


## run a custom update script (if configured)
if [ ! -z "${ADDITIONAL_UPDATE_SCRIPT}" ]; then
  fxTitle "💨 Running ${ADDITIONAL_UPDATE_SCRIPT}..."
  bash "$ADDITIONAL_UPDATE_SCRIPT"
fi


if [ "$SWITCH_PROMPT_TO_NORMAL" = "1" ]; then

  fxTitle "Switching to the 'normal' release channel (if 'never' or 'lts')"
  sed -i -E 's/Prompt=(never|lts)/Prompt=normal/g' "/etc/update-manager/release-upgrades"

else

  fxTitle "Channel switching is disabled: using pre-existing setting"

fi


fxTitle "Cleanup local cache"
apt-get clean

fxTitle "Update available packages informations"
apt-get update

fxTitle "UPGRADE PACKAGES"
apt-get dist-upgrade -y --allow-downgrades


if [ "$FIRMWARE_UPGRADE" = "1" ]; then

  fxTitle "Firmware upgrade"
  if [ -z $(command -v fwupdmgr) ]; then apt install fwupd -y; fi
  fwupdmgr get-upgrades -y
  fwupdmgr update -y

else

  fxTitle "Firmware upgrade skipped (disabled in config)"

fi


if [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "1" ]; then

  fxTitle "Silently upgrade to a new release, if any"
  do-release-upgrade -f DistUpgradeViewNonInteractive

elif [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "0" ]; then

  fxTitle "Interactively upgrade to a new release, if any"
  do-release-upgrade

else

  fxTitle "Upgrade to a new release skipped (disabled in config)"

fi

if [ "$COMPOSER_UPGRADE" = "1" ]; then

  fxTitle "Self-updating Composer..."

  if ! [ -x "$(command -v composer)" ]; then
    fxMessage "Composer is not installed"
  else
    XDEBUG_MODE=off composer self-update
  fi
fi

if [ "$SYMFONY_UPGRADE" = "1" ]; then

  fxTitle "Self-updating Symfony"

  if ! [ -x "$(command -v symfony)" ]; then
    fxMessage "Symfony is not installed"
  else
    symfony self:update --yes
  fi
fi

fxTitle "Packages cleanup (autoremove unused packages)"
apt-get autoremove -y

fxTitle "Current version"
lsb_release -a

fxTitle "Time took"
echo "$((($(date +%s)-$TIME_START)/60)) min."

if [ "$REBOOT" = "1" ]; then

  fxTitle "Rebooting"
  fxCountdown "$REBOOT_TIMEOUT"
  shutdown -r -t 5
fi

fxEndFooter
