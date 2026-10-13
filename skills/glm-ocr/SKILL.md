---
name: glm-ocr
description: Uso correcto del modelo GLM-OCR (zai-org, ~0.9B) en Ollama para OCR de facturas y documentos. Usar cuando se trabaje con glm-ocr, un microservicio OCR propio, transcripción/tablas con triggers oficiales, o se evalúe GLM frente a producción (PaddleOCR+Gemini). Triggers - "glm-ocr", "Text Recognition", "Table Recognition", "Information Extraction GLM", "transcribir factura con GLM", "OCR local con GLM".
---

# GLM-OCR — uso correcto

Modelo de visión-OCR de `github.com/zai-org/GLM-OCR` (~0.9-1.1B, F16). En Ollama como
`glm-ocr:latest`. Es un modelo **pequeño y especializado**: brilla TRANSCRIBIENDO lo que ve,
pero NO razona ni respeta formatos JSON complejos. Toda la guía de abajo nace de un benchmark
real con facturas españolas (junio 2026).

## Regla nº1: triggers OFICIALES, NUNCA lenguaje natural

GLM-OCR se entrenó con prompts-trigger cortos. Pedirle cosas en español ("Transcribe todo el
texto de esta factura...") funciona PEOR y es inestable. Usa los triggers exactos:

| Modo | Trigger | Para qué |
|------|---------|----------|
| Texto | `Text Recognition:` | Transcribe TODO el documento (cabecera + tabla + totales). OCR completo. |
| Tabla | `Table Recognition:` | Reconoce tablas → HTML nativo (`<table>`). Estructura columnas. |
| Fórmula | `Formula Recognition:` | Fórmulas matemáticas. |
| Extracción | `请按下列JSON格式输出图中信息:` + schema JSON | Extracción de campos nativa. **Ver advertencia abajo.** |

Ejemplo Ollama oficial: `ollama run glm-ocr "Text Recognition:" ./image.png`

Medido: el trigger oficial `Text Recognition:` saca MÁS texto que un prompt en español
(2038 vs 1790 chars en una factura). En `Table Recognition:` el lenguaje natural además
provocaba que omitiera cabecera/emisor/CIF.

## Regla nº2: FRENO ANTI-BUCLE obligatorio

GLM-OCR (sobre todo en `Table Recognition:`) entra en **bucles de repetición** que lo cuelgan
>120s y agotan el contexto. NO es culpa del trigger. Hay que ponerle freno SIEMPRE:

```python
"options": {
    "temperature": 0,
    "num_ctx": 16384,
    "num_predict": 4096,     # límite duro: corta el bucle (3072 en tablas grandes)
    "repeat_penalty": 1.3,   # penaliza repetición → rompe el bucle
}
```

Sin esto, `table` se cuelga. Con esto: ~17-32s y HTML estructurado. Este fue el desbloqueo
que cambió el veredicto de "GLM es malo" a "GLM bien usado supera a producción".

## Regla nº3: la división correcta — GLM transcribe, Gemini razona

GLM 0.9B **no puede hacer la extracción de campos él solo**. Probado a fondo (con contexto de
cliente Y con few-shot):
- Confunde **emisor ↔ cliente** (pone al destinatario como emisor pese a instrucción explícita).
  Es un fallo de RAZONAMIENTO → no se arregla con prompt ni ejemplos en un 0.9B.
- JSON siempre **inválido**: decimales españoles (`1.942,39`), `€` dentro del valor, claves sin
  comillas, repeticiones. `json.loads` falla.
- El **few-shot empeora**: el modelo copia literalmente el ejemplo y lo mezcla con la factura real.

**Conclusión: NO uses Information Extraction nativo de GLM para sustituir a un LLM razonador.**
El patrón ganador es: **GLM transcribe (su fuerza) → un LLM grande (p. ej. Gemini) extrae/razona (la suya).**

## El patrón GANADOR: GLM-fusión (text+table) → Gemini

Para LÍNEAS de factura, lee la imagen en DOS modos y fusiónalos antes de pasar a Gemini:

```
texto  = glm("Text Recognition:",  imagen)   # transcripción corrida
tabla  = glm("Table Recognition:", imagen)   # tabla estructurada HTML
fusion = "=== TRANSCRIPCIÓN (Text Recognition) ===\n" + texto +
         "\n\n=== TABLA (Table Recognition) ===\n" + tabla
lineas = gemini(prompt_lineas, fusion)       # Gemini razona sobre la DOBLE vista
```

Resultado medido (28 facturas, 121 líneas): **recall 100% / precisión 93,8%**, SUPERA a
producción PaddleOCR v3+fitz+layout→Gemini (93,4% / 89,0%). Gana porque GLM **ve la imagen** y
recupera importes que el extractor de texto del PDF (fitz) deja vacíos (facturas Amazon).

Caveats honestos:
- GLM es **más lento**: 2 lecturas de visión (~20-40s) vs fitz (~1-8s). Trade-off velocidad↔precisión.
- Mismo coste Gemini (1 llamada). GLM es gratis pero consume GPU.
- Validado sobre un dataset de 28 (falta hold-out independiente antes de migrar producción).

## Parámetros y entorno de referencia

- Render PDF→imagen: PyMuPDF (`fitz`), DPI 200.
- Ollama: `OLLAMA_MAX_LOADED_MODELS=1` (GPU 12GB = 1 modelo grande a la vez), `NUM_PARALLEL=1`,
  `KEEP_ALIVE=24h`. Modelo `glm-ocr:latest` (~2.2GB).
- Conviene envolverlo en un microservicio sencillo (p. ej. Flask) con `POST /ocr` y `mode=text|table|extract`, aplicando
  siempre el freno anti-bucle de arriba.
- Qué medir en tu propio benchmark: texto transcrito (nº de caracteres), tiempo por página, y recall/precisión de las
  líneas de factura tras el LLM razonador.

## Gotchas

- Scripts Ollama en contenedor: pasar `-e OLLAMA_URL=http://<contenedor-ollama>:11434` o falla con
  connection refused (default localhost) y devuelve 0 bytes en silencio.
- `Table Recognition:` sin freno = cuelgue garantizado. El freno es innegociable.
- No esperes JSON limpio del extract nativo: si necesitas campos estructurados, manda el texto
  a un LLM razonador.
- El extract nativo confunde emisor/cliente: NO lo uses para identificar al proveedor.

## Auto-mejora

Al cerrar cada aplicación práctica de esta skill:
1. Registrar aprendizajes nuevos (triggers que funcionan mejor, valores de freno, casos donde
   GLM gana/pierde) en esta sección o en `aprendizajes/<caso>.md`.
2. Si el patrón es generalizable, actualizar el cuerpo de este SKILL.md.
3. Si se descubre un error recurrente, añadirlo a "Gotchas".

Sin esta fase, la skill se fosiliza y pierde valor con el tiempo.
