# 🦞 Lobster Clicker

A Cookie Clicker-inspired idle game with a lobster theme.

Built with Godot 4. Deployed to Vercel (HTML5 export).

## Development

Open the project in Godot 4.6 or run it from the command line:

```bash
godot --path .
```

Run the regression suite before exporting:

```bash
bash scripts/test.sh
```

Run the exported-web resolution/input smoke after serving `export/` locally:

```bash
python3 -m http.server 8765 --directory export
python3 tools/web_smoke.py
```

The web smoke requires the Python Playwright package and its Chromium browser.

Run a browser soak with repeated saves, reloads, and accelerated offline-return cycles:

```bash
python3 tools/web_soak.py http://127.0.0.1:8765/ --duration-seconds 7200
```

Use a shorter duration only to verify the harness itself; release evidence should use the full two-hour default or longer.

## Deployment

HTML5 export deployed to Vercel.

```bash
godot --headless --path . --export-release Web export/index.html
```

Desktop release builds are written to the ignored `build/` directory:

```bash
godot --headless --path . --export-release "Windows Desktop" build/windows/LobsterClicker.exe
godot --headless --path . --export-release macOS build/macos/LobsterClicker.zip
godot --headless --path . --export-release Linux build/linux/lobster-clicker.x86_64
```
