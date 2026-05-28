class_name ComponentIcons
extends RefCounted

const _ICON_MAP: Dictionary = {
	"受击":    "res://resources/icons/trigger_hit.png",
	"击杀":    "res://resources/icons/trigger_kill.png",
	"完成圈数": "res://resources/icons/trigger_loop.png",
	"经过":    "res://resources/icons/trigger_pass.png",
	"治愈":    "res://resources/icons/effect_heal.png",
	"反射":    "res://resources/icons/effect_reflect.png",
}

static var _cache: Dictionary = {}

static func get_icon(id: String) -> Texture2D:
	if _cache.has(id):
		return _cache[id]
	if not _ICON_MAP.has(id):
		_cache[id] = null
		return null
	var tex: Texture2D = ResourceLoader.load(_ICON_MAP[id])
	_cache[id] = tex
	return tex
