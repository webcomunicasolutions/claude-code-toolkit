---
name: database-migrations
description: Migraciones de base de datos seguras y reversibles. Patrones zero-downtime, expand-contract, backfill. Usar cuando se modifique esquema de BD en produccion.
---

# Database Migrations

## Principios
1. **Todo cambio es una migracion** -- nunca alterar BD manual en produccion
2. **Forward-only en produccion** -- rollbacks usan nuevas migraciones forward
3. **Schema y data separadas** -- nunca mezclar DDL y DML en misma migracion
4. **Testear contra data de tamano produccion**
5. **Migraciones inmutables** -- nunca editar una que ya corrio en produccion

## Safety Checklist
- [ ] Migration con UP y DOWN paths
- [ ] Sin full table locks en tablas grandes
- [ ] Nuevas columnas nullable o con defaults
- [ ] Indexes creados CONCURRENTLY
- [ ] Backfill de data en migracion separada
- [ ] Plan de rollback documentado

## Patrones PostgreSQL

### Agregar columna (seguro)
```sql
ALTER TABLE users ADD COLUMN avatar_url TEXT; -- nullable, no lock
```

### Index sin downtime
```sql
CREATE INDEX CONCURRENTLY idx_users_email ON users (email);
```

### Renombrar columna (expand-contract)
```
Fase 1: Agregar nueva columna (nullable)
Fase 2: App escribe en AMBAS (old y new)
Fase 3: Backfill data existente
Fase 4: App lee de NEW solamente
Fase 5: Drop columna vieja
```

### Large data migrations
```sql
-- Batch updates con SKIP LOCKED
UPDATE users SET new_col = old_col
WHERE id IN (
  SELECT id FROM users
  WHERE new_col IS NULL
  LIMIT 1000
  FOR UPDATE SKIP LOCKED
);
```

## Zero-Downtime: Expand-Contract
| Fase | Accion | Riesgo |
|------|--------|--------|
| Expand | Agregar nuevo (columna/tabla/index) | Bajo |
| Migrate | App usa ambos, backfill | Medio |
| Contract | Eliminar viejo | Bajo |

## Herramientas por stack
- TypeScript: Prisma, Drizzle, Kysely
- Python: Django migrations, Alembic
- Go: golang-migrate, goose
- Ruby: ActiveRecord migrations
