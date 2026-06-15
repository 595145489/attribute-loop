# Shop Service Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `规则复制` from the auction pool and replace it with 6 new permanent stat/slot upgrade services.

**Architecture:** Data flows outward from GameConfig (static config values) → GameState (run-time accumulated bonuses) → AuctionManager (service execution) → CombatSystem / ServiceBar (apply bonuses). No new files; all changes are additive to existing files.

**Tech Stack:** GDScript 4, GUT test framework, Godot 4 autoloads.

---

## File Map

| File | What changes |
|------|-------------|
| `src/resources/GameConfig.gd` | Add 5 new `@export` fields for per-purchase deltas and service-bar cap |
| `src/resources/PlayerData.gd` | Fix `hp_base` default: 100 → 250 (restores design value, fixes failing tests) |
| `src/autoloads/GameState.gd` | Add `dmg_bonus`, `attack_interval_bonus`, `service_bar_max`; fix `reset()` to restore `hp_max` and new fields |
| `src/systems/AuctionManager.gd` | Remove `RULE_COPY`; add 6 new `ServiceType` values; update names/descriptions, `all_types`, `execute_service`, pool cap logic, phantom prefs |
| `src/systems/CombatSystem.gd` | Player attack uses `+ GameState.dmg_bonus`; `start()` subtracts `attack_interval_bonus` from timer |
| `src/ui/ServiceBar.gd` | `MAX_SLOTS` reads `GameState.service_bar_max` instead of config cap |
| `tests/unit/test_game_state.gd` | Add 3 new reset tests; existing hp_max tests will pass after fix |
| `tests/unit/test_auction_manager.gd` | Fix 1 broken RULE_COPY ref; add tests for 6 new services + pool cap |
| `tests/unit/test_combat_system.gd` | Add 2 tests for dmg_bonus and attack_interval_bonus |

---

## Task 1: GameConfig — add 5 new fields

**Files:**
- Modify: `src/resources/GameConfig.gd`

- [ ] **Step 1: Add fields to GameConfig.gd**

Open `src/resources/GameConfig.gd`. After the last `auction_*` line (`auction_phantom_b_allin_ratio`), add:

```gdscript
@export var auction_dmg_per_purchase: int = 1
@export var auction_hp_per_purchase: int = 15
@export var auction_speed_delta: float = 0.05
@export var auction_amplify_per_purchase: int = 1
@export var auction_service_bar_max_purchases: int = 3
```

- [ ] **Step 2: Commit**

```bash
git add src/resources/GameConfig.gd
git commit -m "feat: add auction stat/slot config fields to GameConfig"
```

---

## Task 2: PlayerData + GameState — fix hp_max, add new fields

**Files:**
- Modify: `src/resources/PlayerData.gd`
- Modify: `src/autoloads/GameState.gd`
- Modify: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Write failing tests**

In `tests/unit/test_game_state.gd`, append:

```gdscript
func test_dmg_bonus_zero_after_reset() -> void:
	GameState.dmg_bonus = 5
	GameState.reset()
	assert_eq(GameState.dmg_bonus, 0)

func test_attack_interval_bonus_zero_after_reset() -> void:
	GameState.attack_interval_bonus = 0.3
	GameState.reset()
	assert_almost_eq(GameState.attack_interval_bonus, 0.0, 0.001)

func test_service_bar_max_restored_after_reset() -> void:
	GameState.service_bar_max = 99
	GameState.reset()
	assert_eq(GameState.service_bar_max, DataTables.config.auction_service_bar_cap)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 3 new tests fail with `Invalid get index 'dmg_bonus'` (field not yet defined).
Also `test_hp_max_is_250` and `test_hp_starts_at_250_after_reset` currently fail (hp_max = 10000 debug value).

- [ ] **Step 3: Fix PlayerData.gd**

In `src/resources/PlayerData.gd`, change line 4:

```gdscript
# before
@export var hp_base: int = 100
# after
@export var hp_base: int = 250
```

- [ ] **Step 4: Update GameState.gd — declarations**

In `src/autoloads/GameState.gd`, change line 4:

```gdscript
# before
var hp_max: int = 10000
# after
var hp_max: int = 250
```

Then after `var service_bar: Array[int] = []` (around line 37), add three new fields:

```gdscript
var dmg_bonus: int = 0
var attack_interval_bonus: float = 0.0
var service_bar_max: int = 5
```

- [ ] **Step 5: Update GameState.reset() — restore hp_max and new fields**

In `src/autoloads/GameState.gd`, inside `reset()`, add these lines immediately after the existing `amplify_max_stacks = ...` line:

```gdscript
if DataTables.player != null:
    hp_max = DataTables.player.hp_base
