#!/bin/bash

DOMAIN="jujutsu.K22.com"
GOJO="192.222.1.4"
DNS="192.222.1.2"

echo "=========================================="
echo " TEST SOAL 16 - PATH-BASED ROUTING"
echo " Client: $(hostname)"
echo "=========================================="

echo
echo "=== 1. TEST KONEKTIVITAS GOJO ==="
ping -c 3 "$GOJO"

echo
echo "=== 2. TEST DNS DOMAIN ==="
nslookup "$DOMAIN" "$DNS"
nslookup "www.$DOMAIN" "$DNS"

echo
echo "=== 3. TEST WEB ROUND ROBIN (12 REQUEST) ==="
maki=0
panda=0
gagal=0

for i in $(seq 1 12); do
    worker=$(curl -s --connect-timeout 5 \
        "http://$DOMAIN/" |
        grep -oP 'Hostname: \K[^<]+' || true)

    echo "Request $i: ${worker:-GAGAL}"

    case "$worker" in
        maki)  ((maki+=1)) ;;
        panda) ((panda+=1)) ;;
        *)     ((gagal+=1)) ;;
    esac
done

echo
echo "Hasil Web:"
echo "Maki  : $maki"
echo "Panda : $panda"
echo "Gagal : $gagal"

echo
echo "=== 4. TEST API ROUTING (12 REQUEST) ==="
nanami=0
todo=0
api_gagal=0

for i in $(seq 1 12); do
    worker=$(curl -s --connect-timeout 5 \
        "http://$DOMAIN/api" |
        grep -oP '"worker"\s*:\s*"\K[^"]+' || true)

    echo "Request $i: ${worker:-GAGAL}"

    case "$worker" in
        nanami) ((nanami+=1)) ;;
        todo)   ((todo+=1)) ;;
        *)      ((api_gagal+=1)) ;;
    esac
done

echo
echo "Hasil API:"
echo "Nanami : $nanami"
echo "Todo   : $todo"
echo "Gagal  : $api_gagal"

echo
echo "=== 5. TEST ALIAS WWW ==="
curl -s -o /dev/null -w \
    "Web www - HTTP %{http_code}\n" \
    --connect-timeout 5 "http://www.$DOMAIN/"

curl -s -o /dev/null -w \
    "API www - HTTP %{http_code}\n" \
    --connect-timeout 5 "http://www.$DOMAIN/api"

echo
echo "=========================================="
echo " TESTING SOAL 16 SELESAI"
echo "=========================================="