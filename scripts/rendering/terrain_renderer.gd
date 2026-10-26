class_name TerrainRenderer
extends Node2D
## Draws the terrain of a [MapData] in [member chunk_size] × [member chunk_size] offset-cell
## [TerrainChunk]s. Reads the map, never edits it. Cell edits redraw only the chunks they
## touch; layer changes (visibility, order, removal) redraw all chunks.

## Chunk edge length in offset cells.
@export_range(1, 128) var chunk_size: int = 16

var _map: MapData
var _registry: TerrainRegistry
var _chunks: Dictionary[Vector2i, TerrainChunk] = {}


## Sets the map to draw and the registry that resolves its terrain IDs, then rebuilds all chunks.
func set_map(map: MapData, registry: TerrainRegistry) -> void:
	if _map != null:
		_map.cells_changed.disconnect(_on_cells_changed)
		_map.layers_changed.disconnect(redraw_all)
	_map = map
	_registry = registry
	_rebuild_chunks()
	if _map != null:
		_map.cells_changed.connect(_on_cells_changed)
		_map.layers_changed.connect(redraw_all)


## Returns the chunk nodes.
func get_chunks() -> Array[TerrainChunk]:
	var result: Array[TerrainChunk] = []
	result.assign(_chunks.values())
	return result


## Returns the chunk that draws [param hex], or null if the hex is outside the map.
func get_chunk_for(hex: Vector2i) -> TerrainChunk:
	return _chunks.get(_chunk_key(hex))


## Queues a redraw of every chunk.
func redraw_all() -> void:
	for chunk: TerrainChunk in _chunks.values():
		chunk.queue_redraw()


## Returns the distinct chunks that draw any of [param hexes].
func get_chunks_for(hexes: Array[Vector2i]) -> Array[TerrainChunk]:
	var touched: Dictionary[Vector2i, bool] = {}
	for hex: Vector2i in hexes:
		touched[_chunk_key(hex)] = true
	var result: Array[TerrainChunk] = []
	for key: Vector2i in touched:
		var chunk: TerrainChunk = _chunks.get(key)
		if chunk != null:
			result.append(chunk)
	return result


func _on_cells_changed(_layer_id: int, hexes: Array[Vector2i]) -> void:
	for chunk: TerrainChunk in get_chunks_for(hexes):
		chunk.queue_redraw()


func _chunk_key(hex: Vector2i) -> Vector2i:
	var offset: Vector2i = HexCoordinates.axial_to_even_r(hex)
	return Vector2i(floori(float(offset.x) / chunk_size), floori(float(offset.y) / chunk_size))


func _rebuild_chunks() -> void:
	for chunk: TerrainChunk in _chunks.values():
		remove_child(chunk)
		chunk.free()
	_chunks.clear()
	if _map == null:
		return
	var grid: HexGrid = _map.grid
	for cy: int in range(ceili(float(grid.height) / chunk_size)):
		for cx: int in range(ceili(float(grid.width) / chunk_size)):
			var rect := Rect2i(cx * chunk_size, cy * chunk_size, chunk_size, chunk_size)
			var chunk := TerrainChunk.new()
			chunk.name = "Chunk_%d_%d" % [cx, cy]
			chunk.setup(_map, _registry, grid.cells_in_offset_rect(rect))
			add_child(chunk)
			_chunks[Vector2i(cx, cy)] = chunk
