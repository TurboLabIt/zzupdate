#!/usr/bin/env bash
echo ""

SCRIPT_NAME=zzupdate
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"
fxHeader "🔃 zzupdate 🔃"
rootCheck
fxConfigLoader "$1"

## update bash-fx itself (its setup.sh self-skips if freshly fetched), then re-source it
bash "/usr/local/turbolab.it/bash-fx/setup.sh"
source "/usr/local/turbolab.it/bash-fx/bash-fx.sh"

## update every script by TurboLab.it
ZZSCRIPT_DIRS=($(find $INSTALL_DIR_PARENT -maxdepth 1 -type d))

for ZZSCRIPT_DIR in "${ZZSCRIPT_DIRS[@]}"; do

  ZZSCRIPT_DIR_NAME=$(basename "${ZZSCRIPT_DIR}")

  if [ "${ZZSCRIPT_DIR}/" = "$SCRIPT_DIR" ] || [ ! -d "${ZZSCRIPT_DIR}/.git" ] || [ "${ZZSCRIPT_DIR_NAME}" = "bash-fx" ]; then
    continue
  fi

  fxTitle "***** Update ${ZZSCRIPT_DIR}... *****"
  ## -c trusts the dir for this command only ("config --global --add" would append a duplicate line to root's .gitconfig on every run)
  git -C "$ZZSCRIPT_DIR" -c safe.directory="$ZZSCRIPT_DIR" config core.fileMode false

  ## mirror origin. fetch && reset: an offline run must leave the repo untouched
  git -C "$ZZSCRIPT_DIR" -c safe.directory="$ZZSCRIPT_DIR" fetch --depth 1 \
    && git -C "$ZZSCRIPT_DIR" -c safe.directory="$ZZSCRIPT_DIR" reset --hard @{upstream}

  git -C "$ZZSCRIPT_DIR" -c safe.directory="$ZZSCRIPT_DIR" gc --prune=all

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
      curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
        | sudo tee ${NGINX_SIGN_KEY_PATH} >/dev/null

    else
    
      fxOK "The sign key is recent"
    fi
	
  else
  
    fxMessage "🐇 Skipped (nginx sign key not detected)"
  fi

else

  fxMessage "🐇 Skipped (disabled in config)"
fi


fxTitle "🌎 MySQL sign key update"
if [ "$MYSQL_SIGN_KEY_UPDATE" = "1" ]; then

  MYSQL_SIGN_KEY_PATH=/etc/apt/trusted.gpg.d/webstackup-mysql.gpg
  if [ -f "$MYSQL_SIGN_KEY_PATH" ]; then

    fxInfo "MySQL sign key detected"
    ZZUPDATE_MYSQL_CURRENT_DATE=$(date +%s)
    MYSQL_SIGN_KEY_MOD_DATE=$(stat -c %Y "$MYSQL_SIGN_KEY_PATH")
    MYSQL_SIGN_KEY_AGE=$((ZZUPDATE_MYSQL_CURRENT_DATE - MYSQL_SIGN_KEY_MOD_DATE))
    ## 3 months
    ZZUPDATE_MYSQL_AGE_THRESHOLD=$((90 * 24 * 60 * 60))

    # Check if the file is older than 3 months
    if [ $MYSQL_SIGN_KEY_AGE -gt $ZZUPDATE_MYSQL_AGE_THRESHOLD ]; then

      fxInfo "Updating the sign key..."
      curl https://raw.githubusercontent.com/TurboLabIt/webstackup/refs/heads/master/config/mysql/key.pgp \
        | gpg --dearmor | sudo tee ${MYSQL_SIGN_KEY_PATH} >/dev/null

    else

      fxOK "The sign key is recent"
    fi

  else

    fxMessage "🐇 Skipped (MySQL sign key not detected)"
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

    fwupdmgr refresh --assume-yes
    fwupdmgr get-upgrades --assume-yes
    fwupdmgr update --assume-yes --no-reboot-check

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

fxTitle "🦙 Ollama models update"
if [ "$OLLAMA_MODELS_UPDATE" = "1" ]; then

  if ! [ -x "$(command -v ollama)" ]; then

    fxMessage "🐇 Skipped (ollama not detected)"

  elif ! ollama list > /dev/null 2>&1; then

    fxMessage "🐇 Skipped (the ollama service is not responding)"

  else

    for OLLAMA_MODEL in $(ollama list | awk 'NR>1 {print $1}'); do

      fxInfo "Pulling ##${OLLAMA_MODEL}##..."
      OLLAMA_MODEL_ID_PRE=$(ollama list | awk -v m="$OLLAMA_MODEL" '$1 == m {print $2}')
      ollama pull "$OLLAMA_MODEL"
      OLLAMA_MODEL_ID_POST=$(ollama list | awk -v m="$OLLAMA_MODEL" '$1 == m {print $2}')

      ## if the model was actually updated while loaded in memory, unload it:
      ## the next request will then serve the new version
      if [ "$OLLAMA_MODEL_ID_PRE" != "$OLLAMA_MODEL_ID_POST" ] && ollama ps | awk 'NR>1 {print $1}' | grep -qx "$OLLAMA_MODEL"; then

        fxInfo "##${OLLAMA_MODEL}## was updated while loaded. Unloading it..."
        ollama stop "$OLLAMA_MODEL"
      fi

    done
  fi

else

  fxMessage "🐇 Skipped (disabled in config)"
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
