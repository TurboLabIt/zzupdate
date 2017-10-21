# zzupdate
A simple command to fully update an Ubuntu PC/server via apt. Mostly hand-off and unattended. The provided `setup.sh` auto-installs/updates the code and makes the script available as a new, simple shell command (`zzupdate`). The project aims to deliver a fully configfile-driven script: no code editing should be necessary!

**Parli italiano?** » Leggi: [Aggiornare Ubuntu con un solo comando: zzupdate (pacchetti e sistema operativo)](https://turbolab.it/linux-27/aggiornare-ubuntu-solo-comando-zzupdate-pacchetti-sistema-operativo-1383)

# Install
Just execute:

`curl -s https://raw.githubusercontent.com/TurboLabIt/zzupdate/master/setup.sh | sudo sh`

Now copy the provided sample configuration file (`zzupdate.default.conf`) to your own `zzupdate.conf` and set your preference:

`sudo cp /usr/local/turbolab.it/zzupdate/zzupdate.default.conf /etc/turbolab.it/zzupdate.conf && sudo nano /etc/turbolab.it/zzupdate.conf`

# Run it
It's upgrade time! Run `zzupdate` to fully update your system.

# Guides/reviews

* *Italian*: [Aggiornare Ubuntu con un solo comando: zzupdate (pacchetti e sistema operativo)](https://turbolab.it/linux-27/aggiornare-ubuntu-solo-comando-zzupdate-pacchetti-sistema-operativo-1383)
* *English*: [How To Upgrade Ubuntu With A Single Command](https://www.ostechnix.com/upgrade-ubuntu-single-command/)
* *English*: [Reddit on /r/Ubuntu](https://www.reddit.com/r/Ubuntu/comments/6zn8fz/zzupdate_lets_you_to_upgrade_your_ubuntu/)
