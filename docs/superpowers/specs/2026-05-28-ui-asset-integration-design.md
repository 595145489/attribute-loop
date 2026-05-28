# UI Asset Integration Design

**Date:** 2026-05-28

## Goal

Apply the 10 generated UI art assets to the game's existing UI panels, replacing all hardcoded `StyleBoxFlat` color styles with texture-based styles derived from the parchment/translucent art direction.

---

## Assets to Integrate

| Asset | Target |
|-------|--------|
| `resources/ui/panel_bg.png` | All PanelContainer backgrounds (HUD bar, InventoryPanel, StripPanel) |
| `resources/ui/btn_normal/hover/pressed.png` | All Button states |
| `resources/ui/hp_bar_bg.png` | HP ProgressBar background |
| `resources/ui/hp_bar_fill.png` | HP ProgressBar fill |
| `resources/ui/gold_icon.png` | Gold display in HUD |
| `resources/ui/phase_badge_bg.png` | PhasePill panel background |
| `resources/ui/card_trigger_bg.png` | StripPanel trigger component cards |
| `resources/ui/card_effect_bg.png` | StripPanel effect component cards |
| `resources/ui/panel_combat_bg.png` | Deferred — no code integration yet |

---

## Architecture

### 1. Godot Theme Resource (`resources/ui_theme.tres`)

A single `Theme` resource defines texture-based styles for three control types:

- **Panel** (`"panel"` stylebox) → `StyleBoxTexture` using `panel_bg.png`
- **Button** (`"normal"`, `"hover"`, `"pressed"` styleboxes) → `StyleBoxTexture` using respective PNGs
- **ProgressBar** (`"background"`, `"fill"` styleboxes) → `StyleBoxTexture` using `hp_bar_bg.png` / `hp_bar_fill.png`

The theme is assigned to: HUD root, InventoryPanel root, StripPanel root.

All child nodes inherit automatically — no per-node overrides needed except exceptions below.

### 2. Exceptions (per-node overrides, not Theme)

**PhasePill** — uses `phase_badge_bg.png` instead of the default panel_bg. Applied as a `theme_override_styles/panel` on the PhasePill node in `hud.tscn`.

**GoldPill** — add a `TextureRect` (gold_icon.png, 16×16) as a sibling to the existing `GoldLabel` inside an HBoxContainer in `hud.tscn`.

**StripPanel cards** — `StripPanel.gd._make_card()` already creates cards dynamically. Switch from `StyleBoxFlat` border to `StyleBoxTexture` using `card_trigger_bg.png` (slot_type TRIGGER_ONLY) or `card_effect_bg.png` (slot_type EFFECT_ONLY or BOTH).

---

## Files Changed

| File | Change |
|------|--------|
| `resources/ui_theme.tres` | **New** — Theme resource with Panel/Button/ProgressBar texture styles |
| `scenes/ui/hud.tscn` | Assign `ui_theme.tres`; add gold icon TextureRect; assign `phase_badge_bg` to PhasePill |
| `scenes/ui/inventory_panel.tscn` | Assign `ui_theme.tres` |
| `scenes/ui/strip_panel.tscn` | Assign `ui_theme.tres` |
| `src/ui/StripPanel.gd` | Update `_make_card()` to use card bg textures |

---

## Testing

**Screenshot test** — `tests/screenshot_ui_skin.gd`:
- Instantiate HUD scene
- Take screenshot
- Visual assertions:
  - [ ] BottomBar has parchment texture (not solid dark color)
  - [ ] HP pill shows texture background
  - [ ] Gold icon (coin) visible next to gold label
  - [ ] Phase pill shows badge texture
  - [ ] Buttons have parchment texture style

StripPanel card textures are verified by running the main scene and triggering a combat kill to open the panel.

---

## Out of Scope

- `panel_combat_bg.png` — no combat overlay system implemented yet
- Fonts, font sizes, text colors — unchanged
- Enemy/Player sprites — separate task
