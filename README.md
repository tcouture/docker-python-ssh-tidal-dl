# Docker container with Python and SSH server 🐳🐍🔐

## Description

This container provides the most recent official Python container with SSH server preinstalled.

## Basic Setup

This starts the container while listening for SSH connections on port 2222:

```bash
docker run -d -v '/mnt/pythonssh':'/config':'rw' -p '2222:22/tcp' '<work-in-progress>'
```

Note: The SSH username and password is randomly created and visible through the container logs (only on initial setup).

After the initial setup the `/config` directory (`/mnt/pythonssh` on your host machine) contains two files:

- `username.conf` containing the username
- `password_hash.conf` containing the password hash

## Advanced Setup

This starts the container while setting username, password hash, user id and group id:

```bash
docker run -d --name='pythonssh' -e USERNAME='pythonssh' -e PUID='99' -e PGID='100' -e PASSWORD_HASH='$6$b9jajAmHkEGDlAoM$3T8VBYIRlEj2MQ8syB4BuC6grcLIyoq56Ay2Lq1MsPj/KZd3JJFJeh.p97QT24oBIXhxGHpeOZ0Xt/h0PZJUY/' -v '/mnt/pythonssh':'/config':'rw' -p '2222:22/tcp'  '<work-in-progress>'
```

You could create the hash with the following command on your local machine:

```bash
openssl passwd -6 your_password_in_clear_text
```

Or you could add `-e PASSWORD='your_password_in_clear_text'` to your `docker run` command, run the container once and remove it again, as further runs will use the hash in `/config/password_hash.conf` as mentioned above.

## Key-based SSH authentification

As `/config` is the home directory of `USERNAME`, you can provide `/config/.ssh/authorized_keys` to connect by key instead of password.

## TODO

- Set SSH log level for getting an output on `/var/log/auth.log`
- What happens if username does not start with "py" and has been changed?
- Add option to disable login by password
- Allow to set official Python tags (latest, slim, alpine, etc)

