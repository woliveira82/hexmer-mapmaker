class_name MapLayer
## One map layer: its display state and sparse cell content (hexes without content are absent).
## Locking is editor policy: tools must check [member locked]; the layer itself does not.

## Unique within its [MapData]; stable across renames and reordering.
var id: int
var name: String
var visible: bool = true
var locked: bool = false

var _cells: Dictionary[Vector2i, MapCell] = {}


func _init(p_id: int, p_name: String) -> void:
	id = p_id
	name = p_name


## Returns the cell at [param hex], or null if it is empty.
func get_cell(hex: Vector2i) -> MapCell:
	return _cells.get(hex)


## Sets the cell at [param hex]; null clears it.
func set_cell(hex: Vector2i, cell: MapCell) -> void:
	if cell == null:
		_cells.erase(hex)
	else:
		_cells[hex] = cell


## Returns the number of non-empty hexes.
func cell_count() -> int:
	return _cells.size()


## Returns every non-empty hex.
func used_hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_cells.keys())
	return result
