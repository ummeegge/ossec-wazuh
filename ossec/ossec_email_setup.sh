#!/bin/bash -

#
# Ossec email setup assistent.
# Works with an SMTP client called sendEmail, so SMTP auth and TLS transport layer should be presant.
# Encryption will be made via GPG.
# Setup will add a script --> https://github.com/ummeegge/ossec-ipfire/blob/master/ossec_email_alert.sh
# Setup adds via PIPE an custom alert log and searches there for alerts from 6-16 per default and 
# copies a log portion to an email which will encrypted.
# Setup will leads through email configuration, to GPG pubkey integration and serves a testmail function.
# Uninstaller is included.
#
# $author: ummeegge ipfire org ; $date 17.05.2017-16:31:25 ; $version: 0.1
#########################################################################################################
#


# Paths and dirs
OSSEC="/var/ossec";
ALERTSCRIPT="/etc/fcron.minutely/ossec_mailalert.sh";
MAIL="/usr/local/bin/sendEmail";
RC="/etc/sysconfig/rc.local";
TESTMAIL="/tmp/testmail";
TESTFILE="/tmp/testfile";
TESTFILECRYPTED="/tmp/testfile.asc";
MAILDIR="${OSSEC}/custom-mail";
GPGINFO="${MAILDIR}/gpg_pubkey_info";
MAILLOG="${MAILDIR}/testmail.log";
CUSTOMALERTLOG="${OSSEC}/logs/alerts/custom_dated_alert.log";
OSSECALERTLOG="${OSSEC}/logs/alerts/alerts.log"

# Formatting and Colors
COLUMNS="$(tput cols)";
R=$(tput setaf 1);
G=$(tput setaf 2);
B=$(tput setaf 6);
b=$(tput bold);
N=$(tput sgr0);
seperator(){ printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -; }
WELCOME="- Welcome to OSSEC email alert setup assistent -";
INTRO="This installation includes: GPG encryption, SMTP authentication, and email transfer via TLS";
GPG="GPG public key import";
CONFIG="Email setup for OSSEC server or local installation";
ACTIVATE="DE- or ACTIVATE OSSEC email alert section";
DELETE="Delete OSSEC alert mail installation";
ENVCHECK="Check for dependencies";

# Import GPG key
gpgimport_funct(){
	if [ ! -e "${GPGINFO}" ]; then mkdir "${MAILDIR}" && touch "${GPGINFO}"; fi
	read -e -p "Enter path to your GPG public key, you can use tab for completion: " file
	if [ -z "${file}" ]; then
		clear;
		echo
		echo "${R}${b}You need to enter a path to your GPG public key... ${N}";
		echo;
		sleep 3;
		shift;
	fi
	if grep -q "END PGP PUBLIC KEY BLOCK" ${file}; then
		cat ${file} | gpg > "${GPGINFO}";
		clear;
		ID=$(awk '/pub/ { print $2 }' ${GPGINFO} | cut -d'/' -f2) >/dev/null 2>&1;
		if gpg --list-keys | grep -q "${ID}"; then
			echo;
			echo "${R}${b}Key is already imported. Nothing to be done";
			echo;
			sleep 3
			shift;
		fi
		gpg --import ${file};
		echo;
		echo "${R}${b}For full automated GPG encryption you NEED to set now the trust level to ${B}${b}'5'${N} .";
		echo
		echo "To finish the GPG dialog after setting the trust level, use 'quit' and [ENTER]";
		read -p "To set the trust level now press [ENTER]";
		echo;
		gpg --edit-key ${ID} trust;
		echo;
		echo -e "${B}${b}GPG key integration will be listed:${N}";
		echo;
		gpg --list-keys;
		read -p "To go back to menu press [ENTER]";
		shift;
	else
		echo;
		echo -e "${R}${b}This is no valid GPG public key !!!${N}";
		echo;
		sleep 3;
		shift;
	fi
}

