class_name HUD
extends CanvasLayer

const Inventory = preload("res://scripts/systems/Inventory.gd")

@onready var hp_bar: ProgressBar = $HPBar
@onready var hp_label: Label = $HPLabel
@onready var pause_label: Label = $PauseLabel
@onready var enemy_card_overlay = $EnemyCardOverlay
@onready var inventory_panel = $InventoryPanel
@onready var rule_assembly_panel = $RuleAssemblyPanel

func setup(player, inventory: Inventory, enemies_node: Node2D, track = null) -> void:
	enemy_card_overlay.setup(enemies_node)
	inventory_panel.setup(player, inventory)
	rule_assembly_panel.setup(player, inventory)

func update_hp(current: float, maximum: float) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP: %d / %d" % [int(current), int(maximum)]

func set_paused(paused: bool) -> void:
	pause_label.visible = paused
	enemy_card_overlay.visible = paused
	inventory_panel.visible = paused
	rule_assembly_panel.visible = paused
