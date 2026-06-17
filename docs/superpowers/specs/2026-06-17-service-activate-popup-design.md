# Service Activate Popup — Design Spec

**Date:** 2026-06-17
**Scope:** `ServiceActivatePopup` scene and script only. `ServiceBar` is out of scope.

---

## Problem

The current popup has no styling, no descriptions, and no visual hierarchy. It spawns raw Godot `Label` and `Button` nodes directly into a bare `PanelContainer`, resulting in a blank-looking modal with no polish.

---

## Visual Direction

**Dark gold-bordered card** — matching `service_btn_card.png` (dark brown texture, gold filigree border). This reuses an existing art asset and keeps visual consistency with the service bar that opens the popup.

Key palette:
- Background: `#1a1208` (dark brown)
- Border/accent: `#c8923a` (gold)
- Primary text: `#f0d080` (warm gold)
- Secondary text: `#a07840` (muted gold)
- Selected row: gold border + `#c8923a22` fill
- Warning variant (overflow): `#c87838` orange instead of gold

---

## Layout Structure

All popup variants share the same three-zone layout:

```
┌─────────────────────────────────┐
│  [HEADER]  Service Name         │  fixed height ~50px
│            Subtitle / category  │
├─────────────────────────────────┤
│  [BODY]    Description text     │  flexible height
│            Interactive content  │
├─────────────────────────────────┤
│  [FOOTER]  [Cancel]  [Confirm]  │  fixed height ~36px
└─────────────────────────────────┘
```

Popup size: ~480 × 360px. Body zone is wrapped in a `ScrollContainer` so long component lists (up to 12 rows) don't overflow the panel.

---

## Service Type Variants

### Type 1 — Instant Apply (no selection required)
Services: `PRESSURE_DELAY`, `DELETE_PARDON`, `STAT_DMG`, `STAT_HP`, `STAT_SPEED`, `STAT_AMPLIFY`, `SLOT_RULE`, `SLOT_SERVICE`

Body contains:
- Large effect preview box: icon + effect text + "current → after" value line
- Short flavour/lore line in italic muted gold

Confirm button label: **"立即使用"**

### Type 2 — Select Component (single or double)
Services: `COMP_REWRITE` (single select), `COMP_MERGE` (multi-select exactly 2)

Body contains:
- One-line description of the operation
- Column header row: "词条名称" on left, "当前 → 改写后" on right
- Vertical list of rows, one per inventory component:
  - Left: icon + display_name
  - Right: `current_value → projected_value` (gold text when selected)
  - Selected row: gold border + dim gold fill
  - Unselected row: dark fill + muted border
- For COMP_MERGE: two rows can be selected simultaneously; right column shows `effect_value` when unselected, and changes to `A + B → merged` only after both are selected

Confirm button: disabled (greyed) until valid selection is made.
Confirm label: **"改写"** / **"融合"**

### Type 3 — Select Enemy Type
Service: `ENEMY_PARDON`

Body contains:
- Description: "下 3 次遭遇自动掉落，无需战斗"
- Vertical list of 5 enemy types (single-select radio style)
- Each row: colour dot + enemy name

Confirm label: **"赦免"**

### Type 4 — Discard Overflow
Trigger: service bar is full when a new service is won.

Visual: orange warning variant (`#c87838` border/accent instead of gold).

Header subtitle: `新赢得：{service_name} · 选择一个放弃`

Body contains:
- Warning description: "选择放弃哪一个服务（放弃后无法找回）"
- Vertical list of all bar services + the new one; new one tagged with a small "新赢得" badge (orange)
- Single-select

Cancel button label: **"取消（放弃新的）"** — makes the implicit behaviour explicit.
Confirm label: **"放弃选中"**

---

## Implementation Notes

- **No new scene nodes for each variant.** All content is built dynamically in `_build_content()` / `_build_discard_content()` via code, same as current approach. Only the visual styling changes.
- **Background image:** Apply `service_btn_card.png` as a `StyleBoxTexture` on the root `PanelContainer`, or draw it via a `TextureRect` behind the VBox.
- **Row component:** Extract a helper `_make_row(label, left_text, right_text, group)` to reduce duplication across COMP_REWRITE, COMP_MERGE, ENEMY_PARDON, and discard list.
- **Confirm button state:** Connect a `_refresh_confirm()` method to each row's `toggled` signal so the button enables/disables reactively.
- **Projected value calculation:** For COMP_REWRITE, multiply `effect_value × (1 + DataTables.config.auction_comp_rewrite_delta)`. For COMP_MERGE, sum both then multiply by 0.8. Compute inline when building the row.
- **No new art assets required** for the popup itself — reuse `service_btn_card.png`. Icons per effect type can use existing `resources/ui/icons/` if present, or plain emoji fallback.

---

## Out of Scope

- ServiceBar visual redesign
- Tooltip on hover for rows
- Animations / tweens on open/close
- Sound effects
