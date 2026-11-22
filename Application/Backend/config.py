"""
Axion Ingestion Service - Configuration
Loads database connection string from environment variable.
Enforces SSL when connecting to Azure PostgreSQL Flexible Server.
"""

import os
from dataclasses import dataclass


@dataclass
class Settings:
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://axion_user:P%40ssw01rd%40123@localhost:5432/axion_db",
    )
    PORT: int = int(os.getenv("PORT", "8001"))

    def __post_init__(self):
        # Ensure ssl=require for remote Azure PostgreSQL if not already present
        if "ssl=" not in self.DATABASE_URL and "localhost" not in self.DATABASE_URL and "127.0.0.1" not in self.DATABASE_URL:
            sep = "&" if "?" in self.DATABASE_URL else "?"
            self.DATABASE_URL = f"{self.DATABASE_URL}{sep}ssl=require"


settings = Settings()
