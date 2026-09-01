# Lobster Clicker — Visual Polish Brief

Last updated: 2026-09-01

## Goal

Turn the stable prototype into a distinctive small premium Steam game: playful, nautical, readable, and satisfying without looking like a casino, ad-driven mobile game, or generic dashboard.

Working direction: **Midnight Lobster Harbor** — a cozy after-dark fishing port crossed with a slightly ridiculous arcade machine.

## Visual principles

1. The lobster is the star. Clicking it should feel tactile and expressive even when the player ignores every number.
2. Progress should physically enrich the harbor: more lights, boats, traps, signs, buildings, and absurd late-game technology.
3. Information stays readable at 320px and at ultrawide desktop sizes.
4. Gold indicates earned value and focus; coral indicates action; seafoam indicates permanent progress; violet is reserved for unusual/card events.
5. Motion celebrates decisions but never hides information. Reduced-motion mode remains first-class.

## Proposed palette

- Deep Harbor: `#071725` — primary background
- Dock Navy: `#10283A` — panels and cards
- Lobster Coral: `#E9553F` — primary action and hero color
- Shell Highlight: `#FF846B` — hover, shine, and animation accents
- Coin Gold: `#FFD166` — LC, focus, purchases, and milestones
- Seafoam: `#55D6BE` — Molting and permanent progression
- Foam White: `#EAF6F8` — primary text
- Mist Blue: `#94B8C7` — supporting text
- Card Violet: `#A56DE2` — boosts and rare events

All text/background pairs must retain strong contrast. Color is never the only status signal.

## Typography direction

- Display/logo candidate: a chunky, friendly condensed face with nautical-poster energy.
- UI/body candidate: a highly readable rounded sans with clear numerals at small sizes.
- Use no more than two font families and three weights.
- Large-number suffixes, LCPS, costs, and counts must remain unambiguous at mobile sizes.
- Final fonts must ship locally with documented commercial redistribution rights, preferably OFL.

Candidate pairing for the first mockup: **Bungee** for display moments and **Atkinson Hyperlegible** for UI/body. Do not add font files until the direction is approved and licenses are included.

## Vertical-slice scope

Polish these surfaces first before applying the system everywhere:

1. Main title/header with Settings and Mute at 390x664 and 1920x1080.
2. Hero lobster/claw button in idle, pressed, boosted, and reduced-motion states.
3. One building row with icon, count, price, production, affordability, hover, focus, and disabled states.
4. Tab bar and bulk-purchase controls.
5. Molting panel at locked, ready, confirmation, and completed states.
6. Achievement toast and Disco Lobster event treatment.

Approval of this slice freezes the design system for the rest of the game.

## Art and motion targets

- Replace the current flat geometric lobster with a more expressive illustrated lobster while preserving a large, obvious hit target.
- Give buildings memorable silhouettes and small environmental vignettes instead of generic text-only rows.
- Add a restrained water shimmer, drifting particles, dock lights, and depth layers to the harbor background.
- Make purchases feel physical: short squash, coin snap, and localized glow.
- Make Molting the visual climax: shell fracture, seafoam light, silhouette reveal, then a calmer upgraded harbor state.
- Keep all effects deterministic enough for QA and disable nonessential movement in reduced-motion mode.

## Store-art bridge

The in-game hero lobster, logo treatment, palette, and harbor environment should directly generate the Steam capsule family. Store art must represent the shipped game and keep the title readable at small capsule sizes.

## Explicit non-goals for this phase

- New progression systems, buildings, cards, or currencies.
- 3D conversion or engine change.
- A full narrative campaign.
- Steam achievements or Cloud Saves before the POC launch.
- Visual effects that materially reduce mobile readability or performance.
