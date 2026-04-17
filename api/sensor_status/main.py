"""FastAPI app for sensor_status only. Single-table container."""
from fastapi import FastAPI

from sensor_status.router import router

app = FastAPI(title="edge-hmi sensor_status API", version="1.0.0")
app.include_router(router)


@app.get("/")
def root():
    return {"table": "sensor_status", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}
