#!/bin/bash
#
# Fixed from https://www.exratione.com/2015/04/a-provisioning-bash-script-for-a-wordpress-4-ubuntu-14-04-lamp-server/
# For Ubuntu 14.04.
#
# Installation of prerequisites for a LAMP WordPress 4.* server.
#
# Configure Before Running
# ------------------------
#
# In the "EDIT CONFIGURATION BEFORE RUNNING" section, set the values desired for
# the site name, usernames and passwords, and so forth. Then run the script.
#
# Set the import mode via the WP_IMPORT variable. You have the option of:
#
# - wxr: Importing a WXR export file.
# - sql: Importing a MySQL database dump file.
# - any other value: No import at all.
#
# You Still Have Work To Do After Running
# ---------------------------------------
#
# After the setup script runs, you will still have a fair amount of work to do.
# For example:
#
# - Copy in a valid SSL certificate.
# - Append the dhparams.pem file to the certificate file.
# E.g. cat /etc/ssl/private/dhparams.pem > /etc/ssl/certs/www.example.com.pem
# - Finalize wp-config.php.
# - Create a sane .htaccess file.
# - Clean up after the import, especially in the WXR case.
# - Secure the server and the WordPress installation.
# - Configure plugins.
#
# Notes on PHP
# ------------
#
# This uses Apache and mod_php rather than FastCGI, FCGID, or PHP-FPM, as all
# of those options have various issues as of Q2 2015.
#
# - Setting up APC to work well with FastCGI or FCGID is a pain.
# - Managing .htaccess directives with PHP-FPM is also a pain at present.
#
# For the purposes of running a WordPress server, having a reliable bytecode
# cache in the form of APC is more important than the benefits of the other
# options.
#

set -o nounset
set -o errexit

# ----------------------------------------------------------------------------
# EDIT CONFIGURATION BEFORE RUNNING
# ----------------------------------------------------------------------------

NAME="example"
TITLE="Example WordPress Installation"
HOST="example.com"

MYSQL_ROOT_PASS="password"
MYSQL_DATABASE="example"
MYSQL_USER="example"
MYSQL_PASS="password"

APACHE_USER="www-data"

WP_VERSION="4.1.1"
# Location for the WordPress installation.
WP_PATH="/var/www/html"

# Don't call the admin "admin". Some attacks try to log in as that user, so why
# make it easier for them to do that?
WP_ADMIN="exampleadmin"
WP_ADMIN_PASS="password"
WP_ADMIN_NAME="Example Administrator"
WP_ADMIN_EMAIL="exampleadmin@example.com"
WP_URL="https://example.com"

# Plugins to install and activate.
WP_PLUGINS=()
WP_PLUGINS+=( anti-spam )
WP_PLUGINS+=( autoptimize )
WP_PLUGINS+=( disable-comments )
WP_PLUGINS+=( disable-search )
WP_PLUGINS+=( easy-wp-smtp )
WP_PLUGINS+=( revision-control )
WP_PLUGINS+=( simple-trackback-disabler )
WP_PLUGINS+=( wp-super-cache )

# Option 1: No import.
WP_IMPORT=""

# Option 2: Import posts from a WXR file.
# Uncomment and set the values to use this option.
#WP_IMPORT="wxr"
#WP_WXR_FILE="/path/to/wxr-export.xml"

# Option 2: Load up a database.
# Uncomment and set the values to use this option.
#WP_IMPORT="sql"
#WP_MYSQL_BACKUP="/path/to/wordpress-mysqldump.sql"

# ----------------------------------------------------------------------------
# DO NOT EDIT BELOW THIS LINE (UNLESS YOU KNOW WHAT YOU ARE DOING)
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# Set the hostname.
# ----------------------------------------------------------------------------

echo "${HOST}" > /etc/hostname
hostname "${HOST}"

cat >> /etc/hosts <<EOF

127.0.0.1 ${HOST}
EOF

# ----------------------------------------------------------------------------
# Install packages.
# ----------------------------------------------------------------------------

# Get things up to date.
#apt-get update # already performed upstream
#apt-get upgrade -y

# We need a UUID package for this script.
apt-get install -y uuid

# Install necessary packages for a LAMP server.
#
# These lines prevent the mysql installation from derailing things by prompting
# for input.
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASS}"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASS}"
apt-get install -y lamp-server^

# WordPress prerequisites.
apt-get install -y \
curl \
php-apc \
php-pear \
php5-cli \
php5-curl \
php5-dev \
php5-gd \
php5-imagick \
php5-imap \
php5-mcrypt \
php5-mysqlnd \
php5-pspell \
php5-tidy \
php5-xmlrpc \

