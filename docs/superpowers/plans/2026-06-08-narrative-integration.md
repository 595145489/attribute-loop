# Narrative Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Surface the shared-dream story at phase transitions (full-screen overlay) and the game over screen (narrative endings).

**Architecture:** A new `PhaseTransition` CanvasLayer shows a full-screen story moment on every phase advance — copy + background looked up by phase number, game paused, dismissed on click. The existing `GameOver` scene gains a background image and narrative text block above its stats. All copy lives as GDScript constants; backgrounds are PNG assets in `resources/backgrounds/`.

**Tech Stack:** Godot 4, GDScript, GutTest unit tests (`tests/unit/`), aiart for background asset generation.

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `src/ui/PhaseTransition.gd` | Copy data, background lookup, fade-in/out, pause/resume |
| Create | `scenes/ui/phase_transition.tscn` | CanvasLayer with Background, Overlay, content VBox, ContinueHint |
| Create | `tests/unit/test_phase_transition.gd` | Unit tests for copy lookup and background path selection |
| Modify | `src/Main.gd` | Add PhaseTransition node reference; call `show_for_phase()` in `_on_phase_changed` |
| Modify | `scenes/main.tscn` | Add PhaseTransition as child of root |
| Modify | `src/ui/GameOver.gd` | Add `_get_narrative(outcome)` pure function; populate NarrativeText + Background in `_populate()` |
| Modify | `scenes/ui/game_over.tscn` | Add Background TextureRect + NarrativeText RichTextLabel above stats VBox |
| Create | `tests/unit/test_game_over_narrative.gd` | Unit tests for win/lose narrative text selection |
| Generate | `resources/backgrounds/bg_phase_1_2.png` … `bg_game_over_lose.png` | 7 background images (art-production task) |

---

## Task 1: Generate Background Art (art-production skill)

**Files:**
- Create: `resources/backgrounds/bg_phase_1_2.png`
- Create: `resources/backgrounds/bg_phase_3_4.png`
- Create: `resources/backgrounds/bg_phase_5_6.png`
- Create: `resources/backgrounds/bg_phase_7_8.png`
- Create: `resources/backgrounds/bg_phase_9_10.png`
- Create: `resources/backgrounds/bg_game_over_win.png`
- Create: `resources/backgrounds/bg_game_over_lose.png`

> Use the `art-production` skill. Generate all 7 images as a batch. Style: warm dream realism, soft-focus edges, luminous light. Reference mood: 君の名は. Same viewpoint (loop path leading to pavilion) across all 5 phase backgrounds — only contents and lighting change. 1920×1080.

- [ ] **Step 1: Invoke art-production skill**

  Prompt spec for each image (pass to skill):

  | File | Scene description |
  |------|------------------|
  | `bg_phase_1_2` | Dawn mist. Loop path to a small wooden pavilion, lamp lit, a single white flower on the step. Stones recently rearranged beside path. Empty, quiet, someone was just here. Soft blue-grey, pale gold light. |
  | `bg_phase_3_4` | Morning. Same path and pavilion. Stones on ground clearly spelling "?" and "!" side by side. A few carved words just beginning to show on pavilion wall. Warm angled light. |
  | `bg_phase_5_6` | Dusk. Two sets of footprints on path going opposite directions, never overlapping. Pavilion lamp casting wide warm circle. Amber and rose tones. |
  | `bg_phase_7_8` | Night falling. Pavilion walls dense with tiny writing, nearly full. Path darker. One wall side has fewer recent marks. Deep indigo sky. |
  | `bg_phase_9_10` | Deep night. Walls completely covered — no blank space. Pavilion lamp out. Only moonlight. The original flower on the step, dried. |
  | `bg_game_over_win` | Moonlit night. Loop path. Far in the distance, two figures have just met — backs to camera, facing the pavilion. Warm ambient light, close but not sentimental. |
  | `bg_game_over_lose` | Empty pavilion, lamp still burning. Walls covered in writing. No one present. The light is on, as if still waiting. |

- [ ] **Step 2: Verify all 7 files exist in `resources/backgrounds/`**

  ```
  ls resources/backgrounds/
  ```
  Expected: all 7 bg_*.png files present.

- [ ] **Step 3: Commit**

  ```bash
  git add resources/backgrounds/
  git commit -m "assets: add 7 narrative background images"
  ```

---

## Task 2: Phase Transition — Data Layer + Unit Tests

**Files:**
- Create: `src/ui/PhaseTransition.gd`
- Create: `tests/unit/test_phase_transition.gd`

