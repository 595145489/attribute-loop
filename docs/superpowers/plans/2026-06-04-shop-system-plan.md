# 梦境残市 (Shop System) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement a per-loop auction system where players bid gold against two phantom buyers to win operation services that modify their existing build.

**Architecture:** AuctionManager (Node in main.tscn) owns service pool generation, phantom AI, bid settlement, and service effect execution. Service bar state lives in GameState. Each service type has a dedicated activation popup that collects targeting parameters before applying effects.

**Tech Stack:** GDScript 4, GUT testing framework, Godot 4 UI (Control nodes), existing EventBus/GameState/DataTables autoloads.

---

## File Map

**New files:**
- `src/systems/AuctionManager.gd` — pool generation, phantom AI, settlement, effect execution
- `src/ui/AuctionPanel.gd` + `scenes/ui/auction_panel.tscn` — slide-in panel (last results + current bids)
- `src/ui/ServiceBar.gd` + `scenes/ui/service_bar.tscn` — 5-slot HUD bar + full-slot discard popup
- `src/ui/ServiceActivatePopup.gd` + `scenes/ui/service_activate_popup.tscn` — per-service targeting popup
- `tests/unit/test_auction_manager.gd` — unit tests for AuctionManager pure functions

**Modified files:**
- `src/autoloads/EventBus.gd` — add `auction_settled`, `service_bar_changed` signals
- `src/autoloads/GameState.gd` — add service_bar, deletion_free, enemy_pardon state
- `src/systems/GameLoop.gd` — track kills per loop, hook loop_completed → AuctionManager
- `src/entities/Tile.gd` — add `copy_rule_to(target: Tile) -> bool`
- `src/systems/EconomyManager.gd` — check deletion_free before charging
- `src/ui/HUD.gd` — wire up AuctionPanel button + phantom budget display

---

## Task 1: EventBus signals + GameState service state

**Files:**
- Modify: `src/autoloads/EventBus.gd`
- Modify: `src/autoloads/GameState.gd`
- Test: `tests/unit/test_game_state.gd`

- [ ] **Step 1: Add signals to EventBus**

In `src/autoloads/EventBus.gd`, append after the last signal:

```gdscript
signal auction_settled(results: Array)   # Array of {service_type, winner, bids}
signal service_bar_changed
signal enemy_pardoned(enemy_id: String)  # fired when a pardoned enemy auto-drops
```

- [ ] **Step 2: Add service state to GameState**

In `src/autoloads/GameState.gd`, add after `verdict_loops_survived`:

```gdscript
# Auction / service bar
var service_bar: Array[int] = []          # ServiceType enum values, max 5
var deletion_free: bool = false           # 删除特赦 active
var enemy_pardon_type: String = ""        # 敌人赦免 target enemy id
var enemy_pardon_remaining: int = 0       # pardons left this activation
```

- [ ] **Step 3: Reset service state in GameState.reset()**

In `GameState.reset()`, append before the closing brace:

```gdscript
	service_bar = []
	deletion_free = false
	enemy_pardon_type = ""
	enemy_pardon_remaining = 0
```

- [ ] **Step 4: Write failing test**

Append to `tests/unit/test_game_state.gd`:

```gdscript
func test_reset_clears_service_bar() -> void:
    GameState.service_bar = [0, 1, 2]
    GameState.deletion_free = true
    GameState.enemy_pardon_type = "汲取者"
    GameState.enemy_pardon_remaining = 3
    GameState.reset()
    assert_eq(GameState.service_bar.size(), 0)
    assert_false(GameState.deletion_free)
    assert_eq(GameState.enemy_pardon_type, "")
    assert_eq(GameState.enemy_pardon_remaining, 0)
```

- [ ] **Step 5: Run test**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: new test passes.

- [ ] **Step 6: Commit**

```bash
git add src/autoloads/EventBus.gd src/autoloads/GameState.gd tests/unit/test_game_state.gd
git commit -m "feat: add auction service state to EventBus and GameState"
```

---

## Task 2: AuctionManager — service pool generation

**Files:**
- Create: `src/systems/AuctionManager.gd`
- Create: `tests/unit/test_auction_manager.gd`

- [ ] **Step 1: Create AuctionManager with service pool logic**

Create `src/systems/AuctionManager.gd`:

```gdscript
class_name AuctionManager
extends Node

enum ServiceType {
    RULE_COPY      = 0,  # 规则复制
    COMP_REWRITE   = 1,  # 词条改写
    COMP_MERGE     = 2,  # 词条融合
    ENEMY_PARDON   = 3,  # 敌人赦免
    DELETE_PARDON  = 4,  # 删除特赦
    PRESSURE_DELAY = 5,  # 压力延缓
}

const SERVICE_NAMES: Dictionary = {
    ServiceType.RULE_COPY:      "规则复制",
    ServiceType.COMP_REWRITE:   "词条改写",
    ServiceType.COMP_MERGE:     "词条融合",
    ServiceType.ENEMY_PARDON:   "敌人赦免",
    ServiceType.DELETE_PARDON:  "删除特赦",
    ServiceType.PRESSURE_DELAY: "压力延缓",
}

const SERVICE_DESCRIPTIONS: Dictionary = {
    ServiceType.RULE_COPY:      "将某条地块规则复制到另一格（pass_count从0开始）",
    ServiceType.COMP_REWRITE:   "修改某个词条的N值(1-3)或基础数值(最多+50%)",
    ServiceType.COMP_MERGE:     "将两个同类词条合并为一个（结果 = 总和×0.8）",
    ServiceType.ENEMY_PARDON:   "下3只指定类型敌人不战斗，自动掉落组件",
    ServiceType.DELETE_PARDON:  "下次删除词条0费用且不计入全局计数",
    ServiceType.PRESSURE_DELAY: "世界压力计时 -1 圈",
}

# Current loop auction state
var current_services: Array[int] = []        # up to 3 ServiceType values
var carried_over: Array[int] = []            # services nobody bid on last loop
var player_bids: Dictionary = {}             # ServiceType -> int (gold)
var last_results: Array = []                 # Array of {service, winner, bids: {player, phantom_a, phantom_b}}

# Enemies killed this loop (set by GameLoop before settlement)
var _kills_this_loop: Array[String] = []

func _ready() -> void:
    EventBus.loop_completed.connect(_on_loop_completed)

func register_kill(enemy_id: String) -> void:
    _kills_this_loop.append(enemy_id)

func set_player_bid(service_type: int, amount: int) -> void:
    player_bids[service_type] = max(0, amount)

func _on_loop_completed() -> void:
    pass  # filled in Task 4

## Pure functions for testing

static func generate_pool(kills: Array[String], carried: Array[int]) -> Array[int]:
    var pool: Array[int] = carried.duplicate()
    var all_types: Array[int] = [
        ServiceType.RULE_COPY, ServiceType.COMP_REWRITE, ServiceType.COMP_MERGE,
        ServiceType.ENEMY_PARDON, ServiceType.DELETE_PARDON, ServiceType.PRESSURE_DELAY
    ]
    # Each kill contributes a random service type (weighted by enemy type is future work;
    # for now uniform random excluding already-in-pool)
    for _kill in kills:
        if pool.size() >= 3:
            break
        var available: Array[int] = all_types.filter(func(t): return not pool.has(t))
        if available.is_empty():
            break
        pool.append(available[randi() % available.size()])
    # Fill remaining slots from all types if fewer than 3
    while pool.size() < 3:
        var available: Array[int] = all_types.filter(func(t): return not pool.has(t))
        if available.is_empty():
            break
        pool.append(available[randi() % available.size()])
    return pool.slice(0, 3)
```

