-- ==============================================================================
-- Migration: 001_initial_schema.sql
-- Description: Creates initial core tables for NextOps industrial telemetry
-- ==============================================================================

CREATE TABLE IF NOT EXISTS readings (
  id    BIGSERIAL PRIMARY KEY,
  ts    TIMESTAMPTZ NOT NULL DEFAULT now(),
  unit  TEXT NOT NULL DEFAULT 'GENERATOR-01',
  tag   TEXT NOT NULL,
  name  TEXT,
  uom   TEXT,
  value DOUBLE PRECISION NOT NULL
);

CREATE INDEX IF NOT EXISTS readings_tag_ts ON readings (tag, ts DESC);
CREATE INDEX IF NOT EXISTS readings_ts ON readings (ts);

-- Computed stats table written by processor
CREATE TABLE IF NOT EXISTS tag_stats (
  tag        TEXT PRIMARY KEY,
  unit       TEXT NOT NULL DEFAULT 'GENERATOR-01',
  name       TEXT,
  uom        TEXT,
  latest     DOUBLE PRECISION,
  latest_ts  TIMESTAMPTZ,
  avg_5m     DOUBLE PRECISION,
  min_5m     DOUBLE PRECISION,
  max_5m     DOUBLE PRECISION,
  status     TEXT NOT NULL DEFAULT 'NORMAL',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Unit level summary table
CREATE TABLE IF NOT EXISTS unit_summary (
  unit       TEXT PRIMARY KEY,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  data       JSONB NOT NULL
);

-- Alarms lifecycle table
CREATE TABLE IF NOT EXISTS alarms (
  id         BIGSERIAL PRIMARY KEY,
  ts         TIMESTAMPTZ NOT NULL DEFAULT now(),
  unit       TEXT NOT NULL DEFAULT 'GENERATOR-01',
  tag        TEXT NOT NULL,
  severity   TEXT NOT NULL,
  message    TEXT NOT NULL,
  value      DOUBLE PRECISION,
  active     BOOLEAN NOT NULL DEFAULT TRUE,
  cleared_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS alarms_one_active ON alarms (tag) WHERE active;
