# Stage 1: Build
# Build context: edge-hmi/ (project root). Use: docker build -f web/Dockerfile .
FROM node:20-alpine AS build
WORKDIR /app

COPY web/package.json web/package-lock.json* ./
RUN npm install

COPY web/ .
RUN npm run build

# Stage 2: Serve
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY web/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
