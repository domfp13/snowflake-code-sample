#!/bin/bash
set -e
echo "Creating demo tables as ${APP_USER}..."
sqlplus -s "${APP_USER}"/"${APP_USER_PASSWORD}"@//localhost:1521/FREEPDB1 @/container-entrypoint-initdb.d/01_tables.sql
echo "Demo tables created."
