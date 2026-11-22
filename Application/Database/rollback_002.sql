-- ==============================================================================
-- Rollback: rollback_002.sql
-- Description: Drops indexes created by 002_add_telemetry_indexes.sql
-- ==============================================================================

DROP INDEX IF EXISTS idx_tag_stats_unit;
DROP INDEX IF EXISTS idx_alarms_unit_active_ts;
DROP INDEX IF EXISTS idx_readings_unit_tag_ts;
DROP INDEX IF EXISTS idx_readings_unit_ts_desc;