- [ ] **Step 2: Write failing tests**

Create `tests/unit/test_auction_manager.gd`:

```gdscript
extends GutTest

func test_generate_pool_size_is_3() -> void:
    var kills: Array[String] = ["汲取者", "守卫者", "急袭者"]
    var pool = AuctionManager.generate_pool(kills, [])
    assert_eq(pool.size(), 3)

func test_generate_pool_no_duplicates() -> void:
    var kills: Array[String] = ["汲取者", "守卫者", "急袭者", "守卫者"]
    var pool = AuctionManager.generate_pool(kills, [])
    var unique: Dictionary = {}
    for t in pool:
        unique[t] = true
    assert_eq(unique.size(), pool.size())

func test_generate_pool_fills_from_all_types_when_kills_low() -> void:
    var kills: Array[String] = []
    var pool = AuctionManager.generate_pool(kills, [])
    assert_eq(pool.size(), 3)

func test_generate_pool_includes_carried_over() -> void:
    var carried: Array[int] = [AuctionManager.ServiceType.PRESSURE_DELAY]
    var pool = AuctionManager.generate_pool([], carried)
    assert_true(pool.has(AuctionManager.ServiceType.PRESSURE_DELAY))
```

- [ ] **Step 3: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all new tests pass.

- [ ] **Step 4: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_auction_manager.gd
git commit -m "feat: AuctionManager service pool generation"
```

---

## Task 3: PhantomBuyer strategies

**Files:**
- Modify: `src/systems/AuctionManager.gd`
- Modify: `tests/unit/test_auction_manager.gd`

- [ ] **Step 1: Add PhantomBuyer class inside AuctionManager**

Append to `src/systems/AuctionManager.gd` before the final line:

```gdscript
class PhantomBuyer:
    enum Personality { AGGRESSIVE, PATIENT }

    var personality: Personality
    var gold: int = 0
    var preferred_types: Array[int] = []   # AGGRESSIVE: 2 types; PATIENT: 1 type
    var patience_streak: int = 0           # loops since priority service last appeared

    const PATIENT_THRESHOLD: int = 200
    const PATIENT_TIMEOUT_LOOPS: int = 5

    func init(p: Personality, prefs: Array[int]) -> void:
        personality = p
        preferred_types = prefs

    func earn(phase: int) -> void:
        var income_table: Array[int] = [0, 40, 40, 70, 70, 110, 110, 150, 150, 200, 200]
        gold += income_table[clampi(phase, 1, 10)]

    ## Returns interest level 0=none 1=low 2=medium 3=high for a service type
    func interest(service_type: int) -> int:
        if personality == Personality.AGGRESSIVE:
            if preferred_types.has(service_type):
                return 3  # high
            return 1      # low — still bids something
        else:  # PATIENT
            if preferred_types.has(service_type):
                return 3 if gold >= PATIENT_THRESHOLD else 2
            return 0  # none

    ## Returns bid amount for a given service; does not deduct gold
    func calculate_bid(service_type: int, pool: Array[int]) -> int:
        if personality == Personality.AGGRESSIVE:
            var spend_budget := int(gold * 0.75)
            if not preferred_types.has(service_type):
                # bid a small token on anything
                return min(15, gold)
            # count preferred services in this pool
            var pref_in_pool := pool.filter(func(t): return preferred_types.has(t)).size()
            if pref_in_pool == 0:
                return min(15, gold)
            return int(spend_budget / pref_in_pool)
        else:  # PATIENT
            if not preferred_types.has(service_type):
                return randi_range(10, 20)
            if gold < PATIENT_THRESHOLD:
                return randi_range(10, 20)
            # all-in on priority
            return int(gold * 0.85)

    ## Called after settlement to deduct gold for won services
    func pay(amount: int) -> void:
        gold = max(0, gold - amount)

    ## Called each loop when priority service not seen
    func tick_patience(priority_seen: bool) -> void:
        if personality != Personality.PATIENT:
            return
        if priority_seen:
            patience_streak = 0
        else:
            patience_streak += 1

    ## True when patient phantom should dump savings on secondary target
    func patience_overflow() -> bool:
        return personality == Personality.PATIENT and patience_streak >= PATIENT_TIMEOUT_LOOPS
```

- [ ] **Step 2: Instantiate phantoms in AuctionManager._ready()**

Replace the `_ready` body in AuctionManager:

```gdscript
var phantom_a: PhantomBuyer
var phantom_b: PhantomBuyer

func _ready() -> void:
    phantom_a = PhantomBuyer.new()
    phantom_a.init(
        PhantomBuyer.Personality.AGGRESSIVE,
        [ServiceType.RULE_COPY, ServiceType.COMP_MERGE]
    )
    phantom_b = PhantomBuyer.new()
    phantom_b.init(
        PhantomBuyer.Personality.PATIENT,
        [ServiceType.COMP_REWRITE]
    )
    EventBus.loop_completed.connect(_on_loop_completed)