# Check for sendEMail installation
bincheck_funct(){
	# Check for OSSEC
	if [ ! -e "${OSSEC}" ]; then
		echo;
		echo "${R}${b}Can´t find OSSEC installation, you need to install it first. Need to quit";
		echo;
		exit 1;
	fi
	if grep -q 'client' ${OSSEC}/etc/ossec.conf; then
		echo;
		echo "${R}${b}This is a OSSEC agent installation which do not handle emails.${N}"
		echo "Only local and server installation are valid for this. Need to quit.${N}"
		echo;
		exit 1;
	fi
	# Check for sendEmail
	if [ ! -e "${MAIL}" ]; then
		echo "${R}sendEmail is not installed on your system but is needed for this installation.${N}";
		printf "%b" "To install sendEmail use ${R}${b}'Y'-[ENTER]${N} to leave this installation use ${R}${b}'N'-[ENTER]${N}\n";
		printf "To quit use ${R}${b}'[CTRL]-c'${N}"
		echo;
		read what;
		case ${what} in
			y*|Y*)
				pakfire install sendEmail;
			;;

			n*|N*)
				printf "OK will quit. Goodbye... ";
				sleep 3;
				exit 0;
			;;
		esac
	fi
	# Check for maildir
	if [ ! -e "${MAILDIR}" ]; then
		mkdir ${MAILDIR};
	fi
}

pastescript_funct(){
	cat > "${ALERTSCRIPT}" << "EOF"
#!/bin/bash -

#
# Script searches for OSSEC alerts above a defined level (default from 6-16).
# If something appears, an encrypted alert mail will be send.
#
# $author: ummeegge ipfire org ; $date:2016.21.03
#############################################################################
#

# Home needs to be set for GPG public key
export HOME=/root

## Locations
ALERTLOG="/var/ossec/logs/alerts/custom_dated_alert.log";
## sendEmail configuration parameter and locations
MAIL="/usr/local/bin/sendEmail";
GPG="/usr/bin/gpg";
FILE="/tmp/ossec_alert.txt";
FILECRYPTED="/tmp/ossec_alert.txt.asc";

## Check for needed dependencies
# sendEmail check
if [[ ! -e "${MAIL}" ]]; then
   echo -e "Can´t find needed sendEmail binary. Please install it via Pakfire first.";
   exit 1;
fi

# ----- Please configure here your specific Email data -----
MAILPASS="ExtremeSecurePassword";
MAILADDRESS="example@example.de";
MAILNAME="example";
SMTPADDRESS="smtp.example.de:587";
MESSAGE="From $(date) $(hostname)";
SUBJECT="From $(date) OS alert message";
PUBKEYID="2F033721";
# ---------------------------------------------------------------------------------

# Main part
if grep -Eq '\(level [6-9]|1[0-6]\)' "${ALERTLOG}"; then
    cd /tmp || exit 1;
    cat "${ALERTLOG}" | tr -d '\000' | awk -v RS="" -v ORS="\n\n" '/\(level [6-9]|1[0-6]\)/' > "${FILE}";
    ${GPG} --encrypt -a --recipient "${PUBKEYID}" "${FILE}";
    ${MAIL} -f "${MAILADDRESS}" -t "${MAILADDRESS}" \
    -s "${SMTPADDRESS}" \
    -u "${SUBJECT}" \
    -m "${MESSAGE}" \
    -xu "${MAILNAME}" \
    -xp "${MAILPASS}" \
    -o tls=yes \
    -a "${FILECRYPTED}";
    rm -f "${FILE}"*;
    echo > "${ALERTLOG}";
    logger -t ossec: "Mailalert has been send."
else
    echo > "${ALERTLOG}";
fi

# End script

EOF
}

# Paste pipe command to rc.local
pastepipe_funct(){
	if ! grep -q '# Realtime log for Ossec' ${RC}; then
		cat >> /etc/sysconfig/rc.local << "EOF"
# Ossec realtime log for e-mail alerts begin
tail -F /var/ossec/logs/alerts/alerts.log |\
while read line; do echo "$line"; done > /var/ossec/logs/alerts/custom_dated_alert.log &
# Ossec realtime log for e-mail alerts end
EOF

fi
}

