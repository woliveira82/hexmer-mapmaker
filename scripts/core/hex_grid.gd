class_name HexGrid
## Bounds of a finite rectangular hex map: [member width] even-r columns by
## [member height] rows. Holds no cell content; it only answers which axial hexes exist.

var width: int
var height: int


func _init(p_width: int, p_height: int) -> void:
	assert(p_width > 0 and p_height > 0, "HexGrid dimensions must be positive")
	width = p_width
	height = p_height


## Returns true if axial [param hex] lies inside the map bounds.
func contains(hex: Vector2i) -> bool:
	var offset: Vector2i = HexCoordinates.axial_to_even_r(hex)
	return offset.x >= 0 and offset.x < width and offset.y >= 0 and offset.y < height


## Returns the number of hexes in the map.
func cell_count() -> int:
	return width * height


## Returns every axial hex in the map, row by row.
func cells() -> Array[Vector2i]:
	return cells_in_offset_rect(Rect2i(0, 0, width, height))


## Returns the axial hexes whose even-r offset (col, row) lies in [param rect],
## clipped to the map bounds, row by row. Used to split the map into chunks.
func cells_in_offset_rect(rect: Rect2i) -> Array[Vector2i]:
	var clipped: Rect2i = rect.intersection(Rect2i(0, 0, width, height))
	var result: Array[Vector2i] = []
	result.resize(clipped.get_area())
	var i: int = 0
	for row: int in range(clipped.position.y, clipped.end.y):
		for col: int in range(clipped.position.x, clipped.end.x):
			result[i] = HexCoordinates.even_r_to_axial(Vector2i(col, row))
			i += 1
	return result
