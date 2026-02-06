"""FastAPI app for parts_mst only. Parts/spare master per equipment."""
from fastapi import FastAPI

from parts_mst.router import router

app = FastAPI(title="edge-hmi parts_mst API", version="1.0.1")
app.include_router(router)
