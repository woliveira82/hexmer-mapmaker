extends GutTest
## Paint/erase strokes through the editor controller, and undo/redo of whole strokes.

var _controller: EditorController
var _map: MapData
var _base: int


func before_each() -> void:
	_map = MapData.create_default(HexGrid.new(12, 10), HexLayout.new())
	_controller = EditorController.new(_map, TerrainRegistry.create_starter())
	_controller.rng.seed = 7
	_base = _map.get_layers()[0].id


func _pos(hex: Vector2i) -> Vector2:
	return _map.layout.hex_to_pixel(hex)


func _stroke(hexes: Array[Vector2i]) -> void:
	_controller.primary_pressed(_pos(hexes[0]))
	for i: int in range(1, hexes.size()):
		_controller.primary_dragged(_pos(hexes[i]))
	_controller.primary_released()


func _painted(layer_id: int, terrain: StringName) -> int:
	var count: int = 0
	var layer: MapLayer = _map.get_layer(layer_id)
	for hex: Vector2i in layer.used_hexes():
		if layer.get_cell(hex).terrain_id == terrain:
			count += 1
	return count


func test_defaults() -> void:
	assert_eq(_controller.active_tool, EditorController.Tool.SELECT)
	assert_eq(_controller.active_layer_id, _base, "bottom layer active")
	assert_eq(_controller.active_terrain, &"grassland", "first registered terrain")


func test_select_tool_selects_instead_of_painting() -> void:
	_controller.primary_pressed(_pos(Vector2i(2, 2)))
	_controller.primary_released()
	assert_true(_controller.has_selection)
	assert_eq(_map.get_layer(_base).cell_count(), 0)
	assert_false(_controller.undo_stack.can_undo())


func test_paint_stroke_is_one_undo_step() -> void:
	_controller.active_tool = EditorController.Tool.PAINT
	_controller.active_terrain = &"water"
	_stroke([Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)] as Array[Vector2i])
	assert_eq(_painted(_base, &"water"), 3)
	assert_false(_controller.is_stroking())
	assert_eq(_controller.undo_stack.undo_description(), "Paint 3 hexes")
	assert_true(_controller.undo())
	assert_eq(_map.get_layer(_base).cell_count(), 0)
	assert_false(_controller.undo_stack.can_undo())
	assert_true(_controller.redo())
	assert_eq(_painted(_base, &"water"), 3)


func test_fast_drag_fills_gaps() -> void:
	_controller.active_tool = EditorController.Tool.PAINT
	_stroke([Vector2i(0, 0), Vector2i(6, 0)] as Array[Vector2i])
	assert_eq(_map.get_layer(_base).cell_count(), 7, "every hex on the line is painted")


func test_drag_off_map_and_back() -> void:
	_controller.active_tool = EditorController.Tool.PAINT
	_stroke([Vector2i(1, 1), Vector2i(-4, 1), Vector2i(0, 1)] as Array[Vector2i])
	for hex: Vector2i in _map.get_layer(_base).used_hexes():
		assert_true(_map.grid.contains(hex))
	# Row 1 is shifted in even-r, so (-1, 1) is column 0 and still on the map.
	assert_eq(_map.get_layer(_base).cell_count(), 3, "(1,1), (0,1), (-1,1); off-map hexes skipped")


func test_variants_vary_and_same_terrain_keeps_variant() -> void:
	_controller.active_tool = EditorController.Tool.PAINT
	var row: Array[Vector2i] = [Vector2i(0, 0), Vector2i(11, 0)]
	_stroke(row)
	var variants: Dictionary[int, bool] = {}
	var before: Dictionary[Vector2i, int] = {}
	for hex: Vector2i in _map.get_layer(_base).used_hexes():
		var cell: MapCell = _map.get_cell(_base, hex)
		variants[cell.variant] = true
		before[hex] = cell.variant
	assert_eq(variants.size(), 2, "12 grassland hexes use both sprite variants")
	_stroke(row)
	for hex: Vector2i in before:
		assert_eq(_map.get_cell(_base, hex).variant, before[hex], "repainting same terrain is a no-op")
	assert_eq(_controller.undo_stack.undo_description(), "Paint 12 hexes", "no-op stroke not recorded")


func test_erase_stroke_on_active_layer_only() -> void:
	var details: int = _map.get_layers()[1].id
	_map.fill_layer(_base, MapCell.new(&"desert"))
	_map.fill_layer(details, MapCell.new(&"forest"))
	_controller.active_layer_id = details
	_controller.active_tool = EditorController.Tool.ERASE
	_stroke([Vector2i(0, 0), Vector2i(3, 0)] as Array[Vector2i])
	assert_eq(_map.get_layer(details).cell_count(), 120 - 4)
	assert_eq(_map.get_layer(_base).cell_count(), 120, "base layer untouched")
	_controller.undo()
	assert_eq(_map.get_layer(details).cell_count(), 120)


func test_locked_layer_is_not_painted() -> void:
	_map.set_layer_locked(_base, true)
	_controller.active_tool = EditorController.Tool.PAINT
	_stroke([Vector2i(0, 0), Vector2i(3, 0)] as Array[Vector2i])
	assert_eq(_map.get_layer(_base).cell_count(), 0)
	assert_false(_controller.undo_stack.can_undo())


func test_undo_mid_stroke_ends_stroke_first() -> void:
	_controller.active_tool = EditorController.Tool.PAINT
	_controller.primary_pressed(_pos(Vector2i(0, 0)))
	_controller.primary_dragged(_pos(Vector2i(2, 0)))
	assert_true(_controller.undo())
	assert_false(_controller.is_stroking())
	assert_eq(_map.get_layer(_base).cell_count(), 0)
	_controller.primary_dragged(_pos(Vector2i(5, 0)))
	assert_eq(_map.get_layer(_base).cell_count(), 0, "drag after undo does not resume the stroke")


func test_switching_tool_ends_stroke() -> void:
	_controller.active_tool = EditorController.Tool.PAINT
	_controller.primary_pressed(_pos(Vector2i(0, 0)))
	watch_signals(_controller)
	_controller.active_tool = EditorController.Tool.ERASE
	assert_false(_controller.is_stroking())
	assert_true(_controller.undo_stack.can_undo())
	assert_signal_emitted_with_parameters(_controller, "tool_changed", [EditorController.Tool.ERASE])


func test_set_map_clears_history_and_resets_layer() -> void:
	_controller.active_tool = EditorController.Tool.PAINT
	_stroke([Vector2i(0, 0)] as Array[Vector2i])
	_controller.active_layer_id = _map.get_layers()[3].id
	var new_map := MapData.create_default(HexGrid.new(5, 5), HexLayout.new())
	_controller.set_map(new_map)
	assert_false(_controller.undo_stack.can_undo())
	assert_eq(_controller.active_layer_id, new_map.get_layers()[0].id)
