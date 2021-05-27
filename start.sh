#!/usr/bin/env bash
set -o errexit -o pipefail

[[ -z $DOMINO_USER_NAME ]] && DOMINO_USER_NAME="domino"
[[ -z $DOMINO_USER_PASSWORD ]] && DOMINO_USER_PASSWORD="domino"
[[ -z $DOMINO_WORKING_DIR ]] && DOMINO_WORKING_DIR="/mnt"
[[ -z $DOMINO_PROJECT_OWNER ]] && DOMINO_PROJECT_OWNER="domino"
[[ -z $DOMINO_PROJECT_NAME ]] && DOMINO_PROJECT_NAME="domino"
[[ -z $DOMINO_RUN_ID ]] && DOMINO_RUN_ID="1"
[[ -z $DOMINO_USER_HOST ]] && DOMINO_USER_HOST="http://localhost"
[[ -z $DOMINO_USE_SUBDOMAIN ]] && DOMINO_USE_SUBDOMAIN=false
[[ -z $SAS_LOGS_TO_DISK ]] && SAS_LOGS_TO_DISK=true
[[ -z $REVERSE_PROXY_PORT ]] && REVERSE_PROXY_PORT=8888

DOMINO_SAS_CONFIG_DIR="${DOMINO_WORKING_DIR}/sasconfig"
DOMINO_SASSTUDIO_AUTOEXEC_FILE="${DOMINO_SAS_CONFIG_DIR}/sasstudio-autoexec.sas"
DOMINO_SAS_SNIPPETS_DIR="${DOMINO_SAS_CONFIG_DIR}/snippets"
DOMINO_SAS_TASKS_DIR="${DOMINO_SAS_CONFIG_DIR}/tasks"
DOMINO_SAS_PREFERENCES_DIR="${DOMINO_SAS_CONFIG_DIR}/preferences"
DOMINO_SAS_KEYBOARDSHORTCUTS_DIR="${DOMINO_SAS_CONFIG_DIR}/keyboardShortcuts"
DOMINO_SAS_STATE_DIR="${DOMINO_SAS_CONFIG_DIR}/state"
DOMINO_GIT_REPOS_PATH=/repos
DOMINO_DATASETS_PATH=/domino/datasets
SAS_STUDIO_CONFIG_FILE=/opt/sas/viya/config/etc/sasstudio/default/init_usermods.properties
SAS_AUTOEXEC_DIR="$HOME/.sasstudio5"
SAS_STUDIO_AUTOEXEC_FILE="${SAS_AUTOEXEC_DIR}/.autoexec.sas"
SAS_SHORTCUTS_DIR="$HOME/.sasstudio5"
SAS_SHORTCUTS_FILE="${SAS_SHORTCUTS_DIR}/shortcuts.xml"
SAS_SNIPPETS_DIR="$HOME/.sasstudio5/mySnippets"
SAS_TASKS_DIR="$HOME/.sasstudio5/myTasks"
SAS_PREFERENCES_DIR="$HOME/.sasstudio5/preferences"
SAS_KEYBOARDSHORTCUTS_DIR="$HOME/.sasstudio5/keyboardShortcuts"
SAS_STATE_DIR="$HOME/.sasstudio5/state"
SAS_JAVA_OPTIONS="-Dserver.servlet.session.timeout=31104000s"
 
# Prevent SAS Entrypoint script from starting Apache proxy server
APACHE_CONF=/etc/httpd/conf/httpd.conf
APACHE_PORT=8880
sudo sed -Ei "s#Listen 80#Listen $APACHE_PORT#g" $APACHE_CONF
 
# Set up Domino project to preserve SAS configuration files
mkdir -p "$DOMINO_SAS_CONFIG_DIR" "$DOMINO_SAS_SNIPPETS_DIR" "$DOMINO_SAS_TASKS_DIR" "$DOMINO_SAS_PREFERENCES_DIR" "$DOMINO_SAS_KEYBOARDSHORTCUTS_DIR" "$DOMINO_SAS_STATE_DIR"
 
