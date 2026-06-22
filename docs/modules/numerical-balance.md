# Numerical Balance Reference

This document is the authoritative reference for all numerical values in AttributeLoop, their locations, interdependencies, and change-impact rules. It was written after the June 2026 full numerical rebalance. Consult this before touching any number.

---

## 1. File Map

### 1.1 Data Files (.tres) — the actual numbers live here

| File | Class | What it holds |
|------|-------|---------------|
| `data/game_config.tres` | `GameConfig` | Global constants: scaling, economy, enrage, auction, phase config |
| `data/player_data.tres` | `PlayerData` | Player base HP, damage, attack interval, walk speed |
| `data/enemies/enemy_汲取者.tres` | `EnemyData` | Drainer base stats, gold range, component weights, drop presets |
| `data/enemies/enemy_守卫者.tres` | `EnemyData` | Guardian base stats, gold range, component weights, drop presets |
| `data/enemies/enemy_急袭者.tres` | `EnemyData` | Rusher base stats, gold range, component weights, drop presets |
| `data/enemies/enemy_复制者.tres` | `EnemyData` | Replicator base stats, gold range, component weights, drop presets |
| `data/enemies/enemy_先驱者.tres` | `EnemyData` | Vanguard base stats, gold range, component weights, drop presets |
| `data/phases/phase_1.tres` | `PhaseData` | Phase 1: loop window, spawn counts, tier weights, altar requirement |
| `data/phases/phase_2.tres` | `PhaseData` | Phase 2 config |
| `data/phases/phase_3.tres` | `PhaseData` | Phase 3 config |
| `data/phases/phase_4.tres` | `PhaseData` | Phase 4 config |
| `data/phases/phase_5.tres` | `PhaseData` | Phase 5 config |
| `data/phases/phase_6.tres` | `PhaseData` | Phase 6 (裁决前夜Boss) — last normal phase before verdict |
| `data/phases/phase_7.tres` | `PhaseData` | Verdict-loop spawn-weight table only |
| `data/drop_presets/drop_tier_01.tres` | `DropPreset` | Component value ranges for Tier 1 (common) |
| `data/drop_presets/drop_tier_02.tres` | `DropPreset` | Component value ranges for Tier 2 (uncommon) |
| `data/drop_presets/drop_tier_03.tres` | `DropPreset` | Component value ranges for Tier 3 (rare) |
| `data/components/both_治愈.tres` | `ComponentData` | Heal component base stats and growth |
| `data/components/both_反射.tres` | `ComponentData` | Reflect component base stats and growth |
| `data/components/trigger_受击.tres` | `ComponentData` | Hit Taken trigger |
| `data/components/trigger_击杀.tres` | `ComponentData` | Kill trigger |
| `data/components/trigger_完成圈数.tres` | `ComponentData` | Loop Complete trigger (TRIGGER_ONLY) |
| `data/components/trigger_经过.tres` | `ComponentData` | Tile Pass trigger |
| `data/components/trigger_低血.tres` | `ComponentData` | Low HP trigger |
| `data/components/trigger_满血.tres` | `ComponentData` | Full HP trigger |
| `data/components/trigger_规则触发.tres` | `ComponentData` | Rule Fired trigger |
| `data/components/effect_护盾.tres` | `ComponentData` | Shield effect |
| `data/components/effect_减伤.tres` | `ComponentData` | Damage Reduction effect |
| `data/components/effect_吸血.tres` | `ComponentData` | Lifesteal effect |
| `data/components/effect_强化.tres` | `ComponentData` | Amplify effect |
| `data/components/effect_增伤.tres` | `ComponentData` | Damage Boost effect |
| `data/components/effect_蓄能.tres` | `ComponentData` | Charge effect |
| `data/components/effect_灼烧.tres` | `ComponentData` | Burn effect |
| `data/components/effect_侵蚀.tres` | `ComponentData` | Erode effect |

### 1.2 Resource Scripts (.gd) — define the schema

| File | Purpose |
|------|---------|
| `src/resources/GameConfig.gd` | Schema for `game_config.tres` |
| `src/resources/PlayerData.gd` | Schema for `player_data.tres` |
| `src/resources/EnemyData.gd` | Schema for enemy .tres files |
| `src/resources/PhaseData.gd` | Schema for phase .tres files |
| `src/resources/ComponentData.gd` | Schema for component .tres files; also holds `trigger_count` runtime field |
| `src/resources/DropPreset.gd` | Schema for drop tier .tres files |

