class_name HexGridChunk
extends Node2D
## One batch of hex outlines, drawn with a single draw_multiline call. Segments are built
## on the first draw, so chunks that are never shown (see [method HexMapRenderer.set_view])
## cost almost nothing.

## Six edges, two points each.
const SEGMENT_POINTS_PER_HEX: int = 12

## Map-space bounding box of everything this chunk draws.
var bounds: Rect2

var _hexes: Array[Vector2i] = []
var _layout: HexLayout
var _segments := PackedVector2Array()
var _color: Color
var _width: float


## Sets the hexes to outline with [param layout]. Geometry is built lazily when drawn.
func setup(hexes: Array[Vector2i], layout: HexLayout, color: Color, width: float) -> void:
	_hexes = hexes
	_layout = layout
	_color = color
	_width = width
	_segments.clear()
	bounds = layout.hexes_bounds(hexes)
	queue_redraw()


## Returns the number of hexes outlined by this chunk.
func hex_count() -> int:
	return _hexes.size()


## Returns true once the outline geometry has been built.
func is_built() -> bool:
	return not _segments.is_empty() or _hexes.is_empty()


func _draw() -> void:
	if _segments.is_empty():
		_build_segments()
	if not _segments.is_empty():
		draw_multiline(_segments, _color, _width)


func _build_segments() -> void:
	var offsets := PackedVector2Array()
	for i: int in range(6):
		offsets.append(_layout.corner_offset(i))
	_segments.resize(_hexes.size() * SEGMENT_POINTS_PER_HEX)
	var index: int = 0
	for hex: Vector2i in _hexes:
		var center: Vector2 = _layout.hex_to_pixel(hex)
		for i: int in range(6):
			_segments[index] = center + offsets[i]
			_segments[index + 1] = center + offsets[(i + 1) % 6]
			index += 2
