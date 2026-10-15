#!/bin/bash

URL="http://jujutsu.K22.com/api"
TOTAL=50
OUT="/tmp/soal19-rate-results.txt"

echo "=== TEST SOAL 19: RATE LIMITING ==="
echo "Target       : $URL"
echo "Total request: $TOTAL"
echo

: > "$OUT"

for i in $(seq 1 "$TOTAL"); do
    CODE=$(curl -sS --connect-timeout 3 --max-time 10 \
        -o /dev/null -w '%{http_code}' "$URL") || CODE="000"

    echo "$CODE" >> "$OUT"
    printf 'Request %02d: HTTP %s\n' "$i" "$CODE"
done

echo
echo "=== RINGKASAN ==="
echo "HTTP 200:"
grep -cx '200' "$OUT" || true

echo "HTTP 429:"
grep -cx '429' "$OUT" || true

echo "HTTP 502:"
grep -cx '502' "$OUT" || true

echo "HTTP 000:"
grep -cx '000' "$OUT" || true