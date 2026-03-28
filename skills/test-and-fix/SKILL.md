---
name: webapp-qa-loop
description: Loop autonomo de QA para web apps. Lanza agentes en paralelo que prueban todas las paginas, detectan errores (500, campos rotos, datos vacios, templates rotos), arreglan bugs y repiten hasta que todo funcione perfecto. Usar cuando se diga "prueba la web", "testea la app", "QA loop", "arregla los errores de la web", "verifica que funciona", "qa-loop", o despues de hacer cambios grandes en una web app. Tambien usar proactivamente despues de crear o modificar multiples paginas web.
---

# Web App QA Loop

Loop autonomo de testing y correccion para web apps locales. Prueba todas las paginas, detecta errores, arregla bugs, y repite hasta que todo funcione.

## Flujo principal

### 1. Descubrir la app

Detectar automaticamente leyendo el proyecto:
- Buscar archivo principal (app/main.py, manage.py, server.py) para listar rutas
- Determinar URL base (default: http://localhost:8000 o :8001)
- Detectar si necesita auth (buscar login/auth en rutas)
- Verificar que el servidor esta corriendo (`curl -s -o /dev/null -w "%{http_code}" {URL}/`)
- Si no esta corriendo, arrancarlo

Si no se puede auto-detectar, preguntar al usuario: URL, credenciales, paginas clave.

### 2. Lanzar agentes de testing en paralelo

Dividir las paginas en 2-3 grupos y lanzar agentes simultaneamente (Agent tool con run_in_background=true, mode=auto):

**Prompt template para cada agente:**
```
Eres QA tester. Web app en {BASE_URL}. Auth: POST {BASE_URL}/login con {CREDENTIALS}.

Para cada pagina de tu lista:
1. curl con cookie -> verificar HTTP 200
2. Si 500: buscar error en logs, leer codigo fuente (.py + .html), ARREGLAR el bug, re-probar
3. Si 200: verificar que tiene datos reales (no "No hay datos" cuando deberia haberlos)
4. Probar filtros/busqueda con query params
5. Probar HTMX (header HX-Request: true) si la pagina usa htmx

Tu lista: {PAGINAS}

Si arreglas algo, re-probar inmediatamente. Reportar resultado por pagina.
```

**Division de grupos:**
- Grupo 1: Paginas de lectura (dashboard, listados, tablas de datos)
- Grupo 2: Paginas de detalle y joins complejos (detalle por ID, rentabilidades)
- Grupo 3: Paginas de accion (upload, generar, API endpoints)

### 3. Evaluar y iterar

Cuando los agentes terminen:
- Recopilar paginas OK vs con errores
- Si hay errores pendientes: lanzar agente build-error-resolver focalizado
- Re-probar las paginas corregidas
- Maximo 3 iteraciones

### 4. Reporte final

Tabla resumen al usuario:
```
| Pagina | Status | Datos | Bugs corregidos |
|--------|--------|-------|-----------------|
```

## Patrones de error comunes

**En HTML de respuesta:**
- `Internal Server Error` -> 500, buscar traceback en stderr del servidor
- `UndefinedError` -> campo Jinja2 que no existe en el contexto
- `None` visible -> falta manejo de nulls en template
- 0 filas en tabla que deberia tener datos -> query SQL roto

**En logs del servidor:**
- `ProgrammingError: column X does not exist` -> schema BD no coincide con modelo
- `ImportError: cannot import name X` -> modelo renombrado
- `AttributeError: X has no attribute Y` -> campo del modelo cambiado
- `UndefinedColumnError` -> tabla o columna no existe

**Fix pattern:** Leer error -> leer archivo .py que falla -> leer template .html -> editar -> reintentar curl.
