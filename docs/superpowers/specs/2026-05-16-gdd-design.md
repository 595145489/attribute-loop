# Game Design Document — AttributeLoop

**Date:** 2026-05-16  
**Status:** Approved  

---

## 1. Game Overview

**Genre:** Single-map progressive Roguelike, top-down view, inspired by Loop Hero  
**Platform:** HTML5 (Web)  
**Core Fantasy:** Strip rule-components from enemies, assemble them into living rules that rewrite the game world. The world is a blank slate you author — and it pushes back.

---

## 2. Core Loop

```
Auto-walk along track
  → Encounter enemy
    → Pause → Strip components (costs nothing, limited by inventory cap)
      → Allocate components:
          A. Player rule slot  — immediate effect, free to swap
          B. Tile             — permanent world rule, scales with pass_count
          C. Altar            — consumed for Phase buff + advancement
  → Resume walking
  → Tiles fire passively on each pass
  → Gold accumulates from kills
  → When ready: fill Altar → Phase advances → world pressure resets
```

**Resource tensions:**
- Inventory cap (12 slots) forces allocation decisions
- Gold is finite — every deletion costs more than the last
- Altar consumes components permanently but grants buffs and controls Phase timing

---

## 3. Entry Component System

### Structure

Every rule is exactly two slots:

```
[ TRIGGER ] + [ EFFECT ]
```

- Slots are **type-enforced** — only the correct component type may be inserted
- No VERB slot, no Mutation system
- Player rule slots swap freely; tile rules are permanent (delete costs gold)

---

### TRIGGER Components

**Count-based triggers** — value N = event must occur N times before rule fires (then resets)

| Component | Fires When | N Range |
|-----------|-----------|---------|
| 受击(N) | Player takes any damage | 1–3 |
| 击杀(N) | Player kills an enemy | 1–3 |
| 完成一圈(N) | Player completes a full loop | 1–3 |
| 经过(N) | Player passes any tile | 1–3 |
| 规则触发(N) | Any other rule fires | 1–3 |

**State-based triggers** — no count, fires whenever condition is met

| Component | Fires When |
|-----------|-----------|
| 低血 | HP drops below 30% |
| 满血 | Player is at full HP when hit |

Higher-N triggers drop from stronger enemies. N=1 is most common (Phase 1 drops), N=3 is rare (Phase 7+ drops).

---

### EFFECT Components

Each component has:
- `base_value` — shown on card, varies by enemy source / Phase
- `growth_rate` — fixed per component type, scales tile placement over time

**Formula (tile only):**
```
actual_value = base_value × (1 + growth_rate × pass_count)
```

Player rule slots always use `base_value` (pass_count = 0).

| Component | Effect | growth_rate |
|-----------|--------|-------------|
| 治愈 | Restore HP | 0.15 |
| 溢出治愈 | Heal HP; excess converts to temporary shield | 0.15 |
| 护盾 | Absorb incoming damage | 0.20 |
| 反射 | Reflect % of damage back to attacker | 0.10 |
| 吸血 | Steal HP from nearest enemy | 0.12 |
| 加速 | Increase movement speed temporarily | 0.10 |
| 减速 | Reduce all enemies' attack/move speed | 0.10 |
| 蓄能 | Accumulate charges per trigger; release burst at max | 0.08 |
| 强化 | Next rule that fires has multiplied effect | 0.05 |
| 连锁 | Effect also propagates to next entity encountered | 0.08 |

**V1 priority set:**  
Triggers: 受击, 击杀, 低血, 完成一圈, 经过  
Effects: 治愈, 护盾, 反射, 加速, 蓄能

---

## 4. Rule System

### Player Rules

- Player starts with **2 rule slots**; Altar buffs can expand this up to a maximum of 5
- Each slot holds one TRIGGER + one EFFECT component
- Slots may be swapped freely at any time (old component returns to inventory)
- Rules fire when their trigger condition is met during normal play

### Tile Rules

- Player drags a TRIGGER + EFFECT component pair onto a tile
- Once invested, the rule is **permanent** — no retrieval
- Rule fires every time the player passes the tile (if trigger matches)
- Effect value scales with `pass_count` via growth formula
- Tile color gradient (blue → yellow) reflects current `pass_count` strength
- To remove: pay gold (global escalating cost), component is **destroyed**

### Altar Rule

- Player invests components into the special Altar tile
- When altar requirement is met: player receives a powerful buff AND Phase advances
- If player does not fill the altar within the world pressure window, Phase advances automatically — **without the buff**

---

## 5. Tile System

**Track layout:** 12 tiles evenly distributed on the loop  
**Max components per tile:** 3  
**Effect scaling:** `actual_value = base_value × (1 + growth_rate × pass_count)`  
**Visual feedback:** Tile dot color transitions continuously from grey (empty) → blue (low pass_count) → yellow (high pass_count)

The Altar is one additional special tile at a fixed landmark position on the track, visually distinct from normal tiles.

---

## 6. Economy System

### Gold Sources

| Source | Gold Amount |
|--------|------------|
| Defeat 汲取者 / 守卫者 | 5–15 (scales with Phase) |
| Defeat 急袭者 / 复制者 / 先驱者 | 20–50 (scales with Phase) |

### Gold Usage

**Component deletion (inventory or tile) — global escalating cost:**

| Deletion Count (global) | Cost |
|------------------------|------|
| 1st | 20 gold |
| 2nd | 50 gold |
| 3rd | 100 gold |
| Nth (N ≥ 4) | Previous cost × 2 |

