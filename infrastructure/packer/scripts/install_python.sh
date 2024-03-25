#!/bin/bash

dnf -y update
sudo dnf install -y tar curl gcc openssl-devel bzip2-devel libffi-devel zlib-devel wget make -y
wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz
tar -xf Python-3.10.0.tar.xz
cd Python-3.10.0
./configure --enable-optimizations
make -j 2
nproc
make altinstall
# install ansible
python3 -m pip install -U pip
pip install ansible