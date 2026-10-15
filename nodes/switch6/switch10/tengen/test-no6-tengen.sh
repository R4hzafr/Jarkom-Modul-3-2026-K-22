#!/bin/sh
# NOMOR 6 - pemeriksaan reservasi fixed di server
LOG=/root/dokumentasi-no6-tengen.txt
{
  echo '=== NOMOR 6 / TENGEN ==='
  grep -A3 'host kugisaki' /etc/dhcp/net3.conf
  grep 'range ' /etc/dhcp/net3.conf
  dhcpd -t -cf /etc/dhcp/dhcpd.conf && echo '[OK] Konfigurasi valid'
  pgrep -a -x dhcpd
  echo 'CATATAN: fixed-address (host reservation) bisa TIDAK muncul di dhcpd.leases.'
  echo 'Pembuktian utama adalah IP 192.222.3.99 pada client dan MAC reservation di config.'
} 2>&1 | tee "$LOG"
