"""hmi-api: 프록시 전용 게이트웨이. 웹 UI는 web(React) 서비스에서 제공."""
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from hmi_api.config import APP_VERSION, TABLE_SERVICES
from hmi_api.proxy import fetch_openapi, proxy_to_table

app = FastAPI(
    title="Edge HMI API",
    description="프록시 전용: line_mst, equip_mst 등 테이블 API 컨테이너로 프록시",
    version=APP_VERSION,
    docs_url=None,
    redoc_url=None,
    openapi_url=None,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    """API 게이트웨이 루트. 웹 UI는 web 서비스."""
    return {
        "service": "Edge HMI API Gateway",
        "version": APP_VERSION,
        "role": "proxy-only",
        "web_ui": "web (React, separate service)",
        "endpoints": {
            "openapi": "/openapi.json",
            "info": "/info",
            "health": "/health",
        },
    }


@app.get("/health")
def health():
    return {"status": "ok", "role": "gateway"}


@app.get("/info", include_in_schema=False)
async def service_info():
    """서비스 정보."""
    return {
        "service": "Edge HMI API Gateway",
        "version": APP_VERSION,
        "status": "running",
        "role": "proxy-only",
        "integrated_services_count": len(TABLE_SERVICES),
        "services": list(TABLE_SERVICES),
        "available_endpoints": {
            "/openapi.json": "OpenAPI specification",
            "/info": "Service information",
            "/health": "Health check",
        },
    }


@app.get("/openapi.json")
async def openapi_aggregated():
    """각 테이블 서비스 openapi.json 수집 후 병합."""
    paths: dict = {}
    tags: list = []
    seen_tags: set = set()
    all_schemas: dict = {}
    skip_paths = {"/", "/health", "/openapi.json", "/docs", "/redoc"}
    for svc in TABLE_SERVICES:
        spec = await fetch_openapi(svc)
        if not spec:
            continue
        comp = spec.get("components") or {}
        for name, schema in (comp.get("schemas") or {}).items():
            if name not in all_schemas:
                all_schemas[name] = schema
        for path, path_item in (spec.get("paths") or {}).items():
            if path in skip_paths or not path.startswith(f"/{svc}"):
                continue
            paths[path] = path_item
            for op in (path_item or {}).values():
                if not isinstance(op, dict):
                    continue
                for t in op.get("tags") or []:
                    if t not in seen_tags:
                        seen_tags.add(t)
                        tags.append({"name": t})
    return {
        "openapi": "3.0.3",
        "x-source": "gateway-aggregated",
        "info": {
            "title": "Edge HMI API Documentation",
            "version": APP_VERSION,
            "description": f"프록시 게이트웨이. Total {len(tags)} tables integrated.",
        },
        "paths": paths,
        "tags": tags,
        "servers": [],
        "components": {"schemas": all_schemas},
    }


_PROXY_METHODS = ["GET", "POST", "PUT", "PATCH", "DELETE"]


async def _proxy_handler(request: Request, service: str, rest: str | None = None):
    path = f"/{service}" + (f"/{rest}" if rest else "")
    return await proxy_to_table(service, request, path)


def _make_proxy_root(svc: str):
    async def _h(request: Request):
        return await _proxy_handler(request, svc, None)
    return _h


def _make_proxy_path(svc: str):
    async def _h(request: Request, rest: str):
        return await _proxy_handler(request, svc, rest)
    return _h


def _register_proxy_routes():
    for svc in TABLE_SERVICES:
        app.add_api_route(
            f"/{svc}",
            _make_proxy_root(svc),
            methods=_PROXY_METHODS,
            name=f"proxy_{svc}",
        )
        app.add_api_route(
            f"/{svc}/{{rest:path}}",
            _make_proxy_path(svc),
            methods=_PROXY_METHODS,
            name=f"proxy_{svc}_path",
        )


_register_proxy_routes()
