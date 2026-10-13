# Segunda auditoria del mismo panel, ya publicado en internet

Web publicada con login + 2FA tras un proxy inverso (Traefik) + WireGuard. Revisor Sonnet independiente sobre TODO `web/`
(39 PHP; 16 leidos enteros) + caja negra contra produccion por la sesion principal. Sin criticos ni altos.

## Lo que encontro (y no veian 247 pruebas funcionales)
- **Alta del 2FA con solo la contraseña**: usuario con `totp_activo=0` → el login ensenaba el secreto. Arreglo:
  ventana de alta de 24 h que abre un admin (`alta_2fa_hasta`), boton "reiniciar codigo" en Usuarios.
- **Limite de exportacion burlable**: "exige periodo" aceptaba `desde=1900-01-01`. Arreglo: como mucho un ejercicio.
- **Sesion que sobrevive a desactivar/degradar**: releer `activo` y `rol` en cada peticion + sesion maxima 12 h.
- **Carrera en el bloqueo**: 40 logins a la vez → 9 evaluados con limite 5. Arreglo: `GET_LOCK` por IP.
- Bajos: enumeracion por tiempo (hash ficticio), TOTP reutilizable (ultimo paso aceptado), CSP minima.

## Gotchas nuevos
- **Una cache de consultas generica cacheaba `SELECT GET_LOCK(...)`**: cualquier funcion con efecto o con estado
  (GET_LOCK, RELEASE_LOCK, LAST_INSERT_ID, CURRENT_USER...) tiene que estar en la lista de exclusion.
- **La proteccion anti-replay del TOTP rompe el arnes** si dos pasadas entran en la misma ventana de 30 s: el arnes
  pone a NULL el ultimo paso en la BD LOCAL al empezar.
- **`git archive | tar | grep -q` con `set -o pipefail`** da falso: el script de despliegue decia OK con columnas sin
  crear. Leer a una variable y `grep -q <<< "$var"`. (Mismo gotcha que el del arnes, en otra forma: buscarlo.)
- **Mutantes para validar las pruebas**: quitar el candado → la prueba de rafaga vio 9 y fallo; meter un estilo y un
  script en linea → la prueba de CSP vio 80 violaciones. Sin el mutante no se sabe si la prueba mide algo.
- **CSP estricta viable** si el codigo sigue pautas de estilo (sin inline): comprobarla con navegador real
  (`pruebas/prueba_csp.py` del proyecto: recoge "Content Security Policy" de la consola en todas las paginas).
- **Hallazgo fuera de la web**: el panel de EasyPanel del proxy (`:3000` y por IP) abierto a internet. Mirar SIEMPRE
  los puertos del proxy que publica la web, no solo la web.
- **Antivirus que bloquea el dominio nuevo**: guia completa en `plantillas/antivirus-falso-positivo.md`.