### 1.3 System Code — formulas and runtime logic

| File | Numerical responsibility |
|------|--------------------------|
| `src/systems/CombatSystem.gd` | Enrage formula, burn DOT, slow damage reduction, lifesteal, reflect, charge bonus, dmg_boost multiplier |
| `src/systems/RuleEngine.gd` | Effect scaling formula (growth_rate × pass_count), amplify multiplier, loop-end stat decay |
| `src/systems/GameLoop.gd` | Enemy stat-phase selection, tier preset rolling, component value range sampling, boss multipliers |
| `src/systems/EconomyManager.gd` | Gold drop formula |
| `src/systems/AuctionManager.gd` | Phantom buyer income, bid calculation, service execution values |
| `src/autoloads/DataTables.gd` | `calc_stat()` — the single implementation of the phase scaling formula; enemy/phase loading range |
| `src/autoloads/GameState.gd` | `get_deletion_cost()` — deletion cost progression; `reset()` — initialises all runtime stats from data |

### 1.4 Test Files

| File | What it verifies |
|------|-----------------|
| `tests/unit/test_combat_system.gd` | Damage application, enrage, reflect, burn, lifesteal, slow |
| `tests/unit/test_economy_manager.gd` | Gold drop formula and phase scaling |
| `tests/unit/test_auction_manager.gd` | Pool generation, settlement, phantom buyer bids and income |
| `tests/unit/test_game_loop.gd` | Spawn count, enemy ID picking, tile index selection, component value sampling, boss multipliers |
| `tests/unit/test_rule_engine.gd` | Trigger evaluation, effect execution, tile growth, loop-end decay |
| `tests/unit/test_game_state.gd` | Deletion cost sequence, HP management, shield absorption |
| `tests/unit/test_component_data.gd` | Component field schema |
| `tests/unit/test_phase_transition.gd` | Phase advance, verdict trigger, loop pressure window |

---

## 2. Value Dependency Graph

```
PlayerData.hp_base (200)
    └── GameState.hp_max (initial value)
        ├── RuleEngine: heal cap (min(hp + heal, hp_max))
        ├── RuleEngine: shield cap (min(shield + val, hp_max))
        ├── CombatSystem: low_hp threshold check (hp / hp_max < 0.3)
        └── AuctionManager: auction_hp_per_purchase (+15 per service)

PlayerData.dmg_base (10)
    └── CombatSystem._calc_player_dmg()
        ├── + GameState.dmg_bonus (from STAT_DMG auction service)
        ├── × (1 + dmg_boost_stacks × 0.1)
        └── × charge_stacks (charge bonus attack)

PlayerData.attack_interval (0.8s)
    └── CombatSystem._player_timer.wait_time
        └── - GameState.attack_interval_bonus (from STAT_SPEED service, min 0.2s)

GameConfig.stat_scale_factor (0.25)
    └── DataTables.calc_stat(base, phase)
        ├── Enemy.hp_max at spawn time
        ├── Enemy.dmg at spawn time
        └── Used for both normal enemies AND boss circle enemies

EnemyData.hp_base / dmg_base
    └── DataTables.calc_stat(base, phase) → spawned enemy stats
        ├── Boss multiplier: × PhaseData.boss_hp_multiplier (2.0)
        └── Boss multiplier: × PhaseData.boss_damage_multiplier (2.0)

GameConfig.combat_enrage_time (10.0)
    └── CombatSystem._check_enrage()
        └── Enrage stack 1 fires at t=10s; each further stack at +2s intervals
            └── Enrage bonus: × (1 + enrage_stacks × combat_enrage_bonus_per_stack)

GameConfig.combat_burn_dmg_per_stack (2) / combat_burn_interval (1.0)
    └── CombatSystem burn tick: dmg = burn_stacks × 2, every 1.0s

PhaseData.tier_drop_weights [85, 12, 3]
    └── GameLoop._roll_tier_preset() → selects drop_tier_01/02/03.tres
        └── DropPreset.component_ranges[id] → trigger_value and effect_value sampling range

ComponentData.effect_value / growth_rate / scale_exponent / max_scale
    └── RuleEngine._execute_effect()
        └── scaled = effect_value × (1 + growth_rate × pass_count ^ scale_exponent)
        └── actual = min(scaled, effect_value × max_scale) if max_scale > 0
        └── bonus from GameState.altar_bonuses[effect.id]
        └── multiplied by (1 + amplify_stacks × 0.5) if amplify active

EnemyData.gold_min / gold_max / gold_scale
    └── EconomyManager.calc_gold_drop(ed, phase)
        └── mult = 1.0 + (phase - 1) × gold_scale
        └── result = rand(gold_min, gold_max) × mult

GameConfig.deletion_cost_sequence [15, 35, 70] / deletion_cost_multiplier (2.0)
    └── GameState.get_deletion_cost()
        └── First 3 deletions: 15 / 35 / 70
        └── Deletion 4+: 70 × 2.0^(n - 3)

GameConfig.auction_phantom_income_per_phase [0, 20, 20, 35, 35, 55, 55]
    └── PhantomBuyer.earn(phase) — called once per loop for each phantom
        └── Two phantoms → combined 40/70/110 per phase, matches player income (spec 9.2)

GameConfig.verdict_trigger_phase (6)
    └── GameLoop._on_loop_completed()
        └── Phases 1–6 are normal (each ends its pressure window with a boss circle);
            after the phase-6 boss is beaten, the next loop_completed enters the Verdict Loop
        └── DataTables._load_phases() loads phases 1–7 (range(1, 8))
```

