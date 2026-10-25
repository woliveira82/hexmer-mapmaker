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
