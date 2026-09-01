# Lobster Clicker Steam Artwork

This folder contains the launch-candidate Steam artwork generated from the shipped neo-80s harbor visual identity.

## Source artwork

- `source/key-art-wide.png` — artwork-only midnight harbor composition for landscape assets.
- `source/key-art-portrait.png` — artwork-only vertical harbor composition for portrait assets.

Both source paintings were created specifically for Lobster Clicker with OpenAI image generation on 2026-09-01. The existing in-game claw and a real late-game screenshot were supplied as visual references. The briefs requested polished hand-painted neo-80s seaside arcade key art, an oversized red lobster claw trophy, the game's cyan/coral/gold palette, a moonlit working harbor, and no words, logos, watermarks, borders, or unrelated characters.

## Final assets

- `final/header_capsule.png` — 920×430
- `final/small_capsule.png` — 462×174
- `final/main_capsule.png` — 1232×706
- `final/vertical_capsule.png` — 748×896
- `final/library_capsule.png` — 600×900
- `final/library_header.png` — 920×430
- `final/library_hero.png` — 3840×1240, artwork only
- `final/library_logo.png` — 1280×330, transparent
- `final/page_background.png` — 1438×810, artwork only

Run `python3 tools/build_steam_art.py` to reproduce the crops, title treatment, and final dimensions from the source artwork.

## Gameplay screenshots

The six 1920×1080 PNGs under `steam/screenshots/` are direct captures of the running release candidate. They contain no composited marketing content. Rebuild them from a locally served web export with:

```sh
python3 tools/capture_steam_screenshots.py http://127.0.0.1:8765/
```

Asset requirements were checked against Valve's standard store and library asset documentation on 2026-09-01:

- https://partner.steamgames.com/doc/store/assets/standard
- https://partner.steamgames.com/doc/store/assets/libraryassets
- https://partner.steamgames.com/doc/store/assets/rules
