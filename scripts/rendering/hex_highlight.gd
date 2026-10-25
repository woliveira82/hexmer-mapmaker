class_name HexHighlight
extends Node2D
## Draws the hover and selection outlines on top of the grid.
## Line width is given in screen pixels and stays constant across zoom levels.

@export var hover_color: Color = Color(1.0, 1.0, 1.0, 0.7)
@export var selected_color: Color = Color(1.0, 0.75, 0.2)
## Outline width in screen pixels.
@export var line_width_px: float = 2.0

## Layout used to place the outlines. Set before showing anything.
var layout: HexLayout

var _hover_hex: Vector2i
var _show_hover: bool = false
var _selected_hex: Vector2i
var _show_selected: bool = false
var _zoom: float = 1.0


## Shows or hides the hover outline on [param hex].
func set_hover(hex: Vector2i, visible_on_map: bool) -> void:
	_hover_hex = hex
	_show_hover = visible_on_map
	queue_redraw()


## Shows or hides the selection outline on [param hex].
func set_selected(hex: Vector2i, visible_on_map: bool) -> void:
	_selected_hex = hex
	_show_selected = visible_on_map
	queue_redraw()


## Tells the highlight the camera zoom so line width stays constant on screen.
func set_zoom(zoom_level: float) -> void:
	_zoom = maxf(zoom_level, 0.0001)
	queue_redraw()


func _draw() -> void:
	if layout == null:
		return
	var width: float = line_width_px / _zoom
	if _show_hover and not (_show_selected and _hover_hex == _selected_hex):
		_draw_outline(_hover_hex, hover_color, width)
	if _show_selected:
		_draw_outline(_selected_hex, selected_color, width)


func _draw_outline(hex: Vector2i, color: Color, width: float) -> void:
	var points: PackedVector2Array = layout.polygon_corners(hex)
	points.append(points[0])
	draw_polyline(points, color, width, true)