Deleted components are **permanently destroyed** regardless of source (inventory or tile).

---

## 7. Inventory & Resource Management

- **Inventory cap:** 12 component slots
- **Strip cost:** Free (stripping from enemies has no HP cost)
- **Full inventory:** Player cannot strip new components until a slot is freed
- **Freeing a slot:** Invest into rule/tile/altar, or delete (costs gold)
- **Rule slot swap:** Free — old component returns to inventory

---

## 8. Enemy Design

### Enemy Types

| Type | Unlock Phase | HP | Attack | Component Focus | Gold Drop |
|------|-------------|-----|--------|----------------|-----------|
| 汲取者 | Phase 1 | Low | Frequent / low damage | TRIGGER-heavy | 5–15 |
| 守卫者 | Phase 1 | High | Slow / high damage | EFFECT-heavy | 5–15 |
| 急袭者 | Phase 4 | Low | Very fast / medium damage | Mixed | 20–50 |
| 复制者 | Phase 7 | Medium | Medium | Full set | 20–50 |
| 先驱者 | Phase 10 | High | High | Max components | 20–50 |

**复制者** spawns a weakened copy on death.  
**先驱者** carries a full component loadout with high `base_value`.

### Stat Scaling Formula

```
stat = base_stat × (1 + (Phase - 1) × 0.3)
```

| Phase | Multiplier | HP (base 40) | Damage (base 8) |
|-------|-----------|-------------|----------------|
| 1 | ×1.0 | 40 | 8 |
| 3 | ×1.6 | 64 | 13 |
| 5 | ×2.2 | 88 | 18 |
| 7 | ×2.8 | 112 | 22 |
| 10 | ×3.7 | 148 | 30 |

### Component Count per Phase

| Phase | Components per Enemy |
|-------|---------------------|
| 1–2 | 1–2 |
| 3–4 | 2–3 |
| 5–6 | 3–4 |
| 7–8 | 4–5 |
| 9–10 | 5–6 |

Component `base_value` also scales with Phase — late-phase enemies drop more powerful components.

### Spawn Probability Table

| Phase | 汲取者 | 守卫者 | 急袭者 | 复制者 | 先驱者 |
|-------|-------|-------|-------|-------|-------|
| 1 | 50% | 50% | — | — | — |
| 2 | 45% | 45% | — | — | — |
| 3 | 45% | 45% | — | — | — |
| 4 | 40% | 40% | 20% | — | — |
| 5 | 35% | 35% | 30% | — | — |
| 6 | 30% | 30% | 40% | — | — |
| 7 | 25% | 25% | 30% | 20% | — |
| 8 | 20% | 20% | 30% | 30% | — |
| 9 | 15% | 15% | 30% | 40% | — |
| 10 | 10% | 10% | 20% | 30% | 30% |

---

## 9. Phase System

### Phase Table

| Phase | Name | Altar Requirement | World Pressure Window | Enemy Components |
|-------|------|------------------|----------------------|-----------------|
| 1 | 觉醒 | 2 components | 10 loops | 1–2 |
| 2 | 萌动 | 3 components | 9 loops | 1–2 |
| 3 | 涌动 | 4 components | 8 loops | 2–3 |
| 4 | 侵蚀 | 5 components | 7 loops | 2–3 |
| 5 | 失衡 | 6 components | 6 loops | 3–4 |
| 6 | 碰撞 | 7 components | 5 loops | 3–4 |
| 7 | 觉醒II | 8 components | 4 loops | 4–5 |
| 8 | 压制 | 9 components | 3 loops | 4–5 |
| 9 | 律法 | 10 components | 2 loops | 5–6 |
| 10 | 裁决前夜 | 12 components | 1 loop | 5–6 |

### Phase Advancement

**Player-driven (normal):**
1. Player fills Altar with required components
2. Components consumed permanently
3. Player receives a powerful buff
4. Phase advances, enemies scale up, world pressure resets

**World pressure (failsafe):**
1. Player has not filled the Altar within the pressure window
2. Phase advances automatically
3. Player receives **no buff**
4. Risk of snowballing difficulty if unprepared

### Altar Buffs (examples, to be expanded)

Each Phase grants one buff from a pool:
- Permanent HP increase
- Rule slot count +1
- Inventory cap +3
- All tile effect multipliers +20% permanently
- Gold drop rate +30%

---

## 10. Endgame — 裁决圈 (The Verdict Loop)

Triggered after Phase 10 Altar is filled by the player.

- The track enters **裁决圈** — a special endless-pressure loop state
- Enemies spawn at **maximum density and maximum Phase 10 stats**
- No world pressure timer — urgency comes entirely from enemy intensity
- No boss entity — the endgame is a pure survival test
- **Win condition:** Survive a set number of loops (exact count TBD by balance, tentatively 5 loops)
- **Lose condition:** HP reaches 0

The 裁决圈 is a direct test of everything the player has built across 10 Phases — their personal rules, their tile network, and how well they managed their component economy.

---

## 11. Win & Loss Conditions

| Outcome | Condition |
|---------|-----------|
| Failure | Player HP reaches 0 at any point |
| True Victory | Survive the required loops in 裁决圈 |
| Pressure Spiral | Repeated world pressure triggers without player buff accumulation — functionally leads to failure |

---

## 12. Out of Scope (Future Design)

- VERB slot (third rule component)
- Mutation system (wrong-type component forcing)
- Entry will / component migration
- Multi-map or level structure
- Sound effects and art pass
- 裁决圈 exact loop count (balance work)
