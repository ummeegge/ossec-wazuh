#!/bin/bash -

#
# Installerscript for OSSEC on IPFire.
# This installer includes in- or uninstallation for an OSSEC agent or master.
# The OSSEC packages was build by documentation instructions -->
# http://ossec-docs.readthedocs.org/en/latest/manual/installation/installation-binary.html
# but with modification in install.sh for the install directory which is fixed to /var/ossec .
#
# ummeegge 11.01.2016   ummeegge[at]ipfire.org
#################################################################################################
# Installer includes also a minimal configuration option for server and agent.
#

# Packages
VER="2.8.3";
OSSEC="/var/ossec";
AGENTA="ossec-binary-${VER}_agent_32bit.tgz";
SERVERA="ossec-binary-${VER}_server_32bit.tgz";
AGENTB="ossec-binary-${VER}_agent_64bit.tgz";
SERVERB="ossec-binary-${VER}_server_64bit.tgz";
INSTDIR="/tmp/ossec-hids-${VER}*";
BIN="ossec";
ALERTSCRIPT="/etc/fcron.minutely/ossec_mailalert.sh";
CUSTOMALERTLOG="${OSSEC}/logs/alerts/custom_dated_alert.log";
RC="/etc/sysconfig/rc.local";

# Download URL
URL="https://people.ipfire.org/~ummeegge/Ossec_for_IPFire/";

# SHA256 sums
SERVERSUMA="67030a6901d3089c8b674d80360be9d023f9be01711c6b0e0142bad81290fe37";
AGENTSUMA="102c5313db060f5ffdb649913e8c2fe020dd946a9edca94457ff5d9052836a87";
SERVERSUMB="92df72f9076b64033a9ab6055ace9167680c106c534b704eb566b13cc3a38f79";
AGENTSUMB="7a2296902f034e26df223983f4fe8763be538340896c4bf283c94e1272859a12";

# Platform check
TYPE=$(uname -m | tail -c 3);


# Formatting and Colors
COLUMNS="$(tput cols)";
R=$(tput setaf 1);
G=$(tput setaf 2);
B=$(tput setaf 6);
b=$(tput bold);
N=$(tput sgr0);
seperator(){ printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -; };
# Text
WELCOME="-- Welcome to OSSEC on IPFire installation --";
WELCOME1="- This script includes an in- and unstaller of OSSECs server, agent and local -";


# Check for existing symlinks delete them if presant and create new one
symlinkadd_funct() {
    # Possible runlevel ranges
    SO="[8-9][0-9]";
    SA="[3-8][0-9]";
    RE="[8-9][0-9]";
    # Search free runlevel
    STOP=$(ls /etc/rc.d/rc0.d/ | sed -e 's/[^0-9]//g' | awk '$1!=p+1{print p+1" "$1-1}{p=$1}' | sed -e '1d' | tr ' ' '\n' | grep -E "${SO}" | head -1);
    START=$(ls /etc/rc.d/rc3.d/ | sed -e 's/[^0-9]//g' | awk '$1!=p+1{print p+1" "$1-1}{p=$1}' | sed -e '1d' | tr ' ' '\n' | grep -E "${SA}" | head -1);
    REBOOT=$(ls /etc/rc.d/rc6.d/ | sed -e 's/[^0-9]//g' | awk '$1!=p+1{print p+1" "$1-1}{p=$1}' | sed -e '1d' | tr ' ' '\n' | grep -E "${RE}" | head -1);
    ## Add symlinks
    ln -s ../init.d/${BIN} /etc/rc.d/rc0.d/K${STOP}${BIN};
    ln -s ../init.d/${BIN} /etc/rc.d/rc3.d/S${START}${BIN};
    ln -s ../init.d/${BIN} /etc/rc.d/rc6.d/K${REBOOT}${BIN};
}

