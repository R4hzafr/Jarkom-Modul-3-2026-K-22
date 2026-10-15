#!/bin/bash
set -e

CONF="/etc/nginx/sites-available/soal16-public-gateway"

cp "$CONF" "${CONF}.backup-soal17"

python3 - <<'PY'
p = "/etc/nginx/sites-available/soal16-public-gateway"
s = open(p).read()

s = s.replace(
    'proxy_set_header X-Real-IP $remote_addr;',
    'proxy_set_header X-Real-IP $remote_addr;'
)

# Gojo menimpa X-Forwarded-For dari client dan membentuk
# chain berdasarkan alamat koneksi yang benar-benar diterima.
s = s.replace(
    'proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;',
    'proxy_set_header X-Forwarded-For $remote_addr;'
)

open(p, "w").write(s)
PY

nginx -t
nginx -s reload

echo "Soal 17: header forwarding Gojo selesai."