#!/bin/bash

sudo dnf update -y
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y tar vim


sudo dnf update -y
sudo dnf install -y gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget tar vim
wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tgz
tar xzf Python-3.11.0.tgz
cd Python-3.11.0
./configure --enable-optimizations
make altinstall
sudo alternatives --install /usr/bin/python3 python3 /usr/local/bin/python3.11 1

echo "Update pip"
python3.11 -m pip install --upgrade pip
echo "Install Ansible"
pip install ansible
sudo dnf install -y nfs-utils
sudo mkdir -p /mnt/storage