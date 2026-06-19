# Phase Narrative & Background Realignment (10 → 6 Phases) — Design

**Date:** 2026-06-19
**Status:** Approved
**Scope:** Single-file narrative rewrite + background image rename/remap in `PhaseTransition.gd`

## Context

The game's phase count was reduced from 10 to 6 (+ a verdict-loop spawn table at phase 7). The
phase **data** files (`data/phases/phase_1..7.tres`) and their names were already updated:

| phase_id | name (data)            | role                                  |
|----------|------------------------|---------------------------------------|
| 1        | 觉醒                   | normal                                |
| 2        | 涌动                   | normal                                |
| 3        | 侵蚀                   | normal                                |
| 4        | 失衡                   | normal                                |
| 5        | 裁决前夜               | `verdict_trigger_phase = 5`           |
| 6        | 裁决前夜Boss           | boss phase                            |
| 7        | 裁决圈                 | verdict-loop spawn-weight table only  |

However, the **narrative** (`PhaseTransition.gd::_COPY`) and **background mapping**
(`PhaseTransition.gd::_BACKGROUNDS`) still reflect the old 10-phase structure:

- `_COPY` has 10 entries with old names (萌动 / 碰撞 / 觉醒II / 压制 / 律法 …) that no longer match
  the data, and entries 7–10 are unreachable dead code (`verdict_trigger_phase = 5` means the
  transition screen fires at most through phases 1–6).
- `_BACKGROUNDS` maps 10 phases onto 5 images (`bg_phase_1_2`, `bg_phase_3_4`, `bg_phase_5_6`,
  `bg_phase_7_8`, `bg_phase_9_10`). Under the new 6-phase layout, `bg_phase_7_8` and `bg_phase_9_10`
  become dead assets, and the verdict loop (entered from phase 5) has no dedicated background.

## Goal

Realign the story text and background images to the 6-phase structure, and clean up the dead image
assets, by editing only `PhaseTransition.gd` and renaming the image files.

## Decisions

1. **Narrative approach — compress, not rewrite.** Condense the existing 10-phase story arc
   ("发光的小路 / 亭子 / 刻字留言" imagery, emotional escalation toward 裁决前夜) into 6
   entries that align with the new phase names. Preserve the existing imagery, mood progression,
   and the strongest closing beats. (Roughly 1.5 old entries collapse into each new entry.)
2. **Verdict loop gets no dedicated narrative or background.** It is treated as a looping extension
   of phase 5, reusing `bg_phase_5.png`. Saves one asset.
3. **Background coverage — 5 images across 6 phases.** Since only 5 phase background images exist,
   one pair of adjacent phases shares an image. The shared pair is **phases 5 & 6**
   (裁决前夜 → 裁决前夜Boss), which is the most mood-coherent pairing and the natural place for
   reuse — the boss phase inherits the heaviest atmosphere.
4. **Rename all background images to `bg_phase_N.png`.** Every file is renamed so that the filename
   number directly signals "the phase-N mood baseline," eliminating the old `phase_7_8` /
   `phase_9_10` names that imply non-existent phases 7–10.

## Design

### Narrative — `_COPY` (6 entries)

| phase | label                         | copy direction (compressed from the 10-phase arc; final wording polished at implementation time) |
|-------|-------------------------------|----------------------------------------------------------------------------------------------------|
| 1     | Phase 1 · 觉醒               | 发光的小路,亭子里一盏灯和一朵不知谁放的花。你走了进去。                                          |
| 2     | Phase 2 · 涌动               | 路边的石子被摆成某种太刻意的形状。你也摆了一个问号。                                            |
| 3     | Phase 3 · 侵蚀               | 亭子木头上出现文字,你也刻了自己的。这是真实的吗?                                              |
| 4     | Phase 4 · 失衡               | 你开始期待入睡。白天模糊,梦里的小路反而清晰。喜欢上了一个没见过脸的人。                          |
| 5     | Phase 5 · 裁决前夜          | 他们写了一句只有真实的人才会写的话。怀疑消失,木头再也没有空白。                                  |
| 6     | Phase 6 · 裁决前夜Boss      | 亭子的灯第一次灭了。最后一行字字迹很乱:"我可能回不来了。"                                       |

The spirit of the old "觉醒II / 压制 / 律法" entries (试探 → 真心话 → 说完了) is folded into
entry 5. The original "裁决前夜" closing beat ("灯灭了 + 乱字") is retained as entry 6's boss
lead-in. Wording is indicative; refined during implementation.

### Backgrounds — `_BACKGROUNDS` (6 keys → 5 images)

**File renames (all five, each with its `.import` file):**

| old name              | new name          |
|-----------------------|-------------------|
| `bg_phase_1_2.png`    | `bg_phase_1.png`  |
| `bg_phase_3_4.png`    | `bg_phase_2.png`  |
| `bg_phase_5_6.png`    | `bg_phase_3.png`  |
| `bg_phase_7_8.png`    | `bg_phase_4.png`  |
| `bg_phase_9_10.png`    | `bg_phase_5.png`  |

**Mapping (each phase → its baseline image; 5 & 6 share `bg_phase_5.png`):**

| phase | background              |
|-------|-------------------------|
| 1     | `res://resources/backgrounds/bg_phase_1.png` |
| 2     | `res://resources/backgrounds/bg_phase_2.png` |
| 3     | `res://resources/backgrounds/bg_phase_3.png` |
| 4     | `res://resources/backgrounds/bg_phase_4.png` |
| 5     | `res://resources/backgrounds/bg_phase_5.png` |
| 6     | `res://resources/backgrounds/bg_phase_5.png` |

Under this mapping, each phase's on-screen mood shifts up one tier versus the old layout (phase N now
shows the image that previously covered phases N and N+1), giving an even per-phase visual
progression. The verdict loop (entered from phase 5) continues using `bg_phase_5.png`.

## Changes

1. **Rename 5 background images** (+ their `.import` files) per the table above.
2. **Rewrite `src/ui/PhaseTransition.gd`:**
   - `_COPY`: 10 entries → 6 entries (new names + compressed copy per the narrative table).
   - `_BACKGROUNDS`: 6 keys mapping to the 5 renamed images (phases 5 & 6 share `bg_phase_5.png`).
3. **No other files touched.** Data files (`phase_N.tres`), `GameConfig`, and `GameLoop` are
   unchanged — they already reflect the 6-phase layout.

## Verification

- **Layer 1 (syntax):** PostToolUse hook reports no errors for the edited file.
- **Layer 2 (unit tests):** `scripts/self-test.ps1` passes with no regressions.
- **Layer 3 (visual, Godot editor open):** Trigger phase transitions 1–5; confirm each loads its
  correct background and displays its story text. Confirm no missing-resource warnings in the
  editor for the old `phase_X_Y` paths.
- **Layer 4 (docs):** Update the narrative/phase-transition module doc.

## Out of Scope

- No changes to `phase_N.tres` data, `GameConfig`, or `GameLoop`.
- No new background image generation for the verdict loop.
- No dedicated verdict-loop transition screen or narrative entry.
- No restructuring of `_COPY` / `_BACKGROUNDS` into data files (considered, rejected as over-design —
  no evidence of frequent narrative churn that would justify expanding `PhaseData`).
