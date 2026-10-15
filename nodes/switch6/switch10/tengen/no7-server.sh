#!/bin/sh
# NOMOR 7 - validasi DHCP service/pool dan inspeksi lease
LOG=/root/no7-server.txt
{
  echo '=== Nomor 7 K22 / DHCP SERVER ==='
  date
  echo 'Alamat server:'; ip -4 addr show eth0
  echo 'Server DHCP:'; pgrep -a -x dhcpd
  echo 'Konfigurasi subnet/pool:'
  grep -E '^(subnet|[[:space:]]*range |[[:space:]]*option (routers|domain-name|domain-name-servers|broadcast-address))' /etc/dhcp/net2.conf /etc/dhcp/net3.conf
  echo 'Lease aktif/riwayat (ISC):'
  tail -n 160 /var/lib/dhcp/dhcpd.leases
  echo 'CATATAN: dhcpd.leases adalah riwayat; entri terakhir per IP menentukan status terkini.'
} 2>&1 | tee "$LOG"
