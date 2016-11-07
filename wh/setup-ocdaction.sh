#!/bin/bash
cd /home/vagrant/files/
git clone https://github.com/womenhackfornonprofits/ocdaction
cd ocdaction/frontend
sudo gem install sass
npm install  # --no-bin-links
grunt default &
cd ..
sudo pip install -r requirements.txt
sudo -u postgres createdb ocdaction 
python ocdaction/manage.py migrate
cd ocdaction
echo "Run server with: python manage.py runserver"