hp = hp_max
dmg_bonus = 0
attack_interval_bonus = 0.0
service_bar_max = DataTables.config.auction_service_bar_cap if DataTables.config != null else 5
```

Also change the existing `hp = hp_max` at the very start of reset() — it now runs before DataTables is checked, so replace that first line of reset() with:

```gdscript
# remove the existing "hp = hp_max" at the top of reset()
# the new block above handles it after hp_max is set
```

So the full start of reset() becomes:

```gdscript
func reset() -> void:
	loops_completed = 0
	enemies_killed = 0
	current_phase = 1
	is_paused = false
	_panel_pause_count = 0
	speed_multiplier = 1.0
	pending_reflect_ratio = 0.0
	shield = 0
	slow_stacks = 0
	lifesteal_ratio = 0.0
	amplify_stacks = 0
	amplify_max_stacks = DataTables.config.amplify_max_stacks_base if DataTables.config != null else 1
	if DataTables.player != null:
		hp_max = DataTables.player.hp_base
	hp = hp_max
	dmg_bonus = 0
	attack_interval_bonus = 0.0
	service_bar_max = DataTables.config.auction_service_bar_cap if DataTables.config != null else 5
	inventory = []
	rule_slots = []
	# ... rest unchanged
```

- [ ] **Step 6: Run tests — verify they pass**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all previously passing tests still pass, plus 3 new tests pass, plus `test_hp_max_is_250` and `test_hp_starts_at_250_after_reset` now pass.

- [ ] **Step 7: Commit**

```bash
git add src/resources/PlayerData.gd src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat: add dmg_bonus, attack_interval_bonus, service_bar_max to GameState; fix hp_max reset"
```

---

## Task 3: AuctionManager — enum + remove RULE_COPY

**Files:**
- Modify: `src/systems/AuctionManager.gd`
- Modify: `tests/unit/test_auction_manager.gd`

- [ ] **Step 1: Fix broken test that references RULE_COPY**

In `tests/unit/test_auction_manager.gd`, find `test_settle_bids_preserved_in_result` and replace both `RULE_COPY` references with `COMP_REWRITE`:

```gdscript
func test_settle_bids_preserved_in_result() -> void:
	var services: Array[int] = [AuctionManager.ServiceType.COMP_REWRITE]
	var results = AuctionManager.settle(services, {AuctionManager.ServiceType.COMP_REWRITE: 80}, {AuctionManager.ServiceType.COMP_REWRITE: 120}, {})
	assert_eq(results[0]["bids"]["player"], 80)
	assert_eq(results[0]["bids"]["phantom_a"], 120)
```

- [ ] **Step 2: Write tests for new enum values**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_new_service_types_have_names() -> void:
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_DMG))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_HP))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_SPEED))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.STAT_AMPLIFY))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.SLOT_RULE))
	assert_true(AuctionManager.SERVICE_NAMES.has(AuctionManager.ServiceType.SLOT_SERVICE))

func test_pool_never_contains_rule_copy_int() -> void:
	var pool = AuctionManager.generate_pool(["汲取者", "守卫者", "急袭者"], [])
	assert_false(pool.has(0))
```

