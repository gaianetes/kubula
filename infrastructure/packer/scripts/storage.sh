#!/bin/bash

storage_config() {
    sudo su -
    echo "iscsi_tcp" >/etc/modules-load.d/iscsi-tcp.conf
    systemctl enable iscsid --now
    
    cat <<EOF>> /etc/NetworkManager/conf.d/rke2-canal.conf
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:flannel*
EOF
    systemctl reload NetworkManager
    exit
}