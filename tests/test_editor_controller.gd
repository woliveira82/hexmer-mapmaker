extends GutTest

const ORIENTATIONS: Array[HexLayout.HexOrientation] = [
	HexLayout.HexOrientation.POINTY_TOP, HexLayout.HexOrientation.FLAT_TOP,
]


func _make(orientation: HexLayout.HexOrientation = HexLayout.HexOrientation.POINTY_TOP) -> EditorController:
	return EditorController.new(HexGrid.new(10, 8), HexLayout.new(orientation, Vector2(20.0, 20.0)))


func test_hover_inside_emits_once_per_hex() -> void:
	var controller := _make()
	watch_signals(controller)
	var center: Vector2 = controller.layout.hex_to_pixel(Vector2i(2, 3))
	controller.update_hover(center)
	controller.update_hover(center + Vector2(3.0, 2.0))
	assert_signal_emit_count(controller, "hovered_changed", 1)
	assert_signal_emitted_with_parameters(controller, "hovered_changed", [Vector2i(2, 3), true])
	assert_true(controller.is_hovering)


func test_hover_off_map_reports_outside() -> void:
	var controller := _make()
	controller.update_hover(controller.layout.hex_to_pixel(Vector2i(1, 1)))
	watch_signals(controller)
	controller.update_hover(controller.layout.hex_to_pixel(Vector2i(-5, -5)))
	assert_signal_emit_count(controller, "hovered_changed", 1)
	assert_false(controller.is_hovering)
	controller.update_hover(controller.layout.hex_to_pixel(Vector2i(-6, -5)))
	assert_signal_emit_count(controller, "hovered_changed", 1, "no repeat while staying off-map")


func test_clear_hover() -> void:
	var controller := _make()
	controller.update_hover(controller.layout.hex_to_pixel(Vector2i(1, 1)))
	controller.clear_hover()
	assert_false(controller.is_hovering)


func test_click_selects_hex_in_both_orientations() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var controller := _make(orientation)
		for hex: Vector2i in controller.grid.cells():
			controller.select_at(controller.layout.hex_to_pixel(hex) + Vector2(4.0, -3.0))
			assert_true(controller.has_selection)
			assert_eq(controller.selected_hex, hex)


func test_click_off_map_clears_selection() -> void:
	var controller := _make()
	controller.select_at(controller.layout.hex_to_pixel(Vector2i(1, 1)))
	watch_signals(controller)
	controller.select_at(controller.layout.hex_to_pixel(Vector2i(50, 50)))
	assert_false(controller.has_selection)
	assert_signal_emitted_with_parameters(controller, "selected_changed", [Vector2i(1, 1), false])


func test_reselecting_same_hex_does_not_emit() -> void:
	var controller := _make()
	controller.select(Vector2i(1, 1))
	watch_signals(controller)
	controller.select(Vector2i(1, 1))
	assert_signal_not_emitted(controller, "selected_changed")


func test_select_outside_map_is_ignored() -> void:
	var controller := _make()
	controller.select(Vector2i(-20, 0))
	assert_false(controller.has_selection)


func test_set_map_clears_hover_and_selection() -> void:
	var controller := _make()
	controller.update_hover(controller.layout.hex_to_pixel(Vector2i(1, 1)))
	controller.select(Vector2i(2, 2))
	watch_signals(controller)
	var grid := HexGrid.new(3, 3)
	controller.set_map(grid, HexLayout.new(HexLayout.HexOrientation.FLAT_TOP))
	assert_signal_emitted_with_parameters(controller, "hovered_changed", [Vector2i(1, 1), false])
	assert_signal_emitted_with_parameters(controller, "selected_changed", [Vector2i(2, 2), false])
	assert_false(controller.is_hovering)
	assert_false(controller.has_selection)
	assert_eq(controller.grid, grid)
	assert_eq(controller.layout.orientation, HexLayout.HexOrientation.FLAT_TOP)
