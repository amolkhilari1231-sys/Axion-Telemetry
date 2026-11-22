# NextOps Database Setup Guide

This repository contains the database schema and initialization scripts for the **NextOps Industrial Telemetry & Condition Monitoring** platform.

There are **two ways to set up PostgreSQL for NextOps**:
1. **IaaS (Infrastructure as a Service)**: Self-managed PostgreSQL instance on a Virtual Machine (VM) with a Public IP.
2. **PaaS (Platform as a Service)**: Fully managed database using **Azure Database for PostgreSQL - Flexible Server**.

---

## Repository Structure

- `01-extensions.sql`: Enables required PostgreSQL extensions (`pgcrypto` for UUID generation).
- `02-telemetry.sql`: Provisions the `telemetry` (time-series sensor metrics for 12 plant subsystems) and `alarms` tables, along with optimized indexes.

---

## Option 1: IaaS Setup (PostgreSQL on a Linux VM with Public IP)

This approach installs and manages PostgreSQL on an Ubuntu/Debian Linux VM (e.g., Azure VM, AWS EC2, or GCP Compute Engine) with a public IP address.

### Step 1: Configure Network Security / Firewall
Ensure the VM's Network Security Group (NSG) or firewall allows inbound traffic on PostgreSQL's port:
- **Port**: `5432`
- **Protocol**: `TCP`
- **Source**: Your local workstation's Public IP (recommended for security) or `0.0.0.0/0` (if access is needed from any IP).

### Step 2: Install PostgreSQL on the VM
SSH into your Linux VM and run:

```bash
# Update package list
sudo apt update && sudo apt upgrade -y

# Install PostgreSQL and contrib package
sudo apt install -y postgresql postgresql-contrib

# Verify service is running
sudo systemctl status postgresql
```

### Step 3: Configure PostgreSQL for Remote Connections

By default, PostgreSQL only listens on `localhost` (127.0.0.1). You must allow it to listen on all network interfaces.

1. **Edit `postgresql.conf`**:
   ```bash
   sudo nano /etc/postgresql/*/main/postgresql.conf
   ```
   Find `listen_addresses` and change it to:
   ```text
   listen_addresses = '*'
   ```

2. **Edit `pg_hba.conf` to allow remote client authentication**:
   ```bash
   sudo nano /etc/postgresql/*/main/pg_hba.conf
   ```
   Scroll to the end and add the following entry:
   ```text
   # Allow remote password connections from any IP (or restrict to your specific client IP)
   host    all             all             0.0.0.0/0               scram-sha-256
   ```

3. **Restart PostgreSQL to apply changes**:
   ```bash
   sudo systemctl restart postgresql
   ```

### Step 4: Set the `postgres` User Password
Set a password for the default database administrator:

```bash
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'YourStrongPasswordHere';"
```

---

### Step 5: Connect via pgAdmin 4 (IaaS)

1. Launch **pgAdmin 4** on your local machine.
2. In the Browser tree, right-click **Servers** > **Register** > **Server...**.
3. Under the **General** tab:
   - **Name**: `NextOps-IaaS-VM`
4. Under the **Connection** tab:
   - **Host name/address**: `<VM_PUBLIC_IP>`
   - **Port**: `5432`
   - **Maintenance database**: `postgres`
   - **Username**: `postgres`
   - **Password**: `YourStrongPasswordHere` (Check *Save password* if desired)
5. Click **Save**.

---

### Step 6: Create Database & Execute SQL Scripts (IaaS)

1. In pgAdmin, expand the connected server `NextOps-IaaS-VM`.
2. Right-click **Databases** > **Create** > **Database...**.
3. In the dialog, set **Database**: `nextops` and click **Save**.
4. Expand **Databases**, right-click **nextops**, and select **Query Tool**.
5. **Run Script 1 (`01-extensions.sql`)**:
   - Open file `01-extensions.sql` (or paste its content):
     ```sql
     CREATE EXTENSION IF NOT EXISTS pgcrypto;
     ```
   - Click **Execute / Run** (`F5`).
6. **Run Script 2 (`02-telemetry.sql`)**:
   - Open file `02-telemetry.sql` (or paste its content).
   - Click **Execute / Run** (`F5`).
7. Expand `nextops` > **Schemas** > **public** > **Tables** to verify `telemetry` and `alarms` are created.

*(Optional)* You can also run these directly on the VM via command line:
```bash
sudo -u postgres psql -c "CREATE DATABASE nextops;"
sudo -u postgres psql -d nextops -f /path/to/01-extensions.sql
sudo -u postgres psql -d nextops -f /path/to/02-telemetry.sql
```

