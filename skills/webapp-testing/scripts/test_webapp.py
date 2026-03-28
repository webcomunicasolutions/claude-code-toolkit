#!/usr/bin/env python3
"""
Test web applications using Playwright.
Supports screenshots, element checks, interactions, console/network logs.
Output: JSON structured results for automated parsing.

Usage:
    python test_webapp.py --url http://localhost:3000 --screenshot --check-status --json
    python test_webapp.py --url http://localhost:3000 --click "button" --wait-for ".result" --screenshot --json
"""

import argparse
import json
import sys
import time
import os
from datetime import datetime
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout


def parse_args():
    p = argparse.ArgumentParser(description="Web app testing with Playwright")
    p.add_argument("--url", required=True, help="URL to test")
    p.add_argument("--screenshot", action="store_true", help="Take a screenshot")
    p.add_argument("--screenshot-path", help="Custom screenshot path (default: /tmp/claude/screenshot_<timestamp>.png)")
    p.add_argument("--full-page", action="store_true", help="Full page screenshot")
    p.add_argument("--check-status", action="store_true", help="Check HTTP status is 200")
    p.add_argument("--check-text", action="append", default=[], help="Check text exists on page (repeatable)")
    p.add_argument("--check-selector", action="append", default=[], help="Check CSS selector exists (repeatable)")
    p.add_argument("--check-no-selector", action="append", default=[], help="Check CSS selector does NOT exist (repeatable)")
    p.add_argument("--click", action="append", default=[], help="Click element by selector (repeatable, executed in order)")
    p.add_argument("--fill", nargs=2, action="append", default=[], metavar=("SELECTOR", "VALUE"), help="Fill input (repeatable)")
    p.add_argument("--wait-for", action="append", default=[], help="Wait for selector to appear (repeatable)")
    p.add_argument("--console-logs", action="store_true", help="Capture console logs")
    p.add_argument("--network-log", action="store_true", help="Capture network requests")
    p.add_argument("--viewport", default="1280x720", help="Viewport size WxH (default: 1280x720)")
    p.add_argument("--timeout", type=int, default=30, help="Timeout in seconds (default: 30)")
    p.add_argument("--json", action="store_true", dest="json_output", help="Output as JSON")
    p.add_argument("--wait-after", type=float, default=0, help="Wait N seconds after page load before actions")
    p.add_argument("--headless", action="store_true", default=True, help="Run headless (default)")
    return p.parse_args()


