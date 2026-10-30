extends GutTest


func _make_map() -> MapData:
	return MapData.create_default(HexGrid.new(10, 8), HexLayout.new())


func _layer_names(map: MapData) -> PackedStringArray:
	var names := PackedStringArray()
	for layer: MapLayer in map.get_layers():
		names.append(layer.name)
	return names


func test_default_layers() -> void:
	var map := _make_map()
	assert_eq(_layer_names(map), PackedStringArray(MapData.DEFAULT_LAYER_NAMES))
	var ids: Dictionary = {}
	for layer: MapLayer in map.get_layers():
		ids[layer.id] = true
		assert_true(layer.visible)
		assert_false(layer.locked)
	assert_eq(ids.size(), MapData.DEFAULT_LAYER_NAMES.size(), "layer IDs are unique")


func test_add_move_rename_remove_layers() -> void:
	var map := MapData.new(HexGrid.new(4, 4), HexLayout.new())
	watch_signals(map)
	var a := map.add_layer("A")
	var b := map.add_layer("B")
	var c := map.add_layer("C", 0)
	assert_eq(_layer_names(map), PackedStringArray(["C", "A", "B"]))
	assert_true(map.move_layer(c.id, 99))
	assert_eq(_layer_names(map), PackedStringArray(["A", "B", "C"]))
	assert_true(map.rename_layer(b.id, "Roads"))
	assert_eq(map.get_layer(b.id).name, "Roads")
	assert_eq(map.remove_layer(a.id), a)
	assert_eq(map.layer_index(b.id), 0)
	assert_null(map.get_layer(a.id))
	assert_false(map.move_layer(a.id, 0), "removed layer can't be moved")
	assert_signal_emit_count(map, "layers_changed", 6)


func test_removed_layer_can_be_reinserted_with_cells() -> void:
	var map := _make_map()
	var layer: MapLayer = map.get_layers()[2]
	map.set_cell(layer.id, Vector2i(1, 1), MapCell.new(&"forest"))
	var removed := map.remove_layer(layer.id)
	map.insert_layer(removed, 2)
	assert_eq(map.layer_index(layer.id), 2)
	assert_eq(map.get_cell(layer.id, Vector2i(1, 1)).terrain_id, &"forest")
	var fresh := map.add_layer("New")
	assert_ne(fresh.id, layer.id, "new IDs never reuse existing ones")


func test_visibility_and_lock_flags() -> void:
	var map := _make_map()
	var id: int = map.get_layers()[0].id
	assert_true(map.set_layer_visible(id, false))
	assert_true(map.set_layer_locked(id, true))
	assert_false(map.get_layer(id).visible)
	assert_true(map.get_layer(id).locked)
	assert_false(map.set_layer_visible(-1, false))


func test_cells_are_per_layer() -> void:
	var map := _make_map()
	var base: int = map.get_layers()[0].id
	var details: int = map.get_layers()[1].id
	assert_true(map.set_cell(base, Vector2i(2, 3), MapCell.new(&"grassland", 1)))
	assert_eq(map.get_cell(base, Vector2i(2, 3)).variant, 1)
	assert_null(map.get_cell(details, Vector2i(2, 3)), "other layers unaffected")
	assert_true(map.set_cell(base, Vector2i(2, 3), null))
	assert_null(map.get_cell(base, Vector2i(2, 3)))
	assert_eq(map.get_layer(base).cell_count(), 0)


func test_set_cells_skips_out_of_bounds_and_emits_once() -> void:
	var map := _make_map()
	var base: int = map.get_layers()[0].id
	watch_signals(map)
	var cells: Dictionary[Vector2i, MapCell] = {
		Vector2i(0, 0): MapCell.new(&"water"),
		Vector2i(1, 0): MapCell.new(&"water"),
		Vector2i(-5, -5): MapCell.new(&"water"),
	}
	assert_eq(map.set_cells(base, cells), 2)
	assert_signal_emit_count(map, "cells_changed", 1)
	var params: Array = get_signal_parameters(map, "cells_changed")
	assert_eq(params[0], base)
	assert_eq(params[1].size(), 2)
	assert_false(map.set_cell(base, Vector2i(-5, -5), MapCell.new(&"water")))
	assert_eq(map.set_cells(999, cells), 0, "missing layer")
	assert_signal_emit_count(map, "cells_changed", 1)


func test_unknown_terrain_ids_are_kept() -> void:
	var map := _make_map()
	var base: int = map.get_layers()[0].id
	map.set_cell(base, Vector2i(0, 0), MapCell.new(&"not_in_any_pack", 7))
	var cell := map.get_cell(base, Vector2i(0, 0))
	assert_eq(cell.terrain_id, &"not_in_any_pack")
	assert_eq(cell.variant, 7)
	assert_null(TerrainRegistry.create_starter().get_definition(cell.terrain_id))


func test_cell_equality() -> void:
	assert_true(MapCell.new(&"a", 1).equals(MapCell.new(&"a", 1)))
	assert_false(MapCell.new(&"a", 1).equals(MapCell.new(&"a", 2)))
	assert_false(MapCell.new(&"a").equals(null))


func test_fill_layer_covers_every_hex_on_that_layer_only() -> void:
	var map := _make_map()
	var base: int = map.get_layers()[0].id
	watch_signals(map)
	assert_eq(map.fill_layer(base, MapCell.new(&"grassland")), 80)
	assert_eq(map.get_layer(base).cell_count(), 80)
	assert_eq(map.get_layers()[1].cell_count(), 0)
	assert_signal_emitted_with_parameters(map, "layer_content_changed", [base])
	assert_signal_not_emitted(map, "cells_changed", "no per-hex list for a whole-layer fill")
	assert_eq(map.fill_layer(999, MapCell.new(&"grassland")), 0, "missing layer")
