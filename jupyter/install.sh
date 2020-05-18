#!/bin/bash
set -o nounset -o errexit -o pipefail

#install Jupyter
pip install jsonschema jupyter

# # #   # CONFIGURE Jupyter
mkdir -p /home/${DOMINO_USER_NAME}/.jupyter
echo 'c = get_config()' > /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py

# The default cell execution timeout in nbconvert is 30 seconds, set it to a year
echo '# The default cell execution timeout in nbconvert is 30 seconds, set it to a year' >> /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py
echo 'c.ExecutePreprocessor.timeout = 365*24*60*60' >> /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py

# Allow embedding of notebooks in iframes
echo '# Allow embedding of notebooks in iframes' >> /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py
echo 'c.NotebookApp.tornado_settings = { "headers": { "Content-Security-Policy": "frame-ancestors *" } }' >> /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py 
echo "c.NotebookApp.token = ''" >> /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py

#Custom js for domino header. New noebooks open within the same tab with the Domino banner. 
mkdir -p /home/${DOMINO_USER_NAME}/.jupyter/custom/
echo "require(['base/js/namespace'], function(jupyter) { jupyter._target='_self'; });" >> /home/${DOMINO_USER_NAME}/.jupyter/custom/custom.js 

# Disable the login for Jupyter
mkdir -p /home/${DOMINO_USER_NAME}/.jupyter 
printf "\nc.NotebookApp.token = u'' \n\n" >> /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py 
 
# Maintain backward compatibility with ipython
mkdir -p /home/${DOMINO_USER_NAME}/.ipython/profile_default 
ln -s   /home/${DOMINO_USER_NAME}/.jupyter/jupyter_notebook_config.py /home/${DOMINO_USER_NAME}/.ipython/profile_default/ipython_notebook_config.py
chown -R ${DOMINO_USER_NAME}:${DOMINO_USER_GROUP} /home/${DOMINO_USER_NAME}/.ipython

chown -R ${DOMINO_USER_NAME}:${DOMINO_USER_GROUP} /home/${DOMINO_USER_NAME}/.jupyter

