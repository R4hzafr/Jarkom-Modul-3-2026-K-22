#!/bin/bash
# NOMOR 1/2 - jaringan statis tengen; rekonstruksi sesuai konfigurasi teruji
set -e
ip link set eth0 up
ip addr replace 192.222.4.10/24 dev eth0
ip route replace default via 192.222.4.1 dev eth0
# DNS NAT untuk instalasi paket sebelum DNS internal (utahime/shoko) siap.
if ! grep -q '^nameserver 192.168.122.1$' /etc/resolv.conf 2>/dev/null; then
    printf 'nameserver 192.168.122.1\n' > /etc/resolv.conf
fi
ip -4 addr show eth0
ip route
