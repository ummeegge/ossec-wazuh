#!/bin/bash -

#
# OSSEC + Wazuh installerscript for IPFire platform which includes:
# - OSSEC server and agent installation fo 32 and 64 bit versions.
# - Wazuh server and agent installation for 32 and 64 bit versions.
# - OSSEC webinterface (DEPRECATED with Core 118) .
# - OSSEC/Wazuh e-mail alert setup assistent which provides GPG encryption and TLS transport layer and SMTP auth.
#
# $author: ummeegge at web de ; $date: 11.02.2018
#################################################################################################################
#

## Download addresses for installer scripts
# OSSEC in- uninstaller
OINSTALLER="ossec_installer.sh";
OINSTALLERADDRESS="https://raw.githubusercontent.com/ummeegge/ossec-wazuh/master/ossec/${OINSTALLER}";

# Wazuh in- uninstaller
WAINSTALLER="wazuh-installer.sh";
WAINSTALLERADDRESS="https://raw.githubusercontent.com/ummeegge/ossec-wazuh/master/wazuh/${WAINSTALLER}";

# Email alert setup script
EINSTALLER="ossec_email_setup.sh";
EINSTALLERADDRESS="https://raw.githubusercontent.com/ummeegge/ossec-wazuh/master/ossec/${EINSTALLER}";

## Formatting and Colors
COLUMNS="$(tput cols)";
R=$(tput setaf 1);
O=$(tput setaf 3);
B=$(tput setaf 6);
b=$(tput bold);
N=$(tput sgr0);
seperator(){
	echo -e "${O}$(printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -;)${N}"
}
WELCOME="${B}- Welcome to OSSEC + Wazuh administration -";
WELCOMEA="In- and uninstallation for OSSEC + Wazuh and email alert setup assistent${N}";
OSSEC="To install or uninstall OSSEC press                 ${B}${b}'o'${N} and [ENTER]";
WAZUH="To install or uninstall Wazuh press                 ${B}${b}'w'${N} and [ENTER]"
ESETUP="To manage OSSEC + Wazuh email alert press           ${B}${b}'e'${N} and [ENTER]";
QUIT="If you want to quit this installation press          ${B}${b}'q'${N} and [ENTER]";


# Installer Menu
while true
do
	# Choose installation
	clear;
	echo ${N}
	seperator;
	printf "%*s\n" $(((${#WELCOME}+COLUMNS)/2)) "${WELCOME}";
	printf "%*s\n" $(((${#WELCOMEA}+COLUMNS)/2)) "${WELCOMEA}";
	seperator;
	echo;
	printf "%*s\n" $(((${#OSSEC}+COLUMNS)/2)) "${OSSEC}";
	printf "%*s\n" $(((${#WAZUH}+COLUMNS)/2)) "${WAZUH}";
	printf "%*s\n" $(((${#ESETUP}+COLUMNS)/2)) "${ESETUP}";
	echo;
	seperator;
	printf "%*s\n" $(((${#QUIT}+COLUMNS)/2)) "${QUIT}";
	seperator;
	echo;
	read choice
	clear;
	# Install Server
	case $choice in
		o*|O*)
			clear;
			cd /tmp || exit 1;
			# Check if package is already presant otherwise download it
			if [ ! -e "${OINSTALLER}" ]; then
				echo;
				curl -O ${OINSTALLERADDRESS};
			fi
			chmod +x ${OINSTALLER};
			./${OINSTALLER};
		;;

		w*|W*)
			clear;
			cd /tmp || exit 1;
			# Check if package is already presant otherwise download it
			if [ ! -e "${WAINSTALLER}" ]; then
				echo;
				curl -O ${WAINSTALLERADDRESS};
			fi
			chmod +x ${WAINSTALLER};
			./${WAINSTALLER};
		;;

		e*|E*)
			clear;
			cd /tmp || exit 1;
			# Check if package is already presant otherwise download it
			if [ ! -e "${EINSTALLER}" ]; then
				echo;
				curl -O ${EINSTALLERADDRESS};
			fi
			chmod +x ${EINSTALLER};
			./${EINSTALLER};
		;;

		q*|Q*)
			clear;
			echo "Will quit. Goodbye";
			exit 0;
		;;

		*)
			echo;
			echo "${R}${b}This option does not exist... ${N}";
			echo;
		;;
	esac
done


# EOF
