# AttributeLoop — Numerical Balance Redesign

## Overview

A complete numerical rebalance of AttributeLoop, anchored on the target combat duration of 8-12 seconds per normal fight. The core design philosophy: **rule combinations are ~90% of player power**; raw stat growth provides a baseline but never decides fights on its own.

## Design Principles

1. **Combat tempo anchor**: Normal fights last 8-12 seconds
2. **Rules as core growth**: Player strength comes from trigger+effect combinations, not stat scaling
3. **Three-way component tension**: Every good component can be placed on a tile (long-term investment), equipped on the player (immediate tactical use), or sacrificed at the altar (phase advancement)
4. **Readable numbers**: HP 200 base — a 15 HP heal is visibly 7.5%, a 20 HP shield blocks ~7 hits
5. **Soft anti-stall**: Enrage uses linear growth, not exponential — fights get harder over time but don't cliff

---

## 1. Player Base Stats

| Property | Value |
|----------|-------|
| HP | 200 |
| Attack | 10 |
| Attack Interval | 0.8s |
| DPS | 12.5/s |
| Walk Speed | 120 px/s |
| Inventory Capacity | 12 |
| Starting Rule Slots | 2 |
| Max Rule Slots | 5 |

---

## 2. Enemy Base Stats (Phase 1)

| Enemy | HP | Attack | Attack Interval | DPS | Kill Time (naked) | Personality |
|-------|-----|--------|-----------------|-----|-------------------|-------------|
| Drainer (汲取者) | 100 | 3 | 1.0s | 3.0 | 8s | Sustain — heals and drains over time |
| Guardian (守卫者) | 150 | 2 | 1.4s | 1.4 | 12s | Tank — hard to damage, low threat |
| Rusher (急袭者) | 60 | 5 | 0.7s | 7.1 | 5s | Burst — high damage, fragile |
| Replicator (复制者) | 80 | 3 | 0.9s | 3.3 | 6.5s | Combo — complex rule chains |
| Vanguard (先驱者) | 180 | 2 | 1.2s | 1.7 | 14s | All-rounder — most rule pairs |

### Combat Validation (Phase 1, no rules)

- **Drainer**: 8s fight, player takes 24 damage (12% HP) — comfortable ✓
- **Rusher**: 5s fight, player takes 35 damage (17.5% HP) — painful but survivable ✓
- **Guardian**: 12s fight, player takes 17 damage (8.5% HP) — slow but safe ✓
- **One loop (3× Drainer)**: 72 damage total (36% HP) — 2-3 loops naked before death, gives learning window ✓

---

## 3. Enemy Stat Scaling

**Formula**: `stat = base_stat × (1.0 + 0.25) ^ (phase - 1)` (compound)

| Phase | Multiplier | Drainer HP | Drainer Attack | Naked Kill Time |
|-------|-----------|------------|----------------|-----------------|
| 1 | ×1.00 | 100 | 3 | 8s |
| 2 | ×1.25 | 125 | 4 | 10s |
| 3 | ×1.56 | 156 | 5 | 12.5s |
| 4 | ×1.95 | 195 | 6 | 15.6s |
| 5 | ×2.44 | 244 | 7 | 19.5s |
| 6 | ×3.05 | 305 | 9 | 24.4s |

**Design intent**: By Phase 3, naked attacks can't kill within the 8-12s target — rules become mandatory. By Phase 5, no build = certain death.

---

## 4. Component System

### 4.1 Classification

All 17 components have `slot_type = BOTH` except 完成圈数 (TRIGGER_ONLY).

- **10 effect components**: Can be used as T (fires when that effect occurs N times) or E (executes the effect)
- **6 trigger components**: Can be used as T (fires on event) or E (has a unique effect behavior)
- **1 pure trigger**: 完成圈数 (fires on N loops completed, no E behavior)

### 4.2 Tier Drop Probabilities

| Phase | Tier 1 | Tier 2 | Tier 3 |
|-------|--------|--------|--------|
| 1 | 85% | 12% | 3% |
| 2 | 70% | 25% | 5% |
| 3 | 40% | 50% | 10% |
| 4 | 20% | 55% | 25% |
| 5 | 10% | 40% | 50% |
| 6 (Verdict) | 5% | 30% | 65% |

### 4.3 Trigger Values (as T — fires every N occurrences)

