# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**AttributeLoop** — A dynamic strategy Roguelike H5 game. See `PROJECT.md` for full design.

## Environment

- **Godot**: `S:\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64.exe`
- **Language**: GDScript (not C#, despite Mono build)
- **Project root**: `S:\attribute-loop`

## Commands

```bash
# Validate scripts (no display needed)
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop" --headless --quit

# Run game (requires display)
"S:/Godot_v4.6.2-stable_mono_win64/Godot_v4.6.2-stable_mono_win64.exe" --path "S:/attribute-loop"
```

> Use `--headless --quit` instead of `--check-only`. The latter has a class_name registration order bug in headless mode.

## Key Convention

All cross-file custom type references use `const Foo = preload("res://...")` instead of bare class names. This is required for headless compatibility — Godot headless does not auto-build the global class registry.

## Module Docs

| Module | Doc |
|--------|-----|
| Entry system (EntryComponent + Rule) | `doc/entry-system.md` |
| Inventory | `doc/inventory.md` |
| Game state | `doc/game-state.md` |
| Track scene | `doc/track.md` |
| Player scene | `doc/player.md` |
| Enemy scene | `doc/enemy.md` |
| HUD / UI | `doc/hud.md` |
| Main scene | `doc/main.md` |
| Roadmap | `doc/roadmap.md` |
