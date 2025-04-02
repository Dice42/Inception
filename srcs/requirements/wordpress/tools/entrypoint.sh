#!/bin/sh
P_PASS2=$(cat /run/secrets/wp_user2_password)
WP_PASS=$(cat /run/secrets/wp_password)
MARIADB_PASSWORD=$(cat /run/secrets/mariadb_password)


wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
mkdir -p /var/www/html/wordpress
cd /var/www/html/wordpress

sleep 5

# Wait for Redis to be ready
echo "Waiting for Redis..."
while ! nc -z redis 6379; do
    sleep 1
done
echo "Redis is ready!"

#redis
wget https://raw.githubusercontent.com/rhubarbgroup/redis-cache/master/includes/object-cache.php
chmod +x object-cache.php
mv object-cache.php /var/www/html/wordpress/wp-content/
mkdir -p /var/www/html/wordpress/wp-content/plugins
cd /var/www/html/wordpress/wp-content/plugins
wget https://downloads.wordpress.org/plugin/redis-cache.latest-stable.zip
unzip redis-cache.latest-stable.zip
rm redis-cache.latest-stable.zip
cd /var/www/html/wordpress
#

# wp --allow-root core download --force 
php -d memory_limit=512M /usr/local/bin/wp --allow-root core download --force

chmod 777 -R /var/www/html/wordpress
mv wp-config-sample.php wp-config.php

sed -i "s/'database_name_here'/'$MARIADB_NAME'/g" wp-config.php
sed -i "s/'username_here'/'$MARIADB_USER'/g" wp-config.php
sed -i "s/'password_here'/'$MARIADB_PASSWORD'/g" wp-config.php
sed -i "s/'localhost'/'mariadb'/g" wp-config.php

sed -i "s|listen = 127.0.0.1:9000|listen = 0.0.0.0:9000|g" /etc/php83/php-fpm.d/www.conf

#for redis
echo "define('WP_REDIS_HOST', 'redis');" >> /var/www/html/wordpress/wp-config.php
echo "define('WP_REDIS_PORT', 6379);" >> /var/www/html/wordpress/wp-config.php
echo "define('WP_REDIS_TIMEOUT', 1);" >> /var/www/html/wordpress/wp-config.php
echo "define('WP_REDIS_READ_TIMEOUT', 1);" >> /var/www/html/wordpress/wp-config.php
echo "define('WP_CACHE_KEY_SALT', 'wordpress_redis');" >> /var/www/html/wordpress/wp-config.php
echo "define('WP_CACHE', true);" >> /var/www/html/wordpress/wp-config.php

echo 'listen.owner = nobody' >> /etc/php83/php-fpm.d/www.conf
echo 'listen.group = nobody' >> /etc/php83/php-fpm.d/www.conf

wp --allow-root --path=/var/www/html/wordpress core install \
    --url='http://localhost' --title='WordPress' \
    --skip-email --admin_email="$WP_EMAIL" \
    --admin_user="$WP_USER" \
    --admin_password="$WP_PASS"

wp --allow-root --path=/var/www/html/wordpress user create \
    $WP_USER2 $WP_EMAIL2 --role=subscriber \
    --user_pass="$WP_PASS2"

# Enable Redis Cache plugin
wp --allow-root --path=/var/www/html/wordpress plugin activate redis-cache
wp --allow-root --path=/var/www/html/wordpress redis enable

if [ -f /var/www/html/wordpress/wp-config.php ]; then
    php-fpm83 --nodaemonize
fi
