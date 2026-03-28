#!/usr/bin/env python3
"""
Test REST APIs without a browser.
Validates status codes, response body, headers, and JSON paths.

Usage:
    python api_test.py --url http://localhost:3000/api/pedidos --method GET --expect-status 200 --json
    python api_test.py --url http://localhost:3000/api/pedidos --method POST --body '{"name":"test"}' --expect-status 201 --json
"""

import argparse
import json
import sys
import time
from datetime import datetime
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


def parse_args():
    p = argparse.ArgumentParser(description="REST API testing")
    p.add_argument("--url", required=True, help="API endpoint URL")
    p.add_argument("--method", default="GET", choices=["GET", "POST", "PUT", "DELETE", "PATCH"], help="HTTP method")
    p.add_argument("--body", help="Request body (JSON string)")
    p.add_argument("--header", action="append", default=[], help="Header 'Key: Value' (repeatable)")
    p.add_argument("--expect-status", type=int, help="Expected HTTP status code")
    p.add_argument("--expect-json", nargs=2, action="append", default=[], metavar=("PATH", "VALUE"),
                    help="Validate JSON field: 'path.to.key' 'expected_value' (repeatable)")
    p.add_argument("--expect-contains", help="Check response body contains this string")
    p.add_argument("--timeout", type=int, default=30, help="Timeout in seconds")
    p.add_argument("--json", action="store_true", dest="json_output", help="Output as JSON")
    return p.parse_args()


def resolve_json_path(data, path):
    """Resolve a dot-notation path in a JSON object. Supports array indices like 'items.0.name'."""
    keys = path.split(".")
    current = data
    for key in keys:
        if isinstance(current, list):
            try:
                current = current[int(key)]
            except (ValueError, IndexError):
                return None, False
        elif isinstance(current, dict):
            if key in current:
                current = current[key]
            else:
                return None, False
        else:
            return None, False
    return current, True


def main():
    args = parse_args()

    result = {
        "url": args.url,
        "method": args.method,
        "timestamp": datetime.now().isoformat(),
        "success": True,
        "checks": [],
        "errors": [],
        "response": {},
    }

    # Build request
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    for h in args.header:
        key, _, val = h.partition(":")
        headers[key.strip()] = val.strip()

    body_bytes = None
    if args.body:
        body_bytes = args.body.encode("utf-8")

    start_time = time.time()
    status_code = None
    response_body = None
    response_headers = {}

    try:
        req = Request(args.url, data=body_bytes, headers=headers, method=args.method)
        resp = urlopen(req, timeout=args.timeout)
        status_code = resp.status
        response_body = resp.read().decode("utf-8")
        response_headers = dict(resp.headers)
    except HTTPError as e:
        status_code = e.code
        try:
            response_body = e.read().decode("utf-8")
        except Exception:
            response_body = ""
        response_headers = dict(e.headers) if e.headers else {}
    except URLError as e:
        result["errors"].append(f"Connection error: {str(e)}")
        result["success"] = False
    except Exception as e:
        result["errors"].append(f"Request error: {str(e)}")
        result["success"] = False

    elapsed = round(time.time() - start_time, 3)
    result["response"]["status_code"] = status_code
    result["response"]["elapsed_seconds"] = elapsed
    result["response"]["headers"] = response_headers

    # Try to parse JSON body
    response_json = None
    if response_body:
        try:
            response_json = json.loads(response_body)
            result["response"]["body"] = response_json
        except json.JSONDecodeError:
            result["response"]["body_text"] = response_body[:2000]

    # Check status
    if args.expect_status is not None:
        ok = status_code == args.expect_status
        result["checks"].append({
            "type": "status_code",
            "expected": args.expect_status,
            "actual": status_code,
            "passed": ok,
        })
        if not ok:
            result["success"] = False

    # Check body contains
    if args.expect_contains and response_body:
        found = args.expect_contains in response_body
        result["checks"].append({
            "type": "body_contains",
            "value": args.expect_contains,
            "passed": found,
        })
        if not found:
            result["success"] = False

    # Check JSON paths
    if response_json is not None:
        for path, expected in args.expect_json:
            actual, found = resolve_json_path(response_json, path)
            if not found:
                result["checks"].append({
                    "type": "json_path",
                    "path": path,
                    "expected": expected,
                    "actual": None,
                    "passed": False,
                    "error": "Path not found",
                })
                result["success"] = False
            else:
                passed = str(actual) == expected
                result["checks"].append({
                    "type": "json_path",
                    "path": path,
                    "expected": expected,
                    "actual": actual,
                    "passed": passed,
                })
                if not passed:
                    result["success"] = False

    # Output
    if args.json_output:
        print(json.dumps(result, indent=2, ensure_ascii=False, default=str))
    else:
        print(f"{args.method} {args.url}")
        print(f"Status: {status_code} ({elapsed}s)")
        print(f"Result: {'PASS' if result['success'] else 'FAIL'}")
        for check in result["checks"]:
            icon = "✓" if check["passed"] else "✗"
            if check["type"] == "status_code":
                print(f"  {icon} Status: expected {check['expected']}, got {check['actual']}")
            elif check["type"] == "json_path":
                print(f"  {icon} {check['path']}: expected '{check['expected']}', got '{check['actual']}'")
            elif check["type"] == "body_contains":
                print(f"  {icon} Body contains '{check['value']}'")
        for err in result["errors"]:
            print(f"  ERROR: {err}")
        if response_json and not args.json_output:
            preview = json.dumps(response_json, ensure_ascii=False, default=str)
            if len(preview) > 500:
                preview = preview[:500] + "..."
            print(f"  Body: {preview}")

    sys.exit(0 if result["success"] else 1)


if __name__ == "__main__":
    main()
