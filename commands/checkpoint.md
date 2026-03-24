---
description: Crear punto de control del estado actual del codigo
---

# Checkpoint

Gestiona snapshots del estado del codigo para comparar progreso.

## Instrucciones

Operaciones disponibles segun el argumento:

### `create [nombre]` (default)
1. Verifica que el estado de git esta limpio (commit o stash cambios pendientes)
2. Crea un git tag ligero: `checkpoint-[nombre]-[timestamp]`
3. Registra en `.claude/checkpoints.log`: timestamp, nombre, SHA, branch
4. Confirma: "Checkpoint '[nombre]' creado en [SHA corto]"

### `list`
1. Lee `.claude/checkpoints.log`
2. Muestra todos los checkpoints con: nombre, fecha, SHA, distancia desde HEAD

### `compare [nombre]`
1. Busca el checkpoint por nombre en el log
2. Ejecuta `git diff [checkpoint-SHA]...HEAD`
3. Reporta: archivos cambiados, lineas anadidas/eliminadas
4. Si hay tests: compara resultados antes/despues

### `clear`
1. Elimina todos los tags de checkpoint excepto los ultimos 5
2. Limpia entradas antiguas del log

$ARGUMENTS
