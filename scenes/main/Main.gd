extends Node

const TrackScript = preload("res://scenes/track/Track.gd")
const PlayerScript = preload("res://scenes/player/Player.gd")
const HUDScript = preload("res://scenes/ui/HUD.gd")
const GameStateScript = preload("res://scripts/systems/GameState.gd")
const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Rule = preload("res://scripts/core/Rule.gd")
const EnemyScript = preload("res://scenes/enemy/Enemy.gd")

@onready var track: Node2D = $World/Track
@onready var player: Node2D = $World/Player
@onready var enemies_node: Node2D = $World/Enemies
@onready var hud: CanvasLayer = $HUD

var game_state: Node
var enemy_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
var _spawn_timer: float = 0.0
var _spawn_interval: float = 5.0
var _player_attack_timer: float = 0.0
const PLAYER_ATTACK_INTERVAL: float = 1.0
const PLAYER_ATTACK_DAMAGE: float = 20.0
const PLAYER_ATTACK_RANGE: float = 50.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	game_state = GameStateScript.new()
	add_child(game_state)

	player.track = track
	player.took_damage.connect(_on_player_took_damage)
	player.healed.connect(_on_player_healed)
	game_state.state_changed.connect(_on_state_changed)

	_give_player_starter_rule()
	hud.update_hp(player.hp, player.max_hp)

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	_spawn_timer += delta
	if _spawn_timer >= _spawn_interval:
		_spawn_timer = 0.0
		_spawn_enemy()
	_player_attack_timer += delta
	if _player_attack_timer >= PLAYER_ATTACK_INTERVAL:
		_player_attack_timer = 0.0
		_attack_nearby_enemies()

func _attack_nearby_enemies() -> void:
	for enemy in enemies_node.get_children():
		if enemy.global_position.distance_to(player.global_position) <= PLAYER_ATTACK_RANGE:
			enemy.receive_damage(PLAYER_ATTACK_DAMAGE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		game_state.toggle()

func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	enemies_node.add_child(enemy)
	enemy.position = track.get_position_at(randf())
	enemy.player_ref = player
	enemy.setup_components(_make_enemy_components())

func _make_enemy_components() -> Array[EntryComponent]:
	var trigger = EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "受到攻击时"
	trigger.data = {"event": "on_hit"}

	var effect = EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "召唤分身"
	effect.data = {"type": "summon_clone"}

	return [trigger, effect]

func _give_player_starter_rule() -> void:
	var trigger = EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "受到攻击时"
	trigger.data = {"event": "on_hit"}

	var effect = EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "恢复生命"
	effect.data = {"type": "heal"}

	var rule = Rule.new()
	rule.trigger = trigger
	rule.effect = effect
	player.add_rule(rule)

func _on_player_took_damage(_amount: float) -> void:
	hud.update_hp(player.hp, player.max_hp)

func _on_player_healed(_amount: float) -> void:
	hud.update_hp(player.hp, player.max_hp)

func _on_state_changed(new_state: int) -> void:
	hud.set_paused(new_state == 1)
