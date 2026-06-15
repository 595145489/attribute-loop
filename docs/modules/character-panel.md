# Character Panel Module

## Responsibility

Displays all current player combat stats in a grouped list panel, accessible via the C key or a HUD button. Intended for use at decision points (before altar purchases, post-combat review), not during active combat.

## Key Classes / Nodes / Signals

- **`CharacterPanel`** (`src/ui/CharacterPanel.gd`) — `PanelContainer` subclass. Exposes a single `toggle()` method; no signals emitted.
- **`scenes/ui/character_panel.tscn`** — Scene with a `Margin/VBox` tree containing two `VBoxContainer` groups (`SurvivalGroup`, `OffenseGroup`), each holding `HBoxContainer` stat rows with `Name` and `Value` labels.
- **HUD button** (`BottomBar/HContent/CharButton`) and **C key** (`HUD._input`) — the two entry points.

## Execution Flow

1. User presses C or clicks 「角色 [C]」 button → `HUD._on_char_pressed()` is called.
2. If `InventoryPanel` is open, it is toggled closed first (mutual exclusion).
3. `CharacterPanel.toggle()` is called:
   - **Opening:** `_refresh()` reads all stat values from `GameState` and `DataTables.player` once, then calls `GameState.pause_for_panel()` and `show()`.
   - **Closing:** `hide()` and `GameState.unpause_for_panel()`.
4. Each stat row calls `Tooltip.show_tip(text)` / `Tooltip.hide_tip()` on `mouse_entered` / `mouse_exited` (wired in `_ready()`).

## Stats Displayed

**生存 group:** 生命 (`hp/hp_max`), 护盾 (`shield`), 减伤 (`slow_stacks`), 反射 (`pending_reflect_ratio`)

**攻击 group:** 攻击力 (`dmg_base + dmg_bonus`), 攻击间隔 (`attack_interval - attack_interval_bonus`), 强化 (`amplify_stacks`), 吸血 (`lifesteal_ratio`)

Zero-value effect stats render as a grey `—`.

## Dependencies

- `GameState` autoload — stat source
- `DataTables.player` (`PlayerData`) — base dmg and attack interval
- `Tooltip` autoload — per-row tooltips
- `HUD` — hosts the panel instance and button, handles C key