---

## Option 2: PaaS Setup (Azure Database for PostgreSQL - Flexible Server)

This approach uses Microsoft Azure's fully managed PostgreSQL Flexible Server service.

### Step 1: Provision Azure Database for PostgreSQL Flexible Server

#### Via Azure Portal:
1. Sign in to the [Azure Portal](https://portal.azure.com/).
2. Search for **Azure Database for PostgreSQL flexible servers** and click **Create**.
3. Configure the **Basics** tab:
   - **Subscription**: Select your active Azure subscription.
   - **Resource group**: Select or create a resource group (e.g., `rg-nextops`).
   - **Server name**: Enter a unique name (e.g., `nextops-psql-server`).
   - **Region**: Choose a region near your clients/apps.
   - **PostgreSQL version**: Select version `15` or `16`.
   - **Workload type**: Select *Development* or *Production*.
   - **Compute + storage**: Burstable `B1ms` or `B2s` is sufficient for development.
   - **Authentication method**: *PostgreSQL authentication only* (or Microsoft Entra ID).
   - **Admin username**: e.g., `nextopsadmin`
   - **Admin password**: Enter a secure password.
4. Click **Next: Networking >**.

### Step 2: Configure Networking & Firewall Rules

1. Under **Network connectivity**, select **Public access (allowed IP addresses)**.
2. Under **Firewall rules**:
   - Click **+ Add current client IP address** to allow your local machine to connect.
   - (Optional) Check *Allow public access from any Azure service within Azure to this server* if Azure-hosted apps need to connect.
3. Review and click **Review + create**, then click **Create**. Wait for deployment to complete (takes ~3–5 minutes).

---

### Step 3: Connect via pgAdmin 4 (PaaS)

1. Open **pgAdmin 4**.
2. Right-click **Servers** > **Register** > **Server...**.
3. Under the **General** tab:
   - **Name**: `NextOps-Azure-PaaS`
4. Under the **Connection** tab:
   - **Host name/address**: `<server-name>.postgres.database.azure.com` (Find this under *Server name* in Azure Portal Essentials)
   - **Port**: `5432`
   - **Maintenance database**: `postgres`
   - **Username**: `<admin_username>` (e.g., `nextopsadmin`)
   - **Password**: `<admin_password>`
5. Under the **Parameters** (or **SSL**) tab:
   - **SSL mode**: Select `Require` (Azure Flexible Server enforces SSL by default).
6. Click **Save**.

---

### Step 4: Create Database & Execute SQL Scripts (PaaS)

1. In pgAdmin, expand the connected server `NextOps-Azure-PaaS`.
2. Right-click **Databases** > **Create** > **Database...**.
3. Enter **Database**: `nextops` and click **Save**.
4. Right-click the newly created `nextops` database and open **Query Tool**.
5. **Run `01-extensions.sql`**:
   - Paste or open `01-extensions.sql`.
   - Click **Execute** (`F5`).
6. **Run `02-telemetry.sql`**:
   - Paste or open `02-telemetry.sql`.
   - Click **Execute** (`F5`).
7. Refresh and check `nextops` > **Schemas** > **public** > **Tables** to confirm:
   - `telemetry`
   - `alarms`

---

## Verifying the Setup

Run the following test queries in pgAdmin Query Tool against the `nextops` database:

```sql
-- Check installed extensions
SELECT * FROM pg_extension WHERE extname = 'pgcrypto';

-- Check tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Test insert into telemetry
INSERT INTO telemetry (
    device_id,
    device_type,
    refinery_region,
    timestamp,
    temperature,
    pressure,
    flow_rate,
    component_metrics
) VALUES (
    'DEV-TURBINE-01',
    'TURBINE',
    'STATION_1',
    NOW(),
    485.5,
    165.2,
    3600.0,
    '{"bearing_vibration": 0.04, "oil_temp": 62.1}'::jsonb
);

-- View inserted telemetry
SELECT * FROM telemetry;
```

---

## Connection Strings for Applications

Use these formats in your backend application configuration (`.env` or application config):

### IaaS (VM)
```text
postgresql://postgres:<PASSWORD>@<VM_PUBLIC_IP>:5432/nextops?sslmode=disable
```

### PaaS (Azure Flexible Server)
```text
postgresql://<ADMIN_USERNAME>:<PASSWORD>@<SERVER_NAME>.postgres.database.azure.com:5432/nextops?sslmode=require
```