php5enmod \
apcu \
curl \
gd \
imagick \
imap \
mcrypt \
mysqlnd \
pspell \
tidy \
xmlrpc

# ----------------------------------------------------------------------------
# Defend against OpenSSL attacks.
# ----------------------------------------------------------------------------

# See https://weakdh.org/sysadmin.html for details.
#
# Since Apache is 2.4.7 here, you must append dhparams.pem to the end of the
# certificate file.
# openssl dhparam -out /etc/ssl/private/dhparams.pem 2048
openssl dhparam -out /etc/ssl/private/dhparams.pem 256 # for dev
sleep 2
chmod 600 /etc/ssl/private/dhparams.pem


# ----------------------------------------------------------------------------
# Create a snakeoil certificate and copy it.
# ----------------------------------------------------------------------------

# After setup the real certificate should be copied into place.
apt-get install -y ssl-cert
make-ssl-cert generate-default-snakeoil --force-overwrite
cp /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/${HOST}.pem
cp /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/${HOST}.key

# Append the dhparams.pem, only needed in Apache 2.4.7 - once 2.4.8 is out, 
# use SSLOpenSSLConfCmd DHParameters "{path to dhparams.pem}" in the Apache
# configuration instead. See https://weakdh.org/sysadmin.html for details.
cat /etc/ssl/private/dhparams.pem >> /etc/ssl/certs/${HOST}.pem

# ----------------------------------------------------------------------------
# MySQL setup.
# ----------------------------------------------------------------------------

mysql -uroot -p"${MYSQL_ROOT_PASS}" <<EOF
create database if not exists ${MYSQL_DATABASE} default character set utf8;
grant all on ${MYSQL_DATABASE}.* to '${MYSQL_USER}'@'localhost' identified by '${MYSQL_PASS}';
EOF

# ----------------------------------------------------------------------------
# Apache2 configuration.
# ----------------------------------------------------------------------------

# Some of the needed modules are not enabled by default, so enable them.
a2enmod \
expires \
headers \
rewrite \
ssl

# Remove insecure ciphers and protocols and enable perfect forward secrecy if
# all parties support it.
# See: https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
sed -i \
's/^\(\s*\)#\?\s*SSLProtocol.*/\1SSLProtocol ALL -SSLv2 -SSLv3/' \
/etc/apache2/mods-available/ssl.conf
sed -i \
's/^\(\s*\)#\?\s*SSLHonorCipherOrder\s.*/\1SSLHonorCipherOrder On/' \
/etc/apache2/mods-available/ssl.conf
sed -i \
's/^\(\s*\)#\?\s*SSLCipherSuite\s.*/\1SSLCipherSuite ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS/' \
/etc/apache2/mods-available/ssl.conf

# Set up the virtual hosts file.
#
# Note that some escaping of $ characters must happen in here. Some variables
# are provided from this script, but others actually have to be in the final
# configuration file.
cat > /etc/apache2/sites-available/${HOST}.conf <<EOF
<VirtualHost *:80>
ServerName ${HOST}

ServerAdmin webmaster@${HOST}
DocumentRoot /var/www/html

<Directory "/var/www/html">
Options FollowSymLinks
AllowOverride All
</Directory>

# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
# error, crit, alert, emerg.
LogLevel warn

ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

<IfModule mod_ssl.c>
<VirtualHost _default_:443>
ServerName ${HOST}
ServerAdmin webmaster@${HOST}
DocumentRoot /var/www/html

# Set the HTTP Strict Transport Security (HSTS) header to guarantee
# HTTPS for 1 Year, including subdomains, and allow this site to be
# added to the preload list.
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"

<Directory "/var/www/html">
Options FollowSymLinks
AllowOverride All
</Directory>

# Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
# error, crit, alert, emerg.
LogLevel warn

ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined

# SSL Engine Switch:
# Enable/Disable SSL for this virtual host.
SSLEngine on

# If both key and certificate are stored in the same file, only the
# SSLCertificateFile directive is needed.
SSLCertificateFile /etc/ssl/certs/${HOST}.pem
SSLCertificateKeyFile /etc/ssl/private/${HOST}.key

# Server Certificate Chain:
# Point SSLCertificateChainFile at a file containing the
# concatenation of PEM encoded CA certificates which form the
# certificate chain for the server certificate. Alternatively
# the referenced file can be the same as SSLCertificateFile
# when the CA certificates are directly appended to the server
# certificate for convenience.
#SSLCertificateChainFile /etc/apache2/ssl.crt/server-ca.crt

