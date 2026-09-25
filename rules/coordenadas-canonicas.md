# Coordenadas canónicas — no inventar, verificar

Regla nacida de un fallo real: se perdió una sesión entera sondeando una URL equivocada de una API y
concluyendo "API caída" cuando el problema era el número de parámetros de la llamada. La causa raíz: inventar
coordenadas y NO parar a verificar el supuesto al primer fallo.

## Qué es una "coordenada"
Cualquier dato externo con el que se trabaja y que NO se debe adivinar:
- URLs (web, paneles, APIs, webhooks)
- Endpoints, rutas, firmas (nº y orden de params)
- Nombres de servidores, contenedores, bases de datos, tablas
- Rutas de archivos en remotos
- Referencias a credenciales (NUNCA el valor — eso va al vault)

## Regla 1 — Usar solo coordenadas canónicas del proyecto
Cada proyecto mantiene su ficha de coordenadas verificadas:
- `docs/COORDENADAS.md` (preferente) y/o una memoria enlazada desde el índice de memoria del proyecto.
- Cada coordenada lleva **prueba + fecha**: no "la web es X", sino
  "web → HTTP 302, verificado 2026-06-03". Un dato sin prueba envejece sin avisar.

Antes de llamar a una web/API/servidor/DB, leer la ficha. Si no existe, crearla
con lo que se verifique.

## Regla 2 — Ante un fallo, PARAR y verificar el supuesto
Si una llamada da 404 / timeout / auth-error / conexión rechazada:
1. **PARAR.** No lanzar 5 variantes a ciegas quemando tokens.
2. Contrastar el supuesto contra la ficha: ¿es la URL correcta? ¿el nº de
   params? ¿el nombre de contenedor (puede ser dinámico)? ¿la credencial?
3. Verificar en vivo UNA vez la coordenada dudosa (curl/ping mínimo).
4. **NUNCA** concluir "el servicio está caído / discontinuado" sin evidencia
   directa. Un 404 casi siempre es culpa de la llamada, no del servidor.

## Regla 3 bis — Credenciales: SIEMPRE el puntero, NUNCA el valor
En la ficha (y en la memoria del proyecto) toda coordenada que necesite credencial debe indicar
**que la clave existe y dónde está en el vault**, nunca el secreto:
- ✅ `pass en vault ~/.credentials/<proyecto>.json → .servidores.<host>`
- ❌ `pass: aB3x...` (un secreto en un doc acaba en git/backups → prohibido)
Si una coordenada no tiene su puntero al vault, falta media coordenada: añádelo.

## Regla 3 — Al verificar en vivo, registrar
Cada vez que se confirma una coordenada con una llamada real, actualizar la
ficha del proyecto (dato + prueba + fecha). Así la siguiente sesión no repite
el sondeo.

## Antipatrón prohibido
- Inventar variantes de URL/params/rutas e iterar contra ellas.
- Asumir "caído/discontinuado" sin prueba.
- Fiarse de una coordenada sin fecha de última verificación.
