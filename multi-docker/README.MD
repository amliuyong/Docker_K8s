


## Overview
![Overview](./overview.jpg)

## docker compose
```
docker-compose up --build
```

```

version: '3'
services:
  postgres:
    image: 'postgres:latest'
  redis:
    image: 'redis:latest'
  nginx: 
    restart: always
    build:
      dockerfile: Dockerfile.dev
      context: ./nginx
    ports: 
       - '3050:80' 
  api:
    build:
      dockerfile: Dockerfile.dev
      context: ./server
    volumes:
      - /app/node_modules
      - ./server:/app
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - PGHOST=postgres
      - PGPORT=5432
      - PGUSER=postgres
      - PGDATABASE=postgres
      - PG
      
  client:
    build: 
      dockerfile: Dockerfile.dev
      context: ./client
    volumes:
      - /app/node_modules
      - ./client:/app
  worker:
    build: 
      dockerfile: Dockerfile.dev
      context: ./worker
    volumes:
      - /app/node_modules
      - ./worker:/app
    environment:
      - REDIS_HOST=redis
      - REDIS_PORT=6379
  

```


## Why nginx
![Why nginx](./why_nginx.jpg)

- no port mappings for express server in docker compose file
![Why nginx2](./why_nginx2.jpg)
![Why nginx3](./why_nginx3.jpg)

## Routing with nginx
![nginx_config](./nginx_config.jpg)

```config
# default.conf for nginx

upstream client {
    server client:3000;
}

upstream api {
    server api:5000;
}

server {
    listen 80;

    location / {
        proxy_pass http://client;
    }

    location /api {
        rewrite /api/(.*) /$1 break;
        proxy_pass http://api;
    }
}
```