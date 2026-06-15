# AttributeLoop — Shop Service Expansion Design

**Date:** 2026-06-15
**Status:** Approved

---

## 1. Overview

Remove the `规则复制` service from the auction pool and replace it with six new services. Five of the six are permanent run-wide stat upgrades; two of those five have a per-run purchase cap (controlled via `GameConfig`) to prevent uncapped stacking.

The existing five services (词条改写, 词条融合, 敌人赦免, 删除特赦, 压力延缓) are unchanged.

---

## 2. Design Principle

**Components give combat effects. The shop sells structural upgrades that components cannot provide.**

- Lifesteal, shield, reflect, slow — these come from components.
- Base damage floor, HP ceiling, attack speed, amplify cap, slot counts — these are structural parameters that no component currently touches. The shop owns these.

---

## 3. Service Table

| Enum ID | Name | Effect | Config key |
|---------|------|--------|------------|
| 6 | 战意磨砺 | `GameState.dmg_bonus += X` | `auction_dmg_per_purchase: int = 1` |
| 7 | 筋骨强化 | `GameState.hp_max_bonus += X`; heals the delta immediately | `auction_hp_per_purchase: int = 15` |
| 8 | 迅捷折纸 | `GameState.attack_interval_bonus -= X` (floored so total interval ≥ 0.2s) | `auction_speed_delta: float = 0.05` |
| 9 | 强化潜能 | `GameState.amplify_max_stacks += X` | `auction_amplify_per_purchase: int = 1` |
| 10 | 装备槽扩容 | Appends one empty slot to `GameState.rule_slots` | `auction_rule_slot_max_purchases: int = 3` |
| 11 | 服务栏扩容 | `GameState.service_bar_max += 1` | `auction_service_bar_max_purchases: int = 3` |

Services 6–9: no purchase cap, can appear every loop.
Services 10–11: excluded from pool generation once `service_purchase_counts[type] >= config max`.

---

## 4. GameState Changes

New fields added to `GameState.gd`:

```
var dmg_bonus: int = 0
var attack_interval_bonus: float = 0.0
var service_bar_max: int = 5
var service_purchase_counts: Dictionary = {}   # service_type (int) → purchase count (int)
```

All new fields are reset to their defaults in `reset()`.

`hp_max` is modified directly when 筋骨强化 fires. `reset()` must explicitly restore it: `hp_max = DataTables.player.hp_base` (currently `reset()` does not reset `hp_max` — this line must be added).

---

## 5. CombatSystem / PlayerData Changes

`CombatSystem._apply_player_attack` currently reads `DataTables.player.dmg_base` as the raw damage value. After this change:

```gdscript
var dmg := DataTables.player.dmg_base + GameState.dmg_bonus
```

`CombatSystem.start()` currently reads `DataTables.player.attack_interval` for the player timer. After this change:

```gdscript
var interval := maxf(DataTables.player.attack_interval - GameState.attack_interval_bonus, 0.2)
_player_timer.wait_time = interval
```

`PlayerData.gd` itself is not modified — it remains the base/default values.

---

## 6. AuctionManager Changes

### Enum

Remove `RULE_COPY = 0`. Add:

```gdscript
STAT_DMG        = 6
STAT_HP         = 7
STAT_SPEED      = 8
STAT_AMPLIFY    = 9
SLOT_RULE       = 10
SLOT_SERVICE    = 11
```

### Pool Generation

`generate_pool` filters out capped services before building the candidate list:

```gdscript
var all_types: Array[int] = [...]   # all 11 types minus RULE_COPY
var available := all_types.filter(func(t):
    var cap_key = _purchase_cap(t)
    if cap_key < 0:
        return true   # no cap
    return GameState.service_purchase_counts.get(t, 0) < cap_key
)
```

`_purchase_cap(type)` returns the config max for types 10/11, and `-1` for all others.

### execute_service

New match arms:

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
    _track_purchase(params["service_type"])
ServiceType.SLOT_SERVICE:
    GameState.service_bar_max += 1
    _track_purchase(params["service_type"])
```

`_track_purchase(type)` increments `GameState.service_purchase_counts[type]`.

### Phantom Preferences

`phantom_a` currently has `RULE_COPY` in its preferred list. Replace with `STAT_DMG` and `STAT_HP`. `phantom_b` preferred type `COMP_REWRITE` is unchanged.

---

## 7. Service Bar Max

`ServiceBar` and `AuctionManager._award_service_to_player` currently hardcode `< 5`. Replace with `< GameState.service_bar_max`.

---

## 8. GameConfig New Fields

```gdscript
@export var auction_dmg_per_purchase: int = 1
@export var auction_hp_per_purchase: int = 15
@export var auction_speed_delta: float = 0.05
@export var auction_amplify_per_purchase: int = 1
@export var auction_rule_slot_max_purchases: int = 3
@export var auction_service_bar_max_purchases: int = 3
```

---

## 9. Files Changed

| File | Change |
|------|--------|
| `src/autoloads/GameState.gd` | Add 5 new fields, update `reset()` |
| `src/resources/GameConfig.gd` | Add 6 new `@export` fields |
| `src/systems/AuctionManager.gd` | Remove RULE_COPY, add 6 service types, update pool gen + execute + phantom prefs |
| `src/systems/CombatSystem.gd` | Use `dmg_bonus` and `attack_interval_bonus` |
| `src/ui/ServiceBar.gd` | Replace hardcoded `5` with `GameState.service_bar_max` |

No new files required.
