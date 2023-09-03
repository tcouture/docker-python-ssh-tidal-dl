#!/bin/bash
set -e

# Available environmental variables (config files have a higher priority):
# USERNAME
# PASSWORD
# PASSWORD_HASH
# PUID
# PGID

# set default user and group id
PUID=${PUID:-1000}
PGID=${PGID:-1000}

# obtain username by config file
if [[ -f /config/username.conf ]]; then
    USERNAME=$(cat /config/username.conf)
fi

# create random username (no config file and no environmental variable provided)
if [[ ! $USERNAME ]]; then
    USERNAME=$(echo -n "py"; openssl rand -hex 2)
    echo "SSH username is $USERNAME"
fi

# username has been changed
old_user=$(grep "^py" /etc/passwd | grep --max-count=1 --invert-match "^$USERNAME:")
if [[ $old_user ]]; then
    userdel "$old_user"
fi

# obtain password hash by config file
if [[ -f /config/password.conf ]]; then
    PASSWORD_HASH=$(cat /config/password_hash.conf)
elif [[ $PASSWORD ]]; then
    PASSWORD_HASH=$(openssl passwd -6 $PASSWORD)
fi

# create random password (no config file and no environmental variable provided)
if [[ ! $PASSWORD ]]; then
    PASSWORD=$(openssl rand -base64 12)
    echo "SSH password is $PASSWORD"
    PASSWORD_HASH=$(openssl passwd -6 $PASSWORD)
fi
unset PASSWORD # better safe than sorry

# add group
groupadd --gid "$PGID" --system user-group 1>/dev/null || true

# add user
if ! grep --quiet "^$USERNAME:" /etc/passwd; then
    useradd --uid "$PUID" --gid "$PGID" --home /config --shell /bin/bash --password "$PASSWORD_HASH" "$USERNAME"
    chown --recursive --verbose "$PUID:$PGID" /config # update file owner
fi

# password has been changed
if ! grep "^$USERNAME:" /etc/passwd | grep --quiet "$PASSWORD_HASH"; then
    echo "$USERNAME:$PASSWORD_HASH" | chpasswd --encrypted
fi

# link auth.log to container log
ln -sf /proc/self/fd/1 /var/log/auth.log

# start ssh service
service ssh start
