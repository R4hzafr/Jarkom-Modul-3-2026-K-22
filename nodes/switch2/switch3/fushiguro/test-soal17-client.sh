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
fuishiguro:~# ls
no10-client.sh  test-soal17-client.sh  test-soal19-cache.sh
test-soal16.sh  test-soal18.sh         test-soal19-rate.sh
fuishiguro:~# cat test-soal17-client.sh
#!/bin/bash

set -u

DOMAIN="jujutsu.K22.com"
URL="http://${DOMAIN}/api"
LOG="/tmp/test-soal17-client.log"

CLIENT_IP=$(hostname -I | awk '{print $1}')

echo "========================================"
echo "       TESTING SOAL 17 - CLIENT"
echo "========================================"
echo "Hostname  : $(hostname)"
echo "Client IP : ${CLIENT_IP}"
echo "Target    : ${URL}"
echo "Waktu     : $(date)"
echo "========================================"

PASS=0
FAIL=0

check() {
    local name="$1"
    shift

    echo
    echo "[TEST] ${name}"

    if "$@"; then
        echo "[PASS] ${name}"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] ${name}"
        FAIL=$((FAIL + 1))
    fi
}

# 1. DNS domain
check "DNS domain dapat di-resolve" \
    getent hosts "$DOMAIN"

# 2. Akses API dan simpan response
echo
echo "[TEST] Akses endpoint API"

HTTP_CODE=$(curl -sS --connect-timeout 5 --max-time 15 \
    -o /tmp/test-soal17-response.json \
    -w '%{http_code}' "$URL") || HTTP_CODE="000"

cat /tmp/test-soal17-response.json 2>/dev/null || true
echo
echo "HTTP status: ${HTTP_CODE}"

if [ "$HTTP_CODE" = "200" ]; then
    echo "[PASS] API mengembalikan HTTP 200"
    PASS=$((PASS + 1))
else
    echo "[FAIL] API tidak mengembalikan HTTP 200"
    FAIL=$((FAIL + 1))
fi

# 3. Ulangi request untuk menguji konsistensi
echo
echo "[TEST] Kirim 5 request API"

for i in 1 2 3 4 5; do
    CODE=$(curl -sS --connect-timeout 5 --max-time 15 \
        -o /dev/null -w '%{http_code}' "$URL") || CODE="000"

    printf 'Request %d: HTTP %s\n' "$i" "$CODE"

    if [ "$CODE" = "200" ]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
done

# 4. Ringkasan
echo
echo "========================================"
echo "             HASIL TEST"
echo "========================================"
echo "Client IP : ${CLIENT_IP}"
echo "PASS      : ${PASS}"
echo "FAIL      : ${FAIL}"
echo "========================================"
echo "Catatan: IP yang tersimpan diverifikasi melalui database Yaga."