# Phase 2 UI

## StripPanel

`StripPanel` (`src/ui/StripPanel.gd`, `scenes/ui/strip_panel.tscn`) is a `PanelContainer` centered on screen.

**Shown by:** `StripManager` after `enemy_killed` when the enemy has components.

**Layout:** 2-column GridContainer of component cards. Each card shows:
- Colored border by slot_type (orange=T, green=E, blue=BOTH)
- display_name, value summary
- "取走" button (disabled if inventory full)

**Controls:**
- "取走" → `GameState.add_to_inventory(comp)`; updates all take buttons
- "[B] 打开背包" → calls `InventoryPanel.toggle()` (allows deleting to free space)
- "继续 →" → hides panel, sets `is_paused = false`, calls the completion callback

## InventoryPanel

`InventoryPanel` (`src/ui/InventoryPanel.gd`, `scenes/ui/inventory_panel.tscn`) is a `PanelContainer` centered on screen.

**Toggle:** via `toggle()` method (called by HUD bag button, StripPanel bag button). Sets `GameState.is_paused`.

**Layout:**
- Rule slots section: one HBox per slot, T sub-slot button + E sub-slot button
- Inventory grid: 4 columns, one button per component
- Delete button (shown only when a component is selected)

**Equip flow:**
1. Click inventory component → `_selected` set, Delete shown
2. Click T or E sub-slot → `GameState.equip(_selected, slot_idx, as_trigger)` called
3. If sub-slot occupied, old component swapped back to inventory
4. Panel refreshes

**Type enforcement:** `TRIGGER_ONLY` cannot be placed in E sub-slot, `EFFECT_ONLY` cannot be placed in T sub-slot. Enforced in `_make_slot_handler`.

**Delete:** removes from inventory and clears from any rule slot it occupies.

## HUD Updates

New elements in `hud.tscn`:
- `RulesLabel`: shows `"受击→治愈 / 空"` style summary, updated every frame
- `BagButton`: opens InventoryPanel; shows current inventory usage `"背包 [B] 3/12"`
- `FloatLabel`: floating text on `rule_fired` signal (e.g. "+15 治愈"), fades out over 1s via Tween

`HUD.setup(inv_panel)` must be called from `Main._ready()` to wire the bag button.
