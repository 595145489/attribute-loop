# Tile Entry System — Design Spec

**Date:** 2026-04-30  
**Scope:** V2 Phase 1  
**Status:** Approved

---

## Overview

Extend the world with a tile layer along the track. Each tile is an independent entry host — it can hold components, fire rules when the player passes, accumulate power over loops, and participate in the three-way component economy between enemies, the player, and the world.

---

## 1. Tile Data Structure

`Tile` extends `Resource`, consistent with `EntryComponent` and `Rule`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `track_t` | float | — | Center position on track (0–1) |
| `components` | Array[EntryComponent] | [] | Components held by this tile (max 3) |
| `pass_count` | int | 0 | Number of times player has passed through |
| `harvest_threshold` | int | 3 | Minimum pass_count before components can be harvested |

`Track` generates `Array[Tile]` at `_ready()` using an exported `tile_count` (default 12). Player's current tile index is computed as `floor(player.track_t * tile_count)` — no collision detection required.

---

## 2. Three-Way Component Flow

### Enemy → Tile (automatic, on death)
When an enemy dies, its remaining unstripped components transfer to the nearest tile (closest by `t`-value distance). If the tile is already at capacity (3 components), excess components are discarded.

### Player → Tile (manual, pause mode)
During pause, the player's current tile and its two immediate neighbors (3 tiles total) are interactive. Player drags a component from inventory onto a tile to invest it. No cost beyond losing the component from inventory.

### Tile → Player (manual, pause mode, threshold required)
Components on tiles with `pass_count < harvest_threshold` appear as locked cards (greyed out, not draggable). Once the threshold is reached, cards become draggable. Dragging to inventory removes the component from the tile.

---

## 3. Strip Costs

### Enemy strip retaliation
Stripping a component from an enemy immediately calls `player.receive_damage(5)`. Damage is applied at the moment the drag completes, not on unpause.

### Tile harvest cost
Harvesting a component from a tile (Tile → Player) costs `pass_count × 2` HP, applied immediately on drag completion. This represents the accumulated energy releasing on extraction — the more a tile has grown, the more it costs to take from it.

### Last-component final attack (遗言攻击)
When the last component is stripped from an enemy, the enemy immediately deals its full `attack_damage` to the player, then becomes an empty shell. The shell remains on the track but cannot attack and cannot be interacted with. It disappears the next time the player passes through its position.

### Inventory capacity
`Inventory` gains a `capacity` field (default 8). Dragging a component into a full inventory is rejected with a UI prompt.

---

## 4. Tile Trigger Logic

### Pass trigger
Each time the player's `track_t` crosses a tile boundary, `pass_count` increments by 1 for the tile being entered. If that tile has a valid TRIGGER + EFFECT component pair, the rule fires once.

Effect strength scales with accumulation:
```
effective_value = base_value × (1.0 + pass_count * 0.1)
```

### Trigger subject
Only the player triggers tile rules. Enemies do not.

### New trigger type: `on_pass`
A new `EntryComponent` trigger variant with `data["event"] == "on_pass"` is required for tiles. This is distinct from `on_hit` (which is player-damage-based). New tile-specific trigger and effect components must be defined:

**Triggers:**
- `on_pass` — fires when player walks through this tile

**Effects (tile-compatible):**
- `heal` — restore HP (already exists, reusable)
- `boost_speed` — temporarily increase player speed (new)
- `deal_damage_nearby` — damage enemies in radius (new)

---

## 5. Visual Layer

### Track tile indicators (`TileOverlay`)
A new `TileOverlay` Node2D lives as a child of `World`, positioned along the track. At each tile's `track_t` midpoint, a small icon is drawn:

| State | Appearance |
|-------|-----------|
| Empty tile | Dim dot |
| Has components, below threshold | Lit dot, component count badge |
| At or above harvest threshold | Glowing / pulsing, draggable |
| High pass_count | Icon color deepens with accumulation |

### Pause mode interaction
In pause mode, the player's current tile and its two immediate neighbors show component cards (reusing the `ComponentCard` scene from `EnemyCardOverlay`). Below-threshold cards are rendered grey and non-draggable. Above-threshold cards are fully interactive.

### HUD integration
`TileOverlay` is initialized by `HUD.setup()` after receiving a `Track` reference, parallel to how `EnemyCardOverlay` is managed. It is a world-space node, not a CanvasLayer, so it moves with world coordinates.

---

## Out of Scope (next phases)

- Mutation system (wrong-type component forced into slot)
- VERB slot activation
- Tile-to-enemy component transfer
- Tile evolution / tile type changes
- Sound effects
- HTML5 export
