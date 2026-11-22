#!/usr/bin/env bash
# ==============================================================================
# Script: deploy-database.sh
# Automates Azure PostgreSQL Flexible Server configuration & migrations
# Using direct GitHub Secrets / Environment variables (No Key Vault dependency)
# ==============================================================================
set -euo pipefail

ENVIRONMENT="${1:-Preprod}"

if [ "$ENVIRONMENT" = "Production" ]; then
    RESOURCE_GROUP="${RESOURCE_GROUP:-prod_rg}"
    POSTGRES_SERVER="${POSTGRES_SERVER:-axionpostgresql-prod}"
else
    RESOURCE_GROUP="${RESOURCE_GROUP:-dev_rg}"
    POSTGRES_SERVER="${POSTGRES_SERVER:-axionpostgresql}"
fi

echo "======================================================================"
echo "🗄️ [DATABASE] Running automated migrations for Environment: $ENVIRONMENT"
echo "======================================================================"

DB_USER="${POSTGRES_USER:-adminuser}"
DB_PASSWORD="${POSTGRES_PASSWORD:-Admin@123!}"
POSTGRES_HOST="${POSTGRES_SERVER}.postgres.database.azure.com"
POSTGRES_DB="axion_db"

export DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${POSTGRES_HOST}:5432/${POSTGRES_DB}?sslmode=require"
export POSTGRES_HOST
export POSTGRES_USER="$DB_USER"
export POSTGRES_PASSWORD="$DB_PASSWORD"
export POSTGRES_DB="$POSTGRES_DB"

# Detect runner external IP
RUNNER_IP=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me || echo "")
FIREWALL_RULE_NAME="gh-actions-migrator-$(date +%s)"

cleanup() {
    if [ -n "$RUNNER_IP" ]; then
        echo "🧹 [CLEANUP] Removing temporary runner firewall rule '$FIREWALL_RULE_NAME'..."
        az postgres flexible-server firewall-rule delete \
            --resource-group "$RESOURCE_GROUP" \
            --name "$POSTGRES_SERVER" \
            --rule-name "$FIREWALL_RULE_NAME" \
            --yes 2>/dev/null || true
    fi
}
trap cleanup EXIT

if [ -n "$RUNNER_IP" ]; then
    echo "🛡️ Adding runner IP ($RUNNER_IP) to PostgreSQL Flexible Server firewall..."
    az postgres flexible-server firewall-rule create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$POSTGRES_SERVER" \
        --rule-name "$FIREWALL_RULE_NAME" \
        --start-ip-address "$RUNNER_IP" \
        --end-ip-address "$RUNNER_IP" \
        --output none
    echo "✓ Temporary firewall access granted."
fi

python3 -m pip install --quiet psycopg2-binary requests

echo "🚀 Executing migration runner..."
python3 Application/Database/migrate.py --apply

echo "🔍 Validating schema integrity..."
python3 Application/Database/migrate.py --validate

echo "✅ [DATABASE] Schema migrations completed and verified successfully for $ENVIRONMENT!"
