# Balance Rebalance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply the "刃尖求生" balance proposal — lower player HP, raise enemy early-game threat, fix lifesteal/shield bugs, fix debug spawn rotation, tighten pressure windows, and wire up component_count_bonus per phase.

**Architecture:** Four focused code fixes (GameState hp_max, CombatSystem lifesteal reset, RuleEngine shield cap + decay, GameLoop debug spawn removal), followed by pure data edits to .tres resource files. All code changes are covered by new or existing GUT tests.

**Tech Stack:** Godot 4, GDScript, GUT test framework (`tests/unit/`), `scripts/self-test.ps1`

---

## Files

| Action | File |
|--------|------|
| Modify | `src/autoloads/GameState.gd` |
| Modify | `src/systems/CombatSystem.gd` |
| Modify | `src/systems/RuleEngine.gd` |
| Modify | `src/systems/GameLoop.gd` |
| Modify | `tests/unit/test_game_state.gd` |
| Modify | `tests/unit/test_combat_system.gd` |
| Modify | `tests/unit/test_rule_engine.gd` |
| Modify | `data/game_config.tres` |
| Modify | `data/enemies/enemy_汲取者.tres` |
| Modify | `data/enemies/enemy_守卫者.tres` |
| Modify | `data/enemies/enemy_急袭者.tres` |
| Modify | `data/enemies/enemy_复制者.tres` |
| Modify | `data/drop_presets/drop_tier_01.tres` |
| Modify | `data/phases/phase_1.tres` through `phase_10.tres` (10 files) |

---

## Task 1: Player hp_max 500 → 250

**Files:** `tests/unit/test_game_state.gd`, `src/autoloads/GameState.gd`

- [ ] **Step 1.1 — Write failing test**

Append to `tests/unit/test_game_state.gd`:

```gdscript
func test_hp_max_is_250() -> void:
	assert_eq(GameState.hp_max, 250)

func test_hp_starts_at_250_after_reset() -> void:
	GameState.hp = 1
	GameState.reset()
	assert_eq(GameState.hp, 250)
```

- [ ] **Step 1.2 — Confirm RED**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: failure on `test_hp_max_is_250` (currently 500).

- [ ] **Step 1.3 — Implement**

In `src/autoloads/GameState.gd`, change line:

```gdscript
var hp_max: int = 500
```
to:
```gdscript
var hp_max: int = 250
```

- [ ] **Step 1.4 — Confirm GREEN**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 1.5 — Commit**

```bash
git add src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "balance: player hp_max 500 -> 250"
```

---

## Task 2: Lifesteal resets to 0 after each combat

**Files:** `tests/unit/test_combat_system.gd`, `src/systems/CombatSystem.gd`

- [ ] **Step 2.1 — Write failing test**

Append to `tests/unit/test_combat_system.gd`:

```gdscript
func test_lifesteal_ratio_resets_after_combat() -> void:
	GameState.lifesteal_ratio = 0.4
	var enemy = Enemy.new()
	enemy.init("汲取者")
	combat._finish_combat(enemy)
	assert_eq(GameState.lifesteal_ratio, 0.0)
```

- [ ] **Step 2.2 — Confirm RED**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: failure on `test_lifesteal_ratio_resets_after_combat`.

- [ ] **Step 2.3 — Implement**

In `src/systems/CombatSystem.gd`, find `_finish_combat`:

```gdscript
func _finish_combat(enemy: Enemy = null) -> void:
	var resolved := enemy if enemy != null else _active_enemy
	if resolved == null:
		return
	stop()
	GameState.enemies_killed += 1
	EventBus.enemy_killed.emit(resolved)
```

Replace with:

```gdscript
func _finish_combat(enemy: Enemy = null) -> void:
	var resolved := enemy if enemy != null else _active_enemy
	if resolved == null:
		return
	stop()
	GameState.lifesteal_ratio = 0.0
	GameState.enemies_killed += 1
	EventBus.enemy_killed.emit(resolved)
```

- [ ] **Step 2.4 — Confirm GREEN**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 2.5 — Commit**

```bash
git add src/systems/CombatSystem.gd tests/unit/test_combat_system.gd
git commit -m "balance: reset lifesteal_ratio to 0 after each combat"
```

---

## Task 3: Shield cap at hp_max + shield decay 65% per loop

**Files:** `tests/unit/test_rule_engine.gd`, `src/systems/RuleEngine.gd`

- [ ] **Step 3.1 — Write failing tests**

Append to `tests/unit/test_rule_engine.gd`:

```gdscript
func test_shield_capped_at_hp_max() -> void:
	GameState.shield = GameState.hp_max - 10
	_make_rule("受击", 1.0, "护盾", 100.0)
	EventBus.player_hit.emit(5)
	assert_eq(GameState.shield, GameState.hp_max)

func test_shield_decays_65_percent_on_loop_completed() -> void:
	GameState.shield = 200
	EventBus.loop_completed.emit()
	assert_eq(GameState.shield, int(200 * 0.65))
```