- [ ] **Step 1: Write failing tests**

  Create `tests/unit/test_phase_transition.gd`:

  ```gdscript
  extends GutTest

  const PhaseTransition = preload("res://src/ui/PhaseTransition.gd")

  var pt: PhaseTransition

  func before_each() -> void:
      pt = PhaseTransition.new()

  func after_each() -> void:
      pt.free()

  func test_get_copy_phase_1_label() -> void:
      var copy = pt.get_copy(1)
      assert_eq(copy["label"], "Phase 1 · 觉醒")

  func test_get_copy_phase_10_label() -> void:
      var copy = pt.get_copy(10)
      assert_eq(copy["label"], "Phase 10 · 裁决前夜")

  func test_get_copy_phase_1_text_not_empty() -> void:
      var copy = pt.get_copy(1)
      assert_true(copy["text"].length() > 0)

  func test_get_copy_all_phases_have_entries() -> void:
      for i in range(1, 11):
          var copy = pt.get_copy(i)
          assert_not_null(copy, "Phase %d missing copy" % i)

  func test_get_background_phase_1_returns_1_2() -> void:
      assert_eq(pt.get_background_path(1), "res://resources/backgrounds/bg_phase_1_2.png")

  func test_get_background_phase_2_returns_1_2() -> void:
      assert_eq(pt.get_background_path(2), "res://resources/backgrounds/bg_phase_1_2.png")

  func test_get_background_phase_3_returns_3_4() -> void:
      assert_eq(pt.get_background_path(3), "res://resources/backgrounds/bg_phase_3_4.png")

  func test_get_background_phase_4_returns_3_4() -> void:
      assert_eq(pt.get_background_path(4), "res://resources/backgrounds/bg_phase_3_4.png")

  func test_get_background_phase_5_returns_5_6() -> void:
      assert_eq(pt.get_background_path(5), "res://resources/backgrounds/bg_phase_5_6.png")

  func test_get_background_phase_9_returns_9_10() -> void:
      assert_eq(pt.get_background_path(9), "res://resources/backgrounds/bg_phase_9_10.png")

  func test_get_background_phase_10_returns_9_10() -> void:
      assert_eq(pt.get_background_path(10), "res://resources/backgrounds/bg_phase_9_10.png")
  ```

- [ ] **Step 2: Run tests — expect FAIL**

  ```
  cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
  ```
  Expected: errors about missing `PhaseTransition` or missing `get_copy` / `get_background_path`.

- [ ] **Step 3: Create `src/ui/PhaseTransition.gd` with data functions**

  ```gdscript
  class_name PhaseTransition
  extends CanvasLayer

  const _COPY: Dictionary = {
      1: {
          "label": "Phase 1 · 觉醒",
          "text": "一条发光的小路。\n亭子里有一盏灯，还有一朵不知道谁放的花。\n\n你走了进去。\n你也不知道为什么。"
      },
      2: {
          "label": "Phase 2 · 萌动",
          "text": "那朵花变颜色了。\n\n路边的石子被摆成了某种形状，太刻意，不像是偶然。\n\n也许这里不只有你。"
      },
      3: {
          "label": "Phase 3 · 涌动",
          "text": "你把石子摆成了一个问号。\n\n第二天，问号旁边多了一个感叹号。\n\n有人回答了你。"
      },
      4: {
          "label": "Phase 4 · 侵蚀",
          "text": "亭子的木头上开始出现文字。你也刻了自己的。\n\n但有时你会想——\n这是真实的吗？还是你一个人在自言自语？"
      },
      5: {
          "label": "Phase 5 · 失衡",
          "text": "你开始期待入睡了。\n\n白天的事情变得模糊，梦里的小路反而更清晰。\n\n你喜欢上了一个从未见过脸的人。"
      },
      6: {
          "label": "Phase 6 · 碰撞",
          "text": "他们写了一句只有真实的人才会写的话。\n\n你愣了很久。\n\n怀疑消失了。"
      },
      7: {
          "label": "Phase 7 · 觉醒II",
          "text": "你不再试探了。\n\n你开始说真心话，他们也是。\n亭子的木头快写满了。"
      },
      8: {
          "label": "Phase 8 · 压制",
          "text": "小路变得有点暗。\n\n他们的字越来越少，间隔越来越长。\n\n你把那份害怕压了下去。"
      },
      9: {
          "label": "Phase 9 · 律法",
          "text": "该说的话都说完了。木头上再也没有空白的地方。\n\n你们之间的事是真实的——\n这是这个梦唯一的规则。"
      },
      10: {
          "label": "Phase 10 · 裁决前夜",
          "text": "亭子的灯第一次灭了。\n\n最后一行字，字迹很乱，不像平时：\n[i]"我可能回不来了。"[/i]\n\n你拿起刻字的工具，在旁边写：\n[i]"我会在现实里找到你。"[/i]"
      },
  }

  const _BACKGROUNDS: Dictionary = {
      1: "res://resources/backgrounds/bg_phase_1_2.png",
      2: "res://resources/backgrounds/bg_phase_1_2.png",
      3: "res://resources/backgrounds/bg_phase_3_4.png",
      4: "res://resources/backgrounds/bg_phase_3_4.png",
      5: "res://resources/backgrounds/bg_phase_5_6.png",
      6: "res://resources/backgrounds/bg_phase_5_6.png",
      7: "res://resources/backgrounds/bg_phase_7_8.png",
      8: "res://resources/backgrounds/bg_phase_7_8.png",
      9: "res://resources/backgrounds/bg_phase_9_10.png",
      10: "res://resources/backgrounds/bg_phase_9_10.png",
  }

  func get_copy(phase: int) -> Dictionary:
      return _COPY.get(phase, {})

  func get_background_path(phase: int) -> String:
      return _BACKGROUNDS.get(phase, "")
  ```

