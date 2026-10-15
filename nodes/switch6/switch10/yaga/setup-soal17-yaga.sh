#!/bin/bash
set -e

mysql -u root -p db_shibuya_K22 <<'SQL'
ALTER TABLE request_logs
    ADD COLUMN IF NOT EXISTS client_ip VARCHAR(45) NULL AFTER source_ip;
SQL

echo "Kolom client_ip tersedia."