- [ ] **Step 3.2 — Confirm RED**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: both new tests fail.

- [ ] **Step 3.3 — Implement shield cap**

In `src/systems/RuleEngine.gd`, find the `"护盾"` branch inside `_execute_effect`:

```gdscript
		"护盾":
			GameState.shield += int(final_value)
			EventBus.rule_fired.emit(slot_idx, "护盾", final_value)
```

Replace with:

```gdscript
		"护盾":
			GameState.shield = mini(GameState.shield + int(final_value), GameState.hp_max)
			EventBus.rule_fired.emit(slot_idx, "护盾", final_value)
```

- [ ] **Step 3.4 — Implement shield decay**

In `src/systems/RuleEngine.gd`, find `_on_loop_completed`:

```gdscript
func _on_loop_completed() -> void:
	_evaluate_player_triggers(["完成圈数"])
	var decay := ceili(float(GameState.current_phase) / 2.0)
	GameState.slow_stacks = max(0, GameState.slow_stacks - decay)
```

Replace with:

```gdscript
func _on_loop_completed() -> void:
	_evaluate_player_triggers(["完成圈数"])
	var decay := ceili(float(GameState.current_phase) / 2.0)
	GameState.slow_stacks = max(0, GameState.slow_stacks - decay)
	GameState.shield = int(GameState.shield * 0.65)
```

- [ ] **Step 3.5 — Confirm GREEN**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 3.6 — Commit**

```bash
git add src/systems/RuleEngine.gd tests/unit/test_rule_engine.gd
git commit -m "balance: shield capped at hp_max, decays x0.65 per loop"
```

---

## Task 4: Remove debug enemy spawn rotation — use phase weights

**Files:** `src/systems/GameLoop.gd`

The static helper `_pick_enemy_id(phase, current_phase)` already exists and is already tested in `tests/unit/test_game_loop.gd`. No new test needed — just wire `spawn_enemies` to use it.

- [ ] **Step 4.1 — Remove `_debug_enemy_index` variable**

In `src/systems/GameLoop.gd`, remove the line:

```gdscript
var _debug_enemy_index: int = 0
```

- [ ] **Step 4.2 — Replace DEBUG rotation in `spawn_enemies`**

Find this block in `spawn_enemies`:

```gdscript
	const DEBUG_ENEMIES = ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]
	for idx in indices:
		var enemy_id = DEBUG_ENEMIES[_debug_enemy_index % DEBUG_ENEMIES.size()]
		_debug_enemy_index += 1
		var enemy: Enemy = _enemy_scene.instantiate()
```

Replace with:

```gdscript
	for idx in indices:
		var enemy_id = _pick_enemy_id(phase_data, spawn_phase)
		var enemy: Enemy = _enemy_scene.instantiate()
```

- [ ] **Step 4.3 — Confirm GREEN**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass (existing `test_pick_enemy_id_*` tests verify the utility).

- [ ] **Step 4.4 — Commit**

```bash
git add src/systems/GameLoop.gd
git commit -m "fix: replace debug enemy rotation with phase spawn_weights"
```

---

## Task 5: Data — game_config + enemy base stats + gold

**Files:** `data/game_config.tres`, `data/enemies/enemy_*.tres`

No tests needed — these are pure resource data values.

- [ ] **Step 5.1 — Fix verdict_trigger_phase**

In `data/game_config.tres`, change:

```
verdict_trigger_phase = 2
```
to:
```
verdict_trigger_phase = 10
```

- [ ] **Step 5.2 — Update 汲取者**

In `data/enemies/enemy_汲取者.tres`, change:

```
dmg_base = 2
```
to:
```
dmg_base = 5
```

Change:
```
gold_min = 5
gold_max = 15
```
to:
```
gold_min = 12
gold_max = 28
```

Change:
```
attack_interval = 1.2
```
to:
```
attack_interval = 1.0
```

- [ ] **Step 5.3 — Update 守卫者**

In `data/enemies/enemy_守卫者.tres`, change:

```
dmg_base = 3
```
to:
```
dmg_base = 7
```

Change:
```
gold_min = 5
gold_max = 15
```
to:
```
gold_min = 12
gold_max = 28
```

Change:
```
attack_interval = 1.8
```
to:
```
attack_interval = 1.4
```

- [ ] **Step 5.4 — Update 急袭者**

In `data/enemies/enemy_急袭者.tres`, change:

```
dmg_base = 2
```
to:
```
dmg_base = 6
```

Change:
```
gold_min = 20
gold_max = 50
```
to:
```
gold_min = 28
gold_max = 65
```

Change:
```
attack_interval = 0.8
```
to:
```
attack_interval = 0.7
```

- [ ] **Step 5.5 — Update 复制者**

In `data/enemies/enemy_复制者.tres`, change:

```
dmg_base = 2
```
to:
```
dmg_base = 4
```

Change:
```
attack_interval = 1.0
```
to:
```
attack_interval = 0.9
```

