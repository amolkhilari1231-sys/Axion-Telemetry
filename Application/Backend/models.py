"""
NextOps Industrial Ingestion Service - Pydantic Models
Defines request/response schemas for coal electricity plant telemetry across all 12 subsystems.
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class TelemetryMetrics(BaseModel):
    """The 3 core thermal-fluid metrics from coal power plant equipment."""
    temperature: float = Field(..., description="Operating Temperature (°C)")
    pressure: float = Field(..., description="Steam / Vessel Pressure (bar)")
    flow_rate: float = Field(..., alias="flowRate", description="Flow Rate (m³/h, T/h, MW, RPM)")

    model_config = {"populate_by_name": True}


class TelemetryPayload(BaseModel):
    """Incoming telemetry payload from a power plant device."""
    deviceId: str = Field(..., min_length=1, max_length=50, description="Unique device identifier (e.g. TURBINE-01)")
    deviceType: str = Field(..., min_length=1, max_length=50, description="Type of device (BOILER, FURNACE, TURBINE, GENERATOR, etc.)")
    refineryRegion: str = Field("STATION_1", min_length=1, max_length=50, description="Power plant unit or sector code")
    timestamp: datetime = Field(..., description="ISO-8601 timestamp of the reading")
    metrics: TelemetryMetrics
    componentMetrics: Optional[Dict[str, Any]] = Field(default_factory=dict, alias="componentMetrics", description="Component-specific telemetry metrics")

    model_config = {
        "populate_by_name": True,
        "json_schema_extra": {
            "examples": [
                {
                    "deviceId": "TURBINE-01",
                    "deviceType": "TURBINE",
                    "refineryRegion": "STATION_1",
                    "timestamp": "2026-10-10T10:15:30Z",
                    "metrics": {
                        "temperature": 112.0,
                        "pressure": 18.2,
                        "flowRate": 3000.0
                    },
                    "componentMetrics": {
                        "rotation_speed_rpm": 3000.0,
                        "casing_vibration_mms": 1.25,
                        "exhaust_temp_c": 112.0
                    }
                }
            ]
        }
    }


class BatchTelemetryPayload(BaseModel):
    """Batch payload containing telemetry readings for multiple devices."""
    readings: List[TelemetryPayload] = Field(..., description="List of telemetry payloads")


class TelemetryResponse(BaseModel):
    """Response returned after successful single ingestion."""
    status: str = "accepted"
    id: str = Field(..., description="UUID of the inserted telemetry record")
    message: str = "Telemetry data ingested successfully"


class BatchTelemetryResponse(BaseModel):
    """Response returned after successful batch ingestion."""
    status: str = "accepted"
    ingested_count: int = Field(..., description="Number of records inserted")
    ids: List[str] = Field(default_factory=list, description="List of generated UUIDs")
    message: str = "Batch telemetry data ingested successfully"


class TelemetryRecord(BaseModel):
    """A single telemetry record returned from the database."""
    id: str
    deviceId: str = Field(..., alias="device_id")
    deviceType: str = Field(..., alias="device_type")
    refineryRegion: str = Field(..., alias="refinery_region")
    timestamp: datetime
    temperature: float
    pressure: float
    flowRate: float = Field(..., alias="flow_rate")
    componentMetrics: Optional[Dict[str, Any]] = Field(default_factory=dict, alias="component_metrics")
    createdAt: Optional[datetime] = Field(None, alias="created_at")

    model_config = {"populate_by_name": True}