---

## 3. Change Impact Matrix

Use this table whenever you modify a value. The left column is the thing you changed; the right column is everything else that must be reviewed.

| If you change... | Also check... |
|-----------------|---------------|
| **`PlayerData.hp_base`** | Heal .tres effect_value ranges (does 10-15 heal still feel like ~7.5%?); Shield .tres ranges; Low HP self-damage component values; burn DOT significance per stack; enrage survivability window |
| **`PlayerData.dmg_base`** | Naked kill time for each enemy at each phase; enrage trigger time (does combat still end before 10s at Phase 1?); charge bonus damage feel; dmg_boost stack significance |
| **`PlayerData.attack_interval`** | Naked kill time for all enemies; auction_speed_delta relevance (is -0.05s per purchase still meaningful relative to 0.8s?); min clamp at 0.2s still safe |
| **`GameConfig.stat_scale_factor`** | All enemy kill times at all phases; gold drop scaling (does income keep pace with difficulty?); Phase 3+ "rules mandatory" checkpoint — validate with spec tables |
| **`EnemyData.hp_base` or `dmg_base`** | Naked kill time (target 8-12s for that enemy); enrage trigger time (must fire before the fight would naturally end); gold_min/gold_max (drops should feel proportional to fight difficulty); boss multiplier outcome |
| **`EnemyData.gold_min/gold_max/gold_scale`** | Per-loop gold income vs phantom buyer income (both phantoms combined earn 40/70/110 per phase — player should be competitive); deletion cost affordability progression |
| **`GameConfig.combat_enrage_time`** | When the fight runs past this, enrage starts stacking. Set to 10s deliberately: the longest normal naked kill is Guardian at ~12s, so a Guardian fight trips 1-2 enrage stacks near the end — intended pressure on the tankiest enemy, not a bug. Rusher (5s) and Drainer (8s) finish well before it. Re-check this if any enemy's naked kill time drops below 10s (enrage would never fire) or rises far above 12s (enrage would stack heavily during normal fights) |
| **`GameConfig.combat_enrage_bonus_per_stack`** | Enrage curve shape; at what stack count does sustain become impossible? Validate with spec Section 6 table |
| **`GameConfig.combat_burn_dmg_per_stack`** | Burn DPS relative to enemy HP; burn .tres effect_value ranges (how many stacks is "meaningful"?); interaction with enrage |
| **`PhaseData.tier_drop_weights`** | Component power curve by phase; player rule power growth; if Tier 3 rate rises too fast, fights become trivial before stat scaling catches up |
| **`PhaseData.world_pressure_window`** | Total loops per phase; total game length estimate; altar requirement feasibility within the window |
| **`PhaseData.spawn_count_min/max`** | Gold income per loop (more enemies = more gold); player HP attrition per loop; component collection rate |
| **`PhaseData.boss_hp_multiplier` / `boss_damage_multiplier`** | Boss survivability; boss as gate — too easy = no tension, too hard = wall. Cross-check with player DPS and heal values at that phase |
| **`PhaseData.enemy_component_count_min/max`** | Number of rule pairs per enemy at this phase (spec 5.1); the primary lever for the late-game enemy power curve. Boss adds `+2` on top (`GameLoop._BOSS_RULE_PAIR_BONUS`, spec 7.4) |
| **`PhaseData.component_weight_modifiers`** | Which components appear more often in that phase; emergent enemy strategies |
| **`DropPreset.component_ranges` (trigger values)** | Frequency of effect firing; lower trigger N = more frequent, higher effect throughput. Cross-check against enrage timeline |
| **`DropPreset.component_ranges` (effect values)** | Effect magnitude at each tier; scaling formula ceiling; heal/shield significance vs HP baseline |
| **`ComponentData.growth_rate`** | Tile rule power at late game (30+ loops); validate with spec Section 4.5 growth table |
| **`ComponentData.max_scale`** | Ceiling on tile rule growth; prevents tile rules from trivially winning the game at Phase 6 |
| **`ComponentData.altar_ratio`** | How efficiently a component contributes to altar requirement; affects strategic trade-off between inventory use and phase advancement |
| **`GameConfig.deletion_cost_sequence`** | First-deletion cost must be achievable early (Phase 1 loop = ~25-45g); third deletion cost should feel punishing but reachable |
| **`GameConfig.deletion_cost_multiplier`** | Exponential cost growth after third deletion; ensures inventory management is a real constraint |
| **`GameConfig.verdict_trigger_phase`** | Update `DataTables._load_phases()` range — phases are loaded up to `verdict_enemy_phase + 1` (currently range(1, 8)); update `auction_phantom_income_per_phase` array length to match |
| **`GameConfig.auction_phantom_income_per_phase`** | Array index is clamped to `[1, size-1]`, so array length must cover all phases including verdict; phantom competitiveness vs player income |
| **`GameConfig.auction_phantom_a_spend_ratio`** | Phantom A aggressiveness; how often player loses stat services to phantom |
| **`GameConfig.auction_phantom_b_threshold` / `allin_ratio`** | Phantom B saving behavior; how often player gets component services cheaply vs contested |
| **`GameConfig.auction_dmg_per_purchase` / `hp_per_purchase` / `speed_delta` / `amplify_per_purchase`** | Auction service value proposition; compare against equivalent component effect values |
| **Adding a new Phase** | Add `phase_N.tres`; update `DataTables._load_phases()` range; update `GameConfig.verdict_trigger_phase`; update `auction_phantom_income_per_phase` array |
| **Adding a new Enemy** | Add `enemy_X.tres` with trigger_weights, effect_weights, gold range, and phase_drop_presets; add enemy id to `DataTables._load_enemies()`; add to relevant `PhaseData.spawn_weights`; set `unlock_phase` correctly |
| **Adding a new Component** | Add `.tres` file; add path to `DataTables._load_components()`; add `component_ranges` entry in all three `drop_tier_XX.tres` presets; add to enemy `trigger_weights` and `effect_weights` in all enemy .tres files; add effect execution branch in `RuleEngine._execute_effect()`; if combat-only, add to `RuleEngine.COMBAT_TILE_EFFECTS` and handle in `CombatSystem._on_rule_fired()` or `_execute_enemy_effect()` |

