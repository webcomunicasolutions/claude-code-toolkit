---
name: docker-patterns
description: Patrones de Docker y Docker Compose para desarrollo y producción. Multi-stage builds, volumes, networking, security. Usar cuando se containerice aplicaciones.
---

# Docker Patterns

## Multi-stage Dockerfile
```dockerfile
# Build stage
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM node:22-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
USER app
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

## Docker Compose (desarrollo)
```yaml
services:
  app:
    build:
      context: .
      target: dev
    volumes:
      - .:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready"]
      interval: 5s

volumes:
  db_data:
```

## Service Discovery
- Services se comunican vía DNS con container names: `db:5432`
- Custom networks para segmentar tráfico

## Volumes
| Tipo | Uso |
|------|-----|
| Named volumes | Data persistente (BD, uploads) |
| Bind mounts | Código en desarrollo (hot-reload) |
| Anonymous volumes | Proteger deps del host (node_modules) |

## Security Hardening
- Correr como non-root user
- Drop capabilities innecesarias
- Usar tags específicos (nunca `:latest`)
- Secrets via environment files (no baked en layers)
- Scan de vulnerabilidades: `docker scout cves`

## Anti-patrones
- Docker Compose directo en producción
- No persistir data con volumes
- Hardcodear secrets en images
- Múltiples procesos por container
- Imágenes base sin actualizar
