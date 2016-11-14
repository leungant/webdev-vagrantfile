#!/bin/bash
# installs sublime and required libraries and also xterm and dos2unix which are likely to be required

sudo apt-get install -y xterm
sudo apt-get install -y dos2unix

subl_url=`curl https://sublimetext.com/3 | grep 'dl_linux_64' | sed   -e 's/.*\(https.*amd64.deb\).*/\1/g' | grep https`
subl_deb=`curl https://sublimetext.com/3 | grep 'dl_linux_64' | sed   -e 's/.*https.*\/\(.*amd64.deb\).*/\1/g' | grep deb`

mv $subl_deb $subl_deb.backup
wget $subl_url # https://download.sublimetext.com/sublime-text_build-3126_i386.deb
echo $subl_deb

sudo dpkg -i $subl_deb # sublime-text_build-3126_i386.deb
sudo apt-get install -y libgtk2.0
 
