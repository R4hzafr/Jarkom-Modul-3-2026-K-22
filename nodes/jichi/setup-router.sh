#!/bin/bash
# NOMOR 1 - konfigurasi router jichi (rekonstruksi berdasarkan topologi yang berhasil)
# Jalankan: bash /root/setup-router.sh
set -e
WAN_IP="192.168.122.103/24"
WAN_GW="192.168.122.1"
for IFACE in eth0 eth1 eth2 eth3 eth4; do
    ip link set "$IFACE" up
done
ip addr replace "$WAN_IP" dev eth0
ip route replace default via "$WAN_GW" dev eth0
for NET in 1 2 3 4; do
    IFACE="eth${NET}"
    ip addr replace "192.222.${NET}.1/24" dev "$IFACE"
done
sysctl -w net.ipv4.ip_forward=1
if ! command -v iptables >/dev/null 2>&1; then
    apt-get install -y iptables
fi
iptables -t nat -C POSTROUTING -s 192.222.0.0/16 -o eth0 -j MASQUERADE 2>/dev/null || \
    iptables -t nat -A POSTROUTING -s 192.222.0.0/16 -o eth0 -j MASQUERADE
echo '[OK] jichi: interface internal, WAN, forwarding, NAT siap'
ip -4 -br addr
ip route
iptables -t nat -S POSTROUTING
