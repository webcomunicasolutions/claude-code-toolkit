---
name: n8n-workflow
description: Crear, modificar y optimizar workflows de n8n con nodos, conexiones y configuraciones. Usar cuando se trabaja con automatizaciones n8n, se mencionan workflows, o se necesita integrar servicios.
---

# n8n Workflow Specialist

## Activación Automática

Este skill se activa cuando el usuario:
- Menciona "n8n", "workflow", "automatización", "flujo"
- Pide crear, modificar o debuggear un workflow
- Necesita integrar servicios externos
- Pregunta sobre nodos específicos de n8n

## Proceso de Trabajo con n8n

### FASE 1: Entender el Requerimiento

```yaml
Preguntas clave:
  1. ¿Qué quieres automatizar exactamente?
  2. ¿Qué trigger inicia el proceso? (webhook, schedule, manual, evento)
  3. ¿Qué servicios/APIs necesitas conectar?
  4. ¿Qué datos entran y qué datos salen?
  5. ¿Qué pasa si hay un error?
```

### FASE 2: Diseñar el Flujo

```yaml
Pasos:
  1. Identificar el trigger (inicio del workflow)
  2. Mapear los pasos intermedios
  3. Definir transformaciones de datos
  4. Planificar manejo de errores
  5. Determinar la salida/respuesta
```

### FASE 3: Implementar

```yaml
Orden de implementación:
  1. Crear nodo trigger
  2. Añadir nodos de procesamiento
  3. Configurar conexiones
  4. Añadir manejo de errores
  5. Probar con datos reales
```

### FASE 4: Optimizar y Documentar

```yaml
Checklist final:
  - [ ] Nombres descriptivos en todos los nodos
  - [ ] Sticky notes explicando lógica compleja
  - [ ] Error handling configurado
  - [ ] Credenciales usando variables (no hardcoded)
  - [ ] Workflow probado end-to-end
```

---

## Catálogo de Nodos n8n

### Triggers (Inicio del Workflow)

| Nodo | Tipo | Cuándo usar |
|------|------|-------------|
| **Webhook** | `n8n-nodes-base.webhook` | Recibir datos HTTP externos |
| **Schedule** | `n8n-nodes-base.scheduleTrigger` | Ejecutar periódicamente (cron) |
| **Manual** | `n8n-nodes-base.manualTrigger` | Ejecución manual/testing |
| **Email Trigger** | `n8n-nodes-base.emailTrigger` | Al recibir email |
| **Webhook Test** | `n8n-nodes-base.webhook` + responseMode | APIs que esperan respuesta |

### Procesamiento de Datos

| Nodo | Tipo | Cuándo usar |
|------|------|-------------|
| **Set** | `n8n-nodes-base.set` | Crear/modificar campos |
| **Code** | `n8n-nodes-base.code` | Lógica JavaScript/Python personalizada |
| **IF** | `n8n-nodes-base.if` | Bifurcación condicional |
| **Switch** | `n8n-nodes-base.switch` | Múltiples rutas condicionales |
| **Merge** | `n8n-nodes-base.merge` | Combinar datos de ramas |
| **Split In Batches** | `n8n-nodes-base.splitInBatches` | Procesar arrays por lotes |
| **Item Lists** | `n8n-nodes-base.itemLists` | Manipular arrays/listas |
| **Date & Time** | `n8n-nodes-base.dateTime` | Operaciones con fechas |
| **Crypto** | `n8n-nodes-base.crypto` | Hash, encrypt, etc. |

### Integraciones Comunes

| Nodo | Tipo | Uso típico |
|------|------|------------|
| **HTTP Request** | `n8n-nodes-base.httpRequest` | Llamar cualquier API |
| **Respond to Webhook** | `n8n-nodes-base.respondToWebhook` | Responder al trigger |
| **Gmail/Email** | `n8n-nodes-base.gmail` | Enviar/leer emails |
| **Slack** | `n8n-nodes-base.slack` | Mensajes Slack |
| **Google Sheets** | `n8n-nodes-base.googleSheets` | Leer/escribir hojas |
| **Notion** | `n8n-nodes-base.notion` | Bases de datos Notion |
| **Airtable** | `n8n-nodes-base.airtable` | Bases de datos Airtable |
| **OpenAI** | `@n8n/n8n-nodes-langchain.openAi` | GPT, embeddings |
| **Postgres/MySQL** | `n8n-nodes-base.postgres` | Bases de datos SQL |

### Control de Flujo

