#!/bin/sh

wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
mkdir -p /var/www/html/wordpress
cd /var/www/html/wordpress
# wp --allow-root core download --force 
php -d memory_limit=512M /usr/local/bin/wp --allow-root core download --force

chmod 777 -R /var/www/html/wordpress
mv wp-config-sample.php wp-config.php

sed -i "s/'database_name_here'/'$MARIADB_NAME'/g" wp-config.php
sed -i "s/'username_here'/'$MARIADB_USER'/g" wp-config.php
sed -i "s/'password_here'/'$MARIADB_PWD'/g" wp-config.php
sed -i "s/'localhost'/'mariadb'/g" wp-config.php

sed -i "s|listen = 127.0.0.1:9000|listen = 9000|g" /etc/php83/php-fpm.d/www.conf

echo 'listen.owner = nobody' >> /etc/php83/php-fpm.d/www.conf
echo 'listen.group = nobody' >> /etc/php83/php-fpm.d/www.conf

wp --allow-root --path=/var/www/html/wordpress core install \
    --url='mohammoh.42.fr' --title='WordPress' \
    --skip-email --admin_email="${WP_EMAIL}" \
    --admin_user="$WP_USER" \
    --admin_password="$WP_PASS"

if [ -f /var/www/html/wordpress/wp-config.php ]; then
	php-fpm83 --nodaemonize
fi

wp --allow-root --path=/var/www/html/wordpress core install  --url='mohammoh.42.fr' --title='WordPress' --skip-email --admin_email="dice@dice.com" --admin_user="dice" --admin_password="Dice@1234"

# sed -i "s/'database_name_here'/'dicedb'/g" wp-config.php
# sed -i "s/'username_here'/'dice'/g" wp-config.php
# sed -i "s/'password_here'/'dice42'/g" wp-config.php
# sed -i "s/'localhost'/'mariadb'/g" wp-config.php