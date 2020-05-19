FROM SASDS_DOCKER_TAG

# These should not be changed or it will break the Compute Environment
ARG DOMINO_USER_NAME=domino
ARG DOMINO_USER_GROUP=domino

# These can be modified
ARG DOMINO_USER_PASSWORD=domino
ENV SASDS_SCRIPT_DIR=/var/opt/workspaces/sasds
 
USER root

# Add scripts to configure SAS Data Science for Domino
ADD install.sh $SASDS_SCRIPT_DIR/install
ADD jupyter/install.sh /var/opt/workspaces/jupyter/install

RUN chmod a+rx $SASDS_SCRIPT_DIR/install /var/opt/workspaces/jupyter/install && \
    bash $SASDS_SCRIPT_DIR/install

# Add script to help launch SAS batch scripts (used by Domino Jobs)
ADD run_sas.sh /usr/bin/run_sas.sh

# Add script to laucnh SAS Studio workspace
ADD start.sh $SASDS_SCRIPT_DIR/start

# Add files to support the reverse proxy server
ADD reverse_proxy/proxy.sh $SASDS_SCRIPT_DIR/proxy
ADD reverse_proxy/start.html $SASDS_SCRIPT_DIR/html/SASStudio/start.html
ADD reverse_proxy/nginx.conf $SASDS_SCRIPT_DIR/nginx.conf
RUN chown -R $DOMINO_USER_NAME:$DOMINO_GROUP_NAME $SASDS_SCRIPT_DIR && \
    chmod a+rx $SASDS_SCRIPT_DIR/start /usr/bin/run_sas.sh && \
    chmod a+r $SASDS_SCRIPT_DIR/html/SASStudio/start.html $SASDS_SCRIPT_DIR/nginx.conf && \
    chmod a+rx $SASDS_SCRIPT_DIR/proxy && \
    bash $SASDS_SCRIPT_DIR/proxy

ENTRYPOINT []
