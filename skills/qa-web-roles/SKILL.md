---
name: qa-web-roles
description: Testeo sistematico a fondo de una web de cliente con dev-browser, probando ROL POR ROL (admin + cada usuario/rol), cazando fallos e inconsistencias, y entregando un informe accionable para el programador. Guarda memoria de fallos ya reportados para no repetir. Reutilizable en cualquier web: el METODO vive aqui, el QUE probar vive en la config del proyecto. Usar cuando se diga "testea la web", "prueba la pagina a fondo", "chequea con todos los usuarios", "saca todos los fallos", "QA de la web", "revisa el trabajo del programador". NOT para unit tests de codigo, ni para APIs sin UI (usar otras herramientas).
---

# QA de web por roles

Método reutilizable para probar a fondo una web de cliente con **dev-browser**, rol por rol,
y producir un **informe de fallos para el programador**. El MÉTODO es genérico; lo específico
de cada web (URLs, roles, requisitos, fallos conocidos) vive en la **config del proyecto**.

## Herramienta
`dev-browser` (navegador con scripts). Se lanza con un browser nombrado por proyecto
(`--browser <cliente>`) para aislar la sesión. Página nombrada `main`. Login vía formulario.
La sesión PHP puede caducar entre invocaciones: en cada script, comprobar si aparece el
login y re-autenticar si hace falta.

## Fase 0 — Config del proyecto (crear si no existe)
Buscar `qa/config.md` en la raíz del proyecto. Si no existe, crearla con:
- **URLs canónicas** (base + módulos), cada una con prueba+fecha (regla coordenadas-canónicas).
- **Roles y usuarios de prueba**: lista `usuario → rol`, y el PUNTERO al vault de las claves
  (nunca la clave en el archivo). Marcar cuáles no se tienen (p.ej. dueños).
- **Checklist de requisitos** a verificar (del acta/alcance del proyecto).
- **Permiso de datos**: `solo-lectura` | `zz-test` (crear datos ZZ_TEST y borrarlos) | `preguntar`.
- **Fallos conocidos / ya reportados**: para no volver a reportarlos (`qa/fallos-conocidos.md`).

## Fase 1 — Verificar coordenadas ANTES de probar
NO inventar URLs. Extraer los `href` reales del menú tras el login y contrastarlos con la config.
Si una URL da 404, es la llamada la que está mal, no el servidor: corregir la coordenada, no concluir "roto".

## Fase 2 — Autenticación y PERMISOS por rol
Para cada rol de la config:
1. Login. Registrar si la clave funciona.
2. Capturar el **menú visible** (qué módulos ve ese rol).
3. Intentar acceder **directo por URL** a 2-3 páginas que NO debería ver (admin, otros roles):
   ¿le redirige/bloquea, o entra? (fallo de autorización si entra).
4. Comparar entre roles: ¿hay roles distintos con permisos idénticos? ¿un rol no ve algo que necesita?
Salida: **matriz rol × módulo** (ve / no ve / entra-por-URL-aunque-no-debería).

## Fase 3 — Recorrido de módulos (detección de errores)
Con cada rol relevante, abrir cada módulo accesible y detectar:
- Errores HTTP (404/500), **warnings/notices de PHP** en el HTML, trazas, "Fatal error".
- Elementos rotos: tablas vacías que deberían tener datos, botones sin acción, enlaces muertos.
- Inconsistencias de UI/UX: textos placeholder, restos de otro cliente/plantilla, etiquetas equivocadas.
Capturar screenshot de cada anomalía.

## Fase 4 — Flujos clave (solo si permiso = zz-test o preguntar→OK)
Ejecutar los flujos del checklist de punta a punta con **datos marcados `ZZ_TEST`**:
- Crear → editar → verificar → **borrar/papelera** al terminar (limpieza obligatoria).
- Anotar qué se creó para garantizar su limpieza aunque falle a mitad.
- NUNCA tocar datos reales existentes del cliente. NUNCA operaciones destructivas de BD.
- Si permiso = `solo-lectura`: saltar esta fase.