## Main part #######################################################################################
# Install preparation
clear;
echo;
if [[ ! -f "${OSSEC}" && ! -e "${MAIL}" ]]; then
	seperator;
	printf "%*s\n" $(((${#ENVCHECK}+COLUMNS)/2)) "${ENVCHECK}";
	seperator;
	echo
	bincheck_funct;
	echo "${N}";
fi
clear;
echo;
seperator;
printf "%*s\n" $(((${#WELCOME}+COLUMNS)/2)) "${WELCOME}";
seperator;
echo
echo -e "${R}${b}Check a few things before you use this script${N}: \n \
\n \
- Make your own Email account for this. The user credentials are stored in clear text on IPFire.\n \
- Produce an own GPG key in .asc format for this on your client machine which should deliver those emails. \n \
- Import the public GPG key to your IPFire machine where OSSEC is installed, preferable to /tmp . \n \
       Further infos are here --> http://wiki.ipfire.org/en/optimization/scripts/gpg/start located .";
echo;
seperator;
read -p "If you are ready press [ENTER] to start - Or use '[ctrl]-c' to quit";
echo;
# Paste email alert script to tmp if not presant if presant ask what to do
if [ -e "${ALERTSCRIPT}" ]; then
	if ! grep -q 'example' "${ALERTSCRIPT}"; then
		echo "${R}There is already a modified mail alert script installed.";
		echo "Should it be overwritten ? ${N}";
		echo;
		printf "%b" "If yes press ${R}${b}'Y'-[ENTER]${N} to use the exisiting one press ${R}${b}'N'-[ENTER]${N}\n";
		read what;
		case ${what} in
			y*|Y*)
				pastescript_funct;
				rm -rf ${MAILDIR:?}/*
			;;
			n*|N*)
				echo "OK will leave as it is";
			;;
		esac
	else
		pastescript_funct;
	fi
else
	pastescript_funct;
fi

## Setup assistens menu
while true; do
	# Check if GPG key is equivalent to key ID in script
	SCRIPTEXIST=$(if [ ! -e "${ALERTSCRIPT}" ]; then echo "${R}${b}No email alert script available"; fi);
	KEYID=$(awk -F'"' '/PUBKEYID=/ { print $2 }' ${ALERTSCRIPT});
	SCRIPTMOD=$(if grep -q 'example' ${ALERTSCRIPT}; then echo "${R}${b}Script has NOT been configured${N}"; else echo "${B}${b}Script has been modified${N}"; fi);
	GPGPRESANT=$(if ! gpg --list-keys | grep -q "${KEYID}"; then echo "${R}${b}GPG key for script is NOT integrated${N}"; else echo "${B}${b}GPG key for script is integrated${N}"; fi);
	if [ -e "${MAILLOG}" ]; then
		SENDCHECK=$(if grep -q 'Email was sent successfully!' ${MAILLOG}; then echo "${B}${b}Last test was sucessful,${N}"; else echo "${R}${b}Last test was NOT succesful,${N}"; fi);
		TLSCHECK=$(if grep -q 'The remote SMTP server supports TLS' ${MAILLOG}; then echo "${B}${b}with TLS,${N}"; else echo "${R}${b}but NO TLS,${N}"; fi);
		GPGCHECK=$(if grep -q '.asc' ${MAILLOG}; then echo "${B}${b}and CRYPTED${N}"; else echo "${R}${b}but NOT CRYPTED${N}"; fi);
	fi
	NOTEST=$(if [ ! -e "${MAILLOG}" ]; then echo "${R}${b}No testmail report available${N}"; fi);
	FUNCTION=$(if ps aux | grep -v grep | grep -q 'tail -F'; then echo "${B}${b}Process activated${N}"; else echo "${R}${b}Process not activated${N}"; fi);
	ASCRIPT=$(if [ -e "${ALERTSCRIPT}" ]; then echo "${B}${b}Script exists,"; else echo "${R}${b}No script,"; fi);
	APIPE=$(if grep -q 'ossec' ${RC}; then echo "${B}${b}PIPE exists${N}"; else echo "${R}${b}PIPE do not exists${N}"; fi);

	echo "${N}";
	clear;
	echo;
	seperator;
	printf "%*s\n" $(((${#CONFIG}+COLUMNS)/2)) "${CONFIG}";
	printf "%*s\n" $(((${#INTRO}+COLUMNS)/2)) "${INTRO}";
	seperator;
	echo;
	echo -e "       To configure your email use         ${B}${b}'c'${N} and [ENTER] - ${SCRIPTEXIST}${SCRIPTMOD}";
	echo -e "       To import GPG public key use        ${B}${b}'g'${N} and [ENTER] - ${GPGPRESANT}";
	echo -e "       To send test email use              ${B}${b}'s'${N} and [ENTER] - ${NOTEST}${SENDCHECK} ${TLSCHECK} ${GPGCHECK}";
	echo -e "       To de- or activate OSSEC mail use   ${B}${b}'f'${N} and [ENTER] - ${FUNCTION}";
	echo -e "       To delete everything use            ${B}${b}'u'${N} and [ENTER] - ${ASCRIPT} ${APIPE}";
	echo;
	seperator;
	echo -e "       To quit use                         ${B}${b}'q'${N} and [ENTER]";
	seperator;
	echo;
	echo -e "${N}";
	read -r choice
	clear;
	## Install section
	# Minimal installation
	case $choice in
		c*|C*)
			while true; do
				clear;
				seperator;
				printf "%*s\n" $(((${#CONFIG}+COLUMNS)/2)) "${CONFIG}";
				seperator;
				echo;
				# Email data
				ADDRESS=$(awk -F'"' '/MAILADDRESS=/ { print $2 }' ${ALERTSCRIPT});
				SMTP=$(awk -F'"' '/SMTPADDRESS=/ { print $2 }' ${ALERTSCRIPT});
				PASS=$(awk -F'"' '/MAILPASS=/ { print $2 }' ${ALERTSCRIPT});
				MESSAGE=$(awk -F'"' '/MESSAGE=/ { print $2 }' ${ALERTSCRIPT});
				SUBJECT=$(awk -F'"' '/SUBJECT=/ { print $2 }' ${ALERTSCRIPT});
				echo;
				echo "To change the email address use          ${B}${b}'e-[ENTER]'${N}  - Current: ${B}${b}${ADDRESS}${N}";
				echo "To change the SMTP address and port use  ${B}${b}'s-[ENTER]'${N}  - Current: ${B}${b}${SMTP}${N}";
				echo "To change the email password use         ${B}${b}'p-[ENTER]'${N}  - Current: ${B}${b}${PASS}${N}";
				echo "To change the email message use          ${B}${b}'m-[ENTER]'${N}  - Current: ${B}${b}${MESSAGE}${N}";
				echo "To change the email subject use          ${B}${b}'t-[ENTER]'${N}  - Current: ${B}${b}${SUBJECT}${N}";
				echo;
				echo "To go back to main menu use              ${B}${b}'x'${N}";
				echo;
				seperator;
				read -r change;
				case ${change} in
					p*|P*)
						printf "Enter new password e.g. '12345678;-)': \n";
						read newpass;
						sed -i "s/MAILPASS=\".*/MAILPASS=\"${newpass}\"/" ${ALERTSCRIPT};
						shift;
					;;

					e*|E*)
						printf "Enter new mail address with format e.g. 'examplename@web.de': \n";
						read newaddress;
						if echo ${newaddress} | grep -q -E -o "\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,6}\b"; then
							sed -i "s/MAILADDRESS=\".*/MAILADDRESS=\"${newaddress}\"/" ${ALERTSCRIPT};
							newname=$(echo ${newaddress} | awk -F'@' '{ print $1 }');
							sed -i "s/MAILNAME=\".*/MAILNAME=\"${newname}\"/" ${ALERTSCRIPT};
						else
							echo;
							echo "${R}${b}This is no valid email address, please enter it again... ${N}";
							echo;
							sleep 3;
						fi
						shift;
					;;

					s*|S*)
						echo "Enter new SMTP address and port (seperated by ':' e.g. smtp.example.de:587).";
						printf "Take care to choose the correct port for TLS encryption: \n";
						read smtpaddress;
						if echo ${smtpaddress} | grep -q -E "[a-zA-Z0-9]+([-.]?[a-zA-Z0-9]+)*.[a-zA-Z]+:[0-9]+$"; then
							sed -i "s/SMTPADDRESS=\".*/SMTPADDRESS=\"${smtpaddress}\"/" ${ALERTSCRIPT};
						else
							echo;
							echo "${R}${b}This is no valid SMTP address, please enter it again... ${N}";
							echo;
							sleep 3;
						fi
						shift;
					;;

					m*|M*)
						printf "Enter new email message e.g. 'From \$(date) \$(hostname)': \n";
						read newmessage;
						sed -i "s/MESSAGE=\".*/MESSAGE=\"${newmessage}\"/" ${ALERTSCRIPT};
						shift;
					;;

					t*|T*)
						printf "Enter new mail subject e.g. 'From \$(date) OS alert message': \n";
						read newsubject;
						sed -i "s/SUBJECT=\".*/SUBJECT=\"${newsubject}\"/" ${ALERTSCRIPT};
						shift;
					;;

					x*|X*)
						break;
					;;

					*)
						echo "${R}${b}This option does not exist${N}";
						sleep 2;
					;;

				esac
			done
		;;

		g*|G*)
			seperator;
			printf "%*s\n" $(((${#GPG}+COLUMNS)/2)) "${GPG}";
			seperator;
			echo;
			printf "%b" "To import the GPG public key use ${R}${b}'i'-[ENTER]${N} to leave this section use ${R}${b}'q'-[ENTER]${N}\n";
			echo;
			read what;
			case ${what} in
				i*|I*)
					gpgimport_funct;
					if [ -e "${GPGINFO}" ]; then
						# Email GPG ID data
						gpgid=$(awk '/pub/ { print $2 }' ${GPGINFO} | cut -d'/' -f2);
						sed -i "s/PUBKEYID=\".*/PUBKEYID=\"${gpgid}\"/" ${ALERTSCRIPT} >/dev/null 2>&1;
						echo;
						shift;
					else
						echo;
						echo "${R}No GPG public key infos available... ${N}";
						echo
					fi
				;;
				q*|Q*)
					shift;
				;;
				*)
					echo "This option does not exist";
				;;
			esac

		;;

		s*|S*)
			echo "This is a testmail from OSSEC email alert script from IPFire on $(hostname) from $(date)" > ${TESTFILE};
			echo "#!/bin/bash" > ${TESTMAIL};
			sed -n '/# ----- Please/,/# -----/p' ${ALERTSCRIPT} >> ${TESTMAIL};
			cat >> "${TESTMAIL}" << "EOF"
