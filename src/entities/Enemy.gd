class_name Enemy
extends Node2D

var enemy_id: String = ""
var hp: int = 0
var hp_max: int = 0
var dmg: int = 0
var attack_interval: float = 1.0
var components: Array[ComponentData] = []

@onready var _visual: ColorRect = $Visual
@onready var _anim_sprite: AnimatedSprite2D = $AnimSprite
@onready var _hp_label: Label = $HPLabel

func init(id: String, stat_phase: int = -1) -> void:
	enemy_id = id
	var data: EnemyData = DataTables.get_enemy(id)
	var phase := stat_phase if stat_phase > 0 else GameState.current_phase
	hp_max = DataTables.calc_stat(data.hp_base, phase)
	hp = hp_max
	dmg = DataTables.calc_stat(data.dmg_base, phase)
	attack_interval = data.attack_interval
	components = []
	_load_animation()
	_refresh_label()

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	_refresh_label()

func is_dead() -> bool:
	return hp <= 0

func _refresh_label() -> void:
	if _hp_label:
		_hp_label.text = "%d/%d" % [hp, hp_max]

const SPRITE_FOLDERS: Dictionary = {
	"急袭者": "rusher",
	"汲取者": "drainer",
	"守卫者": "guardian",
	"复制者": "replicator",
	"先驱者": "vanguard",
}

func _load_animation() -> void:
	var folder: String = SPRITE_FOLDERS.get(enemy_id, enemy_id)
	var base_path := "res://resources/sprites/enemies/%s/" % folder
	var sf := SpriteFrames.new()
	_load_anim(sf, base_path + "idle/", "idle", true)
	_load_anim(sf, base_path + "activate/", "activate", false)
	if sf.get_animation_names().size() == 0:
		_visual.show()
		return
	_anim_sprite.sprite_frames = sf
	_anim_sprite.show()
	_anim_sprite.play("idle")

func _load_anim(sf: SpriteFrames, path: String, anim: String, loop: bool) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var f := dir.get_next()
	while f != "":
		if f.ends_with(".png"):
			files.append(f)
		f = dir.get_next()
	dir.list_dir_end()
	if files.is_empty():
		return
	files.sort()
	sf.add_animation(anim)
	sf.set_animation_speed(anim, 8.0)
	sf.set_animation_loop(anim, loop)
	for file in files:
		var tex: Texture2D = load(path + file)
		sf.add_frame(anim, tex)