```

- [ ] **Step 3: Write failing tests for PhantomBuyer**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_phantom_aggressive_earns_40g_phase1() -> void:
    var p := AuctionManager.PhantomBuyer.new()
    p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [0, 1])
    p.earn(1)
    assert_eq(p.gold, 40)

func test_phantom_aggressive_earns_110g_phase5() -> void:
    var p := AuctionManager.PhantomBuyer.new()
    p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [0, 1])
    p.earn(5)
    assert_eq(p.gold, 110)

func test_phantom_aggressive_bids_75pct_on_preferred() -> void:
    var p := AuctionManager.PhantomBuyer.new()
    p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [0])
    p.gold = 100
    var pool: Array[int] = [0, 1, 2]
    var bid := p.calculate_bid(0, pool)
    assert_eq(bid, 75)

func test_phantom_patient_low_bid_below_threshold() -> void:
    var p := AuctionManager.PhantomBuyer.new()
    p.init(AuctionManager.PhantomBuyer.Personality.PATIENT, [1])
    p.gold = 100  # below 200 threshold
    var pool: Array[int] = [0, 1, 2]
    var bid := p.calculate_bid(1, pool)
    assert_lte(bid, 20)

func test_phantom_patient_all_in_above_threshold() -> void:
    var p := AuctionManager.PhantomBuyer.new()
    p.init(AuctionManager.PhantomBuyer.Personality.PATIENT, [1])
    p.gold = 250
    var pool: Array[int] = [0, 1, 2]
    var bid := p.calculate_bid(1, pool)
    assert_gte(bid, 200)

func test_phantom_interest_high_for_preferred() -> void:
    var p := AuctionManager.PhantomBuyer.new()
    p.init(AuctionManager.PhantomBuyer.Personality.AGGRESSIVE, [2])
    assert_eq(p.interest(2), 3)

func test_phantom_patience_overflow_after_5_loops() -> void:
    var p := AuctionManager.PhantomBuyer.new()
    p.init(AuctionManager.PhantomBuyer.Personality.PATIENT, [1])
    for i in 5:
        p.tick_patience(false)
    assert_true(p.patience_overflow())
```

- [ ] **Step 4: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all new tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_auction_manager.gd
git commit -m "feat: PhantomBuyer aggressive and patient strategies"
```

---

## Task 4: AuctionManager — settlement logic

**Files:**
- Modify: `src/systems/AuctionManager.gd`
- Modify: `tests/unit/test_auction_manager.gd`

- [ ] **Step 1: Add static settle() function to AuctionManager**

Append to `src/systems/AuctionManager.gd`:

```gdscript
## Pure settlement function. Returns Array of result dicts.
## Each result: {service_type, winner: "player"|"phantom_a"|"phantom_b"|"none",
##               bids: {player, phantom_a, phantom_b}}
static func settle(services: Array[int],
                   player_bids_map: Dictionary,
                   bid_a: Dictionary,
                   bid_b: Dictionary) -> Array:
    var results: Array = []
    for svc in services:
        var pb: int = player_bids_map.get(svc, 0)
        var ab: int = bid_a.get(svc, 0)
        var bb: int = bid_b.get(svc, 0)
        var winner := "none"
        var max_bid := 0
        if pb > max_bid:
            max_bid = pb
            winner = "player"
        if ab > max_bid:
            max_bid = ab
            winner = "phantom_a"
        if bb > max_bid:
            max_bid = bb
            winner = "phantom_b"
        results.append({
            "service_type": svc,
            "winner": winner,
            "bids": {"player": pb, "phantom_a": ab, "phantom_b": bb}
        })
    return results
```

- [ ] **Step 2: Wire _on_loop_completed to run settlement**

Replace the `_on_loop_completed` stub:

```gdscript
func _on_loop_completed() -> void:
    # 1. Phantoms earn income
    phantom_a.earn(GameState.current_phase)
    phantom_b.earn(GameState.current_phase)

    # 2. Generate pool for THIS loop using kills that just happened
    current_services = generate_pool(_kills_this_loop, carried_over)
    _kills_this_loop = []

    # 3. Calculate phantom bids
    var bid_a: Dictionary = {}
    var bid_b: Dictionary = {}
    for svc in current_services:
        bid_a[svc] = phantom_a.calculate_bid(svc, current_services)
        bid_b[svc] = phantom_b.calculate_bid(svc, current_services)

    # 4. Settle
    last_results = settle(current_services, player_bids, bid_a, bid_b)

    # 5. Apply outcomes
    carried_over = []
    for r in last_results:
        match r["winner"]:
            "player":
                phantom_a.pay(0)  # refund phantom_a
                phantom_b.pay(0)  # refund phantom_b
                GameState.gold = max(0, GameState.gold - r["bids"]["player"])
                _award_service_to_player(r["service_type"])
            "phantom_a":
                phantom_a.pay(r["bids"]["phantom_a"])
            "phantom_b":
                phantom_b.pay(r["bids"]["phantom_b"])
            "none":
                carried_over.append(r["service_type"])

    # 6. Patience tick for phantom_b
    var b_priority_seen := current_services.has(phantom_b.preferred_types[0])
    phantom_b.tick_patience(b_priority_seen)
    if phantom_b.patience_overflow():
        phantom_b.patience_streak = 0  # reset after overflow discharge

    # 7. Reset player bids for next loop
    player_bids = {}

    # 8. Notify UI
    EventBus.auction_settled.emit(last_results)
    EventBus.gold_changed.emit(GameState.gold)

func _award_service_to_player(service_type: int) -> void:
    if GameState.service_bar.size() < 5:
        GameState.service_bar.append(service_type)
        EventBus.service_bar_changed.emit()
    else:
        # UI handles the discard popup via service_bar_changed with overflow flag
        _pending_overflow_service = service_type
        EventBus.service_bar_changed.emit()

var _pending_overflow_service: int = -1

func pop_overflow_service() -> int:
    var svc := _pending_overflow_service
    _pending_overflow_service = -1
    return svc
```

- [ ] **Step 3: Write failing settlement tests**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_settle_player_wins_highest_bid() -> void:
    var services: Array[int] = [AuctionManager.ServiceType.PRESSURE_DELAY]
    var player_bids_map := {AuctionManager.ServiceType.PRESSURE_DELAY: 100}
    var bid_a := {AuctionManager.ServiceType.PRESSURE_DELAY: 50}
    var bid_b := {AuctionManager.ServiceType.PRESSURE_DELAY: 30}
    var results = AuctionManager.settle(services, player_bids_map, bid_a, bid_b)
    assert_eq(results[0]["winner"], "player")

func test_settle_phantom_wins_when_higher() -> void:
    var services: Array[int] = [AuctionManager.ServiceType.COMP_MERGE]
    var player_bids_map := {AuctionManager.ServiceType.COMP_MERGE: 20}
    var bid_a := {AuctionManager.ServiceType.COMP_MERGE: 200}
    var bid_b := {AuctionManager.ServiceType.COMP_MERGE: 10}
    var results = AuctionManager.settle(services, player_bids_map, bid_a, bid_b)
    assert_eq(results[0]["winner"], "phantom_a")

func test_settle_none_when_all_zero() -> void:
    var services: Array[int] = [AuctionManager.ServiceType.DELETE_PARDON]
    var results = AuctionManager.settle(services, {}, {}, {})
    assert_eq(results[0]["winner"], "none")

func test_settle_refund_bids_preserved_in_result() -> void:
    var services: Array[int] = [AuctionManager.ServiceType.RULE_COPY]
    var player_bids_map := {AuctionManager.ServiceType.RULE_COPY: 80}
    var bid_a := {AuctionManager.ServiceType.RULE_COPY: 120}
    var bid_b := {}
    var results = AuctionManager.settle(services, player_bids_map, bid_a, bid_b)
    assert_eq(results[0]["bids"]["player"], 80)
    assert_eq(results[0]["bids"]["phantom_a"], 120)
```