---

## 4. Key Formulas Reference

### 4.1 Enemy Stat Scaling

**Location**: `src/autoloads/DataTables.gd:70` (`calc_stat`)

```
scaled_stat = int(base_stat × (1.0 + stat_scale_factor) ^ (phase - 1))
```

- `stat_scale_factor = 0.25` (in `game_config.tres`)
- **Compound** growth — the multiplier table below is `1.25^(phase-1)`, not linear.
  This is intentional: late-game stats rise sharply so raw attacks can't keep up and
  rule combinations become mandatory by Phase 3+ (spec §3).
- Applied at spawn time; boss multipliers stack on top

**Phase multipliers**:
| Phase | Multiplier |
|-------|-----------|
| 1 | ×1.00 |
| 2 | ×1.25 |
| 3 | ×1.56 |
| 4 | ×1.95 |
| 5 | ×2.44 |
| 6 | ×3.05 |

### 4.2 Gold Drop

**Location**: `src/systems/EconomyManager.gd:13` (`calc_gold_drop`)

```
mult = 1.0 + (phase - 1) × enemy.gold_scale
drop = int(rand(gold_min, gold_max) × mult)
```

- `gold_scale` is per-enemy (0.4 for all enemies). Tuned so the continuous formula
  lands inside spec 9.1's bracket table at each phase — `1 + (phase-1) × 0.4` ≈
  ×1.0/1.4/1.8/2.2/2.6/3.0 vs spec brackets P1-2/P3-4/P5-6 (the spec's flat
  brackets can't be matched exactly by a linear scale; 0.4 is the least-error
  single value, vs the old 0.3 which undershot late game by ~30%).

