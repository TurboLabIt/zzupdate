#!/usr/bin/env bash
curl -s https://raw.githubusercontent.com/TurboLabIt/zzupdate/master/setup.sh | sudo bash
sudo -u root -H bash "/usr/local/turbolab.it/zzupdate/zzupdate_run.sh" "$@"
