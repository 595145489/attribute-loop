# Phase 3 Design — 永久的地块

**Date:** 2026-05-22
**Status:** Approved
**Playable Goal:** Place permanent rules on tiles that scale with pass_count; sacrifice components to the Altar for permanent bonuses and Phase advancement; gold economy enforces real deletion costs.

---

## 1. Scope

### What Phase 3 Includes

- Tile rule placement (T+E per slot, T must be 经过(N) in Phase 3)
- pass_count tracking per tile; effect value scales with pass_count
- Tile color gradient reflecting pass_count strength (grey → blue → yellow)
- Tile rule removal: costs gold, components destroyed
- Altar tile: accepts E components only, converts each to a permanent global bonus, fills → Phase advances
- Gold economy: earn from kills, spend to delete (global escalating cost)
- Phase advancement: enemy stats immediately rescale on Phase change
- HUD gold display

### What Phase 3 Does NOT Include

- World pressure system (Phase 4)
- New enemy types: 急袭者, 复制者, 先驱者 (Phase 4)
- New effects: 护盾, 加速, 蓄能 (Phase 4)
- New trigger: 低血 (Phase 4)
- Tile T triggers beyond 经过(N) (future expansion hook, not Phase 3)

---

## 2. Tile Rule System

### Tile Data Structure

Each tile holds up to 3 rule slots. Each slot is a T+E pair:

```gdscript
var pass_count: int = 0
var rule_slots: Array = []  # max 3, each: {"trigger": ComponentData|null, "effect": ComponentData|null}
const MAX_RULES := 3
```

### Tile T Slot Constraint

In Phase 3, the T slot of a tile rule only accepts components with `id == "经过"`. Type enforcement is applied in the placement UI — other trigger components are filtered out. The slot structure is preserved for future expansion (e.g., 完成一圈, 规则触发 as tile triggers).

### pass_count Increment

`pass_count` increments in `Main._check_player_tile()` each time a tile is visited this loop, before `EventBus.tile_passed` is emitted:

```gdscript
if not tile.visited_this_loop:
    tile.visited_this_loop = true
    tile.pass_count += 1
    EventBus.tile_passed.emit(tile.tile_index)
```

### Effect Value Scaling (Tile Only)

```
actual_value = base_value × (1 + growth_rate × pass_count)
```

Player rule slots always use `base_value` (pass_count = 0). Tile rules use the full formula.

### Tile Rule Evaluation (RuleEngine)

When `tile_passed(tile_idx)` fires, RuleEngine looks up the Tile node and evaluates its rule slots:

```gdscript
func _on_tile_passed(tile_idx: int) -> void:
    var tile = _get_tile(tile_idx)
    for slot in tile.rule_slots:
        var t: ComponentData = slot["trigger"]
        var e: ComponentData = slot["effect"]
        if t == null or e == null:
            continue
        var n := int(t.trigger_value)
        if n > 0 and tile.pass_count % n == 0:
            _execute_effect(e, tile.pass_count)
```

`_get_tile(idx)` is resolved via a reference to `TilesContainer` injected at `_ready`.

### Tile Click Interaction

`Main._unhandled_input()` handles left-click and checks distance to all tiles:

```gdscript
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var pos = get_global_mouse_position()
        for tile in tiles_container.get_children():
            if pos.distance_to(tile.global_position) < 30.0:
                if tile.is_altar:
                    _open_altar_panel(tile)
                else:
                    _open_tile_rule_panel(tile)
                return
```

Opening a panel sets `GameState.is_paused = true`; closing it sets it back to `false`.

### Tile Rule Removal

Removing a rule from a tile (either T or E sub-slot, or the full slot):
- Costs gold using the global escalating deletion cost
- Both components in the slot are **permanently destroyed**
- `GameState.deletion_count` increments once per removal

---

## 3. Altar System

### Altar Tile

The Altar is a single special tile on the track (`is_altar = true`), at a fixed landmark position, visually distinct. It uses a separate slot array:

```gdscript
var is_altar: bool = false
var altar_slots: Array = []  # Array of ComponentData|null, size = current phase altar_requirement
```

