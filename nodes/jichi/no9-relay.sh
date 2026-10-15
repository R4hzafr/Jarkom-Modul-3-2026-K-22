#!/bin/bash
# NOMOR 9 - simulasi DHCP Relay berhenti / pulih
set -e
case "${1:-}" in
  stop)
    service isc-dhcp-relay stop >/dev/null 2>&1 || true
    pkill -x dhcrelay 2>/dev/null || true
    sleep 1
    if pgrep -x dhcrelay >/dev/null; then echo '[GAGAL] relay masih aktif'; exit 1; fi
    echo '[OK] DHCP Relay MATI (jalankan uji itadori sekarang)'
    ;;
  start)
    bash /root/relay.sh
    pgrep -a -x dhcrelay
    echo '[OK] DHCP Relay AKTIF'
    ;;
  status)
    if pgrep -a -x dhcrelay; then echo '[OK] relay AKTIF'; else echo '[INFO] relay MATI'; fi
    ;;
  *) echo 'Pakai: bash /root/no9-relay.sh stop|start|status'; exit 1;;
esac
