class_name HexGridChunk
extends Node2D
## One batch of hex outlines. Line segments are built once in [method setup] and
## drawn with a single draw_multiline call; off-screen chunks are culled by Godot.

## Six edges, two points each.
const SEGMENT_POINTS_PER_HEX: int = 12

## Map-space bounding box of everything this chunk draws.
var bounds: Rect2

var _segments := PackedVector2Array()
var _color: Color
var _width: float


## Builds the outline segments for [param hexes] using [param layout].
func setup(hexes: Array[Vector2i], layout: HexLayout, color: Color, width: float) -> void:
	_color = color
	_width = width
	_segments.clear()
	for hex: Vector2i in hexes:
		var corners: PackedVector2Array = layout.polygon_corners(hex)
		for i: int in range(corners.size()):
			_segments.append(corners[i])
			_segments.append(corners[(i + 1) % corners.size()])
	bounds = Rect2()
	if not _segments.is_empty():
		bounds = Rect2(_segments[0], Vector2.ZERO)
		for point: Vector2 in _segments:
			bounds = bounds.expand(point)
	queue_redraw()


## Returns the number of hexes outlined by this chunk.
@warning_ignore("integer_division")
func hex_count() -> int:
	return _segments.size() / SEGMENT_POINTS_PER_HEX


func _draw() -> void:
	if not _segments.is_empty():
		draw_multiline(_segments, _color, _width)