- [ ] **Step 3: Run tests to verify the new ones fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: `test_new_service_types_have_names` fails — `STAT_DMG` not found.

- [ ] **Step 4: Update AuctionManager enum**

In `src/systems/AuctionManager.gd`, replace the full `ServiceType` enum:

```gdscript
enum ServiceType {
	COMP_REWRITE   = 1,
	COMP_MERGE     = 2,
	ENEMY_PARDON   = 3,
	DELETE_PARDON  = 4,
	PRESSURE_DELAY = 5,
	STAT_DMG       = 6,
	STAT_HP        = 7,
	STAT_SPEED     = 8,
	STAT_AMPLIFY   = 9,
	SLOT_RULE      = 10,
	SLOT_SERVICE   = 11,
}
```

- [ ] **Step 5: Update SERVICE_NAMES and SERVICE_DESCRIPTIONS**

Replace the two const Dictionaries (remove RULE_COPY entries, add 6 new entries):

```gdscript
const SERVICE_NAMES: Dictionary = {
	ServiceType.COMP_REWRITE:   "词条改写",
	ServiceType.COMP_MERGE:     "词条融合",
	ServiceType.ENEMY_PARDON:   "敌人赦免",
	ServiceType.DELETE_PARDON:  "删除特赦",
	ServiceType.PRESSURE_DELAY: "压力延缓",
	ServiceType.STAT_DMG:       "战意磨砺",
	ServiceType.STAT_HP:        "筋骨强化",
	ServiceType.STAT_SPEED:     "迅捷折纸",
	ServiceType.STAT_AMPLIFY:   "强化潜能",
	ServiceType.SLOT_RULE:      "装备槽扩容",
	ServiceType.SLOT_SERVICE:   "服务栏扩容",
}

const SERVICE_DESCRIPTIONS: Dictionary = {
	ServiceType.COMP_REWRITE:   "修改某个词条的N值(1-3)或基础数值(最多+50%)",
	ServiceType.COMP_MERGE:     "将两个同类词条合并为一个（结果 = 总和×0.8）",
	ServiceType.ENEMY_PARDON:   "下3只指定类型敌人不战斗，自动掉落组件",
	ServiceType.DELETE_PARDON:  "下次删除词条0费用且不计入全局计数",
	ServiceType.PRESSURE_DELAY: "世界压力计时 -1 圈",
	ServiceType.STAT_DMG:       "永久 基础攻击 +1",
	ServiceType.STAT_HP:        "永久 最大HP +15，立即回复等量血量",
	ServiceType.STAT_SPEED:     "永久 攻击间隔 -0.05s（最低0.2s）",
	ServiceType.STAT_AMPLIFY:   "永久 强化层上限 +1",
	ServiceType.SLOT_RULE:      "永久 装备规则槽 +1",
	ServiceType.SLOT_SERVICE:   "永久 服务栏容量 +1",
}
```

- [ ] **Step 6: Update `all_types` in generate_pool**

In `generate_pool`, replace the `all_types` array:

```gdscript
var all_types: Array[int] = [
	ServiceType.COMP_REWRITE, ServiceType.COMP_MERGE,
	ServiceType.ENEMY_PARDON, ServiceType.DELETE_PARDON, ServiceType.PRESSURE_DELAY,
	ServiceType.STAT_DMG, ServiceType.STAT_HP, ServiceType.STAT_SPEED, ServiceType.STAT_AMPLIFY,
	ServiceType.SLOT_RULE, ServiceType.SLOT_SERVICE,
]
```

- [ ] **Step 7: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_auction_manager.gd
git commit -m "feat: replace RULE_COPY with 6 new service types in AuctionManager enum"
```

---

## Task 4: AuctionManager — execute_service for 6 new services

**Files:**
- Modify: `src/systems/AuctionManager.gd`
- Modify: `tests/unit/test_auction_manager.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_execute_stat_dmg_increases_dmg_bonus() -> void:
	var am := AuctionManager.new()
	GameState.dmg_bonus = 0
	am.execute_service(AuctionManager.ServiceType.STAT_DMG, {})
	assert_eq(GameState.dmg_bonus, DataTables.config.auction_dmg_per_purchase)

