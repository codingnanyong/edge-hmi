# 🌐 Edge HMI Web

[![React](https://img.shields.io/badge/React-18+-61DAFB?logo=react&logoColor=black)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-6+-646CFF?logo=vite&logoColor=white)](https://vitejs.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.6+-3178C6?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)

Dashboard UI for Edge HMI. Overview, Swagger UI, Feature Usage guide, and per-service API detail. Talks to **hmi-api gateway** (`:8000`).

## 📁 Structure

```text
web/
├── src/
│   ├── components/       # Layout, Sidebar
│   ├── pages/            # DashboardHome, SwaggerEmbed, FeatureUsageEmbed, ServiceDetail
│   ├── contexts/         # ThemeContext, LocaleContext
│   ├── data/             # feature-usage, service-icons
│   ├── i18n/             # translations, feature-i18n
│   ├── styles/           # CSS modules
│   ├── App.tsx, main.tsx, routes.ts
│   └── constants.ts      # TABLE_SERVICES, SERVICE_OPERATIONS, SERVICE_INFO
├── public/
├── Dockerfile            # multi-stage: Node build → nginx serve
├── nginx.conf
├── vite.config.ts        # dev proxy → gateway :8000
└── package.json
```

## ⚙️ Prerequisites

- **Node.js** 18+ (recommended 20+)
- **hmi-api gateway** running at `http://localhost:8000` (for API calls and dev proxy)

## 🚀 Scripts

```bash
cd web
npm install
npm run dev      # Vite dev server → http://localhost:8889 (proxies API to :8000)
npm run build    # TypeScript check + production build → dist/
npm run preview  # Preview production build (port 8889)
```

| Script    | Port | Description                   |
|-----------|------|-------------------------------|
| `dev`     | 8889 | Dev server + proxy to gateway |
| `preview` | 8889 | Serve `dist/` locally         |

## 🔌 API Proxy (dev)

`vite.config.ts` proxies these paths to `http://localhost:8000`:

- `/openapi.json`, `/info`, `/health`
- `/line_mst`, `/equip_mst`, `/sensor_mst`, … (all table API paths)

So the app can call the gateway from the same origin during development.

## 🐳 Docker build

Build from **project root** (`edge-hmi/`):

```bash
cd edge-hmi
docker build -f web/Dockerfile -t edge-hmi-web:latest .
```

- **Stage 1**: Node 20, `npm run build` → `dist/`
- **Stage 2**: nginx:alpine serves `dist/` on port 80

Run (e.g. with gateway on host :8000):

```bash
docker run -p 8888:80 edge-hmi-web:latest
# → http://localhost:8888
```

## 📄 Routes

| Path              | Page           | Description                                |
|-------------------|----------------|--------------------------------------------|
| `/`               | Dashboard Home | Service cards, quick links                 |
| `/swagger`        | Swagger UI     | Aggregated API docs (swagger-ui-react)     |
| `/feature-usage`  | Feature Usage  | Embed of FEATURE-USAGE guide               |
| `/service/:id`    | Service Detail | Per-table API operations (e.g. line_mst)   |

## 📚 Related

- **Project root**: [../README.md](../README.md)
- **API / gateway**: [../api/README.md](../api/README.md)
- **Feature-to-API usage**: [../FEATURE-USAGE.md](../FEATURE-USAGE.md)