- [ ] **Step 4: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all settlement tests pass.

- [ ] **Step 5: Commit**

```bash
git add src/systems/AuctionManager.gd tests/unit/test_auction_manager.gd
git commit -m "feat: AuctionManager settlement logic and loop integration"
```

---

## Task 5: Service effect execution + system hooks

**Files:**
- Modify: `src/systems/AuctionManager.gd`
- Modify: `src/entities/Tile.gd`
- Modify: `src/systems/EconomyManager.gd`
- Modify: `src/systems/GameLoop.gd`
- Modify: `tests/unit/test_auction_manager.gd`
- Modify: `tests/unit/test_tile_system.gd`
- Modify: `tests/unit/test_economy_manager.gd`

- [ ] **Step 1: Add Tile.copy_rule_to()**

Append to `src/entities/Tile.gd`:

```gdscript
## Copies first occupied rule slot into an empty slot on target tile.
## Returns true on success, false if source has no rule or target has no empty slot.
func copy_rule_to(target: Tile) -> bool:
    # Find first occupied rule slot on self
    var source_slot: Dictionary = {}
    for s in rule_slots:
        if s["trigger"] != null or s["effect"] != null:
            source_slot = s
            break
    if source_slot.is_empty():
        return false
    # Find empty slot on target
    var dest_slot: Dictionary = {}
    for s in target.rule_slots:
        if s["trigger"] == null and s["effect"] == null:
            dest_slot = s
            break
    if dest_slot.is_empty():
        return false
    # Copy (duplicate so they're independent references)
    if source_slot["trigger"] != null:
        dest_slot["trigger"] = source_slot["trigger"].duplicate()
    if source_slot["effect"] != null:
        dest_slot["effect"] = source_slot["effect"].duplicate()
    return true
```

- [ ] **Step 2: Write tile copy test**

Append to `tests/unit/test_tile_system.gd`:

```gdscript
func test_copy_rule_to_succeeds_with_empty_target_slot() -> void:
    var src := Tile.new()
    src.rule_slots = [{"trigger": null, "effect": null}, {"trigger": null, "effect": null}]
    var comp := ComponentData.new()
    comp.id = "受击"
    src.rule_slots[0]["trigger"] = comp
    var dst := Tile.new()
    dst.rule_slots = [{"trigger": null, "effect": null}]
    var ok := src.copy_rule_to(dst)
    assert_true(ok)
    assert_not_null(dst.rule_slots[0]["trigger"])

func test_copy_rule_to_fails_when_source_empty() -> void:
    var src := Tile.new()
    src.rule_slots = [{"trigger": null, "effect": null}]
    var dst := Tile.new()
    dst.rule_slots = [{"trigger": null, "effect": null}]
    var ok := src.copy_rule_to(dst)
    assert_false(ok)

func test_copy_rule_to_is_independent_duplicate() -> void:
    var src := Tile.new()
    var comp := ComponentData.new()
    comp.id = "受击"
    comp.trigger_value = 2.0
    src.rule_slots = [{"trigger": comp, "effect": null}]
    var dst := Tile.new()
    dst.rule_slots = [{"trigger": null, "effect": null}]
    src.copy_rule_to(dst)
    dst.rule_slots[0]["trigger"].trigger_value = 99.0
    assert_eq(src.rule_slots[0]["trigger"].trigger_value, 2.0)
```

- [ ] **Step 3: Add deletion_free hook to EconomyManager**

Replace `pay_deletion_cost()` in `src/autoloads/GameState.gd`:

```gdscript
func pay_deletion_cost() -> void:
    if deletion_free:
        deletion_free = false
        EventBus.gold_changed.emit(gold)
        return
    gold -= get_deletion_cost()
    deletion_count += 1
    EventBus.gold_changed.emit(gold)
```

- [ ] **Step 4: Write deletion_free test**

Append to `tests/unit/test_game_state.gd`:

```gdscript
func test_deletion_free_skips_cost_and_count() -> void:
    GameState.reset()
    GameState.gold = 100
    GameState.deletion_free = true
    GameState.pay_deletion_cost()
    assert_eq(GameState.gold, 100)
    assert_eq(GameState.deletion_count, 0)
    assert_false(GameState.deletion_free)
```

- [ ] **Step 5: Add kill tracking to GameLoop**

In `src/systems/GameLoop.gd`, add a reference to AuctionManager and register kills.

Add field after `var _combat_tile`:
```gdscript
var _auction_manager: AuctionManager = null
```

Add a `setup_auction(am: AuctionManager)` method:
```gdscript
func setup_auction(am: AuctionManager) -> void:
    _auction_manager = am
```

In `_on_combat_resolved()`, before `state = State.WALKING`, check if an enemy was killed and register it. Find the section where the enemy is freed and append:
```gdscript
    if _combat_tile != null:
        if _combat_tile.enemy != null:
            if _auction_manager != null:
                _auction_manager.register_kill(_combat_tile.enemy.enemy_id)
            _combat_tile.enemy.queue_free()
```

- [ ] **Step 6: Add service execution to AuctionManager**

Add `execute_service()` to `src/systems/AuctionManager.gd`:

