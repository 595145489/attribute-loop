class_name Tile
extends Node2D

signal clicked(tile: Tile)

const TEX_EMPTY = preload("res://resources/tiles/tile_empty.png")
const TEX_OCCUPIED = preload("res://resources/tiles/tile_occupied.png")

var tile_index: int = 0
var enemy: Enemy = null
var visited_this_loop: bool = false
var pass_count: int = 0
var is_altar: bool = false
var rule_slots: Array = []
var altar_slots: Array = []

@onready var visual: Sprite2D = $Visual

func _ready() -> void:
	if is_altar:
		var req := DataTables.get_phase(GameState.current_phase).altar_requirement
		altar_slots.resize(req)
		altar_slots.fill(null)
	else:
		var max_rules := DataTables.TILE_MAX_RULES[tile_index] if tile_index < DataTables.TILE_MAX_RULES.size() else 1
		for i in max_rules:
			rule_slots.append({"trigger": null, "effect": null})

func _process(_delta: float) -> void:
	_refresh_visual()

func _refresh_visual() -> void:
	var occupied := rule_slots.any(func(s): return s.get("trigger") != null or s.get("effect") != null)
	visual.texture = TEX_OCCUPIED if occupied else TEX_EMPTY

func _input(event: InputEvent) -> void:
	if GameState.is_paused:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local_event := make_input_local(event) as InputEventMouseButton
	if local_event == null:
		return
	var p := local_event.position
	if abs(p.x) <= 14.0 and abs(p.y) <= 14.0:
		get_viewport().set_input_as_handled()
		clicked.emit(self)

func has_enemy() -> bool:
	return enemy != null

func place_enemy(e: Enemy) -> void:
	enemy = e

func clear_enemy() -> void:
	enemy = null

func resize_altar_for_phase(phase: int) -> void:
	var req := DataTables.get_phase(phase).altar_requirement
	altar_slots.resize(req)
	while altar_slots.size() < req:
		altar_slots.append(null)
