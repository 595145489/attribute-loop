# Phase Narrative & Background Realignment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Realign `PhaseTransition` story copy and background images to the new 6-phase layout (from the old 10-phase structure) by editing one GDScript file plus renaming five background images.

**Architecture:** Pure data change — no logic. `PhaseTransition.gd`'s two constant dictionaries (`_COPY`, `_BACKGROUNDS`) are rewritten: 10 narrative entries compressed to 6 (aligned to the data-file phase names), and 6 background keys remapped onto 5 renamed `bg_phase_N.png` images (phases 5 & 6 share one). No changes to data files, `GameConfig`, or `GameLoop`.

**Tech Stack:** Godot 4 GDScript, GUT unit tests, PowerShell self-test runner, project-wide self-test protocol (see `CLAUDE.md`).

**Spec:** `docs/superpowers/specs/2026-06-19-phase-narrative-realignment-design.md`

**Important constraint (from user):** At implementation time the approved copy is **polish-only** — wording rhythm may be refined, but no imagery, plot beat, connecting line, or motif bookend may be deleted. The guard tests in Task 1 lock the stone (石子) thread specifically.

---

## File Structure

- **Modify:** `src/ui/PhaseTransition.gd` — rewrite `_COPY` (10→6 entries) and `_BACKGROUNDS` (remap to renamed images).
- **Modify:** `tests/unit/test_phase_transition.gd` — rewrite tests for 6 phases + new background paths; add guard tests for the stone thread.
- **Rename:** five `.png` files and their `.import` sidecars under `resources/backgrounds/` (see Task 2 table).
- **Create:** `docs/modules/phase-transition.md` — module documentation (CLAUDE.md Self-Test Step 4).

**Reference facts (verified during planning):**
- The only code references to these background images are `src/ui/PhaseTransition.gd` and `tests/unit/test_phase_transition.gd`. No `.tscn`/`.tres` references them by path or uid.
- `verdict_trigger_phase = 5`, so the transition screen (`show_for_phase`) fires at most through phases 1–6. Phase 6 copy is reachable if/when the player reaches the boss phase; otherwise it sits inert with no side effects.

---

### Task 1: Rewrite `PhaseTransition.gd` constants (TDD)

**Files:**
- Test: `tests/unit/test_phase_transition.gd`
- Modify: `src/ui/PhaseTransition.gd:4-58`

- [ ] **Step 1: Replace the test file with the new 6-phase tests**

Write `tests/unit/test_phase_transition.gd` (full replacement):

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

func test_get_copy_phase_6_label() -> void:
	var copy = pt.get_copy(6)
	assert_eq(copy["label"], "Phase 6 · 裁决前夜Boss")

func test_get_copy_phase_1_text_not_empty() -> void:
	var copy = pt.get_copy(1)
	assert_true(copy["text"].length() > 0)

func test_get_copy_all_six_phases_have_entries() -> void:
	for i in range(1, 7):
		var copy = pt.get_copy(i)
		assert_false(copy.is_empty(), "Phase %d missing copy" % i)

func test_get_copy_phase_7_is_empty() -> void:
	assert_eq(pt.get_copy(7), {})

func test_phase2_stone_thread_present() -> void:
	# 承上启下 connecting line — must not be deleted at polish time.
	var copy = pt.get_copy(2)
	assert_true(copy["text"].find("也许这里不只有你") != -1, "Phase 2 must keep the stone connecting line")

func test_phase5_stone_bookend_present() -> void:
	# Stone (石子) bookend echo of phase 2's 问号 — must not be deleted at polish time.
	var copy = pt.get_copy(5)
	assert_true(copy["text"].find("石子摆成的问号") != -1, "Phase 5 must keep the stone bookend echo")

func test_get_background_phase_1() -> void:
	assert_eq(pt.get_background_path(1), "res://resources/backgrounds/bg_phase_1.png")

func test_get_background_phase_2() -> void:
	assert_eq(pt.get_background_path(2), "res://resources/backgrounds/bg_phase_2.png")

