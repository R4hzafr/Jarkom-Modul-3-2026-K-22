#!/bin/bash

set -u

DNS_MASTER="192.222.1.2"
DOMAIN="jujutsu.K22.com"
GOJO_IP="192.222.1.4"

echo "========================================"
echo " TEST DNS NOMOR 12 - CLIENT GOJO"
echo "========================================"

echo
echo "[1] A RECORD - DOMAIN UTAMA"
dig @"$DNS_MASTER" "$DOMAIN" A +noall +answer

echo
echo "[2] CNAME - WWW"
dig @"$DNS_MASTER" "www.$DOMAIN" CNAME +noall +answer

echo
echo "[3] REVERSE DNS - PTR"
dig @"$DNS_MASTER" -x "$GOJO_IP" +noall +answer

echo
echo "[4] DNS FORWARDER - GOOGLE.COM"
dig @"$DNS_MASTER" google.com A +noall +answer

echo
echo "[5] PING GOOGLE.COM"
ping -c 3 google.com

echo
echo "========================================"
echo " TEST SELESAI"
echo "========================================"