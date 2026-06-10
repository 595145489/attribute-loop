extends GutTest

func test_known_id_returns_texture() -> void:
	var tex: Texture2D = ComponentIcons.get_icon("受击")
	assert_not_null(tex, "Expected Texture2D for '受击'")

func test_unknown_id_returns_null() -> void:
	var result = ComponentIcons.get_icon("不存在")
	assert_null(result, "Expected null for unknown id")

func test_cache_returns_same_object() -> void:
	var tex1: Texture2D = ComponentIcons.get_icon("治愈")
	var tex2: Texture2D = ComponentIcons.get_icon("治愈")
	assert_same(tex1, tex2, "Expected cached texture to be the same object")

func test_all_implemented_components_have_icons() -> void:
	for id in ["受击", "击杀", "完成圈数", "经过", "治愈", "反射",
			"低血", "满血", "规则触发", "护盾", "减伤", "吸血"]:
		assert_not_null(ComponentIcons.get_icon(id), "Missing icon for '%s'" % id)
