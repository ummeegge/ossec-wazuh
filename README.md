# Ossec + Wazuh installer for IPFire environment

Scripts should deliver a possibility to integrate 
Ossec --> http://ossec.github.io/ OR
Wazuh --> https://wazuh.com/ into 
IPFire --> https://github.com/ipfire environment. The scripts needs a working IPFire environment.

Repo contains currently:

- An administration script 'ossec-wazuh-admin.sh':
	- Which handles all following scripts.

- An in- uninstaller script for OSSEC 'ossec_installer.sh' which can be used to install:

	- Agent, server and standalone operating modes.
	- Download address for already compiled ossec binary will be used by the script ( SHA256 sum from sources will be checked for integrity).
	- Serves initscript and adds also symlinks for the runlevels and meta files for de- or activation of OSSEC over IPFire webuserinterface.
	- Includes a minimal configuration section to add agents <--> server (vice a vers).
	- Installer and uninstaller logs can be found under /tmp.

- An in- uninstaller script for Wazuh 'wazuh-installer.sh' which can be used to install:

	- Agent, server and standalone operating modes.
	- Download address for already compiled wazuh binary will be used by the script ( SHA256 sum from sources will be checked for integrity).
	- Serves initscript and adds also symlinks for the runlevels and meta files for de- or activation of Wazuh over IPFire webuserinterface.
	- Includes a minimal configuration section to add agents <--> server (vice a vers).
	- Installer and uninstaller logs can be found under /tmp.

- A send an e-mail alert script 'ossec_email_alert.sh' which can also be used for Wazuh and does the following:

	- Uses PIPE for own alert logs.
	- Serves the possibility to set defined alert levels (default 6-15 which can be changed with manual intervention .
	- Uses sendEMail which is available via IPfires Pakfire package manager.
	- Uses TLS-auth and SMTP-auth for regular e-mail provider.
	- Uses GPG publickey for email en- and decryption.

- An setup assistent for OSSEC and Wazuh 'ossec_email_setup.sh' for email alerts which uses the script above.

	- Works with an SMTP client called sendEmail, so SMTP authentication and TLS transport layer should be presant.
	- Encryption will be made via GPG.
	- Setup will add the above mentioned email alert script --> https://github.com/ummeegge/ossec-ipfire/blob/master/ossec_email_alert.sh
	- Setup adds via PIPE an custom alert log and searches there for alerts from 6-16 per default and 
	- Setup will leads through email configuration, to GPG pubkey integration and serves a testmail function.
	- Uninstaller is included.


