#!/bin/bash

sudo su -
yum install -y nano curl wget git tmux jq vim-common iscsi-initiator-utils
echo "iscsi_tcp" >/etc/modules-load.d/iscsi-tcp.conf
systemctl enable iscsid --now
systemctl start iscsid
cat <<-EOF >/etc/NetworkManager/conf.d/rke2-canal.conf
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:flannel*
EOF
systemctl reload NetworkManager
exit