func test_execute_stat_dmg_accumulates() -> void:
	var am := AuctionManager.new()
	GameState.dmg_bonus = 0
	am.execute_service(AuctionManager.ServiceType.STAT_DMG, {})
	am.execute_service(AuctionManager.ServiceType.STAT_DMG, {})
	assert_eq(GameState.dmg_bonus, DataTables.config.auction_dmg_per_purchase * 2)

func test_execute_stat_hp_increases_hp_max() -> void:
	var am := AuctionManager.new()
	var hp_before := GameState.hp_max
	am.execute_service(AuctionManager.ServiceType.STAT_HP, {})
	assert_eq(GameState.hp_max, hp_before + DataTables.config.auction_hp_per_purchase)

func test_execute_stat_hp_heals_by_delta() -> void:
	var am := AuctionManager.new()
	GameState.hp = GameState.hp_max
	am.execute_service(AuctionManager.ServiceType.STAT_HP, {})
	assert_eq(GameState.hp, GameState.hp_max)

func test_execute_stat_speed_increases_interval_bonus() -> void:
	var am := AuctionManager.new()
	GameState.attack_interval_bonus = 0.0
	am.execute_service(AuctionManager.ServiceType.STAT_SPEED, {})
	assert_almost_eq(GameState.attack_interval_bonus, DataTables.config.auction_speed_delta, 0.001)

func test_execute_stat_amplify_increases_max_stacks() -> void:
	var am := AuctionManager.new()
	var before := GameState.amplify_max_stacks
	am.execute_service(AuctionManager.ServiceType.STAT_AMPLIFY, {})
	assert_eq(GameState.amplify_max_stacks, before + DataTables.config.auction_amplify_per_purchase)

func test_execute_slot_rule_adds_rule_slot() -> void:
	var am := AuctionManager.new()
	var before := GameState.rule_slots.size()
	am.execute_service(AuctionManager.ServiceType.SLOT_RULE, {})
	assert_eq(GameState.rule_slots.size(), before + 1)

func test_execute_slot_rule_new_slot_is_empty() -> void:
	var am := AuctionManager.new()
	am.execute_service(AuctionManager.ServiceType.SLOT_RULE, {})
	var last = GameState.rule_slots[-1]
	assert_null(last["trigger"])
	assert_null(last["effect"])

func test_execute_slot_service_increases_service_bar_max() -> void:
	var am := AuctionManager.new()
	var before := GameState.service_bar_max
	am.execute_service(AuctionManager.ServiceType.SLOT_SERVICE, {})
	assert_eq(GameState.service_bar_max, before + 1)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 9 new tests fail — new match arms not yet in execute_service.

- [ ] **Step 3: Add new match arms to execute_service**

In `src/systems/AuctionManager.gd`, inside `execute_service`, add these arms before the closing `EventBus.service_bar_changed.emit()` call:

```gdscript
ServiceType.STAT_DMG:
    GameState.dmg_bonus += DataTables.config.auction_dmg_per_purchase
ServiceType.STAT_HP:
    var delta := DataTables.config.auction_hp_per_purchase
    GameState.hp_max += delta
    GameState.hp = mini(GameState.hp + delta, GameState.hp_max)
ServiceType.STAT_SPEED:
    GameState.attack_interval_bonus += DataTables.config.auction_speed_delta
ServiceType.STAT_AMPLIFY:
    GameState.amplify_max_stacks += DataTables.config.auction_amplify_per_purchase
ServiceType.SLOT_RULE:
    GameState.rule_slots.append({"trigger": null, "effect": null})
ServiceType.SLOT_SERVICE:
    GameState.service_bar_max += 1
```

