extends GutTest


func test_axial_cube_round_trip() -> void:
	for q: int in range(-5, 6):
		for r: int in range(-5, 6):
			var hex := Vector2i(q, r)
			var cube: Vector3i = HexCoordinates.axial_to_cube(hex)
			assert_eq(cube.x + cube.y + cube.z, 0, "cube constraint for %s" % hex)
			assert_eq(HexCoordinates.cube_to_axial(cube), hex)


func test_axial_round_exact_and_near_centre() -> void:
	assert_eq(HexCoordinates.axial_round(Vector2(3.0, -2.0)), Vector2i(3, -2))
	assert_eq(HexCoordinates.axial_round(Vector2(3.2, -2.1)), Vector2i(3, -2))
	assert_eq(HexCoordinates.axial_round(Vector2(-0.3, 0.2)), Vector2i(0, 0))


func test_cube_round_keeps_constraint() -> void:
	var samples: Array[Vector3] = [
		Vector3(0.4, 0.4, -0.8), Vector3(1.5, -0.6, -0.9), Vector3(-2.45, 1.1, 1.35),
	]
	for frac: Vector3 in samples:
		var cube: Vector3i = HexCoordinates.cube_round(frac)
		assert_eq(cube.x + cube.y + cube.z, 0, "rounded %s" % frac)


func test_distance_known_values() -> void:
	assert_eq(HexCoordinates.distance(Vector2i(0, 0), Vector2i(0, 0)), 0)
	assert_eq(HexCoordinates.distance(Vector2i(0, 0), Vector2i(3, -1)), 3)
	assert_eq(HexCoordinates.distance(Vector2i(0, 0), Vector2i(2, 2)), 4)
	assert_eq(HexCoordinates.distance(Vector2i(-2, 1), Vector2i(1, -3)), 4)


func test_distance_is_symmetric() -> void:
	var a := Vector2i(4, -7)
	var b := Vector2i(-3, 2)
	assert_eq(HexCoordinates.distance(a, b), HexCoordinates.distance(b, a))


func test_neighbors_are_unique_and_adjacent() -> void:
	var hex := Vector2i(2, -1)
	var result: Array[Vector2i] = HexCoordinates.neighbors(hex)
	assert_eq(result.size(), 6)
	for n: Vector2i in result:
		assert_eq(HexCoordinates.distance(hex, n), 1, "neighbour %s" % n)
		assert_eq(result.count(n), 1, "duplicate neighbour %s" % n)


func test_neighbor_direction_wraps() -> void:
	var hex := Vector2i(0, 0)
	assert_eq(HexCoordinates.neighbor(hex, 6), HexCoordinates.neighbor(hex, 0))
	assert_eq(HexCoordinates.neighbor(hex, -1), HexCoordinates.neighbor(hex, 5))


func test_line_same_hex() -> void:
	assert_eq(HexCoordinates.line(Vector2i(1, 1), Vector2i(1, 1)), [Vector2i(1, 1)] as Array[Vector2i])


func test_line_is_contiguous_with_correct_endpoints() -> void:
	var a := Vector2i(-3, 1)
	var b := Vector2i(4, -2)
	var result: Array[Vector2i] = HexCoordinates.line(a, b)
	assert_eq(result.size(), HexCoordinates.distance(a, b) + 1)
	assert_eq(result.front(), a)
	assert_eq(result.back(), b)
	for i: int in range(1, result.size()):
		assert_eq(HexCoordinates.distance(result[i - 1], result[i]), 1, "step %d" % i)


func test_even_r_known_values() -> void:
	assert_eq(HexCoordinates.axial_to_even_r(Vector2i(0, 0)), Vector2i(0, 0))
	assert_eq(HexCoordinates.axial_to_even_r(Vector2i(0, 1)), Vector2i(1, 1))
	assert_eq(HexCoordinates.axial_to_even_r(Vector2i(-1, 2)), Vector2i(0, 2))
	assert_eq(HexCoordinates.axial_to_even_r(Vector2i(0, -1)), Vector2i(0, -1))


func test_even_r_round_trip() -> void:
	for col: int in range(-6, 7):
		for row: int in range(-6, 7):
			var offset := Vector2i(col, row)
			var axial: Vector2i = HexCoordinates.even_r_to_axial(offset)
			assert_eq(HexCoordinates.axial_to_even_r(axial), offset)