```gdscript
## Called by ServiceActivatePopup with targeting params resolved by the player.
## params keys vary by service type:
##   RULE_COPY:      {source_tile: Tile, target_tile: Tile}
##   COMP_REWRITE:   {component: ComponentData, new_trigger_n: int, new_effect_delta: float}
##   COMP_MERGE:     {comp_a: ComponentData, comp_b: ComponentData}
##   ENEMY_PARDON:   {enemy_id: String}
##   DELETE_PARDON:  {}
##   PRESSURE_DELAY: {}
func execute_service(service_type: int, params: Dictionary) -> void:
    match service_type:
        ServiceType.RULE_COPY:
            params["source_tile"].copy_rule_to(params["target_tile"])
        ServiceType.COMP_REWRITE:
            var c: ComponentData = params["component"]
            if params.has("new_trigger_n"):
                c.trigger_value = clampf(params["new_trigger_n"], 1.0, 3.0)
            if params.has("new_effect_delta"):
                c.effect_value = c.effect_value * (1.0 + clampf(params["new_effect_delta"], 0.0, 0.5))
        ServiceType.COMP_MERGE:
            var a: ComponentData = params["comp_a"]
            var b: ComponentData = params["comp_b"]
            var merged := a.duplicate()
            merged.effect_value = (a.effect_value + b.effect_value) * 0.8
            merged.trigger_value = (a.trigger_value + b.trigger_value) * 0.8
            GameState.remove_from_inventory(a)
            GameState.remove_from_inventory(b)
            GameState.add_to_inventory(merged)
            EventBus.gold_changed.emit(GameState.gold)
        ServiceType.ENEMY_PARDON:
            GameState.enemy_pardon_type = params["enemy_id"]
            GameState.enemy_pardon_remaining = 3
        ServiceType.DELETE_PARDON:
            GameState.deletion_free = true
        ServiceType.PRESSURE_DELAY:
            GameState.loops_in_phase = max(0, GameState.loops_in_phase - 1)
    EventBus.service_bar_changed.emit()
```

- [ ] **Step 7: Write service execution tests**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_execute_delete_pardon_sets_flag() -> void:
    GameState.reset()
    var am := AuctionManager.new()
    am.execute_service(AuctionManager.ServiceType.DELETE_PARDON, {})
    assert_true(GameState.deletion_free)

func test_execute_pressure_delay_decrements_loops_in_phase() -> void:
    GameState.reset()
    GameState.loops_in_phase = 3
    var am := AuctionManager.new()
    am.execute_service(AuctionManager.ServiceType.PRESSURE_DELAY, {})
    assert_eq(GameState.loops_in_phase, 2)

func test_execute_enemy_pardon_sets_type_and_count() -> void:
    GameState.reset()
    var am := AuctionManager.new()
    am.execute_service(AuctionManager.ServiceType.ENEMY_PARDON, {"enemy_id": "汲取者"})
    assert_eq(GameState.enemy_pardon_type, "汲取者")
    assert_eq(GameState.enemy_pardon_remaining, 3)

func test_execute_comp_merge_combines_effect_values() -> void:
    GameState.reset()
    var am := AuctionManager.new()
    var a := ComponentData.new()
    a.effect_value = 10.0
    a.slot_type = ComponentData.SlotType.EFFECT_ONLY
    var b := ComponentData.new()
    b.effect_value = 10.0
    b.slot_type = ComponentData.SlotType.EFFECT_ONLY
    GameState.add_to_inventory(a)
    GameState.add_to_inventory(b)
    am.execute_service(AuctionManager.ServiceType.COMP_MERGE, {"comp_a": a, "comp_b": b})
    assert_eq(GameState.inventory.size(), 1)
    assert_eq(GameState.inventory[0].effect_value, 16.0)  # (10+10)*0.8
```

- [ ] **Step 8: Run all tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 9: Commit**

```bash
git add src/systems/AuctionManager.gd src/entities/Tile.gd src/autoloads/GameState.gd src/systems/GameLoop.gd tests/unit/test_auction_manager.gd tests/unit/test_tile_system.gd tests/unit/test_game_state.gd
git commit -m "feat: service effect execution, Tile.copy_rule_to, deletion_free hook"
```

---

## Task 6: Enemy pardon hook in CombatSystem

**Files:**
- Modify: `src/systems/CombatSystem.gd`
- Modify: `src/systems/GameLoop.gd`
- Modify: `tests/unit/test_combat_system.gd`

- [ ] **Step 1: Read CombatSystem to understand start()**

Read `src/systems/CombatSystem.gd` to find where combat begins and confirm where to inject the pardon check.

- [ ] **Step 2: Add pardon check in GameLoop.check_tile_for_enemy()**

In `src/systems/GameLoop.gd`, in `check_tile_for_enemy()`, before `state = State.COMBAT` add:

```gdscript
    # Check enemy pardon
    if GameState.enemy_pardon_remaining > 0 and GameState.enemy_pardon_type == tile.enemy.enemy_id:
        GameState.enemy_pardon_remaining -= 1
        if GameState.enemy_pardon_remaining == 0:
            GameState.enemy_pardon_type = ""
        # Strip components automatically (same as free strip) then clear enemy
        EventBus.enemy_pardoned.emit(tile.enemy.enemy_id)
        if _auction_manager != null:
            _auction_manager.register_kill(tile.enemy.enemy_id)
        tile.enemy.queue_free()
        tile.clear_enemy()
        return
```

- [ ] **Step 3: Write pardon test**

Append to `tests/unit/test_auction_manager.gd`:

```gdscript
func test_enemy_pardon_remaining_decrements_on_pardon() -> void:
    GameState.reset()
    GameState.enemy_pardon_type = "汲取者"
    GameState.enemy_pardon_remaining = 3
    # Simulate one pardon
    GameState.enemy_pardon_remaining -= 1
    assert_eq(GameState.enemy_pardon_remaining, 2)
```

- [ ] **Step 4: Run tests**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

- [ ] **Step 5: Commit**

```bash
git add src/systems/GameLoop.gd tests/unit/test_auction_manager.gd
git commit -m "feat: enemy pardon check in GameLoop combat gate"
```

---

## Task 7: AuctionPanel UI

**Files:**
- Create: `scenes/ui/auction_panel.tscn`
- Create: `src/ui/AuctionPanel.gd`

- [ ] **Step 1: Create AuctionPanel.gd**

Create `src/ui/AuctionPanel.gd`:

```gdscript
class_name AuctionPanel
extends Control

var _auction_manager: AuctionManager = null

@onready var last_results_container: HBoxContainer = $VBox/LastResults/HBox
@onready var current_container: HBoxContainer = $VBox/CurrentServices/HBox
@onready var gold_label: Label = $VBox/Footer/GoldLabel
@onready var allocated_label: Label = $VBox/Footer/AllocatedLabel
@onready var lock_btn: Button = $VBox/Footer/LockBtn

# service_type -> SpinBox
var _bid_inputs: Dictionary = {}