| Component | Event | Frequency | Tier 1 | Tier 2 | Tier 3 |
|-----------|-------|-----------|--------|--------|--------|
| 受击 (Hit) | Attacked | Very high | 4-6 | 3-5 | 2-4 |
| 经过 (Passage) | Tile passed | High (12/loop) | 5-8 | 4-6 | 3-5 |
| 规则触发 (Rule Trigger) | Other rules fire | High | 5-8 | 4-6 | 3-5 |
| 治愈 (Heal) | Heal occurs | Medium | 3-4 | 2-3 | 2 |
| 护盾 (Shield) | Shield absorbs | Medium | 3-4 | 2-3 | 2 |
| 吸血 (Lifesteal) | Lifesteal heals | Medium | 3-4 | 2-3 | 2 |
| 低血 (Low HP) | HP < 30%, per N sec | Conditional | 3-4 | 2-3 | 2 |
| 满血 (Full HP) | HP = max, per N sec | Conditional | 3-4 | 2-3 | 2 |
| 反射 (Reflect) | Reflect occurs | Medium-low | 2-3 | 2 | 1-2 |
| 减伤 (Damage Reduction) | DR applied | Medium-low | 2-3 | 2 | 1-2 |
| 强化 (Amplify) | Amplify consumed | Low | 2-3 | 2 | 1-2 |
| 增伤 (Damage Boost) | Boost consumed | Low | 2-3 | 2 | 1-2 |
| 蓄能 (Charge) | Charge released | Low | 2-3 | 2 | 1-2 |
| 灼烧 (Burn) | Burn applied | Medium-low | 2-3 | 2 | 1-2 |
| 侵蚀 (Erode) | Erode applied | Medium-low | 2-3 | 2 | 1-2 |
| 击杀 (Kill) | Enemy killed | Low (2-3/loop) | 2-3 | 1-2 | 1 |
| 完成圈数 (Loop Complete) | Loop completed | Very low (1/loop) | 2 | 1-2 | 1 |

### 4.4 Effect Values (as E)

#### One-time value effects

| Component | Effect | Tier 1 | Tier 2 | Tier 3 | Growth Rate |
|-----------|--------|--------|--------|--------|-------------|
| 治愈 (Heal) | Restore HP | 10-15 | 20-30 | 35-50 | 0.15 |
| 护盾 (Shield) | Gain shield | 12-20 | 25-40 | 45-65 | 0.12 |
| 侵蚀 (Erode) | Reduce enemy max HP | 5-10 | 15-25 | 30-45 | 0.10 |

#### Ratio effects

| Component | Effect | Tier 1 | Tier 2 | Tier 3 | Growth Rate |
|-----------|--------|--------|--------|--------|-------------|
| 反射 (Reflect) | Reflect damage % | 0.15-0.25 | 0.30-0.45 | 0.50-0.70 | 0.10 |
| 吸血 (Lifesteal) | Damage → heal % | 0.08-0.15 | 0.20-0.30 | 0.35-0.50 | 0.08 |

#### Stack effects

| Component | Effect | Tier 1 | Tier 2 | Tier 3 | Growth Rate |
|-----------|--------|--------|--------|--------|-------------|
| 减伤 (Damage Reduction) | -10% enemy dmg/stack | 1 | 1-2 | 2-4 | 0 |
| 增伤 (Damage Boost) | +10% player dmg/stack | 1 | 2-3 | 3-5 | 0 |
| 蓄能 (Charge) | Store stacks, release as bonus attacks | 1 | 1-2 | 2-3 | 0 |
| 灼烧 (Burn) | 2 dmg/stack/sec DOT | 1-2 | 3-4 | 5-8 | 0.05 |
| 强化 (Amplify) | Next effect ×(1 + stacks × 0.5) | 1 | 1 | 1 | 0 |

#### Self-damage / special effects

| Component | Effect | Tier 1 | Tier 2 | Tier 3 | Growth Rate |
|-----------|--------|--------|--------|--------|-------------|
| 受击 (Hit) | Damage self | 3-5 | 8-15 | 18-30 | 0 |
| 低血 (Low HP) | Damage self (lighter) | 2-3 | 5-8 | 10-18 | 0 |
| 击杀 (Kill) | Deal % of enemy current HP | 5-8% | 12-18% | 22-35% | 0 |

#### Fixed-behavior effects (no numerical value)

