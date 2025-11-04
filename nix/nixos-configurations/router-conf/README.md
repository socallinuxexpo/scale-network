# Router features to implement

- [ ] SSH Server
- [ ] Logging
- [ ] nftables
  - [ ] MSS clamping
  - [ ] NAT
- [ ] IPv6 Router Advertisement
- [ ] LLDP
- [ ] Ipv6 tunnel broker

# Things to remember

- [ ] Increase size of neighbor tables. This is important because we are operating a larged bridged network that will fill up these caches pretty easily.
- [ ] Add monitoring for neighbor table size

# Things to Monitor

- [ ] NAT port usage

# Running the VM with multiple interfaces

```
./result/bin/run-router-border-vm \
    -netdev user,id=net1 -device virtio-net-pci,netdev=net1,mac=52:54:00:12:00:02 \
    -netdev user,id=net2 -device virtio-net-pci,netdev=net2,mac=52:54:00:12:00:03
```
