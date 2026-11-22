#!/usr/bin/env bash
# ==============================================================================
# Script: deploy-backend.sh
# Automated deployment of backend NextOps Ingestion Service to Azure VM
# Using direct GitHub Secrets / Environment variables (No Key Vault dependency)
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
echo "⚙️ [BACKEND] Deploying Ingestion Service on VM: $VM_NAME ($ENVIRONMENT)"
echo "======================================================================"

DB_USER="${POSTGRES_USER:-adminuser}"
DB_PASSWORD="${POSTGRES_PASSWORD:-Admin@123!}"
INGEST_KEY="${INGEST_API_KEY:-dev-key}"

POSTGRES_HOST="${POSTGRES_SERVER}.postgres.database.azure.com"
DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${POSTGRES_HOST}:5432/axion_db?sslmode=require"

# Prepare remote execution script
REMOTE_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -euo pipefail

echo "==> Configuring NextOps Backend on VM..."
mkdir -p /opt/nextops/backend /etc/nextops /opt/nextops/backups

# Install prerequisites if missing
if ! command -v python3 &>/dev/null || ! command -v pip3 &>/dev/null; then
    apt-get update -y && apt-get install -y python3 python3-pip python3-venv libpq-dev curl
fi

# Setup Virtual Environment
if [ ! -d "/opt/nextops/backend/venv" ]; then
    python3 -m venv /opt/nextops/backend/venv
fi

# Backup previous release if exists
if [ -f "/opt/nextops/backend/main.py" ]; then
    cp /opt/nextops/backend/main.py /opt/nextops/backups/main.py.bak
fi
EOF
)

# Append dynamic files and configuration to script
BACKEND_MAIN=$(cat Application/Backend/main.py | base64 -w 0)
BACKEND_REQ=$(cat Application/Backend/requirements.txt | base64 -w 0)

REMOTE_DEPLOY=$(cat << EOF
$REMOTE_SCRIPT

# Write source files
echo "$BACKEND_MAIN" | base64 -d > /opt/nextops/backend/main.py
echo "$BACKEND_REQ" | base64 -d > /opt/nextops/backend/requirements.txt

# Write Environment File
cat << 'ENVFILE' > /etc/nextops/backend.env
PORT=8001
INGEST_API_KEY=$INGEST_KEY
DATABASE_URL=$DATABASE_URL
ENVFILE

chmod 600 /etc/nextops/backend.env

# Install Python requirements
/opt/nextops/backend/venv/bin/pip install --quiet --upgrade pip
/opt/nextops/backend/venv/bin/pip install --quiet -r /opt/nextops/backend/requirements.txt

# Configure Systemd Service
cat << 'SVCE' > /etc/systemd/system/nextops-ingestion.service
[Unit]
Description=NextOps Ingestion & Telemetry Backend Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nextops/backend
EnvironmentFile=/etc/nextops/backend.env
ExecStart=/opt/nextops/backend/venv/bin/python3 main.py
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
SVCE

systemctl daemon-reload
systemctl enable nextops-ingestion
systemctl restart nextops-ingestion

# Wait for service readiness
sleep 5
for i in {1..12}; do
    if curl -s -f http://127.0.0.1:8001/health >/dev/null || curl -s -f http://127.0.0.1:8001/healthz >/dev/null; then
        echo "✓ NextOps Backend is healthy and responding on port 8001!"
        exit 0
    fi
    echo "Waiting for backend service (attempt \$i/12)..."
    sleep 2
done

echo "❌ Backend health check failed on local port 8001!"
systemctl status nextops-ingestion --no-pager
journalctl -u nextops-ingestion -n 30 --no-pager
exit 1
EOF
)

echo "📡 Executing backend deployment via Azure VM Run Command..."
az vm run-command invoke \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --command-id RunShellScript \
    --scripts "$REMOTE_DEPLOY" \
    --output json

echo "✅ [BACKEND] Ingestion Service successfully deployed on $VM_NAME!"