| Component | Effect Behavior |
|-----------|----------------|
| 满血 (Full HP) | +1 to existing charge/dmg_boost/amplify stacks |
| 经过 (Passage) | Re-trigger current tile's rules |
| 规则触发 (Rule Trigger) | +1 trigger_count to all rules |

### 4.5 Tile Growth Formula

```
final_value = base_value × (1.0 + growth_rate × pass_count ^ scale_exponent)
```

Player rule slots always use `pass_count = 0` (no growth). Tile rules use
`age = tile.pass_count - slot.placed_pass` — growth counts from when the effect
was placed on the tile, not the tile's total pass count (so a rule placed on an
already-worn tile starts at age 0).

**Growth rate summary and 30-loop multiplier:**

| Effect | Growth Rate | ×30 loops | Design Reason |
|--------|------------|-----------|---------------|
| Heal | 0.15 | ×5.5 | Primary recovery, high growth |
| Shield | 0.12 | ×4.6 | Strong but decays 35%/loop |
| Reflect | 0.10 | ×4.0 | Ratio effect, can't exceed 100% |
| Erode | 0.10 | ×4.0 | Anti-tank special, moderate growth |
| Lifesteal | 0.08 | ×3.4 | Multiplicative with attack, implicit growth |
| Burn | 0.05 | ×2.5 | Stack-based, too fast would dominate |
| Others | 0 | ×1.0 | Stack effects are fixed values |

### 4.6 Chain Combos

Self-referencing rule chains (e.g., Heal T → Heal E → triggers Heal T again) are a **feature**, not a bug. Natural balance:

- **Slot cost**: Building a self-loop consumes multiple rule slots, leaving fewer for damage or defense
- **Enrage**: Sustain loops that don't kill the enemy will eventually be overwhelmed by linear enrage
- **Minimum trigger threshold**: No trigger value of 1 exists, preventing trivial infinite loops

---

## 5. Enemy Rule Preferences

### 5.1 Rule Pair Count by Phase

| Phase | Min Pairs | Max Pairs |
|-------|-----------|-----------|
| 1 | 1 | 2 |
| 2 | 2 | 2 |
| 3 | 2 | 3 |
| 4 | 3 | 3 |
| 5 | 3 | 4 |
| 6 (Verdict) | 4 | 4 |

### 5.2 Component Weight Tables

Each enemy type has separate T-weight and E-weight for every component. When generating a rule pair, one component is drawn from the T-weight pool and one from the E-weight pool.

#### Drainer (汲取者) — Sustain

| Component | T Weight | E Weight |
|-----------|----------|----------|
| 受击 | 30 | 5 |
| 吸血 | 20 | 30 |
| 治愈 | 15 | 25 |
| 低血 | 15 | 5 |
| 灼烧 | 5 | 15 |
| 护盾 | 5 | 10 |
| Others (each) | 3 | 3 |

#### Guardian (守卫者) — Defense

| Component | T Weight | E Weight |
|-----------|----------|----------|
| 受击 | 25 | 5 |
| 护盾 | 20 | 30 |
| 满血 | 15 | 5 |
| 治愈 | 10 | 20 |
| 减伤 | 10 | 25 |
| 反射 | 5 | 10 |
| Others (each) | 3 | 3 |

#### Rusher (急袭者) — Burst

| Component | T Weight | E Weight |
|-----------|----------|----------|
| 击杀 | 20 | 5 |
| 增伤 | 20 | 25 |
| 受击 | 15 | 5 |
| 蓄能 | 15 | 25 |
| 灼烧 | 10 | 20 |
| 强化 | 5 | 10 |
| Others (each) | 3 | 3 |

#### Replicator (复制者) — Combo

| Component | T Weight | E Weight |
|-----------|----------|----------|
| 规则触发 | 25 | 5 |
| 治愈 | 15 | 15 |
| 反射 | 15 | 20 |
| 强化 | 15 | 20 |
| 灼烧 | 10 | 15 |
| 侵蚀 | 5 | 15 |
| Others (each) | 3 | 3 |

#### Vanguard (先驱者) — All-rounder

| Component | T Weight | E Weight |
|-----------|----------|----------|
| All 16 BOTH components | ~6 each | ~6 each |

Uniform distribution — unpredictable, the "final exam" enemy.

---

## 6. Enrage System (Anti-Stall)

| Parameter | Value |
|-----------|-------|
| Trigger Time | 10 seconds into combat |
| Stack Interval | 2 seconds |
| Per-stack bonus | +30% base damage (linear) |

