#!/bin/bash -

#
# This installer will integrate OSSEC webinterface
#
# ummeegge 15.04.2017
####################################################################################################
# A vhost config for OSSEC will be installed so OSSEC listens to port 9955 TCP where you need https.
# An error and access log will be created under /var/log/httpd for potential overviews over the WI.
# A logrotate will also be integrated so the log area shouldn´t be oversized.
# /etc/php.ini becomes also an european time zone, to prevent high error amount in the error log.
#


URL="https://github.com/ossec/ossec-wui/archive/0.9.tar.gz";
PACK="0.9.tar.gz";
VERSION="ossec-wui-0.9";

# SHA256 sum
WUISUM="322e3d8042f94ee97c133882e5e38779c9f83c6617c03c56130a0d79fa384873";

# install paths
INSDIR="/srv/web/ossec";
VHOST="/etc/httpd/conf/vhosts.d";
LOG="/var/log/httpd/";
ROTATE="/etc/logrotate.d/ossec";

# Formatting and Colors
COLUMNS="$(tput cols)";
R=$(tput setaf 1);
G=$(tput setaf 2);
B=$(tput setaf 6);
b=$(tput bold);
N=$(tput sgr0);
seperator(){ printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -; };
# Text
CONFIG="OSSEC UI configuration section - The following points needs to be done";

