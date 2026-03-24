---
name: postgres-patterns
description: Best practices PostgreSQL - indexing, RLS, pagination, optimization, data types. Usar cuando se trabaje con PostgreSQL.
---

# PostgreSQL Patterns

## Data Types
| Uso | Tipo |
|-----|------|
| IDs | bigint (bigserial) |
| Strings | text |
| Fechas | timestamptz |
| Dinero | numeric(19,4) |
| JSON | jsonb |
| UUID | uuid con gen_random_uuid() |

## Indexes
```sql
-- B-tree (default)
CREATE INDEX idx_users_email ON users (email);

-- Composite (orden importa)
CREATE INDEX idx_orders ON orders (user_id, created_at DESC);

-- Partial (subset)
CREATE INDEX idx_active ON users (email) WHERE deleted_at IS NULL;

-- GIN (jsonb, arrays)
CREATE INDEX idx_tags ON posts USING GIN (tags);

-- Sin lock
CREATE INDEX CONCURRENTLY idx_name ON users (name);
```

## FK siempre indexados
```sql
CREATE INDEX idx_orders_user_id ON orders (user_id);
```

## Cursor Pagination
```sql
SELECT * FROM posts
WHERE created_at < $1
ORDER BY created_at DESC
LIMIT 20;
```

## Row Level Security
```sql
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
CREATE POLICY user_docs ON documents
  USING (user_id = (SELECT auth.uid()));
```

## Queue Pattern
```sql
SELECT * FROM jobs
WHERE status = 'pending'
ORDER BY created_at
LIMIT 1
FOR UPDATE SKIP LOCKED;
```

## UPSERT
```sql
INSERT INTO settings (key, value)
VALUES ('theme', 'dark')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value;
```
