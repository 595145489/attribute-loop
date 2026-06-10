# Component Tooltips Design

**Date:** 2026-06-10  
**Status:** Approved

## Goal

Show a 1-2 line mechanical description when the player hovers over a component in the inventory or loot strip.

## Implementation

Use Godot's built-in `tooltip_text` property. Set it when creating component buttons/cards. No custom tooltip system needed.

**Files modified:**
- `InventoryPanel.gd` — add `btn.tooltip_text = comp.description` in `_build_inventory_grid()`
- `StripPanel.gd` — add `card.tooltip_text = comp.description` on the PanelContainer in `_make_card()`
- All 12 `data/components/*.tres` — update `description` field

**Not in scope:** HUD rule slots, altar panel, tile rule panel (too small/contextually inappropriate).

## Descriptions

| id | description |
|----|-------------|
| 受击 | 每受到 N 次攻击后触发 |
| 击杀 | 每击杀 N 个敌人后触发 |
| 完成圈数 | 每完成 N 圈后触发 |
| 经过 | 每经过 N 格后触发 |
| 低血 | 生命低于 30% 时，每持续 N 秒触发一次 |
| 满血 | 生命值满时，每持续 N 秒触发一次 |
| 规则触发 | 其他规则累计触发 N 次后触发 |
| 治愈 | 恢复一定量生命值，随圈数累积成长 |
| 反射 | 将下一次受到的伤害按比例反弹给攻击者 |
| 护盾 | 获得护盾值，受伤时优先消耗护盾 |
| 减伤 | 叠加减伤层，每层使敌人伤害减少 10%，层数上限随阶段提升 |
| 吸血 | 提升吸血比率，每次攻击后按比例回复生命值 |