### 4.3 Player Damage

**Location**: `src/systems/CombatSystem.gd:199` (`_calc_player_dmg`)

```
dmg = PlayerData.dmg_base + GameState.dmg_bonus
if dmg_boost_stacks > 0:
    # 增伤 is capped the same way as 减伤/slow: mini(phase + 1, 8) effective stacks.
    var stack_cap = mini(current_phase + 1, 8)
    var capped = mini(dmg_boost_stacks, stack_cap)
    dmg = int(dmg × (1.0 + capped × 0.1))
```

Raw `dmg_boost_stacks` can still accumulate past the cap (e.g. from frequent tile-pass
rules), but only the capped count feeds the multiplier, and the surplus is brought back
down by the per-loop decay (see 4.x below). This mirrors `slow_stacks`, which is also
uncapped in storage but capped in the damage formula.

### 4.4 Charge Bonus Damage

**Location**: `src/systems/CombatSystem.gd:206` (`_calc_charge_bonus`)

```
charge_bonus = charge_stacks × _calc_player_dmg()
```

Charge stacks are consumed and dealt as bonus damage on the next player attack.

### 4.5 Tile Effect Scaling (Growth Formula)

**Location**: `src/systems/RuleEngine.gd:121` (`_execute_effect`)

```
exponent = effect.scale_exponent  (default 1.0)
scale_factor = 1.0 + effect.growth_rate × pow(pass_count, exponent)
scaled = effect.effect_value × scale_factor
actual = min(scaled, effect.effect_value × effect.max_scale)  # if max_scale > 0
final_value = actual + GameState.altar_bonuses.get(effect.id, 0.0)
if amplify active:
    final_value *= (1.0 + amplify_stacks × 0.5)
```

- Player rule slots always use `pass_count = 0` (no growth)
- Tile rules use `age = tile.pass_count - slot.placed_pass`, where `placed_pass`
  is stamped when the effect is placed on the tile. Growth counts from **effect
  placement**, not the tile's total pass count — so a rule placed on an
  already-worn tile starts at age 0 and grows from there. `placed_pass` defaults
  to 0 for rules present at game start (easy presets) and is reset whenever an
  effect is (re)placed via `TileRulePanel` or copied via `Tile.copy_rule_to`.
  The trigger rhythm (`tile.pass_count % N`) still uses the tile's total
  pass_count — only the growth input changed.

**Growth rates by component**:
| Component | growth_rate | ×30 loops approx |
|-----------|------------|------------------|
| 治愈 (Heal) | 0.15 | ×5.5 |
| 护盾 (Shield) | 0.12 | ×4.6 |
| 反射 (Reflect) | 0.10 | ×4.0 |
| 侵蚀 (Erode) | 0.10 | ×4.0 |
| 吸血 (Lifesteal) | 0.08 | ×3.4 |
| 灼烧 (Burn) | 0.05 | ×2.5 |
| All stack effects | 0.0 | ×1.0 (fixed) |

### 4.6 Enrage

**Location**: `src/systems/CombatSystem.gd:79` (`_check_enrage`)

```
threshold = combat_enrage_time + enrage_stacks × combat_enrage_interval
if enrage_timer >= threshold:
    enrage_stacks += 1
```

Enemy damage per attack with enrage:
```
dmg = int(base_dmg × (1.0 + enrage_bonus_per_stack × enrage_stacks))
```

