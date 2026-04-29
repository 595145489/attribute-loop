# Inventory

`scripts/systems/Inventory.gd`

Extends `Node`. Created and added as a child of Player in `Player._ready()`.

## Responsibility

Stores EntryComponent fragments stripped from enemies, available for rule assembly.

## API

| Method / Property | Description |
|-------------------|-------------|
| `components: Array[EntryComponent]` | All held components |
| `MAX_SIZE = 12` | Capacity cap |
| `add(component) → bool` | Add component; returns false if full |
| `remove(component)` | Remove component |

## Signals

| Signal | When |
|--------|------|
| `component_added(component)` | After successful add |
| `component_removed(component)` | After removal |

The UI layer listens to these signals to refresh the inventory display — no polling needed.
