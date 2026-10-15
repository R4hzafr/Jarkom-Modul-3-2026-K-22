#!/bin/bash
set -e

# ==========================================
# SOAL 16 - GOJO PUBLIC GATEWAY
# /     -> MAKI + PANDA (Round Robin)
# /api  -> GETO -> NANAMI + TODO
# ==========================================

DOMAIN="jujutsu.K22.com"
GOJO_IP="192.222.1.4"

MAKI="192.222.4.6"
PANDA="192.222.4.7"
GETO="192.222.4.5"

CONFIG="/etc/nginx/sites-available/soal16-public-gateway"
ENABLED="/etc/nginx/sites-enabled/soal16-public-gateway"

echo "=========================================="
echo " SETUP SOAL 16 - GOJO PUBLIC GATEWAY"
echo "=========================================="

# 1. Install Nginx jika belum tersedia
if ! command -v nginx >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
fi

# 2. Backup konfigurasi Soal 14 jika tersedia
if [ -f /etc/nginx/sites-available/soal14-web-proxy ] &&
   [ ! -f /root/soal14-web-proxy.backup ]; then
    cp /etc/nginx/sites-available/soal14-web-proxy \
       /root/soal14-web-proxy.backup
fi

# 3. Buat konfigurasi public gateway
cat > "$CONFIG" <<NGINX
upstream frontend_workers {
    server ${MAKI}:80;
    server ${PANDA}:80;
}

upstream api_gateway {
    server ${GETO}:80;
}

server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    # API: teruskan URI /api ke Geto tanpa menghapus prefix
    location = /api {
        proxy_pass http://api_gateway;

        proxy_set_header Host api.${DOMAIN};
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ^~ /api/ {
        proxy_pass http://api_gateway;

        proxy_set_header Host api.${DOMAIN};
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Web utama: Round Robin ke Maki dan Panda
    location / {
        proxy_pass http://frontend_workers;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

# 4. Aktifkan konfigurasi tunggal untuk kedua domain
ln -sfn "$CONFIG" "$ENABLED"

# Nonaktifkan site lama agar tidak bentrok
rm -f /etc/nginx/sites-enabled/soal14-web-proxy
rm -f /etc/nginx/sites-enabled/default

# 5. Validasi konfigurasi sebelum reload
nginx -t

# 6. Start atau reload Nginx tanpa systemctl
if pgrep -x nginx >/dev/null 2>&1; then
    nginx -s reload
else
    nginx
fi

echo
echo "=========================================="
echo " SETUP SOAL 16 BERHASIL"
echo "=========================================="
echo "Domain : ${DOMAIN}"
echo "Alias  : www.${DOMAIN}"
echo "Web    : Maki + Panda (Round Robin)"
echo "API    : Geto -> Nanami + Todo"
echo
echo "Site aktif:"
ls -l /etc/nginx/sites-enabled/