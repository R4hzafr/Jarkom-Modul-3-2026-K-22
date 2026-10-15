#!/bin/bash
# NOMOR 2 - master config konsisten; hanya dhcp-base menulis dhcpd.conf.
# Tidak menghapus kebijakan net2.conf dan net3.conf jika sudah dibuat.
set -e
if ! command -v dhcpd >/dev/null 2>&1; then apt-get install -y isc-dhcp-server; fi
mkdir -p /etc/dhcp /var/lib/dhcp
touch /var/lib/dhcp/dhcpd.leases
# Scope awal tanpa pool, akan diganti script no4/no5 jika dibutuhkan.
if [ ! -f /etc/dhcp/net2.conf ]; then
cat > /etc/dhcp/net2.conf <<'EOF'
subnet 192.222.2.0 netmask 255.255.255.0 {
  option routers 192.222.2.1;
}
EOF
fi
if [ ! -f /etc/dhcp/net3.conf ]; then
cat > /etc/dhcp/net3.conf <<'EOF'
subnet 192.222.3.0 netmask 255.255.255.0 {
  option routers 192.222.3.1;
}
EOF
fi
cat > /etc/dhcp/dhcpd.conf <<'EOF'
# K22 - tidak ada duplikasi subnet; kebijakan ada di net2.conf dan net3.conf.
authoritative;
default-lease-time 600;
max-lease-time 43200;
subnet 192.222.4.0 netmask 255.255.255.0 {
    # Lokasi server tengen; TIDAK ADA pool dinamis.
}
include "/etc/dhcp/net2.conf";
include "/etc/dhcp/net3.conf";
EOF
if [ -f /etc/default/isc-dhcp-server ]; then
    sed -i 's/^INTERFACESv4=.*/INTERFACESv4="eth0"/' /etc/default/isc-dhcp-server
fi
dhcpd -t -cf /etc/dhcp/dhcpd.conf
echo '[OK] Konfigurasi dasar DHCP valid (net2/net3 tanpa pool jika belum dikonfigurasi)'
