# AttributeLoop — Narrative Integration Design

**Date:** 2026-06-08
**Status:** Approved

---

## 1. Overview

Two narrative injection points surface the game's story without disrupting the roguelike loop:

1. **Phase Transition Overlay** — full-screen story moment when a phase advances
2. **Game Over Screen** — narrative ending text before the restart button

Both use pre-written copy tied to the existing phase narrative and the shared-dream story from `docs/design/lore.md`.

---

## 2. Phase Transition Overlay

### Trigger

Fires on every phase advance — both player-triggered (altar filled) and world-pressure forced advance.

### Visual Structure

Full-screen dark overlay (animated fade in 0.4s, fade out 0.3s on click).

```
┌─────────────────────────────────────┐
│                                     │
│  [Background image]                 │
│  [Dark overlay: ~75% opacity]       │
│                                     │
│     Phase 3 · 涌动                  │  ← small label, centered top area
│                                     │
│   你把石子摆成了一个问号。            │
│                                     │  ← story text, centered, relaxed line-height
│   第二天，问号旁边多了一个感叹号。    │
│                                     │
│   有人回答了你。                     │
│                                     │
│                                     │
│           点击继续  ·  ·  ·          │  ← small, bottom center, slow pulse animation
└─────────────────────────────────────┘
```

### Background Images

Each 2-phase group has a dedicated background. Same location (loop path + pavilion), same viewpoint — only the scene contents and lighting change to mirror the story beat.

| Phases | Filename | Scene Description |
|--------|----------|-------------------|
| 1–2 | `bg_phase_1_2.png` | Dawn mist. A single flower on the pavilion step. Stones recently rearranged nearby. Someone was just here — but isn't. Empty, quiet, expectant. |
| 3–4 | `bg_phase_3_4.png` | Morning light angled low. Stones on the ground clearly spelling a question mark and an exclamation point side by side. A few carved words just beginning to appear on the pavilion's wooden walls. |
| 5–6 | `bg_phase_5_6.png` | Dusk, warm amber light. Two sets of footprints on the path going opposite directions — never overlapping. The pavilion lamp casts a wide, intimate circle of light. |
| 7–8 | `bg_phase_7_8.png` | Night falling. The pavilion walls dense with writing, nearly full. The path behind is darker. One side of the walls has noticeably fewer recent marks. |
| 9–10 | `bg_phase_9_10.png` | Deep night. The walls completely covered — not a blank space left. The pavilion lamp is out. Only moonlight. The original flower on the step, now dried. |

**Art style:** Warm dream realism. Soft-focus edges, luminous light sources, not quite sharp — like a memory of a place. Reference mood: the visual quietness of 君の名は.

### Phase Copy

| Phase | Label | Story Text |
|-------|-------|-----------|
| 1 | Phase 1 · 觉醒 | 一条发光的小路。<br>亭子里有一盏灯，还有一朵不知道谁放的花。<br><br>你走了进去。<br>你也不知道为什么。 |
| 2 | Phase 2 · 萌动 | 那朵花变颜色了。<br><br>路边的石子被摆成了某种形状，太刻意，不像是偶然。<br><br>也许这里不只有你。 |
| 3 | Phase 3 · 涌动 | 你把石子摆成了一个问号。<br><br>第二天，问号旁边多了一个感叹号。<br><br>有人回答了你。 |
| 4 | Phase 4 · 侵蚀 | 亭子的木头上开始出现文字。你也刻了自己的。<br><br>但有时你会想——<br>这是真实的吗？还是你一个人在自言自语？ |
| 5 | Phase 5 · 失衡 | 你开始期待入睡了。<br><br>白天的事情变得模糊，梦里的小路反而更清晰。<br><br>你喜欢上了一个从未见过脸的人。 |
| 6 | Phase 6 · 碰撞 | 他们写了一句只有真实的人才会写的话。<br><br>你愣了很久。<br><br>怀疑消失了。 |
| 7 | Phase 7 · 觉醒II | 你不再试探了。<br><br>你开始说真心话，他们也是。<br>亭子的木头快写满了。 |
| 8 | Phase 8 · 压制 | 小路变得有点暗。<br><br>他们的字越来越少，间隔越来越长。<br><br>你把那份害怕压了下去。 |
| 9 | Phase 9 · 律法 | 该说的话都说完了。木头上再也没有空白的地方。<br><br>你们之间的事是真实的——<br>这是这个梦唯一的规则。 |
| 10 | Phase 10 · 裁决前夜 | 亭子的灯第一次灭了。<br><br>最后一行字，字迹很乱，不像平时：<br>*"我可能回不来了。"*<br><br>你拿起刻字的工具，在旁边写：<br>*"我会在现实里找到你。"* |

