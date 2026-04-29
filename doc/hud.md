# HUD

`scenes/ui/HUD.gd` + `scenes/ui/HUD.tscn`

Extends `CanvasLayer` — always renders above the game world.

## Responsibility

Displays player HP, pause overlay, and the inventory panel (skeleton built, content pending).

## API

| Method | Description |
|--------|-------------|
| `update_hp(current, maximum)` | Refresh HP bar and label |
| `set_paused(paused: bool)` | Show / hide "PAUSED - DRAG MODE" label |

## Node Structure

```
HUD (CanvasLayer)
├── HPBar (ProgressBar)       top-left health bar
├── HPLabel (Label)           "HP: 100 / 100"
├── PauseLabel (Label)        centered pause overlay, hidden by default
└── InventoryPanel (Panel)    bottom inventory area (pending)
    └── InventoryLabel
```

## Upcoming

Inventory UI: listen to `Inventory.component_added/removed` signals and dynamically create/remove component cards. Drag nodes inside HUD must set `process_mode = ALWAYS` to receive input while the game is paused.
