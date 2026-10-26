extends GutTest
## Paint/erase commands and the undo stack.

const GRASS: StringName = &"grassland"
const WATER: StringName = &"water"

var _map: MapData
var _base: int
var _details: int


func before_each() -> void:
	_map = MapData.create_default(HexGrid.new(10, 8), HexLayout.new())
	_base = _map.get_layers()[0].id
	_details = _map.get_layers()[1].id


func _hexes(list: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(list)
	return result


## Returns a comparable snapshot of every layer: {layer_id: {hex: "id:variant"}}.
func _snapshot() -> Dictionary:
	var result: Dictionary = {}
	for layer: MapLayer in _map.get_layers():
		var cells: Dictionary = {}
		for hex: Vector2i in layer.used_hexes():
			var cell: MapCell = layer.get_cell(hex)
			cells[hex] = "%s:%d" % [cell.terrain_id, cell.variant]
		result[layer.id] = cells
	return result


func test_paint_stores_only_affected_hexes() -> void:
	_map.set_cell(_base, Vector2i(1, 1), MapCell.new(GRASS))
	var hexes := _hexes([Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2), Vector2i(-9, -9)])
	var command := SetCellsCommand.paint(_map, _base, hexes, MapCell.new(GRASS))
	assert_eq(command.get_hexes().size(), 2, "skips the unchanged and out-of-bounds hexes")
	assert_eq(command.get_description(), "Paint 2 hexes")


func test_paint_undo_redo_round_trip() -> void:
	_map.set_cell(_base, Vector2i(1, 1), MapCell.new(WATER, 1))
	var original := _snapshot()
	var stack := UndoStack.new()
	stack.execute(SetCellsCommand.paint(_map, _base, _hexes([Vector2i(0, 0), Vector2i(1, 1)]), MapCell.new(GRASS)))
	var painted := _snapshot()
	assert_eq(_map.get_cell(_base, Vector2i(1, 1)).terrain_id, GRASS)
	assert_true(stack.undo())
	assert_eq(_snapshot(), original, "undo restores the previous cell, including its variant")
	assert_true(stack.redo())
	assert_eq(_snapshot(), painted)


func test_erase_only_touches_active_layer() -> void:
	_map.set_cell(_base, Vector2i(3, 3), MapCell.new(GRASS))
	_map.set_cell(_details, Vector2i(3, 3), MapCell.new(WATER))
	var original := _snapshot()
	var stack := UndoStack.new()
	var command := SetCellsCommand.erase(_map, _details, _hexes([Vector2i(3, 3), Vector2i(4, 4)]))
	assert_eq(command.get_hexes(), _hexes([Vector2i(3, 3)]), "empty hexes are not recorded")
	stack.execute(command)
	assert_null(_map.get_cell(_details, Vector2i(3, 3)))
	assert_eq(_map.get_cell(_base, Vector2i(3, 3)).terrain_id, GRASS, "other layer untouched")
	stack.undo()
	assert_eq(_snapshot(), original)


func test_locked_or_missing_layer_gives_empty_command() -> void:
	_map.set_layer_locked(_base, true)
	var stack := UndoStack.new()
	assert_true(SetCellsCommand.paint(_map, _base, _hexes([Vector2i(0, 0)]), MapCell.new(GRASS)).is_empty())
	assert_true(SetCellsCommand.erase(_map, 999, _hexes([Vector2i(0, 0)])).is_empty())
	assert_false(stack.execute(SetCellsCommand.paint(_map, _base, _hexes([Vector2i(0, 0)]), MapCell.new(GRASS))))
	assert_false(stack.can_undo(), "empty commands are not recorded")
	assert_null(_map.get_cell(_base, Vector2i(0, 0)))


