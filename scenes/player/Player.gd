class_name Player
extends Node2D

const Rule = preload("res://scripts/core/Rule.gd")
const TrackScript = preload("res://scenes/track/Track.gd")
const Inventory = preload("res://scripts/systems/Inventory.gd")

signal rule_fired(rule: Rule, effect_type: String)
signal took_damage(amount: float)
signal healed(amount: float)
signal player_died

@export var speed: float = 80.0

var track: Node2D = null
var track_t: float = 0.0
var hp: float = 100.0
var max_hp: float = 100.0
var rules: Array[Rule] = []
var inventory: Inventory
var speed_multiplier: float = 1.0

var _speed_boost_timer: float = 0.0
const SPEED_BOOST_DURATION: float = 3.0

func _ready() -> void:
	inventory = Inventory.new()
	add_child(inventory)
	rule_fired.connect(_on_rule_fired)

func _process(delta: float) -> void:
	if track == null:
		return
	var length = track.get_total_length()
	track_t += (speed * speed_multiplier / length) * delta
	if track_t >= 1.0:
		track_t -= 1.0
	position = track.get_position_at(track_t)
	if _speed_boost_timer > 0.0:
		_speed_boost_timer -= delta
		if _speed_boost_timer <= 0.0:
			speed_multiplier = 1.0

func receive_damage(amount: float) -> void:
	hp = clampf(hp - amount, 0.0, max_hp)
	took_damage.emit(amount)
	if hp <= 0.0:
		Log.warn("player died", "Player")
		player_died.emit()
		return
	_fire_rules("on_hit", {"owner": self, "amount": amount})

func receive_heal(amount: float) -> void:
	hp = clampf(hp + amount, 0.0, max_hp)
	healed.emit(amount)

func apply_speed_boost(multiplier: float) -> void:
	speed_multiplier = multiplier
	_speed_boost_timer = SPEED_BOOST_DURATION

func _fire_rules(event: String, context: Dictionary) -> void:
	for rule in rules:
		rule.try_fire(event, context)

func add_rule(rule: Rule) -> void:
	rules.append(rule)

func _on_rule_fired(_rule: Rule, effect_type: String) -> void:
	match effect_type:
		"heal":
			receive_heal(15.0)
		"reflect_damage":
			pass
		"summon_clone":
			pass