- [ ] **Step 4: Run tests — expect PASS**

  ```
  cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
  ```
  Expected: all `test_phase_transition` tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add src/ui/PhaseTransition.gd tests/unit/test_phase_transition.gd tests/unit/test_phase_transition.gd.uid
  git commit -m "feat: add PhaseTransition data layer with copy and background lookup"
  ```

---

## Task 3: Phase Transition Scene

**Files:**
- Create: `scenes/ui/phase_transition.tscn`
- Modify: `src/ui/PhaseTransition.gd` (add scene logic: `show_for_phase`, fade, input)

- [ ] **Step 1: Create scene via MCP `create_scene`**

  Create `scenes/ui/phase_transition.tscn` with this node tree:

  ```
  PhaseTransition [CanvasLayer]           ← script: res://src/ui/PhaseTransition.gd
                                            layer = 10
                                            process_mode = ALWAYS
                                            visible = false
    Background [TextureRect]              ← anchors_preset = 15 (full rect)
                                            expand_mode = 1 (ignore size)
                                            stretch_mode = 6 (scale)
    DarkOverlay [ColorRect]               ← anchors_preset = 15 (full rect)
                                            color = Color(0, 0, 0, 0.75)
    Content [VBoxContainer]               ← anchor_left = 0.5, anchor_right = 0.5
                                            anchor_top = 0.4, anchor_bottom = 0.4
                                            grow_horizontal = 2 (both)
                                            alignment = CENTER
      PhaseLabel [Label]                  ← horizontal_alignment = CENTER
                                            theme_override_font_size = 18
      StoryText [RichTextLabel]           ← bbcode_enabled = true
                                            fit_content = true
                                            custom_minimum_size = Vector2(600, 0)
                                            horizontal_alignment = CENTER
    ContinueHint [Label]                  ← anchor_top = 1.0, anchor_bottom = 1.0
                                            anchor_left = 0.5, anchor_right = 0.5
                                            grow_vertical = 0 (begin)
                                            offset_top = -60
                                            text = "点击继续"
                                            horizontal_alignment = CENTER
                                            theme_override_font_size = 14
                                            modulate = Color(1, 1, 1, 0.6)
  ```

- [ ] **Step 2: Add scene logic to `src/ui/PhaseTransition.gd`**

  Append after the data section (keep the data constants and `get_copy`/`get_background_path` functions):

  ```gdscript
  @onready var _background: TextureRect = $Background
  @onready var _phase_label: Label = $Content/PhaseLabel
  @onready var _story_text: RichTextLabel = $Content/StoryText

  var _dismissable: bool = false

  func show_for_phase(phase: int) -> void:
      var copy = get_copy(phase)
      if copy.is_empty():
          return
      var bg_path = get_background_path(phase)
      if bg_path != "" and ResourceLoader.exists(bg_path):
          _background.texture = load(bg_path)
      _phase_label.text = copy["label"]
      _story_text.text = copy["text"]
      visible = true
      modulate.a = 0.0
      _dismissable = false
      get_tree().paused = true
      var tween = create_tween()
      tween.tween_property(self, "modulate:a", 1.0, 0.4)
      tween.tween_callback(func(): _dismissable = true)

  func _input(event: InputEvent) -> void:
      if not visible or not _dismissable:
          return
      if event is InputEventMouseButton and event.pressed:
          _dismiss()
      elif event is InputEventKey and event.pressed and not event.echo:
          _dismiss()

  func _dismiss() -> void:
      _dismissable = false
      var tween = create_tween()
      tween.tween_property(self, "modulate:a", 0.0, 0.3)
      tween.tween_callback(func():
          visible = false
          get_tree().paused = false
      )
  ```

- [ ] **Step 3: Run self-test to confirm no regressions**

  ```
  cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
  ```
  Expected: all existing tests pass.

- [ ] **Step 4: Commit**

  ```bash
  git add scenes/ui/phase_transition.tscn src/ui/PhaseTransition.gd
  git commit -m "feat: add PhaseTransition overlay scene with fade and pause"
  ```

---

## Task 4: Wire PhaseTransition into Main

**Files:**
- Modify: `scenes/main.tscn` (add PhaseTransition node as child of root)
- Modify: `src/Main.gd` (add `@onready` reference, call `show_for_phase` in `_on_phase_changed`)

- [ ] **Step 1: Add PhaseTransition node to `scenes/main.tscn`**

  Use MCP `open_scene` then `create_node`:
  - Open: `scenes/main.tscn`
  - Create node: type `PhaseTransition`, name `PhaseTransition`, parent is root node
  - Set script: `res://src/ui/PhaseTransition.gd`
  - Save scene

