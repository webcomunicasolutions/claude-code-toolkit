---
name: api-design
description: Diseno de REST APIs - convenciones, response formats, pagination, auth, rate limiting. Usar cuando se disenan o revisan endpoints API.
---

# API Design Patterns

## Resource URLs
- Plural, kebab-case: `/api/v1/user-profiles`
- Nested para relaciones: `/api/v1/users/{id}/orders`
- Maximo 3 niveles de nesting

## Metodos HTTP
| Metodo | Uso | Respuesta |
|--------|-----|-----------|
| GET | Obtener recurso(s) | 200 OK |
| POST | Crear recurso | 201 Created |
| PUT | Reemplazar recurso | 200 OK |
| PATCH | Actualizar parcial | 200 OK |
| DELETE | Eliminar recurso | 204 No Content |

## Response Format

### Exito
```json
{
  "data": { "id": "123", "name": "Alice" },
  "meta": { "total": 100, "page": 1 },
  "links": { "self": "/api/v1/users/123", "next": "/api/v1/users?page=2" }
}
```

### Error
```json
{
  "error": {
    "code": "validation_error",
    "message": "Request validation failed",
    "details": [
      { "field": "email", "message": "Invalid format", "code": "invalid_format" }
    ]
  }
}
```

## Pagination
- **Offset**: `?page=2&limit=20` -- simple pero lento en datasets grandes
- **Cursor**: `?cursor=abc123&limit=20` -- optimo para datasets grandes e infinite scroll

## Filtrado y ordenamiento
- Filtros: `?status=active&price[gte]=10`
- Orden: `?sort=-created_at` (- = descendente)
- Busqueda: `?q=wireless+headphones`
- Campos: `?fields=id,name,email`

## Autenticacion
- Bearer token en header `Authorization: Bearer <token>`
- Verificar propiedad del recurso antes de retornar datos
- RBAC (Role-Based Access Control) para permisos

## Rate Limiting
Headers obligatorios: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`

## Versionado
- URL path: `/api/v1/`, `/api/v2/` (recomendado)
- Maximo 2 versiones activas
- No-breaking: nuevos fields, endpoints, parametros opcionales
- Breaking changes -> nueva version
