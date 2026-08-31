# Lobster Clicker Finish-Line Checklist

Status legend: `[ ]` not started, `[~]` in progress, `[x]` verified.

## Release blockers

- [x] Make paid capsule/card transactions survive save, reload, and interrupted selection.
- [x] Prevent invalid card rewards and fully reset hidden timer state.
- [~] Add save schema versioning, validation, backup recovery, and atomic native writes.
- [~] Replace unsupported glyphs and verify every control is readable.
- [~] Add keyboard/controller navigation and desktop export presets.
- [ ] Define and implement the 1.0 endgame/progression loop.

## First-session experience

- [x] Show a clear objective from the first click.
- [x] Add saved achievement toasts for first click, first building, ten buildings, Disco Lobster, and offline return.
- [x] Trigger a deterministic saved Disco Lobster event by 100 lifetime LC.
- [ ] Verify a fresh player reaches automation, an upgrade prompt, and Disco Lobster within ten minutes.

## Quality and polish

- [~] Fix fractional and large-number presentation.
- [~] Persist audio/settings state and add music/SFX controls.
- [x] Add bulk building purchases.
- [x] Reduce per-frame UI signal work.
- [~] Add regression tests for economy, saves, offline earnings, boosts, cards, and reset.
- [ ] Complete desktop/mobile soak and full-progression playtests.

## Release acceptance

- [ ] No purchase can consume LC without delivering or restoring its reward.
- [ ] Normal exit, forced close, corrupted primary save, and migration preserve progress.
- [ ] Mouse, touch, keyboard, and controller can perform every essential action.
- [ ] All supported resolutions have readable text and reachable controls.
- [ ] A full progression run has no unexplained stalls or dead ends.