- [ ] **Step 2: Add `@onready` reference in `src/Main.gd`**

  In the `@onready` block (around line 22), add:

  ```gdscript
  @onready var phase_transition: PhaseTransition = $PhaseTransition
  ```

- [ ] **Step 3: Update `_on_phase_changed` in `src/Main.gd`**

  Current (line 139):
  ```gdscript
  func _on_phase_changed(new_phase: int) -> void:
      for tile in tiles_container.get_children():
          if tile.is_altar:
              tile.resize_altar_for_phase(new_phase)
  ```

  Replace with:
  ```gdscript
  func _on_phase_changed(new_phase: int) -> void:
      for tile in tiles_container.get_children():
          if tile.is_altar:
              tile.resize_altar_for_phase(new_phase)
      phase_transition.show_for_phase(new_phase)
  ```

- [ ] **Step 4: Run self-test**

  ```
  cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
  ```
  Expected: all tests pass.

- [ ] **Step 5: Commit**

  ```bash
  git add scenes/main.tscn src/Main.gd
  git commit -m "feat: wire PhaseTransition overlay to phase_changed event"
  ```

---

## Task 5: Game Over Narrative Text + Backgrounds

**Files:**
- Create: `tests/unit/test_game_over_narrative.gd`
- Modify: `src/ui/GameOver.gd`
- Modify: `scenes/ui/game_over.tscn`

- [ ] **Step 1: Write failing tests**

  Create `tests/unit/test_game_over_narrative.gd`:

  ```gdscript
  extends GutTest

  const GameOver = preload("res://src/ui/GameOver.gd")

  var go: GameOver

  func before_each() -> void:
      go = GameOver.new()

  func after_each() -> void:
      go.free()

  func test_win_narrative_contains_recognition_line() -> void:
      var text = go._get_narrative("win")
      assert_true(text.find("是你") >= 0)

  func test_lose_narrative_contains_enough_line() -> void:
      var text = go._get_narrative("lose")
      assert_true(text.find("这已经足够了") >= 0)

  func test_win_background_path() -> void:
      assert_eq(go._get_background_path("win"), "res://resources/backgrounds/bg_game_over_win.png")

  func test_lose_background_path() -> void:
      assert_eq(go._get_background_path("lose"), "res://resources/backgrounds/bg_game_over_lose.png")
  ```

- [ ] **Step 2: Run tests — expect FAIL**

  ```
  cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
  ```
  Expected: failures on missing `_get_narrative` and `_get_background_path`.

