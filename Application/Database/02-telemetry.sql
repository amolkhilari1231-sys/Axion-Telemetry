-- ========================================================
-- NextOps Industrial v2 - Telemetry & Alarms Schema
-- Condition Monitoring for Coal Electricity Plants (12 Plant Subsystems)
-- Core Metrics: Temperature (°C), Pressure (bar), Flow Rate (m³/h / T/h / MW / RPM)
-- Custom Component Metrics: JSONB
-- ========================================================

CREATE TABLE IF NOT EXISTS telemetry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    device_id VARCHAR(50) NOT NULL,
    device_type VARCHAR(50) NOT NULL,          -- 'COAL_FEEDER', 'FURNACE', 'BOILER', 'CHIMNEY', 'STEAM_LINE', 'TURBINE', 'GENERATOR', 'TRANSFORMER', 'CONDENSER', 'FEEDWATER', 'COOLING_SYSTEM', 'TRANSMISSION'
    refinery_region VARCHAR(50) NOT NULL,      -- 'STATION_1', etc.

    timestamp TIMESTAMP NOT NULL,

    -- Core Base Metrics
    temperature DOUBLE PRECISION NOT NULL,     -- Operating Temperature (°C)
    pressure DOUBLE PRECISION NOT NULL,        -- Operating / Steam Pressure (bar)
    flow_rate DOUBLE PRECISION NOT NULL,       -- Flow Rate / Speed / Power Output

    -- Custom Component-Specific Metrics (JSONB)
    component_metrics JSONB DEFAULT '{}'::jsonb,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fast telemetry lookups & trends
CREATE INDEX IF NOT EXISTS idx_telemetry_device_id_timestamp
ON telemetry(device_id, timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_timestamp
ON telemetry(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_telemetry_region
ON telemetry(refinery_region);

-- Industrial Alarms & Event Logs
CREATE TABLE IF NOT EXISTS alarms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alarm_code VARCHAR(50) NOT NULL,           -- e.g. 'ALM-1049'
    device_id VARCHAR(50) NOT NULL,
    device_type VARCHAR(50) NOT NULL,
    severity VARCHAR(20) NOT NULL,             -- 'CRITICAL', 'WARNING', 'ADVISORY'
    metric_name VARCHAR(50) NOT NULL,
    current_value VARCHAR(50) NOT NULL,
    threshold_value VARCHAR(50) NOT NULL,
    message TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'ACTIVE',       -- 'ACTIVE', 'ACKNOWLEDGED', 'CLEARED'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cleared_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_alarms_device_status
ON alarms(device_id, status);

CREATE INDEX IF NOT EXISTS idx_alarms_created_at
ON alarms(created_at DESC);