def main():
    args = parse_args()
    w, h = map(int, args.viewport.split("x"))
    timeout_ms = args.timeout * 1000

    result = {
        "url": args.url,
        "timestamp": datetime.now().isoformat(),
        "success": True,
        "checks": [],
        "actions": [],
        "errors": [],
        "screenshots": [],
        "console_logs": [],
        "network_requests": [],
    }

    console_logs = []
    network_requests = []

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(viewport={"width": w, "height": h})
            page = context.new_page()
            page.set_default_timeout(timeout_ms)

            # Set up console log capture
            if args.console_logs:
                page.on("console", lambda msg: console_logs.append({
                    "type": msg.type,
                    "text": msg.text,
                }))

            # Set up network capture
            if args.network_log:
                def on_response(response):
                    network_requests.append({
                        "url": response.url,
                        "status": response.status,
                        "method": response.request.method,
                    })
                page.on("response", on_response)

            # Navigate
            try:
                response = page.goto(args.url, wait_until="networkidle", timeout=timeout_ms)
                status_code = response.status if response else None
                result["status_code"] = status_code
            except PlaywrightTimeout:
                result["errors"].append(f"Timeout navigating to {args.url}")
                result["success"] = False
                status_code = None
            except Exception as e:
                result["errors"].append(f"Navigation error: {str(e)}")
                result["success"] = False
                status_code = None

            # Wait after load
            if args.wait_after > 0:
                page.wait_for_timeout(int(args.wait_after * 1000))

            # Check status
            if args.check_status:
                ok = status_code == 200
                result["checks"].append({
                    "type": "status",
                    "expected": 200,
                    "actual": status_code,
                    "passed": ok,
                })
                if not ok:
                    result["success"] = False

            # Check text
            for text in args.check_text:
                content = page.content()
                found = text in content or text in page.inner_text("body")
                result["checks"].append({
                    "type": "text",
                    "value": text,
                    "passed": found,
                })
                if not found:
                    result["success"] = False

            # Check selectors exist
            for sel in args.check_selector:
                try:
                    count = page.locator(sel).count()
                    found = count > 0
                except Exception:
                    found = False
                    count = 0
                result["checks"].append({
                    "type": "selector_exists",
                    "selector": sel,
                    "passed": found,
                    "count": count,
                })
                if not found:
                    result["success"] = False

            # Check selectors don't exist
            for sel in args.check_no_selector:
                try:
                    count = page.locator(sel).count()
                    absent = count == 0
                except Exception:
                    absent = True
                result["checks"].append({
                    "type": "selector_absent",
                    "selector": sel,
                    "passed": absent,
                })
                if not absent:
                    result["success"] = False

            # Wait for selectors
            for sel in args.wait_for:
                try:
                    page.wait_for_selector(sel, timeout=timeout_ms)
                    result["actions"].append({"type": "wait_for", "selector": sel, "success": True})
                except PlaywrightTimeout:
                    result["actions"].append({"type": "wait_for", "selector": sel, "success": False})
                    result["errors"].append(f"Timeout waiting for: {sel}")
                    result["success"] = False

            # Click actions
            for sel in args.click:
                try:
                    page.locator(sel).first.click(timeout=timeout_ms)
                    page.wait_for_load_state("networkidle")
                    result["actions"].append({"type": "click", "selector": sel, "success": True})
                except Exception as e:
                    result["actions"].append({"type": "click", "selector": sel, "success": False, "error": str(e)})
                    result["errors"].append(f"Click failed on '{sel}': {str(e)}")
                    result["success"] = False

            # Fill actions
            for sel, val in args.fill:
                try:
                    page.locator(sel).first.fill(val, timeout=timeout_ms)
                    result["actions"].append({"type": "fill", "selector": sel, "value": val, "success": True})
                except Exception as e:
                    result["actions"].append({"type": "fill", "selector": sel, "value": val, "success": False, "error": str(e)})
                    result["errors"].append(f"Fill failed on '{sel}': {str(e)}")
                    result["success"] = False

            # Screenshot
            if args.screenshot:
                ts = datetime.now().strftime("%Y%m%d_%H%M%S")
                path = args.screenshot_path or f"/tmp/claude-1000/screenshot_{ts}.png"
                os.makedirs(os.path.dirname(path), exist_ok=True)
                page.screenshot(path=path, full_page=args.full_page)
                result["screenshots"].append(path)

            # Collect logs
            if args.console_logs:
                result["console_logs"] = console_logs
            if args.network_log:
                result["network_requests"] = network_requests

            browser.close()

    except Exception as e:
        result["errors"].append(f"Fatal error: {str(e)}")
        result["success"] = False

    # Output
    if args.json_output:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"URL: {result['url']}")
        print(f"Status: {'PASS' if result['success'] else 'FAIL'}")
        if result.get("status_code"):
            print(f"HTTP Status: {result['status_code']}")
        for check in result["checks"]:
            icon = "✓" if check["passed"] else "✗"
            print(f"  {icon} {check['type']}: {check.get('value') or check.get('selector') or check.get('expected')}")
        for action in result["actions"]:
            icon = "✓" if action["success"] else "✗"
            print(f"  {icon} {action['type']}: {action.get('selector', '')}")
        for err in result["errors"]:
            print(f"  ERROR: {err}")
        for ss in result["screenshots"]:
            print(f"  Screenshot: {ss}")
        if console_logs:
            print(f"  Console logs: {len(console_logs)} entries")
        if network_requests:
            print(f"  Network requests: {len(network_requests)} captured")

    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
