-- ==============================================================================
-- Migration: 002_add_telemetry_indexes.sql
-- Description: Composite and covering indexes to accelerate dashboard queries
-- ==============================================================================

-- Index for unit-scoped time queries
CREATE INDEX IF NOT EXISTS idx_readings_unit_ts_desc ON readings (unit, ts DESC);

-- Composite index for fast tag sparklines per unit
CREATE INDEX IF NOT EXISTS idx_readings_unit_tag_ts ON readings (unit, tag, ts DESC);

-- Index for fast active alarm retrieval by unit
CREATE INDEX IF NOT EXISTS idx_alarms_unit_active_ts ON alarms (unit, active, ts DESC);

-- Index for tag_stats unit filtering
CREATE INDEX IF NOT EXISTS idx_tag_stats_unit ON tag_stats (unit);
