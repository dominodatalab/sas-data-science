FROM SASDS_DOCKER_TAG

# These should not be changed or it will break the Compute Environment
ARG DOMINO_USER_NAME=domino
ARG DOMINO_USER_GROUP=domino

# These can be modified
ARG DOMINO_USER_PASSWORD=domino
ARG SASDS_SCRIPT_DIR="/var/opt/workspaces/sasds"

ENTRYPOINT []
 
USER root
 
RUN mkdir $SASDS_SCRIPT_DIR
ADD install.sh start.sh $SASDS_SCRIPT_DIR/
ADD run_sas.sh /usr/bin/run_sas.sh
RUN chmod a+x /usr/bin/run_sas.sh
    chmod a+x $SASDS_SCRIPT_DIR/start && \
    bash $SASDS_SCRIPT_DIR/install