# Hack to ensure autoexec.sas can live in the Domino project folder.
# This is needed to properly tie in autoexec.sas with SAS Studio
mkdir -p "$SAS_AUTOEXEC_DIR"
rm -rf "$SAS_STUDIO_AUTOEXEC_FILE"
ln -s "$DOMINO_SASSTUDIO_AUTOEXEC_FILE" "$SAS_STUDIO_AUTOEXEC_FILE"
 
# Hack to ensure SAS Studio "My Snippets" are preserved with the Domino project files
rm -rf "$SAS_SNIPPETS_DIR"
ln -s "$DOMINO_SAS_SNIPPETS_DIR" "$SAS_SNIPPETS_DIR"
 
# Hack to ensure SAS Studio "My Tasks" are preserved with the Domino project files
rm -rf "$SAS_TASKS_DIR"
ln -s "$DOMINO_SAS_TASKS_DIR" "$SAS_TASKS_DIR"
 
# Hack to ensure SAS Studio Preferences are preserved with the Domino project files
[[ ! -d "$DOMINO_SAS_STATE_DIR" && -d "$SAS_STATE_DIR" ]] && cp -r "${SAS_STATE_DIR}/*" "${DOMINO_SAS_STATE_DIR}/"
rm -rf "$SAS_STATE_DIR"
ln -s "$DOMINO_SAS_STATE_DIR" "$SAS_STATE_DIR"
 
# Hack to ensure SAS Studio state is preserved with the Domino project files
[[ ! -d "$DOMINO_SAS_PREFERENCES_DIR" && -d "$SAS_PREFERENCES_DIR" ]] && cp -r "${SAS_PREFERENCES_DIR}/*" "${DOMINO_SAS_PREFERENCES_DIR}/"
rm -rf "$SAS_PREFERENCES_DIR"
ln -s "$DOMINO_SAS_PREFERENCES_DIR" "$SAS_PREFERENCES_DIR"
 
# Hack to ensure SAS Studio Keyboard Shortcuts are preserved with the Domino project files
rm -rf "$SAS_KEYBOARDSHORTCUTS_DIR"
ln -s "$DOMINO_SAS_KEYBOARDSHORTCUTS_DIR" "$SAS_KEYBOARDSHORTCUTS_DIR"
 
# Configure SAS Studio folder shortcuts to show Domino Git repos and Datasets folders
SHORTCUTS_DOMINO_GIT_REPOS=""
if [ -d "$DOMINO_GIT_REPOS_PATH" ]; then
    SHORTCUTS_DOMINO_GIT_REPOS="  <Shortcut type=\"disk\" name=\"Git Repos\" dir=\"$DOMINO_GIT_REPOS_PATH\" />"
fi
 
SHORTCUTS_DOMINO_DATASETS=""
if [ -d "$DOMINO_DATASETS_PATH" ]; then
    SHORTCUTS_DOMINO_DATASETS="  <Shortcut type=\"disk\" name=\"Domino Datasets\" dir=\"$DOMINO_DATASETS_PATH\" />"
fi
 
SHORTCUTS_DOMINO_IMPORTS=""
for DOMINO_IMPORT in `printenv | grep -e 'DOMINO_.*_WORKING_DIR' | tr '=' ' ' | awk '{print $1}'`; do
    DOMINO_IMPORT_DIR=${!DOMINO_IMPORT}
    DOMIMO_IMPORT_NAME=`echo "Import $DOMINO_IMPORT_DIR" | sed 's#/mnt/##g'`
    SHORTCUTS_DOMINO_IMPORTS="  <Shortcut type=\"disk\" name=\"$DOMIMO_IMPORT_NAME\" dir=\"$DOMINO_IMPORT_DIR\" />"
done
 
SHORTCUTS_HOME="  <Shortcut type=\"disk\" name=\"Home\" dir=\"$HOME\" />"
SHORTCUTS_TMP="  <Shortcut type=\"disk\" name=\"Temp\" dir=\"/tmp\" />"
 
