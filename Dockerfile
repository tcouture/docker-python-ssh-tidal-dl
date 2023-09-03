FROM python:latest

# install ssh package
RUN apt update && apt -y install openssh-server

# copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# expose ssh port
EXPOSE 22/tcp

# run entrypoint script
ENTRYPOINT [ "entrypoint.sh" ]
