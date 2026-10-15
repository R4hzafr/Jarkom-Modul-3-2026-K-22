#!/bin/sh
# NOMOR 8 - capture satu transaksi DORA lewat relay
set -eu
mode="${1:-}"
case "$mode" in
  net2|net3)
    command -v tcpdump >/dev/null 2>&1 || apt-get install -y tcpdump
    F="/root/no8-${mode}-$(date +%Y%m%d-%H%M%S).pcap"
    echo "Capture $mode ke $F"
    echo 'Lalu pada client terkait: ip addr flush dev eth0; udhcpc -i eth0 -n -q'
    echo 'STOP capture dengan Ctrl+C jika sudah DORA; kemudian jalankan baca2/baca3.'
    tcpdump -i eth0 -n -s 0 -U -w "$F" 'udp port 67 or udp port 68'
    ;;
  baca2|baca3)
    command -v tcpdump >/dev/null 2>&1 || { echo 'tcpdump belum terpasang'; exit 1; }
    case "$mode" in baca2) net=net2;; baca3) net=net3;; esac
    last="$(find /root -maxdepth 1 -type f -name "no8-${net}-*.pcap" | sort | tail -n 1)"
    [ -n "$last" ] || { echo "File untuk $net belum ada"; exit 1; }
    echo "Membaca $last"
    tcpdump -n -vvv -r "$last"
    ;;
  *) echo 'Pakai: sh /root/no8-capture.sh net2|net3|baca2|baca3'; exit 1;;
esac