- [ ] **Step 5.6 — Confirm tests still pass**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5.7 — Commit**

```bash
git add data/game_config.tres data/enemies/
git commit -m "balance: enemy base dmg/speed up, gold up, verdict phase restored to 10"
```

---

## Task 6: Data — Tier 1 drop preset component values

**File:** `data/drop_presets/drop_tier_01.tres`

- [ ] **Step 6.1 — Update 治愈 effect range**

Change:
```
"治愈": {"trigger": Vector2(2, 3), "effect": Vector2(5, 10)},
```
to:
```
"治愈": {"trigger": Vector2(2, 3), "effect": Vector2(15, 25)},
```

- [ ] **Step 6.2 — Update 反射 effect range**

Change:
```
"反射": {"trigger": Vector2(2, 3), "effect": Vector2(0.2, 0.3)},
```
to:
```
"反射": {"trigger": Vector2(2, 3), "effect": Vector2(0.3, 0.45)},
```

- [ ] **Step 6.3 — Update 护盾 effect range**

Change:
```
"护盾": {"effect": Vector2(20, 40)},
```
to:
```
"护盾": {"effect": Vector2(40, 70)},
```

- [ ] **Step 6.4 — Update 减伤 effect range**

Change:
```
"减伤": {"effect": Vector2(1, 2)},
```
to:
```
"减伤": {"effect": Vector2(2, 3)},
```

- [ ] **Step 6.5 — Update 吸血 effect range**

Change:
```
"吸血": {"effect": Vector2(0.05, 0.1)}
```
to:
```
"吸血": {"effect": Vector2(0.1, 0.2)}
```

- [ ] **Step 6.6 — Confirm tests still pass**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 6.7 — Commit**

```bash
git add data/drop_presets/drop_tier_01.tres
git commit -m "balance: tier 1 component values boosted (shield 40-70, heal 15-25, etc.)"
```

---

## Task 7: Data — Phase pressure windows + component_count_bonus

**Files:** `data/phases/phase_1.tres` through `data/phases/phase_10.tres`

New values summary:

| Phase | world_pressure_window | component_count_bonus |
|-------|-----------------------|-----------------------|
| 1 | 3 (add; was default 10) | 0 (default, no change) |
| 2 | 4 (was 9) | 0 (default, no change) |
| 3 | 4 (was 8) | 1 (add) |
| 4 | 4 (was 7) | 1 (add) |
| 5 | 4 (was 6) | 2 (add) |
| 6 | 3 (was 5) | 2 (add) |
| 7 | 4 (was 4, no change) | 3 (add) |
| 8 | 4 (was 3) | 3 (add) |
| 9 | 4 (was 2) | 4 (add) |
| 10 | 5 (was 1) | 4 (add) |

- [ ] **Step 7.1 — phase_1.tres** — add `world_pressure_window = 3` after `altar_requirement = 2`:

```
altar_requirement = 2
world_pressure_window = 3
```

- [ ] **Step 7.2 — phase_2.tres** — change `world_pressure_window = 9` → `world_pressure_window = 4`:

```
world_pressure_window = 4
```

- [ ] **Step 7.3 — phase_3.tres** — change window 8→4, add bonus=1:

```
world_pressure_window = 4
```

After `world_pressure_window` line add:

```
component_count_bonus = 1
```

- [ ] **Step 7.4 — phase_4.tres** — change window 7→4, add bonus=1:

```
world_pressure_window = 4
```

Add:

```
component_count_bonus = 1
```

- [ ] **Step 7.5 — phase_5.tres** — change window 6→4, add bonus=2:

```
world_pressure_window = 4
```

Add:

```
component_count_bonus = 2
```

- [ ] **Step 7.6 — phase_6.tres** — change window 5→3, add bonus=2:

```
world_pressure_window = 3
```

Add:

```
component_count_bonus = 2
```

- [ ] **Step 7.7 — phase_7.tres** — window stays 4, add bonus=3:

Add after `world_pressure_window = 4`:

```
component_count_bonus = 3
```

- [ ] **Step 7.8 — phase_8.tres** — change window 3→4, add bonus=3:

```
world_pressure_window = 4
```

Add:

```
component_count_bonus = 3
```

- [ ] **Step 7.9 — phase_9.tres** — change window 2→4, add bonus=4:

```
world_pressure_window = 4
```

Add:

```
component_count_bonus = 4
```

- [ ] **Step 7.10 — phase_10.tres** — change window 1→5, add bonus=4:

```
world_pressure_window = 5
```

Add:

```
component_count_bonus = 4
```

- [ ] **Step 7.11 — Confirm tests still pass**

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 7.12 — Commit**

```bash
git add data/phases/
git commit -m "balance: tighten early pressure windows (3-4 loops/phase), add component_count_bonus per phase"
```

---

## Final Verification

- [ ] Run full test suite one more time:

```powershell
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

All tests green.

- [ ] Update `docs/superpowers/specs/2026-06-11-balance-proposals.md` status to `Implemented (B variant)`.