SAS_SHORTCUTS="""<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Shortcuts>
$SHORTCUTS_DOMINO_GIT_REPOS
$SHORTCUTS_DOMINO_DATASETS
$SHORTCUTS_DOMINO_IMPORTS
$SHORTCUTS_HOME
$SHORTCUTS_TMP
</Shortcuts>"""
mkdir -p $SAS_SHORTCUTS_DIR
echo $SAS_SHORTCUTS > $SAS_SHORTCUTS_FILE
 
 
# Configure SAS Studio options for Domino
SAS_CONFIG_UPDATES="""
sas.studio.basicUser=${DOMINO_USER_NAME}
sas.studio.basicPassword=${DOMINO_USER_PASSWORD}
sas.studio.fileNavigationRoot=CUSTOM
sas.studio.fileNavigationCustomRootPath=${DOMINO_WORKING_DIR}
sas.studio.globalShortcutsPath=${SAS_SHORTCUTS_FILE}

sas.commons.web.security.cors.allowedOrigins=*
sas.commons.web.security.csrf.enable-csrf=false
sas.commons.web.security.content-security-policy-enabled=false
sas.commons.web.security.x-frame-options-enabled=false
sas.commons.web.security.x-content-type-options-enabled=false
sas.commons.web.security.x-xss-protection-enabled=false
"""
sudo sh -c "echo '$SAS_CONFIG_UPDATES' > $SAS_STUDIO_CONFIG_FILE"

# Some configuration for Domino subdomains and revese proxy server
if $DOMINO_USE_SUBDOMAIN; then
    PREFIX="/SASStudio/"    
else
    PREFIX="/${DOMINO_PROJECT_OWNER}/${DOMINO_PROJECT_NAME}/notebookSession/${DOMINO_RUN_ID}/"
    SAS_JAVA_OPTIONS="$SAS_JAVA_OPTIONS -Dserver.servlet.context-path=$PREFIX"
fi
SAS_TEST_URL="http://localhost:7080${PREFIX}"
DOMINO_SAS_ENTRY_PAGE="${PREFIX}start.html"
sudo mkdir -p ${SASDS_SCRIPT_DIR}/html${PREFIX}
sudo chown -R $DOMINO_USER_NAME:$DOMINO_USER_NAME ${SASDS_SCRIPT_DIR}/html${PREFIX}
sudo sed -Ei "s#8888#$REVERSE_PROXY_PORT#g" ${SASDS_SCRIPT_DIR}/nginx.conf
sudo sed -E "s#SESSION_PATH#$PREFIX#g" ${SASDS_SCRIPT_DIR}/start.html > ${SASDS_SCRIPT_DIR}/html${DOMINO_SAS_ENTRY_PAGE}

# Populate environment variables into SAS processes
export | sudo sh -c "cat >> /opt/sas/spre/home/SASFoundation/bin/sasenv_local"

# Enable XCMD
sudo sed -Ei 's#^USERMODS=(.*)#USERMODS=-allowxcmd \1#g' /opt/sas/viya/config/etc/spawner/default/spawner_usermods.sh
sudo sh -c "echo '-XCMD' >> /opt/sas/spre/home/SASFoundation/sasv9_local.cfg"

# This actually starts the SAS Studio workspace
# The Apache httpd variables here are to ensure the SAS httpd service does not start since we do not use it in Domino
sudo -E SAS_LOGS_TO_DISK=$SAS_LOGS_TO_DISK _JAVA_OPTIONS="$_JAVA_OPTIONS $SAS_JAVA_OPTIONS" APACHE_CONF_D=/etc/httpd/conf.d APACHE_CONF=/etc/httpd/conf/httpd.conf APACHE_DOCROOT=/var/www/html APACHE_BIN=/usr/bin/echo APACHE_CTL=/usr/bin/echo APACHE_PID=/var/run/sas/sas-viya-spawner-default.pid bash -c '/opt/sas/viya/home/bin/entrypoint &'

# Wait for SAS Studio web server to come online
until $(curl --output /dev/null --silent --head --fail $SAS_TEST_URL); do sleep 3; done

# Start reverse proxy server
sudo /usr/sbin/nginx -c ${SASDS_SCRIPT_DIR}/nginx.conf
echo -e "\n\nSAS Studio is now running\nTo get started, please visit ${DOMINO_USER_HOST}${DOMINO_SAS_ENTRY_PAGE} in your web browser.\n\n"

# Infinite loop to prevent Workspace container from terminating
while true ; do :; sleep 60 ; done
