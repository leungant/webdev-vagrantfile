#!/bin/bash

sudo apt-get install -y npm
sudo npm install n -g
sudo n latest




#On Ubuntu 14.04.5 LTSthe easier way is
#1 Install npm:
#sudo apt-get install npm
#Install n
#sudo npm install n -g
#Get latest version of node
#sudo n latest
#If you prefer to install a specific version of `node you can
#2.1 List available node versions
#n ls
#2.2 and the install a specific version
#sudo n 4.5.0