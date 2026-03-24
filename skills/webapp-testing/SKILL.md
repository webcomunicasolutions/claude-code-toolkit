---
name: webapp-testing
description: Toolkit for interacting with and testing local web applications using Playwright. Supports verifying frontend functionality, debugging UI behavior, capturing browser screenshots, and viewing browser logs.
license: Complete terms in LICENSE.txt
---

# Web Application Testing

To test local web applications, write native Python Playwright scripts or use the built-in helper scripts.

**Helper Scripts Available**:
- `scripts/with_server.py` - Manages server lifecycle (supports multiple servers)
- `scripts/test_webapp.py` - All-in-one web testing: screenshots, checks, interactions, logs
- `scripts/api_test.py` - REST API testing without a browser
- `scripts/smoke_test.py` - Automatic smoke test: visits pages, captures errors, screenshots

**Always run scripts with `--help` first** to see usage. DO NOT read the source until you try running the script first and find that a customized solution is absolutely necessary.

## Quick Reference

### Test a page (screenshot + checks)
```bash
python scripts/test_webapp.py --url http://localhost:3000 \
  --screenshot --check-status --check-selector "table" --console-logs --json
```

### Test an API endpoint
```bash
python scripts/api_test.py --url http://localhost:3000/api/items \
  --method GET --expect-status 200 --json
```

### Smoke test entire app
```bash
python scripts/smoke_test.py --url http://localhost:3000 --screenshots --json
```

### With server lifecycle
```bash
python scripts/with_server.py --server "cd app && npm run dev" --port 3000 \
  -- python scripts/smoke_test.py --url http://localhost:3000 --json
```

### Interactive test (click, fill, verify)
```bash
python scripts/test_webapp.py --url http://localhost:3000 \
  --click "button:text('New')" --wait-for "form" \
  --fill "input[name=name]" "Test Value" --screenshot --json
```

## Decision Tree: Choosing Your Approach

```
Task → What do you need to test?
  ├─ API endpoint (no UI) → Use api_test.py
  │     --method, --body, --expect-status, --expect-json
  │
  ├─ Quick health check → Use smoke_test.py
  │     Visits pages, finds links, captures errors
  │
  ├─ Specific page/interaction → Use test_webapp.py
  │     --screenshot, --click, --fill, --check-selector
  │
  └─ Custom/complex scenario → Write Playwright script
        Use with_server.py for server management
```

## Script Details

### test_webapp.py
Full web page testing with Playwright. Key flags:
- `--url URL` - Page to test (required)
- `--screenshot` / `--full-page` - Capture screenshot
- `--screenshot-path PATH` - Custom path (default: /tmp/claude-1000/)
- `--check-status` - Verify HTTP 200
- `--check-text "text"` - Verify text on page (repeatable)
- `--check-selector "sel"` - Verify element exists (repeatable)
- `--check-no-selector "sel"` - Verify element absent (repeatable)
- `--click "sel"` - Click element (repeatable, sequential)
- `--fill "sel" "val"` - Fill input (repeatable)
- `--wait-for "sel"` - Wait for element to appear
- `--console-logs` - Capture browser console
- `--network-log` - Capture network requests
- `--viewport WxH` - Viewport size (default: 1280x720)
- `--timeout N` - Seconds (default: 30)
- `--wait-after N` - Wait N seconds after page load
- `--json` - JSON output

### api_test.py
REST API testing (no browser needed). Key flags:
- `--url URL` - Endpoint (required)
- `--method GET/POST/PUT/DELETE/PATCH`
- `--body '{"json":"data"}'` - Request body
- `--header "Key: Value"` - Custom header (repeatable)
- `--expect-status 200` - Expected status code
- `--expect-json "path.to.key" "value"` - Validate JSON field (repeatable)
- `--expect-contains "text"` - Body contains string
- `--timeout N` - Seconds (default: 30)
- `--json` - JSON output

### smoke_test.py
Automatic smoke test with link crawling. Key flags:
- `--url URL` - Base URL (required)
- `--max-pages N` - Max pages to visit (default: 10)
- `--screenshots` - Screenshot every page
- `--screenshot-dir PATH` - Directory for screenshots
- `--no-follow-links` - Only test the base URL
- `--timeout N` - Per-page timeout (default: 15)
- `--json` - JSON output

## Using with_server.py

**Single server:**
```bash
python scripts/with_server.py --server "npm run dev" --port 5173 -- python your_script.py
```

**Multiple servers (backend + frontend):**
```bash
python scripts/with_server.py \
  --server "cd backend && python server.py" --port 3000 \
  --server "cd frontend && npm run dev" --port 5173 \
  -- python your_script.py
```

## Writing Custom Playwright Scripts

For scenarios not covered by the helper scripts:
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto('http://localhost:5173')
    page.wait_for_load_state('networkidle')  # CRITICAL: Wait for JS
    # ... your logic
    browser.close()
```

## Common Pitfall

- **Don't** inspect DOM before `networkidle` on dynamic apps
- **Do** use `--json` flag for automated parsing of results
- **Do** use `--wait-after` if the page has delayed JS rendering

## Reference Files

- **examples/** - Examples showing common patterns:
  - `element_discovery.py` - Discovering buttons, links, and inputs
  - `static_html_automation.py` - Using file:// URLs for local HTML
  - `console_logging.py` - Capturing console logs
