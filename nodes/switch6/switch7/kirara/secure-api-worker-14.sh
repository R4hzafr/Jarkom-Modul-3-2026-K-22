#!/bin/bash
set -Eeuo pipefail

GETO_IP="192.222.4.5"
API_PORT="8080"

apt-get update
apt-get install -y iptables

# Izinkan trafik loopback
iptables -C INPUT -i lo -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 1 -i lo -j ACCEPT

# Izinkan koneksi yang sudah terbentuk
iptables -C INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 2 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Hanya Geto yang boleh memulai koneksi ke port API
iptables -C INPUT -p tcp -s "$GETO_IP" --dport "$API_PORT" -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 3 -p tcp -s "$GETO_IP" --dport "$API_PORT" -j ACCEPT

# Tolak sumber lain ke port API
iptables -C INPUT -p tcp --dport "$API_PORT" -j DROP 2>/dev/null ||
    iptables -A INPUT -p tcp --dport "$API_PORT" -j DROP

echo "=== API WORKER FIREWALL SELESAI: $(hostname) ==="
iptables -L INPUT -n -v --line-numbers