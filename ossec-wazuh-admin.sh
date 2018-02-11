#!/bin/bash -

#
# OSSEC installerscript on IPFire platform for:
# - OSSEC server and agent installation fo 32 and 64 bit versions.
# - OSSEC webinterface.
# - OSSEC e-mail alert setup assistent which provides GPG encryption and TLS transport layer and SMTP auth.
#
# $author: ummeegge at web de ; $date: 07.06.2017
###########################################################################################################
#

# Download addresses for installer scripts
OINSTALLERADDRESS="https://raw.githubusercontent.com/ummeegge/ossec-ipfire/master/ossec_installer.sh";
OINSTALLER="ossec_installer.sh";
WINSTALLERADDRESS="https://raw.githubusercontent.com/ummeegge/ossec-ipfire/master/ossec_wi_installer.sh";
WINSTALLER="ossec_wi_installer.sh";
EINSTALLERADDRESS="https://raw.githubusercontent.com/ummeegge/ossec-ipfire/master/ossec_email_setup.sh";
EINSTALLER="ossec_email_setup.sh";

# Formatting and Colors
COLUMNS="$(tput cols)";
R=$(tput setaf 1);
G=$(tput setaf 2);
O=$(tput setaf 3);
C=$(tput setaf 4);
B=$(tput setaf 6);
b=$(tput bold);
N=$(tput sgr0);
seperator(){
	echo -e "${O}$(printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -;)${N}"
}
WELCOME="- Welcome to OSSEC administration -";
WELCOMEA="In- and uninstallation for OSSEC, OSSECs WI and and email alert setup assistent";
OSSEC="To install or uninstall OSSEC press                 ${B}${b}'o'${N} and [ENTER]";
WINTERFACE="To install or uninstall OSSECs webinterface press   ${B}${b}'w'${N} and [ENTER]";
ESETUP="To activate or deactivate OSSECs email alert press  ${B}${b}'e'${N} and [ENTER]";
QUIT="If you want to quit this installation press         ${B}${b}'q'${N} and [ENTER]";


# Installer Menu
while true
do
	# Choose installation
	clear;
	echo ${N}
	seperator;
	printf "%*s\n" $(((${#WELCOME}+$COLUMNS)/2)) "${WELCOME}";
	printf "%*s\n" $(((${#WELCOMEA}+$COLUMNS)/2)) "${WELCOMEA}";
	seperator;
	echo;
	printf "%*s\n" $(((${#OSSEC}+$COLUMNS)/2)) "${OSSEC}";
	printf "%*s\n" $(((${#WINTERFACE}+$COLUMNS)/2)) "${WINTERFACE}";
	printf "%*s\n" $(((${#ESETUP}+$COLUMNS)/2)) "${ESETUP}";
	echo;
	seperator;
	printf "%*s\n" $(((${#QUIT}+$COLUMNS)/2)) "${QUIT}";
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
			if [[ ! -e "${OINSTALLER}" ]]; then
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
			if [[ ! -e "${WINSTALLER}" ]]; then
				echo;
				curl -O ${WINSTALLERADDRESS};
			fi
			chmod +x ${WINSTALLER};
			./${WINSTALLER};
		;;

		e*|E*)
			clear;
			cd /tmp || exit 1;
			# Check if package is already presant otherwise download it
			if [[ ! -e "${EINSTALLER}" ]]; then
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
