# Puertos - Seguridad

## Regla absoluta
NUNCA lanzar un servidor o servicio en un puerto sin verificar que esta libre.

## Procedimiento obligatorio
1. `lsof -i :<puerto> | grep LISTEN` antes de usar cualquier puerto
2. Si esta ocupado: NO matar el proceso, buscar otro puerto
3. Usar puertos altos (9100+) para tests temporales
4. Guardar el PID del proceso lanzado para matarlo al terminar
5. Al terminar: matar SOLO tu proceso, nunca otros

## Prohibido
- Asumir que un puerto esta libre
- Matar procesos de otros proyectos
- Usar puertos comunes (3000-8999) para tests sin verificar

## Gotcha: `until ! pgrep -f "patron"` se autodetecta (bucle infinito)

Detectado en un proyecto real: se dejaron **varias tareas de background colgadas para siempre**
esperando a procesos que ya habian terminado.

```bash
# MAL: el pgrep encuentra el propio shell que ejecuta el bucle,
#      porque "mi_script.py" aparece en SU linea de comandos -> nunca sale
until ! pgrep -f "mi_script.py" >/dev/null; do sleep 10; done

# BIEN: truco del corchete, no coincide consigo mismo
until ! pgrep -f "[m]i_script.py" >/dev/null; do sleep 10; done

# MEJOR: esperar a un PID concreto
lanzar_proceso & PID=$!
until ! kill -0 "$PID" 2>/dev/null; do sleep 10; done
```

**Y comprobar siempre las tareas del harness al cerrar**, no solo `pgrep` desde otro shell:
un `pgrep` externo NO las ve como pendientes porque estan dormidas en `sleep`. Revisar con
`/tasks` o el estado de tareas en background antes de dar una sesion por limpia.
