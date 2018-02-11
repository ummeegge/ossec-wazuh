############################################################################
#                                                                          #
# This file is part of the IPFire Firewall.                                #
#                                                                          #
# IPFire is free software; you can redistribute it and/or modify           #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation; either version 2 of the License, or        #
# (at your option) any later version.                                      #
#                                                                          #
# IPFire is distributed in the hope that it will be useful,                #
# but WITHOUT ANY WARRANTY; without even the implied warranty of           #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
# GNU General Public License for more details.                             #
#                                                                          #
# You should have received a copy of the GNU General Public License        #
# along with IPFire; if not, write to the Free Software                    #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA #
#                                                                          #
# Copyright (C) 2009 IPFire-Team <info@ipfire.org>.                        #
#                                                                          #
############################################################################
#
. /opt/pakfire/lib/functions.sh

BIN="ossec-agent";

## Add users and group
# Investigate highest ID in group
GR=$(awk -F":" '{ print $3 }' /etc/group | sort -rn | head -1);
# Investigate highest IDs passwd
U=$(awk -F":" '{ print $3 }' /etc/passwd | sort -rn | head -1);
G=$(awk -F":" '{ print $4 }' /etc/passwd | sort -rn | head -1);
# Calculate group
GROUP=$(echo $((${GR} +1)));
# Calculate first user ossec
OSSECU=$(echo $((${U} + 1)));
OSSECG=${GROUP};
# Add group 'ossec'
groupadd -g ${GROUP} ossec;
# Add 'ossec' user
useradd -g ${GROUP} -u ${OSSECU} -d /var/ossec -s /sbin/nologin ossec;

extract_files

## Add symlinks
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

echo "Please configure your agent appropriatley before starting Ossec-agent";

# End script
