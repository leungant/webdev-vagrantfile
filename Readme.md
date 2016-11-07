+ 
WORK-ANYWHERE WEB DEVELOPMENT VAGRANTFILE:
==========================================

PURPOSE + JUSTIFICATION:
========================
+ Create VM environment with common webdev tools already set up. 
+ Useful for hack or meetup crew setups where you can get started developing quickly.
+ Designed to "just work" so any odd looking choices and combinations are most likely due to support for as wide a range of  OSes/architectures as possible.

+ Add your code fetching steps to the install.sh file.

+ Use the bash scripts to ensure similar setups on a linux machine.. though the theory is you're a whizz at installing packages on a linux machine if you run linux!

+ /home/vagrant/files on the VM is mapped to the Windows Vagrantfile directory, you can access and transfer files there, and use your windows development tools with the files on the virtual box.

+ Docker layer may come soon.. Especially if Docker and Docker machine support 32 bit.. Will be Docker Swarm scripts.



INSTALLATION:
=============

1. Download and install Vagrant https://www.vagrantup.com/downloads.html
2. Download and install Virtualbox https://www.virtualbox.org/wiki/Downloads
3. Make a local directory, and in that directory open an ADMINISTRATOR command prompt:
```
git clone https://github.com/leungant/webdev-vagrantfile
cd wh
vagrant up   (with admin privileges!)
```
Administrator privilege is required for the vagrant up step to allow symbolic links to be made, this is very important if you are interacting with javascript and node/npm, or drupal etc, less so if you know you are not.

This will download the initial 32-bit Ubuntu linux image, then set up the machine so it's ready for web dev. After this first time, "vagrant up" will be relatively snappy.

While you're waiting and on windows:

7. Download and install putty (https://the.earth.li/~sgtatham/putty/latest/x86/putty-0.67-installer.msi) + an X Server (https://sourceforge.net/projects/vcxsrv/) if you wish to use graphical applications on the box (e.g. Sublime Text), or just mobaxterm on its own (https://mobaxterm.mobatek.net/download-home-edition.html) for both an SSH client and an X Server combined.

After VM creation is complete, type 
vagrant ssh 
to get login details to your locally hosted vagrant machine.

Typically this is hostname: localhost, port: 2222, user: vagrant, password: vagrant

Login, et voila, a webdev box ready to go.