---

## 3. Game Over Screen

### Structure

Narrative text occupies the upper portion of the screen. The restart button sits below, separated by a divider. No win/lose label — the story text is the verdict.

```
┌─────────────────────────────────────┐
│  [Background image]                 │
│  [Dark overlay]                     │
│                                     │
│   [Narrative text, centered]        │
│                                     │
│   ─────────────────────────         │
│                                     │
│           再来一次                   │
└─────────────────────────────────────┘
```

### Win Ending

**Background (`bg_game_over_win.png`):** Moonlit path at night. In the far distance, two figures have just met — backs to the camera, facing the pavilion. Warm light, close but not sentimental.

**Copy:**
> 梦里你们从未见过彼此的脸。
>
> 但你认得出那种把石子翻到平面朝上的习惯，
> 认得出那句潦草的字——
> *"我住的地方晚上能看见一座塔。"*
>
> 你在人群里停下来。
>
> 是你。

### Lose Ending

**Background (`bg_game_over_lose.png`):** The empty pavilion, lamp still burning. Walls covered in writing. No one there — but the light is on, like it's still waiting.

**Copy:**
> 不是每一次寻找都以相遇结束。
>
> 但那些夜晚是真实的，
> 那些刻在木头上的字是真实的，
> 你愿意走出来——也是真实的。
>
> 这已经足够了。

---

## 4. Assets Required

| File | Type | Used In |
|------|------|---------|
| `resources/backgrounds/bg_phase_1_2.png` | 1920×1080 | Phase 1–2 overlay |
| `resources/backgrounds/bg_phase_3_4.png` | 1920×1080 | Phase 3–4 overlay |
| `resources/backgrounds/bg_phase_5_6.png` | 1920×1080 | Phase 5–6 overlay |
| `resources/backgrounds/bg_phase_7_8.png` | 1920×1080 | Phase 7–8 overlay |
| `resources/backgrounds/bg_phase_9_10.png` | 1920×1080 | Phase 9–10 overlay |
| `resources/backgrounds/bg_game_over_win.png` | 1920×1080 | Win ending screen |
| `resources/backgrounds/bg_game_over_lose.png` | 1920×1080 | Lose ending screen |

---

## 5. Implementation Scope

### New scenes / scripts

- `scenes/ui/phase_transition.tscn` — the overlay scene
- `src/ui/PhaseTransition.gd` — handles fade in/out, copy lookup, background selection, click-to-dismiss

### Modified scenes / scripts

- `scenes/ui/game_over.tscn` — add narrative text label + win/lose background switching
- `src/ui/GameOver.gd` — populate narrative text and background based on win/lose signal
- `scenes/main.tscn` — instantiate PhaseTransition overlay, connect to `phase_changed` event

### Data

- Phase copy lives in `PhaseTransition.gd` as a dictionary keyed by phase number
- Background selection uses a lookup: phases 1–2 → bg_phase_1_2, 3–4 → bg_phase_3_4, etc.
- Game over copy lives in `GameOver.gd` as two string constants

### Event connections

| Event | Handler |
|-------|---------|
| `EventBus.phase_changed` | PhaseTransition: show overlay for new phase |
| `EventBus.game_won` | GameOver: show win narrative + win background |
| `EventBus.player_died` | GameOver: show lose narrative + lose background |

---

## 6. Out of Scope

- Per-phase music or sound changes
- Animated elements within the background images
- Localization (copy is Chinese only for now)
- Skip/replay narrative history log
