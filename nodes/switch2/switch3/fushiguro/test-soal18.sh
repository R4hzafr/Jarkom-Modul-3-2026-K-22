#!/bin/bash

URL="http://jujutsu.K22.com/api"

echo "=== TEST SOAL 18: KONDISI NORMAL ==="
for i in $(seq 1 10); do
    echo -n "Request $i: "
    curl -sS --connect-timeout 3 --max-time 10 \
        -o /tmp/soal18-response.json \
        -w 'HTTP %{http_code}\n' "$URL" \
        || echo "[ERROR] Request gagal"

    cat /tmp/soal18-response.json 2>/dev/null
    echo
done