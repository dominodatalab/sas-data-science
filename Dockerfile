FROM SASDS_DOCKER_TAG

ARG SASDS_SCRIPT_DIR="/var/opt/workspaces/sasds"

ENTRYPOINT []
 
USER root
 
RUN mkdir $SASDS_SCRIPT_DIR
ADD install.sh start.sh $SASDS_SCRIPT_DIR/install
RUN chmod a+x /var/opt/workspaces/sasds/start && \
    bash $SASDS_SCRIPT_DIR/install
