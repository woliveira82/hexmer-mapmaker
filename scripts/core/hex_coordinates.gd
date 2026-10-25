class_name HexCoordinates
## Pure hex-coordinate math. No Node or UI dependencies.
##
## Axial (q, r) stored as Vector2i(q, r) is the primary logical system.
## Cube (q, r, s) with s = -q - r is used for rounding, distance and lines.
## Offset coordinates use the even-r layout, stored as Vector2i(col, row).

## The six axial neighbour offsets, in order. Index with [method neighbor].
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
	Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
]

## Tiny offset applied to line endpoints so samples never land exactly on a hex edge.
const LINE_NUDGE := Vector2(1e-6, 2e-6)


## Converts axial (q, r) to cube (q, r, s).
static func axial_to_cube(hex: Vector2i) -> Vector3i:
	return Vector3i(hex.x, hex.y, -hex.x - hex.y)


## Converts cube (q, r, s) to axial (q, r). Assumes q + r + s == 0.
static func cube_to_axial(cube: Vector3i) -> Vector2i:
	return Vector2i(cube.x, cube.y)


## Rounds fractional cube coordinates to the nearest hex, keeping q + r + s == 0.
static func cube_round(frac: Vector3) -> Vector3i:
	var q: float = roundf(frac.x)
	var r: float = roundf(frac.y)
	var s: float = roundf(frac.z)
	var dq: float = absf(q - frac.x)
	var dr: float = absf(r - frac.y)
	var ds: float = absf(s - frac.z)
	if dq > dr and dq > ds:
		q = -r - s
	elif dr > ds:
		r = -q - s
	else:
		s = -q - r
	return Vector3i(int(q), int(r), int(s))


## Rounds fractional axial coordinates to the nearest hex.
static func axial_round(frac: Vector2) -> Vector2i:
	return cube_to_axial(cube_round(Vector3(frac.x, frac.y, -frac.x - frac.y)))


## Returns the hex distance (number of steps) between two axial hexes.
@warning_ignore("integer_division")
static func distance(a: Vector2i, b: Vector2i) -> int:
	var d: Vector2i = a - b
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2


## Returns the neighbour of [param hex] in [param direction] (wraps modulo 6).
static func neighbor(hex: Vector2i, direction: int) -> Vector2i:
	return hex + DIRECTIONS[posmod(direction, DIRECTIONS.size())]


## Returns all six neighbours of [param hex], in [constant DIRECTIONS] order.
static func neighbors(hex: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction: Vector2i in DIRECTIONS:
		result.append(hex + direction)
	return result


## Returns the hexes on a straight line from [param a] to [param b], inclusive.
static func line(a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var steps: int = distance(a, b)
	var result: Array[Vector2i] = []
	if steps == 0:
		result.append(a)
		return result
	var start: Vector2 = Vector2(a) + LINE_NUDGE
	var end: Vector2 = Vector2(b) + LINE_NUDGE
	for i: int in range(steps + 1):
		result.append(axial_round(start.lerp(end, float(i) / float(steps))))
	return result


## Converts axial (q, r) to even-r offset (col, row).
@warning_ignore("integer_division")
static func axial_to_even_r(hex: Vector2i) -> Vector2i:
	return Vector2i(hex.x + (hex.y + (hex.y & 1)) / 2, hex.y)


## Converts even-r offset (col, row) to axial (q, r).
@warning_ignore("integer_division")
static func even_r_to_axial(offset: Vector2i) -> Vector2i:
	return Vector2i(offset.x - (offset.y + (offset.y & 1)) / 2, offset.y)
