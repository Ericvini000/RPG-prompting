# COD-006 Enemies and Waves Implementation Plan

**Goal:** Add the ranged enemy, tank, and three ordered arena waves defined in GDD v0.1.

**Spec:** `docs/GDD.md`, sections 5 and 14 (COD-006). `docs/ARCHITECTURE.md` defines scene ownership and signals.

**Constraints:** Godot 4.7.2, typed GDScript, no new addon, no XP or result UI in this task. Preserve Funplay MCP, GdUnit4, and existing user edits.

## Task 1: Enemy variants

- Add a failing headless test for ranged and tank stats, ranged spacing and 1.8 s projectile cadence, projectile damage and collision, and tank contact damage.
- Extract shared health, target lookup, defeat signal, and removal into `EnemyController`; move chaser contact logic into `ContactEnemyController` for chaser and tank.
- Add `RangedEnemyController`, `enemy_bolt.tscn`, `ranged_enemy.tscn`, `tank.tscn`, and `data/ranged_enemy.tres`/`data/tank.tres`.
- Keep unspecified projectile speed, preferred range, and tank contact interval configurable and mark them as proposals in the architecture document.
- Import, run the enemy test and existing smoke tests, then commit the enemy variants.

## Task 2: Three configurable waves

- Add a failing headless test for wave compositions (4 chasers; 3 chasers + 2 ranged; 2 chasers + 2 ranged + 1 tank), safe distinct spawn points, ordered transitions, and one completion signal.
- Add `WaveData` resources with enemy scene arrays, `WaveDirector` in Main, and enough fixed arena spawn markers to avoid the player's current location.
- Remove the fixed chaser instance; the director creates enemies in the arena and observes their defeat signals.
- Keep XP rewards as emitted signals for COD-007; no progression or victory screen yet.
- Update README and architecture, import, run all headless checks and a visual runtime check, then commit the wave system.
