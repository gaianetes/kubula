#!/bin/sh

pip3 uninstall ansible -y
dnf -y clean all

# Remove Virtualbox specific files

rm -rf /usr/src/vboxguest* /usr/src/virtualbox-ose-guest*
rm -rf *.iso *.iso.? /tmp/vbox /home/vagrant/.vbox_version

# Cleanup log files
find /var/log -type f | while read f; do echo -ne '' > $f; done;

# remove under tmp directory
rm -rf /tmp/*

# remove interface persistent
rm -f /etc/udev/rules.d/70-persistent-net.rules

for ifcfg in $(ls /etc/sysconfig/network-scripts/ifcfg-*)
do
    if [ "$(basename ${ifcfg})" != "ifcfg-lo" ]
    then
        sed -i '/^UUID/d'   /etc/sysconfig/network-scripts/ifcfg-enp0s3
        sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-enp0s3
    fi
done

dd if=/dev/zero of=/EMPTY bs=1M
rm -rf /EMPTY

echo "Uninstalling Python"
dnf remove python39 -y
# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
# sync