func test_get_background_phase_3() -> void:
	assert_eq(pt.get_background_path(3), "res://resources/backgrounds/bg_phase_3.png")

func test_get_background_phase_4() -> void:
	assert_eq(pt.get_background_path(4), "res://resources/backgrounds/bg_phase_4.png")

func test_get_background_phase_5() -> void:
	assert_eq(pt.get_background_path(5), "res://resources/backgrounds/bg_phase_5.png")

func test_get_background_phase_6_shares_phase_5() -> void:
	assert_eq(pt.get_background_path(6), "res://resources/backgrounds/bg_phase_5.png")

func test_get_background_phase_7_is_empty() -> void:
	assert_eq(pt.get_background_path(7), "")
```

- [ ] **Step 2: Run the tests to verify they fail against the current code**

Run: `powershell -NoProfile -File scripts/self-test.ps1`
Expected: FAIL — e.g. `test_get_copy_phase_6_label` expects `"Phase 6 · 裁决前夜Boss"` but current phase 6 label is `"Phase 6 · 碰撞"`; `test_get_background_phase_1` expects `bg_phase_1.png` but current is `bg_phase_1_2.png`.

- [ ] **Step 3: Replace `_COPY` and `_BACKGROUNDS` in `src/ui/PhaseTransition.gd`**

Replace the two constant dictionaries (lines 4–58, the `const _COPY` and `const _BACKGROUNDS` blocks) with exactly:

```gdscript
const _COPY: Dictionary = {
	1: {
		"label": "Phase 1 · 觉醒",
		"text": "一条发光的小路。\n亭子里有一盏灯，还有一朵不知道谁放的花。\n\n你走了进去。\n你也不知道为什么。"
	},
	2: {
		"label": "Phase 2 · 涌动",
		"text": "路边的石子被摆成了某种形状，太刻意，不像偶然。\n\n你摆了一个问号。\n第二天，问号旁边多了一个感叹号。\n\n也许这里不只有你。\n有人回答了你。"
	},
	3: {
		"label": "Phase 3 · 侵蚀",
		"text": "亭子的木头上开始出现文字。你也刻了自己的。\n\n但有时你会想——\n这是真实的吗？还是你一个人在自言自语？"
	},
	4: {
		"label": "Phase 4 · 失衡",
		"text": "你开始期待入睡了。\n\n白天的事情变得模糊，梦里的小路反而更清晰。\n\n你喜欢上了一个从未见过脸的人。"
	},
	5: {
		"label": "Phase 5 · 裁决前夜",
		"text": "那个石子摆成的问号，早已经有了答案。\n\n他们写了一句只有真实的人才会写的话。\n怀疑消失了。\n你们开始说真心话，不再试探。\n\n亭子的木头再也没有空白的地方。\n你们之间的事是真实的——\n这是这个梦唯一的规则。"
	},
	6: {
		"label": "Phase 6 · 裁决前夜Boss",
		"text": "亭子的灯第一次灭了。\n\n最后一行字，字迹很乱，不像平时：\n[i]“我可能回不来了。”[/i]\n\n你拿起刻字的工具，在旁边写：\n[i]“我会在现实里找到你。”[/i]"
	},
}

const _BACKGROUNDS: Dictionary = {
	1: "res://resources/backgrounds/bg_phase_1.png",
	2: "res://resources/backgrounds/bg_phase_2.png",
	3: "res://resources/backgrounds/bg_phase_3.png",
	4: "res://resources/backgrounds/bg_phase_4.png",
	5: "res://resources/backgrounds/bg_phase_5.png",
	6: "res://resources/backgrounds/bg_phase_5.png",
}
```

Leave the rest of the file (`@onready` vars, `get_copy`, `get_background_path`, `show_for_phase`, `_input`, `_dismiss`) untouched.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `powershell -NoProfile -File scripts/self-test.ps1`
Expected: PASS — all `test_phase_transition.gd` tests green.

- [ ] **Step 5: Commit**

```bash
cd "S:/attribute-loop"
git add src/ui/PhaseTransition.gd tests/unit/test_phase_transition.gd
git commit -m "$(cat <<'EOF'
feat(narrative): realign PhaseTransition copy & backgrounds to 6 phases