**Enrage curve (Drainer Phase 1, base attack 3):**

| Time | Stacks | Total Attack | Feel |
|------|--------|-------------|------|
| 0-10s | 0 | 3 | Normal |
| 12s | 1 | 3.9 | Slight pressure |
| 14s | 2 | 4.8 | Noticeable |
| 16s | 3 | 5.7 | Painful |
| 18s | 4 | 6.6 | Critical |
| 20s | 5 | 7.5 | Sustain builds fail |

Compared to old exponential system (1.5^n): 16s old = 10.1 attack vs new = 5.7 — much more predictable.

---

## 7. Phase System

### 7.1 Phase Table

| Phase | Name | Loop Window | Enemies/Loop | Altar Req | New Enemy |
|-------|------|------------|-------------|-----------|-----------|
| 1 | 觉醒 | 8 | 2-3 | 2 | Drainer, Guardian |
| 2 | 涌动 | 7 | 2-3 | 3 | Rusher |
| 3 | 侵蚀 | 6 | 3 | 4 | Replicator |
| 4 | 失衡 | 5 | 3-4 | 5 | Vanguard |
| 5 | 裁决前夜 | 4 | 3-4 | 6 | — |
| 6 | 裁决 | Survive 5 | 5-6 | — | — |

### 7.2 Design Intent

- **Total altar cost**: 2+3+4+5+6 = 20 components sacrificed to reach Verdict
- **Total loops**: ~35 loops (8+7+6+5+4+5) ≈ 30-35 minutes
- **Difficulty scaling**: Primarily through enemy quality (better rules, higher tier components), not quantity
- **Enemy count**: Stable early (2-3) for component collection, slight increase late (3-4), spike at Verdict (5-6)

### 7.3 World Pressure

If the player fails to fill the altar within the loop window:
- Phase advances automatically WITHOUT altar buff
- Punishment: difficulty increases but player gets no reward

### 7.4 Boss Circle

Before each normal phase advance (Phase 1-5):
- A single boss enemy spawns at the last tile
- Boss multipliers: HP ×2.0, Attack ×2.0, Rule pairs +2
- Phase advances after boss is defeated

---

## 8. Tile System

### 8.1 Track Layout

13 tiles total (1 altar + 12 normal). Tile rule slot distribution:

| Tile | 0 (Altar) | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
|------|-----------|---|---|---|---|---|---|---|---|---|----|----|-----|
| Slots | Special | 1 | 2 | 1 | 3 | 2 | 1 | 2 | 3 | 1 | 2 | 3 | 2 |

Total: 23 tile rule slots available.

### 8.2 Unified Pass Trigger

All tile rules trigger when the player **passes** the tile:
- **Non-combat effects** (Heal, Shield, etc.): Always trigger on pass
- **Combat effects** (Lifesteal, Reflect, Burn, Erode): Only trigger if the tile has an enemy present

### 8.3 Loop-end Decay

| Stat | Decay Formula |
|------|--------------|
| Slow stacks | `max(0, stacks - ceil(phase / 2.0))` |
| Shield | `shield × 0.65` |
| Damage boost stacks | `max(0, stacks - ceil(phase / 2.0))` |

`增伤` and `减伤` share the same phase-scaled decay (`ceil(phase / 2)`) so neither
buff nor debuff snowballs across loops. `增伤` is additionally capped in the damage
formula (`mini(phase + 1, 8)` effective stacks — see 4.3).

---

## 9. Economy System

### 9.1 Gold Income (Enemy Kill Drops)

Gold drops scale with phase bracket, not component tier.

| Enemy | Phase 1-2 | Phase 3-4 | Phase 5-6 |
|-------|-------------------|-------------------|-------------------|
| Drainer | 8-15 | 15-25 | 25-40 |
| Guardian | 10-18 | 18-30 | 30-45 |
| Rusher | 15-25 | 25-40 | 40-60 |
| Replicator | 12-20 | 20-35 | 35-50 |
| Vanguard | 18-30 | 30-50 | 50-75 |

**Per-loop income estimates:**
- Phase 1: ~25-45 gold/loop
- Phase 3: ~55-90 gold/loop
- Phase 5: ~100-170 gold/loop

### 9.2 Phantom Buyer Income

| Phase | Income/Loop (both phantoms combined) | Per phantom |
|-------|--------------------------------------|-------------|
| 1-2 | 40 gold | 20 |
| 3-4 | 70 gold | 35 |
| 5-6 | 110 gold | 55 |

