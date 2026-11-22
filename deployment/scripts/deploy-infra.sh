#!/usr/bin/env bash
# ==============================================================================
# Script: deploy-infra.sh
# Description: Automated deployment of Terraform Infrastructure with state reuse
# ==============================================================================
set -euo pipefail

ENVIRONMENT="${1:-Preprod}"
ACTION="${2:-apply}" # plan or apply

echo "======================================================================"
echo "🚀 [INFRASTRUCTURE] Deploying Terraform for Environment: $ENVIRONMENT"
echo "======================================================================"

# Determine directory based on environment
ENV_DIR="Envoirnment/$ENVIRONMENT"
if [ ! -d "$ENV_DIR" ]; then
    echo "❌ Error: Environment directory '$ENV_DIR' not found!"
    exit 1
fi

# Azure State Backend configuration (reusing existing Azure storage)
BACKEND_RG="${BACKEND_RESOURCE_GROUP:-QA_Storage}"
BACKEND_STORAGE="${BACKEND_STORAGE_ACCOUNT:-terraformqastorage}"
BACKEND_CONTAINER="${BACKEND_CONTAINER_NAME:-terraformqastate}"
BACKEND_KEY="${ENVIRONMENT,,}/terraform.tfstate"

echo "📦 Backend Configuration:"
echo "   - Resource Group : $BACKEND_RG"
echo "   - Storage Account: $BACKEND_STORAGE"
echo "   - Container Name : $BACKEND_CONTAINER"
echo "   - State Key      : $BACKEND_KEY"

cd "$ENV_DIR"

echo "🔧 Initializing Terraform with remote Azure Blob backend..."
terraform init \
    -backend-config="resource_group_name=$BACKEND_RG" \
    -backend-config="storage_account_name=$BACKEND_STORAGE" \
    -backend-config="container_name=$BACKEND_CONTAINER" \
    -backend-config="key=$BACKEND_KEY" \
    -reconfigure

echo "🔍 Validating Terraform configurations..."
terraform validate

echo "📋 Generating Terraform Plan..."
terraform plan -out=tfplan -input=false

if [ "$ACTION" = "apply" ]; then
    echo "⚡ Applying Terraform Infrastructure changes..."
    terraform apply -input=false -auto-approve tfplan
    echo "✅ [INFRASTRUCTURE] Successfully applied Terraform for $ENVIRONMENT"
else
    echo "ℹ️ Plan generated successfully (Dry-Run mode)."
fi