symlinkdel_funct(){
    ls /etc/rc.d/rc?.d | grep 'ossec' > /dev/null 2>&1
    if [ "$?" = "0" ]; then
        rm -rfv /etc/rc.d/rc?.d/*ossec*;
    fi
}

# Installer Menu
while true
do

    # Choose installation
    clear;
    echo ${N}
    seperator;
    printf "%*s\n" $(((${#WELCOME}+COLUMNS)/2)) "${WELCOME}";
    printf "%*s\n" $(((${#WELCOME1}+COLUMNS)/2)) "${WELCOME1}";
    seperator;
    echo;
    echo -e "    If you want to install OSSEC server (or standalone) press    ${B}${b}'s'${N} and [ENTER] ";
    echo -e "    If you want to install OSSEC agent press                     ${B}${b}'a'${N} and [ENTER] ";
    echo -e "    If you want to configure OSSEC press                         ${B}${b}'c'${N} and [ENTER] ";
    echo -e "    If you want to uninstall OSSEC press                         ${B}${b}'u'${N} and [ENTER] ";
    echo;
    seperator;
    echo -e "    If you want to quit this installation press                  ${B}${b}'q'${N} and [ENTER]  ";
    seperator;
    echo;
    read choice
    clear;
    # Install Server
    case $choice in
        s*|S*)
            # Check for 64 bit installation
            if [[ ${TYPE} = "64" ]]; then
                clear;
                read -p "To install the OSSEC server now press [ENTER] , to quit use [CTRL-c]... ";
                cd /tmp || exit 1;
                # Check if package is already presant otherwise download it
                if [[ ! -e "${SERVERB}" ]]; then
                    echo;
                    curl -O ${URL}/${SERVERB};
                fi
                # Check SHA256 sum
                CHECK=$(sha256sum ${SERVERB} | awk '{print $1}');
                if [[ "${CHECK}" = "${SERVERSUMB}" ]]; then
                    echo;
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m is correct… ";
                    echo "will go to further processing :-) ...";
                    echo;
                    sleep 3;
                else
                    echo;
                    echo -e "SHA2 sum should be \033[1;32m${SERVERSUMB}\033[0m";
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m and is not correct… ";
                    echo;
                    echo -e "\033[1;31mShit happens :-( the SHA2 sum is incorrect, please report this here\033[0m";
                    echo "--> https://forum.ipfire.org/viewtopic.php?f=4&t=4924";
                    echo;
                    exit 1;
                fi
                # Unpack and install package
                tar xvfz ${SERVERB};
                cd ${INSTDIR};
                echo;
                echo -e "\033[1;32mChange now to original OSSEC installer... \033[0m ";
                sleep 3;
                ./install.sh 2>&1 | tee /tmp/ossec_installer.log;
                symlinkdel_funct;
                symlinkadd_funct;
                touch /opt/pakfire/db/installed/meta-ossec;
                # CleanUP
                rm -rf \
                /tmp/ossec-hids-${VER} \
                echo;
                clear;
                echo "Please don´t forget to integrate your agent(s) into your server environment if you do not use the local version... ";
                echo;
                echo "To start OSSEC use /etc/init.d/ossec start ";
                echo;
                echo "Or use OSSECs internal bin/ with a /var/ossec/bin/ossec-control start ";
                echo;
                read -p "The script provides also minimum configuration in the menu. Press [ENTER] to proceed further... ";
            elif [[ ${TYPE} = "86" ]]; then
                # 32 bit installation
                clear;
                read -p "To install the OSSEC server now press [ENTER] , to quit use [CTRL-c]... ";
                cd /tmp || exit 1;
                # Check if package is already presant otherwise download it
                if [[ ! -e "${SERVERA}" ]]; then
                    echo;
                    curl -O ${URL}/${SERVERA};
                fi
                # Check SHA256 sum
                CHECK=$(sha256sum ${SERVERA} | awk '{print $1}');
                if [[ "${CHECK}" = "${SERVERSUMA}" ]]; then
                    echo;
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m is correct… ";
                    echo "will go to further processing :-) ...";
                    echo;
                    sleep 3;
                else
                    echo;
                    echo -e "SHA2 sum should be \033[1;32m${SERVERSUMA}\033[0m";
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m and is not correct… ";
                    echo;
                    echo -e "\033[1;31mShit happens :-( the SHA2 sum is incorrect, please report this here\033[0m";
                    echo "--> https://forum.ipfire.org/viewtopic.php?f=4&t=4924";
                    echo;
                    exit 1;
                fi
                # Unpack and install package
                tar xvfz ${SERVERA};
                cd ${INSTDIR};
                echo;
                echo -e "\033[1;32mChange now to original OSSEC installer... \033[0m ";
                sleep 3;
                ./install.sh 2>&1 | tee /tmp/ossec_installer.log;
                symlinkdel_funct;
                symlinkadd_funct;
                touch /opt/pakfire/db/installed/meta-ossec;
                # CleanUP
                rm -rf \
                /tmp/ossec-hids-${VER} \
                echo;
                clear;
                echo "Please don´t forget to integrate your agent(s) into your server environment if you do not use the local version... ";
                echo;
                echo "To start OSSEC use /etc/init.d/ossec start ";
                echo;
                echo "Or use OSSECs internal bin/ with a /var/ossec/bin/ossec-control start ";
                echo;
                read -p "The script provides also minimum configuration in the menu. Press [ENTER] to proceed further... ";
             else
                echo;
                echo "Sorry this platform is currently not supported, need to quit... ";
                echo;
            fi
        ;;
   
        a*|A*)
            # Check for 64 bit installation
             if [[ ${TYPE} = "64" ]]; then
                clear;
                read -p "To install the OSSEC agent now press [ENTER] , to quit use [CTRL-c]... ";
                cd /tmp;
                # Check if package is already presant
                if [[ ! -e "${AGENTB}" ]]; then
                    echo;
                    curl -O ${URL}/${AGENTB};
                fi
                # Check SHA256 sum
                CHECK=$(sha256sum "${AGENTB}" | awk '{print $1}');
                if [[ "${CHECK}" = "${AGENTSUMB}" ]]; then
                    echo;
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m is correct… ";
                    echo;
                    echo "will go to further processing :-) ...";
                    echo;
                    sleep 3;
                else
                    echo;
                    echo -e "SHA2 sum should be \033[1;32m${AGENTSUMB}\033[0m ";
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m and is not correct… ";
                    echo;
                    echo -e "\033[1;31mShit happens the SHA2 sum is incorrect, please report this here\033[0m";
                    echo "--> https://forum.ipfire.org/viewtopic.php?f=4&t=4924";
                    echo;
                    sleep 5;
                    exit 1;
                fi
                # Unpack and install package
                tar xvfz ${AGENTB};
                cd ${INSTDIR};
                echo;
                echo -e "\033[1;32mChange now to original OSSEC installer... \033[0m";
                sleep 3;
                ./install.sh 2>&1 | tee /tmp/installer.log;
                symlinkdel_funct;
                symlinkadd_funct;
                touch /opt/pakfire/db/installed/meta-ossec;
                # CleanUP
                rm -rf \
                /tmp/ossec-hids-${VER} \
                echo;
                clear;
                echo -e "${b}${R}Please don´t forget to configure your agent to your needs... ${N}";
                echo;
                echo -e "To start OSSEC use ${G}/etc/init.d/ossec start ${N}";
                echo;
                echo -e "Or use OSSECs internal bin/ with a ${G}/var/ossec/bin/ossec-control start ${N}";
                echo;
                read -p "The script provides also minimum configuration in the menu. Press [ENTER] to proceed further... ";
            elif [[ ${TYPE} = "86" ]]; then
                clear;
                read -p "To install the OSSEC agent now press [ENTER] , to quit use [CTRL-c]... ";
                cd /tmp  || exit 1;
                # Check if package is already presant
                if [[ ! -e "${AGENTA}" ]]; then
                    echo;
                    curl -O ${URL}/${AGENTA};
                fi
                # Check SHA256 sum
                CHECK=$(sha256sum "${AGENTA}" | awk '{print $1}');
                if [[ "${CHECK}" = "${AGENTSUMA}" ]]; then
                    echo;
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m is correct… ";
                    echo;
                    echo "will go to further processing :-) ...";
                    echo;
                    sleep 3;
                else
                    echo;
                    echo -e "SHA2 sum should be \033[1;32m${AGENTSUMA}\033[0m ";
                    echo -e "SHA2 sum is        \033[1;32m${CHECK}\033[0m and is not correct… ";
                    echo;
                    echo -e "\033[1;31mShit happens the SHA2 sum is incorrect, please report this here\033[0m";
                    echo "--> https://forum.ipfire.org/viewtopic.php?f=4&t=4924";
                    echo;
                    sleep 5;
                    exit 1;
                fi
                # Unpack and install package
                tar xvfz ${AGENTA};
                cd ${INSTDIR};
                echo;
                echo -e "\033[1;32mChange now to original OSSEC installer... \033[0m";
                sleep 3;
                ./install.sh 2>&1 | tee /tmp/installer.log;
                symlinkdel_funct;
                symlinkadd_funct;
                touch /opt/pakfire/db/installed/meta-ossec;
                # CleanUP
                rm -rf \
                /tmp/ossec-hids-${VER} \
                echo;
                clear;
                echo "Please don´t forget to configure your agent to your needs... ";
                echo;
                echo "To start OSSEC use ${G}${b}/etc/init.d/ossec start${N} ";
                echo;
                echo "Or use OSSECs internal bin/ with a ${G}${b}/var/ossec/bin/ossec-control start${N} ";
                echo;
                read -p "The script provides also minimum configuration in the menu. Press [ENTER] to proceed further... ";
            else
                echo;
                echo "Sorry this platform is currently not supported, need to quit... ";
                echo;
            fi
        ;;

        c*|C*)
            clear;
            read -p "To start minimal configuration press [ENTER] , to quit use [CTRL-c]... ";
            # Check for installation
            if [[ ! -d /var/ossec ]]; then
                echo;
                echo "OSSEC is not installed on this system, please install it first... "
                echo;
                sleep 5;
            else
                cd /var/ossec/bin;
                ./manage_agents;
                # Start OSSEC
                echo;
                read -p "If you want to start your OSSEC installation use ${R}'y'${N}-[ENTER] . To quit use ${R}"n"${N}: " what
                echo;
                case "$what" in
                    y)
                        echo "Start now OSSEC... ";
                        echo;
                        /etc/init.d/ossec restart;
                        echo;
                    ;;

                    *)
                        echo;
                        echo "Will quit goodbye... "
                        exit 1;
                    ;;
                esac
                echo "Configuration is done... ";
                echo "Please check the console output if OSSEC was startet... ";
                echo "If yes enjoy ;-)... ";
                echo "If not, come to https://forum.ipfire.org/viewtopic.php?f=4&t=4924 will try then to help you... ";
                echo;
                echo "Goodbye";
                echo
                exit 1;
            fi

        ;;

        u*|U*)
            clear;
            read -p "To uninstall the OSSEC installation press [ENTER] , to quit use [CTRL-c]... ";
            if [[ ! -e /var/ossec ]]; then
                echo "OSSEC is currently not installed on this system... ";
                echo;
                sleep 3;
                exit 1;
            else
                echo;
                echo "Will stop OSSEC now... ";
                echo;
                /etc/init.d/ossec stop;
            fi

            if [[ -d /var/ossec ]]; then
                rm -rvf \
                /var/ossec \
                /etc/rc.d/init.d/ossec \
                /opt/pakfire/db/installed/meta-ossec \
                /etc/ossec-init.conf 2>&1 | tee /tmp/ossec_uninstaller.log;
                symlinkdel_funct;
                sed -i '/^ossec/d' /etc/passwd;
                sed -i '/^ossec/d' /etc/group;
                if [ -e "${ALERTSCRIPT}" ]; then
                    rm -rfv ${ALERTSCRIPT} ${CUSTOMALERTLOG};
                    sed -i '/# Ossec realtime log for e-mail alerts begin/,/# Ossec realtime log for e-mail alerts end/d' ${RC};
                    PID=$(ps x | grep -v grep | grep 'tail -F /var/ossec/logs/alerts/alerts.log' | awk '{ print $1 }');
                    if [ -n "${PID}" ]; then
                        kill ${PID};
                    fi
                fi
                echo;
                echo "OSSEC has been uninstalled, the uninstaller is finished now, thanks for testing.";
                echo;
                echo "Goodbye."
                echo;
                exit 0;
            else
                echo;
                echo "Can´t find OSSEC installation... ";
                echo;
                exit 1;
            fi
        ;;

        q*|Q*)
            exit 1
        ;;

        *)
            echo;
            echo "   Ooops, there went something wrong 8-\ - for explanation again   ";
            echo "-------------------------------------------------------------------";
            echo "             To install-server press 's' and [ENTER]";
            echo "             To install-agent press  'a' and [ENTER]";
            echo "             To configure press      'c' and [ENTER]";
            echo "             To uninstall press      'u' and [ENTER]";
            echo;
            read -p "To go back to installer menu press [ENTER]";
            echo;
        ;;
   
    esac

done

## End OSSEC installerscript
