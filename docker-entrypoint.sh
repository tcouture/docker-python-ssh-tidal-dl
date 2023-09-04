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
if [[ -f "/config/username.conf" ]]; then
    USERNAME=$(cat "/config/username.conf")
fi

# create random username (no config file and no environmental variable were provided)
if [[ ! $USERNAME ]]; then
    USERNAME=$(echo -n "py"; openssl rand -hex 2)
    echo "SSH username is $USERNAME"
fi

# username has been changed
old_username=$(grep ":pythonsshcomment:" /etc/passwd | grep --max-count=1 --invert-match "^$USERNAME:" | cut -d ':' -f 1 )
if [[ $old_username ]]; then
    if userdel "$old_username"; then
        echo "Warning: $old_username has been deleted as it was changed to $USERNAME."
    else
        echo "Error: $old_username could not be deleted!"
    fi
fi

# obtain password hash by config file
if [[ -f "/config/password.conf" ]]; then
    PASSWORD_HASH=$(cat "/config/password_hash.conf")
elif [[ $PASSWORD ]]; then
    PASSWORD_HASH=$(openssl passwd -6 $PASSWORD)
fi

# create random password (no config file and no environmental variable were provided)
if [[ ! $PASSWORD ]]; then
    PASSWORD=$(openssl rand -base64 12)
    echo "SSH password is $PASSWORD"
    PASSWORD_HASH=$(openssl passwd -6 $PASSWORD)
fi

# better safe than sorry
unset PASSWORD

# add group
groupadd --gid "$PGID" --system user-group 1>/dev/null || true

# add user
if ! grep --quiet "^$USERNAME:" /etc/passwd; then
    echo "Information: $USERNAME will be added as new SSH user."
    useradd --uid "$PUID" --gid "$PGID" --comment "pythonsshcomment" --home "/config" --shell "/bin/bash" --password "$PASSWORD_HASH" "$USERNAME"
    chown --recursive --verbose "$PUID:$PGID" "/config" # update file owner
    echo "$USERNAME" > "/config/username.conf"
    echo "$PASSWORD_HASH" > "/config/password_hash.conf"
fi

# password has been changed
if ! grep "^$USERNAME:" /etc/shadow | grep --quiet "$PASSWORD_HASH"; then
    if echo "$USERNAME:$PASSWORD_HASH" | chpasswd --encrypted; then
        echo "$PASSWORD_HASH" > "/config/password_hash.conf"
        echo "Warning: Password of $USERNAME has been changed."
    else
        echo "Error: Could not change password of $USERNAME!"
    fi
fi

# link auth.log to container log
ln -sf /proc/self/fd/1 /var/log/auth.log

# start ssh service
service ssh start
