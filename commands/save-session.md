---
description: Guardar estado de sesion actual para retomar despues
---

# Save Session

Captura y preserva el contexto de trabajo actual para retomarlo en futuras sesiones.

## Instrucciones

1. Ejecuta `mkdir -p ~/.claude/sessions/` si no existe
2. Revisa TODOS los cambios, decisiones, errores y progreso de esta sesion
3. Crea un archivo con formato `YYYY-MM-DD-<descripcion-corta>-session.md` en `~/.clone/sessions/`
4. El archivo DEBE contener TODAS estas secciones (usa "N/A" si no aplica, nunca omitas):

### Plantilla obligatoria:

```
# Sesion: [titulo descriptivo]
**Fecha:** YYYY-MM-DD HH:MM
**Proyecto:** [ruta del proyecto]

## Que estamos construyendo
[1-3 parrafos con contexto suficiente para alguien que no conoce la sesion]

## Que FUNCIONO (solo exitos confirmados)
- [Exito con evidencia: test results, comportamiento verificado]

## Que NO funciono (CRITICO - previene reintentos)
- [Enfoque fallido]: [error exacto / razon del fallo]

## Que NO se ha intentado aun
- [Enfoques prometedores sin probar]

## Estado actual de archivos
| Archivo | Estado | Notas |
|---------|--------|-------|
| path/file | modificado/nuevo/eliminado | detalle |

## Decisiones tomadas
- [Decision]: [razon/tradeoff]

## Blockers y preguntas abiertas
- [Issue sin resolver]

## Proximo paso exacto
[Una sola accion precisa para retomar con minimo esfuerzo cognitivo]
```

5. Muestra el archivo creado y pide confirmacion al usuario
6. La seccion "Que NO funciono" es la mas importante - previene que futuras sesiones reintenten enfoques fallidos
