class_name HexLayout
## Maps axial hexes to 2D positions and back, for one orientation, hex size and origin.
## Pure math; no Node or UI dependencies. Positions are in map space (before camera).

enum HexOrientation { POINTY_TOP, FLAT_TOP }

const SQRT3: float = 1.7320508075688772

## Hex orientation. Changing it rebuilds the conversion transforms.
var orientation: HexOrientation = HexOrientation.POINTY_TOP:
	set(value):
		orientation = value
		_rebuild()

## Distance from hex centre to a corner, per axis (x, y), in map units.
var hex_size: Vector2 = Vector2(32.0, 32.0):
	set(value):
		hex_size = value
		_rebuild()

## Map-space position of the centre of hex (0, 0).
var origin: Vector2 = Vector2.ZERO:
	set(value):
		origin = value
		_rebuild()

var _to_pixel: Transform2D
var _to_hex: Transform2D


func _init(
		p_orientation: HexOrientation = HexOrientation.POINTY_TOP,
		p_hex_size: Vector2 = Vector2(32.0, 32.0),
		p_origin: Vector2 = Vector2.ZERO) -> void:
	orientation = p_orientation
	hex_size = p_hex_size
	origin = p_origin


## Returns the map-space centre of [param hex].
func hex_to_pixel(hex: Vector2i) -> Vector2:
	return _to_pixel * Vector2(hex)


## Returns the fractional axial coordinates under map-space [param point].
func pixel_to_hex_fractional(point: Vector2) -> Vector2:
	return _to_hex * point


## Returns the hex containing map-space [param point].
func pixel_to_hex(point: Vector2) -> Vector2i:
	return HexCoordinates.axial_round(pixel_to_hex_fractional(point))


## Returns the offset of corner [param index] (0–5) from a hex centre.
func corner_offset(index: int) -> Vector2:
	var start_angle: float = 0.5 if orientation == HexOrientation.POINTY_TOP else 0.0
	var angle: float = TAU * (start_angle + index) / 6.0
	return Vector2(cos(angle), sin(angle)) * hex_size


## Returns the map-space bounding box of [param hexes] (empty Rect2 if there are none).
func hexes_bounds(hexes: Array[Vector2i]) -> Rect2:
	if hexes.is_empty():
		return Rect2()
	var centers := Rect2(hex_to_pixel(hexes[0]), Vector2.ZERO)
	for hex: Vector2i in hexes:
		centers = centers.expand(hex_to_pixel(hex))
	var corners := Rect2(corner_offset(0), Vector2.ZERO)
	for i: int in range(1, 6):
		corners = corners.expand(corner_offset(i))
	return Rect2(centers.position + corners.position, centers.size + corners.size)


## Returns the six map-space corners of [param hex].
func polygon_corners(hex: Vector2i) -> PackedVector2Array:
	var center: Vector2 = hex_to_pixel(hex)
	var corners := PackedVector2Array()
	for i: int in range(6):
		corners.append(center + corner_offset(i))
	return corners


func _rebuild() -> void:
	var q_axis: Vector2
	var r_axis: Vector2
	if orientation == HexOrientation.POINTY_TOP:
		q_axis = Vector2(SQRT3, 0.0)
		r_axis = Vector2(SQRT3 / 2.0, 1.5)
	else:
		q_axis = Vector2(1.5, SQRT3 / 2.0)
		r_axis = Vector2(0.0, SQRT3)
	_to_pixel = Transform2D(q_axis * hex_size, r_axis * hex_size, origin)
	_to_hex = _to_pixel.affine_inverse()
