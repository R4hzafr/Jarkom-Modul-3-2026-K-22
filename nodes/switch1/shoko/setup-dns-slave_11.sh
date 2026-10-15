#!/bin/bash
set -Eeuo pipefail

DOMAIN="jujutsu.K22.com"
MASTER_IP="192.222.1.2"
SLAVE_IP="192.222.1.3"

echo "=== DNS SLAVE: SHOKO ==="

echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y bind9 bind9-utils bind9-dnsutils

# Konfigurasi IP statis Network 1
ip link set eth0 up
ip addr replace "${SLAVE_IP}/24" dev eth0
ip route replace default via 192.222.1.1

# Direktori penyimpanan secondary zone
mkdir -p /var/cache/bind
chown bind:bind /var/cache/bind

# Konfigurasi DNS Slave
cat > /etc/bind/named.conf.local <<EOF
zone "${DOMAIN}" {
    type secondary;
    file "/var/cache/bind/db.jujutsu.K22.com";
    primaries { ${MASTER_IP}; };
    allow-query { any; };
};
EOF

echo "=== VALIDASI KONFIGURASI ==="
named-checkconf

echo "=== SIAPKAN RUNTIME DIRECTORY ==="
mkdir -p /run/named
chown bind:bind /run/named

echo "=== JALANKAN BIND9 ==="
if pgrep -x named >/dev/null; then
    pkill -x named
    sleep 1
fi

named -u bind -c /etc/bind/named.conf
sleep 2

echo "=== CEK PROSES ==="
pgrep -a named

echo "=== UJI QUERY SLAVE ==="
dig @"${SLAVE_IP}" "${DOMAIN}" SOA +noall +answer
dig @"${SLAVE_IP}" "${DOMAIN}" NS +noall +answer

echo "[SELESAI] Konfigurasi DNS Slave diterapkan."