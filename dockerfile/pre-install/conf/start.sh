#!/usr/bin/env bash

###############################################
# DigitalBridge ERPNext
# Runtime entrypoint
###############################################

set -euo pipefail

SITE_NAME=${SITE_NAME:-default.site}

BENCH_DIR="/home/frappe/frappe-bench"
ASSETS_DIR="${BENCH_DIR}/sites/assets"

log() {
    echo "$(date '+%H:%M:%S') -> $*"
}

###############################################
# Prepare runtime directories
###############################################

log "Preparing runtime directories..."

mkdir -p /run/mysqld

chown -R mysql:mysql /run/mysqld

###############################################
# Repair directory permissions
###############################################

log "Checking ERPNext asset permissions..."

# Allow nginx to traverse parent directories.
chmod 755 /home/frappe
chmod 755 "${BENCH_DIR}"
chmod 755 "${BENCH_DIR}/sites"

# Ensure asset directories exist.
mkdir -p "${ASSETS_DIR}"

# Restore asset ownership.
chown -R frappe:frappe "${ASSETS_DIR}"

# Allow nginx to read asset files and directories.
find -L "${ASSETS_DIR}" -type d -exec chmod 755 {} +
find -L "${ASSETS_DIR}" -type f -exec chmod 644 {} +

###############################################
# Verify ERPNext assets
###############################################

log "Verifying ERPNext assets..."

if [ -d "${ASSETS_DIR}/frappe/dist" ]; then
    log "Frappe asset directory found."
else
    log "WARNING: Frappe asset directory missing."
fi

if [ -d "${ASSETS_DIR}/erpnext/dist" ]; then
    log "ERPNext asset directory found."
else
    log "WARNING: ERPNext asset directory missing."
fi

###############################################
# Configure nginx
###############################################

log "Injecting variables into nginx..."

export SITE_NAME

envsubst '${SITE_NAME}' \
    < /etc/nginx/frappe.conf.template \
    > /etc/nginx/sites-enabled/default

###############################################
# Start ERPNext services
###############################################

log "Starting ERPNext services..."

exec /usr/bin/supervisord \
    -n \
    -c /etc/supervisor/conf.d/frappe.conf