GPG="/usr/bin/gpg";
TESTFILE="/tmp/testfile";
TESTFILECRYPTED="/tmp/testfile.asc";

${GPG} --encrypt -a --recipient "${PUBKEYID}" "${TESTFILE}";
${MAIL} -vvv -f "${MAILADDRESS}" -t "${MAILADDRESS}" \
-s "${SMTPADDRESS}" \
-u "${SUBJECT}" \
-m "${MESSAGE}" \
-xu "${MAILNAME}" \
-xp "${MAILPASS}" \
-o tls=yes \
-a "${TESTFILECRYPTED}";

EOF
			chmod +x ${TESTMAIL};
			if [ ! -e "${MAILDIR}" ]; then mkdir "${MAILDIR}"; fi
			if [ ! -e "${MAILLOG}" ]; then touch "${MAILLOG}"; fi
			${TESTMAIL} 2>&1 | tee ${MAILLOG};
			echo;
			echo "Please check your mails if everything went fine... ";
			echo
			read -p "To go back to menu press [ENTER]";
			rm -f ${TESTMAIL} ${TESTFILECRYPTED} ${TESTFILE};
			echo;
		;;

		f*|F*)
			while true; do
				clear;
				seperator;
				printf "%*s\n" $(((${#ACTIVATE}+COLUMNS)/2)) "${ACTIVATE}";
				seperator;
				SCRIPTCONF=$(if grep -q 'example' ${ALERTSCRIPT}; then echo "${R}${b}Script has NOT been configured and won´t work${N}"; else echo "${B}${b}Script has been modified${N}"; fi);
				SCRIPTPERM=$(stat -c "%a %n" ${ALERTSCRIPT} | awk '{ print $1 }');
				SCRIPTACTIVE=$(if ! echo "${SCRIPTPERM}" | grep -q '755'; then echo "${R}${b}Script will NOT work, cause permissions are NOT set${N}"; else echo "${B}${b}Script is active${N}"; fi);
				PIPE=$(if ! grep -q '# Ossec realtime' ${RC}; then echo "${R}${b}PIPE command has net been set in ${RC}${N}"; else echo "${B}${b}PIPE command has been set in ${RC}${N}"; fi);
				FUNCTION=$(if ps aux | grep -v grep | grep -q 'tail -F'; then echo "${B}${b}Process activated${N}"; else echo "${R}${b}Process not activated${N}"; fi);
				# Paste email alert script to tmp if not presant if presant ask what to do
				if [ -e "${ALERTSCRIPT}" ]; then
					echo;
					echo -e "Current state: \n \
					${SCRIPTCONF} \n \
					${SCRIPTACTIVE} \n \
					${PIPE} \n \
					${FUNCTION}";
					echo;
					seperator;
					echo
					echo "To activate OSSEC mail alert use        ${B}${b}'a-[ENTER]'${N}";
					echo "To deactivate OSSEC mail alert use      ${B}${b}'d-[ENTER]'${N}";
					echo;
					echo "To go back to main menu use             ${B}${b}'x-[ENTER]'${N}";
					echo;
					seperator;
					read -r change;
					case ${change} in
						a*|A*)
							if ! grep -q 'Email was sent successfully!' ${MAILLOG} >/dev/null 2>&1; then
								echo;
								echo "Testmail has NOT be send succesfully, can not activate configuration";
								echo;
								sleep 3;
								break;
							fi
							if ! grep -q '.asc' ${MAILLOG} >/dev/null 2>&1; then
								echo;
								echo "Testmail was NOT encrypted, for your own safty configuration won´t be activated!!!";
								echo;
								sleep 3;
								break;
							fi
							if [ "$(stat -c "%a %n" /etc/fcron.minutely/ossec_mailalert.sh | awk '{ print $1 }')" != "755" ]; then
								chmod 755 ${ALERTSCRIPT};
							else
								echo;
								echo "Script permission is set";
								ls -la ${ALERTSCRIPT};
								sleep 3;
							fi
							if ! grep -q '# Ossec realtime' ${RC}; then
								pastepipe_funct;
							else
								echo;
								echo "PIPE command has already been pasted";
								sleep 3;
							fi
							if [[ "$(ps x | grep -v grep | grep 'tail -F /var/ossec/logs/alerts/alerts.log' | awk '{ print $1 }' | wc -c)" -eq 0 ]]; then
								tail -F /var/ossec/logs/alerts/alerts.log | while read line; do echo "$line"; done > /var/ossec/logs/alerts/custom_dated_alert.log &
								echo "Have executed process command. Process runs with PID:"
								echo;
								ps x | grep -v grep | grep "tail -F /var/ossec/logs/alerts/alerts.log";
								sleep 3;
							else
								echo;
								echo "Mailalert PIPE is already running.";
								sleep 3;
							fi

						;;

						d*|D*)
							if [[ "$(ps x | grep -v grep | grep 'tail -F /var/ossec/logs/alerts/alerts.log' | awk '{ print $1 }' | wc -c)" -ne 0 ]]; then
								kill -9 "$(ps x | grep -v grep | grep 'tail -F /var/ossec/logs/alerts/alerts.log' | awk '{ print $1 }')";
								echo "Have killed process";
								ps x | grep -v grep | grep "tail -F /var/ossec/logs/alerts/alerts.log";
								echo;
								sleep 3;
								sed -i '/# Ossec realtime log for e-mail alerts begin/,/# Ossec realtime log for e-mail alerts end/d' ${RC};
								echo "Have deleted PIPE command from ${RC}"
								echo
								sleep 3;
								chmod 644 ${ALERTSCRIPT};
								echo "Have reduced permissions for ${ALERTSCRIPT} so fcron should not execute it.";
								ls -la ${ALERTSCRIPT};
								sleep 5;
								echo
							else
								echo;
								echo "Mailalert PIPE is already stopped.";
								sleep 3;
							fi
						;;

						x*|X*)
							break;
						;;

						*)
							echo;
							echo "${R}${b}This option does not exist${N}";
							echo
						;;
					esac
				fi
			done
		;;


		u*|U*)
			seperator;
			printf "%*s\n" $(((${#DELETE}+COLUMNS)/2)) "${DELETE}";
			seperator;
			echo;
			if [ ! -e "${ALERTSCRIPT}" ]; then
				echo;
				echo "${R}${b}No installation found, nothing to be done";
				echo;
			else
				printf "%b" "To delete OSSEC alert mail installation use ${R}${b}'D'-[ENTER]${N} to go back to main menu use ${R}${b}'B'-[ENTER]${N}\n";
				echo;
				read what;
				case ${what} in
					d*|D*)
						if [[ "$(ps x | grep -v grep | grep 'tail -F /var/ossec/logs/alerts/alerts.log' | awk '{ print $1 }' | wc -c)" -ne 0 ]]; then
							kill -9 "$(ps x | grep -v grep | grep 'tail -F /var/ossec/logs/alerts/alerts.log' | awk '{ print $1 }')";
						fi
						if [ -e "${GPGINFO}" ]; then
							gpgid=$(awk '/pub/ { print $2 }' ${GPGINFO} | cut -d'/' -f2);
							gpg --delete-key ${gpgid};
						fi
						sed -i '/# Ossec realtime log for e-mail alerts begin/,/# Ossec realtime log for e-mail alerts end/d' ${RC};
						rm -rfv ${ALERTSCRIPT} ${MAILDIR} ${CUSTOMALERTLOG};
						echo;
						echo "Have deleted installation. Goodbye.";
						echo
						exit 0;
					;;

					b*|B*)
						shift;
					;;
				esac
			fi
		;;
			

		q*|Q*)
			echo "Will quit. Goodbye... ";
			exit 0;
		;;

		*)
			clear;
			echo "Sorry this option do not exist... ";
			sleep 3;
		;;

	esac
done

# EOF