Compress 10-phase story into 6 entries matching data-file phase names;
remap 6 background keys onto 5 renamed bg_phase_N.png images (5 & 6 share).
Add stone-thread guard tests.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Rename the five background images and fix import sidecars

**Files:**
- Rename (each `.png` + its `.png.import`) under `resources/backgrounds/`:

| old basename        | new basename     |
|---------------------|------------------|
| `bg_phase_1_2`      | `bg_phase_1`     |
| `bg_phase_3_4`      | `bg_phase_2`     |
| `bg_phase_5_6`      | `bg_phase_3`     |
| `bg_phase_7_8`      | `bg_phase_4`     |
| `bg_phase_9_10`     | `bg_phase_5`     |

**Why both `.png` and `.import`:** Godot stores import metadata in the `.import` sidecar next to the image. Each sidecar records its own `source_file`, `path`, and `dest_files` using the old basename, plus a stable uid. We rename the files together and update those three internal path references, **preserving the uid** (so any latent uid reference stays valid) and the content hash in the cached-filename (it is a content hash; the image bytes are unchanged). On next editor open Godot re-imports; an orphaned `.godot/imported/bg_phase_*_*.ctex` under an old name is harmless and ignored.

- [ ] **Step 1: Rename all ten files (5 images × 2) with `git mv`**

Run (Git Bash / POSIX):

```bash
cd "S:/attribute-loop"
git mv resources/backgrounds/bg_phase_1_2.png     resources/backgrounds/bg_phase_1.png
git mv resources/backgrounds/bg_phase_1_2.png.import resources/backgrounds/bg_phase_1.png.import
git mv resources/backgrounds/bg_phase_3_4.png     resources/backgrounds/bg_phase_2.png
git mv resources/backgrounds/bg_phase_3_4.png.import resources/backgrounds/bg_phase_2.png.import
git mv resources/backgrounds/bg_phase_5_6.png     resources/backgrounds/bg_phase_3.png
git mv resources/backgrounds/bg_phase_5_6.png.import resources/backgrounds/bg_phase_3.png.import
git mv resources/backgrounds/bg_phase_7_8.png     resources/backgrounds/bg_phase_4.png
git mv resources/backgrounds/bg_phase_7_8.png.import resources/backgrounds/bg_phase_4.png.import
git mv resources/backgrounds/bg_phase_9_10.png     resources/backgrounds/bg_phase_5.png
git mv resources/backgrounds/bg_phase_9_10.png.import resources/backgrounds/bg_phase_5.png.import
```

- [ ] **Step 2: Fix the three internal path references inside each renamed `.import` file**

In each renamed `.import` sidecar, replace the old basename (`bg_phase_X_Y`) with the new basename (`bg_phase_N`) on exactly these three lines, leaving the uid and the content-hash portion untouched:

- `source_file="res://resources/backgrounds/bg_phase_X_Y.png"` → `...bg_phase_N.png`
- `path="res://.godot/imported/bg_phase_X_Y.png-<HASH>.ctex"` → `...bg_phase_N.png-<HASH>.ctex`
- `dest_files=["res://.godot/imported/bg_phase_X_Y.png-<HASH>.ctex"]` → `...bg_phase_N.png-<HASH>.ctex`

Per-file mapping to apply (old→new basename):

| file                                | replace `bg_phase_1_2` → `bg_phase_1` |
|-------------------------------------|----------------------------------------|
| `bg_phase_1.png.import`             | `bg_phase_1_2` → `bg_phase_1`          |
| `bg_phase_2.png.import`             | `bg_phase_3_4` → `bg_phase_2`          |
| `bg_phase_3.png.import`             | `bg_phase_5_6` → `bg_phase_3`          |
| `bg_phase_4.png.import`             | `bg_phase_7_8` → `bg_phase_4`          |
| `bg_phase_5.png.import`             | `bg_phase_9_10` → `bg_phase_5`         |

