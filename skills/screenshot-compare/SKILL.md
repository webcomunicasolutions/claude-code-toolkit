---
name: screenshot-compare
description: Captura screenshots de webs para comparar con implementaciones propias. Navega con nodriver (anti-bot), hace login si es necesario, y guarda capturas organizadas por sección. Ideal para verificar que una réplica coincide con la original.
triggers:
  - screenshot
  - captura
  - comparar web
  - comparar pantalla
  - sacar captura
---

# Screenshot Compare

Skill para capturar screenshots de aplicaciones web y compararlas con implementaciones propias.

## Uso

Cuando el usuario pida capturar screenshots de una web para comparar:

1. **Buscar credenciales**: Verificar si existe `.credentials.json` en el proyecto actual con las credenciales de login
2. **Ejecutar el script**: Usar `xvfb-run` para ejecutar el script de captura
3. **Guardar resultados**: Las capturas se guardan en `{proyecto}/capturas/` organizadas por fecha y sección

## Comando principal

```bash
xvfb-run --auto-servernum python3 ~/.claude/skills/screenshot-compare/capture.py \
  --url "https://example.com" \
  --login-url "https://example.com/login" \
  --credentials ".credentials.json" \
  --sections "dashboard,ordenes,clientes" \
  --output "./capturas"
```

## Parámetros

- `--url`: URL base de la web a capturar
- `--login-url`: URL de login (si requiere autenticación)
- `--credentials`: Path al JSON con credenciales (formato: {"username": "...", "password": "..."} o estructura anidada)
- `--sections`: Secciones/rutas a capturar separadas por coma
- `--output`: Carpeta de salida (default: ./capturas)
- `--wait`: Segundos de espera después de cargar cada página (default: 3)
- `--width`: Ancho del viewport (default: 1920)
- `--height`: Alto del viewport (default: 1080)

## Formato de credenciales

El script busca en el JSON las keys `username`/`password` o `user`/`pass` de forma recursiva. Soporta estructuras anidadas como:
```json
{
  "gestioo": {
    "login_url": "https://example.com/login",
    "username": "user@mail.com",
    "password": "pass123"
  }
}
```

## Resultado

Genera capturas PNG en la carpeta de output con formato:
```
capturas/
  2026-03-21_gestioo/
    01_dashboard.png
    02_ordenes.png
    03_clientes.png
    _metadata.json  (URLs, timestamps, resolución)
```

## Dependencias del sistema
- python3 con nodriver (`pip3 install --user nodriver`)
- xvfb (`apt install xvfb`)
- Google Chrome/Chromium
