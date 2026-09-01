# Lobster Clicker — Human Batch Test

Use this after the next approved deployment. Testers should not read the expected outcomes before their first ten minutes.

## Test setup

- Use the deployed build on at least one desktop browser and one phone.
- One tester should use a controller; one should use keyboard only for five minutes.
- For a fresh run, use a private window or Settings → Reset All Progress.
- Record device, operating system, browser, input method, and approximate window size.
- Capture a screenshot and the exact action whenever something breaks or feels confusing.

## Pass A — Uncoached first ten minutes

Do not explain the game. Record the timestamp when the player:

- [ ] Understands that the claw generates Lobster Coins.
- [ ] Buys the first Coin Collecting automation.
- [ ] Notices and buys or intentionally saves for the first upgrade.
- [ ] Encounters Disco Lobster.
- [ ] Understands that the crew earns LC while the game is closed.
- [ ] Discovers Buy 1, Buy 10, and Buy Max.
- [ ] Can explain the next objective without coaching.

Ask afterward:

1. What was confusing?
2. When did the game first become fun?
3. What did you think Molting would do?
4. Was there a point where you did not know what to buy next?
5. Did any sound become irritating or feel too loud?

## Pass B — Controls and layout

Complete each available column for desktop, mobile, keyboard, and controller.

- [ ] Click/tap/Space/controller A activates the claw.
- [ ] Tab/D-pad moves through visible controls with a clear gold focus ring.
- [ ] Enter/Space/controller A activates the focused control.
- [ ] Q/E and controller LB/RB cycle through unlocked tabs.
- [ ] Locked Consumables is skipped during tab cycling.
- [ ] Buildings, upgrades, cards, boosts, Molting, Settings, and dialogs are reachable without a mouse.
- [ ] Scrolling works in long Buildings and Upgrades lists.
- [ ] Settings and Mute never overlap Molt or another control.
- [ ] The 32-character farm-name limit cannot break the layout.
- [ ] Text, costs, counts, and buttons remain readable at the smallest tested size.

## Pass C — Save and transaction abuse

- [ ] Buy a building, refresh/relaunch, and confirm the building and LC balance persist.
- [ ] Start a paid Lobster Card draw, close before choosing, reopen, and confirm the same choices remain without a second charge.
- [ ] Select a restored paid card and confirm the reward arrives exactly once.
- [ ] Trigger a timed boost, close/reopen, and confirm the remaining boost/cooldown survives.
- [ ] Close the game with positive LCPS, wait at least six minutes, reopen, and confirm offline earnings appear once.
- [ ] Change music/SFX/mute/reduced-motion settings, reopen, and confirm they persist.
- [ ] Open Reset All Progress, cancel, and confirm nothing changes.
- [ ] Confirm Reset All Progress and verify the game returns to a truly fresh state.
- [ ] Attempt Molting, cancel, and confirm nothing changes.
- [ ] Complete Molting and confirm Shells persist while ordinary run progress resets.

## Pass D — Full progression run

At least one tester completes an honest zero-to-first-Molt run without developer tools.

Record the elapsed time for:

- [ ] First building.
- [ ] First building upgrade.
- [ ] Consumables unlock.
- [ ] First paid card.
- [ ] Each new building tier.
- [ ] Immortality purchase.
- [ ] First Molt.

Flag any period where the player has no meaningful decision or visible near-term target. After Molting, play another 15 minutes and report whether the Shell bonus feels noticeable.

## Pass E — Audio, motion, and polish

- [ ] Default music level sits below SFX and never masks feedback.
- [ ] Click, purchase, achievement, Disco, boost, and Molt sounds are distinct.
- [ ] Repeated clicks and purchases remain tolerable after ten minutes.
- [ ] Reduced motion removes nonessential movement and particles.
- [ ] Every objective, upgrade, achievement, card, Settings label, and Molt message reads naturally.
- [ ] Credits & Licenses opens and closes correctly.

## Bug report template

- Device/OS/browser:
- Input method:
- Fresh or returning save:
- Exact action:
- Expected result:
- Actual result:
- Reproducible every time?:
- Screenshot/video:
- Severity: blocker / major / minor / polish

## Approval rule

The batch passes when there are no blocker or major issues, no tester loses LC or progress, every essential action works with the assigned input method, and the full-run tester reaches Molting without coaching or an unexplained progression wall.
