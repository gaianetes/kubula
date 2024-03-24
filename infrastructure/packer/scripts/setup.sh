#!/bin/bash

scripts=(
    common.sh
    firewall.sh
    storage.sh
    rke2.sh
    cilium.sh
)
for script in "${scripts[@]}"; do
    source $script
done

network_config() {
    info "Configuring network preferences..."
    sudo modprobe br_netfilter
    sudo modprobe overlay
    sudo su -
    cat <<EOT | sudo tee /etc/modules-load.d/kubernetes.conf
br_netfilter
overlay
EOT
cat <<EOT | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOT
    sysctl --system
    exit
}

kernel_config() {
    info "Updating Kernel..."
    sudo apt-get update --refresh
    sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    sudo dnf install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
    sudo dnf --enablerepo=elrepo-kernel install -y kernel-ml kernel-ml-core kernel-ml-headers kernel-ml-modules kernel-ml-modules-extra
}

selinux_config() {
    info "Configuring SELinux..."
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
}


main() {
    network_config
    firewall_config
    kernel_config
    selinux_config
    storage_config
    setup_rke2
    setup_cilium
}

main