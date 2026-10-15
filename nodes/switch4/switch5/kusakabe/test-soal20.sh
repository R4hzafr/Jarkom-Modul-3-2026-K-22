#!/bin/bash
set -u

N=600
C=30
DOMAIN="jujutsu.K22.com"
OUT="/root/soal20-results"

mkdir -p "$OUT"

if ! command -v ab >/dev/null 2>&1; then
    echo "[ERROR] Apache Benchmark belum terpasang."
    echo "Install dengan: apt install -y apache2-utils"
    exit 1
fi

echo "======================================"
echo " SOAL 20 - BENCHMARK"
echo " Host      : $(hostname)"
echo " Request   : $N"
echo " Concurrency: $C"
echo "======================================"

run_ab() {
    local label="$1"
    local url="$2"
    local host_header="$3"
    local file="$OUT/${label}.txt"

    echo
    echo "=== $label ==="

    if [ -n "$host_header" ]; then
        ab -n "$N" -c "$C" -H "Host: $host_header" "$url" \
            2>&1 | tee "$file"
    else
        ab -n "$N" -c "$C" "$url" 2>&1 | tee "$file"
    fi

    echo
    echo "--- Ringkasan $label ---"
    grep -E \
      'Complete requests:|Failed requests:|Requests per second:|Time per request:|Non-2xx responses:|Percentage of the requests served within a certain time' \
      "$file" || true
}

# Frontend
run_ab "frontend" "http://${DOMAIN}/" ""

# API - hasil benchmark murni, termasuk respons 429 bila ada.
run_ab "api" "http://${DOMAIN}/api" ""

# Catat distribusi status HTTP API secara terpisah.
echo
echo "=== DISTRIBUSI STATUS HTTP API ==="
STATUS_FILE="$OUT/api-status.txt"
: > "$STATUS_FILE"

for i in $(seq 1 "$N"); do
    code=$(curl -sS --connect-timeout 3 --max-time 10 \
        -o /dev/null -w '%{http_code}' \
        "http://${DOMAIN}/api") || code="000"
    echo "$code" >> "$STATUS_FILE"
done

sort "$STATUS_FILE" | uniq -c | sort -nr

echo
echo "Hasil tersimpan di: $OUT"