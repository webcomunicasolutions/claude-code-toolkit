# Patterns

## Repository Pattern
Crear capa uniforme de acceso a datos:
- Interfaz abstracta: findAll, findById, create, update, delete
- Implementaciones concretas por storage (DB, API, archivo)
- Logica de negocio independiente del storage
- Facilita testing con mocks

## API Response Format
Formato consistente para todas las respuestas:

### Exito
```json
{
  "data": { ... },
  "meta": { "total": 100, "page": 1, "limit": 20 }
}
```

### Error
```json
{
  "error": {
    "code": "validation_error",
    "message": "Descripcion legible",
    "details": [{ "field": "email", "message": "Formato invalido" }]
  }
}
```

## Skeleton Projects
Al construir features nuevas:
1. Buscar proyectos skeleton battle-tested
2. Evaluar seguridad, extensibilidad, relevancia
3. Clonar como base
4. Adaptar a convenciones del proyecto

## Error Handling Pattern
```
try {
  // operacion
} catch (error) {
  // 1. Log detallado (para debugging)
  logger.error('Context:', { error, input, userId });
  // 2. Respuesta generica (para usuario)
  throw new AppError('Something went wrong', 500);
}
```

## Principios de diseno
- DRY pero no prematuro (3 repeticiones antes de abstraer)
- YAGNI (no construir para requisitos hipoteticos)
- Composicion sobre herencia
- Fail fast, fail loud