# Installer Menu
while true
do

    # Choose installation
    echo "${N}";
    clear;
    echo "+----------------------------------------------------------------------+          ";
    echo "|             Welcome to OSSEC WI on IPFire installation               |          ";
    echo "|   This script includes an in- and unstaller of OSSECs webinterface   |          ";
    echo "+----------------------------------------------------------------------+          ";
    echo;
    echo -e "       If you want to install OSSECs WI press     ${B}${b}'i'${N} and [ENTER] ";
    echo -e "       If you want to uninstall OSSEC WI press    ${B}${b}'u'${N} and [ENTER] ";
    echo;
    echo    "+----------------------------------------------------------------------+";
    echo -e "      If you want to quit this installation press ${B}${b}'q'${N} and [ENTER] ";
    echo    "+----------------------------------------------------------------------+";
    echo;
    read choice
    clear;

    case ${choice} in
        i*|I*)

            # Check if PHP is available
            if [ ! -e "/usr/bin/php" ]; then
                echo
                echo -e "${R}There is no PHP available on this platform so OSSECs WI won´t work. Need to quit... ${N}"
                echo
                sleep 3
                exit 1
            fi
            # Start installer
            # Check if OSSEC is installed
            clear;
            read -p "To install OSSECs webinterface now press [ENTER] , to quit use [CTRL-c]... ";
            if [[ ! -d /var/ossec ]]; then
                clear;
                echo "Please install OSSEC first... ";
                echo;
                exit 1;
            elif [[ -d /srv/web/ossec ]]; then
                echo;
                echo "OSSECs UI is alread installed, please uninstall it first.";
                sleep 3;
                echo;
                exit 1;
            fi

            # Check if UI package is presant otherwise download it
            cd /tmp || exit 1;
            if [[ ! -e ${PACK} ]]; then
                clear;
                echo;
                wget --input-file=${VERSION}.tar.gz ${URL};
                echo;
            fi
   
            # check SHA256 sum
            CHECK=$(sha256sum ${PACK} | awk '{print $1}');
            if [[ "${CHECK}" = "${WUISUM}" ]]; then
                echo;
                echo -e "SHA2 sum should be ${G}${b}${WUISUM}${N}";
                echo -e "SHA2 sum is        ${G}${b}${CHECK}${N} and is correct… ";
                echo;
                echo "will go to further processing :-) ...";
                echo;
                sleep 3;
            else
                echo;
                echo -e "SHA2 sum should be ${R}${b}${WUISUM}${N}";
                echo -e "SHA2 sum is        ${R}${b}${CHECK}${N} and is not correct… ";
                echo;
                echo -e "${R}${b}Shit happens :-( the SHA2 sum is incorrect, please report this here";
                echo "--> https://forum.ipfire.org/viewtopic.php?f=4&t=4924${N}";
                echo;
                exit 1;
            fi

            # Unpack, move to install dir and rename it
            tar xvfz ${PACK};
            mv ${VERSION} /srv/web/ossec;
            cd /srv/web/ossec;
            # Set username and password
            clear;
            echo;
            seperator;
            printf "%*s\n" $(((${#CONFIG}+COLUMNS)/2)) "${CONFIG}";
            seperator;
            echo;
            echo "- You will need in the following process to setup your ${B}username${N} and ${B}password${N} .";
            echo;
            echo "- The webserver username needs to be set which regularily should be ${R}${b}'nobody'${N} .";
            echo;
            echo "- Your OSSEC install directory is regularily ${B}${b}/var/ossec${N}, so you should use OSSECs installation path .";
            echo;
            seperator;
            read -p "To start configuration press [ENTER]";
            echo
            ./setup.sh;
            # Repair permissions for tmp/
            chmod 770 tmp/
            chown -R nobody:nobody ${INSDIR};
            cd /tmp;
            # Need to add PHP time zone
            sed -i 's|;date.timezone =|date.timezone = "Europe/Berlin"|' /etc/php.ini
            echo;
            echo "Added 'Europe timezone' in ${B}${b}/etc/php.ini${N}. To change this please make this manually... ";
            echo;
            sleep 5;
            # vhost configuration
            cat > ${VHOST}/ossec.conf << "EOF"
Listen 9955
<VirtualHost *:9955>
    SSLEngine on
    SSLProtocol all -SSLv2
    SSLCipherSuite ALL:!ADH:!EXPORT56:!eNULL:!SSLv2:!RC4+RSA:+HIGH:+MEDIUM
    SSLCertificateFile /etc/httpd/server.crt
    SSLCertificateKeyFile /etc/httpd/server.key

        DocumentRoot "/srv/web/ossec"
        Include /etc/httpd/conf/conf.d/php*.conf
        ErrorLog "/var/log/httpd/ossec-wui-error.log"
        CustomLog "/var/log/httpd/ossec-wui-access.log" combined

<Directory "/srv/web/ossec">
        Options +FollowSymlinks
        Require ip {ENTER HERE YOUR NETWORK OR CLIENTIP WITHOUT BRACES}
</Directory>

    <Location />

        Require ip {ENTER HERE YOUR NETWORK OR CLIENTIP WITHOUT BRACES}

    </Location>

</VirtualHost>
EOF

            # Enter IP or subnet with access to the UI
            seperator;
            echo;
            echo "- ${B}${b}You need now to enter a host IP or a whole subnet which is marked as--> ${N} ";
            echo "${R}${b}'{ENTER HERE YOUR NETWORK OR CLIENTIP WITHOUT BRACES}'${N} ${B}(CIDR notation is possible)${N} ";
            echo;
            echo "- Use both 'Allow from... ' lines in this config file and modify it to your environment.";
            echo;
            echo "- Since you will use now vim to edit ossec vhost config, type 'i' to edit it, hit '[ESC]' to leave edit mode.";
            echo "To write and save the file after editing, you can use ':x! [ENTER]' .";
            echo;
            seperator;
            read -p "To start with editing press [ENTER] ";
            vim ${VHOST}/ossec.conf;
            # Add now logrotate entry for error and access log
            cat >> ${ROTATE} << "EOF"

# OSSEC error and access log
/var/log/httpd/ossec-*.log {
    weekly
    rotate 4
    copytruncate
    compress
    delaycompress
    notifempty
    create 0660 root ossec
    missingok
}

EOF
            # Set permission for logrotate
            chown root:ossec ${ROTATE};
            chmod 0644 ${ROTATE};
            echo;
            clear;
            echo "Will restart now Apache... ";
            /etc/init.d/apache restart;
            sleep 3;
       
            echo;
            echo "Installation is finish now, ";
            echo;
            echo "You can access OSSECs UI with ${B}${b}https://{IP_or_hostname-IPFire}:${R}${b}9955${N}";
            echo;
            echo "Happy testing. Goodbye";
            echo;
            exit 0;
        ;;

        # Uninstaller
        u*|U*)
            clear;
            read -p "To install OSSECs webinterface now press [ENTER] , to quit use [CTRL-c]... ";
            if [[ ! -d /srv/web/ossec ]]; then
                echo;
                echo "${R}${b}OSSECs webinterface is not installed${N}, nothing to be done.";
                echo;
                sleep 5;
            else
                rm -rfv \
                ${INSDIR} \
                ${VHOST}/ossec.conf \
                ${ROTATE} \
                /var/log/httpd/ossec-wui-error.log \
                /var/log/httpd/ossec-wui-access.log;
                sed -i 's/ossec:x:1001:nobody/ossec:x:1001:/' /etc/group;
                sed -i 's|date.timezone = "Europe/Berlin"|;date.timezone =|' /etc/php.ini
                mv ${ROTATE}.bckOrig ${ROTATE};
                echo;
                echo "Restart Apache now... ";
                echo;
                /etc/init.d/apache restart;
                echo;       
                echo "The uninstaller of OSSECs UI is finished now thanks for testing... ";
                echo;
                echo "Goodbye";
                echo;
                exit 0;
                echo;
            fi
        ;;
   
        q*|Q*)
            exit 0;
        ;;
   
        *)
            echo;
            echo "${R}${b}This option does not exist... ${N}";
            sleep 3;
            echo;
        ;;

    esac


done

## EOF
