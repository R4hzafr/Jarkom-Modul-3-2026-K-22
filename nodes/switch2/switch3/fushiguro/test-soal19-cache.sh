#!/bin/bash

set -u
URL="http://jujutsu.K22.com/"

echo "=== TEST SOAL 19: PROXY CACHE ==="

for i in 1 2 3; do
    echo
    echo "--- Request $i ---"

    curl -sS --connect-timeout 5 --max-time 15 \
        -D /tmp/soal19-headers.txt \
        -o /tmp/soal19-body.txt \
        "$URL"

    CODE=$(head -n 1 /tmp/soal19-headers.txt | tr -d '\r')
    CACHE=$(grep -i '^X-Cache-Status:' /tmp/soal19-headers.txt \
        | tail -n 1 | tr -d '\r')

    echo "HTTP       : $CODE"
    echo "Cache      : ${CACHE:-HEADER TIDAK ADA}"
    echo "Response   :"
    head -c 300 /tmp/soal19-body.txt
    echo
    sleep 1
done