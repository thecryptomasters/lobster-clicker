# Lobster Clicker — Final Launch Sprint

Last updated: 2026-08-31

Scope: game functionality, code, packaging, and playtesting required for a confident 1.0 build. Steam store-page, submission, and marketing steps are intentionally excluded.

Status legend: `[ ]` remaining, `[~]` underway or awaiting human verification, `[x]` complete and verified.

## Launch definition

Lobster Clicker is ready when a new player can understand the game, reach the first Molt without developer help, and continue into the permanent progression loop without losing progress or encountering a broken purchase, unreachable control, unreadable screen, or major economy stall.

## Completed foundation

- [x] Core clicking, buildings, upgrades, boosts, cards, offline earnings, save/reload, and reset loop.
- [x] Paid card choices survive reload; invalid and no-reward card draws are prevented.
- [x] Active boosts and cooldowns persist through save/reload.
- [x] Versioned saves, validation, backup recovery, and atomic native writes.
- [x] Reset confirmation and complete clearing of temporary state.
- [x] First-session objectives, achievement toasts, and deterministic Disco Lobster event.
- [x] Buy 1, Buy 10, and Buy Max building controls.
- [x] Molting prestige loop with permanent Shell bonuses.
- [x] Fractional and compact large-number formatting.
- [x] Persistent music, SFX, mute, and reduced-motion settings.
- [x] Original SFX for clicking, purchasing, achievements, Disco, boosts, and Molting.
- [x] Release-only developer-menu guard and safe farm-name length.
- [x] Web, Windows, macOS, and Linux export presets.
- [x] Automated regression coverage for economy, saves, migrations, offline earnings, boosts, cards, reset, settings, and Molting.
- [x] Per-frame UI update work reduced.

## Sprint 1 — Release-blocker QA

Goal: prove that progress, purchases, and essential controls cannot fail.

- [x] Add a headless main-scene smoke test for fresh boot, click, purchase, save, and reload.
- [x] Add exact-debit, duplicate-rejection, and reward-delivery tests for every LC-spending family.
- [~] Test normal exit, forced close, corrupted primary save, backup recovery, and v2-to-v3 migration in packaged builds (automated recovery/migration passes; human lifecycle test pending).
- [x] Test offline earnings at zero production, every upgrade tier, the duration cap, and future timestamps.
- [~] Verify mouse and touch can perform every essential action (exported first-catch smoke passes; full human path pending).
- [~] Complete keyboard navigation, visible focus states, and activation for every essential action (implemented and automated core path passes; full human path pending).
- [~] Complete controller navigation and activation for every essential action (A and LB/RB automated; hardware path pending).
- [x] Verify reset and Molt confirmation dialogs cannot be triggered accidentally or bypassed.

Exit gate: no transaction loses LC without granting or restoring its reward, and every required action works without a mouse.

## Sprint 2 — Progression and first-session balance

Goal: make the entire run understandable and paced well, not merely mathematically completable.

- [ ] Conduct at least three human fresh-save first-10-minute tests.
- [ ] Confirm ordinary players reach first automation, first upgrade prompt, and Disco Lobster within ten minutes.
- [ ] Confirm objectives clearly teach buildings, upgrades, boosts, cards, offline earnings, and Molting.
- [ ] Run a complete zero-to-first-Molt playtest without developer tools.
- [ ] Record the time and cost between every meaningful unlock and identify dead zones.
- [ ] Rebalance any unexplained stall longer than the intended idle interval.
- [x] Verify click upgrades communicate their actual multiplicative stacking behavior.
- [ ] Confirm Shell awards and permanent bonuses make the second run noticeably faster without trivializing it.
- [~] Run a second-Molt economy simulation and spot-check it with human play (exact 1/2/3-Shell boundaries, two-Molt compounding, and persistence pass; full pacing simulation pending).

Exit gate: a new player understands the loop without outside help, reaches the first Molt on the intended timetable, and wants to begin the next run.

## Sprint 3 — Presentation and accessibility