- [ ] **Step 4: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_auction_manager.gd
git commit -m "feat: implement execute_service for 6 new stat/slot services"
```

---

## Task 5: AuctionManager — pool cap + phantom prefs

**Files:**
- Modify: `src/systems/AuctionManager.gd`
- Modify: `tests/unit/test_auction_manager.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_pool_excludes_slot_rule_when_maxed() -> void:
	# Fill rule_slots to max
	while GameState.rule_slots.size() < DataTables.config.rule_slot_count_max:
		GameState.rule_slots.append({"trigger": null, "effect": null})
	var pool = AuctionManager.generate_pool([], [])
	assert_false(pool.has(AuctionManager.ServiceType.SLOT_RULE))

func test_pool_includes_slot_rule_when_not_maxed() -> void:
	# Start with 2 slots, max is 5 — not maxed
	assert_eq(GameState.rule_slots.size(), 2)
	# Run many iterations; SLOT_RULE must eventually appear
	var found := false
	for i in 200:
		var pool = AuctionManager.generate_pool([], [])
		if pool.has(AuctionManager.ServiceType.SLOT_RULE):
			found = true
			break
	assert_true(found)

func test_pool_excludes_slot_service_when_maxed() -> void:
	var cap: int = DataTables.config.auction_service_bar_cap
	var max_extra: int = DataTables.config.auction_service_bar_max_purchases
	GameState.service_bar_max = cap + max_extra
	var pool = AuctionManager.generate_pool([], [])
	assert_false(pool.has(AuctionManager.ServiceType.SLOT_SERVICE))

func test_pool_includes_slot_service_when_not_maxed() -> void:
	GameState.service_bar_max = DataTables.config.auction_service_bar_cap  # not maxed
	var found := false
	for i in 200:
		var pool = AuctionManager.generate_pool([], [])
		if pool.has(AuctionManager.ServiceType.SLOT_SERVICE):
			found = true
			break
	assert_true(found)

func test_phantom_a_prefers_stat_dmg() -> void:
	var p := AuctionManager.PhantomBuyer.new()
	p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE,
		[AuctionManager.ServiceType.STAT_DMG, AuctionManager.ServiceType.STAT_HP])
	assert_eq(p.interest(AuctionManager.ServiceType.STAT_DMG), 3)
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: cap tests fail — generate_pool has no cap filter yet.

- [ ] **Step 3: Add cap filter to generate_pool**

In `src/systems/AuctionManager.gd`, inside `generate_pool`, add a helper and filter:

Replace this block in generate_pool:
```gdscript
var all_types: Array[int] = [...]
```

With:
```gdscript
var all_types: Array[int] = [
	ServiceType.COMP_REWRITE, ServiceType.COMP_MERGE,
	ServiceType.ENEMY_PARDON, ServiceType.DELETE_PARDON, ServiceType.PRESSURE_DELAY,
	ServiceType.STAT_DMG, ServiceType.STAT_HP, ServiceType.STAT_SPEED, ServiceType.STAT_AMPLIFY,
	ServiceType.SLOT_RULE, ServiceType.SLOT_SERVICE,
]
var rule_max: int = DataTables.config.rule_slot_count_max
var bar_cap: int = DataTables.config.auction_service_bar_cap
var bar_max_extra: int = DataTables.config.auction_service_bar_max_purchases
var cur_rule_slots: int = GameState.rule_slots.size()
var cur_bar_max: int = GameState.service_bar_max
all_types = all_types.filter(func(t: int) -> bool:
	if t == ServiceType.SLOT_RULE:
		return cur_rule_slots < rule_max
	if t == ServiceType.SLOT_SERVICE:
		return cur_bar_max < bar_cap + bar_max_extra
	return true
)
```

- [ ] **Step 4: Update phantom_a preferences in _ready()**

In `src/systems/AuctionManager.gd`, inside `_ready()`, change:

