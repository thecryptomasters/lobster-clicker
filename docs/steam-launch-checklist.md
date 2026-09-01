# Lobster Clicker — Steam Launch Checklist

Last updated: 2026-09-01

Launch definition: ship a polished, stable Windows-first Lobster Clicker 1.0 through Steam as ABC's proof of concept for completing the full Steamworks release pipeline. The browser build is the QA/playtest channel, not the launch milestone.

Status legend: `[ ]` remaining, `[~]` underway or awaiting evidence, `[x]` complete.

## 1. Steamworks timing gate

- [ ] Confirm the Steamworks partner account is fully onboarded with identity, tax, and bank details accepted.
- [ ] Pay the $100 Steam Direct fee for the Lobster Clicker application and record the payment date.
- [ ] Record the assigned App ID and Windows depot ID in the private release record; do not commit credentials.
- [ ] Confirm the earliest release date allowed by Steam's 30-day post-fee waiting period.
- [ ] Publish an approved Coming Soon page at least 14 days before release.

Steam's timing gates may overlap. The honest launch date is the latest of the post-fee day 30, Coming Soon day 14, Valve approvals, and our internal release approval.

## 2. Product scope and positioning

- [x] Public launch target is Steam; browser remains the test channel.
- [x] Windows-first release keeps the POC narrow.
- [x] Steam achievements, Cloud Saves, trading cards, Workshop, and leaderboards are deferred from 1.0.
- [ ] Choose launch price and any launch discount.
- [ ] Approve the one-sentence positioning, short description, and full store description.
- [ ] Complete Steam's content survey and supported-feature declarations using only launch-day functionality.

## 3. Visual polish and store-ready presentation

- [x] Establish the final visual direction in `docs/visual-polish-brief.md`.
- [x] Apply the approved palette, typography, UI panels, buttons, tabs, and information hierarchy.
- [x] Replace or polish the hero lobster/claw artwork and key animations.
- [x] Add coherent building, upgrade, card, achievement, and Molting iconography.
- [x] Complete the background/environment and late-game visual treatment.
- [x] Capture six final gameplay-only 1920×1080 screenshots after visual polish is implemented.
- [x] Produce every required Steam capsule/library asset with a readable Lobster Clicker title or logo.
- [ ] Produce a gameplay trailer only if it improves the page; it is not required for the POC.

## 4. Windows build and SteamPipe

- [x] Godot Windows x86-64 release export preset exists and produces a valid GUI PE executable.
- [x] Repeatable Windows staging/checksum script exists at `tools/prepare_steam_windows.sh`.
- [x] SteamPipe App Build and Windows depot templates exist under `steam/`.
- [ ] Stage the exact 1.0 Windows candidate and archive its SHA-256 manifest.
- [ ] Configure the Steam launch option for `LobsterClicker.exe` on Windows.
- [ ] Configure the Windows content depot and include it in the Developer Comp and store packages.
- [ ] Upload through SteamPipe to a password-protected test branch first.
- [ ] Install the Steam-delivered build on a clean Windows machine and verify launch, save, update, uninstall, and reinstall.
- [ ] Confirm no console window, debug menu, test save, secrets, or development files ship.

## 5. Release QA

- [x] Automated Godot regression suite covers saves, transactions, boosts, settings, Molting, and input fundamentals.
- [x] Browser fresh/late-game layout checks cover six resolutions and keyboard, mouse, and touch.
- [~] Automated soak harness exists and accelerated stress proof passes; full-duration evidence remains pending.
- [~] Ross reports audio balance, browser save/reopen, and Mac hardware behavior pass.
- [ ] Complete a two-hour automated soak against the release candidate.
- [ ] Complete three uncoached first-10-minute playtests.
- [ ] Complete one natural zero-to-first-Molt run and record pacing/dead zones.
- [ ] Verify keyboard and mouse through every required action in the packaged Windows build.
- [ ] Verify hardware controller behavior only if controller support is declared on the Steam page.
- [ ] Run fresh-save and returning-save acceptance on the exact Steam-delivered candidate.

## 6. Valve review and release

- [ ] Complete the store-presence checklist and submit it for Valve review.
- [ ] Resolve store feedback and publish the Coming Soon page.
- [ ] Upload a near-final default-branch build and complete the build checklist.
- [ ] Submit the build for Valve review after store presence submission.
- [ ] Allow at least seven business days for each review path and corrections.
- [ ] Confirm store page, build, pricing, packages, release date, and Coming Soon timer are green.
- [ ] Bump project and export metadata from `0.9.0` to `1.0.0` and create the signed release commit/tag.
- [ ] Obtain Ross's final GO.
- [ ] Use Steamworks Release App controls manually at the approved launch time.
- [ ] Install the public build immediately after release and run the launch smoke.

## Current blockers requiring Ross

1. Confirm whether the Steam Direct fee has already been paid for this app; if yes, provide the payment date.
2. Provide the Steam App ID and Windows depot ID once created.
3. Choose price/launch-discount direction before store review.
4. Approve the visual direction and final store assets.
5. Provide or authorize access to a Windows machine for the Steam-delivered acceptance pass.

## Official references

- Steam Direct and timing: https://partner.steamgames.com/steamdirect
- Release process: https://partner.steamgames.com/doc/store/releasing
- Review process: https://partner.steamgames.com/doc/store/review_process
- SteamPipe uploads: https://partner.steamgames.com/doc/sdk/uploading
