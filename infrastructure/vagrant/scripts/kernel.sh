#!/bin/sh

sudo dnf -y upgrade --refresh
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo dnf install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
sudo dnf --enablerepo=elrepo-kernel install -y kernel-ml #kernel-ml-{core,headers,modules,modules-extra}
# set the new kernel as the default
sudo grubby --set-default /boot/vmlinuz-$(rpm -q kernel-ml --qf "%{version}-%{release}.$(uname -m)\n")
