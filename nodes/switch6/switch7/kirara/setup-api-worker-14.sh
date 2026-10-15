#!/bin/bash
set -Eeuo pipefail

# ==========================================
# SOAL 14 - API WORKER NANAMI
# IP Nanami : 192.222.4.8
# Database  : Yaga (192.222.4.3)
# ==========================================

DB_HOST="192.222.4.3"
DB_NAME="db_shibuya_K22"
DB_USER="shibuya_app"
DB_PASS="App_K22_2026!"

echo "=== SETUP API WORKER: $(hostname) ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx php-fpm php-mysql mariadb-client

# Deteksi versi PHP
PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_FPM="/usr/sbin/php-fpm${PHP_VERSION}"
PHP_CONFIG="/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
PHP_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"

# Siapkan direktori runtime
mkdir -p /run/php /var/www/api
chown www-data:www-data /run/php

# Pastikan socket PHP-FPM menggunakan lokasi yang diharapkan
POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

if [[ -f "$POOL" ]]; then
    sed -i \
        "s|^[;[:space:]]*listen = .*|listen = ${PHP_SOCKET}|" \
        "$POOL"
fi

# Jalankan PHP-FPM secara manual bila service manager tidak tersedia
if ! pgrep -f "php-fpm: master process" >/dev/null; then
    "$PHP_FPM" --fpm-config "$PHP_CONFIG" -D
fi

# Tunggu socket terbentuk
for i in $(seq 1 20); do
    [[ -S "$PHP_SOCKET" ]] && break
    sleep 1
done

if [[ ! -S "$PHP_SOCKET" ]]; then
    echo "[ERROR] PHP-FPM belum membuat socket: $PHP_SOCKET"
    echo "Periksa log PHP-FPM dan konfigurasi pool."
    exit 1
fi

# API worker
cat > /var/www/api/index.php <<'PHP'
<?php
header('Content-Type: application/json');

$hostname = gethostname();
$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH);
$method = $_SERVER['REQUEST_METHOD'] ?? 'GET';

$clientIp = $_SERVER['HTTP_X_REAL_IP']
    ?? $_SERVER['REMOTE_ADDR']
    ?? 'unknown';

$statusCode = 200;

try {
    $db = new mysqli(
        '192.222.4.3',
        'shibuya_app',
        'App_K22_2026!',
        'db_shibuya_K22'
    );

    if ($db->connect_error) {
        throw new Exception('Database connection failed');
    }

    $stmt = $db->prepare(
        'INSERT INTO request_logs
         (source_ip, request_path, method, status_code)
         VALUES (?, ?, ?, ?)'
    );

    $stmt->bind_param(
        'sssi',
        $clientIp,
        $path,
        $method,
        $statusCode
    );

    $stmt->execute();
    $stmt->close();
    $db->close();

    echo json_encode([
        'worker' => $hostname,
        'path' => $path,
        'method' => $method,
        'logged' => true
    ]);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'worker' => $hostname,
        'error' => 'Request logging failed'
    ]);
}
PHP

# Virtual host API
cat > /etc/nginx/sites-available/api-worker <<EOF
server {
    listen 8080;
    server_name api.jujutsu.K22.com;

    root /var/www/api;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass unix:${PHP_SOCKET};
    }
}
EOF

ln -sfn /etc/nginx/sites-available/api-worker \
    /etc/nginx/sites-enabled/api-worker
rm -f /etc/nginx/sites-enabled/default

# Validasi sebelum menjalankan Nginx
nginx -t

if pgrep -x nginx >/dev/null; then
    nginx -s reload
else
    nginx
fi

echo
echo "=== API WORKER NANAMI SELESAI ==="
echo "Hostname : $(hostname)"
echo "IP       : 192.222.4.8"
echo "Port     : 8080"
echo "Socket   : ${PHP_SOCKET}"
