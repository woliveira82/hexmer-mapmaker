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
