# Recuperación post-reboot: servicios en crashloop / 502 por DNS overlay de Swarm

**Caso real:** servidor con EasyPanel + Docker Swarm, reboot 2026-07-18
tras 54 días de uptime para activar kernel nuevo.

## Síntoma
Tras el reboot, la mayoría de servicios suben, pero algunos con dependencias
(Chatwoot, NocoDB) quedan en **crashloop** o dando **HTTP 502** intermitente,
aunque `docker service ls` los muestre fluctuando 1/1 ↔ 0/1.

En los logs (`docker service logs <servicio>`):
```
getaddrinfo: Name does not resolve (redis://..._redis:6379)
could not translate host name "..._db" to address: Name does not resolve
MaxRetriesPerRequestError (ioredis)
```

## Causa raíz
Tras un reboot, el **DNS embebido de Docker Swarm** (127.0.0.11) no re-registra
correctamente algunos servicios en la red overlay — típicamente los **Redis** y
a veces los **PostgreSQL**. El contenedor de BD/Redis está *running* y con IP,
pero su **nombre no resuelve** desde las tareas nuevas de los consumidores.
El consumidor (Rails/Node) arranca, no resuelve su dependencia, y muere antes de
levantar el puerto → crashloop → Traefik devuelve 502.

Agravante en Chatwoot: al arrancar corre `rails db:chatwoot_prepare` que aplica
**migraciones pendientes** (si lleva mucho sin reiniciarse, hay varias acumuladas);
la migración llama a Redis (`GlobalConfig.clear_cache`) y aborta por el DNS.
Las migraciones son transaccionales → hacen rollback, la BD NO queda a medias.

## Fix (dependencia primero, verificar, luego consumidor)
NO reiniciar el consumidor a ciegas (llega a 1/1 y vuelve a caer). Orden correcto:

1. **Refrescar el registro DNS de la dependencia** (re-registra en la overlay):
   ```bash
   docker service update --force --detach <stack>_<db|redis>
   ```
2. **VERIFICAR resolución** desde un contenedor de la MISMA red antes de seguir:
   ```bash
   docker exec <contenedor_misma_red> getent hosts <stack>_<db|redis>
   # debe devolver IP + nombre; si no, repetir paso 1
   ```
3. Solo cuando resuelva, **relanzar el consumidor**:
   ```bash
   docker service update --force --detach <stack>_<app>
   docker service update --force --detach <stack>_<app>-sidekiq   # si aplica
   ```
4. **Confirmar con HTTP real** (no solo réplicas 1/1): sondear el dominio hasta
   200/302. Rails tarda 1-3 min en levantar el puerto tras la migración.

Revisar TODOS los Redis del host (cada stack): el fallo suele afectar a varios.

## Verificación post-reboot recomendada (añadir a la fase Servicios)
- `wg show interfaces | wc -w` → nº de VPN esperado (aquí 23)
- `docker ps -q | wc -l` → nº de contenedores esperado (aquí 31)
- servicios swarm incompletos: `docker service ls` con `a[1]!=a[2]`
- **HTTP real** de cada web pública (n8n, NocoDB, Chatwoot, panel), no solo réplicas
- reglas iptables críticas que Docker vacía en reboot (aquí: candado MySQL 3306
  en DOCKER-USER; sobrevivió gracias a unit systemd `After=docker.service`)

## Gotcha de diagnóstico
Si el contenedor muere muy rápido, `docker logs <CID>` sale vacío o el CID ya no
existe. Usar **`docker service logs --tail N <servicio>`** (agrega todas las tareas,
incluidas las muertas) para capturar el error real.
