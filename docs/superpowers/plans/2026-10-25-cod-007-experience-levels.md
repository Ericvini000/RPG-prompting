# COD-007 Experience and Levels Implementation Plan

**Goal:** Award enemy XP, calculate levels with excess XP retained, and queue one pending choice per level.

**Spec:** `docs/GDD.md` sections 6, 12, and COD-007; `docs/ARCHITECTURE.md` sections 4 and 5.

**Constraints:** Godot 4.7.2 and typed GDScript. Keep progression state in a RunManager Autoload. COD-008 owns card selection and combat pause. Preserve pre-existing editor changes to the arena and resource files.

## Task 1: Progression state

- Write a failing headless test for thresholds 20, 30, 40, 50; exact thresholds; excess XP; several level-ups from one grant; one request per level; queue consumption; reset; and non-positive XP.
- Implement `scripts/core/run_manager.gd` and register `RunManager` in `project.godot`.
- Import, run the progression test, then commit the state and test.

## Task 2: Enemy reward integration

- Write a failing headless test that defeats enemies created by WaveDirector and checks that RunManager receives their configured XP exactly once. Check the cumulative result after all three waves.
- Connect each spawned enemy's `enemy_defeated(xp_reward)` signal to `RunManager.add_experience`; reset run state when Main starts a new session.
- Keep combat running while choices are pending until COD-008 supplies the selection screen and pause flow.
- Update README and architecture, import, run all smoke tests and the main scene, then commit the integration.
