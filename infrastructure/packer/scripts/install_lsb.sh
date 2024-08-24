#!/bin/bash

# update sudoers.d to not ask for password for rke2 user
sudo echo "rke2 ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/rke2
# reload rke2 user
sudo su - rke2

# need to install lsb for ansible to work
sudo dnf install -y yum-utils
sudo dnf config-manager --set-enabled devel
sudo dnf update -y
sudo dnf install redhat-lsb-core