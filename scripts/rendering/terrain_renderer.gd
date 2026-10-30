class_name TerrainRenderer
extends Node2D
## Draws the terrain of a [MapData] in [member chunk_size] × [member chunk_size] offset-cell
## [TerrainChunk]s. Reads the map, never edits it. Cell edits redraw only the chunks they
## touch; layer changes (visibility, order, removal) redraw all chunks. Chunks outside the
## view given to [method set_view] are hidden, so Godot skips drawing them until they are
## shown again (it redraws a chunk whenever it becomes visible). When hexes are smaller than
## [member detail_min_hex_pixels] on screen, chunks switch to cheap one-pixel-per-hex drawing.

## Chunk edge length in offset cells.
@export_range(1, 128) var chunk_size: int = 16
## Below this on-screen hex radius (pixels), chunks draw flat colours instead of sprites.
@export var detail_min_hex_pixels: float = 4.0

var _map: MapData
var _registry: TerrainRegistry
var _chunks: Dictionary[Vector2i, TerrainChunk] = {}
var _view_rect: Rect2
var _has_view: bool = false
var _low_detail: bool = false


## Sets the map to draw and the registry that resolves its terrain IDs, then rebuilds all chunks.
func set_map(map: MapData, registry: TerrainRegistry) -> void:
	if _map != null:
		_map.cells_changed.disconnect(_on_cells_changed)
		_map.layer_content_changed.disconnect(_on_layer_content_changed)
		_map.layers_changed.disconnect(redraw_all)
	_map = map
	_registry = registry
	_rebuild_chunks()
	if _map != null:
		_map.cells_changed.connect(_on_cells_changed)
		_map.layer_content_changed.connect(_on_layer_content_changed)
		_map.layers_changed.connect(redraw_all)


## Shows only the chunks overlapping [param view_rect] (map space), and picks the detail
## level from [param zoom_level]. Until this is called, all chunks are shown in full detail.
func set_view(view_rect: Rect2, zoom_level: float) -> void:
	_view_rect = view_rect
	_has_view = true
	_low_detail = _map != null and _map.layout.hex_size.x * zoom_level < detail_min_hex_pixels
	for chunk: TerrainChunk in _chunks.values():
		_apply_view(chunk)


## Returns true if chunks are drawn in low-detail mode.
func is_low_detail() -> bool:
	return _low_detail


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


func _on_layer_content_changed(_layer_id: int) -> void:
	redraw_all()


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
			chunk.setup(_map, _registry, rect)
			add_child(chunk)
			_apply_view(chunk)
			_chunks[Vector2i(cx, cy)] = chunk


func _apply_view(chunk: TerrainChunk) -> void:
	chunk.visible = not _has_view or chunk.bounds.intersects(_view_rect)
	chunk.low_detail = _low_detail
