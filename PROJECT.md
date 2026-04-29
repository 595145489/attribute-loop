# Game Project Document

## Tech Stack

| Item | Detail |
|------|--------|
| Engine | Godot 4.6.2 stable Mono |
| Language | GDScript |
| Target platform | HTML5 (Web export) |
| Project directory | `S:\attribute-loop` |
| Godot executable | `S:\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64.exe` |

---

## Game Design

### Title
> TBD

### Genre
Dynamic strategy Roguelike

### Core Concept
The player rides an auto-running looping track, drags and strips structural shells and core entry-components from enemies, then stitches them onto themselves or the environment to rewrite game logic in real time. Top-down view, inspired by Loop Hero.

### Core Loop
- Character auto-walks along a closed loop track
- Enemies appear on the track and auto-fight
- Player can **pause** at any time to enter drag mode
- Drag to strip entry components from enemies (trigger / verb / effect)
- Components go into the inventory and can be assembled into rules
- Rules attached to the player or environment tiles activate and alter game logic
- Each loop cycle, entries accumulate in the world and shift map state

### Entry System
Entries are decomposable rule sentences structured as:
```
[Trigger] + [Verb] + [Effect]
```

- Components can be stored individually in inventory
- Rules with empty slots are dormant (inactive)
- Forcing a wrong-type component into a slot produces a **mutation entry** (unknown effect, high risk / high reward)
- Strong entries have "will" — they may attempt to migrate to a stronger host

### Positive Feedback Design
| Layer | When | Experience |
|-------|------|------------|
| Immediate feel | Drag-strip moment | Tear effect, enemy behavior breaks |
| Rule trigger | Player-built rule fires | Particle trace, "I made this" |
| World rewrite | Cross-loop entry accumulation | Archaeologizing your own past actions |

### View & Controls
- Top-down (inspired by Loop Hero)
- Character moves automatically
- Pause enters drag/assembly mode

---

## V1 Milestone: Demo

**Goal:** Prove the "strip → assemble → rule fires" core loop is fun

| Included | Excluded |
|----------|----------|
| Auto-walking character on loop track (top-down) | Multi-loop world accumulation |
| 2 enemy types with 2–3 components each | Mutation system |
| Pause + drag to strip components | Boss / level structure |
| Simplified rule assembly (trigger + effect, 2 slots) | Polished art |
| Clear visual feedback when rule fires | Sound effects |
| Stable for 2–3 loops | |

---

## Scene Structure

> Updated as development progresses — see `doc/main.md`

---

## Progress

| Module | Status | Notes |
|--------|--------|-------|
| Project document | ✅ Done | |
| Godot project init | ✅ Done | |
| Track system | ✅ Done | |
| Player auto-movement | ✅ Done | |
| Enemy system | ✅ Done | |
| Entry component system | ✅ Done | |
| Pause / drag mode (state) | ✅ Done | |
| Drag-strip UI | ⬜ Todo | |
| Rule assembly UI | ⬜ Todo | |
| Rule trigger feedback | ⬜ Todo | |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-04-28 | Created project doc, defined tech stack |
| 2026-04-29 | Completed design discussion, defined V1 scope, built project skeleton |