Example — `bg_phase_1.png.import` after edit (only the three path lines change; uid and hash retained from the original sidecar):

```
[remap]

importer="texture"
type="CompressedTexture2D"
uid="uid://cbkijnmfky5il"
path="res://.godot/imported/bg_phase_1.png-7e0e0dc4c743d52281dba172cc1bad0e.ctex"
metadata={
"vram_texture": false
}

[deps]

source_file="res://resources/backgrounds/bg_phase_1.png"
dest_files=["res://.godot/imported/bg_phase_1.png-7e0e0dc4c743d52281dba172cc1bad0e.ctex"]

[params]
... (unchanged)
```

> The `uid://...` value differs per file; **keep whatever uid each original sidecar had** — do not overwrite it with the example uid above.

- [ ] **Step 3: Verify no stale references to the old basenames remain**

Run (Git Bash / POSIX):

```bash
cd "S:/attribute-loop"
grep -rn "bg_phase_1_2\|bg_phase_3_4\|bg_phase_5_6\|bg_phase_7_8\|bg_phase_9_10" \
  --include=*.gd --include=*.tscn --include=*.tres --include=*.import .
```

Expected: **no output** (all references resolved). If any line prints, fix it before continuing.

- [ ] **Step 4: Verify the new image set is exactly 5 `.png` + 5 `.import`**

Run (Git Bash / POSIX):

```bash
cd "S:/attribute-loop"
ls resources/backgrounds/ | grep -E "^bg_phase_[0-9]+\.png"
```

Expected output (5 files):
```
bg_phase_1.png
bg_phase_2.png
bg_phase_3.png
bg_phase_4.png
bg_phase_5.png
```

- [ ] **Step 5: Commit**

```bash
cd "S:/attribute-loop"
git add resources/backgrounds/
git commit -m "$(cat <<'EOF'
refactor(assets): rename phase background images to bg_phase_N.png

Rename the five phase background images (and their .import sidecars,
preserving uids) so filenames signal the phase baseline directly. Phases
5 & 6 share bg_phase_5.png; the old phase_7_8 / phase_9_10 names are gone.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Full self-test (Layers 1 & 2)

This is the CLAUDE.md Self-Test Protocol Steps 1 & 2, run together.

- [ ] **Step 1: Confirm no PostToolUse syntax errors** from editing `PhaseTransition.gd`. If any syntax error was reported, fix before continuing.

- [ ] **Step 2: Run the headless unit test suite**

Run: `powershell -NoProfile -File scripts/self-test.ps1`
Expected: all tests PASS, including the new `test_phase_transition.gd` cases and no regressions elsewhere.

- [ ] **Step 3: If any test fails** — fix the code, re-run. Do not proceed to Task 4 until green.

---

### Task 4: Visual integration test (Layer 3 — requires Godot editor open)

CLAUDE.md Self-Test Protocol Step 3. **Requires the Godot editor to be open with this project loaded.** If the editor is not open, skip this task and note it to the user.

- [ ] **Step 1: Create the test-mode sentinel file**

Write an empty file to `S:/attribute-loop/tests/.test_mode`.

- [ ] **Step 2: Play the main scene via the editor**

Use MCP `execute_editor_script` with this code:

```gdscript
var plugin = Engine.get_meta("GodotMCPPlugin")
plugin.get_editor_interface().play_main_scene()
```

- [ ] **Step 3: Poll for the screenshot**

Poll every 2 seconds (timeout 20s) until `tests/screenshots/last_run.png` appears.

- [ ] **Step 4: Read the screenshot and verify**

Open `tests/screenshots/last_run.png` with the Read tool. Verify:
- Game window rendered (not black/blank)
- No obvious error dialogs

- [ ] **Step 5: Trigger phase transitions 1→5 and confirm backgrounds load**

Advance the game through phases 1–5 (normal play to fill altars / advance phases). At each `PhaseTransition` overlay confirm:
- The correct background image renders (no missing-texture placeholder / magenta)
- The story text displays
- No `ERROR: Could not preload resource file ... bg_phase_*` lines appear in the editor Output

If the editor Output shows missing-resource errors for `bg_phase_*` paths, the `.import` rename in Task 2 Step 2 has a stale path — re-check that sidecar and re-run.

- [ ] **Step 6: Delete the sentinel file**

Delete `S:/attribute-loop/tests/.test_mode`.

- [ ] **Step 7: Stop the running game** (editor ▶ Stop).

---

### Task 5: Write module documentation (Layer 4)

CLAUDE.md Self-Test Protocol Step 4.

**Files:**
- Create: `docs/modules/phase-transition.md`

- [ ] **Step 1: Write the module doc**

Create `docs/modules/phase-transition.md`:

````markdown
# Phase Transition

**Responsibility:** Shows the narrative transition overlay between phases — a full-screen background image plus a phase label and a short story paragraph — when the player advances to a new phase.

## Key class

- `PhaseTransition` (`src/ui/PhaseTransition.gd`) — `CanvasLayer`.

### Data

- `_COPY: Dictionary` — keyed by phase id (1–6). Each entry has `label` (e.g. `Phase 1 · 觉醒`) and `text` (the story paragraph; supports BBCode via the `RichTextLabel`).
- `_BACKGROUNDS: Dictionary` — keyed by phase id (1–6) → a `res://resources/backgrounds/bg_phase_N.png` path. **Phases 5 & 6 share `bg_phase_5.png`** (裁决前夜 → boss share the heaviest atmosphere). Five images cover six phases.

