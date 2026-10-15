#!/bin/bash
set -euo pipefail

CONF="/etc/nginx/sites-available/soal16-public-gateway"
EXTRA="/etc/nginx/conf.d/soal19-zones.conf"
STAMP=$(date +%Y%m%d-%H%M%S)

if [ ! -f "$CONF" ]; then
    echo "[ERROR] Config tidak ditemukan: $CONF"
    exit 1
fi

if ! grep -q 'upstream frontend_workers' "$CONF" ||
   ! grep -q 'upstream api_gateway' "$CONF"; then
    echo "[ERROR] Upstream frontend_workers/api_gateway tidak ditemukan."
    exit 1
fi

cp "$CONF" "${CONF}.backup-soal19-${STAMP}"

if [ -f "$EXTRA" ]; then
    cp "$EXTRA" "${EXTRA}.backup-soal19-${STAMP}"
fi

# Zona cache dan rate limit harus berada di konteks http.
cat > "$EXTRA" <<'NGINX'
proxy_cache_path /var/cache/nginx/soal19
    levels=1:2
    keys_zone=frontend_cache:10m
    max_size=100m
    inactive=10m
    use_temp_path=off;

limit_req_zone $binary_remote_addr
    zone=api_limit:10m
    rate=10r/s;
NGINX

mkdir -p /var/cache/nginx/soal19
chown -R www-data:www-data /var/cache/nginx/soal19 2>/dev/null || true

python3 - "$CONF" <<'PY'
import re
import sys
from pathlib import Path

p = Path(sys.argv[1])
s = p.read_text()

# Tambahkan cache ke location frontend, hanya jika belum dipasang.
m = re.search(r'(?m)^(\s*)location\s+/\s*\{', s)
if not m:
    raise SystemExit("[ERROR] location / frontend tidak ditemukan.")

start = m.end()
depth = 1
i = start
while i < len(s) and depth:
    if s[i] == '{':
        depth += 1
    elif s[i] == '}':
        depth -= 1
    i += 1

if depth:
    raise SystemExit("[ERROR] Blok location / tidak lengkap.")

block = s[m.start():i]
if 'proxy_cache frontend_cache;' not in block:
    additions = """
        proxy_cache frontend_cache;
        proxy_cache_key "$scheme$proxy_host$request_uri";
        proxy_cache_valid 200 10m;
        proxy_cache_methods GET HEAD;
        proxy_cache_lock on;
        add_header X-Cache-Status $upstream_cache_status always;
"""
    block = block.replace('{', '{' + additions, 1)
    s = s[:m.start()] + block + s[i:]

# Pasang rate limit pada /api dan /api/ tanpa menimpa proxy/header yang ada.
for loc_pattern in [
    r'(?m)^(\s*)location\s*=\s*/api\s*\{',
    r'(?m)^(\s*)location\s+\^~\s+/api/\s*\{',
]:
    m = re.search(loc_pattern, s)
    if not m:
        raise SystemExit(
            "[ERROR] Location API tidak ditemukan: " + loc_pattern
        )

    start = m.end()
    depth = 1
    i = start
    while i < len(s) and depth:
        if s[i] == '{':
            depth += 1
        elif s[i] == '}':
            depth -= 1
        i += 1

    if depth:
        raise SystemExit("[ERROR] Blok location API tidak lengkap.")

    block = s[m.start():i]
    if 'limit_req zone=api_limit' not in block:
        addition = """
        limit_req zone=api_limit burst=10 nodelay;
        limit_req_status 429;
"""
        block = block.replace('{', '{' + addition, 1)
        s = s[:m.start()] + block + s[i:]

p.write_text(s)
print("[OK] Cache frontend dan rate limit API ditambahkan.")
PY

echo "=== Validasi konfigurasi ==="
nginx -t

echo "=== Reload Nginx ==="
nginx -s reload

echo
echo "=== Zona cache dan rate limit ==="
nginx -T 2>/dev/null | grep -A6 -E \
    'proxy_cache_path|limit_req_zone'

echo
echo "[SELESAI] Soal 19 dikonfigurasi."