Goal: remove visible prototype roughness from every supported layout.

- [~] Verify 320x568, 390x664, 480x854, 720p, 1080p, 1440p, and ultrawide layouts (automated and visual fresh-save plus synthetic long-state passes complete; human natural-progression pass pending).
- [ ] Verify every icon, label, dialog, tooltip, toast, and long number remains readable.
- [ ] Verify long farm names cannot clip or break layouts.
- [ ] Tune default music and SFX levels from human feedback.
- [ ] Confirm reduced-motion mode removes nonessential particles, pulsing, and camera/UI movement.
- [ ] Add a high-contrast/readability option if human testing shows the current palette is insufficient.
- [x] Add a high-visibility gold focus indicator for keyboard/controller navigation.
- [ ] Perform a final copy pass for objectives, upgrades, achievements, settings, Molting, and offline-return messages.

Exit gate: all controls are readable and reachable at every target resolution and input method.

## Sprint 4 — Native build and stability pass

Goal: produce repeatable desktop builds that remain stable over real play sessions.

- [ ] Launch and play the Windows package on Windows hardware.
- [~] Launch and play the macOS package on supported Intel/Apple Silicon targets as applicable (universal package headless launch passes; graphical human pass pending).
- [ ] Launch and play the Linux package on a supported distribution.
- [ ] Verify native save locations, save persistence, clean shutdown, forced close, and relaunch on each target OS.
- [~] Run a multi-hour soak test with automation and offline-return cycles (repeatable browser harness and accelerated stress proof pass; full-duration result pending).
- [ ] Check logs for errors, runaway memory use, repeated signals, and save corruption.
- [ ] Confirm release builds contain no accessible debug/developer controls.
- [x] Lock the supported Godot version and document clean regression, web-smoke, and release export commands.

Exit gate: each supported package launches, saves, closes, restores, and runs for hours without errors or progression corruption.

## Sprint 5 — Release candidate sign-off

Goal: freeze a build that can be called Lobster Clicker 1.0.

- [x] Add an in-game credits/licenses screen for music, fonts, code, and visual assets.
- [x] Confirm every included asset has documented permission or an original-source record and package third-party notices.
- [~] Set the release-candidate version consistently in the project and desktop export metadata (`0.9.0`; final `1.0.0` waits for sign-off).
- [ ] Run the complete automated suite against the exact release candidate.
- [ ] Run one final fresh-save and one returning-save acceptance test.
- [ ] Archive checksums for the Windows, macOS, and Linux release packages.
- [ ] Tag the approved release candidate in Git.
- [ ] Obtain Ross's final gameplay and audio approval.

Exit gate: all earlier gates pass, no release-blocking bugs remain, and the exact packaged build receives final approval.

## Explicitly deferred from 1.0

These are worthwhile but should not delay launch unless testing proves they are necessary:

- Large-scale refactoring of `main.gd` and `game_manager.gd`.
- Platform achievements.
- Cloud saves and account systems.
- Additional prestige layers beyond Molting.
- New buildings, cards, events, monetization, or live-ops systems.
- Steam store-page, upload, submission, and marketing work.

## Input needed from the team

Development can continue without input until the human playtest gates. The team will need to provide:

1. Three first-10-minute playtests from people who have not been coached.
2. Feedback on default music/SFX loudness and whether any sound becomes annoying during repeated play.
3. Access to representative Windows and Linux machines if those platforms remain launch targets.
4. Final judgment on the intended first-Molt duration after one complete human run.
5. Final release-candidate approval after the acceptance pass.

## Recommended execution order

1. Release-blocker QA and missing automated smoke coverage.
2. Keyboard/controller completion.
3. Human first-session and full-progression balance tests.
4. Resolution, accessibility, and copy polish.
5. Native OS testing and soak testing.
6. Credits, licensing, version lock, and release-candidate sign-off.

Estimated remaining effort: 7–12 focused development/QA days, plus access to human playtesters and target operating systems. Scope changes or major economy rework would extend that estimate.
