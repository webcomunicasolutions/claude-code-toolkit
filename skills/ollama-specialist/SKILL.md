---
name: ollama-specialist
description: "Especialista en Ollama para gestión de modelos LLM locales con GPU. Usar cuando se trabaje con: (1) Configuración de Ollama y variables de entorno, (2) Modelos de visión como DeepSeek-OCR, LLaVA o Qwen-VL, (3) GPU passthrough y optimización VRAM, (4) Troubleshooting de bloqueos, timeouts o errores OOM, (5) Integración con n8n u otras APIs, (6) Gestión de contexto (num_ctx) y parámetros de modelo, (7) Cuantización y selección de modelos según hardware."
---

# Ollama Specialist

## Hardware del Usuario

**GPU: RTX 4070 (12GB VRAM)**

Variables de entorno calibradas:
```bash
OLLAMA_NUM_PARALLEL=1        # OBLIGATORIO para vision
OLLAMA_FLASH_ATTENTION=1
OLLAMA_NUM_GPU=999
OLLAMA_CONTEXT_LENGTH=8192
OLLAMA_KV_CACHE_TYPE=q8_0
OLLAMA_KEEP_ALIVE=24h
```

Modelos probados: ministral:8b, llama3.2:8b, deepseek-ocr, llava:7b, qwen2-vl:7b

## Consumo VRAM Medido (Q4_K_M)

| Parametros | VRAM Base | + 4K ctx | + 8K ctx |
|------------|-----------|----------|----------|
| 7B | ~4.5 GB | ~5.5 GB | ~7 GB |
| 8B | ~5 GB | ~6 GB | ~8 GB |
| 13B | ~8 GB | ~9.5 GB | ~12 GB |

| Modelo Vision | VRAM |
|---------------|------|
| moondream | ~3 GB |
| llava:7b | ~6 GB |
| deepseek-ocr | ~9 GB |
| qwen2-vl:7b | ~7 GB |

## DeepSeek-OCR (Prompts con tiempos medidos)

```bash
ollama run deepseek-ocr "/ruta/imagen.jpg
PROMPT_AQUI"
```
**El salto de linea entre ruta y prompt es OBLIGATORIO.**

| Prompt | Uso | Velocidad |
|--------|-----|-----------|
| `Free OCR.` | Texto plano rapido | ~5s |
| `Extract the text in the image.` | **Recomendado facturas** | ~7s |
| `<\|grounding\|>Convert the document to markdown.` | Tablas + coordenadas | ~20s |

## Integracion n8n

Nodo HTTP Request:
```json
{
  "method": "POST",
  "url": "http://ollama:11434/api/generate",
  "body": {
    "model": "deepseek-ocr",
    "prompt": "Extract the text in the image.",
    "images": ["={{ $binary.imagen.data }}"],
    "stream": false
  }
}
```

## Datos Criticos

- `OLLAMA_NUM_PARALLEL=1` es **obligatorio** para modelos de vision. Con >1 el Vision Encoder se satura y bloquea.
- `NUM_PARALLEL` multiplica el contexto: 2K ctx x 4 paralelas = 8K total VRAM.
- PDF no se acepta directamente: convertir con `pdftoppm -jpeg -r 300 doc.pdf salida`.
- Exit code 137 = OOM. Activar Flash Attention o reducir modelo.
- Cuantizacion recomendada: Q4_K_M (mejor balance calidad/VRAM).
- Configurar en systemd: `sudo systemctl edit ollama.service` -> `Environment="VAR=valor"`.
- En Docker/EasyPanel: anadir en variables de entorno del servicio.
