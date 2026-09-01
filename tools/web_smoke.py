#!/usr/bin/env python3
"""Exercise a locally served Godot web export across launch resolutions."""

import argparse
import json
import sys
from pathlib import Path

from playwright.sync_api import sync_playwright


SIZES = [(320, 568), (390, 664), (480, 854), (1280, 720), (1920, 1080), (2560, 1080)]


def saved_progress(page):
    raw = page.evaluate("localStorage.getItem('lobster_clicker_save')")
    return json.loads(raw) if raw else {}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("url", nargs="?", default="http://127.0.0.1:8765/")
    parser.add_argument("--screenshots", default="/tmp/lobster-web-smoke")
    args = parser.parse_args()
    screenshot_dir = Path(args.screenshots)
    screenshot_dir.mkdir(parents=True, exist_ok=True)
    results = []
    failed = False

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        for width, height in SIZES:
            context = browser.new_context(viewport={"width": width, "height": height})
            page = context.new_page()
            console_errors = []
            page_errors = []
            page.on("console", lambda message, bucket=console_errors: bucket.append(message.text) if message.type == "error" else None)
            page.on("pageerror", lambda error, bucket=page_errors: bucket.append(str(error)))
            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(2500)
            canvas_box = page.locator("#canvas").bounding_box()
            screenshot = screenshot_dir / f"{width}x{height}.png"
            page.screenshot(path=str(screenshot))
            canvas_fills_viewport = bool(
                canvas_box
                and canvas_box["x"] == 0
                and canvas_box["y"] == 0
                and canvas_box["width"] == width
                and canvas_box["height"] == height
            )
            passed = canvas_fills_viewport and not console_errors and not page_errors
            failed = failed or not passed
            results.append({
                "size": f"{width}x{height}",
                "passed": passed,
                "canvas": canvas_box,
                "console_errors": console_errors,
                "page_errors": page_errors,
                "screenshot": str(screenshot),
            })
            context.close()

        interaction_cases = [
            ("keyboard", {"viewport": {"width": 1280, "height": 720}}, lambda page: page.keyboard.press("Space")),
            ("mouse", {"viewport": {"width": 1280, "height": 720}}, lambda page: page.mouse.click(290, 465)),
            ("touch", {"viewport": {"width": 390, "height": 664}, "has_touch": True, "is_mobile": True}, lambda page: page.touchscreen.tap(195, 290)),
        ]
        for name, context_options, action in interaction_cases:
            context = browser.new_context(**context_options)
            page = context.new_page()
            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(2200)
            action(page)
            page.wait_for_timeout(350)
            data = saved_progress(page)
            passed = data.get("total_lobsters") == 1.0 and data.get("achievements", {}).get("first_catch") is True
            failed = failed or not passed
            results.append({"input": name, "passed": passed, "saved_total": data.get("total_lobsters")})
            context.close()
        browser.close()

    print(json.dumps(results, indent=2))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
