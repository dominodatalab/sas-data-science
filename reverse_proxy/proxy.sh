#!/usr/bin/env bash
set -o errexit -o pipefail

# Reverse proxy configuration

if [[ -z $REVERSE_PROXY_PORT ]]; then
    REVERSE_PROXY_PORT=8888
fi
 
yum install nginx -y
sed -iE "s#8888#$REVERSE_PROXY_PORT#g" ${SASDS_SCRIPT_DIR}/nginx.conf
sed -iE "s#function start_viya .*#function start_viya { sudo SAS_LOGS_TO_DISK=\$SAS_LOGS_TO_DISK su --session-command '/opt/sas/viya/home/bin/entrypoint \&' root; until \$(curl --output /dev/null --silent --head --fail http://localhost:7080/SASStudio); do sleep 3; done; sudo /usr/sbin/nginx -c \${SASDS_SCRIPT_DIR}/nginx.conf; echo -e '\\\n\\\nStarted reverse proxy server...\\\n\\\n'; while true; do :; done; }#g" ${SASDS_SCRIPT_DIR}/start
