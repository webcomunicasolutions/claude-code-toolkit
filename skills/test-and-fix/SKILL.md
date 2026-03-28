---
name: test-and-fix
description: Loop autonomo de QA agresivo para web apps. Prueba todas las paginas con Playwright, detecta errores (500, JS crashes, pantallas blancas, datos vacios, peticiones fallidas), critica el diseno y la UX, lanza agentes reviewers (code, security, DB), arregla bugs y repite. Usar cuando se diga "prueba la web", "testea la app", "test-and-fix", "busca fallos", "critica la web", "QA agresivo", o despues de hacer cambios grandes.
---

# Web App QA Loop (Agresivo)

Loop autonomo de testing, critica y correccion para web apps. Prueba, critica, arregla, repite.

## Flujo principal

### Fase 1: Descubrir la app

Detectar automaticamente:
- Buscar main.py/App.tsx/routes para listar todas las paginas
- Determinar URL base (local o produccion)
- Detectar auth (login endpoint, credenciales en .credentials.json o CLAUDE.md)
- Verificar que el servidor responde

Si no se puede auto-detectar, preguntar al usuario.

### Fase 2: Test funcional con Playwright

Escribir un script Python con Playwright que:

1. **Login** y obtener sesion
2. **Navegar CADA pagina** con screenshot:
   - Verificar HTTP 200 (no timeout, no 500)
   - Verificar NO Error Boundary ("Algo salio mal")
   - Verificar NO pantalla blanca (body < 100 chars)
   - Verificar datos reales (tablas con filas, KPIs con numeros)
3. **Stress test** - navegar rapido entre todas las paginas x3 rondas (0.3s entre cada una):
   - Capturar errores JS con page.on("pageerror")
   - Capturar console.error con page.on("console")
   - Capturar network failures con page.on("requestfailed")
4. **Test interactivo**:
   - Command Palette (Ctrl+K) si existe
   - Busqueda en tablas
   - Clicks en detalle/modal
   - Filtros y dropdowns

### Fase 3: Test API

Probar CADA endpoint con curl/requests:
- Health check
- Todos los /reports/* con fechas (hoy, esta semana, este mes)
- Todos los CRUD (GET lista, GET detalle, POST si aplica)
- Endpoints especiales (sync, upload, AI)
- Verificar: status 200, datos no vacios, tiempos de respuesta

### Fase 4: Critica agresiva (lanzar agentes reviewers en paralelo)

Lanzar 3-5 agentes en paralelo con Agent tool (run_in_background=true):

- **code-reviewer**: Bugs, memory leaks, race conditions, codigo muerto
- **security-reviewer**: Vulnerabilidades, tokens, inyeccion, CORS
- **database-reviewer**: N+1 queries, indices, conexiones
- **principal-engineer**: Arquitectura, escalabilidad, deuda tecnica
- **devils-advocate**: Cuestionar decisiones de diseno

### Fase 5: Evaluar y arreglar

Recopilar todos los resultados:
1. **CRITICOS** (arreglar YA): 500s, crashes, datos corruptos, seguridad
2. **ALTOS** (arreglar pronto): Pantallas blancas intermitentes, datos vacios, UX rota
3. **MEDIOS** (planificar): Performance, deuda tecnica, mejoras
4. **BAJOS** (backlog): Cosmeticos, optimizaciones menores

Para los criticos y altos: arreglar directamente, rebuild, re-probar.
Maximo 3 iteraciones de fix + re-test.

### Fase 6: Reporte final

Generar tabla resumen:

```
REPORTE QA - {fecha}
========================
| Pagina/Test      | Status | Datos | Errores | Arreglados |
|------------------|--------|-------|---------|------------|
| Dashboard        | OK     | Si    | 0       | -          |
| /api/health      | OK     | -     | 0       | -          |
| Stress test 3x   | 31/33  | -     | 2 timeout| -         |

JS Errors: X | Network Fails: Y | Page Crashes: Z
Criticos: A | Altos: B | Medios: C | Bajos: D
```

## Patrones de error y fix

### Frontend (React/TypeScript)
- `TypeError: Cannot read properties of undefined` -> Falta optional chaining (?.)
- `Failed to fetch` -> Peticion cancelada por navegacion, manejar AbortError
- `insertBefore` / `removeChild` -> Extension del navegador, auto-reload en ErrorBoundary
- Pantalla blanca -> Error no capturado, necesita Error Boundary
- Datos vacios -> API devuelve [] cuando deberia tener datos, revisar query

### Backend (FastAPI/Python)
- `500 Internal Server Error` -> Excepcion no capturada, revisar logs
- `422 Validation Error` -> Schema Pydantic no coincide con request
- `502 Bad Gateway` -> Servicio externo caido (Gemini, etc)
- `time.sleep` bloqueante -> Cambiar a `await asyncio.sleep`
- Query N+1 -> Usar joinedload o subquery

### Base de datos (PostgreSQL)
- `column X does not exist` -> Modelo ORM no coincide con tabla
- `relation X does not exist` -> Tabla no creada, revisar migrations
- Sequential scan en tabla grande -> Falta indice

### Network
- `ERR_ABORTED` -> Peticion cancelada (normal al navegar rapido)
- `net::ERR_CONNECTION_REFUSED` -> Servidor caido
- `CORS error` -> Falta dominio en allow_origins

## Script base de test

```python
from playwright.sync_api import sync_playwright
import time, requests

BASE = "{URL}"
CREDENTIALS = {"username": "...", "password": "..."}

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_context(viewport={"width": 1280, "height": 800}).new_page()

    errors = []
    page.on("pageerror", lambda err: errors.append(str(err)))
    page.on("console", lambda msg: errors.append(msg.text) if msg.type == "error" else None)
    page.on("requestfailed", lambda req: errors.append(f"NET: {req.failure}"))

    # Login
    page.goto(f"{BASE}/login", wait_until="networkidle")
    page.fill('input[type="text"]', CREDENTIALS["username"])
    page.fill('input[type="password"]', CREDENTIALS["password"])
    page.click('button[type="submit"]')
    page.wait_for_url("**/")

    # Test each page...
    for route in ROUTES:
        page.goto(f"{BASE}{route}", wait_until="domcontentloaded", timeout=15000)
        time.sleep(1)
        body = page.inner_html("#root")  # or "body"
        # Check: len(body), "error" in body, screenshot

    browser.close()
```
