"""
NextOps Industrial Ingestion Service - Database Layer
Manages the asyncpg connection pool and inserts thermal telemetry records.
Supports single and batch ingestion for all 12 thermal power plant subsystems.
"""

import datetime
import json
from typing import List, Dict, Any
import asyncpg
from config import settings

pool: asyncpg.Pool | None = None


async def connect_db():
    """Create the asyncpg connection pool."""
    global pool
    pool = await asyncpg.create_pool(
        dsn=settings.DATABASE_URL,
        min_size=2,
        max_size=10,
    )


async def disconnect_db():
    """Close the connection pool."""
    global pool
    if pool:
        await pool.close()
        pool = None


async def insert_telemetry(
    device_id: str,
    device_type: str,
    refinery_region: str,
    timestamp,
    temperature: float,
    pressure: float,
    flow_rate: float,
    component_metrics: dict | None = None,
) -> str:
    """
    Insert a coal power plant telemetry record and return the generated UUID.
    """
    if timestamp.tzinfo is not None:
        timestamp = timestamp.astimezone(datetime.timezone.utc).replace(tzinfo=None)
        
    metrics_json = json.dumps(component_metrics or {})
    query = """
        INSERT INTO telemetry (device_id, device_type, refinery_region, timestamp, temperature, pressure, flow_rate, component_metrics)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb)
        RETURNING id;
    """
    row = await pool.fetchrow(
        query,
        device_id,
        device_type,
        refinery_region,
        timestamp,
        temperature,
        pressure,
        flow_rate,
        metrics_json,
    )
    return str(row["id"])


async def insert_telemetry_batch(readings: List[Dict[str, Any]]) -> List[str]:
    """
    Batch insert multiple telemetry records in a single transaction.
    Returns the list of generated UUIDs.
    """
    records_to_insert = []
    for r in readings:
        ts = r["timestamp"]
        if hasattr(ts, "tzinfo") and ts.tzinfo is not None:
            ts = ts.astimezone(datetime.timezone.utc).replace(tzinfo=None)
        records_to_insert.append((
            r["device_id"],
            r["device_type"],
            r["refinery_region"],
            ts,
            float(r["temperature"]),
            float(r["pressure"]),
            float(r["flow_rate"]),
            json.dumps(r.get("component_metrics") or {})
        ))

    async with pool.acquire() as conn:
        async with conn.transaction():
            stmt = """
                INSERT INTO telemetry (device_id, device_type, refinery_region, timestamp, temperature, pressure, flow_rate, component_metrics)
                VALUES ($1, $2, $3, $4, $5, $6, $7, $8::jsonb)
                RETURNING id;
            """
            rows = []
            for item in records_to_insert:
                row = await conn.fetchrow(stmt, *item)
                rows.append(str(row["id"]))
            return rows


async def fetch_telemetry(
    device_id: str | None = None,
    limit: int = 100,
) -> list[dict]:
    """
    Fetch recent telemetry records, optionally filtered by device_id.
    Results are ordered by timestamp descending.
    """
    if device_id:
        query = """
            SELECT id, device_id, device_type, refinery_region,
                   timestamp, temperature, pressure, flow_rate,
                   COALESCE(component_metrics, '{}'::jsonb) as component_metrics,
                   created_at
            FROM telemetry
            WHERE device_id = $1
            ORDER BY timestamp DESC
            LIMIT $2;
        """
        rows = await pool.fetch(query, device_id, limit)
    else:
        query = """
            SELECT id, device_id, device_type, refinery_region,
                   timestamp, temperature, pressure, flow_rate,
                   COALESCE(component_metrics, '{}'::jsonb) as component_metrics,
                   created_at
            FROM telemetry
            ORDER BY timestamp DESC
            LIMIT $1;
        """
        rows = await pool.fetch(query, limit)

    result = []
    for r in rows:
        d = dict(r)
        if isinstance(d.get("component_metrics"), str):
            try:
                d["component_metrics"] = json.loads(d["component_metrics"])
            except Exception:
                d["component_metrics"] = {}
        result.append(d)
    return result
