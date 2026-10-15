#!/bin/bash
set -euo pipefail

FILE="/var/www/api/index.php"
BACKUP="/root/index.php.backup-soal17-$(date +%Y%m%d-%H%M%S)"

if [ ! -f "$FILE" ]; then
    echo "[ERROR] File $FILE tidak ditemukan."
    exit 1
fi

# Pastikan skema API yang akan diubah sesuai dengan versi sebelumnya.
if ! grep -Fq "INSERT INTO request_logs" "$FILE"; then
    echo "[ERROR] Query INSERT request_logs tidak ditemukan."
    exit 1
fi

if grep -Fq "client_ip" "$FILE"; then
    echo "[INFO] Kolom client_ip sudah digunakan dalam kode."
    echo "[INFO] Backup: $BACKUP"
    cp "$FILE" "$BACKUP"
    echo "[INFO] Periksa file secara manual; tidak mengubahnya ulang."
    exit 0
fi

cp "$FILE" "$BACKUP"

python3 - "$FILE" <<'PY'
import sys
from pathlib import Path

p = Path(sys.argv[1])
s = p.read_text()

old_ip = """$clientIp = $_SERVER['HTTP_X_REAL_IP']
    ?? $_SERVER['REMOTE_ADDR']
    ?? 'unknown';"""

new_ip = """$clientIp = $_SERVER['HTTP_X_REAL_IP'] ?? '';

if (!filter_var($clientIp, FILTER_VALIDATE_IP)) {
    http_response_code(400);
    echo json_encode([
        'error' => 'Missing or invalid verified client IP'
    ]);
    exit;
}"""

old_sql = """(source_ip, request_path, method, status_code)
         VALUES (?, ?, ?, ?)"""

new_sql = """(source_ip, client_ip, request_path, method, status_code)
         VALUES (?, ?, ?, ?, ?)"""

old_bind = """'sssi',
        $clientIp,
        $path,
        $method,
        $statusCode"""

new_bind = """'ssssi',
        $clientIp,
        $clientIp,
        $path,
        $method,
        $statusCode"""

for name, old in [
    ("pemilihan IP", old_ip),
    ("query SQL", old_sql),
    ("parameter bind_param", old_bind),
]:
    count = s.count(old)
    if count != 1:
        raise SystemExit(
            f"[ERROR] Pola {name} ditemukan {count} kali, "
            "bukan tepat satu kali. File tidak diubah."
        )

s = s.replace(old_ip, new_ip, 1)
s = s.replace(old_sql, new_sql, 1)
s = s.replace(old_bind, new_bind, 1)

p.write_text(s)
print("[OK] Pemilihan IP, query SQL, dan bind_param diperbarui.")
PY

echo
echo "=== Validasi PHP ==="
php -l "$FILE"

echo
echo "=== Bagian kode yang diperbarui ==="
grep -n -A8 -B2 -E 'clientIp|INSERT INTO request_logs|bind_param' "$FILE"

echo
echo "[SELESAI] Backup tersimpan di: $BACKUP"