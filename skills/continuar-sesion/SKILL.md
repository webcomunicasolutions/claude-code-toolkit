# Skill: continuar-sesion

> Prepara el traspaso de trabajo a la siguiente conversación cuando el contexto se está agotando.
> Invocar con `/continuar-sesion` o cuando el usuario diga "estamos en el límite", "pásale el trabajo", "prepara el relevo", "sesión nueva", "continuar en otra conversación".

## Qué hace

1. **Guarda el estado completo** del trabajo actual en la memoria del proyecto
2. **Crea una guía de continuación** específica para que la siguiente conversación retome sin perder nada
3. **Lista errores cometidos** para que no se repitan
4. **Actualiza MEMORY.md** con el estado actual
5. **Notifica por Telegram** si está configurado

## Proceso paso a paso

### Paso 1: Recopilar estado
Preguntar al usuario (o deducir del contexto):
- ¿Qué estábamos haciendo?
- ¿Qué está completado y verificado?
- ¿Qué está pendiente?
- ¿Qué errores cometí que no deben repetirse?
- ¿Qué archivos son clave para continuar?

### Paso 2: Crear memoria de sesión
Escribir en la carpeta de memoria del proyecto:
```
memory/project_estado_sesion_[FECHA].md
```

Con frontmatter:
```yaml
---
name: Estado sesión [proyecto] [fecha]
description: [resumen en 1 línea]
type: project
---
```

Contenido obligatorio:
- **Contexto**: qué estamos haciendo y por qué
- **Lo completado**: con nivel de confianza (verificado/asumido/no probado)
- **Lo pendiente**: en orden de prioridad
- **Archivos clave**: lista ordenada de qué leer primero
- **Conexiones/credenciales**: cómo acceder a los recursos
- **Errores cometidos**: lista honesta de equivocaciones para no repetir
- **Actitud requerida**: qué espera el usuario del siguiente Claude

### Paso 3: Actualizar MEMORY.md
Actualizar las primeras líneas con:
```
**ULTIMA SESION: [fecha]** → leer [archivo_memoria]
**PROXIMA SESION**: [tarea concreta siguiente]
**[CLAVE]**: [dato más importante que no debe perderse]
```

### Paso 4: Generar guía de continuación
Crear un bloque de texto que el usuario pueda copiar y pegar al inicio de la nueva conversación. Formato:

```markdown
## Guía para continuar el trabajo de [proyecto]

### Contexto en 3 líneas
[qué, por qué, para quién]

### Lee estos archivos EN ESTE ORDEN
1. [archivo más importante] — [por qué]
2. ...

### Lo que está hecho
[lista con nivel de confianza]

### Lo que NO está hecho
[lista priorizada]

### Conexiones
[credenciales y accesos]

### Errores que YO cometí y que tú NO debes repetir
[lista honesta]

### Actitud que el usuario exige
[reglas de comportamiento]
```

### Paso 5: Notificar (opcional)
Si hay Telegram configurado, enviar resumen breve.

## Reglas

- **No inventar** — si no sabes el estado de algo, di "no verificado"
- **Ser honesto sobre errores** — el usuario valora la honestidad por encima de todo
- **Priorizar** — los pendientes van en orden de importancia, no cronológico
- **Incluir queries/comandos** — que el siguiente pueda verificar sin adivinar
- **No duplicar** — si algo ya está en MEMORY.md, referenciarlo, no copiarlo


## Auto-mejora

Al cerrar cada aplicacion practica de esta skill:
1. Registrar aprendizajes en `aprendizajes/<caso>.md` (o en esta seccion si es breve)
2. Si el patron es generalizable, actualizar el cuerpo de este SKILL.md
3. Si se descubre un error recurrente, anadirlo a una seccion de "Errores conocidos"

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
