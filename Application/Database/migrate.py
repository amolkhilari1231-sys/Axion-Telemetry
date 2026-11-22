#!/usr/bin/env python3
"""
NextOps Industrial Database Migration Engine
Connects to Azure Database for PostgreSQL Flexible Server, applies SQL files in order,
tracks migrations in schema_migrations table, and provides validation and rollback support.
"""

import os
import sys
import hashlib
import argparse
import logging
from pathlib import Path
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("nextops-database-migrator")

REPO_DIR = Path(__file__).resolve().parent

def get_db_url() -> str:
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        host = os.getenv("POSTGRES_HOST", "localhost")
        port = os.getenv("POSTGRES_PORT", "5432")
        user = os.getenv("POSTGRES_USER", os.getenv("POSTGRES_ADMIN_USER", "adminuser"))
        password = os.getenv("POSTGRES_PASSWORD", os.getenv("POSTGRES_ADMIN_PASSWORD", ""))
        dbname = os.getenv("POSTGRES_DB", "axion_db")
        sslmode = os.getenv("POSTGRES_SSLMODE", "require" if "azure" in host else "prefer")
        db_url = f"postgresql://{user}:{password}@{host}:{port}/{dbname}?sslmode={sslmode}"

    if "sslmode=" not in db_url and "localhost" not in db_url and "127.0.0.1" not in db_url:
        sep = "&" if "?" in db_url else "?"
        db_url = f"{db_url}{sep}sslmode=require"

    return db_url

def ensure_database(db_url: str):
    """Ensure target database exists."""
    if "/" in db_url:
        base_url = db_url.rsplit("/", 1)[0] + "/postgres"
        if "?" in db_url:
            base_url = f"{base_url}?{db_url.split('?', 1)[1]}"
    else:
        base_url = db_url

    target_db = os.getenv("POSTGRES_DB", "axion_db")
    try:
        conn = psycopg2.connect(base_url)
        conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (target_db,))
            if not cur.fetchone():
                logger.info(f"Database '{target_db}' does not exist. Creating...")
                cur.execute(f'CREATE DATABASE "{target_db}";')
                logger.info(f"Database '{target_db}' created successfully.")
            else:
                logger.info(f"Database '{target_db}' exists.")
        conn.close()
    except Exception as e:
        logger.warning(f"Database check notice: {e}")

def init_tracking_table(conn):
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version VARCHAR(64) PRIMARY KEY,
                filename VARCHAR(255) NOT NULL,
                checksum VARCHAR(64) NOT NULL,
                applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
            );
        """)
    conn.commit()

def apply_migrations(conn):
    init_tracking_table(conn)
    with conn.cursor() as cur:
        cur.execute("SELECT version FROM schema_migrations;")
        applied = {row[0] for row in cur.fetchall()}

    sql_files = sorted(REPO_DIR.glob("*.sql"))
    sql_files = [f for f in sql_files if not f.name.startswith("rollback")]

    if not sql_files:
        logger.warning("No migration SQL files found.")
        return

    count = 0
    for sql_file in sql_files:
        version = sql_file.stem
        if version in applied:
            logger.info(f"  [✓ ALREADY APPLIED] {sql_file.name}")
            continue

        logger.info(f"  [→ APPLYING] {sql_file.name}...")
        content = sql_file.read_text(encoding="utf-8")
        chk = hashlib.sha256(content.encode("utf-8")).hexdigest()

        with conn:
            with conn.cursor() as cur:
                cur.execute(content)
                cur.execute(
                    "INSERT INTO schema_migrations (version, filename, checksum) VALUES (%s, %s, %s);",
                    (version, sql_file.name, chk)
                )
        logger.info(f"  [✓ SUCCESS] Applied {sql_file.name}")
        count += 1

    logger.info(f"Migration completed. Applied {count} new file(s).")

def rollback_migrations(conn):
    rollback_file = REPO_DIR / "rollback.sql"
    if not rollback_file.exists():
        logger.error(f"Rollback file not found at {rollback_file}")
        sys.exit(1)

    logger.info("Executing rollback using rollback.sql...")
    sql = rollback_file.read_text(encoding="utf-8")
    with conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            cur.execute("DROP TABLE IF EXISTS schema_migrations;")
    logger.info("Rollback executed successfully.")

def validate_schema(conn) -> bool:
    expected_tables = ["telemetry", "alarms", "schema_migrations"]
    with conn.cursor() as cur:
        cur.execute("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public';
        """)
        tables = {r[0] for r in cur.fetchall()}

    missing = [t for t in expected_tables if t not in tables]
    if missing:
        logger.error(f"Schema validation FAILED. Missing tables: {missing}")
        return False

    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM telemetry;")
        tel_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM alarms;")
        alm_count = cur.fetchone()[0]

    logger.info(f"✓ Schema validation PASSED. All {len(expected_tables)} required tables exist.")
    logger.info(f"  - Telemetry rows: {tel_count}")
    logger.info(f"  - Alarms rows   : {alm_count}")
    return True

def main():
    parser = argparse.ArgumentParser(description="NextOps Database Migration CLI")
    parser.add_argument("--apply", action="store_true", help="Apply migrations")
    parser.add_argument("--rollback", action="store_true", help="Rollback migrations")
    parser.add_argument("--validate", action="store_true", help="Validate schema")
    args = parser.parse_args()

    db_url = get_db_url()
    ensure_database(db_url)

    conn = psycopg2.connect(db_url)
    try:
        if args.rollback:
            rollback_migrations(conn)
        elif args.validate:
            if not validate_schema(conn):
                sys.exit(1)
        else:
            apply_migrations(conn)
            if not validate_schema(conn):
                sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    main()
