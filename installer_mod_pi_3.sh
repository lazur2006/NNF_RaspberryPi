#!/bin/sh

# installing raspberian lite os to sd flash drive
# ssh connection setup via raspberrypi imager
# copy installer to home dir --> scp /Users/***/***/custom_nnf_installer.sh user@xxx.xxx.xxx.xxx:~/
#
# start script with --> "bash custom_nnf_installer.sh"
# change device hostname via "sudo nano /etc/hostname" --> hostname should be "eat" (eat.local)
# make a restart via "sudo shutdown -r now"

deviceipaddress="$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')"

sudo apt-get install python3 --assume-yes
sudo apt install python3-pip --assume-yes
sudo apt-get install python3-venv --assume-yes
sudo apt-get install libatlas-base-dev --assume-yes
sudo apt-get install python3-numpy --assume-yes
sudo apt-get install nginx --assume-yes
sudo apt-get install git --assume-yes
sudo apt install avahi-daemon --assume-yes

mkdir -p ~/git
cd ~/git
git clone https://github.com/lazur2006/NNF.git
cd NNF
python3 -m venv --system-site-packages menv
source ./menv/bin/activate
pip install Flask==2.1.2 flask_classful python_picnic_api qrcode requests tqdm urllib3 gunicorn python-dotenv werkzeug==2.1.2 gitpython cryptography
touch ~/git/NNF/log.log
sudo chown $USER:$USER log.log
sudo chown -R $USER:$USER ~/git/NNF
deactivate
cd ~
username=$USER
printf -v service "
[Unit]
Description=Flask Web Application Server using Gunicorn
After=network.target

[Service]
User=%s
Group=%s
WorkingDirectory=/home/%s/git/NNF
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ExecStartPre=/bin/mkdir -p /tmp/my-server
ExecStartPre=/bin/chown %s:%s /tmp/my-server
ExecStart=/home/%s/git/NNF/menv/bin/gunicorn -w 1 -k gthread --thread=8 --bind unix:/tmp/my-server/ipc.sock app:app --preload --error-logfile /home/%s/git/NNF/log.log --capture-output --log-level debug

Restart=always

[Install]
WantedBy=multi-user.target
" $username $username $username $username $username $username $username $username

echo "$service" | sudo tee /etc/systemd/system/my-server.service
sudo chown $USER:$USER my-server.service

mkdir -p /tmp/my-server
sudo chown $USER:$USER /tmp/my-server/

printf "server {\nlisten 80;\nlisten [::]:80;\nserver_name $deviceipaddress $(hostname).local;\n\nlocation / {\nproxy_buffering off;\nproxy_cache off;\nproxy_set_header Connection '';\nproxy_http_version 1.1;\nchunked_transfer_encoding off;\ninclude proxy_params;\nproxy_pass http://unix:/tmp/my-server/ipc.sock;\n}\n}" | sudo tee /etc/nginx/sites-available/my-server
sudo nginx -t
sudo ln -s /etc/nginx/sites-available/my-server /etc/nginx/sites-enabled/
sudo ls -l  /etc/nginx/sites-enabled/
sudo systemctl disable my-server --now
sudo systemctl enable my-server --now
sudo nginx -s reload
sudo service avahi-daemon restart
