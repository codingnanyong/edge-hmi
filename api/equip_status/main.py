"""FastAPI app for equip_status only (interval history). List + Get."""
from fastapi import FastAPI

from equip_status.router import router

app = FastAPI(title="edge-hmi equip_status API", version="1.0.1")
app.include_router(router)


@app.get("/")
def root():
    return {"table": "equip_status", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "ok"}