- `combat_enrage_time = 10.0s` — first stack at 10s
- `combat_enrage_interval = 2.0s` — each subsequent stack every 2s
- `combat_enrage_bonus_per_stack = 0.30` — +30% base damage per stack

### 4.7 Burn DOT

**Location**: `src/systems/CombatSystem.gd:67` (in `_process`)

```
every combat_burn_interval (1.0s):
    burn_dmg = burn_stacks × combat_burn_dmg_per_stack (2)
    enemy.take_damage(burn_dmg)
```

### 4.8 Slow (Damage Reduction)

**Location**: `src/systems/CombatSystem.gd:107` (player attack) and `144` (enemy attack)

```
stack_cap = min(current_phase + 1, 8)
capped = min(slow_stacks, stack_cap)
dmg = int(dmg × (1.0 - capped × 0.1))
```

Each stack reduces damage by 10%, capped at min(phase+1, 8) effective stacks.

### 4.9 Tier Drop Probability

**Location**: `src/systems/GameLoop.gd:182` (`_roll_tier_preset`)

```
roll = rand(1, sum(tier_drop_weights))
select tier whose cumulative weight >= roll
```

`tier_drop_weights` is in `PhaseData` — e.g., `[85, 12, 3]` for Phase 1.

### 4.10 Component Value Sampling

**Location**: `src/systems/GameLoop.gd:210` (`_create_component`)

```
trigger_value = rand_int(preset.component_ranges[id].trigger.x,
                          preset.component_ranges[id].trigger.y)
effect_value  = rand_float(preset.component_ranges[id].effect.x,
                            preset.component_ranges[id].effect.y)
```

Values come from the `DropPreset` matching the rolled tier (1/2/3).

### 4.10b Bonus 经过 Loot

**Location**: `src/systems/GameLoop.gd` (`_append_bonus_pair`, called from `spawn_enemies`)

Tile rules require a 经过 trigger, but 经过 sits in the enemy `trigger_weights`
"Others" bucket at weight 3 — too low to keep tiles supplied (≈1 经过 drop per
phase). To keep tiles viable without weakening enemies or distorting drop
weights, every other loop (`loops_completed % 2 == 1`) the first spawned enemy
gets a bonus pair appended to its components:

```
enemy.components.append(_create_component("经过", preset))   # tile-enabling trigger
enemy.components.append(_create_component(<random effect>, preset))
```

The pair is **inert for the enemy** — 经过 is never evaluated as an enemy trigger
(only 受击/低血/满血/规则触发 are), so it never fires — but it appears in the
strip panel so the player can take it. Yields ≈1 bonus 经过 every 2 loops.

### 4.11 Deletion Cost

**Location**: `src/autoloads/GameState.gd:154` (`get_deletion_cost`)

```
if deletion_count < len(sequence):
    return sequence[deletion_count]   # [15, 35, 70]
else:
    cost = 70
    for i in (deletion_count - (len(sequence) - 1)):
        cost = int(cost × deletion_cost_multiplier)  # ×2 each time
    return cost
```

Deletion 4 = 140, 5 = 280, 6 = 560, ...

### 4.12 Boss Multipliers

**Location**: `src/systems/GameLoop.gd:227` (`_apply_boss_modifiers`)

```
enemy.hp_max = int(enemy.hp_max × phase_data.boss_hp_multiplier)    # 2.0
enemy.hp     = enemy.hp_max
enemy.dmg    = int(enemy.dmg    × phase_data.boss_damage_multiplier) # 2.0
enemy.scale  = Vector2.ONE × phase_data.boss_scale                   # 1.6
```

Bosses also get `+2` rule pairs on top of the phase's `enemy_component_count_min/max`
via `GameLoop._BOSS_RULE_PAIR_BONUS` (spec 7.4). The bonus is applied in
`_assign_components(..., _BOSS_RULE_PAIR_BONUS)` at the boss-spawn call site,
not inside `_apply_boss_modifiers`.

### 4.13 Loop-End Stat Decay

**Location**: `src/systems/RuleEngine.gd:71` (`_on_loop_completed`)

```
decay = ceil(current_phase / 2.0)
slow_stacks      = max(0, slow_stacks - decay)
shield           = int(shield × 0.65)
dmg_boost_stacks = max(0, dmg_boost_stacks - decay)
```

