extends GutTest


func test_cell_count_and_unique_contained_cells() -> void:
	var grid := HexGrid.new(7, 5)
	var cells: Array[Vector2i] = grid.cells()
	assert_eq(grid.cell_count(), 35)
	assert_eq(cells.size(), 35)
	var seen: Dictionary = {}
	for hex: Vector2i in cells:
		assert_true(grid.contains(hex), "contains %s" % hex)
		seen[hex] = true
	assert_eq(seen.size(), 35, "cells are unique")


func test_contains_bounds_in_offset_space() -> void:
	var grid := HexGrid.new(4, 3)
	var inside: Array[Vector2i] = [Vector2i(0, 0), Vector2i(3, 0), Vector2i(0, 2), Vector2i(3, 2)]
	var outside: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(4, 0), Vector2i(0, -1), Vector2i(0, 3)]
	for offset: Vector2i in inside:
		assert_true(grid.contains(HexCoordinates.even_r_to_axial(offset)), "inside %s" % offset)
	for offset: Vector2i in outside:
		assert_false(grid.contains(HexCoordinates.even_r_to_axial(offset)), "outside %s" % offset)


func test_large_grid_size() -> void:
	var grid := HexGrid.new(100, 100)
	assert_eq(grid.cells().size(), 10000)


func test_offset_rect_is_clipped_to_bounds() -> void:
	var grid := HexGrid.new(10, 6)
	var cells: Array[Vector2i] = grid.cells_in_offset_rect(Rect2i(8, 4, 16, 16))
	assert_eq(cells.size(), 4, "2 cols x 2 rows remain after clipping")
	for hex: Vector2i in cells:
		assert_true(grid.contains(hex), "contains %s" % hex)


func test_offset_rect_outside_is_empty() -> void:
	var grid := HexGrid.new(10, 6)
	assert_eq(grid.cells_in_offset_rect(Rect2i(20, 20, 5, 5)).size(), 0)


func test_offset_rect_chunks_partition_map() -> void:
	var grid := HexGrid.new(37, 23)
	var seen: Dictionary = {}
	for y: int in range(0, grid.height, 8):
		for x: int in range(0, grid.width, 8):
			for hex: Vector2i in grid.cells_in_offset_rect(Rect2i(x, y, 8, 8)):
				assert_false(seen.has(hex), "hex %s in two chunks" % hex)
				seen[hex] = true
	assert_eq(seen.size(), grid.cell_count())
