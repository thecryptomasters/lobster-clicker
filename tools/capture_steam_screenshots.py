#!/usr/bin/env python3
"""Capture honest 1920x1080 Steam screenshots from the web release candidate."""

import argparse
import time
from pathlib import Path

from playwright.sync_api import sync_playwright

from web_smoke import build_long_state, saved_progress, storage_state


VIEWPORT = {"width": 1920, "height": 1080}


def open_page(browser, url, state=None):
    options = {"viewport": VIEWPORT}
    if state is not None:
        options["storage_state"] = storage_state(url, state)
    context = browser.new_context(**options)
    page = context.new_page()
    errors = []
    page.on("console", lambda message: errors.append(message.text) if message.type == "error" else None)
    page.on("pageerror", lambda error: errors.append(str(error)))
    page.goto(url, wait_until="networkidle")
    page.wait_for_timeout(2300)
    return context, page, errors


def screenshot(page, output: Path, name: str):
    path = output / name
    page.screenshot(path=str(path))
    print(path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("url", nargs="?", default="http://127.0.0.1:8765/")
    parser.add_argument("--output", default="steam/screenshots")
    args = parser.parse_args()
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    all_errors = []

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)

        seed_context, seed_page, errors = open_page(browser, args.url)
        seed_page.keyboard.press("Space")
        seed_page.wait_for_timeout(250)
        long_state = build_long_state(seed_page)
        long_state["farm_name"] = "Neon Claw Harbor"
        long_state["reduced_motion"] = False
        all_errors.extend(errors)
        seed_context.close()

        context, page, errors = open_page(browser, args.url, long_state)
        screenshot(page, output, "01-harbor-empire.png")
        page.keyboard.press("E")
        page.wait_for_timeout(350)
        screenshot(page, output, "02-upgrade-arcade.png")
        page.keyboard.press("E")
        page.wait_for_timeout(350)
        screenshot(page, output, "03-capsule-catcher.png")
        page.mouse.click(1395, 765)
        page.wait_for_timeout(850)
        screenshot(page, output, "04-lobster-card-draw.png")
        all_errors.extend(errors)
        context.close()

        offline_state = dict(long_state)
        offline_state["last_save_time"] = int(time.time()) - 3600
        context, page, errors = open_page(browser, args.url, offline_state)
        screenshot(page, output, "05-offline-shift-report.png")
        all_errors.extend(errors)
        context.close()

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
        context, page, errors = open_page(browser, args.url, molt_state)
        for _ in range(3):
            page.keyboard.press("E")
            page.wait_for_timeout(120)
        page.mouse.click(1395, 482)
        page.wait_for_timeout(180)
        page.keyboard.press("Enter")
        page.wait_for_timeout(420)
        result = saved_progress(page)
        if result.get("molt_count") != 1:
            all_errors.append("Molt capture did not complete a real Molt")
        screenshot(page, output, "06-molt-complete.png")
        all_errors.extend(errors)
        context.close()
        browser.close()

    if all_errors:
        for error in all_errors:
            print(f"ERROR: {error}")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
