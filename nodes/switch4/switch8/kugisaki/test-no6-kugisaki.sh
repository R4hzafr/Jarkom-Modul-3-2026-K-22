#!/bin/sh
LOG=/root/dokumentasi-no6-kugisaki.txt
{
echo "===== NOMOR 6 - KUGISAKI ====="
date
echo
echo "--- MAC eth0 ---"
ip link show eth0 | grep link/ether
echo
echo "--- Request pertama ---"
udhcpc -i eth0 -q
ip -4 addr show eth0 | grep inet
echo
echo "--- Renew (request kedua) ---"
udhcpc -i eth0 -q
ip -4 addr show eth0 | grep inet
echo
echo "--- Routing ---"
ip route
echo
echo "Target: 192.222.3.99/24 di kedua request"
} 2>&1 | tee $LOG
echo; echo "Disimpan di $LOG"