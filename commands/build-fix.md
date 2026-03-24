---
description: Resolver errores de build/compilacion de forma sistematica
---

# Build Fix

Resuelve errores de build incrementalmente con cambios minimos.

## Instrucciones

1. **Detecta el sistema de build**: busca package.json, tsconfig.json, Cargo.toml, go.mod, pyproject.toml, Makefile
2. **Ejecuta el build**: usa el comando apropiado (npm run build, cargo build, go build, etc.)
3. **Si hay errores**:
   - Agrupa errores por archivo
   - Ordena por dependencia (arregla imports/tipos antes que logica)
   - Para CADA error:
     a. Lee el archivo afectado
     b. Diagnostica la causa raiz
     c. Aplica el cambio MINIMO posible
     d. Re-ejecuta el build
     e. Verifica que no introdujo regresiones
4. **Repite** hasta build limpio

## Principios
- Arregla UN error a la vez
- Prefiere diffs minimos sobre refactoring
- NUNCA cambies logica de negocio para arreglar un error de tipos
- Si un fix genera mas errores de los que resuelve -> consulta al usuario
- Si el mismo error persiste tras 3 intentos -> consulta al usuario

## Cuando escalar al usuario
- Cambios arquitecturales necesarios
- Dependencias faltantes que requieren instalacion
- Conflictos de versiones entre paquetes
- Errores de configuracion del entorno

$ARGUMENTS
