class_name EditorController
extends RefCounted
## Editor state shared by tools and UI: the map being edited plus the hovered and
## selected hex. Works in map-space positions; converting from screen space is the view's job.

## Emitted when the hovered hex changes. [param inside] is false when off the map.
signal hovered_changed(hex: Vector2i, inside: bool)
## Emitted when the selection changes. [param has_selection] is false when cleared.
signal selected_changed(hex: Vector2i, has_selection: bool)

var grid: HexGrid
var layout: HexLayout
var hovered_hex: Vector2i
var is_hovering: bool = false
var selected_hex: Vector2i
var has_selection: bool = false


func _init(p_grid: HexGrid, p_layout: HexLayout) -> void:
	grid = p_grid
	layout = p_layout


## Switches to a new map. Clears hover and selection, since old hexes may no longer exist.
func set_map(p_grid: HexGrid, p_layout: HexLayout) -> void:
	clear_hover()
	clear_selection()
	grid = p_grid
	layout = p_layout


## Updates the hovered hex from a map-space position.
func update_hover(map_position: Vector2) -> void:
	var hex: Vector2i = layout.pixel_to_hex(map_position)
	var inside: bool = grid.contains(hex)
	if inside == is_hovering and (not inside or hex == hovered_hex):
		return
	hovered_hex = hex
	is_hovering = inside
	hovered_changed.emit(hex, inside)


## Clears the hover state, e.g. when the mouse leaves the window.
func clear_hover() -> void:
	if not is_hovering:
		return
	is_hovering = false
	hovered_changed.emit(hovered_hex, false)


## Selects the hex at a map-space position, or clears the selection if it is off the map.
func select_at(map_position: Vector2) -> void:
	var hex: Vector2i = layout.pixel_to_hex(map_position)
	if grid.contains(hex):
		select(hex)
	else:
		clear_selection()


## Selects [param hex]. Hexes outside the map are ignored.
func select(hex: Vector2i) -> void:
	if not grid.contains(hex) or (has_selection and hex == selected_hex):
		return
	selected_hex = hex
	has_selection = true
	selected_changed.emit(hex, true)


## Clears the selection.
func clear_selection() -> void:
	if not has_selection:
		return
	has_selection = false
	selected_changed.emit(selected_hex, false)