## Fase 5 — Informe para el programador
Entregar `qa/informes/<fecha>-informe.md` y resumen en el chat. Cada hallazgo:
- **Título** corto · **Severidad** (bloqueante / grave / menor / cosmético).
- **Rol** con el que ocurre · **URL/módulo**.
- **Pasos para reproducir** (numerados, concretos).
- **Resultado observado** vs **esperado**.
- **Evidencia**: captura + fragmento de error si lo hay.
Ordenar por severidad. Solo hallazgos REALES y reproducibles (no rellenar por parecer minucioso;
un falso positivo es 3x peor que un hueco). Excluir los ya listados en fallos-conocidos.

## Fase 6 — Registrar y auto-mejorar
- Añadir los fallos nuevos a `qa/fallos-conocidos.md` (con estado: reportado/pendiente/resuelto).
- Al re-testear, marcar los que ya estén corregidos.

## Reglas de seguridad
- **Producción de cliente**: exige autorización explícita del usuario para crear/editar/borrar.
  Sin ella → `solo-lectura`.
- Datos de prueba SIEMPRE con prefijo `ZZ_TEST` y limpieza al final.
- **Evidencia antes de afirmar**: un fallo sin repro se descarta. Mostrar output/captura real.
- Credenciales: solo por puntero al vault, nunca escribir la clave en config/informe/chat.

## Errores típicos a buscar (aprendidos)
- **Adaptación de otra web**: campos de BD duplicados (p.ej. `nombre_comercial` viejo vs `nombre_fiscal` nuevo). El alta rellena uno y varios listados leen el otro sin fallback → datos "vacíos". Buscar `grep` del campo viejo y ver cuáles usan `?:`/`COALESCE` y cuáles no.
- **Sesión persistente entre scripts**: dev-browser mantiene la sesión PHP; SIEMPRE hacer `logout` + login explícito del rol objetivo, no fiarse de "si aparece el login". Confirmar el rol activo por ítems de menú exclusivos, no por una regex sobre todo el `aside` (el menú de admin contiene la palabra "Presupuestos" y da falsos positivos).
- **Falso positivo de `:invalid`**: al diagnosticar por qué un form no se envía, filtrar `form#<id> :invalid` SOLO del form objetivo. Los modales de la misma página tienen sus propios `<form>` con campos `required` ocultos (Nuevo Cliente, Nuevo Estado) que aparecen como `:invalid` global pero NO bloquean el submit de otro form. Verificar `.closest('form').id` antes de acusar.
- **Submit por AJAX**: muchos forms envían por fetch con handler JS; un `.click()` programático puede no disparar el flujo. Para probar el alta real, o disparar el submit del form (`form.requestSubmit()`) o hacer POST directo al endpoint y verificar en el listado. No reportar "no se puede crear X" sin descartar la fricción de automatización.

- **Fichajes con geolocalización**: si la página se queda en "Obteniendo ubicación…", conceder permiso
  desde dev-browser: `page.context().grantPermissions(["geolocation"], {origin}) + setGeolocation({lat,lng})`.
- **Foto obligatoria (cámara)**: `setInputFiles` de la sandbox falla (exige Buffer de Node). Crear el
  File DENTRO de la página: `new File([bytes], "foto.png")` + `DataTransfer` + `input.files = dt.files`
  + `dispatchEvent(new Event("change",{bubbles:true}))`.
- **"Execution context was destroyed" tras un click = la acción navegó** (casi siempre ÉXITO del submit).
  No repetir la acción a ciegas: recargar y verificar el estado antes de reintentar (riesgo de duplicados).
- **Modales custom sin clase `.modal`**: no fiarse de `closest(".modal")`. Listar TODOS los botones
  visibles tras abrir el modal y pulsar por texto exacto (p.ej. el último "Eliminar"/"Aceptar" visible).
  Si el modal usa un `<form method=POST>` interno, `form.submit()` es lo más fiable.
- **UI que ofrece acciones prohibidas ≠ agujero**: antes de reportar, probar el endpoint con el rol
  bloqueado (fetch con su sesión + CSRF de la página) y adjuntar la respuesta real ("Sin permiso").

## Auto-mejora
Al cerrar cada aplicación práctica de esta skill:
1. Registrar aprendizajes en `qa/fallos-conocidos.md` del proyecto y patrones nuevos aquí.
2. Si se descubre un método/atajo generalizable (p.ej. cómo detectar warnings PHP), actualizar este SKILL.md.
3. Si un tipo de fallo se repite entre proyectos, añadirlo a "Errores típicos a buscar".
