FROM python:latest

# install ssh package
RUN apt update && apt -y install openssh-server

# install tidal-dl
RUN pip3 install tidal-dl --upgrade

# copy the entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# copy the tidal-dl startup script
# COPY etc/bash.bashrc /etc

# expose ssh port
EXPOSE 22/tcp

# run entrypoint script
ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
