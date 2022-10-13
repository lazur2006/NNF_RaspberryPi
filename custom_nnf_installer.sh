#!/bin/sh

# installing raspberian lite os to sd flash drive
# ssh connection setup via raspberrypi imager
# copy installer to home dir --> scp /Users/***/***/custom_nnf_installer.sh user@xxx.xxx.xxx.xxx:~/
#
# start script with --> "bash custom_nnf_installer.sh"
# change device hostname via "sudo nano /etc/hostname" --> hostname should be "eat" (eat.local)
# make a restart via "sudo shutdown -r now"

deviceipaddress="$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')"
username="$(echo $USER)"
sudo apt-get install python3.9 --assume-yes
sudo apt install python3-pip --assume-yes
sudo apt-get install python3-venv --assume-yes
sudo apt-get install libatlas-base-dev --assume-yes
sudo apt-get install nginx --assume-yes
sudo apt-get install git --assume-yes
sudo apt install avahi-daemon --assume-yes

mkdir -p ~/git
cd ~/git
git clone https://github.com/lazur2006/NNF.git
cd NNF
python3 -m venv menv
source ./menv/bin/activate
pip install -r requirements.txt
touch ~/git/NNF/log.log
sudo chown -R $username:$username ~/git/NNF
deactivate
cd ~
printf "[Unit]\nDescription=Flask Web Application Server using Gunicorn\nAfter=network.target\n\n[Service]\nUser=$username\nGroup=$username\nWorkingDirectory=/home/$username/git/NNF\nEnvironment="PATH=/home/$username/git/NNF/menv/bin"\nExecStart=sudo /bin/bash -c 'mkdir -p /tmp/my-server; source /home/$username/git/NNF/menv/bin/activate; gunicorn -w 1 -k gthread --thread=8 --bind unix:/tmp/my-server/ipc.sock app:app --preload --error-logfile /home/$username/git/NNF/log.log --capture-output --log-level debug;'\n\nRestart=always\n\n[Install]\nWantedBy=multi-user.target\n" | sudo tee /etc/systemd/system/my-server.service
mkdir -p /tmp/my-server
printf "server {\nlisten 80;\nlisten [::]:80;\nserver_name $(hostname).local;\n\nlocation / {\nproxy_buffering off;\nproxy_cache off;\nproxy_set_header Connection '';\nproxy_http_version 1.1;\nchunked_transfer_encoding off;\ninclude proxy_params;\nproxy_pass http://unix:/tmp/my-server/ipc.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/my-server
sudo nginx -t
sudo ln -s /etc/nginx/sites-available/my-server /etc/nginx/sites-enabled/
sudo ls -l  /etc/nginx/sites-enabled/
sudo systemctl disable my-server --now
sudo systemctl enable my-server --now
sudo nginx -s reload
sudo service avahi-daemon restart
