# Axion Telemetry Azure Infrastructure

This repository contains modularized **Terraform** configurations to provision and manage Azure Cloud Infrastructure for the **Axion Telemetry** project.

---

## 🏗️ Architecture & Module Structure

The project uses a modular design to promote reusability across environments (`Preprod`, `Prod`).

```
Axion-Telemetry/
├── Envoirnment/
│   ├── Preprod/             # Pre-production environment deployment configs
│   │   ├── Main.tf          # Module invocations
│   │   ├── Provider.tf      # AzureRM provider configurations
│   │   ├── variables.tf     # Variable definitions
│   │   └── terraform.tfvars # Environment specific variable values
│   └── Prod/                # Production environment deployment configs
└── modules/                 # Reusable infrastructure modules
    ├── Application_Gateway/ # Azure Application Gateway provisioner
    ├── Azure_Bastion/       # Azure Bastion host for secure access
    ├── Azure_firewall/      # Azure Firewall configurations
    ├── Nat_gateway/         # NAT Gateway for outbound traffic
    ├── Resource_Group/      # Azure Resource Groups
    ├── Subnets/             # Subnet provisions within VNets
    ├── VNet_Peering/        # Virtual Network Peering connections
    ├── Virtual_machine/     # Compute instances (VMs)
    ├── Virtual_network/     # Azure Virtual Networks (VNets)
    └── postgresql_flexble_service/ # PostgreSQL Flexible Server instance
```

---

## 🚀 Provisioned Azure Services

- **Resource Groups (`Resource_Group`)**: Container for Azure resources.
- **Virtual Networks (`Virtual_network`) & Subnets (`Subnets`)**: Network topology isolation.
- **Virtual Machines (`Virtual_machine`)**: Compute workloads.
- **PostgreSQL Flexible Server (`postgresql_flexble_service`)**: Managed relational database service.
- **Azure Bastion (`Azure_Bastion`)**: Secure RDP/SSH access without public IPs.
- **NAT Gateway (`Nat_gateway`)**: Outbound internet connectivity for private subnets.
- **Application Gateway (`Application_Gateway`)**: Layer 7 load balancer and web traffic routing.
- **VNet Peering (`VNet_Peering`)**: Connectivity between Virtual Networks.
- *(Optional)* **Azure Firewall (`Azure_firewall`)**: Cloud-native network security.

---

## 🛠️ Prerequisites

- [Terraform](https://www.terraform.io/downloads) (v1.0+)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) logged into target Azure Subscription (`az login`)

---

## 💻 Usage & Deployment Guide

### 1. Authenticate to Azure
```bash
az login
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"
```

### 2. Navigate to Environment Directory
For `Preprod`:
```bash
cd Envoirnment/Preprod
```

For `Prod`:
```bash
cd Envoirnment/Prod
```

### 3. Initialize & Apply Terraform

```bash
# Initialize working directory and download provider modules
terraform init

# Validate configuration syntax
terraform validate

# Review execution plan
terraform plan

# Apply infrastructure changes
terraform apply
```

---

## ⚙️ Configuration (`terraform.tfvars`)

Customize infrastructure parameters inside the `terraform.tfvars` file under the respective environment folder (`Envoirnment/Preprod/terraform.tfvars` or `Envoirnment/Prod/terraform.tfvars`).