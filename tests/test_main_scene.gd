extends GutTest
## Milestone 1 acceptance: a 100 × 100 map loads and clicking identifies a hex.

const MainScene: PackedScene = preload("res://scenes/main/main.tscn")
const ORIENTATIONS: Array[HexLayout.HexOrientation] = [
	HexLayout.HexOrientation.POINTY_TOP, HexLayout.HexOrientation.FLAT_TOP,
]


func _make_main(orientation: HexLayout.HexOrientation) -> Node2D:
	var main: Node2D = MainScene.instantiate()
	main.set("orientation", orientation)
	add_child_autofree(main)
	return main


func test_main_scene_builds_100x100_map() -> void:
	var main := _make_main(HexLayout.HexOrientation.POINTY_TOP)
	var renderer: HexMapRenderer = main.get_node("HexMapRenderer")
	assert_eq(renderer.get_chunks().size(), 49)
	var status: StatusBar = main.get_node("UI/StatusBar")
	assert_string_contains(status.get_texts()[2], "100 × 100 pointy-top")
	assert_false(status.get_texts()[3].ends_with(StatusBar.NO_HEX_TEXT), "zoom shown after fit")


func test_click_identifies_hex_in_status_bar() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var main := _make_main(orientation)
		var controller: EditorController = main.get("_controller")
		var status: StatusBar = main.get_node("UI/StatusBar")
		for hex: Vector2i in [Vector2i(0, 0), Vector2i(10, 20), HexCoordinates.even_r_to_axial(Vector2i(99, 99))]:
			controller.select_at(controller.layout.hex_to_pixel(hex))
			assert_eq(controller.selected_hex, hex)
			assert_string_contains(status.get_texts()[1], StatusBar.format_hex(hex))


func test_settings_panel_rebuilds_map() -> void:
	var main := _make_main(HexLayout.HexOrientation.POINTY_TOP)
	var controller: EditorController = main.get("_controller")
	controller.select(Vector2i(50, 50))
	var panel: MapSettingsPanel = main.get_node("UI/MapSettingsPanel")
	panel.set_settings(20, 10, HexLayout.HexOrientation.FLAT_TOP, 16.0)
	panel.apply()
	var renderer: HexMapRenderer = main.get_node("HexMapRenderer")
	assert_eq(renderer.get_chunks().size(), 2, "20 × 10 is two 16 × 16 chunks")
	assert_eq(controller.grid.width, 20)
	assert_eq(controller.grid.height, 10)
	assert_eq(controller.layout.orientation, HexLayout.HexOrientation.FLAT_TOP)
	assert_eq(controller.layout.hex_size, Vector2(16.0, 16.0))
	assert_false(controller.has_selection, "old selection cleared")
	var camera: MapCamera = main.get_node("MapCamera")
	assert_eq(camera.map_rect, renderer.get_map_rect())
	var status: StatusBar = main.get_node("UI/StatusBar")
	assert_string_contains(status.get_texts()[1], StatusBar.NO_HEX_TEXT)
	assert_string_contains(status.get_texts()[2], "20 × 10 flat-top")


func test_new_map_starts_with_grassland_base() -> void:
	var main := _make_main(HexLayout.HexOrientation.POINTY_TOP)
	var map: MapData = main.get("_map")
	assert_eq(map.layer_count(), MapData.DEFAULT_LAYER_NAMES.size())
	var base: MapLayer = map.get_layers()[0]
	assert_eq(base.cell_count(), 10000)
	assert_eq(base.get_cell(Vector2i(10, 20)).terrain_id, &"grassland")
	assert_eq(map.get_layers()[1].cell_count(), 0, "other layers start empty")
	var terrain: TerrainRenderer = main.get_node("TerrainRenderer")
	assert_eq(terrain.get_chunks().size(), 49)
	assert_lt(terrain.get_index(), main.get_node("HexMapRenderer").get_index(), "terrain drawn under the grid")
	var batches := terrain.get_chunks()[0].build_batches()
	assert_eq(batches.size(), 1)
	assert_not_null(batches[0].texture, "grassland drawn with its sprite")


func test_rebuild_replaces_map_data_and_terrain() -> void:
	var main := _make_main(HexLayout.HexOrientation.POINTY_TOP)
	var old_map: MapData = main.get("_map")
	main.rebuild_map(20, 10, HexLayout.HexOrientation.FLAT_TOP, 16.0)
	var map: MapData = main.get("_map")
	assert_ne(map, old_map)
	assert_eq(map.get_layers()[0].cell_count(), 200)
	assert_eq(map.layout.orientation, HexLayout.HexOrientation.FLAT_TOP)
	var controller: EditorController = main.get("_controller")
	assert_eq(controller.grid, map.grid, "controller picks on the new map")
	var terrain: TerrainRenderer = main.get_node("TerrainRenderer")
	assert_eq(terrain.get_chunks().size(), 2)


func test_empty_default_terrain_leaves_map_blank() -> void:
	var main: Node2D = MainScene.instantiate()
	main.set("default_terrain", &"")
	add_child_autofree(main)
	var map: MapData = main.get("_map")
	assert_eq(map.get_layers()[0].cell_count(), 0)
