FROM SASDS_DOCKER_TAG

# These should not be changed or it will break the Compute Environment
ARG DOMINO_USER_NAME=domino
ARG DOMINO_USER_GROUP=domino

# These can be modified
ARG DOMINO_USER_PASSWORD=domino
ARG SASDS_SCRIPT_DIR="/var/opt/workspaces/sasds"

ENTRYPOINT []
 
USER root

# Add scripts to configuration and launch SAS Studio workspaces
ADD install.sh start.sh $SASDS_SCRIPT_DIR/

# Add script to help launch SAS batch scripts (used by Domino Jobs)
ADD run_sas.sh /usr/bin/run_sas.sh

# Add files to support the reverse proxy server
ADD reverse_proxy/start.html $SASDS_SCRIPT_DIR/html/SASStudio/
ADD reverse_proxy/nginx.conf $SASDS_SCRIPT_DIR/

RUN chown -r $DOMINO_USER_NAME:$DOMINO_GROUP_NAME $SASDS_SCRIPT_DIR
    chmod a+x /usr/bin/run_sas.sh
    chmod a+x $SASDS_SCRIPT_DIR/install $SASDS_SCRIPT_DIR/start && \
    bash $SASDS_SCRIPT_DIR/install
