#!/bin/bash
set -euo pipefail

CONF="/etc/nginx/sites-available/soal15-api-lb"

if [ ! -f "$CONF" ]; then
    echo "[ERROR] Config tidak ditemukan: $CONF"
    exit 1
fi

cp "$CONF" "${CONF}.backup-soal18-$(date +%Y%m%d-%H%M%S)"

python3 - "$CONF" <<'PY'
import re
import sys
from pathlib import Path

p = Path(sys.argv[1])
s = p.read_text()

pattern = r'upstream\s+api_cluster\s*\{.*?\}'
replacement = """upstream api_cluster {
    server 192.222.4.8:8080 weight=3 max_fails=2 fail_timeout=5s;
    server 192.222.4.9:8080 weight=1 max_fails=2 fail_timeout=5s;
    server 192.222.4.10:8080 backup;
}"""

new_s, count = re.subn(pattern, replacement, s, count=1, flags=re.S)

if count != 1:
    raise SystemExit(
        "[ERROR] upstream api_cluster tidak ditemukan. "
        "Config belum diubah; periksa file secara manual."
    )

p.write_text(new_s)
print("[OK] Upstream api_cluster diperbarui.")
PY

echo
echo "=== Uji konfigurasi Nginx ==="
nginx -t

echo
echo "=== Reload Nginx ==="
nginx -s reload

echo
echo "=== Upstream aktif ==="
nginx -T 2>/dev/null | grep -A5 'upstream api_cluster'

echo "[SELESAI] Konfigurasi Soal 18 diterapkan."