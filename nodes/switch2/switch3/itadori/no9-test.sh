#!/bin/sh

# NOMOR 9 - DHCP RELAY TEST
# Kelompok K22
# Node: itadori

echo "================================"
echo " NOMOR 9 - DHCP CLIENT TEST"
echo "================================"

echo "Menghapus IP lama..."
ip addr flush dev eth0

echo "Meminta IP dari DHCP Server..."
udhcpc -i eth0 -n -q -t 3 -T 2

RESULT=$?

echo ""
echo "================================"
echo " HASIL PENGUJIAN DHCP"
echo "================================"

if [ "$RESULT" -eq 0 ]; then
    echo "BERHASIL: DHCP mendapatkan IP"
else
    echo "GAGAL: DHCP tidak mendapatkan IP"
fi

echo ""
echo "Alamat IP:"
ip -4 addr show eth0

echo ""
echo "Routing:"
ip route

exit "$RESULT"