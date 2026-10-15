#!/bin/bash
# NOMOR 10 - pemulihan jaringan dan server DHCP setelah restart container
set -e
exec > >(tee -a /root/no10-tengen-run.log) 2>&1
echo "[TENGEN] Pemulihan dimulai: $(date)"
bash /root/tengen-net.sh
bash /root/dhcp-base.sh
bash /root/dhcp-net2.sh
bash /root/dhcp-net3.sh
dhcpd -t -cf /etc/dhcp/dhcpd.conf
pgrep -a -x dhcpd
ip -4 addr show eth0
ip route
echo '[OK] tengen: DHCP Server aktif'
