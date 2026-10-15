#!/bin/bash
set -Eeuo pipefail

# ==========================================
# SOAL 13 - MARIADB MASTER (YAGA)
# ==========================================

MASTER_IP="192.222.4.3"
SLAVE_IP="192.222.4.4"
DB_NAME="db_shibuya_K22"
REPL_USER="replicator"
REPL_PASS="Repl_K22_2026!"

echo "=== SETUP MARIADB MASTER - YAGA ==="

export DEBIAN_FRONTEND=noninteractive

# 1. Install MariaDB
apt-get update
apt-get install -y mariadb-server mariadb-client

# 2. Konfigurasi binary logging dan GTID
cat > /etc/mysql/mariadb.conf.d/60-master.cnf <<EOF
[mysqld]
server-id=1
bind-address=0.0.0.0
log_bin=/var/log/mysql/mariadb-bin
binlog_format=ROW
gtid_strict_mode=ON
log_slave_updates=ON
EOF

# 3. Siapkan direktori binary log
mkdir -p /var/log/mysql
chown mysql:mysql /var/log/mysql

# 4. Jalankan/restart MariaDB
if command -v service >/dev/null 2>&1; then
    service mariadb restart || true
fi

if ! pgrep -x mariadbd >/dev/null && ! pgrep -x mysqld >/dev/null; then
    mkdir -p /run/mysqld
    chown mysql:mysql /run/mysqld
    mariadbd --user=mysql &
    for i in $(seq 1 30); do
        mariadb-admin ping --silent >/dev/null 2>&1 && break
        sleep 1
    done
fi

# 5. Buat database, tabel, dan akun replikasi
mariadb <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

USE ${DB_NAME};

CREATE TABLE IF NOT EXISTS request_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    source_ip VARCHAR(45) NOT NULL,
    request_path VARCHAR(255) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code SMALLINT UNSIGNED NOT NULL DEFAULT 200,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE USER IF NOT EXISTS '${REPL_USER}'@'192.222.4.%'
IDENTIFIED BY '${REPL_PASS}';

GRANT REPLICATION SLAVE ON *.*
TO '${REPL_USER}'@'192.222.4.%';

CREATE USER IF NOT EXISTS 'shibuya_app'@'192.222.4.%'
IDENTIFIED BY 'App_K22_2026!';

GRANT ALL PRIVILEGES ON ${DB_NAME}.*
TO 'shibuya_app'@'192.222.4.%';

FLUSH PRIVILEGES;
SQL

# 6. Validasi konfigurasi
mariadbd --help --verbose >/dev/null 2>&1 || true

echo
echo "=== STATUS MASTER ==="
mariadb -e "SHOW VARIABLES LIKE 'server_id';"
mariadb -e "SHOW VARIABLES LIKE 'log_bin';"
mariadb -e "SHOW MASTER STATUS;"

echo
echo "=== MASTER SELESAI DIKONFIGURASI ==="