func test_merged_stroke_undoes_in_one_step() -> void:
	var original := _snapshot()
	var stack := UndoStack.new()
	var stroke: SetCellsCommand = null
	# Simulates a drag: each segment is applied live, then merged into the stroke.
	for hex: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 0), Vector2i(2, 0)]:
		var segment := SetCellsCommand.paint(_map, _base, _hexes([hex]), MapCell.new(GRASS))
		segment.do()
		if stroke == null:
			stroke = segment
		else:
			assert_true(stroke.merge(segment))
	assert_true(stack.push_done(stroke))
	assert_eq(stroke.get_hexes().size(), 3)
	assert_eq(_map.get_layer(_base).cell_count(), 3)
	stack.undo()
	assert_eq(_snapshot(), original)
	assert_false(stack.can_undo())


func test_merge_keeps_first_before_and_detects_no_op() -> void:
	_map.set_cell(_base, Vector2i(0, 0), MapCell.new(WATER))
	var first := SetCellsCommand.paint(_map, _base, _hexes([Vector2i(0, 0)]), MapCell.new(GRASS))
	first.do()
	var second := SetCellsCommand.paint(_map, _base, _hexes([Vector2i(0, 0)]), MapCell.new(WATER))
	second.do()
	first.merge(second)
	assert_true(first.is_empty(), "water → grass → water is no change overall")
	assert_false(first.merge(SetCellsCommand.new(_map, _details)), "different layers don't merge")


func test_new_command_clears_redo() -> void:
	var stack := UndoStack.new()
	stack.execute(SetCellsCommand.paint(_map, _base, _hexes([Vector2i(0, 0)]), MapCell.new(GRASS)))
	stack.undo()
	assert_true(stack.can_redo())
	stack.execute(SetCellsCommand.paint(_map, _base, _hexes([Vector2i(1, 0)]), MapCell.new(WATER)))
	assert_false(stack.can_redo())
	assert_false(stack.redo())


func test_many_operations_undo_back_to_start() -> void:
	var original := _snapshot()
	var stack := UndoStack.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var terrains: Array[StringName] = [GRASS, WATER, &"forest"]
	var layers: Array[int] = [_base, _details]
	var states: Array[Dictionary] = [original]
	for i: int in 40:
		var hexes: Array[Vector2i] = []
		for j: int in rng.randi_range(1, 5):
			hexes.append(HexCoordinates.even_r_to_axial(Vector2i(rng.randi_range(0, 9), rng.randi_range(0, 7))))
		var layer: int = layers[rng.randi_range(0, 1)]
		var command: SetCellsCommand
		if rng.randf() < 0.3:
			command = SetCellsCommand.erase(_map, layer, hexes)
		else:
			command = SetCellsCommand.paint(_map, layer, hexes, MapCell.new(terrains[rng.randi_range(0, 2)], rng.randi_range(0, 1)))
		if stack.execute(command):
			states.append(_snapshot())
	for i: int in range(states.size() - 1, 0, -1):
		assert_eq(_snapshot(), states[i])
		assert_true(stack.undo())
	assert_eq(_snapshot(), original)
	assert_false(stack.undo())
	while stack.redo():
		pass
	assert_eq(_snapshot(), states.back())


func test_max_size_drops_oldest() -> void:
	var stack := UndoStack.new()
	stack.max_size = 3
	for col: int in 5:
		stack.execute(SetCellsCommand.paint(_map, _base, _hexes([Vector2i(col, 0)]), MapCell.new(GRASS)))
	var undone: int = 0
	while stack.undo():
		undone += 1
	assert_eq(undone, 3)
	assert_eq(_map.get_layer(_base).cell_count(), 2, "the two oldest edits can no longer be undone")


func test_signals_and_descriptions() -> void:
	var stack := UndoStack.new()
	watch_signals(stack)
	assert_eq(stack.undo_description(), "")
	stack.execute(SetCellsCommand.paint(_map, _base, _hexes([Vector2i(0, 0)]), MapCell.new(GRASS)))
	assert_eq(stack.undo_description(), "Paint 1 hex")
	stack.undo()
	assert_eq(stack.redo_description(), "Paint 1 hex")
	stack.clear()
	assert_false(stack.can_redo())
	assert_signal_emit_count(stack, "changed", 3)
