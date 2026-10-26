extends GutTest


func _make_definition(id: StringName, category: String = "Test") -> TerrainDefinition:
	var definition := TerrainDefinition.new()
	definition.id = id
	definition.category = category
	return definition


func test_register_and_resolve() -> void:
	var registry := TerrainRegistry.new()
	assert_true(registry.register(_make_definition(&"grass", "Green")))
	assert_true(registry.register(_make_definition(&"water", "Blue")))
	assert_true(registry.register(_make_definition(&"forest", "Green")))
	assert_true(registry.has(&"grass"))
	assert_eq(registry.get_definition(&"water").category, "Blue")
	assert_eq(registry.ids(), [&"grass", &"water", &"forest"] as Array[StringName])
	assert_eq(registry.categories(), PackedStringArray(["Green", "Blue"]))
	assert_eq(registry.ids_in_category("Green"), [&"grass", &"forest"] as Array[StringName])


func test_unknown_id_resolves_to_null() -> void:
	var registry := TerrainRegistry.new()
	assert_null(registry.get_definition(&"missing"))
	assert_false(registry.has(&"missing"))


func test_rejects_empty_and_duplicate_ids() -> void:
	var registry := TerrainRegistry.new()
	assert_false(registry.register(_make_definition(&"")))
	assert_true(registry.register(_make_definition(&"grass")))
	assert_false(registry.register(_make_definition(&"grass")))
	assert_eq(registry.ids().size(), 1)


func test_starter_terrains_load() -> void:
	var registry := TerrainRegistry.create_starter()
	assert_eq(registry.ids(), [
		&"grassland", &"forest", &"mountains", &"water", &"desert", &"snow",
	] as Array[StringName])
	for id: StringName in registry.ids():
		var definition: TerrainDefinition = registry.get_definition(id)
		assert_false(definition.display_name.is_empty(), "%s has a name" % id)
		assert_ne(definition.color, Color.MAGENTA, "%s has its own colour" % id)


func test_variant_texture_wraps_and_handles_empty() -> void:
	var definition := _make_definition(&"grass")
	assert_null(definition.get_variant_texture(0), "no sprites → placeholder")
	var a := PlaceholderTexture2D.new()
	var b := PlaceholderTexture2D.new()
	definition.variants = [a, b] as Array[Texture2D]
	assert_eq(definition.get_variant_texture(1), b)
	assert_eq(definition.get_variant_texture(2), a)
	assert_eq(definition.get_variant_texture(-1), b)
