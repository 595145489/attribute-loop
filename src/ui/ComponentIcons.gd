class_name ComponentIcons
extends RefCounted

const _ICON_MAP: Dictionary = {
	"受击":    "res://resources/icons/trigger_hit.png",
	"击杀":    "res://resources/icons/trigger_kill.png",
	"完成圈数": "res://resources/icons/trigger_loop.png",
	"经过":    "res://resources/icons/trigger_pass.png",
	"治愈":    "res://resources/icons/effect_heal.png",
	"反射":    "res://resources/icons/effect_reflect.png",
	"低血":    "res://resources/icons/trigger_low_hp.png",
	"满血":    "res://resources/icons/trigger_full_hp.png",
	"规则触发": "res://resources/icons/trigger_rule_fire.png",
	"护盾":    "res://resources/icons/effect_shield.png",
	"减伤":    "res://resources/icons/effect_slow.png",
	"吸血":    "res://resources/icons/effect_lifesteal.png",
	"强化":    "res://resources/icons/effect_empower.png",
}

static var _cache: Dictionary = {}
static var _placeholder: Texture2D = null

static func get_placeholder() -> Texture2D:
	if _placeholder == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		_placeholder = ImageTexture.create_from_image(img)
	return _placeholder

static func get_icon(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	if not _ICON_MAP.has(id):
		_cache[id] = null
		return null
	var tex: Texture2D = ResourceLoader.load(_ICON_MAP[id])
	_cache[id] = tex
	return tex