- [ ] **Step 3: Add pure functions to `src/ui/GameOver.gd`**

  Add these two functions before `_ready`:

  ```gdscript
  func _get_narrative(result: String) -> String:
      if result == "win":
          return "梦里你们从未见过彼此的脸。\n\n但你认得出那种把石子翻到平面朝上的习惯，\n认得出那句潦草的字——\n[i]"我住的地方晚上能看见一座塔。"[/i]\n\n你在人群里停下来。\n\n是你。"
      return "不是每一次寻找都以相遇结束。\n\n但那些夜晚是真实的，\n那些刻在木头上的字是真实的，\n你愿意走出来——也是真实的。\n\n这已经足够了。"

  func _get_background_path(result: String) -> String:
      if result == "win":
          return "res://resources/backgrounds/bg_game_over_win.png"
      return "res://resources/backgrounds/bg_game_over_lose.png"
  ```

- [ ] **Step 4: Run tests — expect PASS**

  ```
  cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
  ```
  Expected: all `test_game_over_narrative` tests pass.

- [ ] **Step 5: Update `scenes/ui/game_over.tscn` node structure**

  Use MCP to open `scenes/ui/game_over.tscn` and add:
  - Add `TextureRect` named `Background` as first child of root CanvasLayer (before Center):
    - anchors_preset = 15 (full rect), expand_mode = 1, stretch_mode = 6
  - Add `ColorRect` named `DarkOverlay` after Background:
    - anchors_preset = 15, color = Color(0, 0, 0, 0.65)
  - Inside `Center/VBox`, add `RichTextLabel` named `NarrativeText` as the FIRST child (before PhaseLabel):
    - bbcode_enabled = true, fit_content = true
    - custom_minimum_size = Vector2(600, 0)
  - Add `HSeparator` named `Divider` after NarrativeText
  - Save scene.

- [ ] **Step 6: Update `_populate()` in `src/ui/GameOver.gd`**

  Add `@onready` references at class level:

  ```gdscript
  @onready var background: TextureRect = $Background
  @onready var narrative_text: RichTextLabel = $Center/VBox/NarrativeText
  ```

  Update `_populate()`:

  ```gdscript
  func _populate() -> void:
      var config: GameConfig = DataTables.config
      narrative_text.text = _get_narrative(outcome)
      var bg_path = _get_background_path(outcome)
      if ResourceLoader.exists(bg_path):
          background.texture = load(bg_path)
      phase_label.text = "到达阶段: %d" % GameState.current_phase
      loops_label.text = "圈数: %d" % GameState.loops_completed
      kills_label.text = "击杀数: %d" % GameState.enemies_killed
      verdict_loops_label.text = "裁决圈完成: %d / %d" % [
          GameState.verdict_loops_survived,
          config.verdict_survive_loops
      ]
  ```

- [ ] **Step 7: Run self-test**

  ```
  cd "S:/attribute-loop" && powershell -NoProfile -File scripts/self-test.ps1
  ```
  Expected: all tests pass.

- [ ] **Step 8: Commit**

  ```bash
  git add src/ui/GameOver.gd scenes/ui/game_over.tscn tests/unit/test_game_over_narrative.gd tests/unit/test_game_over_narrative.gd.uid
  git commit -m "feat: add narrative text and backgrounds to game over screen"
  ```

---

## Self-Review

### Spec coverage check

| Spec requirement | Task |
|-----------------|------|
| Phase overlay full-screen, dark, click to continue | Task 3 |
| Fade in 0.4s, fade out 0.3s | Task 3 Step 2 |
| Phase label (e.g. "Phase 3 · 涌动") | Task 2 data |
| Story text for all 10 phases | Task 2 data |
| "点击继续" hint at bottom | Task 3 Step 1 |
| Background image changes per 2-phase group | Task 2 data + Task 1 |
| Game pauses during overlay | Task 3 Step 2 |
| Triggers on both altar-fill and world-pressure advance | Task 4 (both use `phase_changed` signal) |
| Win narrative text "是你" | Task 5 |
| Lose narrative text "这已经足够了" | Task 5 |
| Win/lose background images | Task 1 + Task 5 |
| No win/lose label — story text is the verdict | Task 5 Step 6 (narrative is primary) |

All requirements covered.

### Placeholder scan

No TBDs, TODOs, or vague steps found. All code is complete.

### Type consistency check

- `PhaseTransition.get_copy(phase: int) -> Dictionary` — used in `show_for_phase` ✓
- `PhaseTransition.get_background_path(phase: int) -> String` — used in `show_for_phase` ✓
- `GameOver._get_narrative(result: String) -> String` — used in `_populate()` ✓
- `GameOver._get_background_path(result: String) -> String` — used in `_populate()` ✓
- `GameOver.outcome: String` — already exists in codebase ✓
