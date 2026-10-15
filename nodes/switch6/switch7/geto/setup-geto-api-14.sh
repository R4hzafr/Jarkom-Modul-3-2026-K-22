#!/bin/bash
set -Eeuo pipefail

# SOAL 14 - GETO API LOAD BALANCER
# Geto   : 192.222.4.5
# Nanami : 192.222.4.8:8080
# Todo   : 192.222.4.9:8080
# Kirara : 192.222.4.10:8080

echo "=== SETUP GETO API LOAD BALANCER ==="

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx curl

# Upstream load balancer
cat > /etc/nginx/sites-available/geto-api <<'NGINX'
upstream api_workers {
    server 192.222.4.8:8080;
    server 192.222.4.9:8080;
    server 192.222.4.10:8080;
}

server {
    listen 80;
    server_name api.jujutsu.K22.com;

    location / {
        proxy_pass http://api_workers;

        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $http_x_real_ip;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
    }
}
NGINX

ln -sfn /etc/nginx/sites-available/geto-api \
    /etc/nginx/sites-enabled/geto-api

rm -f /etc/nginx/sites-enabled/default

nginx -t

if pgrep -x nginx >/dev/null; then
    nginx -s reload
else
    nginx
fi

echo
echo "=== GETO API LOAD BALANCER SELESAI ==="
echo "Listen : 0.0.0.0:80"
echo "Workers:"
echo " - 192.222.4.8:8080 (Nanami)"
echo " - 192.222.4.9:8080 (Todo)"
echo " - 192.222.4.10:8080 (Kirara)"