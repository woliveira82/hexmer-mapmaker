extends GutTest

const EPSILON: float = 0.001
const ORIENTATIONS: Array[HexLayout.HexOrientation] = [
	HexLayout.HexOrientation.POINTY_TOP, HexLayout.HexOrientation.FLAT_TOP,
]


func _assert_near(actual: Vector2, expected: Vector2, label: String = "") -> void:
	assert_lt(actual.distance_to(expected), EPSILON, "%s: %s vs %s" % [label, actual, expected])


func test_origin_hex_is_at_origin() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var layout := HexLayout.new(orientation, Vector2(20.0, 20.0), Vector2(5.0, -7.0))
		_assert_near(layout.hex_to_pixel(Vector2i.ZERO), Vector2(5.0, -7.0), "origin")


func test_pointy_known_positions() -> void:
	var layout := HexLayout.new(HexLayout.HexOrientation.POINTY_TOP, Vector2(10.0, 10.0))
	_assert_near(layout.hex_to_pixel(Vector2i(1, 0)), Vector2(10.0 * HexLayout.SQRT3, 0.0), "q+1")
	_assert_near(layout.hex_to_pixel(Vector2i(0, 1)), Vector2(5.0 * HexLayout.SQRT3, 15.0), "r+1")


func test_flat_known_positions() -> void:
	var layout := HexLayout.new(HexLayout.HexOrientation.FLAT_TOP, Vector2(10.0, 10.0))
	_assert_near(layout.hex_to_pixel(Vector2i(1, 0)), Vector2(15.0, 5.0 * HexLayout.SQRT3), "q+1")
	_assert_near(layout.hex_to_pixel(Vector2i(0, 1)), Vector2(0.0, 10.0 * HexLayout.SQRT3), "r+1")


func test_pixel_hex_round_trip_both_orientations() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var layout := HexLayout.new(orientation, Vector2(24.0, 18.0), Vector2(100.0, -50.0))
		for q: int in range(-6, 7):
			for r: int in range(-6, 7):
				var hex := Vector2i(q, r)
				assert_eq(layout.pixel_to_hex(layout.hex_to_pixel(hex)), hex)


func test_picking_inside_hex_near_corners_and_edges() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var layout := HexLayout.new(orientation, Vector2(30.0, 30.0), Vector2(12.0, 34.0))
		for hex: Vector2i in [Vector2i(0, 0), Vector2i(3, -2), Vector2i(-4, 5)]:
			var center: Vector2 = layout.hex_to_pixel(hex)
			for i: int in range(6):
				var corner: Vector2 = layout.corner_offset(i)
				var edge_mid: Vector2 = (corner + layout.corner_offset(i + 1)) / 2.0
				assert_eq(layout.pixel_to_hex(center + corner * 0.95), hex, "near corner %d" % i)
				assert_eq(layout.pixel_to_hex(center + edge_mid * 0.95), hex, "near edge %d" % i)


func test_picking_across_each_edge_selects_neighbour() -> void:
	for orientation: HexLayout.HexOrientation in ORIENTATIONS:
		var layout := HexLayout.new(orientation, Vector2(16.0, 16.0))
		var hex := Vector2i(2, 1)
		var center: Vector2 = layout.hex_to_pixel(hex)
		for n: Vector2i in HexCoordinates.neighbors(hex):
			var toward: Vector2 = layout.hex_to_pixel(n) - center
			assert_eq(layout.pixel_to_hex(center + toward * 0.49), hex, "just inside toward %s" % n)
			assert_eq(layout.pixel_to_hex(center + toward * 0.51), n, "just across toward %s" % n)


func test_corners_match_orientation() -> void:
	var size: float = 10.0
	var pointy := HexLayout.new(HexLayout.HexOrientation.POINTY_TOP, Vector2(size, size))
	var flat := HexLayout.new(HexLayout.HexOrientation.FLAT_TOP, Vector2(size, size))
	var pointy_corners: PackedVector2Array = pointy.polygon_corners(Vector2i.ZERO)
	var flat_corners: PackedVector2Array = flat.polygon_corners(Vector2i.ZERO)
	assert_eq(pointy_corners.size(), 6)
	for i: int in range(6):
		assert_almost_eq(pointy_corners[i].length(), size, EPSILON, "pointy corner radius")
		assert_almost_eq(flat_corners[i].length(), size, EPSILON, "flat corner radius")
	# Pointy-top has a vertex straight up; flat-top has one straight right.
	assert_true(Array(pointy_corners).any(func(c: Vector2) -> bool: return c.distance_to(Vector2(0.0, -size)) < EPSILON))
	assert_true(Array(flat_corners).any(func(c: Vector2) -> bool: return c.distance_to(Vector2(size, 0.0)) < EPSILON))


func test_changing_orientation_updates_mapping() -> void:
	var layout := HexLayout.new(HexLayout.HexOrientation.POINTY_TOP, Vector2(10.0, 10.0))
	layout.orientation = HexLayout.HexOrientation.FLAT_TOP
	_assert_near(layout.hex_to_pixel(Vector2i(1, 0)), Vector2(15.0, 5.0 * HexLayout.SQRT3), "flat q+1")


func test_hexes_bounds_matches_corner_bounds() -> void:
	for orientation: HexLayout.HexOrientation in [HexLayout.HexOrientation.POINTY_TOP, HexLayout.HexOrientation.FLAT_TOP]:
		var layout := HexLayout.new(orientation, Vector2(20.0, 20.0), Vector2(5.0, -3.0))
		var hexes: Array[Vector2i] = HexGrid.new(7, 5).cells()
		var expected := Rect2(layout.polygon_corners(hexes[0])[0], Vector2.ZERO)
		for hex: Vector2i in hexes:
			for corner: Vector2 in layout.polygon_corners(hex):
				expected = expected.expand(corner)
		var bounds: Rect2 = layout.hexes_bounds(hexes)
		assert_almost_eq(bounds.position, expected.position, Vector2(0.001, 0.001))
		assert_almost_eq(bounds.size, expected.size, Vector2(0.001, 0.001))
	assert_eq(HexLayout.new().hexes_bounds([] as Array[Vector2i]), Rect2())
