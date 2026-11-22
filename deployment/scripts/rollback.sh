#!/usr/bin/env bash
# ==============================================================================
# Script: rollback.sh
# Rollback handler (No Key Vault dependency)
# ==============================================================================
set -euo pipefail

ENVIRONMENT="${1:-Preprod}"

if [ "$ENVIRONMENT" = "Production" ]; then
    RESOURCE_GROUP="${RESOURCE_GROUP:-prod_rg}"
    VM_NAME="${VM_NAME:-axionbackendvm-prod}"
else
    RESOURCE_GROUP="${RESOURCE_GROUP:-dev_rg}"
    VM_NAME="${VM_NAME:-axionbackendvm}"
fi

TARGET_DB_VERSION="${2:-}"

echo "======================================================================"
echo "⚠️ [ROLLBACK] Initiating rollback procedure for Environment: $ENVIRONMENT"
echo "======================================================================"

if [ -n "$TARGET_DB_VERSION" ]; then
    echo "🗄️ Rolling back database migrations..."
    python3 Application/Database/migrate.py --rollback 2>/dev/null || true
fi

echo "🔄 Rolling back backend and frontend on VM: $VM_NAME..."

ROLLBACK_VM_SCRIPT=$(cat << 'EOF'
#!/bin/bash
set -euo pipefail

echo "==> Checking for available service backups..."
if [ -f "/opt/nextops/backups/main.py.bak" ]; then
    cp /opt/nextops/backups/main.py.bak /opt/nextops/backend/main.py
    systemctl restart nextops-ingestion
    echo "✓ Backend service restored from backup."
fi

if [ -f "/opt/nextops/backups/index.html.bak" ]; then
    cp /opt/nextops/backups/index.html.bak /var/www/nextops-dashboard/index.html
    systemctl restart nginx
    echo "✓ Frontend restored from backup."
fi
EOF
)

az vm run-command invoke \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --command-id RunShellScript \
    --scripts "$ROLLBACK_VM_SCRIPT" \
    --output json

echo "✅ [ROLLBACK] Rollback procedure finished for $ENVIRONMENT."
