#!/bin/bash
if [[ $1 == "onvagrant" ]] 
then export SCRIPTS_PATH='/vagrant/' 
else export SCRIPTS_PATH='./' 
fi

sudo apt-get update


sudo apt-get install git
sudo apt-get install dos2unix

#wget -qO- https://get.docker.com/ | sh
#sudo usermod -aG docker $(whoami)

sudo apt-get -y install python-pip
sudo pip install virtualenv
sudo pip install virtualenvwrapper
source `which virtualenvwrapper.sh`
echo "source `which virtualenvwrapper.sh`" >> ~/.bashrc # TODO check if required.


${SCRIPTS_PATH}/install-node.sh

# Install Python version manager p
npm install -g pyvm

# install Postgres database
${SCRIPTS_PATH}/install-pg.sh
sudo apt-get -y install postgresql-client

# Install wordpress (and mysql and LAMP)

${SCRIPTS_PATH}/install-wp.sh

# Install Sublime Text Editor and required libraries

${SCRIPTS_PATH}/install-sublime.sh


# install wordpress with docker compose (only works for 64 bit clients)
#mkvirtualenv docker # required due to dependency conflicts
#sudo pip install docker-compose
# git clone https://github.com/leungant/django-docker # todo migrate to wh. 
#docker-compose up
#sudo apt-get install ansible -y 


# Update Ruby
#command curl -sSL https://rvm.io/mpapis.asc | gpg --import -
#\curl -L https://get.rvm.io | bash -s stable --ruby
#rvm get stable --autolibs=enable
#rvm install ruby
#rvm --default use ruby-2.3.1
