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

    fxCatastrophicError "Profile config file(s) not found" proceed
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

## update every script by TurboLab.it
ZZSCRIPT_DIRS=($(find $INSTALL_DIR_PARENT -maxdepth 1 -type d))

for ZZSCRIPT_DIR in "${ZZSCRIPT_DIRS[@]}"; do

  ZZSCRIPT_DIR_NAME=$(basename "${ZZSCRIPT_DIR}")

  if [ "${ZZSCRIPT_DIR}/" = "$SCRIPT_DIR" ] || [ ! -d "${ZZSCRIPT_DIR}/.git" ] || [ "${ZZSCRIPT_DIR_NAME}" = "bash-fx" ]; then
    continue
  fi

  fxTitle "***** Update ${ZZSCRIPT_DIR}... *****"
  git config --global --add safe.directory "$ZZSCRIPT_DIR"
  git -C "$ZZSCRIPT_DIR" reset --hard
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

  fxTitle "🦘 Switching to the 'normal' release channel (if 'never' or 'lts')"
  sed -i -E 's/Prompt=(never|lts)/Prompt=normal/g' "/etc/update-manager/release-upgrades"

else

  fxTitle "🐇 Channel switching is disabled: using pre-existing setting"
fi


fxTitle "🌎 Nginx sign key update"
if [ "$NGINX_SIGN_KEY_UPDATE" = "1" ]; then

  NGINX_SIGN_KEY_PATH=/usr/share/keyrings/nginx-archive-keyring.gpg
  if [ -f "$NGINX_SIGN_KEY_PATH" ]; then

    fxInfo "Nginx sign key detected"
    ZZUPDATE_NGINX_CURRENT_DATE=$(date +%s)
    NGINX_SIGN_KEY_MOD_DATE=$(stat -c %Y "$NGINX_SIGN_KEY_PATH")
    NGINX_SIGN_KEY_AGE=$((ZZUPDATE_NGINX_CURRENT_DATE - NGINX_SIGN_KEY_MOD_DATE))
    ## 3 months
    ZZUPDATE_NGINX_AGE_THRESHOLD=$((90 * 24 * 60 * 60))

    # Check if the file is older than 3 months
    if [ $NGINX_SIGN_KEY_AGE -gt $ZZUPDATE_NGINX_AGE_THRESHOLD ]; then

      fxInfo "Updating the sign key..."
      curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

    else
    
      fxOK "The sign key is recent"
    fi
	
  else
  
    fxMessage "🐇 Skipped (nginx sign key not detected)"
  fi

else

  fxMessage "🐇 Skipped (disabled in config)"
fi


fxTitle "🧹 Cleanup local cache"
apt-get clean

fxTitle "🔍 Update available packages informations"
apt-get update --allow-releaseinfo-change

fxTitle "📦 UPGRADE PACKAGES"
apt-get dist-upgrade -y --allow-downgrades
snap refresh


fxTitle "⚙️ Firmware upgrade"
if [ "$(fxContainerDetection silent)" = "1" ] && [ "$FIRMWARE_UPGRADE" = "1" ]; then

  fxMessage "🐋 Skipped (container detected)"

elif [ "$FIRMWARE_UPGRADE" = "1" ]; then

  if [ -z $(command -v fwupdmgr) ]; then apt install fwupd -y; fi
  fwupdmgr get-upgrades -y --assume-yes
  fwupdmgr update -y --no-reboot

else

  fxMessage "🐇 Skipped (disabled in config)"
fi


if [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "1" ]; then

  fxTitle "➡️ Silently upgrade to a new release, if any"
  do-release-upgrade -f DistUpgradeViewNonInteractive

elif [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "0" ]; then

  fxTitle "➡️ Interactively upgrade to a new release, if any"
  do-release-upgrade

else

  fxTitle "🐇 Upgrade to a new release skipped (disabled in config)"
fi

if [ "$COMPOSER_UPGRADE" = "1" ]; then

  fxTitle "📦 Self-updating Composer..."

  if ! [ -x "$(command -v composer)" ]; then
    fxMessage "Composer is not installed"
  else
    XDEBUG_MODE=off composer self-update
  fi
fi

fxTitle "🧹 Packages cleanup (autoremove unused packages)"
apt autoremove -y

fxTitle "ℹ️ Current version"
lsb_release -a

if [ "$REBOOT" = "1" ]; then

  fxTitle "🔌 Rebooting"
  fxCountdown "$REBOOT_TIMEOUT"
  bash -c "sleep 3; reboot"&
fi

fxEndFooter