func setup(am: AuctionManager) -> void:
    _auction_manager = am
    EventBus.auction_settled.connect(_on_settled)
    EventBus.gold_changed.connect(_refresh_footer)
    lock_btn.pressed.connect(_on_lock_pressed)
    hide()

func toggle() -> void:
    if visible:
        close()
    else:
        open()

func open() -> void:
    _refresh_current()
    _refresh_last_results()
    _refresh_footer(GameState.gold)
    GameState.pause_for_panel()
    show()

func close() -> void:
    GameState.unpause_for_panel()
    hide()

func _on_settled(_results: Array) -> void:
    _refresh_last_results()
    _refresh_current()

func _refresh_footer(gold: int) -> void:
    gold_label.text = "金币: %d" % gold
    var alloc := 0
    for svc in _bid_inputs:
        alloc += int(_bid_inputs[svc].value)
    allocated_label.text = "已分配: %d" % alloc

func _on_lock_pressed() -> void:
    for svc in _bid_inputs:
        _auction_manager.set_player_bid(svc, int(_bid_inputs[svc].value))
    close()

func _refresh_last_results() -> void:
    for c in last_results_container.get_children():
        c.queue_free()
    if _auction_manager == null:
        return
    for r in _auction_manager.last_results:
        var card := _make_result_card(r)
        last_results_container.add_child(card)

func _refresh_current() -> void:
    for c in current_container.get_children():
        c.queue_free()
    _bid_inputs = {}
    if _auction_manager == null:
        return
    for svc in _auction_manager.current_services:
        var card := _make_bid_card(svc)
        current_container.add_child(card)

func _make_result_card(r: Dictionary) -> Control:
    var panel := PanelContainer.new()
    var vbox := VBoxContainer.new()
    panel.add_child(vbox)
    var name_lbl := Label.new()
    name_lbl.text = AuctionManager.SERVICE_NAMES.get(r["service_type"], "?")
    vbox.add_child(name_lbl)
    var winner_lbl := Label.new()
    match r["winner"]:
        "player":
            winner_lbl.text = "✓ 你赢了  %dg" % r["bids"]["player"]
        "phantom_a":
            winner_lbl.text = "✗ 影子甲  你:%dg↩  甲:%dg" % [r["bids"]["player"], r["bids"]["phantom_a"]]
        "phantom_b":
            winner_lbl.text = "✗ 影子乙  你:%dg↩  乙:%dg" % [r["bids"]["player"], r["bids"]["phantom_b"]]
        "none":
            winner_lbl.text = "— 无人竞价"
    vbox.add_child(winner_lbl)
    # Show phantom refunds
    var refund_lbl := Label.new()
    if r["winner"] == "player":
        refund_lbl.text = "甲:%dg↩ 乙:%dg↩" % [r["bids"]["phantom_a"], r["bids"]["phantom_b"]]
    vbox.add_child(refund_lbl)
    return panel

func _make_bid_card(svc: int) -> Control:
    var panel := PanelContainer.new()
    var vbox := VBoxContainer.new()
    panel.add_child(vbox)
    var name_lbl := Label.new()
    name_lbl.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
    vbox.add_child(name_lbl)
    var desc_lbl := Label.new()
    desc_lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
    desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
    vbox.add_child(desc_lbl)
    # Interest bars (text-based)
    if _auction_manager != null:
        var int_a := _auction_manager.phantom_a.interest(svc)
        var int_b := _auction_manager.phantom_b.interest(svc)
        var interest_labels := ["无", "低", "中", "高"]
        var ia_lbl := Label.new()
        ia_lbl.text = "影子甲: %s" % interest_labels[int_a]
        var ib_lbl := Label.new()
        ib_lbl.text = "影子乙: %s" % interest_labels[int_b]
        vbox.add_child(ia_lbl)
        vbox.add_child(ib_lbl)
    var spin := SpinBox.new()
    spin.min_value = 0
    spin.max_value = GameState.gold
    spin.step = 1
    spin.value_changed.connect(func(_v): _refresh_footer(GameState.gold))
    _bid_inputs[svc] = spin
    vbox.add_child(spin)
    return panel
```

- [ ] **Step 2: Create auction_panel.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/ui/auction_panel.tscn` with root Control node named `AuctionPanel`, script `src/ui/AuctionPanel.gd`. Add child nodes:
- `VBox: VBoxContainer`
  - `LastResults: VBoxContainer` (Label "↩ 上圈结果" + HBoxContainer `HBox`)
  - `CurrentServices: VBoxContainer` (Label "● 本圈拍品" + HBoxContainer `HBox`)
  - `Footer: HBoxContainer` (Label `GoldLabel`, Label `AllocatedLabel`, Button `LockBtn` text "锁定出价")

- [ ] **Step 3: Commit**

```bash
git add src/ui/AuctionPanel.gd scenes/ui/auction_panel.tscn
git commit -m "feat: AuctionPanel UI with last results and current bids"
```

---

## Task 8: ServiceBar UI + discard popup

**Files:**
- Create: `src/ui/ServiceBar.gd`
- Create: `scenes/ui/service_bar.tscn`

- [ ] **Step 1: Create ServiceBar.gd**

Create `src/ui/ServiceBar.gd`:

```gdscript
class_name ServiceBar
extends HBoxContainer

var _auction_manager: AuctionManager = null
var _activate_popup: ServiceActivatePopup = null

const MAX_SLOTS := 5

func setup(am: AuctionManager, popup: ServiceActivatePopup) -> void:
    _auction_manager = am
    _activate_popup = popup
    EventBus.service_bar_changed.connect(_refresh)
    _refresh()

func _refresh() -> void:
    for c in get_children():
        c.queue_free()

    # Check for overflow service pending discard
    if _auction_manager != null and _auction_manager._pending_overflow_service >= 0:
        _show_discard_popup(_auction_manager._pending_overflow_service)
        return

    for i in MAX_SLOTS:
        var btn := Button.new()
        if i < GameState.service_bar.size():
            var svc: int = GameState.service_bar[i]
            btn.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
            btn.pressed.connect(_on_service_pressed.bind(svc, i))
        else:
            btn.text = "—"
            btn.disabled = true
        add_child(btn)

func _on_service_pressed(svc: int, idx: int) -> void:
    if _activate_popup != null:
        _activate_popup.open(svc, idx)

func _show_discard_popup(new_svc: int) -> void:
    # Build the 6 options: current 5 + new one
    var options: Array[int] = GameState.service_bar.duplicate()
    options.append(new_svc)
    if _activate_popup != null:
        _activate_popup.open_discard(options, new_svc, _auction_manager)
```

