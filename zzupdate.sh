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


printTitle "Cleanup local cache"
apt-get clean

printTitle "Update package list"
apt-get update

printTitle "UPGRADE PACKAGES"
apt-get dist-upgrade -y

if [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "1" ]; then

    printTitle "Silently upgrade to a new release, if any"
	do-release-upgrade -f DistUpgradeViewNonInteractive
	
if [ "$VERSION_UPGRADE" = "1" ] && [ "$VERSION_UPGRADE_SILENT" = "0" ]; then

	printTitle "Interactively upgrade to a new release, if any"
	do-release-upgrade -f
	
else

	printTitle "Upgrade to a new release skipped (disabled in config)"
	
fi

printTitle "Remove unused packages"
apt-get autoremove -y

printTitle "Current version"
lsb_release –d

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

