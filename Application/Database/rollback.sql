-- ========================================================
-- NextOps Industrial v2 - Telemetry & Alarms Rollback Script
-- Reverts tables and indexes created by 01-extensions & 02-telemetry
-- ========================================================

DROP INDEX IF EXISTS idx_alarms_created_at;
DROP INDEX IF EXISTS idx_alarms_device_status;
DROP TABLE IF EXISTS alarms CASCADE;

DROP INDEX IF EXISTS idx_telemetry_region;
DROP INDEX IF EXISTS idx_telemetry_timestamp;
DROP INDEX IF EXISTS idx_telemetry_device_id_timestamp;
DROP TABLE IF EXISTS telemetry CASCADE;

-- (Optional) DROP EXTENSION IF EXISTS pgcrypto;
