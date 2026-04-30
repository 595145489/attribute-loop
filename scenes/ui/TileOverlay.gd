class_name TileOverlay
extends Control

const ComponentCard = preload("res://scenes/ui/ComponentCard.tscn")
const TileSlot = preload("res://scenes/ui/TileSlot.tscn")
const Tile = preload("res://scripts/core/Tile.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

var track = null
var player = null
var inventory: Inventory = null

var _is_paused: bool = false
var _tile_containers: Dictionary = {}

func setup(p_track, p_player, p_inventory: Inventory) -> void:
	track = p_track
	player = p_player
	inventory = p_inventory
	for tile in track.tiles:
		tile.component_stripped.connect(_on_tile_component_stripped.bind(tile))

func set_paused(paused: bool) -> void:
	_is_paused = paused
	if paused:
		_build_tile_cards()
	else:
		_clear_tile_cards()
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()
	if not _is_paused or track == null:
		return
	var canvas_tf = get_viewport().get_canvas_transform()
	for idx in _tile_containers:
		if not is_instance_valid(_tile_containers[idx]):
			continue
		var tile = track.tiles[idx] as Tile
		var world_pos = track.get_position_at(tile.track_t)
		var screen_pos = canvas_tf * world_pos
		_tile_containers[idx].position = screen_pos + Vector2(-40, -130)

func _draw() -> void:
	if track == null:
		return
	var canvas_tf = get_viewport().get_canvas_transform()
	for tile in track.tiles:
		var world_pos = track.get_position_at(tile.track_t)
		var screen_pos = canvas_tf * world_pos
		var color: Color
		if tile.components.is_empty():
			color = Color(0.35, 0.35, 0.35, 0.5)
		elif tile.pass_count >= tile.harvest_threshold:
			color = Color(1.0, 0.8, 0.1, 0.95)
		else:
			var t = clampf(float(tile.pass_count) / float(tile.harvest_threshold), 0.0, 1.0)
			color = Color(0.2 + t * 0.2, 0.5, 0.9, 0.7)
		draw_circle(screen_pos, 7.0, color)
		if tile.components.size() > 0:
			var font = get_theme_default_font()
			draw_string(font, screen_pos + Vector2(9, 4), str(tile.components.size()),
						HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)

func _build_tile_cards() -> void:
	_clear_tile_cards()
	if track == null or player == null:
		return
	var n = track.tiles.size()
	var player_idx = track.get_tile_index_for_t(player.track_t)
	for offset in [-1, 0, 1]:
		var idx = (player_idx + offset + n) % n
		var tile = track.tiles[idx] as Tile
		_create_tile_container(idx, tile)

func _create_tile_container(idx: int, tile: Tile) -> void:
	var container := VBoxContainer.new()
	add_child(container)
	_tile_containers[idx] = container

	var slot = TileSlot.instantiate()
	container.add_child(slot)
	slot.setup(tile, inventory)

	for comp in tile.components:
		var harvestable = tile.pass_count >= tile.harvest_threshold
		var card = ComponentCard.instantiate()
		container.add_child(card)
		card.setup(comp, null, tile, harvestable)

func _clear_tile_cards() -> void:
	for container in _tile_containers.values():
		if is_instance_valid(container):
			container.queue_free()
	_tile_containers.clear()

func _on_tile_component_stripped(component, tile: Tile) -> void:
	var idx = track.tiles.find(tile)
	if idx < 0 or idx not in _tile_containers:
		return
	var container = _tile_containers[idx]
	if not is_instance_valid(container):
		return
	for child in container.get_children():
		if child.has_method("setup") and child.get("component") == component:
			container.remove_child(child)
			child.queue_free()
			break
	if container.get_child_count() <= 1:
		container.queue_free()
		_tile_containers.erase(idx)
