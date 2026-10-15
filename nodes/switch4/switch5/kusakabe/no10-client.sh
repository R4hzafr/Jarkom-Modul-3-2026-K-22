#!/bin/sh

# NOMOR 10 - DHCP CLIENT TEST
# Kelompok K22
# Untuk semua client Alpine

POLICY="$1"

case "$POLICY" in
  pool1)
    NETWORK=2
    MIN=10
    MAX=35
    ;;
  pool2)
    NETWORK=2
    MIN=70
    MAX=95
    ;;
  short)
    NETWORK=3
    MIN=10
    MAX=89
    ;;
  long)
    NETWORK=3
    MIN=100
    MAX=199
    ;;
  fixed)
    NETWORK=3
    MIN=99
    MAX=99
    ;;
  *)
    echo "Gunakan: pool1, pool2, short, long, fixed"
    exit 1
    ;;
esac

echo "================================"
echo " NOMOR 10 - DHCP CLIENT TEST"
echo " Kelompok K22"
echo "================================"

echo "Menghapus IP lama..."
ip addr flush dev eth0

echo "Menghapus default route lama..."
ip route del default dev eth0 2>/dev/null || true

echo "Meminta IP DHCP..."
udhcpc -i eth0 -n -q -t 3 -T 2

if [ "$?" -ne 0 ]; then
    echo "GAGAL: Tidak mendapat IP DHCP"
    exit 1
fi

IP=$(ip -4 -o addr show dev eth0 |
    awk '{print $4}' | cut -d/ -f1 | head -n 1)

GW=$(ip route |
    awk '$1=="default" {print $3; exit}')

LAST=${IP##*.}

echo "================================"
echo " HASIL PENGUJIAN"
echo "================================"

echo "IP Address: $IP"
echo "Gateway: $GW"

echo "DNS:"
cat /etc/resolv.conf

case "$IP" in
    192.222.$NETWORK.*) ;;
    *)
        echo "GAGAL: Network tidak sesuai"
        exit 1
        ;;
esac

if [ "$LAST" -lt "$MIN" ] || [ "$LAST" -gt "$MAX" ]; then
    echo "GAGAL: IP di luar pool"
    exit 1
fi

if [ "$GW" != "192.222.$NETWORK.1" ]; then
    echo "GAGAL: Gateway tidak sesuai"
    exit 1
fi

echo "================================"
echo " BERHASIL: IP dan Gateway sesuai"
echo "================================"