#!/bin/bash
set -Eeuo pipefail

# ==================================================
# SOAL 12 - DNS MASTER UTAHIME
# Domain : jujutsu.K22.com
# Master : 192.222.1.2
# Gojo   : 192.222.1.4
# Slave  : 192.222.1.3
# Gateway: 192.168.122.1
# ==================================================

DOMAIN="jujutsu.K22.com"
MASTER_IP="192.222.1.2"
SLAVE_IP="192.222.1.3"
GOJO_IP="192.222.1.4"
GATEWAY_IP="192.168.122.1"

FORWARD_ZONE="/etc/bind/db.jujutsu.K22.com"
REVERSE_ZONE="/etc/bind/db.192.222.1"
NAMED_LOCAL="/etc/bind/named.conf.local"
NAMED_OPTIONS="/etc/bind/named.conf.options"

echo "=== KONFIGURASI DNS MASTER SOAL 12 ==="

# --------------------------------------------------
# 1. Pastikan file zona forward tersedia
# --------------------------------------------------
if [[ ! -f "$FORWARD_ZONE" ]]; then
    echo "[ERROR] Zona forward tidak ditemukan: $FORWARD_ZONE"
    exit 1
fi

# --------------------------------------------------
# 2. Tambahkan A record dan CNAME
# --------------------------------------------------
if ! grep -Eq '^[[:space:]]*@?[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.222\.1\.4([[:space:]]|$)' "$FORWARD_ZONE" &&
   ! grep -Eq '^[[:space:]]*jujutsu\.K22\.com\.?[[:space:]]+IN[[:space:]]+A[[:space:]]+192\.222\.1\.4([[:space:]]|$)' "$FORWARD_ZONE"; then
    echo "@       IN      A       ${GOJO_IP}" >> "$FORWARD_ZONE"
fi

if ! grep -Eq '^[[:space:]]*www[[:space:]]+IN[[:space:]]+CNAME[[:space:]]+jujutsu\.K22\.com\.?([[:space:]]|$)' "$FORWARD_ZONE"; then
    echo "www     IN      CNAME   ${DOMAIN}." >> "$FORWARD_ZONE"
fi

# Naikkan serial SOA satu kali jika masih serial sebelumnya.
# Script ini dirancang untuk serial nomor 11: 2026101402.
if grep -q '2026101402' "$FORWARD_ZONE"; then
    sed -i 's/2026101402/2026101403/' "$FORWARD_ZONE"
fi

# --------------------------------------------------
# 3. Buat zona Reverse DNS
# --------------------------------------------------
cat > "$REVERSE_ZONE" <<EOF
\$TTL 86400
@   IN  SOA ns1.${DOMAIN}. hostmaster.${DOMAIN}. (
        2026101401
        3600
        900
        1209600
        86400
)
@   IN  NS  ns1.${DOMAIN}.
@   IN  NS  ns2.${DOMAIN}.

4   IN  PTR ${DOMAIN}.
EOF

# --------------------------------------------------
# 4. Daftarkan zona Reverse DNS jika belum ada
# --------------------------------------------------
if ! grep -q 'zone "1.222.192.in-addr.arpa"' "$NAMED_LOCAL"; then
    cat >> "$NAMED_LOCAL" <<EOF

zone "1.222.192.in-addr.arpa" {
    type master;
    file "${REVERSE_ZONE}";
    allow-query { any; };
    allow-transfer { ${SLAVE_IP}; };
    also-notify { ${SLAVE_IP}; };
    notify yes;
};
EOF
fi

# --------------------------------------------------
# 5. Tambahkan DNS Forwarder ke gateway internet
# --------------------------------------------------
cat > "$NAMED_OPTIONS" <<EOF
options {
    directory "/var/cache/bind";

    forwarders {
        ${GATEWAY_IP};
    };

    forward only;
    dnssec-validation auto;
    listen-on { any; };
    listen-on-v6 { any; };
    allow-query { any; };
};
EOF

# --------------------------------------------------
# 6. Validasi konfigurasi
# --------------------------------------------------
echo "=== VALIDASI KONFIGURASI ==="
named-checkconf
named-checkzone "$DOMAIN" "$FORWARD_ZONE"
named-checkzone "1.222.192.in-addr.arpa" "$REVERSE_ZONE"

# --------------------------------------------------
# 7. Reload BIND9 yang berjalan manual
# --------------------------------------------------
if pgrep -x named >/dev/null; then
    kill -HUP "$(pgrep -xo named)"
    echo "[OK] Konfigurasi BIND9 berhasil dimuat ulang."
else
    mkdir -p /run/named
    chown bind:bind /run/named
    named -u bind -c /etc/bind/named.conf
    echo "[OK] BIND9 dijalankan secara manual."
fi

echo "=== KONFIGURASI DNS MASTER SOAL 12 SELESAI ==="
