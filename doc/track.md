# Track Scene

`scenes/track/Track.gd` + `scenes/track/Track.tscn`

## Responsibility

Defines the closed polyline path the player walks, and renders it.

## Data

`loop_points: Array[Vector2]` — world-space vertices of the loop. If empty on `_ready()`, a default centered rectangular track is generated (480×280, corner offset 80px).

## Core API

| Method | Description |
|--------|-------------|
| `get_position_at(t: float) → Vector2` | t ∈ [0, 1), returns world position on track via linear interpolation |
| `get_total_length() → float` | Total perimeter in pixels |

`get_position_at` maps t to a segment index in `loop_points`, then lerps between the two endpoints. t=0 and t=1 both point to the first vertex.

## Child Nodes

- `TrackVisual: Line2D` — renders the track; `_draw_track()` writes a closed point array to it.
