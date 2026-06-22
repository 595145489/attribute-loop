# Phase Transition

**Responsibility:** Shows the narrative transition overlay between phases — a full-screen
background image plus a phase label and a short story paragraph — when the player advances to a
new phase.

## Key class

- `PhaseTransition` (`src/ui/PhaseTransition.gd`) — a `CanvasLayer`.

### Data

- `_COPY: Dictionary` — keyed by phase id (1–6). Each entry has `label` (e.g. `Phase 1 · 觉醒`)
  and `text` (the story paragraph; supports BBCode via the `RichTextLabel`).
- `_BACKGROUNDS: Dictionary` — keyed by phase id (1–6) → a
  `res://resources/backgrounds/bg_phase_N.png` path. **Phases 5 & 6 share `bg_phase_5.png`**
  (裁决前夜 → boss share the heaviest atmosphere). Five images cover six phases.

### Public API

- `get_copy(phase: int) -> Dictionary` — returns the `{label, text}` entry, or `{}` for phases with
  no entry.
- `get_background_path(phase: int) -> String` — returns the background resource path, or `""` for
  phases with no mapping.
- `show_for_phase(phase: int) -> void` — loads the background (if the resource exists), sets the
  label/text, makes the overlay visible, pauses the tree, and fades in. Becomes dismissable after
  the fade completes; any mouse-click or key dismisses it (fades out, unpauses).

### Narrative note

The story is a 6-entry arc compressed from an earlier 10-phase version, aligned to the data-file
phase names (`觉醒 / 涌动 / 侵蚀 / 失衡 / 裁决前夜 / 裁决前夜Boss`).

The **stone (石子) thread** is a deliberate 承上启下 motif: introduced in phase 2 (the
`问号`/`感叹号` exchange and the connecting line `也许这里不只有你`) and bookended in phase 5
(`那个石子摆成的问号，早已经有了答案`). Guard tests
(`test_phase2_stone_thread_present`, `test_phase5_stone_bookend_present`) prevent the thread from
being accidentally deleted during copy polish — per project convention, the approved copy is
polish-only: wording rhythm may be refined, but no imagery, beat, or connecting line may be removed.

## Execution flow

1. `Main` calls `_phase_transition.show_for_phase(new_phase)` on phase change (and `show_for_phase(1)`
   on the boot path).
2. `show_for_phase` loads the background texture, fills the label/text, shows the overlay, pauses the
   tree, and tweens alpha 0→1.
3. After the fade, `_dismissable` becomes true; the next input event triggers `_dismiss`
   (alpha 1→0, hide, unpause).

## Background assets

`resources/backgrounds/bg_phase_1.png` … `bg_phase_5.png` — five phase baseline images. Each `.png`
has an `.import` sidecar (Godot import metadata). Filenames signal the phase baseline directly;
phase 6 (boss) reuses `bg_phase_5.png`.

## Dependencies

- Background images under `resources/backgrounds/` (`bg_phase_1.png` … `bg_phase_5.png`).
- Driven by `src/Main.gd`, which calls `show_for_phase` on phase changes.
- Phase 6 ("裁决前夜Boss") is a normal phase with its own pressure window; its narrative
  plays via `phase_changed(6)` exactly like phases 1–5 (it shows when the player advances
  into phase 6 after beating phase 5's boss, before phase 6's own boss).
- The verdict loop (`verdict_trigger_phase = 6`, entered after phase 6's boss is beaten)
  has no transition screen of its own — it is treated as a looping extension of phase 6
  and reuses `bg_phase_5.png`.
