#!/bin/bash
set -e

# ==========================================
# SETUP SOAL 14 - REVERSE PROXY WEB
# GOJO -> MAKI & PANDA
# ==========================================

MAKI="192.222.4.6"
PANDA="192.222.4.7"
DOMAIN="jujutsu.K22.com"

echo "=========================================="
echo " SETUP SOAL 14 - GOJO REVERSE PROXY WEB"
echo "=========================================="

# 1. Install Nginx jika belum tersedia
if ! command -v nginx >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
fi

# 2. Buat konfigurasi reverse proxy
cat > /etc/nginx/sites-available/soal14-web-proxy <<NGINX
upstream web_workers {
    server ${MAKI}:80;
    server ${PANDA}:80;
}

server {
    listen 80;
    server_name ${DOMAIN} www.${DOMAIN};

    location / {
        proxy_pass http://web_workers;

        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX

# 3. Aktifkan site
ln -sfn /etc/nginx/sites-available/soal14-web-proxy \
        /etc/nginx/sites-enabled/soal14-web-proxy

# 4. Nonaktifkan default site agar tidak bentrok
rm -f /etc/nginx/sites-enabled/default

# 5. Validasi konfigurasi
nginx -t

# 6. Start atau reload Nginx tanpa systemctl
if pgrep -x nginx >/dev/null 2>&1; then
    nginx -s reload
else
    nginx
fi

echo
echo "=========================================="
echo " SETUP SOAL 14 SELESAI"
echo "=========================================="
echo "Reverse proxy : Gojo"
echo "Domain        : ${DOMAIN}"
echo "Backend 1     : Maki (${MAKI}:80)"
echo "Backend 2     : Panda (${PANDA}:80)"
echo
echo "Nginx process:"
ps aux | grep '[n]ginx'