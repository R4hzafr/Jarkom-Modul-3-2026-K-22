#!/bin/bash
# NOMOR 10 - pemulihan dari /root untuk Docker GNS3
set -e
exec > >(tee -a /root/no10-jichi-run.log) 2>&1
echo "[JICHI] Pemulihan dimulai: $(date)"
# setup-router juga menyetel WAN dan NAT; perintah eksplisit WAN ditampilkan demi dokumentasi.
bash /root/setup-router.sh
ip addr replace 192.168.122.103/24 dev eth0
ip route replace default via 192.168.122.1 dev eth0
bash /root/relay.sh
sysctl net.ipv4.ip_forward
iptables -t nat -S POSTROUTING
pgrep -a -x dhcrelay
echo '[OK] jichi: DHCP Relay aktif'
