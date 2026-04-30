class_name Track
extends Node2D

const Tile = preload("res://scripts/core/Tile.gd")

@export var loop_points: Array[Vector2] = []
@export var tile_count: int = 12
@onready var visual: Line2D = $TrackVisual

var tiles: Array = []

func _ready() -> void:
	if loop_points.is_empty():
		_build_default_track()
	_draw_track()
	_generate_tiles()

func _build_default_track() -> void:
	var cx = 640.0
	var cy = 360.0
	var w = 480.0
	var h = 280.0
	var r = 80.0
	loop_points = [
		Vector2(cx - w/2 + r, cy - h/2),
		Vector2(cx + w/2 - r, cy - h/2),
		Vector2(cx + w/2, cy - h/2 + r),
		Vector2(cx + w/2, cy + h/2 - r),
		Vector2(cx + w/2 - r, cy + h/2),
		Vector2(cx - w/2 + r, cy + h/2),
		Vector2(cx - w/2, cy + h/2 - r),
		Vector2(cx - w/2, cy - h/2 + r),
	]

func _draw_track() -> void:
	var pts = loop_points.duplicate()
	pts.append(pts[0])
	visual.points = PackedVector2Array(pts)

func _generate_tiles() -> void:
	tiles.clear()
	for i in tile_count:
		var tile = Tile.new()
		tile.track_t = (float(i) + 0.5) / float(tile_count)
		tiles.append(tile)

func get_position_at(t: float) -> Vector2:
	var total = loop_points.size()
	var scaled = t * total
	var idx = int(scaled) % total
	var next = (idx + 1) % total
	var frac = scaled - int(scaled)
	return loop_points[idx].lerp(loop_points[next], frac)

func get_total_length() -> float:
	var length = 0.0
	for i in loop_points.size():
		var next = (i + 1) % loop_points.size()
		length += loop_points[i].distance_to(loop_points[next])
	return length

func get_tile_index_for_t(t: float) -> int:
	return int(t * tile_count) % tile_count
