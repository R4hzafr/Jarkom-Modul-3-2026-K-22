#!/bin/bash
set -Eeuo pipefail

GOJO_IP="192.222.1.4"
WEB_PORT="80"

apt-get update
apt-get install -y iptables

# Izinkan loopback dan koneksi yang sudah terbentuk
iptables -C INPUT -i lo -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 1 -i lo -j ACCEPT

iptables -C INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 2 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Izinkan Gojo mengakses web worker
iptables -C INPUT -p tcp -s "$GOJO_IP" --dport "$WEB_PORT" -j ACCEPT 2>/dev/null ||
    iptables -I INPUT 3 -p tcp -s "$GOJO_IP" --dport "$WEB_PORT" -j ACCEPT

# Tolak akses HTTP langsung dari sumber lain
iptables -C INPUT -p tcp --dport "$WEB_PORT" -j DROP 2>/dev/null ||
    iptables -A INPUT -p tcp --dport "$WEB_PORT" -j DROP

echo "=== WEB WORKER FIREWALL: $(hostname) ==="
iptables -L INPUT -n -v --line-numbers