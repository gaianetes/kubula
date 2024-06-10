#!/bin/bash

# first argument is the server IP
# ensure that 3 arguments are passed
if [ "$#" -ne 3 ]; then
  echo "Illegal number of parameters"
  echo "Usage: $0 <server_ip> <token> <rke2_type>"
  exit 1
fi
server_ip=$1
token=$2
rke2_type=$3

sudo mkdir -p /etc/rancher/rke2

curl -sfL https://get.rke2.io | sudo INSTALL_RKE2_CHANNEL=latest INSTALL_RKE2_TYPE="${rke2_type}" sh -
# if rke2_type is server, then start the server
if [ "${rke2_type}" == "server" ]; then
  sudo systemctl start rke2-server.service --now
  cat <<-EOF >/etc/profile.d/rke2.sh
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml PATH=/usr/local/bin:$PATH:/var/lib/rancher/rke2/bin
alias k=kubectl
EOF
fi
# if rke2_type is agent, then start the agent
if [ "${rke2_type}" == "agent" ]; then
cat <<-EOF >/etc/rancher/rke2/config.yaml
server: https://$server_ip:9345
token: $token
EOF
  sudo systemctl start rke2-agent.service --now
fi
