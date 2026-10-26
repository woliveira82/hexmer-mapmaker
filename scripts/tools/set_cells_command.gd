class_name SetCellsCommand
extends EditCommand
## Sets cells on one layer and remembers what they were. Used for painting and erasing.
## Stores only the affected hexes: [code]before[/code] and [code]after[/code] (null = empty).

var map: MapData
var layer_id: int
var description: String

var _before: Dictionary[Vector2i, MapCell] = {}
var _after: Dictionary[Vector2i, MapCell] = {}


func _init(p_map: MapData, p_layer_id: int, p_description: String = "Edit") -> void:
	map = p_map
	layer_id = p_layer_id
	description = p_description


## Returns a command that sets every hex in [param hexes] to [param cell].
## Hexes outside the map or already holding the same content are left out;
## a missing or locked layer gives an empty command.
static func paint(p_map: MapData, p_layer_id: int, hexes: Array[Vector2i], cell: MapCell) -> SetCellsCommand:
	var command := SetCellsCommand.new(p_map, p_layer_id, "Paint")
	var layer: MapLayer = p_map.get_layer(p_layer_id)
	if layer == null or layer.locked:
		return command
	for hex: Vector2i in hexes:
		var current: MapCell = layer.get_cell(hex)
		if p_map.grid.contains(hex) and not cell.equals(current):
			command.add_change(hex, current, cell)
	return command


## Returns a command that clears every hex in [param hexes] on the layer.
## Hexes that are already empty are left out; a missing or locked layer gives an empty command.
static func erase(p_map: MapData, p_layer_id: int, hexes: Array[Vector2i]) -> SetCellsCommand:
	var command := SetCellsCommand.new(p_map, p_layer_id, "Erase")
	var layer: MapLayer = p_map.get_layer(p_layer_id)
	if layer == null or layer.locked:
		return command
	for hex: Vector2i in hexes:
		var current: MapCell = layer.get_cell(hex)
		if current != null:
			command.add_change(hex, current, null)
	return command


## Records that [param hex] goes from [param before] to [param after]. If the hex is already
## recorded, its original [code]before[/code] is kept and only [code]after[/code] is updated.
func add_change(hex: Vector2i, before: MapCell, after: MapCell) -> void:
	if not _before.has(hex):
		_before[hex] = before
	_after[hex] = after


## Folds [param other] (a later edit on the same layer) into this command, so a drag
## stroke undoes as one step. Returns false if the layers differ.
func merge(other: SetCellsCommand) -> bool:
	if other.map != map or other.layer_id != layer_id:
		return false
	for hex: Vector2i in other._after:
		add_change(hex, other._before[hex], other._after[hex])
	return true


## Returns the hexes this command changes.
func get_hexes() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(_after.keys())
	return result


func do() -> void:
	map.set_cells(layer_id, _after)


func undo() -> void:
	map.set_cells(layer_id, _before)


## True when no hex actually changes (including hexes painted and then restored in one stroke).
func is_empty() -> bool:
	for hex: Vector2i in _after:
		var before: MapCell = _before[hex]
		var after: MapCell = _after[hex]
		if not (before == after or (before != null and before.equals(after))):
			return false
	return true


func get_description() -> String:
	var count: int = _after.size()
	return "%s %d %s" % [description, count, "hex" if count == 1 else "hexes"]
