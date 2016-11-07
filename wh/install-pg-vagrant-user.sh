#!/bin/sh -e
# Set up vagrant user

cat << EOF | su - postgres -c psql
-- Create the database user:
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASS';

CREATE USER vagrant WITH PASSWORD 'vagrant';

-- Create the database:
CREATE DATABASE $APP_DB_NAME WITH OWNER=$APP_DB_USER
                                  LC_COLLATE='en_US.utf8'
                                  LC_CTYPE='en_US.utf8'
                                  ENCODING='UTF8'
                                  TEMPLATE=template0;
CREATE DATABASE vagrant;
EOF


sudo -u $APP_DB_USER psql -c "ALTER USER vagrant with SUPERUSER;"
sudo -u postgres psql -c "ALTER USER vagrant PASSWORD 'vagrant';"