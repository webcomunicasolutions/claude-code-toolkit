---
description: Crear/actualizar la ficha CLAUDE.md de un CLIENTE (capa padre) escaneando sus subproyectos. Contexto de empresa compartido por todos los proyectos del cliente.
argument-hint: "[cliente|all] (opcional; por defecto, el cliente de la carpeta actual)"
---

# Ficha de cliente (capa padre)

Genera o actualiza el `CLAUDE.md` que vive en la carpeta de un CLIENTE
(`~/proyectos/clientes/<cliente>/CLAUDE.md`; ajusta la ruta a tu estructura). Ese archivo se **auto-carga**
en TODOS los subproyectos del cliente (Claude Code lee los CLAUDE.md subiendo por el
arbol), asi que da el contexto de empresa una sola vez para todos sus proyectos.

Es la **capa cliente**, por encima de la capa proyecto (el `CLAUDE.md` de cada subproyecto).

## Objetivo del cliente (argumento)

`$ARGUMENTS` puede ser:
- **vacio**: deducir el cliente de la ruta actual (la carpeta directa bajo la carpeta de clientes).
- **un nombre** (p.ej. `acme`): ese cliente.
- **`all` / `todos`**: modo batch; recorrer todos los clientes que NO tengan aun `CLAUDE.md` y generar un borrador para cada uno. Informar al final con una tabla de cuantos huecos ⬜ quedan por cliente.

## Paso 1 - Reunir contexto SOLO verificable

Escanear las fuentes del cliente y de sus subproyectos y quedarse unicamente con datos con evidencia:
- `README.md`, `CLAUDE.md` y `*.md` de cabecera de cada subproyecto.
- Memorias de los subproyectos, si existen.
- Credenciales: comprobar si existen en tu gestor de credenciales (NO leer secretos; dejar solo el puntero).
- Nombres de las subcarpetas (una linea de que es cada proyecto).

## Paso 2 - Reglas anti-invencion (criticas)

- Solo escribir datos **explicitamente presentes** en las fuentes. Nada de deducir sector, tamano, contactos o fechas "por contexto".
- Todo lo que no se pueda verificar se deja como **`⬜`** con una nota minima de que falta. Un hueco honesto vale mas que un dato inventado.
- **NUNCA** meter secretos (passwords, tokens, IPs sensibles) en la ficha: solo punteros a tu gestor de credenciales.
- No inventar el estado de un proyecto: si no hay evidencia de si esta activo/pausado, `⬜`.

## Paso 3 - Escribir `<cliente>/CLAUDE.md` con este formato

```markdown
# CLAUDE.md - Cliente: <Razon social> (<nombre corto>)

> Ficha del CLIENTE (capa padre). Se auto-carga en todos los proyectos internos.
> ⬜ = por confirmar. Credenciales SIEMPRE en tu gestor, aqui solo punteros.

## Quien es el cliente
- **Razon social / nombre:** ...
- **Sector / a que se dedica:** ...  (⬜ si no consta)
- **Ubicacion:** ...
- **Tamano / antiguedad como cliente:** ⬜

## Personas clave
| Persona | Rol | Notas (usuario, email, tel - sin secretos) |
|---|---|---|
| ... | ... | ... |

## Infraestructura (resumen; detalle en cada proyecto)
- Servidores / dominios / ERP / accesos: punteros a la subcarpeta que lo detalla.
- **Credenciales:** puntero a tu gestor de credenciales.

## Proyectos para este cliente
| Carpeta | Que es | Estado |
|---|---|---|
| `xxx/` | ... | ⬜ |

## Como trabajar en este cliente
- Notas de rol / lineas rojas si las hay.
```

Mantener la ficha **concisa** (objetivo < 60 lineas). El detalle fino vive en cada subproyecto.

## Paso 4 - Idempotencia (cliente que YA tiene ficha)

- **Preservar** todo lo que el humano ya relleno (huecos ya completados no se pisan).
- Anadir subproyectos nuevos; no borrar secciones escritas a mano.
- Si hay conflicto entre la ficha y lo escaneado, senalarlo en la respuesta, no sobrescribir a ciegas.

## Paso 5 - Cerrar

- Reportar la lista de **huecos `⬜`** que quedan y pedir al usuario que los complete (puede dictarlos).
- En modo `all`, entregar una tabla `cliente -> n de ⬜ pendientes`.