| Nodo | Tipo | Cuándo usar |
|------|------|-------------|
| **Wait** | `n8n-nodes-base.wait` | Pausar ejecución |
| **Loop Over Items** | `n8n-nodes-base.splitInBatches` | Iterar sobre array |
| **Error Trigger** | `n8n-nodes-base.errorTrigger` | Capturar errores globales |
| **Stop and Error** | `n8n-nodes-base.stopAndError` | Terminar con error |
| **No Operation** | `n8n-nodes-base.noOp` | Placeholder/debugging |
| **Execute Workflow** | `n8n-nodes-base.executeWorkflow` | Llamar otro workflow |

---

## Patrones Comunes de Workflows

### 1. Webhook → Procesar → Responder

```
Webhook ──► Set (transformar) ──► Respond to Webhook
```

Uso: APIs, integraciones, recibir datos externos

### 2. Schedule → Obtener datos → Procesar → Notificar

```
Schedule ──► HTTP Request ──► IF (validar) ──► Slack/Email
                                    │
                                    └──► (nada si no hay cambios)
```

Uso: Monitoreo, alertas, sincronización periódica

### 3. Webhook → Validar → Switch por tipo → Múltiples acciones

```
Webhook ──► IF (validar) ──► Switch ──► Acción A
                                   ├──► Acción B
                                   └──► Acción C
```

Uso: APIs con múltiples endpoints, procesamiento condicional

### 4. Trigger → Loop por items → Acción por cada uno

```
Trigger ──► Split In Batches ──► HTTP Request ──► (loop back)
                    │
                    └──► Merge ──► Resultado final
```

Uso: Procesar listas, llamar API por cada item

### 5. Workflow con Error Handling

```
Trigger ──► Try (nodos principales) ──► Éxito
                    │
              Error Trigger ──► Notificar error ──► Log
```

Uso: Cualquier workflow que necesite robustez

---

## Expresiones n8n Más Útiles

### Acceder a datos

```javascript
// Dato del nodo actual
{{ $json.campo }}
{{ $json.objeto.subcampo }}
{{ $json["campo con espacios"] }}

// Dato de nodo específico
{{ $('Nombre Nodo').item.json.campo }}

// Todos los items de un nodo
{{ $('Nombre Nodo').all() }}

// Item actual en loop
{{ $item }}
{{ $itemIndex }}
```

### Transformaciones comunes

```javascript
// Fecha actual
{{ $now.toISO() }}
{{ $now.format('yyyy-MM-dd') }}

// Condicionales
{{ $json.valor ? 'si' : 'no' }}
{{ $json.campo ?? 'valor por defecto' }}

// Strings
{{ $json.texto.toLowerCase() }}
{{ $json.texto.trim() }}
{{ $json.texto.split(',') }}

// Arrays
{{ $json.array.length }}
{{ $json.array.map(x => x.id) }}
{{ $json.array.filter(x => x.activo) }}

// JSON
{{ JSON.stringify($json) }}
{{ JSON.parse($json.stringJson) }}
```

### Variables de entorno

```javascript
// Variables del workflow
{{ $vars.MI_VARIABLE }}

// Variables de entorno del sistema
{{ $env.MI_ENV_VAR }}
```

---

## Código JavaScript en nodo Code

### Template básico

```javascript
// Para cada item
for (const item of $input.all()) {
  // Procesar
  item.json.nuevoCampo = item.json.existente.toUpperCase();
}

return $input.all();
```

### Crear nuevos items

```javascript
const resultados = [];

for (const item of $input.all()) {
  resultados.push({
    json: {
      id: item.json.id,
      procesado: true,
      timestamp: new Date().toISOString()
    }
  });
}

return resultados;
```

### Llamar API desde Code

```javascript
const response = await this.helpers.httpRequest({
  method: 'POST',
  url: 'https://api.ejemplo.com/endpoint',
  headers: {
    'Authorization': 'Bearer ' + $json.token
  },
  body: {
    data: $json.datos
  }
});

return [{ json: response }];
```

### Manejo de errores en Code

```javascript
try {
  // Lógica principal
  const resultado = procesarDatos($json);
  return [{ json: { success: true, data: resultado } }];
} catch (error) {
  return [{ json: { success: false, error: error.message } }];
}
```

---

## Estructura JSON de Workflow

### Workflow completo

