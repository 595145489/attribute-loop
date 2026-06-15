class_name Tile
extends Node2D

signal clicked(tile: Tile)

const TEX_EMPTY = preload("res://resources/tiles/tile_empty.png")
const TILE_NAMES: Array[String] = [
	"祭坛", "瞭望塔", "铁匠铺", "魔法图书馆", "炼金实验室",
	"兵营", "市集", "酒馆", "治愈圣坛", "法师塔",
	"宝库", "神殿", "猎人小屋",
]

func get_tile_name() -> String:
	if tile_index < TILE_NAMES.size():
		return TILE_NAMES[tile_index]
	return "地块%d" % tile_index
const TEX_BUILDINGS: Array[Texture2D] = [
	preload("res://resources/tiles/buildings/tile_0.png"),
	preload("res://resources/tiles/buildings/tile_1.png"),
	preload("res://resources/tiles/buildings/tile_2.png"),
	preload("res://resources/tiles/buildings/tile_3.png"),
	preload("res://resources/tiles/buildings/tile_4.png"),
	preload("res://resources/tiles/buildings/tile_5.png"),
	preload("res://resources/tiles/buildings/tile_6.png"),
	preload("res://resources/tiles/buildings/tile_7.png"),
	preload("res://resources/tiles/buildings/tile_8.png"),
	preload("res://resources/tiles/buildings/tile_9.png"),
	preload("res://resources/tiles/buildings/tile_10.png"),
	preload("res://resources/tiles/buildings/tile_11.png"),
	preload("res://resources/tiles/buildings/tile_12.png"),
]

var tile_index: int = 0
var guard_position: Vector2 = Vector2.ZERO
var enemy: Enemy = null
var visited_this_loop: bool = false
var pass_count: int = 0
var is_altar: bool = false
var rule_slots: Array = []
var altar_slots: Array = []

@onready var visual: Sprite2D = $Visual
@onready var building: Sprite2D = $Building

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
	if occupied and tile_index < TEX_BUILDINGS.size():
		building.texture = TEX_BUILDINGS[tile_index]
		building.visible = true
		visual.visible = false
	else:
		building.visible = false
		visual.visible = true

func _input(event: InputEvent) -> void:
	if Engine.time_scale == 0.0 and not has_enemy() and not GameState.is_tutorial:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var local_event := make_input_local(event) as InputEventMouseButton
	if local_event == null:
		return
	var p := local_event.position
	var guard_local: Vector2 = guard_position - global_position
	var hit_tile: bool = abs(p.x) <= 14.0 and abs(p.y) <= 14.0
	var hit_guard: bool = has_enemy() and (p - guard_local).length() <= 32.0
	if hit_tile or hit_guard:
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

func copy_rule_to(target: Tile) -> bool:
	var source_slot: Dictionary = {}
	for s in rule_slots:
		if s["trigger"] != null or s["effect"] != null:
			source_slot = s
			break
	if source_slot.is_empty():
		return false
	var dest_slot: Dictionary = {}
	for s in target.rule_slots:
		if s["trigger"] == null and s["effect"] == null:
			dest_slot = s
			break
	if dest_slot.is_empty():
		return false
	if source_slot["trigger"] != null:
		dest_slot["trigger"] = source_slot["trigger"].duplicate()
	if source_slot["effect"] != null:
		dest_slot["effect"] = source_slot["effect"].duplicate()
	return true
