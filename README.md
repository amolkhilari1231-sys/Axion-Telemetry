# 🚀 Axion Telemetry & NextOps Enterprise One-Click Deployment System

This repository provides an automated **One-Click Continuous Delivery (CD) and Infrastructure as Code (IaC) System** using **GitHub Actions**, **Terraform**, **Azure Database for PostgreSQL Flexible Server**, and **Azure Linux Compute**.

It orchestrates and deploys the full-stack architecture across four repositories/components:
1. **Axion-Telemetry** – Modular Terraform Azure Infrastructure (`Preprod` & `Production`)
2. **nextops-database** – PostgreSQL schema, versioned migrations, and automated rollbacks
3. **nextops-ingestion-service** – High-throughput FastAPI telemetry ingestion and query backend
4. **nextops-dashboard** – Real-time industrial telemetry monitoring frontend (React + Vite + Nginx)

---

## 🏛️ System Architecture

```
[ Industrial Sensors / Gateways ]
               │
               ▼ HTTP POST (X-API-Key)
    [ Azure Application Gateway ] (Axion-appgateway: Port 80)
               │
               ▼ Reverse Proxy / Routing (/path1/ -> Port 8001)
     [ NextOps Dashboard & Ingestion Backend ] (axionbackendvm: Ubuntu 22.04)
     ├── Frontend UI: Nginx (Port 80)
     └── Backend API: FastAPI / Uvicorn (Port 8001)
               │
               ▼ SSL Connection (Port 5432, sslmode=require)
  [ Azure Database for PostgreSQL Flexible Server ] (axionpostgresql)
```

---

## 🔐 Security & Secrets Management (No Key Vault Required)

Key Vault complexity has been eliminated. All sensitive credentials are managed directly via **GitHub Actions Secrets**:

| Secret Name | Purpose | Example |
|---|---|---|
| `AZURE_CLIENT_ID` | Azure App Registration Client ID for OIDC | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_TENANT_ID` | Azure Active Directory Tenant ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AZURE_SUBSCRIPTION_ID` | Target Azure Subscription ID | `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `POSTGRES_PASSWORD` | Azure Database for PostgreSQL admin password | `YourSecurePassword123!` |
| `INGEST_API_KEY` | Telemetry API key for sensor validation | `dev-key` |

---

## 📂 Repository Layout

```text
Axion-Telemetry/
├── .github/
│   └── workflows/
│       ├── one-click-deploy.yml    # Master One-Click End-to-End Orchestrator
│       ├── infra-deploy.yml        # Standalone Terraform Infrastructure Deployment
│       ├── database-deploy.yml     # Standalone Database Migrations & Rollback
│       ├── backend-deploy.yml      # Standalone Backend Ingestion Service Deploy
│       ├── frontend-deploy.yml     # Standalone Frontend Dashboard Deploy
│       └── terraform-ci.yml        # IaC Linting, Validation & Scanning CI
├── Application/
│   ├── Backend/                    # nextops-ingestion-service Source Code
│   ├── Database/                   # nextops-database Source Code
│   └── frontend/                   # nextops-dashboard Source Code
├── deployment/
│   ├── backend/                    # Systemd & Docker service configurations
│   ├── frontend/                   # Nginx reverse proxy configurations
│   └── scripts/
│       ├── deploy-infra.sh         # Terraform Apply & State Reuse Automation
│       ├── deploy-database.sh      # DB Migration & Dynamic IP Firewall Handler
│       ├── deploy-backend.sh       # VM In-Guest Deployment (az vm run-command)
│       ├── deploy-frontend.sh      # VM Web Server & Reverse Proxy Setup
│       ├── validate-health.sh      # 4-Stage Multi-Tier Health Check Suite
│       └── rollback.sh             # Automated & Manual Rollback Handler
├── Envoirnment/
│   ├── Preprod/                    # Pre-production Environment Configuration
│   │   ├── Main.tf, Provider.tf, terraform.tfvars, variables.tf, outputs.tf
│   └── Prod/                       # Production Environment Configuration
│       ├── Main.tf, Provider.tf, terraform.tfvars, variables.tf, outputs.tf
└── modules/                        # Reusable Terraform Modules
```

---

## 🎯 Environments & Production Approval Gate

### 1. Preprod Environment
- **Resource Group**: `dev_rg`
- **PostgreSQL Server**: `axionpostgresql`
- **VM**: `axionbackendvm`
- **Remote State**: `preprod/terraform.tfstate` in `QA_Storage/terraformqastorage/terraformqastate`
- **Approval**: Runs directly upon dispatch.

### 2. Production Environment
- **Resource Group**: `prod_rg`
- **PostgreSQL Server**: `axionpostgresql-prod`
- **VM**: `axionbackendvm-prod`
- **Remote State**: `prod/terraform.tfstate` in `QA_Storage/terraformqastorage/terraformqastate`
- **Approval Gate**: Requires manual review by designated leads before executing changes.

---

## ⚡ How to Trigger One-Click Deployment

1. Navigate to your repository's **Actions** tab.
2. Select **🚀 NextOps One-Click Deployment System** on the left menu.
3. Click **Run workflow**:
   - **Target Cloud Environment**: Select `Preprod` or `Production`.
   - **Deployment Scope / Action**: Choose `Deploy All (End-to-End)` or component-specific.
   - **Automatically rollback on failure**: `true`.
4. Click **Run workflow**.
