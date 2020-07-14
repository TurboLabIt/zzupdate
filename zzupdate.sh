#!/bin/bash
clear

## Script name
SCRIPT_NAME=zzupdate

## Title and graphics
FRAME="O===========================================================O"
echo "$FRAME"
echo "      $SCRIPT_NAME - $(date)"
echo "$FRAME"

## Enviroment variables
TIME_START="$(date +%s)"
DOWEEK="$(date +'%u')"
HOSTNAME="$(hostname)"

## Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT_FULLPATH=$(readlink -f "$0")
SCRIPT_HASH=`md5sum ${SCRIPT_FULLPATH} | awk '{ print $1 }'`

## Absolute path this script is in, thus /home/user/bin
SCRIPT_DIR=$(dirname "$SCRIPT_FULLPATH")/

## Config files
CONFIGFILE_NAME=$SCRIPT_NAME.conf
CONFIGFILE_FULLPATH_DEFAULT=${SCRIPT_DIR}$SCRIPT_NAME.default.conf
CONFIGFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_NAME
CONFIGFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_NAME

## Title printing function
function printTitle
{
    echo ""
    echo "$1"
    printf '%0.s-' $(seq 1 ${#1})
    echo ""
}

## root check
if ! [ $(id -u) = 0 ]; then

		echo ""
		echo "vvvvvvvvvvvvvvvvvvvv"
		echo "Catastrophic error!!"
		echo "^^^^^^^^^^^^^^^^^^^^"
		echo "This script must run as root!"

		printTitle "How to fix it?"
		echo "Execute the script like this:"
		echo "sudo $SCRIPT_NAME"

		printTitle "The End"
		echo $(date)
		echo "$FRAME"
		exit
fi

## Profile requested
if [ ! -z "$1" ]; then

	CONFIGFILE_PROFILE_NAME=${SCRIPT_NAME}.profile.${1}.conf
	CONFIGFILE_PROFILE_FULLPATH_ETC=/etc/turbolab.it/$CONFIGFILE_PROFILE_NAME
	CONFIGFILE_PROFILE_FULLPATH_DIR=${SCRIPT_DIR}$CONFIGFILE_PROFILE_NAME

	if [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_ETC" ] && [ ! -f "$CONFIGFILE_PROFILE_FULLPATH_DIR" ]; then

		echo ""
		echo "vvvvvvvvvvvvvvvvvvvv"
		echo "Catastrophic error!!"
		echo "^^^^^^^^^^^^^^^^^^^^"
		echo "Profile config file(s) not found:"
		echo "[X] $CONFIGFILE_PROFILE_FULLPATH_ETC"
		echo "[X] $CONFIGFILE_PROFILE_FULLPATH_DIR"

		printTitle "How to fix it?"
		echo "Create a config file for this profile:"
		echo "sudo cp $CONFIGFILE_FULLPATH_DEFAULT $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo nano $CONFIGFILE_PROFILE_FULLPATH_ETC && sudo chmod ugo=rw /etc/turbolab.it/*.conf"

		printTitle "The End"
		echo $(date)
		echo "$FRAME"
		exit
	fi
fi


for CONFIGFILE_FULLPATH in "$CONFIGFILE_FULLPATH_DEFAULT" "$CONFIGFILE_MYSQL_FULLPATH_ETC" "$CONFIGFILE_FULLPATH_ETC" "$CONFIGFILE_FULLPATH_DIR" "$CONFIGFILE_PROFILE_FULLPATH_ETC" "$CONFIGFILE_PROFILE_FULLPATH_DIR"
do
	if [ -f "$CONFIGFILE_FULLPATH" ]; then
		source "$CONFIGFILE_FULLPATH"
	fi
done
	

printTitle "Self-update...."
source "${SCRIPT_FULLPATH}setup.sh"

SCRIPT_HASH_AFTER_UPDATE=`md5sum ${SCRIPT_FULLPATH} | awk '{ print $1 }'`
if [ "$SCRIPT_HASH" != "$SCRIPT_HASH_AFTER_UPDATE" ]; then

		echo ""
		echo "vvvvvvvvvvvvvvvvvvvvvv"
		echo "Self-update installed!"
		echo "^^^^^^^^^^^^^^^^^^^^^^"
		echo "zzupdate itself has been updated!"
		echo "Please run zzupdate again to update your system."

		printTitle "The End"
		echo $(date)
		echo "$FRAME"
		exit
fi

INSTALL_DIR_PARENT="/usr/local/turbolab.it/"
ZZSCRIPT_DIRS=($(find $INSTALL_DIR_PARENT -maxdepth 1 -type d))

for ZZSCRIPT_DIR in "${ZZSCRIPT_DIRS[@]}"; do

	printTitle "Update ${ZZSCRIPT_DIR}..."
	git -C "$ZZSCRIPT_DIR" pull
done


if [ "$SWITCH_PROMPT_TO_NORMAL" = "1" ]; then

	printTitle "Switching to the 'normal' release channel (if 'never' or 'lts')"
	sed -i -E 's/Prompt=(never|lts)/Prompt=normal/g' "/etc/update-manager/release-upgrades"
	
else

	printTitle "Channel switching is disabled: using pre-existing setting"
	
fi


printTitle "Cleanup local cache"
apt-get clean

printTitle "Update available packages informations"
apt-get update

printTitle "UPGRADE PACKAGES"
apt-get dist-upgrade -y

if [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "1" ]; then

	printTitle "Silently upgrade to a new release, if any"
	do-release-upgrade -f DistUpgradeViewNonInteractive
	
elif [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "0" ]; then

	printTitle "Interactively upgrade to a new release, if any"
	do-release-upgrade
	
else

	printTitle "Upgrade to a new release skipped (disabled in config)"
	
fi

if [ "$COMPOSER_UPGRADE" = "1" ]; then

	printTitle "Self-updating Composer"
	
	if ! [ -x "$(command -v composer)" ]; then
		echo "Composer is not installed"
	else
		composer self-update
	fi
fi

if [ "$SYMFONY_UPGRADE" = "1" ]; then

	printTitle "Self-updating Symfony"
	
	if ! [ -x "$(command -v symfony)" ]; then
		echo "Symfony is not installed"
	else
		symfony self:update --yes
	fi
fi



printTitle "Packages cleanup (autoremove unused packages)"
apt-get autoremove -y

printTitle "Current version"
lsb_release -d

printTitle "Time took"
echo "$((($(date +%s)-$TIME_START)/60)) min."

if [ "$REBOOT" = "1" ]; then
	printTitle "Rebooting"
	
	while [ $REBOOT_TIMEOUT -gt 0 ]; do
	   echo -ne "$REBOOT_TIMEOUT\033[0K\r"
	   sleep 1
	   : $((REBOOT_TIMEOUT--))
	done
	reboot
fi

printTitle "The End"
echo $(date)
echo "$FRAME"
