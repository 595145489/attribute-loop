# Phase 5 Design — 裁决圈 + 发布

**Date:** 2026-05-25
**Status:** Approved

---

## 1. Overview

**Dev Phase 5 Playable Goal:** Endgame survival loop, win/lose result screens, HTML5 export deployable to itch.io.

The centerpiece is 裁决圈 (The Verdict Loop) — a special endless-pressure mode triggered after the player fills the Altar at a configurable phase. It is the final test of everything the player has built.

---

## 2. Configuration Layer

### GameConfig.gd — new fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `verdict_trigger_phase` | int | 10 | In-game phase whose Altar fill triggers 裁决圈 |
| `verdict_survive_loops` | int | 5 | Loops the player must survive in 裁决圈 to win |
| `verdict_enemy_phase` | int | 10 | Phase index used to calculate enemy stats in 裁决圈 |
| `verdict_spawn_phase` | int | 11 | Key used to look up spawn weights in DataTables |

During development, set `verdict_trigger_phase = 5` in the `.tres` config file to reach 裁决圈 without playing through all 10 in-game phases. Change to `10` before release.

### DataTables — spawn_weights

Add key `11` to the `spawn_weights` dictionary. This row is used exclusively by 裁决圈 and is independent of Phase 10 weights:

```
11: { "汲取者": 10, "守卫者": 10, "急袭者": 20, "复制者": 30, "先驱者": 30 }
```

Values are relative weights; adjust as needed for balance.

---

## 3. GameState Layer

### New fields

```gdscript
var in_verdict_loop: bool = false
var verdict_loops_survived: int = 0
```

### Existing fields reused for result screen

- `current_phase` — phase reached when 裁决圈 was entered
- `total_kills` — cumulative kill count across the run

### State transitions

| Event | Action |
|-------|--------|
| Altar filled at `verdict_trigger_phase` | `in_verdict_loop = true`, `verdict_loops_survived = 0` |
| Loop completed inside 裁决圈 | `verdict_loops_survived += 1` |
| HP reaches 0 | emit `game_lost` (existing flow) |
| `verdict_loops_survived >= verdict_survive_loops` | emit `game_won` |
| Restart | reset all GameState fields, reload main scene |

---

## 4. GameLoop Layer

### Altar activation check

After the existing altar activation logic (altar buff fires first as normal), add:

```gdscript
if GameState.current_phase == config.verdict_trigger_phase:
    GameState.in_verdict_loop = true
    GameState.verdict_loops_survived = 0
    EventBus.emit_signal("verdict_loop_entered")
    # Do NOT advance phase or reset pressure — 裁决圈 takes over
```

### 裁决圈 behavioral overrides

When `GameState.in_verdict_loop == true`:

- **Enemy spawn:** use `config.verdict_spawn_phase` (= 11) for spawn weights; use `config.verdict_enemy_phase` (= 10) for stat scaling
- **World pressure:** skip entirely — no pressure window check, no forced phase advance
- **Loop completion:** increment `GameState.verdict_loops_survived`; if `>= config.verdict_survive_loops` emit `EventBus.game_won`

### New EventBus signals

```gdscript
signal verdict_loop_entered   # 裁决圈 begins
signal game_won               # player survives required loops
```

`game_lost` (HP = 0) already exists and is unchanged.

---

## 5. Win/Lose UI

### Scene

Extend existing `GameOver.tscn` / `GameOver.gd`. The same scene handles both outcomes, switching content based on which signal triggered it.

### Layout — Result Card

```
┌─────────────────────────────┐
│  [裁决通过] / [阵亡]          │
│                             │
│  到达阶段      Phase N       │
│  击杀数        NNN           │
│  裁决圈完成    N / M 圈       │
│                             │
│       [ 重新开始 ]            │
└─────────────────────────────┘
```

- On `game_won`: title = 「裁决通过」; show all three stat rows
- On `game_lost`: title = 「阵亡」; show all three stat rows (verdict loops may be 0 if died before 裁决圈)
- Restart button: calls `GameState.reset()` then reloads main scene via `get_tree().reload_current_scene()`

### Signal wiring

`GameOver.gd` connects to both `EventBus.game_won` and `EventBus.game_lost` at `_ready`. Whichever fires first populates the card and shows the panel.

---

## 6. HTML5 Export

### Export preset

Configure `export_presets.cfg` with a Web export target:
- Template: Godot 4 Web export template (release)
- Output path: `exports/web/index.html`
- Threads enabled (requires SharedArrayBuffer headers on server)

### One-click export script

`scripts/export_web.ps1` — calls Godot headless export:

```powershell
godot --headless --export-release "Web" exports/web/index.html
```

Output: `exports/web/` directory containing `index.html`, `.wasm`, `.js`, `.pck`.

### itch.io deployment

1. Zip the `exports/web/` directory
2. Upload to itch.io project page
3. Set **Kind of project** to HTML
4. Enable **SharedArrayBuffer** under Embed options (required for Godot 4 threads)
5. Mark as playable in browser

---

## 7. Execution Order

1. Add fields to `GameConfig.gd` and `GameConfig.tres` (set `verdict_trigger_phase = 5` for dev)
2. Add `11` row to `DataTables` spawn weights
3. Add `in_verdict_loop` and `verdict_loops_survived` to `GameState.gd` + `reset()`
4. Add `verdict_loop_entered` and `game_won` signals to `EventBus.gd`
5. Update `GameLoop.gd` — altar check + 裁决圈 overrides
6. Update `GameOver.gd` / `GameOver.tscn` — result card layout
7. Write unit tests for new GameState fields and GameLoop 裁决圈 logic
8. Configure HTML5 export preset + write `scripts/export_web.ps1`
9. Test export locally in browser
10. Deploy to itch.io

---

## 8. Out of Scope

- Sound effects and music
- Animated transitions on win/lose screen
- Run history / leaderboard
- 护盾 / 加速 / 蓄能 effects and 低血 trigger (Phase 4 tech debt, deferred)
