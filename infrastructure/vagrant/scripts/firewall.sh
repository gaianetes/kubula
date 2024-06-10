#!/bin/bash

ALLOWED_PORTS=(6443 9100 8080 4245 9345 6443 6444 10250 10259 10257 2379 2380 9796 19090 9090 6942 9091 4244 4240 80 443 9963 9964 8081 8082 7000 9001 6379 9121 8084 6060 6061 6062 9879 9890 9891 9892 9893 9962 9966)
for i in "${ALLOWED_PORTS[@]}"; do
  sudo firewall-cmd --add-port=$i/tcp --permanent
done

sudo firewall-cmd --add-port=30000-32767/tcp --permanent
sudo firewall-cmd --remove-icmp-block=echo-request --permanent
sudo firewall-cmd --remove-icmp-block=echo-reply --permanent
# Since we are using Cilium with GENEVE as overlay, we need the following port too:
# UDP
UDP_PORTS=(8472 4789 6081 51871 53 55355 58467 41637 39291 38519 46190)
for i in "${UDP_PORTS[@]}"; do
  sudo firewall-cmd --add-port=$i/udp --permanent
done
sudo firewall-cmd --reload
### Ingress Controller specific ports

### To get DNS resolution working, simply enable Masquerading.
sudo firewall-cmd --zone=public --add-masquerade --permanent

sudo firewall-cmd --zone=trusted --permanent --add-source=192.168.0.0/16

### Finally apply all the firewall changes
sudo firewall-cmd --reload
