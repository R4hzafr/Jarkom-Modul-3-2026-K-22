#!/bin/bash
# NOMOR 3 - DHCP Relay jichi menuju tengen; eth4 diperlukan sebagai jalur balasan
set -e
if ! command -v dhcrelay >/dev/null 2>&1; then
    apt-get install -y isc-dhcp-relay
fi
# Hentikan daemon sebelumnya agar tidak terjadi relay ganda.
service isc-dhcp-relay stop >/dev/null 2>&1 || true
pkill -x dhcrelay 2>/dev/null || true
sleep 1
dhcrelay -4 -i eth2 -i eth3 -i eth4 192.222.4.10
sleep 1
pgrep -a -x dhcrelay || { echo '[GAGAL] dhcrelay tidak berjalan'; exit 1; }