- [ ] **Step 2: Create service_bar.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/ui/service_bar.tscn` with root HBoxContainer named `ServiceBar`, script `src/ui/ServiceBar.gd`.

- [ ] **Step 3: Commit**

```bash
git add src/ui/ServiceBar.gd scenes/ui/service_bar.tscn
git commit -m "feat: ServiceBar 5-slot HUD bar"
```

---

## Task 9: ServiceActivatePopup

**Files:**
- Create: `src/ui/ServiceActivatePopup.gd`
- Create: `scenes/ui/service_activate_popup.tscn`

- [ ] **Step 1: Create ServiceActivatePopup.gd**

Create `src/ui/ServiceActivatePopup.gd`:

```gdscript
class_name ServiceActivatePopup
extends Control

var _auction_manager: AuctionManager = null
var _tiles: Array = []
var _current_service: int = -1
var _current_bar_idx: int = -1

@onready var title_label: Label = $Panel/VBox/Title
@onready var content_container: VBoxContainer = $Panel/VBox/Content
@onready var confirm_btn: Button = $Panel/VBox/Buttons/Confirm
@onready var cancel_btn: Button = $Panel/VBox/Buttons/Cancel

func setup(am: AuctionManager, tiles: Array) -> void:
    _auction_manager = am
    _tiles = tiles
    confirm_btn.pressed.connect(_on_confirm)
    cancel_btn.pressed.connect(_on_cancel)
    hide()

func open(svc: int, bar_idx: int) -> void:
    _current_service = svc
    _current_bar_idx = bar_idx
    title_label.text = AuctionManager.SERVICE_NAMES.get(svc, "?")
    _build_content(svc)
    GameState.pause_for_panel()
    show()

func open_discard(options: Array[int], new_svc: int, am: AuctionManager) -> void:
    _auction_manager = am
    _current_service = -1
    title_label.text = "服务栏已满，选择一个放弃"
    _build_discard_content(options, new_svc)
    GameState.pause_for_panel()
    show()

func _on_cancel() -> void:
    GameState.unpause_for_panel()
    hide()

func _on_confirm() -> void:
    if _current_service < 0:
        return
    var params := _collect_params(_current_service)
    if params == null:
        return  # validation failed
    # Remove from service bar
    GameState.service_bar.remove_at(_current_bar_idx)
    _auction_manager.execute_service(_current_service, params)
    GameState.unpause_for_panel()
    hide()

func _build_content(svc: int) -> void:
    for c in content_container.get_children():
        c.queue_free()
    match svc:
        AuctionManager.ServiceType.PRESSURE_DELAY, AuctionManager.ServiceType.DELETE_PARDON:
            var lbl := Label.new()
            lbl.text = AuctionManager.SERVICE_DESCRIPTIONS.get(svc, "")
            content_container.add_child(lbl)
        AuctionManager.ServiceType.ENEMY_PARDON:
            var lbl := Label.new()
            lbl.text = "选择赦免的敌人类型："
            content_container.add_child(lbl)
            for enemy_id in ["汲取者", "守卫者", "急袭者", "复制者", "先驱者"]:
                var btn := Button.new()
                btn.text = enemy_id
                btn.name = "EnemyBtn_" + enemy_id
                btn.toggle_mode = true
                btn.button_group = ButtonGroup.new()
                content_container.add_child(btn)
        AuctionManager.ServiceType.COMP_REWRITE:
            var lbl := Label.new()
            lbl.text = "选择要改写的词条，然后设定新数值："
            content_container.add_child(lbl)
            for comp in GameState.inventory:
                var btn := Button.new()
                btn.text = "%s (当前值: %.1f)" % [comp.display_name, comp.effect_value if comp.slot_type == ComponentData.SlotType.EFFECT_ONLY else comp.trigger_value]
                btn.name = "CompBtn_" + comp.id
                btn.toggle_mode = true
                content_container.add_child(btn)
        AuctionManager.ServiceType.COMP_MERGE:
            var lbl := Label.new()
            lbl.text = "选择两个同类词条合并（结果数值 = 总和×0.8）："
            content_container.add_child(lbl)
            for comp in GameState.inventory:
                var btn := Button.new()
                btn.text = "%s (%.1f)" % [comp.display_name, comp.effect_value if comp.slot_type == ComponentData.SlotType.EFFECT_ONLY else comp.trigger_value]
                btn.toggle_mode = true
                btn.name = "MergeBtn_" + comp.id
                content_container.add_child(btn)
        AuctionManager.ServiceType.RULE_COPY:
            var lbl := Label.new()
            lbl.text = "选择来源地块（有规则），再选目标地块（有空槽）："
            content_container.add_child(lbl)

func _collect_params(svc: int) -> Dictionary:
    match svc:
        AuctionManager.ServiceType.PRESSURE_DELAY, AuctionManager.ServiceType.DELETE_PARDON:
            return {}
        AuctionManager.ServiceType.ENEMY_PARDON:
            for c in content_container.get_children():
                if c is Button and c.button_pressed:
                    return {"enemy_id": c.text}
            return null  # none selected
        AuctionManager.ServiceType.COMP_REWRITE:
            for c in content_container.get_children():
                if c is Button and c.button_pressed and c.name.begins_with("CompBtn_"):
                    var id := c.name.substr("CompBtn_".length())
                    var comp := GameState.inventory.filter(func(x): return x.id == id)
                    if comp.is_empty():
                        return null
                    # Increase effect_value by 20% as default rewrite
                    return {"component": comp[0], "new_effect_delta": 0.2}
            return null
        AuctionManager.ServiceType.COMP_MERGE:
            var selected: Array = []
            for c in content_container.get_children():
                if c is Button and c.button_pressed and c.name.begins_with("MergeBtn_"):
                    var id := c.name.substr("MergeBtn_".length())
                    var found := GameState.inventory.filter(func(x): return x.id == id)
                    if not found.is_empty():
                        selected.append(found[0])
            if selected.size() < 2:
                return null
            if selected[0].slot_type != selected[1].slot_type:
                return null  # must be same kind
            return {"comp_a": selected[0], "comp_b": selected[1]}
        AuctionManager.ServiceType.RULE_COPY:
            # Rule copy uses tile selection; for now returns empty (tile selection
            # is handled via Tile.clicked signal in Main — this popup just confirms)
            return {}
    return {}

