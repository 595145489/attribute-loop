# V1 Demo UI — Design Spec

**Date:** 2026-04-29  
**Scope:** Complete the V1 Demo milestone for AttributeLoop. All backend (Inventory, Rule, EntryComponent, Enemy.strip_component) is done. This spec covers the missing UI layer and remaining game features.

---

## 1. Goals

- Playable proof of the "strip → assemble → rule fires" core loop
- Clean scene architecture (each UI concern is its own scene, HUD is compositor only)
- Survives 2–3 loops without crash; player death triggers restart

---

## 2. Scene Hierarchy

```
HUD (CanvasLayer)
├── GameHUDLayer          # existing: HP bar + pause label
├── EnemyCardOverlay      # new: component cards floating above paused enemies
├── InventoryPanel        # new: bottom strip, cards from Inventory
└── RuleAssemblyPanel     # new: TRIGGER slot + EFFECT slot, rule builder
```

HUD.gd listens to `GameState.paused` signal and sets `visible` on the three new panels. It does not contain any drag logic.

---

## 3. Data Flow

```
Space key
  → GameState.toggle_pause()
  → HUD shows EnemyCardOverlay + InventoryPanel + RuleAssemblyPanel

Drag card from EnemyCardOverlay
  → Enemy.strip_component(component)       # removes from enemy internal list
  → Inventory.add(component)
  → InventoryPanel receives Inventory.component_added signal → refreshes cards
  → Enemy shows visual "stripped" state (dimmed / placeholder card)

Drag card from InventoryPanel → RuleAssemblyPanel slot
  → Inventory.remove(component)
  → Slot filled; if both slots filled → Player.add_rule(new Rule)
  → Slot card rendered in active state

Drag card from RuleAssemblyPanel slot → InventoryPanel
  → Rule removed from Player (if complete)
  → Inventory.add(component) back
  → Slot returns to empty state

Rule fires
  → Player emits rule_fired(rule) signal
  → RuleAssemblyPanel flashes the matching slot highlight (0.5 s)

Player HP ≤ 0
  → Player emits player_died
  → Main.gd calls get_tree().reload_current_scene()
```

---

## 4. Scenes — Detail

### 4.1 EnemyCardOverlay

- **Node type:** CanvasLayer child (Control, full-rect)
- For each enemy alive, show a small card near the enemy's screen position
- Card displays: component type label (TRIGGER / EFFECT), component name
- Card is draggable only when enemy has unstripped components
- After strip, card is removed; enemy node gets a visual modifier (modulate dimmed)
- Uses Godot's `_get_drag_data` / `_drop_data` protocol

### 4.2 InventoryPanel

- **Node type:** HBoxContainer anchored to bottom of screen
- One `ComponentCard` scene per slot (max 12, matching Inventory limit)
- Listens to `Inventory.component_added` and `Inventory.component_removed`
- Cards are draggable via `_get_drag_data`
- Accepts drops from RuleAssemblyPanel (cards returning from rules)

### 4.3 RuleAssemblyPanel

- **Node type:** HBoxContainer centered on screen
- Two `RuleSlot` nodes: one labeled TRIGGER, one labeled EFFECT
- Each slot accepts drops matching its type (`EntryComponent.type`)
- Wrong-type drop: rejected visually (red flash), no state change
- Both slots filled: automatically calls `Player.add_rule(rule)` and locks slots
- Locked slots show active styling; `rule_fired` signal triggers a highlight flash
- Clicking a locked slot returns its component to inventory and removes the rule

### 4.4 ComponentCard (shared scene)

- Label: component type badge + component name
- Draggable (exports drag payload as the `EntryComponent` resource)
- Visual states: default, dragging (semi-transparent), stripped (dimmed, non-draggable)

---

## 5. Second Enemy Type

- New scene `EnemyB.tscn` (instance of Enemy.tscn with overridden export vars)
- Different component loadout: e.g., Enemy A carries TRIGGER+EFFECT, Enemy B carries two EFFECTs
- Different color tint to distinguish on track
- Main.gd spawn timer alternates or randomly picks enemy type

---

## 6. Stability

- Player HP ≤ 0 → `player_died` signal → `Main._on_player_died()` → `reload_current_scene()`
- Enemy freed while card overlay is visible: EnemyCardOverlay listens to `enemy.tree_exited` and removes the associated card
- Rule slots cleared on scene reload (no persistent state across restarts at V1)

---

## 7. Out of Scope (V1)

- Art / sprite polish
- Sound effects
- Mutation entries (wrong-type slot forcing)
- VERB slot (three-part rules)
- Persistent world accumulation across loops

---

## 8. Validation Criteria

- Headless `--headless --quit` exits 0 (no script errors)
- Can strip a component from an enemy while paused
- Stripped component appears in InventoryPanel
- Can drag component to rule slot; both slots filled → rule visible on player
- Player "heal on hit" starter rule still fires and flashes slot
- Player death reloads scene
- EnemyB spawns and carries different components
