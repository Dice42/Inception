#!/bin/sh

/etc/init.d/mariadb setup

rc-service mariadb start

echo "CREATE DATABASE IF NOT EXISTS $MARIADB_NAME;" > md.file
echo "CREATE USER IF NOT EXISTS '$MARIADB_USER'@'%' IDENTIFIED BY '$MARIADB_PWD' ;" >> md.file
echo "GRANT ALL PRIVILEGES ON $MARIADB_NAME.* TO '$MARIADB_USER'@'localhost' ;" >> md.file
echo "FLUSH PRIVILEGES;" >> md.file
# echo "ALTER USER '$MARIADB_ROOT_USER'@'localhost' IDENTIFIED BY '$MARIADB_ROOT_PASS';" >> md.file

mariadb < md.file


sed -i 's/skip-networking/#skip-networking/g' /etc/my.cnf.d/mariadb-server.cnf
sed -i 's/#bind-address=0.0.0.0/bind-address=0.0.0.0/g' /etc/my.cnf.d/mariadb-server.cnf

rc-service mariadb restart
rc-service mariadb stop

#manually start the mariadb deamon --base directory where mariadb installed --data directory where mariadb stores all its tables logs schemas indexes --plugin dir where its stores its engine plugin authintication --pid 
/usr/bin/mariadbd --basedir=/usr --datadir=/var/lib/mysql --plugin-dir=/usr/lib/mariadb/plugin --user=mysql --pid-file=/run/mysqld/mariadb.pid
