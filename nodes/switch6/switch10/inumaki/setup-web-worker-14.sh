#!/bin/bash
set -Eeuo pipefail

echo "=== SETUP WEB WORKER: $(hostname) ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx php-fpm

PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"
PHP_FPM="/usr/sbin/php-fpm${PHP_VERSION}"
PHP_CONFIG="/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
PHP_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"
POOL="/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"

mkdir -p /run/php /var/www/frontend

# Pastikan PHP-FPM menggunakan socket yang sesuai
if [[ -f "$POOL" ]]; then
    sed -i \
        "s|^[;[:space:]]*listen = .*|listen = ${PHP_SOCKET}|" \
        "$POOL"
fi

# Jalankan PHP-FPM jika belum aktif
if ! pgrep -f "php-fpm: master process" >/dev/null; then
    "$PHP_FPM" --fpm-config "$PHP_CONFIG" -D
fi

for i in $(seq 1 20); do
    [[ -S "$PHP_SOCKET" ]] && break
    sleep 1
done

if [[ ! -S "$PHP_SOCKET" ]]; then
    echo "[ERROR] Socket PHP-FPM tidak ditemukan: $PHP_SOCKET"
    exit 1
fi

# Halaman frontend menampilkan hostname worker
cat > /var/www/frontend/index.php <<'PHP'
<?php
header('Content-Type: text/html; charset=UTF-8');
$hostname = htmlspecialchars(gethostname(), ENT_QUOTES, 'UTF-8');
echo "<!doctype html>
<html lang='id'>
<head><meta charset='utf-8'><title>Web Worker</title></head>
<body>
<h1>WEB FRONTEND</h1>
<p>Hostname: {$hostname}</p>
</body>
</html>";
PHP

cat > /etc/nginx/sites-available/web-worker <<EOF
server {
    listen 80 default_server;
    server_name _;

    root /var/www/frontend;
    index index.php index.html;

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

ln -sfn /etc/nginx/sites-available/web-worker \
    /etc/nginx/sites-enabled/web-worker
rm -f /etc/nginx/sites-enabled/default

nginx -t

if pgrep -x nginx >/dev/null; then
    nginx -s reload
else
    nginx
fi

echo
echo "=== WEB WORKER SELESAI ==="
echo "Hostname: $(hostname)"
echo "Port: 80"
echo "PHP-FPM socket: ${PHP_SOCKET}"