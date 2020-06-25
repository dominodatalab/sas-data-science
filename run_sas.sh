#!/usr/bin/env bash
set -o errexit -o pipefail

[[ -z $DOMINO_USER_NAME ]] && DOMINO_USER_NAME="domino"
[[ -z $DOMINO_WORKING_DIR ]] && DOMINO_WORKING_DIR="/mnt"
[[ -z $DOMINO_PROJECT_OWNER ]] && DOMINO_PROJECT_OWNER="domino"
[[ -z $DOMINO_PROJECT_NAME ]] && DOMINO_PROJECT_NAME="domino"
[[ -z $SAS_LOGS_TO_DISK ]] && SAS_LOGS_TO_DISK=true
 
DOMINO_SAS_CONFIG_DIR="${DOMINO_WORKING_DIR}/sasconfig"
DOMINO_SASBATCH_AUTOEXEC_FILE="${DOMINO_SAS_CONFIG_DIR}/sasbatch-autoexec.sas"
SAS_BATCH_AUTOEXEC_FILE="/opt/sas/viya/config/etc/batchserver/default/autoexec.sas"
SAS_AUTHINFO_FILE="$HOME/.authinfo"
 
function sas_log_errors { echo $(grep "ERROR: Errors printed on page" $1 | wc -l); }
 
 
FILE=$1
if [[ $FILE == *.sas ]]
then
    if [[ -f "$FILE" ]]
    then
        # Set up Domino project to preserve SAS configuration files
        mkdir -p "$DOMINO_SAS_CONFIG_DIR"
 
        # Hack to ensure we preserve the batch-mode autoexec.sas
        [[ ! -f "$DOMINO_SASBATCH_AUTOEXEC_FILE" && -f "$SAS_BATCH_AUTOEXEC_FILE" ]] && cp "$SAS_BATCH_AUTOEXEC_FILE" "$DOMINO_SASBATCH_AUTOEXEC_FILE"
        sudo rm -rf "$SAS_BATCH_AUTOEXEC_FILE"
        sudo ln -s "$DOMINO_SASBATCH_AUTOEXEC_FILE" "$SAS_BATCH_AUTOEXEC_FILE"
    
        # Fix an error message where this file does not exist
        sudo touch /opt/sas/viya/config/etc/cas/default/startup.lua
        # Fix set -x in cas_create_dir.sh
        sudo sed -Ei 's#set [-+]x##g' /opt/sas/viya/home/SASFoundation/utilities/bin/cas_create_dir.sh
 
        # Make sure we minimize output to stdout
        cd $(dirname "$FILE")
        /opt/sas/spre/home/bin/sas -batch $(basename "$FILE")
        #sudo SAS_LOGS_TO_DISK=$SAS_LOGS_TO_DISK AUTHINFO="$SAS_AUTHINFO_FILE" /opt/sas/viya/home/bin/entrypoint --batch "$1" > /dev/null
        #sudo SAS_LOGS_TO_DISK=$SAS_LOGS_TO_DISK su --session-command '/opt/sas/viya/home/bin/entrypoint --batch "$1"' root > /dev/null
 
        # Output of SAS Program should be saved to a log file
        # Grab the filename of the most recent log file that fits the name of the SAS Program
        #log_file=$(ls -t $(basename $(echo ${FILE} | cut -d "." -f 1))*.log | head -n 1)
 
        # Write output of script to STDOUT
        #cat $log_file
 
        #exit_code=0
        #if [[ $(sas_log_errors $log_file) -gt 0 ]]
        #then
        #    exit_code=1
        #fi
 
        # Remove log file
        #rm -rf $log_file
 
        #exit $exit_code
    else
        echo "File '$FILE' does not exist. Please contact support@dominodatalab.com if this is unexpected."
    fi
else
    echo "File '$FILE' not recognized by run_sas.sh. Please contact support@dominodatalab.com if this is unexpected."
fi
