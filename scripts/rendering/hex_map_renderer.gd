class_name HexMapRenderer
extends Node2D
## Draws the hex grid overlay for a map. Reads a [HexGrid] and [HexLayout]; never owns map data.
## The map is split into [member chunk_size] × [member chunk_size] offset-cell chunks,
## one [HexGridChunk] each, so there is never one Node per hex.

## Chunk edge length in offset cells.
@export_range(1, 128) var chunk_size: int = 16
@export var line_color: Color = Color(0.42, 0.46, 0.52)
## Line width in pixels; negative draws thin lines that stay 1 px at any zoom.
@export var line_width: float = -1.0

var _grid: HexGrid
var _layout: HexLayout
var _map_rect: Rect2


## Sets the grid and layout to draw and rebuilds all chunks.
func set_map(grid: HexGrid, layout: HexLayout) -> void:
	_grid = grid
	_layout = layout
	_rebuild_chunks()


## Returns the map-space bounding box of the whole grid.
func get_map_rect() -> Rect2:
	return _map_rect


## Returns the current chunk nodes.
func get_chunks() -> Array[HexGridChunk]:
	var result: Array[HexGridChunk] = []
	for child: Node in get_children():
		if child is HexGridChunk:
			result.append(child)
	return result


func _rebuild_chunks() -> void:
	for chunk: HexGridChunk in get_chunks():
		remove_child(chunk)
		chunk.free()
	_map_rect = Rect2()
	if _grid == null or _layout == null:
		return
	var chunks_x: int = ceili(float(_grid.width) / chunk_size)
	var chunks_y: int = ceili(float(_grid.height) / chunk_size)
	var first: bool = true
	for cy: int in range(chunks_y):
		for cx: int in range(chunks_x):
			var rect := Rect2i(cx * chunk_size, cy * chunk_size, chunk_size, chunk_size)
			var chunk := HexGridChunk.new()
			chunk.name = "Chunk_%d_%d" % [cx, cy]
			chunk.setup(_grid.cells_in_offset_rect(rect), _layout, line_color, line_width)
			add_child(chunk)
			_map_rect = chunk.bounds if first else _map_rect.merge(chunk.bounds)
			first = false
