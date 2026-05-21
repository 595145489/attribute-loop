class_name Tile
extends Node2D

var tile_index: int = 0
var enemy: Enemy = null
var visited_this_loop: bool = false

func has_enemy() -> bool:
    return enemy != null

func place_enemy(e: Enemy) -> void:
    enemy = e

func clear_enemy() -> void:
    enemy = null