```json
{
  "name": "Mi Workflow",
  "nodes": [
    {
      "id": "uuid-1",
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "position": [250, 300],
      "webhookId": "uuid-webhook",
      "parameters": {
        "path": "mi-endpoint",
        "responseMode": "responseNode",
        "options": {}
      },
      "typeVersion": 2
    },
    {
      "id": "uuid-2",
      "name": "Procesar",
      "type": "n8n-nodes-base.set",
      "position": [450, 300],
      "parameters": {
        "mode": "manual",
        "duplicateItem": false,
        "assignments": {
          "assignments": [
            {
              "id": "uuid-assign",
              "name": "resultado",
              "value": "={{ $json.input }}",
              "type": "string"
            }
          ]
        }
      },
      "typeVersion": 3.4
    },
    {
      "id": "uuid-3",
      "name": "Responder",
      "type": "n8n-nodes-base.respondToWebhook",
      "position": [650, 300],
      "parameters": {
        "respondWith": "json",
        "responseBody": "={{ $json }}"
      },
      "typeVersion": 1.1
    }
  ],
  "connections": {
    "Webhook": {
      "main": [[{ "node": "Procesar", "type": "main", "index": 0 }]]
    },
    "Procesar": {
      "main": [[{ "node": "Responder", "type": "main", "index": 0 }]]
    }
  },
  "settings": {
    "executionOrder": "v1"
  },
  "staticData": null,
  "pinData": {}
}
```

---

## Mejores Prácticas

### Nombrado

```yaml
Nombres buenos:
  - "Recibir pedido webhook"
  - "Validar datos cliente"
  - "Buscar en base de datos"
  - "Notificar por Slack si error"

Nombres malos:
  - "Set"
  - "HTTP Request"
  - "Code1"
  - "IF"
```

### Error Handling

```yaml
Siempre incluir:
  1. Error Trigger workflow separado para errores globales
  2. Try/catch en nodos Code
  3. Validación de datos antes de procesar
  4. Notificación cuando hay errores críticos
```

### Performance

```yaml
Optimizaciones:
  - Usar Split In Batches para arrays grandes (>100 items)
  - Limitar datos con Select para no pasar campos innecesarios
  - Cachear respuestas de APIs cuando sea posible
  - Usar ejecución paralela cuando los pasos son independientes
```

### Seguridad

```yaml
Reglas:
  - NUNCA hardcodear API keys en parámetros
  - Usar Credentials de n8n para secrets
  - Validar inputs de webhooks externos
  - Sanitizar datos antes de usar en queries SQL
```

---

## Debugging

### Técnicas

```yaml
1. Ejecución paso a paso:
   - Ejecutar workflow manualmente
   - Revisar output de cada nodo

2. Pin data:
   - Fijar datos de un nodo para testing
   - Evitar llamar APIs mientras debuggeas

3. Console en Code:
   - Usar console.log() para debug
   - Ver logs en la ejecución

4. Nodo NoOp:
   - Insertar para ver datos intermedios
   - No afecta el flujo
```

### Errores comunes

```yaml
"Cannot read property X of undefined":
  - El campo no existe en el JSON
  - Usar optional chaining: $json.campo?.subcampo

"The workflow cannot be executed":
  - Revisar conexiones entre nodos
  - Verificar que hay un trigger

"Rate limit exceeded":
  - Añadir Wait entre llamadas
  - Usar Split In Batches con delay

"Invalid credentials":
  - Verificar credenciales en n8n
  - Renovar tokens si expiraron
```

---

## Recursos para Consultar (via WebSearch)

Cuando necesites información actualizada, buscar en:

```yaml
Documentación oficial:
  - docs.n8n.io/integrations/         # Nodos específicos
  - docs.n8n.io/code/                 # Código y expresiones
  - docs.n8n.io/workflows/            # Conceptos de workflows

Comunidad:
  - community.n8n.io                  # Foro con soluciones
  - n8n.io/workflows                  # Templates oficiales

Búsquedas útiles:
  - "n8n [nombre nodo] example"
  - "n8n [integración] tutorial"
  - "n8n error [mensaje error]"
```

---

## Flujo de Trabajo Recomendado

Cuando el usuario pida ayuda con n8n:

```yaml
1. ENTENDER:
   - ¿Qué quiere automatizar?
   - ¿Qué servicios necesita conectar?

2. DISEÑAR:
   - Proponer el flujo visualmente (texto/diagrama)
   - Identificar nodos necesarios

3. IMPLEMENTAR:
   - Generar JSON del workflow
   - Explicar cada parte

4. PROBAR:
   - Sugerir datos de prueba
   - Anticipar posibles errores

5. OPTIMIZAR:
   - Revisar mejoras posibles
   - Añadir error handling si falta
```
