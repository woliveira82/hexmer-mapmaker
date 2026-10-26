extends GutTest

const PaletteScene: PackedScene = preload("res://scenes/editor/terrain_palette.tscn")


func _make_palette() -> TerrainPalette:
	var palette: TerrainPalette = PaletteScene.instantiate()
	add_child_autofree(palette)
	return palette


func test_lists_terrains_in_registry_order() -> void:
	var palette := _make_palette()
	var registry := TerrainRegistry.create_starter()
	palette.set_terrains(registry)
	assert_eq(palette.get_terrain_ids(), registry.ids())


func test_textureless_terrain_gets_colour_icon() -> void:
	var registry := TerrainRegistry.new()
	var flat := TerrainDefinition.new()
	flat.id = &"flat"
	flat.display_name = "Flat"
	registry.register(flat)
	var palette := _make_palette()
	palette.set_terrains(registry)
	var list: ItemList = palette.get_node("%TerrainList")
	assert_not_null(list.get_item_icon(0))


func test_set_tool_and_terrain_do_not_emit() -> void:
	var palette := _make_palette()
	palette.set_terrains(TerrainRegistry.create_starter())
	watch_signals(palette)
	palette.set_tool(EditorController.Tool.ERASE)
	palette.set_terrain(&"water")
	assert_eq(palette.get_shown_tool(), EditorController.Tool.ERASE)
	assert_signal_not_emitted(palette, "tool_selected")
	assert_signal_not_emitted(palette, "terrain_selected")
	var list: ItemList = palette.get_node("%TerrainList")
	assert_eq(list.get_selected_items(), PackedInt32Array([3]))


func test_switching_tools_keeps_one_button_pressed() -> void:
	var palette := _make_palette()
	palette.set_tool(EditorController.Tool.SELECT)
	palette.set_tool(EditorController.Tool.PAINT)
	var pressed: int = 0
	for tool: EditorController.Tool in TerrainPalette.TOOL_ACTIONS:
		if palette.get_tool_button(tool).button_pressed:
			pressed += 1
	assert_eq(pressed, 1)
	assert_eq(palette.get_shown_tool(), EditorController.Tool.PAINT)


func test_tool_buttons_emit_and_show_shortcuts() -> void:
	var palette := _make_palette()
	watch_signals(palette)
	palette.get_tool_button(EditorController.Tool.PAINT).pressed.emit()
	assert_signal_emitted_with_parameters(palette, "tool_selected", [EditorController.Tool.PAINT])
	assert_eq(palette.get_tool_button(EditorController.Tool.PAINT).tooltip_text, "Paint (B)")


func test_undo_state() -> void:
	var palette := _make_palette()
	assert_eq(palette.get_undo_buttons_enabled(), [false, false] as Array[bool])
	palette.set_undo_state(true, false, "Paint 3 hexes", "")
	assert_eq(palette.get_undo_buttons_enabled(), [true, false] as Array[bool])
	var undo: Button = palette.get_node("%UndoButton")
	assert_eq(undo.tooltip_text, "Undo Paint 3 hexes (Ctrl+Z)")