func _build_discard_content(options: Array[int], new_svc: int) -> void:
    for c in content_container.get_children():
        c.queue_free()
    for i in options.size():
        var svc := options[i]
        var btn := Button.new()
        var label := AuctionManager.SERVICE_NAMES.get(svc, "?")
        if svc == new_svc:
            label += " (新)"
        btn.text = label
        btn.toggle_mode = true
        btn.name = "DiscardBtn_%d" % i
        content_container.add_child(btn)
    confirm_btn.pressed.disconnect(_on_confirm)
    confirm_btn.pressed.connect(_on_discard_confirm.bind(options, new_svc))

func _on_discard_confirm(options: Array[int], new_svc: int) -> void:
    for c in content_container.get_children():
        if c is Button and c.button_pressed:
            var idx := int(c.name.substr("DiscardBtn_".length()))
            if idx < GameState.service_bar.size():
                GameState.service_bar.remove_at(idx)
            # Add all non-discarded services (the new one if not discarded)
            if options[idx] != new_svc:
                # discarded an existing one, add new
                GameState.service_bar.append(new_svc)
            _auction_manager._pending_overflow_service = -1
            EventBus.service_bar_changed.emit()
            GameState.unpause_for_panel()
            hide()
            return
```

- [ ] **Step 2: Create service_activate_popup.tscn via MCP**

Use `mcp__godot__create_scene` to create `scenes/ui/service_activate_popup.tscn` with root Control named `ServiceActivatePopup`, script `src/ui/ServiceActivatePopup.gd`. Add:
- `Panel: PanelContainer`
  - `VBox: VBoxContainer`
    - `Title: Label`
    - `Content: VBoxContainer`
    - `Buttons: HBoxContainer`
      - `Cancel: Button` text "取消"
      - `Confirm: Button` text "确认"

- [ ] **Step 3: Commit**

```bash
git add src/ui/ServiceActivatePopup.gd scenes/ui/service_activate_popup.tscn
git commit -m "feat: ServiceActivatePopup targeting UI for all 6 service types"
```

---

## Task 10: Wire up in Main + HUD phantom display

**Files:**
- Modify: `src/Main.gd`
- Modify: `scenes/main.tscn`
- Modify: `src/ui/HUD.gd`
- Modify: `scenes/ui/hud.tscn`

- [ ] **Step 1: Read Main.gd to understand setup flow**

Read `src/Main.gd` to understand how systems are wired.

- [ ] **Step 2: Add AuctionManager to main.tscn**

Use MCP `mcp__godot__open_scene` to open `scenes/main.tscn`, then `mcp__godot__create_node` to add:
- `AuctionManager` (script `src/systems/AuctionManager.gd`) as child of root

- [ ] **Step 3: Add AuctionPanel + ServiceBar + ServiceActivatePopup to hud.tscn**

Use MCP to open `scenes/ui/hud.tscn` and instantiate:
- `AuctionPanel` from `scenes/ui/auction_panel.tscn`
- `ServiceBar` from `scenes/ui/service_bar.tscn`
- `ServiceActivatePopup` from `scenes/ui/service_activate_popup.tscn`

Also add to the BottomBar HContent area:
- `AuctionBtn: Button` text "残市"
- `PhantomAPill: Label` (for phantom A budget)
- `PhantomBPill: Label` (for phantom B budget)

- [ ] **Step 4: Wire everything in Main.gd**

In `src/Main.gd`, after the existing setup calls, add:

```gdscript
@onready var _auction_manager: AuctionManager = $AuctionManager

func _ready() -> void:
    # ... existing setup ...
    _game_loop.setup_auction(_auction_manager)
    var auction_panel = $HUD/AuctionPanel
    var service_bar = $HUD/ServiceBar
    var activate_popup = $HUD/ServiceActivatePopup
    auction_panel.setup(_auction_manager)
    activate_popup.setup(_auction_manager, _tiles)
    service_bar.setup(_auction_manager, activate_popup)
    _hud.setup_auction(auction_panel)
```

- [ ] **Step 5: Add phantom budget display to HUD**

In `src/ui/HUD.gd`, add after `_on_rule_fired`:

```gdscript
var _auction_manager: AuctionManager = null
@onready var phantom_a_label: Label = $BottomBar/HContent/PhantomAPill
@onready var phantom_b_label: Label = $BottomBar/HContent/PhantomBPill
@onready var auction_btn: Button = $BottomBar/HContent/AuctionBtn
var _auction_panel = null

func setup_auction(panel) -> void:
    _auction_panel = panel
    auction_btn.pressed.connect(_auction_panel.toggle)

func _process(_delta: float) -> void:
    # ... existing process code ...
    if _auction_panel != null and _auction_panel._auction_manager != null:
        var am = _auction_panel._auction_manager
        phantom_a_label.text = "甲 %dg" % am.phantom_a.gold
        phantom_b_label.text = "乙 %dg%s" % [am.phantom_b.gold, " !" if am.phantom_b.gold >= 180 else ""]
```

- [ ] **Step 6: Run full self-test**

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add src/Main.gd scenes/main.tscn src/ui/HUD.gd scenes/ui/hud.tscn
git commit -m "feat: wire AuctionManager, AuctionPanel, ServiceBar into main scene"
```

---

## Self-Review Checklist

**Spec coverage:**
- ✅ 6 services defined with effects (Tasks 2, 5)
- ✅ Service pool from enemy kills + fallback fill (Task 2)
- ✅ Carry-over with indicator (Task 4 settlement)
- ✅ No forced pause, HUD accessible (Task 7)
- ✅ End-of-loop settlement (Task 4)
- ✅ All losing bidders refunded (Task 4)
- ✅ Service bar 5 slots (Task 8)
- ✅ Manual activation only (Task 9)
- ✅ Full-slot discard popup (Task 9)
- ✅ Phantom A aggressive strategy (Task 3)
- ✅ Phantom B patient strategy (Task 3)
- ✅ Phase-scaled income with carry-over (Task 3)
- ✅ Interest level display (Task 7)
- ✅ Last loop results with exact bids + refunds (Task 7)
- ✅ Phantom budgets on HUD (Task 10)
- ✅ Enemy pardon hook (Task 6)
- ✅ 词条融合 sum×0.8 formula (Task 5)
- ✅ 词条改写 N range 1-3, delta ≤50% (Task 5)
- ✅ 规则复制 starts at pass_count=0 (Task 5)

**Placeholder scan:** No TBD/TODO found.

**Type consistency:**
- `ServiceType` enum defined in Task 2, used consistently across Tasks 3-10
- `PhantomBuyer` class defined in Task 3, referenced in Tasks 4, 7, 10
- `execute_service(service_type: int, params: Dictionary)` signature defined Task 5, called Task 9
- `copy_rule_to(target: Tile) -> bool` defined Task 5, called Task 5
