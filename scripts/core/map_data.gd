class_name MapData
## The logical map: bounds, layout, seed and an ordered stack of layers (index 0 is drawn
## first, i.e. at the bottom). Renderers and tools read and edit it; it knows nothing about them.

## Emitted when cells on a layer change.
signal cells_changed(layer_id: int, hexes: Array[Vector2i])
## Emitted when layers are added, removed, reordered, renamed, hidden or locked.
signal layers_changed

const DEFAULT_LAYER_NAMES: Array[String] = [
	"Base terrain", "Terrain details", "Natural objects",
	"Infrastructure", "Settlements", "Annotations",
]

var grid: HexGrid
var layout: HexLayout
var map_seed: int = 0

var _layers: Array[MapLayer] = []
var _next_layer_id: int = 1


func _init(p_grid: HexGrid, p_layout: HexLayout) -> void:
	grid = p_grid
	layout = p_layout


## Returns a map with the standard layers from [constant DEFAULT_LAYER_NAMES].
static func create_default(p_grid: HexGrid, p_layout: HexLayout) -> MapData:
	var map := MapData.new(p_grid, p_layout)
	for layer_name: String in DEFAULT_LAYER_NAMES:
		map.add_layer(layer_name)
	return map


# --- Layers ---------------------------------------------------------------------------------

## Returns the layers, bottom first. The array is a copy; the layers are not.
func get_layers() -> Array[MapLayer]:
	return _layers.duplicate()


## Returns the number of layers.
func layer_count() -> int:
	return _layers.size()


## Returns the layer with [param id], or null.
func get_layer(id: int) -> MapLayer:
	var index: int = layer_index(id)
	return _layers[index] if index >= 0 else null


## Returns the stack index of layer [param id], or -1.
func layer_index(id: int) -> int:
	for i: int in _layers.size():
		if _layers[i].id == id:
			return i
	return -1


## Creates a layer at [param index] (-1 = top) and returns it.
func add_layer(layer_name: String, index: int = -1) -> MapLayer:
	var layer := MapLayer.new(_next_layer_id, layer_name)
	_next_layer_id += 1
	insert_layer(layer, index)
	return layer


## Inserts an existing [param layer] at [param index] (-1 = top), e.g. to undo a removal.
## Its ID must not already be in the map.
func insert_layer(layer: MapLayer, index: int = -1) -> void:
	assert(layer_index(layer.id) == -1, "Layer ID already in map")
	if index < 0 or index > _layers.size():
		index = _layers.size()
	_layers.insert(index, layer)
	_next_layer_id = maxi(_next_layer_id, layer.id + 1)
	layers_changed.emit()


## Removes layer [param id] and returns it (with its cells), or null if not found.
func remove_layer(id: int) -> MapLayer:
	var index: int = layer_index(id)
	if index < 0:
		return null
	var layer: MapLayer = _layers[index]
	_layers.remove_at(index)
	layers_changed.emit()
	return layer


## Moves layer [param id] to stack index [param new_index] (clamped). Returns false if not found.
func move_layer(id: int, new_index: int) -> bool:
	var index: int = layer_index(id)
	if index < 0:
		return false
	var layer: MapLayer = _layers[index]
	_layers.remove_at(index)
	_layers.insert(clampi(new_index, 0, _layers.size()), layer)
	layers_changed.emit()
	return true


## Renames layer [param id]. Returns false if not found.
func rename_layer(id: int, new_name: String) -> bool:
	var layer: MapLayer = get_layer(id)
	if layer == null:
		return false
	layer.name = new_name
	layers_changed.emit()
	return true


## Shows or hides layer [param id]. Returns false if not found.
func set_layer_visible(id: int, is_visible: bool) -> bool:
	var layer: MapLayer = get_layer(id)
	if layer == null:
		return false
	layer.visible = is_visible
	layers_changed.emit()
	return true


## Locks or unlocks layer [param id]. Returns false if not found.
func set_layer_locked(id: int, is_locked: bool) -> bool:
	var layer: MapLayer = get_layer(id)
	if layer == null:
		return false
	layer.locked = is_locked
	layers_changed.emit()
	return true


# --- Cells ----------------------------------------------------------------------------------

## Returns the cell at [param hex] on layer [param layer_id], or null.
func get_cell(layer_id: int, hex: Vector2i) -> MapCell:
	var layer: MapLayer = get_layer(layer_id)
	return layer.get_cell(hex) if layer != null else null


## Sets one cell (null clears it). Returns false if the layer is missing or the hex is
## outside the map.
func set_cell(layer_id: int, hex: Vector2i, cell: MapCell) -> bool:
	var cells: Dictionary[Vector2i, MapCell] = {hex: cell}
	return set_cells(layer_id, cells) == 1


## Sets several cells on one layer in one go (null values clear) and emits
## [signal cells_changed] once. Hexes outside the map are skipped. Returns how many were set.
func set_cells(layer_id: int, cells: Dictionary[Vector2i, MapCell]) -> int:
	var layer: MapLayer = get_layer(layer_id)
	if layer == null:
		return 0
	var changed: Array[Vector2i] = []
	for hex: Vector2i in cells:
		if grid.contains(hex):
			layer.set_cell(hex, cells[hex])
			changed.append(hex)
	if not changed.is_empty():
		cells_changed.emit(layer_id, changed)
	return changed.size()
