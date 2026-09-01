#!/usr/bin/env python3
"""Run a configurable browser soak with save, reload, and offline cycles."""

import argparse
import json
import math
import sys
import time
from urllib.parse import urlsplit

from playwright.sync_api import sync_playwright


SAVE_KEY = "lobster_clicker_save"


def read_save(page):
    raw = page.evaluate("key => localStorage.getItem(key)", SAVE_KEY)
    return json.loads(raw) if raw else {}


def write_save(page, data):
    page.evaluate(
        "([key, value]) => localStorage.setItem(key, JSON.stringify(value))",
        [SAVE_KEY, data],
    )


def storage_state(url, data):
    parsed = urlsplit(url)
    origin = f"{parsed.scheme}://{parsed.netloc}"
    return {"cookies": [], "origins": [{"origin": origin, "localStorage": [{"name": SAVE_KEY, "value": json.dumps(data)}]}]}


def force_save(page):
    page.evaluate("window.dispatchEvent(new Event('pagehide'))")
    page.wait_for_timeout(150)


def validate_save(data, previous=None):
    errors = []
    for key in ("total_lobsters", "lifetime_lobsters", "run_lobsters"):
        value = data.get(key)
        if not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
            errors.append(f"{key} is invalid: {value!r}")
        elif previous and value < previous.get(key, 0):
            errors.append(f"{key} regressed from {previous.get(key)} to {value}")
    counts = data.get("building_counts")
    if not isinstance(counts, list) or not counts or any(not isinstance(v, (int, float)) or v < 0 for v in counts):
        errors.append("building_counts is missing or invalid")
    if data.get("save_version") != 3:
        errors.append(f"unexpected save version: {data.get('save_version')!r}")
    return errors


def build_seed_progress(page):
    page.keyboard.press("Space")
    page.wait_for_timeout(250)
    data = read_save(page)
    if not data:
        raise RuntimeError("fresh click did not create a save")
    data.update(
        {
            "total_lobsters": 5_000_000.0,
            "lifetime_lobsters": 5_000_000.0,
            "run_lobsters": 5_000_000.0,
            "farm_name": "Automated Soak Reef",
            "reduced_motion": True,
            "music_muted": True,
        }
    )
    counts = list(data.get("building_counts", []))
    for index, amount in enumerate((25, 10, 5, 2)):
        if index < len(counts):
            counts[index] = amount
    data["building_counts"] = counts
    data["last_save_time"] = int(time.time())
    return data


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("url", nargs="?", default="http://127.0.0.1:8765/")
    parser.add_argument("--duration-seconds", type=int, default=7200)
    parser.add_argument("--cycle-seconds", type=float, default=10.0)
    parser.add_argument("--reload-every", type=int, default=6)
    parser.add_argument("--offline-every", type=int, default=12)
    parser.add_argument("--offline-seconds", type=int, default=360)
    args = parser.parse_args()
    if args.duration_seconds < 1 or args.cycle_seconds <= 0:
        parser.error("duration and cycle interval must be positive")

    started = time.monotonic()
    deadline = started + args.duration_seconds
    results = {"url": args.url, "requested_seconds": args.duration_seconds, "cycles": 0, "reloads": 0, "offline_cycles": 0}
    failures = []

    with sync_playwright() as playwright:
        browser = playwright.chromium.launch(headless=True)
        context = browser.new_context(viewport={"width": 1280, "height": 720})
        page = context.new_page()
        console_errors = []
        page_errors = []
        page.on("console", lambda message: console_errors.append(message.text) if message.type == "error" else None)
        page.on("pageerror", lambda error: page_errors.append(str(error)))
        page.goto(args.url, wait_until="networkidle")
        page.wait_for_timeout(2200)

        try:
            seed = build_seed_progress(page)
            context.close()

            context = browser.new_context(
                viewport={"width": 1280, "height": 720},
                storage_state=storage_state(args.url, seed),
            )
            page = context.new_page()
            page.on("console", lambda message: console_errors.append(message.text) if message.type == "error" else None)
            page.on("pageerror", lambda error: page_errors.append(str(error)))
            page.goto(args.url, wait_until="networkidle")
            page.wait_for_timeout(2200)
            force_save(page)
            previous = read_save(page)
            failures.extend(validate_save(previous))
            results["start"] = {key: previous.get(key) for key in ("total_lobsters", "lifetime_lobsters", "run_lobsters")}

            while time.monotonic() < deadline and not failures:
                results["cycles"] += 1
                page.keyboard.press("Space")
                page.wait_for_timeout(100)
                force_save(page)
                current = read_save(page)
                failures.extend(validate_save(current, previous))
                previous = current

                if args.offline_every > 0 and results["cycles"] % args.offline_every == 0:
                    before_offline = previous.get("total_lobsters", 0)
                    previous["last_save_time"] = int(time.time()) - args.offline_seconds
                    write_save(page, previous)
                    page.reload(wait_until="networkidle")
                    page.wait_for_timeout(2200)
                    force_save(page)
                    current = read_save(page)
                    failures.extend(validate_save(current, previous))
                    if current.get("total_lobsters", 0) <= before_offline:
                        failures.append("offline cycle did not award positive production")
                    previous = current
                    results["offline_cycles"] += 1
                    results["reloads"] += 1
                elif args.reload_every > 0 and results["cycles"] % args.reload_every == 0:
                    page.reload(wait_until="networkidle")
                    page.wait_for_timeout(2200)
                    force_save(page)
                    current = read_save(page)
                    failures.extend(validate_save(current, previous))
                    previous = current
                    results["reloads"] += 1

                remaining = deadline - time.monotonic()
                if remaining > 0:
                    page.wait_for_timeout(int(min(args.cycle_seconds, remaining) * 1000))

            results["end"] = {key: previous.get(key) for key in ("total_lobsters", "lifetime_lobsters", "run_lobsters")}
            results["elapsed_seconds"] = round(time.monotonic() - started, 2)
            results["console_errors"] = console_errors
            results["page_errors"] = page_errors
            failures.extend(console_errors)
            failures.extend(page_errors)
        except Exception as error:
            failures.append(str(error))
        finally:
            context.close()
            browser.close()

    results["passed"] = not failures
    results["failures"] = failures
    print(json.dumps(results, indent=2))
    return 0 if not failures else 1


if __name__ == "__main__":
    sys.exit(main())
