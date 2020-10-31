mkdir -p /etc/pgbackrest
mkdir -p /etc/pgbackrest/conf.d
mkdir -p /var/log/pgbackrest
touch /etc/pgbackrest/pgbackrest.conf
chmod 640 /etc/pgbackrest/pgbackrest.conf
chmod 770 /var/log/pgbackrest
chown postgres:postgres /etc/pgbackrest/pgbackrest.conf
chown postgres:postgres /var/log/pgbackrest
