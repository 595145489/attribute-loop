class_name Tile
extends Node2D

var tile_index: int = 0
var enemy: Enemy = null
var visited_this_loop: bool = false
var pass_count: int = 0
var is_altar: bool = false
var rule_slots: Array = []
var altar_slots: Array = []

func _ready() -> void:
	if is_altar:
		var req := DataTables.get_phase(GameState.current_phase).altar_requirement
		altar_slots.resize(req)
		altar_slots.fill(null)
	else:
		var max_rules := DataTables.TILE_MAX_RULES[tile_index] if tile_index < DataTables.TILE_MAX_RULES.size() else 1
		for i in max_rules:
			rule_slots.append({"trigger": null, "effect": null})

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
