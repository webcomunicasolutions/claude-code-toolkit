# LLMWhisperer Clients & Integrations

## Table of Contents
- [Python Client](#python-client)
- [JavaScript Client](#javascript-client)
- [n8n Custom Node](#n8n-custom-node)
- [MCP Server](#mcp-server)

---

## Python Client

`pip install llmwhisperer-client` (version 2.x.y for API v2)

### Import & Init

```python
from unstract.llmwhisperer import LLMWhispererClientV2
from unstract.llmwhisperer.client_v2 import LLMWhispererClientException

# Uses env vars LLMWHISPERER_API_KEY, LLMWHISPERER_BASE_URL_V2
client = LLMWhispererClientV2()

# Or explicit
client = LLMWhispererClientV2(
    base_url="https://llmwhisperer-api.us-central.unstract.com/api/v2",
    api_key="your_key",
    logging_level="INFO"  # DEBUG, INFO, WARNING, ERROR
)
```

### Methods

**`whisper()`** - Process document

```python
result = client.whisper(
    file_path="doc.pdf",       # or stream=file_obj, or url="https://..."
    mode="high_quality",       # native_text, low_cost, high_quality, form, table
    output_mode="layout_preserving",  # or "text"
    page_seperator="<<<",
    pages_to_extract="1-5,7",
    median_filter_size=0,      # low_cost mode only
    gaussian_blur_radius=0,    # low_cost mode only
    line_splitter_tolerance=0.75,
    horizontal_stretch_factor=1.0,
    mark_vertical_lines=False,
    mark_horizontal_lines=False,
    line_spitter_strategy="left-priority",
    lang="eng",
    tag="default",
    filename="",
    use_webhook="",
    webhook_metadata="",
    wait_for_completion=False,  # True = sync mode (blocking)
    wait_timeout=180,          # seconds (for sync mode)
    encoding="utf-8",
    add_line_nos=False,
)
```

**`whisper_status(whisper_hash)`** - Check status
```python
status = client.whisper_status(whisper_hash=result["whisper_hash"])
# status["status"]: "processing", "processed", "delivered", "unknown"
```

**`whisper_retrieve(whisper_hash)`** - Get result (ONE TIME ONLY)
```python
result = client.whisper_retrieve(whisper_hash="...")
# result["result_text"], result["confidence_metadata"]
```

**`get_usage_info()`** - Account usage
```python
usage = client.get_usage_info()
```

**`get_highlight_rect()`** - Bounding box for UI highlighting
```python
page, x1, y1, x2, y2 = client.get_highlight_rect(
    line_metadata=whisper["extraction"]["line_metadata"][line_no],
    line_no=line_no,
    target_width=2480,
    target_height=3508
)
```

### Async Polling Example

```python
import time
client = LLMWhispererClientV2()

result = client.whisper(file_path="document.pdf", mode="form")
if result["status_code"] == 202:
    while True:
        status = client.whisper_status(whisper_hash=result["whisper_hash"])
        if status["status"] == "processed":
            data = client.whisper_retrieve(whisper_hash=result["whisper_hash"])
            print(data["result_text"])
            break
        elif status["status"] in ("delivered", "unknown", "error"):
            break
        time.sleep(5)
```

### Sync Example

```python
result = client.whisper(
    file_path="document.pdf",
    mode="form",
    wait_for_completion=True,
    wait_timeout=200
)
print(result["extraction"]["result_text"])
```

### Error Handling

```python
try:
    result = client.whisper_retrieve("invalid_hash")
except LLMWhispererClientException as e:
    print(f"Error: {e.message}, Status: {e.status_code}")
```

### Result Format

Async (202):
```json
{"message": "Whisper Job Accepted", "status": "processing", "whisper_hash": "...", "status_code": 202, "extraction": {}}
```

Sync (200):
```json
{"message": "Whisper Job Accepted", "status": "processed", "whisper_hash": "...", "status_code": 200,
 "extraction": {"result_text": "...", "confidence_metadata": [], "line_metadata": [], "metadata": {}}}
```

---

## JavaScript Client

`npm install llmwhisperer-client` (version 2.x.y for API v2)

### Init

```javascript
const { LLMWhispererClientV2 } = require("llmwhisperer-client");

const client = new LLMWhispererClientV2({
    baseUrl: "https://llmwhisperer-api.us-central.unstract.com/api/v2",
    apiKey: "your_key",
    loggingLevel: "info"  // error, warn, info, debug
});
// Or use env vars: LLMWHISPERER_API_KEY, LLMWHISPERER_BASE_URL_V2
```

### Methods

```javascript
// Process document
const whisper = await client.whisper({
    filePath: "document.pdf",
    mode: "high_quality",
    pagesToExtract: "1-2",
    waitForCompletion: true,  // sync mode
    waitTimeout: 120
});

// Async polling
const result = await client.whisper({ filePath: "doc.pdf" });
const status = await client.whisperStatus(result.whisper_hash);
const data = await client.whisperRetrieve(result.whisper_hash);

// Usage info
const usage = await client.getUsageInfo();

// Webhooks
await client.registerWebhook(webhookUrl, authToken, webhookName);
const details = await client.getWebhookDetails(webhookName);

// Highlighting
const rect = client.getHighlightRect(lineMetadata, lineNo, targetWidth, targetHeight);
```

Dependencies: axios, winston.

---

## n8n Custom Node

NPM package: `n8n-nodes-unstract`

### Installation
Install via n8n Community Nodes GUI installation.

### Credentials
Create LLMWhisperer credentials in n8n: enter "LLMWhisperer" when asked for app/service, provide API key.

### Input
- **File Contents**: Binary file from previous node
- All `/whisper` API parameters available as node fields

### Typical Workflow
1. Read Binary File node (or HTTP Request to download)
2. LLMWhisperer node (extracts text)
3. Process extracted text downstream

---

## MCP Server

Docker image: `unstract/mcp-server`

### Claude Desktop Configuration

```json
{
  "mcpServers": {
    "extract_text": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "/tmp:/tmp",
        "-e", "LLMWHISPERER_API_KEY",
        "unstract/mcp-server", "llm_whisperer"
      ],
      "env": {
        "LLMWHISPERER_API_KEY": "<your-key>"
      }
    }
  }
}
```

### Tool
`extract_text` - Submits file to LLMWhisperer API, polls for processing, retrieves extracted text. Supports all processing modes and output formats.

### Sample Prompt
"Extract text from the document /tmp/sample-bank_statement.pdf"
