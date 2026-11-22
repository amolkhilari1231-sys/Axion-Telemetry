#!/usr/bin/env bash
# ==============================================================================
# Script: deploy.sh (nextops-database)
# Automates schema migration against Azure PostgreSQL Flexible Server
# Using direct GitHub Secrets / Environment variables (No Key Vault dependency)
# ==============================================================================
set -euo pipefail

ENVIRONMENT="${1:-Preprod}"
ACTION="${2:-apply}"

echo "======================================================================"
echo "🗄️ [nextops-database] Running $ACTION for: $ENVIRONMENT"
echo "======================================================================"

if [ "$ENVIRONMENT" = "Production" ]; then
    RESOURCE_GROUP="${RESOURCE_GROUP:-prod_rg}"
    POSTGRES_SERVER="${POSTGRES_SERVER:-axionpostgresql-prod}"
else
    RESOURCE_GROUP="${RESOURCE_GROUP:-dev_rg}"
    POSTGRES_SERVER="${POSTGRES_SERVER:-axionpostgresql}"
fi

DB_USER="${POSTGRES_USER:-adminuser}"
DB_PASSWORD="${POSTGRES_PASSWORD:-Admin@123!}"
POSTGRES_HOST="${POSTGRES_SERVER}.postgres.database.azure.com"
POSTGRES_DB="axion_db"

export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}?sslmode=require"
export POSTGRES_HOST
export POSTGRES_USER="$DB_USER"
export POSTGRES_PASSWORD="$DB_PASSWORD"
export POSTGRES_DB

RUNNER_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || echo "")
FIREWALL_RULE="gh-migrator-$(date +%s)"

cleanup() {
    if [ -n "$RUNNER_IP" ]; then
        echo "🧹 [CLEANUP] Removing temporary firewall rule '$FIREWALL_RULE'..."
        az postgres flexible-server firewall-rule delete \
            --resource-group "$RESOURCE_GROUP" \
            --name "$POSTGRES_SERVER" \
            --rule-name "$FIREWALL_RULE" \
            --yes 2>/dev/null || true
    fi
}
trap cleanup EXIT

if [ -n "$RUNNER_IP" ]; then
    echo "🛡️ Adding runner IP ($RUNNER_IP) to Azure PostgreSQL Flexible Server firewall..."
    az postgres flexible-server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$POSTGRES_SERVER" \
        --rule-name "$FIREWALL_RULE" \
        --start-ip-address "$RUNNER_IP" \
        --end-ip-address "$RUNNER_IP" \
        --output none
fi

python3 -m pip install --quiet psycopg2-binary

if [ "$ACTION" = "rollback" ]; then
    python3 migrate.py --rollback
elif [ "$ACTION" = "validate" ]; then
    python3 migrate.py --validate
else
    python3 migrate.py --apply
fi

echo "✅ [nextops-database] Database $ACTION completed successfully for $ENVIRONMENT!"
