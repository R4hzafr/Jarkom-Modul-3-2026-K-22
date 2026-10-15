#!/bin/bash
set -Eeuo pipefail

# ==========================================
# SOAL 13 - MARIADB SLAVE (INUMAKI)
# ==========================================

MASTER_IP="192.222.4.3"
SLAVE_IP="192.222.4.4"
DB_NAME="db_shibuya_K22"
DUMP_FILE="/root/db_shibuya_K22.sql"

REPL_USER="replicator"
REPL_PASS="Repl_K22_2026!"

MASTER_LOG_FILE="mariadb-bin.000001"
MASTER_LOG_POS="1913"

echo "=========================================="
echo " SETUP MARIADB SLAVE - INUMAKI"
echo "=========================================="

export DEBIAN_FRONTEND=noninteractive

# 1. Pastikan dump database tersedia
if [[ ! -s "$DUMP_FILE" ]]; then
    echo "[ERROR] Dump tidak ditemukan atau kosong: $DUMP_FILE"
    exit 1
fi

# 2. Instal MariaDB
echo "[1/6] Instalasi MariaDB..."
apt-get update
apt-get install -y mariadb-server mariadb-client

# 3. Konfigurasi Slave
echo "[2/6] Konfigurasi MariaDB Slave..."

cat > /etc/mysql/mariadb.conf.d/60-slave.cnf <<EOF
[mysqld]
server-id=2
bind-address=0.0.0.0
relay-log=/var/log/mysql/mariadb-relay-bin
log_bin=/var/log/mysql/mariadb-bin
binlog_format=ROW
gtid_strict_mode=ON
read_only=ON
EOF

mkdir -p /var/log/mysql /run/mysqld
chown mysql:mysql /var/log/mysql /run/mysqld

# 4. Restart MariaDB
echo "[3/6] Restart MariaDB..."
service mariadb restart

# Tunggu hingga server siap
for i in $(seq 1 30); do
    if mariadb-admin ping --silent >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! mariadb-admin ping --silent >/dev/null 2>&1; then
    echo "[ERROR] MariaDB tidak berhasil dijalankan."
    exit 1
fi

# 5. Impor dump database awal
echo "[4/6] Impor database awal..."
mariadb -e "STOP SLAVE;" 2>/dev/null || true
mariadb < "$DUMP_FILE"

# 6. Hubungkan Slave ke Master
echo "[5/6] Konfigurasi replikasi..."

mariadb <<SQL
STOP SLAVE;
RESET SLAVE ALL;

CHANGE MASTER TO
    MASTER_HOST='${MASTER_IP}',
    MASTER_PORT=3306,
    MASTER_USER='${REPL_USER}',
    MASTER_PASSWORD='${REPL_PASS}',
    MASTER_LOG_FILE='${MASTER_LOG_FILE}',
    MASTER_LOG_POS=${MASTER_LOG_POS};

START SLAVE;
SQL

# 7. Tampilkan status
echo "[6/6] Status replikasi:"
mariadb -e "SHOW SLAVE STATUS\G"

echo
echo "=========================================="
echo " SETUP MARIADB SLAVE SELESAI"
echo "=========================================="