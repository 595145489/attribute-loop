extends Node

const TrackScript = preload("res://scenes/track/Track.gd")
const PlayerScript = preload("res://scenes/player/Player.gd")
const HUDScript = preload("res://scenes/ui/HUD.gd")
const GameStateScript = preload("res://scripts/systems/GameState.gd")
const EntryComponent = preload("res://scripts/core/EntryComponent.gd")
const Rule = preload("res://scripts/core/Rule.gd")
const Tile = preload("res://scripts/core/Tile.gd")

@onready var track: Node2D = $World/Track
@onready var player: Node2D = $World/Player
@onready var enemies_node: Node2D = $World/Enemies
@onready var hud: CanvasLayer = $HUD

var game_state: Node
var enemy_a_scene: PackedScene = preload("res://scenes/enemy/Enemy.tscn")
var enemy_b_scene: PackedScene = preload("res://scenes/enemy/EnemyB.tscn")

var _spawn_timer: float = 0.0
var _spawn_interval: float = 5.0
var _player_attack_timer: float = 0.0
var _last_player_tile_index: int = -1

const PLAYER_ATTACK_INTERVAL: float = 1.0
const PLAYER_ATTACK_DAMAGE: float = 20.0
const PLAYER_ATTACK_RANGE: float = 50.0
const EMPTY_SHELL_CLEAR_RANGE: float = 30.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	$World.process_mode = Node.PROCESS_MODE_PAUSABLE
	game_state = GameStateScript.new()
	add_child(game_state)

	player.track = track
	player.took_damage.connect(_on_player_took_damage)
	player.healed.connect(_on_player_healed)
	player.player_died.connect(_on_player_died)
	game_state.state_changed.connect(_on_state_changed)

	hud.update_hp(player.hp, player.max_hp)
	hud.setup(player, player.inventory, enemies_node, track)
	_seed_initial_tiles()

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
	_check_player_tile()
	_clear_nearby_empty_shells()

func _check_player_tile() -> void:
	if track.tiles.is_empty():
		return
	var idx = track.get_tile_index_for_t(player.track_t)
	if idx == _last_player_tile_index:
		return
	_last_player_tile_index = idx
	_on_player_entered_tile(idx)

func _on_player_entered_tile(tile_index: int) -> void:
	var tile = track.tiles[tile_index] as Tile
	tile.pass_count += 1
	Log.info("entered tile %d, pass_count=%d" % [tile_index, tile.pass_count], "Main")
	var effect_type = tile.try_fire()
	if effect_type == "":
		return
	var mult = tile.effect_multiplier()
	match effect_type:
		"heal":
			player.receive_heal(15.0 * mult)
			Log.info("tile heal %.1f" % (15.0 * mult), "Main")
		"boost_speed":
			player.apply_speed_boost(1.5)
			Log.info("tile boost_speed x1.5", "Main")
		"deal_damage_nearby":
			var dmg = 10.0 * mult
			for enemy in enemies_node.get_children():
				if not is_instance_valid(enemy):
					continue
				if enemy.global_position.distance_to(player.global_position) <= 100.0:
					enemy.receive_damage(dmg)
			Log.info("tile deal_damage_nearby %.1f" % dmg, "Main")

func _clear_nearby_empty_shells() -> void:
	for enemy in enemies_node.get_children():
		if not is_instance_valid(enemy):
			continue
		if enemy.is_empty_shell and enemy.global_position.distance_to(player.global_position) <= EMPTY_SHELL_CLEAR_RANGE:
			enemy.queue_free()

func _attack_nearby_enemies() -> void:
	for enemy in enemies_node.get_children():
		if is_instance_valid(enemy) and not enemy.is_empty_shell:
			if enemy.global_position.distance_to(player.global_position) <= PLAYER_ATTACK_RANGE:
				enemy.receive_damage(PLAYER_ATTACK_DAMAGE)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		game_state.toggle()

func _spawn_enemy() -> void:
	var use_b := randf() > 0.5
	var scene := enemy_b_scene if use_b else enemy_a_scene
	var enemy := scene.instantiate()
	var components = _make_enemy_b_components() if use_b else _make_enemy_a_components()
	enemy.setup_components(components)
	enemies_node.add_child(enemy)
	var t = randf()
	enemy.position = track.get_position_at(t)
	enemy.spawn_t = t
	enemy.player_ref = player
	enemy.enemy_defeated.connect(_on_enemy_defeated.bind(enemy))

func _on_enemy_defeated(enemy: Node) -> void:
	if enemy.components.is_empty():
		return
	var nearest = _find_nearest_tile_to_t(enemy.spawn_t)
	if nearest == null:
		return
	for comp in enemy.components.duplicate():
		nearest.add_component(comp)
	Log.info("enemy death → %d components → tile (pass_count=%d)" % [enemy.components.size(), nearest.pass_count], "Main")

func _find_nearest_tile_to_t(t: float) -> Tile:
	if track.tiles.is_empty():
		return null
	var best_tile: Tile = null
	var best_dist := INF
	for tile in track.tiles:
		var d = absf(tile.track_t - t)
		d = minf(d, 1.0 - d)
		if d < best_dist:
			best_dist = d
			best_tile = tile
	return best_tile

func _make_enemy_a_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "受到攻击时"
	trigger.data = {"event": "on_hit"}

	var effect := EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "召唤分身"
	effect.data = {"type": "summon_clone"}

	return [trigger, effect]

func _make_enemy_b_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "受到攻击时"
	trigger.data = {"event": "on_hit"}

	var effect1 := EntryComponent.new()
	effect1.slot_type = EntryComponent.SlotType.EFFECT
	effect1.label = "反弹伤害"
	effect1.data = {"type": "reflect_damage"}

	var effect2 := EntryComponent.new()
	effect2.slot_type = EntryComponent.SlotType.EFFECT
	effect2.label = "恢复生命"
	effect2.data = {"type": "heal"}

	return [trigger, effect1, effect2]

func _make_tile_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "经过时"
	trigger.data = {"event": "on_pass"}

	var effect := EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "治愈"
	effect.data = {"type": "heal"}

	return [trigger, effect]

func _make_tile_boost_components() -> Array[EntryComponent]:
	var trigger := EntryComponent.new()
	trigger.slot_type = EntryComponent.SlotType.TRIGGER
	trigger.label = "经过时"
	trigger.data = {"event": "on_pass"}

	var effect := EntryComponent.new()
	effect.slot_type = EntryComponent.SlotType.EFFECT
	effect.label = "加速"
	effect.data = {"type": "boost_speed"}

	return [trigger, effect]

func _seed_initial_tiles() -> void:
	if track.tiles.size() < 7:
		return
	var heal_comps = _make_tile_components()
	var tile0 = track.tiles[0] as Tile
	for comp in heal_comps:
		tile0.add_component(comp)
	tile0.pass_count = 3

	var boost_comps = _make_tile_boost_components()
	var tile6 = track.tiles[6] as Tile
	for comp in boost_comps:
		tile6.add_component(comp)
	tile6.pass_count = 0

	Log.info("seeded tile 0 (heal, harvestable) + tile 6 (boost_speed, accumulating)", "Main")

func _on_player_took_damage(_amount: float) -> void:
	hud.update_hp(player.hp, player.max_hp)

func _on_player_healed(_amount: float) -> void:
	hud.update_hp(player.hp, player.max_hp)

func _on_player_died() -> void:
	get_tree().reload_current_scene()

func _on_state_changed(new_state: int) -> void:
	hud.set_paused(new_state == 1)