`auction_phantom_income_per_phase = [0, 20, 20, 35, 35, 55, 55]` — each phantom
earns the per-phantom value once per loop, so two phantoms combined match the
player's per-loop gold income by phase.

Design: Player income ≈ phantom income (combined) — cannot outbid everything, must choose strategically.

### 9.3 Component Deletion Costs

| Deletion # | 1 | 2 | 3 | 4 | 5 | 6+ |
|-----------|---|---|---|---|---|-----|
| Cost | 15 | 35 | 70 | 140 | 280 | ×2 |

### 9.4 Phantom Buyer Preferences

#### Shadow A — Aggressive (激进型)

Spends ~75% budget per loop. Prefers direct stat upgrades.

| Service | Weight |
|---------|--------|
| 战意磨砺 (+Attack) | 30 |
| 筋骨强化 (+HP) | 25 |
| 迅捷折纸 (-Attack Interval) | 20 |
| 装备槽扩容 (+Rule Slot) | 10 |
| Others (each) | 3 |

#### Shadow B — Patient (蓄势型)

Below 200g: bids 10-20g symbolically. At 200g+ when priority appears: bids 80%+. After 5 loops without priority: spends 60% on best alternative.

| Service | Weight |
|---------|--------|
| 词条改写 (Comp Rewrite) | 35 |
| 词条融合 (Comp Merge) | 25 |
| 强化潜能 (+Amplify Cap) | 15 |
| 服务栏扩容 (+Service Slot) | 10 |
| Others (each) | 3 |

---

## 10. Auction Services — Numerical Values

| Service | Value | Notes |
|---------|-------|-------|
| 战意磨砺 (+Attack) | +2 | 20% of base 10; meaningful but not decisive |
| 筋骨强化 (+HP) | +15 | 7.5% of base 200 |
| 迅捷折纸 (-Attack Interval) | -0.05s | From 0.8s, min 0.2s, max 12 purchases |
| 强化潜能 (+Amplify Cap) | +1 | Unchanged |
| 装备槽扩容 (+Rule Slot) | +1 (max 3 purchases) | Unchanged |
| 服务栏扩容 (+Service Slot) | +1 (max 3 purchases) | Unchanged |
| 词条改写 | N ±1 or E +50% | Unchanged |
| 词条融合 | Merge 2 same type = sum × 0.8 | Unchanged |
| 删除特赦 | Free deletion, no counter increment | Unchanged |
| 敌人赦免 | Next 3 enemies auto-drop | Unchanged |
| 压力延缓 | -1 loop pressure | Unchanged |

---

## 11. Verdict Loop (裁决圈)

**Trigger**: Phase 5 altar filled + boss defeated → enter Phase 6

**Rules:**
- 5-6 enemies per loop, randomly distributed across 12 tiles
- All enemies at Phase 6 stats (×3.05 multiplier)
- All 5 enemy types available
- 4 rule pairs per enemy (maximum configuration)
- **Win condition**: Survive 5 consecutive loops
- **Fail condition**: HP reaches 0

**Duration estimate**: 5 loops × ~60-70s = 4-6 minutes of endgame challenge

**Validation:**
- Drainer Phase 6: HP 305, Attack 9 — naked kill time 24s, guaranteed death via enrage
- Requires fully grown tile rules (30+ loops of growth) and complete build to kill within 10s
- 5-6 fights per loop with minimal breathing room — ultimate build test ✓

---

## 12. Global Config Summary

```
# Player
player_hp_base = 200
player_dmg_base = 10
player_attack_interval = 0.8
player_walk_speed = 120
inventory_cap = 12
rule_slot_count_base = 2
rule_slot_count_max = 5

# Scaling
stat_scale_factor = 0.25

# Combat
combat_enrage_time = 10.0
combat_enrage_interval = 2.0
combat_enrage_bonus_per_stack = 0.30
combat_burn_dmg_per_stack = 2
combat_burn_interval = 1.0
low_hp_threshold = 0.3

# Economy
deletion_cost_sequence = [15, 35, 70]
deletion_cost_multiplier = 2.0

# Phase
total_phases = 6
verdict_trigger_phase = 5
verdict_survive_loops = 5

# Amplify
amplify_max_stacks_base = 1
amplify_multiplier_per_stack = 0.5

# Stacks
slow_per_stack = 0.10
dmg_boost_per_stack = 0.10
