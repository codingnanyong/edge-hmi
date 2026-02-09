# Stage 1: Build
# Build context: api/ (parent). Use: docker build -f hmi_web/Dockerfile .
FROM node:20-alpine AS build
WORKDIR /app

COPY hmi_web/package.json hmi_web/package-lock.json* ./
RUN npm install

COPY hmi_web/ .
RUN npm run build

# Stage 2: Serve
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY hmi_web/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
