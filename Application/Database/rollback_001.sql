-- ==============================================================================
-- Rollback: rollback_001.sql
-- Description: Drops base tables created by 001_initial_schema.sql
-- ==============================================================================

DROP TABLE IF EXISTS alarms CASCADE;
DROP TABLE IF EXISTS unit_summary CASCADE;
DROP TABLE IF EXISTS tag_stats CASCADE;
DROP TABLE IF EXISTS readings CASCADE;
