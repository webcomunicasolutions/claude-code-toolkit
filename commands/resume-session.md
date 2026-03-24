---
description: Retomar una sesion guardada previamente
---

# Resume Session

Carga el estado de una sesion previa y orientate completamente ANTES de hacer cualquier trabajo.

## Instrucciones

1. Si no se proporciona argumento: busca el archivo mas reciente `*-session.md` en `~/.claude/sessions/`
2. Si se proporciona fecha (ej: 2024-01-15): busca archivos que coincidan con esa fecha
3. Si se proporciona ruta: lee ese archivo directamente

### Formato de briefing obligatorio:

```
**PROYECTO:** [nombre/tema]
**QUE ESTAMOS CONSTRUYENDO:** [resumen 2-3 frases]
**ESTADO ACTUAL:** [X funcionando / Y en progreso / Z sin empezar]
**QUE NO REINTENTAR:** [enfoques fallidos con razones]
**BLOCKERS / PREGUNTAS ABIERTAS:** [issues pendientes]
**PROXIMO PASO:** [accion exacta recomendada]
```

## Reglas criticas
- Lee el archivo COMPLETO antes de responder
- NUNCA modifiques el archivo de sesion (solo lectura)
- NO empieces a trabajar automaticamente - espera direccion del usuario
- Si no hay sesiones guardadas, informa y pregunta que hacer

$ARGUMENTS
