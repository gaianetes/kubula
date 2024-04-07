# Migrate from MetalLB to Cilium

This document will serve as a (very) minimal guide to get Cilium to perform IPAM and BGP advertisement so you can expose Kubernetes Services without needing to use a cloud load balancer. 

## Prerequisites

- Kubernetes cluster
- Cilium
- [FRR](https://frrouting.org/)
- Helm

* Please refer to this [guide](https://mitchmurphy.io/cilium-rke2/) to get your cluster provisioned and Cilium installed. 
* FRR can simply be installed with `sudo yum install frr -y`

There needs to be a few configuration changes made to get FRR to function propery:

- Turn on `bgpd`: `sed -i 's/bgpd=no/bgpd=yes/g'`
- Create `/etc/frr/frr.conf` file (shown [here](frr.conf))
    - Make the necessary changes to IP addresses and ASNs (configured [here](./bgp-peering.yaml))
- `sudo systemctl restart frr`

1. Create [CiliumLoadBalancerIPPool](ip-pool.yaml)
2. Create [CiliumBGPPeeringPolicy](bgp-peering.yaml)
3. Create sample [service](web.yaml)

_Note_: more to follow.