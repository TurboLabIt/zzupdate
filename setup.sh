#!/bin/bash
clear

## Script name
SCRIPT_NAME=zzupdate

## Install directory
WORKING_DIR_ORIGINAL="$(pwd)"
INSTALL_DIR_PARENT="/usr/local/turbolab.it/"
INSTALL_DIR=${INSTALL_DIR_PARENT}${SCRIPT_NAME}/

## /etc/ config directory
mkdir -p "/etc/turbolab.it/"

## Pre-requisites
apt update
apt install git -y

## Install/update
echo ""
if [ ! -d "$INSTALL_DIR" ]; then
	echo "Installing..."
	echo "-------------"
	mkdir -p "$INSTALL_DIR_PARENT"
	cd "$INSTALL_DIR_PARENT"
	git clone https://github.com/TurboLabIt/${SCRIPT_NAME}.git
else
	echo "Updating..."
	echo "----------"
fi

## Fetch & pull new code
cd "$INSTALL_DIR"
git pull

## Symlink (globally-available command)
if [ ! -e "/usr/bin/${SCRIPT_NAME}" ]; then
	ln -s ${INSTALL_DIR}${SCRIPT_NAME}.sh /usr/bin/${SCRIPT_NAME}
fi

## Restore working directory
cd $WORKING_DIR_ORIGINAL

