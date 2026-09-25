# MySQL

## Estilo y seguridad
- Prepared statements SIEMPRE (PDO/mysqli), nunca concatenar input
- Charset/collation explicito en CREATE TABLE; preferir `utf8mb4`
- `--default-character-set=utf8mb4` al conectar el cliente CLI, si no
  los acentos se ven como `�` (problema de display, no de dato)
- NO exponer mensajes de error MySQL crudos al usuario

## Gotchas que cuestan horas (aprendidos en prod)

### No metas funciones en la condicion del JOIN
`ON f.Numero = SUBSTRING_INDEX(bd.factura,'-',-1)` impide usar indice ->
nested loop full scan. Sobre 1M+ filas no termina (16+ min). Solucion:
precalcular una columna real indexada y hacer JOIN por ella.

### Cross-DB JOIN con charset mixto invalida indices
Si dos BDs tienen collations distintas (ej. `utf8mb4_unicode_ci` vs
`utf8mb4_0900_ai_ci`), el JOIN entre columnas de texto necesita `COLLATE`
forzado, y ESO invalida el indice -> full scan. Patron correcto:
**tabla intermedia** en la MISMA BD/collation que el destino, poblada con
JOINs internos por columnas `int` (los enteros no tienen charset), luego
un solo UPDATE/JOIN por PK indexada. Pasa de 16 min colgado a segundos.

### MySQL 8.x NO es MariaDB
- `ADD COLUMN IF NOT EXISTS` es sintaxis MariaDB -> error 1064 en MySQL 8.x.
  Usar `ADD COLUMN` directo (o comprobar information_schema antes).

### ONLY_FULL_GROUP_BY (default en 8.x)
`GROUP BY` sobre el alias de un CASE que referencia otra columna -> error
1055. Solucion: DERIVED TABLE (calcular la expresion por fila en una
subconsulta, agrupar en la externa).

### MySQL 5.1 (sistemas legacy)
- `SHOW COLUMNS ... LIMIT` falla -> usar `DESCRIBE`
- `mysqldump 8.x --default-character-set=utf8mb4` contra 5.1 falla ->
  usar `utf8` (sin mb4) para el origen 5.1

### Antes de fiarte de un campo, mide contra datos reales
Que exista la columna + la FK en el DDL no significa que tenga datos. Un
campo "obvio" puede estar 99.98% NULL (deprecado). `SELECT COUNT(*) WHERE
campo IS NOT NULL` antes de construir sobre el.

## Indexacion
- Indice sobre las columnas del WHERE/JOIN mas selectivas
- `FORCE INDEX (idx)` cuando el optimizador elige mal (ej. usa idx_codigo
  por el GROUP BY cuando deberia usar idx_fecha del WHERE)
- Verificar con `EXPLAIN` antes y despues
- Covering index si la query solo lee columnas indexadas

## Operaciones masivas
- Backup ANTES de cualquier UPDATE/ALTER sobre tablas grandes
- Para detectar duplicados/mixtos antes de colapsar: `GROUP BY ... HAVING
  COUNT(DISTINCT x) > 1` (verifica supuestos en vez de asumirlos)
- UPDATE con JOIN por PK indexada en tabla intermedia >> UPDATE con
  subconsulta correlacionada por fila

## Testing
- Datos de prueba via factories/seeds reproducibles
- Verificar collation de columnas de JOIN ANTES de poblar
