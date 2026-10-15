#!/bin/bash
set -e

CONF="/etc/nginx/sites-available/soal15-api-lb"

cp "$CONF" "${CONF}.backup-soal17"

python3 - <<'PY'
p = "/etc/nginx/sites-available/soal15-api-lb"
s = open(p).read()

# Pastikan trusted proxy hanya Gojo
if "set_real_ip_from 192.222.1.4;" not in s:
    s = s.replace(
        "server_name api.jujutsu.K22.com;",
        """server_name api.jujutsu.K22.com;

    # Percayai forwarded IP hanya dari Gojo
    set_real_ip_from 192.222.1.4;
    real_ip_header X-Real-IP;
    real_ip_recursive on;"""
    )

# Teruskan IP yang telah diverifikasi ke worker
s = s.replace(
    "proxy_set_header X-Real-IP $remote_addr;",
    "proxy_set_header X-Real-IP $remote_addr;"
)
s = s.replace(
    "proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
    "proxy_set_header X-Forwarded-For $remote_addr;"
)

open(p, "w").write(s)
PY

nginx -t
nginx -s reload

echo "Soal 17: trusted proxy Geto selesai."
nginx -T 2>/dev/null | grep -E \
'set_real_ip_from|real_ip_header|real_ip_recursive|proxy_set_header X-Real-IP'