```gdscript
# before
phantom_a.init(PhantomBuyer.Personality.AGGRESSIVE, [ServiceType.RULE_COPY, ServiceType.COMP_MERGE])
# after
phantom_a.init(PhantomBuyer.Personality.AGGRESSIVE, [ServiceType.STAT_DMG, ServiceType.STAT_HP])
```

- [ ] **Step 5: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_auction_manager.gd
git commit -m "feat: cap SLOT_RULE and SLOT_SERVICE pool appearance; update phantom_a prefs"
```

---

## Task 6: CombatSystem — apply dmg_bonus and attack_interval_bonus

**Files:**
- Modify: `src/systems/CombatSystem.gd`
- Modify: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Write failing tests**

Append to `tests/unit/test_combat_system.gd`:

```gdscript
func test_player_attack_applies_dmg_bonus() -> void:
	GameState.dmg_bonus = 3
	var enemy = Enemy.new()
	enemy.init("汲取者")
	var hp_before = enemy.hp
	combat._apply_player_attack(enemy)
	assert_eq(enemy.hp, hp_before - (DataTables.player.dmg_base + 3))

func test_combat_start_uses_attack_interval_bonus() -> void:
	GameState.attack_interval_bonus = 0.2
	var enemy = Enemy.new()
	enemy.init("汲取者")
	combat.start(enemy)
	var expected := maxf(DataTables.player.attack_interval - 0.2, 0.2)
	assert_almost_eq(combat._player_timer.wait_time, expected, 0.001)
	combat.stop()
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: 2 new tests fail — dmg_bonus not applied, interval not adjusted.

- [ ] **Step 3: Update _apply_player_attack**

In `src/systems/CombatSystem.gd`, change line in `_apply_player_attack`:

```gdscript
# before
var dmg := DataTables.player.dmg_base
# after
var dmg := DataTables.player.dmg_base + GameState.dmg_bonus
```

- [ ] **Step 4: Update start() — apply attack_interval_bonus**

In `src/systems/CombatSystem.gd`, change the player timer line in `start()`:

```gdscript
# before
_player_timer.wait_time = DataTables.player.attack_interval
# after
_player_timer.wait_time = maxf(DataTables.player.attack_interval - GameState.attack_interval_bonus, 0.2)
```

- [ ] **Step 5: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass, including the pre-existing `test_player_damage_uses_player_dmg_base` (still passes because `dmg_bonus = 0` in `before_each`).

- [ ] **Step 6: Commit**

```bash
git add src/systems/CombatSystem.gd tests/unit/test_combat_system.gd
git commit -m "feat: CombatSystem applies dmg_bonus and attack_interval_bonus from GameState"
```

---

## Task 7: ServiceBar — use GameState.service_bar_max

**Files:**
- Modify: `src/ui/ServiceBar.gd`
- Modify: `src/systems/AuctionManager.gd` (one-line fix)

- [ ] **Step 1: Update ServiceBar.MAX_SLOTS**

In `src/ui/ServiceBar.gd`, change the `MAX_SLOTS` property:

```gdscript
# before
var MAX_SLOTS: int:
	get: return DataTables.config.auction_service_bar_cap
# after
var MAX_SLOTS: int:
	get: return GameState.service_bar_max
```

- [ ] **Step 2: Update AuctionManager._award_service_to_player**

In `src/systems/AuctionManager.gd`, inside `_award_service_to_player`:

```gdscript
# before
if GameState.service_bar.size() < 5:
# after
if GameState.service_bar.size() < GameState.service_bar_max:
```

- [ ] **Step 3: Run full test suite**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 4: Commit**

```bash
git add src/ui/ServiceBar.gd src/systems/AuctionManager.gd
git commit -m "feat: ServiceBar and AuctionManager use dynamic service_bar_max"
```

---

## Final verification

- [ ] Run full test suite one last time and confirm pass count matches or exceeds the pre-change count

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] Confirm no `RULE_COPY` references remain in source

```bash
grep -rn "RULE_COPY" S:/attribute-loop/src S:/attribute-loop/tests
```

Expected: no output.
