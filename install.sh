#!/usr/bin/env bash
set -o nounset -o errexit -o pipefail
 
## Domino specific set up for centos:7 image
 
WORKING_TMP_DIR=/tmp/centos_init
 
# Create domino user
groupadd -g 12574 $DOMINO_USER_GROUP
useradd -u 12574 -g 12574 -m -N -s /bin/bash $DOMINO_USER_NAME
sh -c "echo $DOMINO_USER_PASSWORD | passwd $DOMINO_USER_NAME --stdin"
echo "$DOMINO_USER_NAME    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo 'alias python="/usr/bin/python3"' >> /home/${DOMINO_USER_NAME}/.bashrc
echo 'alias pip="/usr/bin/pip3"' >> /home/${DOMINO_USER_NAME}/.bashrc
 
# Install some common utilities
yum install epel-release shadow-utils.x86_64 wget curl which git unzip gzip sudo -y
 
# Temporary working directory for packages
mkdir $WORKING_TMP_DIR
cd $WORKING_TMP_DIR
 
# Install Python3
yum install python3 -y
alias python="/usr/bin/python3"
rm -rf "/usr/bin/pip"
ln -s `which pip3` "/usr/bin/pip"
 
# Install Jupyter
bash /var/opt/workspaces/jupyter/install
pip3 install jupyter-server-proxy
mkdir -p /var/opt/workspaces/jupyter
curl -s https://raw.githubusercontent.com/dominodatalab/workspace-configs/develop/jupyter/start-centos -o /var/opt/workspaces/jupyter/start
chmod a+rx /var/opt/workspaces/jupyter/start
 
# Clean up
unalias -a
rm -rf $WORKING_TMP_DIR
yum clean all

# SAS Data Science Configuration
SAS_STUDIO_CONFIG_FILE=/opt/sas/viya/config/etc/sasstudio/default/init_usermods.properties
SAS_CLIENT_TOKEN_DIR="/opt/sas/viya/config/etc/SASSecurityCertificateFramework/tokens/consul/default/"
SAS_CLIENT_TOKEN_FILE="${SAS_CLIENT_TOKEN_DIR}/client.token"
SAS_AUTHINFO_FILE="/home/${DOMINO_USER_NAME}/.authinfo"
 
## Configure for Domino
# Setup SAS binaries for easy access
ln -s /opt/sas/spre/home/SASFoundation/bin/sas_en /usr/bin/sas
chmod a+rx /usr/bin/sas
 
# Create a .authinfo file for SAS CAS Engine batch scripts to run locally
echo """host localhost port 5570 user $DOMINO_USER_NAME password $DOMINO_USER_PASSWORD
default user $DOMINO_USER_NAME password $DOMINO_USER_PASSWORD""" > $SAS_AUTHINFO_FILE
chmod 600 $SAS_AUTHINFO_FILE
chown $DOMINO_USER_NAME:$DOMINO_USER_GROUP $SAS_AUTHINFO_FILE
 
# Configure SAS Studio
mkdir -p $SAS_CLIENT_TOKEN_DIR
touch $SAS_STUDIO_CONFIG_FILE $SAS_CLIENT_TOKEN_FILE
