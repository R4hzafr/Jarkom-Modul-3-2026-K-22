#!/bin/bash
set -e

# ==========================================
# SOAL 15 - WEIGHTED ROUND ROBIN
# GETO -> NANAMI : TODO = 3 : 1
# ==========================================

NANAMI="192.222.4.8"
TODO="192.222.4.9"
DOMAIN="api.jujutsu.K22.com"

CONFIG="/etc/nginx/sites-available/soal15-api-lb"
ENABLED="/etc/nginx/sites-enabled/soal15-api-lb"

echo "=========================================="
echo " SETUP SOAL 15 - GETO LOAD BALANCER"
echo "=========================================="

# 1. Install Nginx jika belum tersedia
if ! command -v nginx >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
fi

# 2. Backup konfigurasi lama jika masih tersedia
if [ -f /etc/nginx/sites-available/geto-api ] &&
   [ ! -f /root/geto-api.backup ]; then
    cp /etc/nginx/sites-available/geto-api /root/geto-api.backup
fi

# 3. Nonaktifkan konfigurasi lama yang bentrok
rm -f /etc/nginx/sites-enabled/geto-api

# 4. Buat konfigurasi weighted round robin
cat > "$CONFIG" <<NGINX
upstream api_cluster {
    server ${NANAMI}:8080 weight=3;
    server ${TODO}:8080 weight=1;
}

server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://api_cluster;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

# 5. Aktifkan konfigurasi Soal 15
ln -sfn "$CONFIG" "$ENABLED"

# 6. Validasi sebelum menerapkan konfigurasi
nginx -t

# 7. Reload jika Nginx berjalan, atau jalankan jika belum
if pgrep -x nginx >/dev/null 2>&1; then
    nginx -s reload
else
    nginx
fi

echo
echo "=========================================="
echo " SETUP SOAL 15 BERHASIL"
echo "=========================================="
echo "Load balancer : Geto"
echo "Domain        : ${DOMAIN}"
echo "Nanami        : ${NANAMI}:8080 (weight=3)"
echo "Todo          : ${TODO}:8080 (weight=1)"
echo
echo "Konfigurasi aktif:"
nginx -T 2>/dev/null | grep -A 4 'upstream api_cluster'

echo
echo "Site aktif:"
ls -l /etc/nginx/sites-enabled/