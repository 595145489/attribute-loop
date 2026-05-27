# DataTables Module

## Overview

DataTables is an autoload singleton that loads and caches all game configuration and entity data from Godot resource files (.tres). It serves as the central data access layer for the entire game, providing read-only access to game configuration, player stats, enemy templates, and phase definitions.

## Responsibilities

- **Resource Loading:** Loads all .tres files from the data/ directory during engine initialization
- **Data Caching:** Maintains in-memory dictionaries of loaded resources for fast runtime access
- **Data Access API:** Provides convenience methods (`get_enemy()`, `get_phase()`) for retrieving specific data
- **Stat Calculation:** Computes phase-scaled stats via `calc_stat()` using the configured scale factor

## Key Classes and Signals

### Public Members

- `config: GameConfig` — Global game configuration (stat_scale_factor, timing constants, etc.)
- `player: PlayerData` — Player entity template (hp_base, walk_speed, attack_interval, etc.)
- `enemies: Dictionary` — Map of enemy_id → EnemyData for all 5 enemy types
- `phases: Dictionary` — Map of phase_number (1–10) → PhaseData with spawn rules

### Public Methods

- `get_enemy(id: String) -> EnemyData` — Retrieve enemy template by ID
- `get_phase(phase_id: int) -> PhaseData` — Retrieve phase data by ID
- `calc_stat(base: int, phase: int) -> int` — Calculate phase-scaled stat (integer result)

## Execution Flow

1. **Engine startup** — Godot initializes autoloads before loading any scenes
2. **`_ready()` called** — DataTables begins loading resources:
   - Loads `res://data/game_config.tres` → `config`
   - Loads `res://data/player_data.tres` → `player`
   - Calls `_load_enemies()` to populate enemy dictionary
   - Calls `_load_phases()` to populate phase dictionary
3. **Runtime access** — Game code queries DataTables for stats, templates, and phase data
4. **Data is immutable** — No getters modify data; all access is read-only

## Resource Dependencies

- **Inputs:** All .tres files in res://data/ (created and maintained by Task 5)
  - `res://data/game_config.tres`
  - `res://data/player_data.tres`
  - `res://data/enemies/enemy_{id}.tres` (5 files)
  - `res://data/phases/phase_{1..10}.tres` (10 files)
- **Resource Classes:** GameConfig, PlayerData, EnemyData, PhaseData (from src/resources/)

## Other Modules It Serves

- **GameState:** Uses `DataTables.player` and `calc_stat()` to initialize player HP and scale combat stats
- **Spawner:** Uses `DataTables.get_phase()` to determine enemy spawn counts and weights
- **CombatSystem:** Uses enemy and player stat templates for damage calculation
- **GameLoop:** Uses phase data to manage game progression