`altar_slots` is resized each time Phase advances, using `DataTables.get_phase(current_phase).altar_requirement`.

### Altar Accepts E Only

Only components with `slot_type == EFFECT_ONLY` or `BOTH` can be placed in altar slots. The placement UI filters out TRIGGER_ONLY components.

### Permanent Bonus Formula

Each E component placed and activated in the altar contributes a permanent global bonus:

```
altar_bonuses[effect_id] += base_value × altar_ratio
```

`altar_ratio` is a new per-type field on `ComponentData` (configured in each `.tres` file):

| Effect | altar_ratio |
|--------|------------|
| 治愈 | 0.10 |
| 反射 | 0.05 |
| 护盾 | 0.08 |
| 加速 | 0.08 |
| 蓄能 | 0.06 |

### Bonus Application in RuleEngine

When executing any effect, the altar bonus for that effect type is added to the final value:

```gdscript
func _execute_effect(e: ComponentData, pass_count: int) -> void:
    var scale := 1.0 + e.growth_rate * pass_count
    var base := e.effect_value * scale
    var bonus := GameState.altar_bonuses.get(e.id, 0.0)
    var final_value := base + bonus
    # ... execute effect with final_value
```

Player rule slots: `pass_count = 0`, so `scale = 1.0`, but `bonus` still applies.

### Altar Activation

When all `altar_slots` are filled, the Altar panel shows an "激活" button. On activation:

1. For each E component in `altar_slots`:
   - Apply `GameState.altar_bonuses[e.id] += e.base_value × e.altar_ratio`
   - Component is permanently consumed (not returned to inventory)
2. Clear `altar_slots`
3. `GameState.current_phase += 1`
4. Resize `altar_slots` to new phase's requirement
5. Emit `EventBus.phase_changed(new_phase)`

### Phase Change Response

`GameLoop` listens to `phase_changed`. From that point, all newly spawned enemies use the new phase's stat multiplier:

```
stat = base_stat × (1 + (current_phase - 1) × 0.3)
```

Enemies already on the track keep their existing stats.

---

## 4. Gold Economy

### GameState Additions

```gdscript
var gold: int = 0
var deletion_count: int = 0  # global across all deletions (inventory + tile)
var altar_bonuses: Dictionary = {}  # {"治愈": 2.5, "反射": 0.03, ...}
```

### Gold Drop from Kills

`EconomyManager` (new Node in Systems) listens to `EventBus.enemy_killed`:

```gdscript
func _on_enemy_killed(enemy: Enemy) -> void:
    var ed := DataTables.get_enemy(enemy.enemy_id)
    var phase_mult := 1.0 + (GameState.current_phase - 1) * 0.3
    var amount := int(randi_range(ed.gold_min, ed.gold_max) * phase_mult)
    GameState.gold += amount
    EventBus.gold_changed.emit(GameState.gold)
```

Base gold ranges per enemy type:

| Enemy | gold_min | gold_max |
|-------|----------|----------|
| 汲取者 | 5 | 15 |
| 守卫者 | 5 | 15 |

(Higher enemy types are Phase 4.)

### Deletion Cost — Global Escalating

`EconomyManager` provides:

```gdscript
func get_deletion_cost() -> int:
    match GameState.deletion_count:
        0: return 20
        1: return 50
        2: return 100
        _:
            var cost := 100
            for i in GameState.deletion_count - 2:
                cost *= 2
            return cost

func pay_deletion_cost() -> void:
    GameState.gold -= get_deletion_cost()
    GameState.deletion_count += 1
    EventBus.gold_changed.emit(GameState.gold)
```

The deletion button in all UIs (InventoryPanel, TileRulePanel) is disabled when `GameState.gold < EconomyManager.get_deletion_cost()`.

### Reset

`GameState.reset()` clears: `gold = 0`, `deletion_count = 0`, `altar_bonuses = {}`. `Main.reset_tiles()` zeroes `pass_count`, clears `rule_slots` and `altar_slots` on all tiles.

---

## 5. Scene Structure

