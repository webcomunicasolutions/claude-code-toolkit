---
name: llmwhisperer
description: "LLMWhisperer v2 OCR API by Unstract - extract text from PDFs, images, scanned documents, Office files for LLM consumption. Use when: (1) user mentions LLMWhisperer, Unstract, or whisper API, (2) needs OCR/text extraction from documents for LLMs, (3) works with LLMWhisperer Python/JS client, (4) configures LLMWhisperer in n8n workflows, (5) asks about document processing modes (native_text, low_cost, high_quality, form, table), (6) needs to integrate document extraction API into applications."
---

# LLMWhisperer v2 API

LLMWhisperer extracts text from complex documents (PDFs, images, Office files) in a layout-preserving format optimized for LLM consumption. All requests are async.

## Quick Reference

| Item | Value |
|------|-------|
| Base URL US | `https://llmwhisperer-api.us-central.unstract.com/api/v2` |
| Base URL EU | `https://llmwhisperer-api.eu-west.unstract.com/api/v2` |
| Auth Header | `unstract-key: <API_KEY>` |
| Python pkg | `pip install llmwhisperer-client` |
| JS pkg | `npm install llmwhisperer-client` |
| n8n node | `n8n-nodes-unstract` |

## Processing Modes

| Mode | Use For | Scanned | Handwriting | Forms | Tables |
|------|---------|---------|-------------|-------|--------|
| `native_text` | Digital PDFs, very fast | No | No | No | No |
| `low_cost` | Clean scanned docs | Yes | Basic | No | No |
| `high_quality` | Low-quality scans, handwriting | Yes | Yes | No | No |
| `form` | Checkboxes, radio buttons, forms | Yes | Yes | Yes | No |
| `table` | Financial reports, spreadsheets | Yes | Yes | No | Yes |

## API Workflow (Polling)

```
1. POST /whisper (file binary) → 202 { whisper_hash }
2. GET  /whisper-status?whisper_hash=X → { status: "processing"|"processed" }
3. GET  /whisper-retrieve?whisper_hash=X → { result_text, confidence_metadata }
```

Alternative: register webhook via `/whisper-manage-callback`, pass `use_webhook=name` in `/whisper`.

## Curl Example

```bash
# Extract text from PDF
curl -X POST 'https://llmwhisperer-api.us-central.unstract.com/api/v2/whisper?mode=form&output_mode=layout_preserving' \
  -H 'unstract-key: <KEY>' \
  --data-binary '@document.pdf'

# Check status
curl 'https://llmwhisperer-api.us-central.unstract.com/api/v2/whisper-status?whisper_hash=HASH' \
  -H 'unstract-key: <KEY>'

# Retrieve result
curl 'https://llmwhisperer-api.us-central.unstract.com/api/v2/whisper-retrieve?whisper_hash=HASH' \
  -H 'unstract-key: <KEY>'
```

## Python Client Quick Start

```python
from unstract.llmwhisperer import LLMWhispererClientV2

client = LLMWhispererClientV2(
    base_url="https://llmwhisperer-api.us-central.unstract.com/api/v2",
    api_key="YOUR_KEY"
)

# Sync mode (waits for completion)
result = client.whisper(
    file_path="document.pdf",
    mode="form",
    wait_for_completion=True,
    wait_timeout=200
)
print(result["extraction"]["result_text"])

# Async mode
result = client.whisper(file_path="document.pdf", mode="high_quality")
# Poll with client.whisper_status(result["whisper_hash"])
# Retrieve with client.whisper_retrieve(result["whisper_hash"])
```

Env vars: `LLMWHISPERER_API_KEY`, `LLMWHISPERER_BASE_URL_V2`, `LLMWHISPERER_LOGGING_LEVEL`

## Reference Files

For detailed information, read these files as needed:

- **[API Reference](references/api_reference.md)** - All endpoints, parameters, request/response formats, error codes
- **[Clients & Integrations](references/clients.md)** - Python client API, JS client API, n8n node setup, MCP server
- **[Modes & Features](references/modes_features.md)** - Detailed mode comparison, file formats, languages, webhooks, highlighting
- **[Editions & Deployment](references/editions.md)** - Cloud vs On-Prem, pricing, deployment guide

Source docs: https://docs.unstract.com/llmwhisperer/
