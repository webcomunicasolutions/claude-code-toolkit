---
description: Crear plan de implementacion detallado antes de codificar
---

# Plan

Crea un plan de implementacion estructurado ANTES de escribir codigo.

## Instrucciones

Actua como arquitecto de software y planificador. Para la solicitud del usuario:

1. **Reformula requisitos** - Clarifica que se debe construir
2. **Analiza arquitectura actual** - Lee codigo relevante, identifica patrones existentes
3. **Identifica riesgos** - Que puede salir mal, dependencias, edge cases
4. **Crea plan por fases**:

### Formato del plan:

```
## Resumen
[1-2 frases de que se va a hacer y por que]

## Arquitectura
[Cambios estructurales necesarios, componentes afectados]

## Fases de implementacion

### Fase 1: [nombre]
- **Archivos:** [rutas exactas]
- **Acciones:** [que hacer en cada archivo]
- **Dependencias:** [que debe existir antes]
- **Riesgo:** bajo/medio/alto
- **Verificacion:** [como saber que funciona]

### Fase 2: [nombre]
...

## Testing
[Estrategia: que tests escribir, cobertura esperada]

## Riesgos y mitigaciones
| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|-------------|---------|------------|

## Criterios de exito
- [ ] [criterio verificable 1]
- [ ] [criterio verificable 2]
```

5. **STOP** - No escribas codigo hasta que el usuario apruebe el plan
6. El usuario puede pedir modificaciones, reordenar fases, o aprobar

## Cuando usar
- Features nuevas
- Cambios arquitecturales
- Refactoring complejo
- Cambios multi-archivo
- Especificaciones poco claras

$ARGUMENTS