# Certificate Authority (CA):
# Set the CA certificate verification path where to find CA
# certificates for client authentication or alternatively one
# huge file containing all of them (file must be PEM encoded)
# Note: Inside SSLCACertificatePath you need hash symlinks
# to point to the certificate files. Use the provided
# Makefile to update the hash symlinks after changes.
#SSLCACertificatePath /etc/ssl/certs/
#SSLCACertificateFile /etc/apache2/ssl.crt/ca-bundle.crt

# Certificate Revocation Lists (CRL):
# Set the CA revocation path where to find CA CRLs for client
# authentication or alternatively one huge file containing all
# of them (file must be PEM encoded)
# Note: Inside SSLCARevocationPath you need hash symlinks
# to point to the certificate files. Use the provided
# Makefile to update the hash symlinks after changes.
#SSLCARevocationPath /etc/apache2/ssl.crl/
#SSLCARevocationFile /etc/apache2/ssl.crl/ca-bundle.crl

# Client Authentication (Type):
# Client certificate verification type and depth. Types are
# none, optional, require and optional_no_ca. Depth is a
# number which specifies how deeply to verify the certificate
# issuer chain before deciding the certificate is not valid.
#SSLVerifyClient require
#SSLVerifyDepth 10

# SSL Engine Options:
# Set various options for the SSL engine.
#SSLOptions +FakeBasicAuth +ExportCertData +StrictRequire
<FilesMatch "\.(cgi|shtml|phtml|php)\$">
SSLOptions +StdEnvVars
</FilesMatch>

# SSL Protocol Adjustments:
BrowserMatch "MSIE [2-6]" \
nokeepalive ssl-unclean-shutdown \
downgrade-1.0 force-response-1.0
# MSIE 7 and newer should be able to use keepalive
BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

</VirtualHost>
</IfModule>
EOF

# Disable the default host and enable this host.
a2dissite 000-default
a2ensite ${HOST}

# Turn off some of the unnecessary response headers.
sed -i \
"s/^ServerTokens\s.*/ServerTokens Prod/" \
/etc/apache2/conf-available/security.conf
sed -i \
"s/^ServerSignature\s.*/ServerSignature Off/" \
/etc/apache2/conf-available/security.conf

# ----------------------------------------------------------------------------
# PHP configuration.
# ----------------------------------------------------------------------------

# Turn off the expose_php setting.
sed -i "s/expose_php =.*/expose_php = Off/" /etc/php5/apache2/php.ini

# ----------------------------------------------------------------------------
# Other odds and ends.
# ----------------------------------------------------------------------------

# A fix for an annoying issue.
cat >> /etc/hosts <<EOF

# This may or may not prove necessary.
#
# As of Q2 2015 there is something cranky about the new api.wordpress.org name
# resolution and the WordPress code response to that, but it seems more likely
# to happen in Vagrant than elsewhere. You'll see errors containing the string
# "could not establish a secure connection to WordPress.org" when installing or
# using administrative functions when the problem occurs.
#
# Check that the IP address is still correct before enabling this.
#
# 66.155.40.202 api.wordpress.org
EOF

# ----------------------------------------------------------------------------
# Restart services.
# ----------------------------------------------------------------------------

service apache2 restart

# ----------------------------------------------------------------------------
# Install and configure Monit to keep things running.
# ----------------------------------------------------------------------------

apt-get install monit

cat > /etc/monit/conf.d/apache2 <<EOF
check process apache2 with pidfile /var/run/apache2.pid
group www
start program = "/etc/init.d/apache2 start"
stop program = "/etc/init.d/apache2 stop"
if failed host localhost port 80 protocol http
with timeout 10 seconds
then restart
if failed host localhost port 443 type tcpssl protocol http
with timeout 10 seconds
then restart
if 5 restarts within 5 cycles then timeout
EOF

cat > /etc/monit/conf.d/mysql <<EOF
check process mysqld with pidfile /var/run/mysqld/mysqld.pid
group database
start program = "/etc/init.d/mysql start"
stop program = "/etc/init.d/mysql stop"
if failed host localhost port 3306 protocol mysql then restart
if 5 restarts within 5 cycles then timeout
EOF

service monit restart

# ----------------------------------------------------------------------------
# Allow the ${APACHE_USER} user to login.
# ----------------------------------------------------------------------------

