#!/usr/bin/env bash
# ==============================================================================
# Script: deploy-frontend.sh
# Description: Automated deployment of NextOps Frontend Dashboard to Azure VM/Nginx
# ==============================================================================
set -euo pipefail

ENVIRONMENT="${1:-Preprod}"
RESOURCE_GROUP="${RESOURCE_GROUP:-dev_rg}"
VM_NAME="${VM_NAME:-axionbackendvm}"

echo "======================================================================"
echo "🌐 [FRONTEND] Deploying NextOps Dashboard on VM: $VM_NAME ($ENVIRONMENT)"
echo "======================================================================"

FRONTEND_HTML=$(cat Application/frontend/index.html | base64 -w 0)
FRONTEND_NGINX=$(cat Application/frontend/nginx.conf | base64 -w 0)

REMOTE_DEPLOY=$(cat << EOF
#!/bin/bash
set -euo pipefail

echo "==> Configuring Frontend Dashboard on VM..."
mkdir -p /var/www/nextops-dashboard /opt/nextops/backups

# Install Nginx if missing
if ! command -v nginx &>/dev/null; then
    echo "==> Installing Nginx..."
    apt-get update -y && apt-get install -y nginx curl
fi

# Backup previous frontend if exists
if [ -f "/var/www/nextops-dashboard/index.html" ]; then
    cp /var/www/nextops-dashboard/index.html /opt/nextops/backups/index.html.bak
fi

# Write HTML & Nginx Configuration
echo "$FRONTEND_HTML" | base64 -d > /var/www/nextops-dashboard/index.html
echo "$FRONTEND_NGINX" | base64 -d > /etc/nginx/sites-available/nextops.conf

# Point Nginx root to /var/www/nextops-dashboard
sed -i 's|root /usr/share/nginx/html;|root /var/www/nextops-dashboard;|g' /etc/nginx/sites-available/nextops.conf

# Enable site
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/nextops.conf /etc/nginx/sites-enabled/nextops.conf

# Test and reload Nginx
nginx -t
systemctl enable nginx
systemctl restart nginx

# Verify frontend response
sleep 3
if curl -s -f http://127.0.0.1/health >/dev/null || curl -s -f http://127.0.0.1/ | grep -q "NextOps Industrial"; then
    echo "✓ NextOps Frontend Dashboard successfully responding on port 80!"
    exit 0
else
    echo "❌ Frontend health check failed on local port 80!"
    systemctl status nginx --no-pager
    exit 1
fi
EOF
)

echo "📡 Executing frontend deployment via Azure VM Run Command..."
az vm run-command invoke \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --command-id RunShellScript \
    --scripts "$REMOTE_DEPLOY" \
    --output json

echo "✅ [FRONTEND] Dashboard successfully deployed and running on $VM_NAME!"
