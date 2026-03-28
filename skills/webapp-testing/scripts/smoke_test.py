#!/usr/bin/env python3
"""
Smoke test: quick health check for a web application.
Visits the base URL, discovers navigation links, visits each page,
captures screenshots and console errors.

Usage:
    python smoke_test.py --url http://localhost:3000 --json
    python smoke_test.py --url http://localhost:3000 --max-pages 10 --screenshots --json
"""

import argparse
import json
import os
import sys
import re
from datetime import datetime
from urllib.parse import urljoin, urlparse
from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout


def parse_args():
    p = argparse.ArgumentParser(description="Smoke test for web apps")
    p.add_argument("--url", required=True, help="Base URL to test")
    p.add_argument("--max-pages", type=int, default=10, help="Max pages to visit (default: 10)")
    p.add_argument("--screenshots", action="store_true", help="Take screenshot of each page")
    p.add_argument("--screenshot-dir", default="/tmp/claude-1000/smoke", help="Directory for screenshots")
    p.add_argument("--timeout", type=int, default=15, help="Timeout per page in seconds")
    p.add_argument("--viewport", default="1280x720", help="Viewport WxH")
    p.add_argument("--json", action="store_true", dest="json_output", help="Output as JSON")
    p.add_argument("--follow-links", action="store_true", default=True, help="Follow internal links (default: true)")
    p.add_argument("--no-follow-links", action="store_true", help="Only test the base URL")
    return p.parse_args()


def is_internal(base_url, href):
    """Check if a URL is internal to the base domain."""
    if not href or href.startswith("#") or href.startswith("javascript:") or href.startswith("mailto:"):
        return False
    parsed_base = urlparse(base_url)
    full = urljoin(base_url, href)
    parsed = urlparse(full)
    return parsed.netloc == parsed_base.netloc


def sanitize_filename(url):
    """Create a safe filename from a URL path."""
    path = urlparse(url).path.strip("/") or "index"
    return re.sub(r'[^a-zA-Z0-9_-]', '_', path)[:80]


def test_page(page, url, timeout_ms, take_screenshot, screenshot_dir):
    """Test a single page and return results."""
    console_errors = []
    console_warnings = []

    def on_console(msg):
        if msg.type == "error":
            console_errors.append(msg.text)
        elif msg.type == "warning":
            console_warnings.append(msg.text)

    page.on("console", on_console)

    page_result = {
        "url": url,
        "status": None,
        "load_time_ms": None,
        "title": None,
        "console_errors": [],
        "console_warnings": [],
        "screenshot": None,
        "links_found": 0,
        "internal_links": [],
        "passed": False,
        "error": None,
    }

    try:
        start = page.evaluate("Date.now()")
        response = page.goto(url, wait_until="networkidle", timeout=timeout_ms)
        end = page.evaluate("Date.now()")

        page_result["status"] = response.status if response else None
        page_result["load_time_ms"] = end - start
        page_result["title"] = page.title()
        page_result["console_errors"] = console_errors
        page_result["console_warnings"] = console_warnings

        # Discover internal links
        links = page.evaluate("""() => {
            return Array.from(document.querySelectorAll('a[href]'))
                .map(a => a.getAttribute('href'))
                .filter(h => h && !h.startsWith('#') && !h.startsWith('javascript:') && !h.startsWith('mailto:'));
        }""")
        internal = [urljoin(url, l) for l in links if is_internal(url, l)]
        # Deduplicate
        internal = list(dict.fromkeys(internal))
        page_result["links_found"] = len(links)
        page_result["internal_links"] = internal

        # Screenshot
        if take_screenshot:
            os.makedirs(screenshot_dir, exist_ok=True)
            fname = f"{sanitize_filename(url)}.png"
            path = os.path.join(screenshot_dir, fname)
            page.screenshot(path=path, full_page=True)
            page_result["screenshot"] = path

        page_result["passed"] = (page_result["status"] or 0) < 400 and len(console_errors) == 0

    except PlaywrightTimeout:
        page_result["error"] = "Timeout"
        page_result["passed"] = False
    except Exception as e:
        page_result["error"] = str(e)
        page_result["passed"] = False

    # Remove listener to avoid duplicates
    page.remove_listener("console", on_console)
    return page_result


def main():
    args = parse_args()
    w, h = map(int, args.viewport.split("x"))
    timeout_ms = args.timeout * 1000
    follow_links = not args.no_follow_links

    result = {
        "base_url": args.url,
        "timestamp": datetime.now().isoformat(),
        "pages_tested": 0,
        "pages_passed": 0,
        "pages_failed": 0,
        "total_console_errors": 0,
        "pages": [],
        "summary": "",
    }

    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            context = browser.new_context(viewport={"width": w, "height": h})
            page = context.new_page()
            page.set_default_timeout(timeout_ms)

            # BFS through pages
            visited = set()
            to_visit = [args.url]

            while to_visit and len(visited) < args.max_pages:
                current_url = to_visit.pop(0)
                # Normalize URL for dedup
                normalized = current_url.rstrip("/")
                if normalized in visited:
                    continue
                visited.add(normalized)

                page_result = test_page(page, current_url, timeout_ms, args.screenshots, args.screenshot_dir)
                result["pages"].append(page_result)
                result["pages_tested"] += 1

                if page_result["passed"]:
                    result["pages_passed"] += 1
                else:
                    result["pages_failed"] += 1

                result["total_console_errors"] += len(page_result.get("console_errors", []))

                # Add discovered links to visit queue
                if follow_links:
                    for link in page_result.get("internal_links", []):
                        norm_link = link.rstrip("/")
                        if norm_link not in visited:
                            to_visit.append(link)

            browser.close()

    except Exception as e:
        result["summary"] = f"Fatal error: {str(e)}"
        if args.json_output:
            print(json.dumps(result, indent=2, ensure_ascii=False))
        else:
            print(f"FATAL: {str(e)}")
        sys.exit(1)

    # Summary
    all_passed = result["pages_failed"] == 0
    result["summary"] = f"{'PASS' if all_passed else 'FAIL'}: {result['pages_passed']}/{result['pages_tested']} pages OK, {result['total_console_errors']} console errors"

    if args.json_output:
        print(json.dumps(result, indent=2, ensure_ascii=False))
    else:
        print(f"\nSmoke Test: {args.url}")
        print(f"{'=' * 50}")
        for pr in result["pages"]:
            icon = "✓" if pr["passed"] else "✗"
            status = pr.get("status", "???")
            load = pr.get("load_time_ms", "?")
            errors = len(pr.get("console_errors", []))
            title = pr.get("title", "")[:40]
            print(f"  {icon} [{status}] {pr['url']}")
            if title:
                print(f"        Title: {title}")
            print(f"        Load: {load}ms | Console errors: {errors}")
            if pr.get("screenshot"):
                print(f"        Screenshot: {pr['screenshot']}")
            if pr.get("error"):
                print(f"        Error: {pr['error']}")
            for ce in pr.get("console_errors", [])[:3]:
                print(f"        Console: {ce[:100]}")
        print(f"{'=' * 50}")
        print(f"Result: {result['summary']}")

    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