# This is useful for uploading files via SCP/SFTP such that they have the right
# ownership.
#
# Allow the ${APACHE_USER} user to log in, and give it a different home
# directory to hold .ssh and various dotfiles, etc.
mkdir /home/${APACHE_USER}
chown ${APACHE_USER}:${APACHE_USER} /home/${APACHE_USER}
sed -i \
"s/^\(${APACHE_USER}:.*\):\/var\/www:\/usr\/sbin\/nologin$/\1:\/home\/${APACHE_USER}:\/bin\/bash/" \
/etc/passwd

# ----------------------------------------------------------------------------
# Install WP-CLI.
# ----------------------------------------------------------------------------

curl -sS -O \
https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sleep 1
chmod a+x wp-cli.phar
mv wp-cli.phar /usr/bin/wp

# ----------------------------------------------------------------------------
# Run as much of the WordPress setup as possible without manual intervention.
# ----------------------------------------------------------------------------

# Note that in the Vagrant scenario all the files may already be present via a
# synced folder.

# Make sure that the ${APACHE_USER} user has rights to the location, and make sure
# that the location exists.
mkdir -p "${WP_PATH}"
chown ${APACHE_USER}:${APACHE_USER} "${WP_PATH}"
chmod 755 "${WP_PATH}"

# Obtain the code, don't overwrite an existing installation. This will return
# an error code in that case, so force a non-error exit code for this line.
su - ${APACHE_USER} \
-c "wp core download --path='${WP_PATH}' --version='${WP_VERSION}'" \
|| true

# Create a bare minimum wp-config.php file if there is no existing file.
if [ ! -f "${WP_PATH}/wp-config.php" ]; then
mv "${WP_PATH}/wp-config-sample.php" "${WP_PATH}/wp-config.php"
UUID=`uuid -v4`
sed -i \
"s/put your unique phrase here/${UUID}/" \
"${WP_PATH}/wp-config.php"

sed -i \
"s/define('DB_NAME', '[^']*');/define('DB_NAME', '${MYSQL_DATABASE}');/" \
"${WP_PATH}/wp-config.php"
sed -i \
"s/define('DB_USER', '[^']*');/define('DB_USER', '${MYSQL_USER}');/" \
"${WP_PATH}/wp-config.php"
sed -i \
"s/define('DB_PASSWORD', '[^']*');/define('DB_PASSWORD', '${MYSQL_PASS}');/" \
"${WP_PATH}/wp-config.php"
fi

# Install the WordPress schema.
su - ${APACHE_USER} -c "wp core install --path='${WP_PATH}' --url='${WP_URL}' --title='${TITLE}' --admin_user='admin' --admin_password='${WP_ADMIN_PASS}' --admin_email='admin@${HOST}'"

# What we're doing here is creating an initial admin user called "admin", then
# creating a new administrator with the desired name, then deleting the "admin"
# user. This has the effect of getting rid of the ID 1 user and giving it a name
# that isn't "admin", which is alleged to block some automated attacks.
su - ${APACHE_USER} -c "wp user create --path='${WP_PATH}' '${WP_ADMIN}' '${WP_ADMIN_EMAIL}' --user_pass='${WP_ADMIN_PASS}' --display_name='${WP_ADMIN_NAME}' --role=administrator --porcelain"
su - ${APACHE_USER} -c "wp user delete admin --path='${WP_PATH}' --yes"

# Install and activate plugins.
for WP_PLUGIN in "${WP_PLUGINS[@]}"; do
su - ${APACHE_USER} -c "wp plugin install ${WP_PLUGIN} --path='${WP_PATH}' --activate"
done

# ----------------------------------------------------------------------------
# Import a WXR export file.
# ----------------------------------------------------------------------------

# This expects the WordPress PHP code, including wp-config.php file, to be in
# place already with suitable configuration.
if [ "${WP_IMPORT}" == "wxr" ]; then
# Add the wordpress-importer plugin
su - ${APACHE_USER} -c "wp plugin install wordpress-importer --path='${WP_PATH}' --activate"

# Import the WXR file
#
# Note that using --authors=skip seems necessary, as other options cause
# errors. You will almost certainly have to tinker with things and clean up
# after the import.
su - ${APACHE_USER} -c "wp import --path='${WP_PATH}' --authors=skip '${WP_WXR_FILE}'"

# Deactivate the importer plugin.
su - ${APACHE_USER} -c "wp plugin deactivate wordpress-importer --path='${WP_PATH}'"
fi

# ----------------------------------------------------------------------------
# Import a complete database dump.
# ----------------------------------------------------------------------------

# This overwrites some of what was done already.
if [ "${WP_IMPORT}" == "sql" ]; then
mysql -u"${MYSQL_USER}" -p"${MYSQL_PASS}" ${MYSQL_DATABASE} < "${WP_MYSQL_BACKUP}"
fi