extends GutTest

func test_slot_type_enum_values() -> void:
	assert_eq(ComponentData.SlotType.TRIGGER_ONLY, 0)
	assert_eq(ComponentData.SlotType.EFFECT_ONLY, 1)
	assert_eq(ComponentData.SlotType.BOTH, 2)

func test_duplicate_preserves_id_and_values() -> void:
	var c := ComponentData.new()
	c.id = "受击"
	c.slot_type = ComponentData.SlotType.TRIGGER_ONLY
	c.trigger_value = 3.0
	var copy := c.duplicate() as ComponentData
	assert_eq(copy.id, "受击")
	assert_eq(copy.slot_type, ComponentData.SlotType.TRIGGER_ONLY)
	assert_eq(copy.trigger_value, 3.0)

func test_new_component_has_zero_counts() -> void:
	var c := ComponentData.new()
	assert_eq(c.trigger_count, 0)
	assert_eq(c.trigger_value, 0.0)
	assert_eq(c.effect_value, 0.0)

func test_drop_preset_ranges_dictionary() -> void:
	var dp := DropPreset.new()
	dp.component_ranges["受击"] = {"trigger": Vector2(2, 3)}
	assert_eq(dp.component_ranges["受击"]["trigger"], Vector2(2, 3))

func test_growth_rate_default_zero() -> void:
	var c := ComponentData.new()
	assert_eq(c.growth_rate, 0.0)

func test_scale_exponent_default_one() -> void:
	var c := ComponentData.new()
	assert_eq(c.scale_exponent, 1.0)

func test_max_scale_default_zero() -> void:
	var c := ComponentData.new()
	assert_eq(c.max_scale, 0.0)

func test_altar_ratio_default_zero() -> void:
	var c := ComponentData.new()
	assert_eq(c.altar_ratio, 0.0)
