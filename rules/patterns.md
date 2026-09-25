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

## Error Handling Pattern (Agentic)
Errores siempre detallados - nunca genericos. Incluir:
1. **Que fallo** - operacion y contexto
2. **Que se intento** - pasos ejecutados
3. **Resultados parciales** - datos recuperados antes del fallo
4. **Siguiente paso sugerido** - que mas se puede probar

```
try {
  // operacion
} catch (error) {
  // 1. Log detallado (para debugging)
  logger.error('Context:', { error, input, userId, attempted, partialResults });
  // 2. Respuesta con contexto para reintentos
  throw new AppError('Something went wrong', 500, {
    what_failed: 'operation description',
    attempted: ['step1', 'step2'],
    partial_results: partialData,
    suggested_next: 'alternative approach'
  });
}
```

## Few-Shot over Instructions
- 2-3 ejemplos reales de input/output superan a una pagina de instrucciones
- Claude aprende el patron subyacente, no solo el formato
- Usar en: prompts de extraccion, templates de automatizacion, system prompts de skills

## Principios de diseno
- DRY pero no prematuro (3 repeticiones antes de abstraer)
- YAGNI (no construir para requisitos hipoteticos)
- Composicion sobre herencia
- Fail fast, fail loud