```
main.tscn
├── GameLoop (Node)
├── World (Node2D)
│   ├── Track (Path2D)
│   │   └── PlayerFollow (PathFollow2D)
│   │       └── [player.tscn]
│   ├── TilesContainer (Node2D)
│   └── EnemiesContainer (Node2D)
├── Systems (Node)
│   ├── CombatSystem (Node)
│   ├── [rule_engine.tscn]
│   ├── [strip_manager.tscn]
│   └── EconomyManager (Node)        ← NEW
└── UI (CanvasLayer)
    ├── [hud.tscn]
    ├── [strip_panel.tscn]
    ├── [inventory_panel.tscn]
    ├── [tile_rule_panel.tscn]        ← NEW
    └── [altar_panel.tscn]            ← NEW
```

### New Scenes

| Scene | Script | Responsibility |
|-------|--------|---------------|
| tile_rule_panel.tscn | TileRulePanel.gd | Display and edit one tile's rule slots |
| altar_panel.tscn | AltarPanel.gd | Display altar slots, preview bonuses, activate |

---

## 6. TileRulePanel UI

Opens when player clicks a non-altar tile. Game pauses while open.

**Layout:**
- Header: "地块 #{index} — 经过 {pass_count} 次"
- Tile color indicator (reflects pass_count strength)
- 3 rule slot rows, each showing:
  - T sub-slot: component name + trigger_value, or `[放入经过组件]`
  - E sub-slot: component name + calculated effect value, or `[放入效果组件]`
  - Remove button (per slot, not per sub-slot): removes the entire T+E pair together; shows cost `(¥{cost})`; disabled if gold insufficient or both sub-slots are empty
- Inventory selector: appears inline when a sub-slot is clicked; filters by type (T→经过 only, E→all effects)
- Close button

**Placement flow:**
1. Player clicks empty T sub-slot → inventory filtered to `id == "经过"` components
2. Player selects a component → component moves from inventory to tile slot
3. Same for E sub-slot (no type filter beyond EFFECT_ONLY / BOTH)

---

## 7. AltarPanel UI

Opens when player clicks the Altar tile. Game pauses while open.

**Layout:**
- Header: "祭坛 — Phase {n}" + progress "{filled}/{required}"
- N slot rows (N = current phase altar_requirement), each showing:
  - Filled: component name + base_value + `→ +{preview_bonus} {effect_id}`
  - Empty: `[放入效果组件]`
- Accumulated bonuses section: lists all current `GameState.altar_bonuses`
- "激活" button: enabled only when all slots filled; triggers Phase advancement
- Close button

**Placement flow:**
1. Click empty slot → inventory filtered to EFFECT_ONLY / BOTH components
2. Select → component immediately moves from inventory to altar slot
3. Player can click a filled slot to remove it back to inventory (before activation only)
4. Once "激活" is pressed, all components are permanently consumed — no retrieval possible

---

## 8. EventBus Additions

```gdscript
signal gold_changed(new_amount: int)
signal phase_changed(new_phase: int)
```

---

## 9. ComponentData Addition

```gdscript
@export var altar_ratio: float = 0.0
```

All existing `.tres` files get `altar_ratio` set. TRIGGER_ONLY components keep `altar_ratio = 0.0` (never placed in altar).

---

## 10. EnemyData Addition

```gdscript
@export var gold_min: int
@export var gold_max: int
```

Add to existing enemy `.tres` files.

---

## 11. HUD Update

Gold added to the bottom bar between HP and Phase:

```
[ HP: 80/100 ] [ 金: 150 ] [ Loops: 3 ] [ Phase: 1 觉醒 ] [ 规则槽 ... ] [ Bag [B] 3/12 ]
```

---

## 12. Out of Scope

- World pressure (auto Phase advance without buff) — Phase 4
- Enemy types 急袭者, 复制者, 先驱者 — Phase 4
- Effects 护盾, 加速, 蓄能; trigger 低血 — Phase 4
- Additional tile trigger types (完成一圈, 规则触发, 击杀) — future
- Altar buff UI showing rich details per past activation — future
