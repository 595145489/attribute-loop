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

## MCP Server

Prefer Godot MCP Server tools (`mcp__godot__*`) for all scene, node, script, and resource operations over direct file reads/writes or CLI commands. Fall back to file tools or Bash only when MCP cannot cover the operation (e.g., bulk text search, git, script syntax validation).

## Documentation Language

All documentation — CLAUDE.md, doc/*.md, comments, and any other written docs — must be in English.

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
