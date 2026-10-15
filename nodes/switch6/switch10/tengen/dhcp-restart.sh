#!/bin/bash
# Start/restart DHCP dengan aman di image debinet tanpa systemd.
set -e
dhcpd -t -cf /etc/dhcp/dhcpd.conf
service isc-dhcp-server stop >/dev/null 2>&1 || true
pkill -x dhcpd 2>/dev/null || true
sleep 1
# Menjalankan daemon secara langsung dengan interface eth0; dhcpd mem-fork sendiri.
dhcpd -4 -q -cf /etc/dhcp/dhcpd.conf eth0
sleep 1
pgrep -a -x dhcpd || { echo '[GAGAL] DHCP daemon belum aktif'; exit 1; }
