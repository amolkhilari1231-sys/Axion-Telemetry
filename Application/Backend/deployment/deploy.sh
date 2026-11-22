#!/usr/bin/env bash
# ==============================================================================
# Script: deploy.sh (nextops-ingestion-service)
# In-Guest VM deployment using Azure VM Run Command (No Key Vault dependency)
# ==============================================================================
set -euo pipefail

ENVIRONMENT="${1:-Preprod}"

if [ "$ENVIRONMENT" = "Production" ]; then
    RESOURCE_GROUP="${RESOURCE_GROUP:-prod_rg}"
    VM_NAME="${VM_NAME:-axionbackendvm-prod}"
    POSTGRES_SERVER="${POSTGRES_SERVER:-axionpostgresql-prod}"
else
    RESOURCE_GROUP="${RESOURCE_GROUP:-dev_rg}"
    VM_NAME="${VM_NAME:-axionbackendvm}"
    POSTGRES_SERVER="${POSTGRES_SERVER:-axionpostgresql}"
fi

echo "======================================================================"
echo "⚙️ [nextops-ingestion-service] Deploying to VM: $VM_NAME ($ENVIRONMENT)"
echo "======================================================================"

DB_USER="${POSTGRES_USER:-adminuser}"
DB_PASSWORD="${POSTGRES_PASSWORD:-Admin@123!}"
POSTGRES_HOST="${POSTGRES_SERVER}.postgres.database.azure.com"
POSTGRES_DB="axion_db"
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}?ssl=require"

# Base64 encode files to bundle into VM run script
MAIN_PY=$(cat main.py | base64 -w 0)
CONFIG_PY=$(cat config.py | base64 -w 0)
DB_PY=$(cat database.py | base64 -w 0)
MODELS_PY=$(cat models.py | base64 -w 0)
REQ_TXT=$(cat requirements.txt | base64 -w 0)

REMOTE_SCRIPT=$(cat << EOF
#!/bin/bash
set -euo pipefail

echo "==> Preparing /opt/nextops/backend..."
mkdir -p /opt/nextops/backend /etc/nextops /opt/nextops/backups

if [ -f "/opt/nextops/backend/main.py" ]; then
    cp -r /opt/nextops/backend/* /opt/nextops/backups/ 2>/dev/null || true
fi

if ! command -v python3 &>/dev/null || ! command -v pip3 &>/dev/null; then
    apt-get update -y && apt-get install -y python3 python3-pip python3-venv curl libpq-dev
fi

if [ ! -d "/opt/nextops/backend/venv" ]; then
    python3 -m venv /opt/nextops/backend/venv
fi

echo "$MAIN_PY" | base64 -d > /opt/nextops/backend/main.py
echo "$CONFIG_PY" | base64 -d > /opt/nextops/backend/config.py
echo "$DB_PY" | base64 -d > /opt/nextops/backend/database.py
echo "$MODELS_PY" | base64 -d > /opt/nextops/backend/models.py
echo "$REQ_TXT" | base64 -d > /opt/nextops/backend/requirements.txt

cat << 'ENVFILE' > /etc/nextops/backend.env
PORT=8001
DATABASE_URL=$DATABASE_URL
ENVFILE
chmod 600 /etc/nextops/backend.env

/opt/nextops/backend/venv/bin/pip install --quiet --upgrade pip
/opt/nextops/backend/venv/bin/pip install --quiet -r /opt/nextops/backend/requirements.txt

cat << 'SVCE' > /etc/systemd/system/nextops-ingestion.service
[Unit]
Description=NextOps Industrial Ingestion Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nextops/backend
EnvironmentFile=/etc/nextops/backend.env
ExecStart=/opt/nextops/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8001
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
SVCE

systemctl daemon-reload
systemctl enable nextops-ingestion
systemctl restart nextops-ingestion

sleep 5
for i in {1..12}; do
    if curl -s -f http://127.0.0.1:8001/health >/dev/null; then
        echo "✓ nextops-ingestion-service is healthy on port 8001!"
        exit 0
    fi
    echo "Waiting for service to be healthy (\$i/12)..."
    sleep 2
done

echo "❌ Health check failed on local port 8001!"
systemctl status nextops-ingestion --no-pager
journalctl -u nextops-ingestion -n 40 --no-pager
exit 1
EOF
)

az vm run-command invoke \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --command-id RunShellScript \
    --scripts "$REMOTE_SCRIPT" \
    --output json

echo "✅ [nextops-ingestion-service] Deployment succeeded on $VM_NAME!"
