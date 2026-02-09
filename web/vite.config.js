import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
export default defineConfig({
    plugins: [react()],
    base: '/',
    resolve: {
        alias: { '@': new URL('./src', import.meta.url).pathname },
    },
    server: {
        host: true,
        port: 8889,
        proxy: {
            '/openapi.json': { target: 'http://localhost:8000', changeOrigin: true },
            '/info': { target: 'http://localhost:8000', changeOrigin: true },
            '/health': { target: 'http://localhost:8000', changeOrigin: true },
            '/line_mst': { target: 'http://localhost:8000', changeOrigin: true },
            '/equip_mst': { target: 'http://localhost:8000', changeOrigin: true },
            '/sensor_mst': { target: 'http://localhost:8000', changeOrigin: true },
            '/worker_mst': { target: 'http://localhost:8000', changeOrigin: true },
            '/shift_cfg': { target: 'http://localhost:8000', changeOrigin: true },
            '/kpi_cfg': { target: 'http://localhost:8000', changeOrigin: true },
            '/alarm_cfg': { target: 'http://localhost:8000', changeOrigin: true },
            '/maint_cfg': { target: 'http://localhost:8000', changeOrigin: true },
            '/work_order': { target: 'http://localhost:8000', changeOrigin: true },
            '/parts_mst': { target: 'http://localhost:8000', changeOrigin: true },
            '/defect_code_mst': { target: 'http://localhost:8000', changeOrigin: true },
            '/measurement': { target: 'http://localhost:8000', changeOrigin: true },
            '/status_his': { target: 'http://localhost:8000', changeOrigin: true },
            '/prod_his': { target: 'http://localhost:8000', changeOrigin: true },
            '/defect_his': { target: 'http://localhost:8000', changeOrigin: true },
            '/alarm_his': { target: 'http://localhost:8000', changeOrigin: true },
            '/maint_his': { target: 'http://localhost:8000', changeOrigin: true },
            '/shift_map': { target: 'http://localhost:8000', changeOrigin: true },
            '/kpi_sum': { target: 'http://localhost:8000', changeOrigin: true },
        },
    },
    preview: {
        host: true,
        port: 8889,
    },
});
