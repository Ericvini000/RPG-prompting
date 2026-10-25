# MVP 0.1 Completion Implementation Plan

**Goal:** Complete COD-008 through COD-011 and deliver one playable three-wave roguelite run.

**Spec:** `docs/GDD.md` v0.1, especially sections 3-8 and COD-008 through COD-011. `docs/ARCHITECTURE.md` describes the existing scene paths and signals.

**Architecture:** Keep card definitions in immutable Resources and session modifiers in a separate runtime stats object. UpgradeManager owns offering and applying choices; UpgradeScreen only displays them. RunManager owns pause, result states, and pending level choices. HUD and result screens observe signals. Existing WaveDirector continues to own enemy creation.

**Tech Stack:** Godot 4.7.2, typed GDScript, built-in scenes and SVG placeholders, existing GdUnit4 and Funplay addons.

## Constraints and risks

- Preserve local editor changes to `data/chaser.tres`, `data/player_stats.tres`, and `scenes/arena_01.tscn` unless a required edit can be made without discarding them.
- Do not add a save system, procedural rooms, permanent progression, or external assets.
- Confirm card selection still receives mouse input while SceneTree is paused.
- Confirm multiple pending levels produce separate offers with no repeated card in the same offer.
- Confirm final-wave victory waits until pending card choices are resolved.
- Confirm restart clears entities, XP, levels, modifiers, effects, and pause.

## Task 1: COD-008 card selection

- RED: tests for three distinct eligible definitions, limits, one choice per pending level, and pause/resume.
- Add `UpgradeDefinition` Resource and eight data records with original placeholder icons.
- Add `UpgradeManager`, `UpgradeScreen`, and RunManager state transitions for upgrade selection.
- Import, run the targeted tests and existing suite, visually inspect the selection screen, then commit.

## Task 2: COD-009 upgrade effects

- RED: tests for additive damage/movement, attack interval formula, max/current life, pierce, triple shot, burn, and dash cooldown. Test resource defaults remain unchanged.
- Add runtime player stats, modify player/projectile behavior, and add a reusable burn component.
- Run targeted and regression tests, then commit.

## Task 3: COD-010 interface and results

- RED: tests for HUD signals, victory, defeat, restart, and clean state after restart.
- Add HUD and result scenes, feedback on damage, and Main wiring through RunManager. Include usable normal pause if it does not change the defined state flow.
- Visually inspect gameplay, cards, HUD, and result screens, then commit.

## Task 4: COD-011 stabilization

- Execute import, every smoke test, runtime headless, and visual checks. Review collision, formulas, card eligibility, pause, queued levels, wave order, and restart.
- Fix verified defects with regression tests, update README and architecture, and commit the stabilization work.
- Report tests, known limits, and concrete improvement recommendations.
