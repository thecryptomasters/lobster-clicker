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
