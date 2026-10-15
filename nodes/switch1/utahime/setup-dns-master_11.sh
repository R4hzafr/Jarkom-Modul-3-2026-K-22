#!/bin/bash
set -Eeuo pipefail

# ==========================================
# MODUL 3 - SOAL 11
# DNS MASTER: UTAHIME
# Domain: jujutsu.K22.com
# ==========================================

DOMAIN="jujutsu.K22.com"
MASTER_IP="192.222.1.2"
SLAVE_IP="192.222.1.3"
ZONE_FILE="/etc/bind/db.jujutsu.K22.com"
LOCAL_CONF="/etc/bind/named.conf.local"

if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] Jalankan sebagai root."
    exit 1
fi

echo "=== DNS MASTER: UTAHIME ==="

# 1. Persiapan jaringan
ip link set eth0 up
ip addr replace "${MASTER_IP}/24" dev eth0
ip route replace default via 192.222.1.1

# 2. Instalasi BIND9
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    bind9 bind9-utils bind9-dnsutils

# 3. Tentukan serial zona
SERIAL="2026101401"

if [ -f "$ZONE_FILE" ]; then
    OLD_SERIAL=$(sed -nE \
        '/SOA/,/)/s/^[[:space:]]*([0-9]{10})[[:space:]]*;.*/\1/p' \
        "$ZONE_FILE" | head -n 1)

    if [[ "$OLD_SERIAL" =~ ^[0-9]{10}$ ]]; then
        SERIAL=$((10#$OLD_SERIAL + 1))
    fi
fi

# 4. Konfigurasi DNS Master dan zone transfer
cat > "$LOCAL_CONF" <<EOF
zone "${DOMAIN}" {
    type master;
    file "${ZONE_FILE}";
    allow-query { any; };
    allow-transfer { ${SLAVE_IP}; };
    also-notify { ${SLAVE_IP}; };
    notify yes;
};
EOF

# 5. SOA dan NS records
cat > "$ZONE_FILE" <<EOF
\$TTL 86400
@   IN SOA ns1.jujutsu.K22.com. hostmaster.jujutsu.K22.com. (
        ${SERIAL} ; Serial
        3600      ; Refresh
        900       ; Retry
        1209600   ; Expire
        86400     ; Negative Cache TTL
)

    IN NS ns1.jujutsu.K22.com.
    IN NS ns2.jujutsu.K22.com.

ns1 IN A ${MASTER_IP}
ns2 IN A ${SLAVE_IP}
EOF

# 6. Validasi sebelum reload/start
echo "=== VALIDASI ==="
named-checkconf
named-checkzone "$DOMAIN" "$ZONE_FILE"

# 7. Jalankan atau reload BIND9
mkdir -p /run/named
chown bind:bind /run/named

if pgrep -x named >/dev/null; then
    kill -HUP "$(pgrep -xo named)"
    echo "[OK] Konfigurasi BIND9 di-reload."
else
    named -u bind -c /etc/bind/named.conf
    sleep 2

    if ! pgrep -x named >/dev/null; then
        echo "[ERROR] BIND9 gagal berjalan."
        exit 1
    fi

    echo "[OK] BIND9 berhasil dijalankan."
fi

# 8. Uji query Master
echo "=== TEST SOA ==="
dig @"${MASTER_IP}" "$DOMAIN" SOA +noall +answer

echo "=== TEST NS ==="
dig @"${MASTER_IP}" "$DOMAIN" NS +noall +answer

echo "[SELESAI] DNS Master selesai dikonfigurasi."