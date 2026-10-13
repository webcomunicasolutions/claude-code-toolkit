# Checklist de tareas: no perder el hilo

Cuando el usuario encarga una lista de tareas, se lleva un checklist para ir cerrándolas una a una y no perder
el hilo. Aplica en todos los proyectos.

## Cuándo

- El usuario encarga **3 o más cosas** en un mensaje (o seguidas), o una tarea que claramente tiene varios pasos.
- **No** para una consulta suelta ni para 1-2 acciones triviales: el checklist sería ruido.

## Cómo

1. **Al recibir el encargo**, antes de empezar: escribir la lista numerada, **una línea por tarea**, con su criterio
   de «hecho» (qué prueba demuestra que está terminada). Si una tarea es ambigua, decirlo ahí, no al final.
2. **Dónde vive**: la lista de tareas del harness si existe (TaskCreate/TaskList). Si no, un fichero
   `TAREAS-EN-CURSO.md` en la carpeta del proyecto. **El chat no basta**: se pierde al compactar o al cambiar de sesión.
3. **Estados**: `[ ]` pendiente · `[~]` en curso (solo una a la vez) · `[x]` hecha · `[!]` bloqueada (con el motivo).
4. **Marcar `[x]` solo con evidencia** (salida de un comando, fichero verificado, respuesta del servicio), nunca
   porque «debería». Una hecha a medias o con avisos NO se marca hecha: se deja `[~]` y se explica.
5. **Al cerrar cada tarea**, mostrar la lista actualizada en dos líneas (hechas/pendientes), no el listado entero.
6. **Lo que surja por el camino** (algo nuevo que pida el usuario, un fallo descubierto) se **añade** a la lista.
7. **Al terminar el bloque**: cerrar con «N de N hechas» y, si queda algo, decir qué y por qué.
8. **Al retomar una sesión** (`/resume-session`): recrear la lista desde el fichero antes de seguir.

## Formato mínimo de `TAREAS-EN-CURSO.md`

```
# Tareas en curso — <proyecto> — <fecha>
Encargo: <una frase con lo que pidió el usuario>
- [x] 1. <tarea> — <evidencia en pocas palabras>
- [~] 2. <tarea>
- [ ] 3. <tarea> — hecho cuando: <criterio>
- [!] 4. <tarea> — bloqueada: <motivo / qué falta del usuario>
```

Cuando todo esté `[x]`, no borrarlo: dejarlo como histórico del día o moverlo a una carpeta de archivo.

## Límites honestos

- Es un hábito de trabajo, no un mecanismo automático: si la sesión se corta a mitad, el fichero es lo único que
  sobrevive.
- No sustituye a una agenda de pendientes con fecha ni al resumen de `/save-session`.