### Public API

- `get_copy(phase: int) -> Dictionary` — returns the `{label, text}` entry, or `{}` for phases with no entry.
- `get_background_path(phase: int) -> String` — returns the background resource path, or `""` for phases with no mapping.
- `show_for_phase(phase: int) -> void` — loads the background (if the resource exists), sets the label/text, makes the overlay visible, pauses the tree, and fades in. Becomes dismissable after the fade completes; any mouse-click or key dismisses it (fades out, unpauses).

### Narrative note

The story is a 6-entry arc compressed from an earlier 10-phase version. The **stone (石子) thread** is a deliberate 承上启下 motif: introduced in phase 2 (the `问号`/`感叹号` exchange and the connecting line `也许这里不只有你`) and bookended in phase 5 (`那个石子摆成的问号，早已经有了答案`). Guard tests (`test_phase2_stone_thread_present`, `test_phase5_stone_bookend_present`) prevent the thread from being accidentally deleted during copy polish.

## Execution flow

1. `Main._on_phase_changed(new_phase)` (or the boot path at phase 1) calls `_phase_transition.show_for_phase(new_phase)`.
2. `show_for_phase` loads the background texture, fills the label/text, shows the overlay, pauses the tree, and tweens alpha 0→1.
3. After the fade, `_dismissable` becomes true; the next input event triggers `_dismiss` (alpha 1→0, hide, unpause).

## Dependencies

- Background images under `resources/backgrounds/` (`bg_phase_1.png` … `bg_phase_5.png`).
- Driven by `src/Main.gd`, which calls `show_for_phase` on phase changes.
- Verdict loop (`verdict_trigger_phase = 5`) has **no** dedicated transition screen — it is treated as a looping extension of phase 5 and reuses `bg_phase_5.png`.
````

- [ ] **Step 2: Commit**

```bash
cd "S:/attribute-loop"
git add docs/modules/phase-transition.md
git commit -m "$(cat <<'EOF'
docs: add phase-transition module documentation

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

---

## Completion

After Task 5, all four self-test layers are satisfied (syntax, unit tests, visual, docs). Report completion to the user for acceptance per CLAUDE.md Self-Test Protocol Step 5.
