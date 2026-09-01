#!/usr/bin/env python3
"""Exercise a locally served Godot web export across launch resolutions."""

import argparse
import json
import sys
import time
from pathlib import Path
from urllib.parse import urlsplit

from playwright.sync_api import sync_playwright


SIZES = [(320, 568), (390, 664), (480, 854), (1280, 720), (1920, 1080), (2560, 1080)]


def saved_progress(page):
    raw = page.evaluate("localStorage.getItem('lobster_clicker_save')")
    return json.loads(raw) if raw else {}


def storage_state(url, data):
    parsed = urlsplit(url)
    origin = f"{parsed.scheme}://{parsed.netloc}"
    return {"cookies": [], "origins": [{"origin": origin, "localStorage": [{"name": "lobster_clicker_save", "value": json.dumps(data)}]}]}


def build_long_state(page):
    page.keyboard.press("Space")
    page.wait_for_timeout(250)
    data = saved_progress(page)
    if not data:
        raise RuntimeError("could not create the long-state seed save")
    data.update({
        "total_lobsters": 9_876_543_210_000_000.0,
        "lifetime_lobsters": 9_876_543_210_000_000.0,
        "run_lobsters": 90_000_000_000.0,
        "shells": 1234,
        "molt_count": 42,
        "farm_name": "The Longest Lobster Farm Name!!!",
        "music_muted": True,
        "reduced_motion": True,
        "achievements": {"first_catch": True, "tiny_fleet": True, "ten_on_deck": True, "disco_lobster": True},
        "first_rare_event_seen": True,
        "pending_premium_options": [],
        "pending_premium_cost": 0.0,
        "active_boost": {},
        "boost_end_time": 0.0,
        "cooldown_end_time": 0.0,
        "single_building_boost_index": -1,
        "single_building_boost_mult": 1.0,
        "single_boost_end_time": 0.0,
        "last_save_time": int(time.time()),
    })
    data["building_counts"] = [100 for _ in data.get("building_counts", [])]
    data["building_upgrades"] = [[True for _ in tiers] for tiers in data.get("building_upgrades", [])]
    for key in ("click_upgrades", "cps_click_upgrades", "hold_click_upgrades", "gacha_cooldown_upgrades", "offline_rate_upgrades", "offline_duration_upgrades"):
        data[key] = [True for _ in data.get(key, [])]
    return data


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

            long_state = build_long_state(page)
            context.close()

            long_context = browser.new_context(
                viewport={"width": width, "height": height},
                storage_state=storage_state(args.url, long_state),
            )
            page = long_context.new_page()
            long_console_errors = []
            long_page_errors = []
            page.on("console", lambda message, bucket=long_console_errors: bucket.append(message.text) if message.type == "error" else None)
            page.on("pageerror", lambda error, bucket=long_page_errors: bucket.append(str(error)))
            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(2200)
            tab_screenshots = []
            for tab_index, tab_name in enumerate(("buildings", "upgrades", "cards", "molt")):
                if tab_index:
                    page.keyboard.press("E")
                    page.wait_for_timeout(350)
                tab_screenshot = screenshot_dir / f"{width}x{height}-long-{tab_name}.png"
                page.screenshot(path=str(tab_screenshot))
                tab_screenshots.append(str(tab_screenshot))
            restored = saved_progress(page)
            long_passed = (
                restored.get("farm_name") == long_state["farm_name"]
                and restored.get("total_lobsters", 0) >= long_state["total_lobsters"]
                and restored.get("shells") == long_state["shells"]
                and not long_console_errors
                and not long_page_errors
            )
            failed = failed or not long_passed
            results.append({
                "long_state_size": f"{width}x{height}",
                "passed": long_passed,
                "farm_name_length": len(restored.get("farm_name", "")),
                "total_lobsters": restored.get("total_lobsters"),
                "shells": restored.get("shells"),
                "tabs": tab_screenshots,
                "console_errors": long_console_errors,
                "page_errors": long_page_errors,
            })
            long_context.close()

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

        # Exercise the real prestige flow with motion enabled. This protects
        # the theatrical overlay from becoming a screenshot-only flourish:
        # the same click must still confirm a Molt and persist the new Shells.
        molt_state = dict(long_state)
        molt_state.update({
            "total_lobsters": 10_000_000_000.0,
            "run_lobsters": 10_000_000_000.0,
            "shells": 0,
            "molt_count": 0,
            "reduced_motion": False,
            "last_save_time": int(time.time()),
        })
        molt_state["building_counts"] = [0 for _ in molt_state.get("building_counts", [])]
        molt_state["building_counts"][-1] = 1
        context = browser.new_context(
            viewport={"width": 1280, "height": 720},
            storage_state=storage_state(args.url, molt_state),
        )
        page = context.new_page()
        console_errors = []
        page_errors = []
        page.on("console", lambda message: console_errors.append(message.text) if message.type == "error" else None)
        page.on("pageerror", lambda error: page_errors.append(str(error)))
        page.goto(args.url, wait_until="networkidle")
        page.wait_for_timeout(2200)
        for _ in range(3):
            page.keyboard.press("E")
            page.wait_for_timeout(120)
        page.mouse.click(930, 321)
        page.wait_for_timeout(180)
        page.keyboard.press("Enter")
        page.wait_for_timeout(420)
        celebration_screenshot = screenshot_dir / "molt-celebration.png"
        page.screenshot(path=str(celebration_screenshot))
        molt_result = saved_progress(page)
        passed = (
            molt_result.get("shells", 0) >= 1
            and molt_result.get("molt_count") == 1
            and not console_errors
            and not page_errors
        )
        failed = failed or not passed
        results.append({
            "interaction": "molt_celebration",
            "passed": passed,
            "shells": molt_result.get("shells"),
            "molt_count": molt_result.get("molt_count"),
            "screenshot": str(celebration_screenshot),
            "console_errors": console_errors,
            "page_errors": page_errors,
        })
        context.close()

        # Repeat the prestige path on the narrow touch layout. The Down control
        # scrolls the Molt action into view before the confirmation is accepted.
        context = browser.new_context(
            viewport={"width": 390, "height": 664},
            has_touch=True,
            is_mobile=True,
            storage_state=storage_state(args.url, molt_state),
        )
        page = context.new_page()
        console_errors = []
        page_errors = []
        page.on("console", lambda message: console_errors.append(message.text) if message.type == "error" else None)
        page.on("pageerror", lambda error: page_errors.append(str(error)))
        page.goto(args.url, wait_until="networkidle")
        page.wait_for_timeout(2200)
        for _ in range(3):
            page.keyboard.press("E")
            page.wait_for_timeout(120)
        for _ in range(4):
            page.touchscreen.tap(195, 640)
            page.wait_for_timeout(120)
        page.touchscreen.tap(195, 576)
        page.wait_for_timeout(180)
        page.keyboard.press("Enter")
        page.wait_for_timeout(420)
        mobile_celebration_screenshot = screenshot_dir / "molt-celebration-mobile.png"
        page.screenshot(path=str(mobile_celebration_screenshot))
        mobile_molt_result = saved_progress(page)
        passed = (
            mobile_molt_result.get("shells", 0) >= 1
            and mobile_molt_result.get("molt_count") == 1
            and not console_errors
            and not page_errors
        )
        failed = failed or not passed
        results.append({
            "interaction": "molt_celebration_mobile",
            "passed": passed,
            "shells": mobile_molt_result.get("shells"),
            "molt_count": mobile_molt_result.get("molt_count"),
            "screenshot": str(mobile_celebration_screenshot),
            "console_errors": console_errors,
            "page_errors": page_errors,
        })
        context.close()
        browser.close()

    print(json.dumps(results, indent=2))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