`增伤` and `减伤` share the same phase-scaled decay (`ceil(phase / 2)`), so neither
snowballs across loops. 增伤 is additionally capped in the damage formula
(`mini(phase + 1, 8)` effective stacks — see 4.3).

### 4.14 Auction Phantom Income

**Location**: `src/systems/AuctionManager.gd:287` (`PhantomBuyer.earn`)

```
income_table = config.auction_phantom_income_per_phase
              # [0, 20, 20, 35, 35, 55, 55]
gold += income_table[clamp(phase, 1, len(income_table) - 1)]
```

Both phantoms earn once per loop end. Values are **per-phantom**: with two
phantoms the combined phantom budget per loop is 40 / 40 / 70 / 70 / 110 / 110,
which matches the player's per-loop gold income by phase (spec 9.2). Halving the
per-phantom table from the earlier [0,40,40,70,70,110,110] fixed a 2× phantom
overbid that let phantoms dominate every auction.

**Preferred types & interest (spec 9.4).** `preferred_types` is set in
`AuctionManager._ready`, not in config. Shadow A (AGGRESSIVE) prefers
`STAT_DMG / STAT_HP / STAT_SPEED / SLOT_RULE`; Shadow B (PATIENT) prefers
`COMP_REWRITE / COMP_MERGE / STAT_AMPLIFY / SLOT_SERVICE`. `interest()` returns
0–3 (无/低/中/高) for the UI label. B returns **1 (低)** for non-preferred
services — not 0 — because B still token-bids 10-20g on them (spec 9.4 "Others
weight 3" = low). Returning 0 would display "无竞拍意愿" while B actually bids,
misleading the player.

### 4.15 Comp Merge Formula

**Location**: `src/systems/AuctionManager.gd:176` (`execute_service`)

```
merged.effect_value  = (a.effect_value  + b.effect_value)  × auction_comp_merge_ratio  (0.8)
merged.trigger_value = (a.trigger_value + b.trigger_value) × auction_comp_merge_ratio  (0.8)
```

### 4.16 Amplify Multiplier

**Location**: `src/systems/RuleEngine.gd:133` (`_execute_effect`)

```
if effect.id != "强化" and amplify_stacks > 0:
    final_value *= (1.0 + amplify_stacks × 0.5)
    amplify_stacks = 0
```

Amplify multiplier per stack = 0.5 (hardcoded in RuleEngine, not in GameConfig).

---

## 5. Testing

### 5.1 Run All Unit Tests

```bash
cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
```

All 80 tests must pass before any change is considered complete.

### 5.2 Test-to-System Coverage Map

| Test File | Systems Covered |
|-----------|----------------|
| `test_combat_system.gd` | `CombatSystem` formulas: player/enemy damage, shield, slow, reflect, lifesteal, burn, enrage, charge |
| `test_economy_manager.gd` | `EconomyManager.calc_gold_drop` — phase scaling, gold addition to GameState |
| `test_auction_manager.gd` | Pool generation, settlement logic, phantom bid calculation, phantom income, service execution |
| `test_game_loop.gd` | Spawn count, enemy selection, tile index picking, weighted component picking, boss multipliers, component value sampling |
| `test_rule_engine.gd` | Trigger evaluation, all effect branches, tile growth scaling, loop-end decay |
| `test_game_state.gd` | Deletion cost sequence, HP management, shield absorption, inventory operations |
| `test_phase_transition.gd` | Phase advance conditions, verdict trigger, world pressure window, boss circle |
| `test_component_data.gd` | ComponentData schema validation |
| `test_data_tables.gd` | Loading all .tres assets, `calc_stat` formula |

### 5.3 What to Validate After Common Changes

**After changing any GameConfig value**: Run `test_combat_system.gd`, `test_auction_manager.gd`, `test_game_state.gd`.

**After changing any EnemyData**: Run `test_combat_system.gd`, `test_economy_manager.gd`, `test_game_loop.gd`. Manually verify kill time in editor against 8-12s target.

**After changing any PhaseData**: Run `test_game_loop.gd`, `test_phase_transition.gd`.

**After changing any DropPreset or ComponentData**: Run `test_game_loop.gd` (component sampling), `test_rule_engine.gd` (effect execution).

**After adding a new component or enemy**: Run the full suite — new assets affect almost every system.
