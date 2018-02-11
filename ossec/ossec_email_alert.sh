#!/bin/bash -

#
# Script searches for Ossec alerts above a defined level (default from 6-16).
# If something appears, an encrypted alert mail will be send.
#
# $author: ummeegge ; $date:2016.21.03
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
MAILPASS="StrengstGeheimesKennwort";
MAILADDRESS="example@web.de";
MAILNAME="example";
SMTPADDRESS="smtp.web.de:587";
MESSAGE="From $(date)";
SUBJECT="From $(date) OA message";
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
    -a "${FILECRYPTED}";
    rm -f "${FILE}"*;
    echo > "${ALERTLOG}";
    logger -t ossec: "Mailalert has been send."
else
    echo > "${ALERTLOG}";
fi

# End script
