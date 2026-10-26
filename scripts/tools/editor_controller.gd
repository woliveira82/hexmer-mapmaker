class_name EditorController
extends RefCounted
## Editor state shared by tools and UI: the map being edited, hover and selection, the active
## tool, layer and terrain, and the undo history. Works in map-space positions; converting
## from screen space is the view's job.

enum Tool { SELECT, PAINT, ERASE }

## Emitted when the hovered hex changes. [param inside] is false when off the map.
signal hovered_changed(hex: Vector2i, inside: bool)
## Emitted when the selection changes. [param has_selection] is false when cleared.
signal selected_changed(hex: Vector2i, has_selection: bool)
## Emitted when the active tool changes.
signal tool_changed(tool: Tool)
## Emitted when the terrain used by the paint tool changes.
signal active_terrain_changed(terrain_id: StringName)

var map: MapData
var registry: TerrainRegistry
## Undo history for edits to [member map]; cleared when the map is replaced.
var undo_stack := UndoStack.new()
## Picks sprite variants when painting.
var rng := RandomNumberGenerator.new()

var grid: HexGrid:
	get:
		return map.grid
var layout: HexLayout:
	get:
		return map.layout

var hovered_hex: Vector2i
var is_hovering: bool = false
var selected_hex: Vector2i
var has_selection: bool = false

var active_tool: Tool = Tool.SELECT:
	set(value):
		if value == active_tool:
			return
		end_stroke()
		active_tool = value
		tool_changed.emit(value)
var active_terrain: StringName:
	set(value):
		if value == active_terrain:
			return
		active_terrain = value
		active_terrain_changed.emit(value)
## Layer that paint and erase act on. Defaults to the bottom layer.
var active_layer_id: int = -1

var _stroke: SetCellsCommand
var _stroke_hexes: Dictionary[Vector2i, bool] = {}
var _last_stroke_hex: Vector2i


func _init(p_map: MapData, p_registry: TerrainRegistry) -> void:
	map = p_map
	registry = p_registry
	rng.randomize()
	_reset_active_layer()
	var ids: Array[StringName] = registry.ids()
	if not ids.is_empty():
		active_terrain = ids[0]


## Switches to a new map. Ends any stroke, clears hover, selection and undo history,
## and makes the bottom layer active.
func set_map(p_map: MapData) -> void:
	end_stroke()
	clear_hover()
	clear_selection()
	map = p_map
	undo_stack.clear()
	_reset_active_layer()


# --- Hover and selection --------------------------------------------------------------------

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


# --- Primary button (tools) -----------------------------------------------------------------

## Handles a primary-button press at a map-space position with the active tool.
func primary_pressed(map_position: Vector2) -> void:
	var hex: Vector2i = layout.pixel_to_hex(map_position)
	match active_tool:
		Tool.SELECT:
			select_at(map_position)
		Tool.PAINT, Tool.ERASE:
			end_stroke()
			_stroke = SetCellsCommand.new(map, active_layer_id, _stroke_name())
			_last_stroke_hex = hex
			_stroke_hex(hex)


## Continues a stroke to a map-space position. Fills in every hex between the previous
## and current positions so fast drags leave no gaps.
func primary_dragged(map_position: Vector2) -> void:
	if _stroke == null:
		return
	var hex: Vector2i = layout.pixel_to_hex(map_position)
	if hex == _last_stroke_hex:
		return
	var path: Array[Vector2i] = HexCoordinates.line(_last_stroke_hex, hex)
	for i: int in range(1, path.size()):
		_stroke_hex(path[i])
	_last_stroke_hex = hex


## Ends the current stroke and records it as one undo step.
func primary_released() -> void:
	end_stroke()


## Returns true while a paint or erase stroke is in progress.
func is_stroking() -> bool:
	return _stroke != null


## Finishes any stroke in progress, recording it if it changed anything.
func end_stroke() -> void:
	if _stroke == null:
		return
	undo_stack.push_done(_stroke)
	_stroke = null
	_stroke_hexes.clear()


# --- Undo -----------------------------------------------------------------------------------

## Undoes the latest edit (finishing any stroke first). Returns false if nothing to undo.
func undo() -> bool:
	end_stroke()
	return undo_stack.undo()


## Redoes the latest undone edit (finishing any stroke first). Returns false if nothing to redo.
func redo() -> bool:
	end_stroke()
	return undo_stack.redo()


# --- Internals ------------------------------------------------------------------------------

func _stroke_hex(hex: Vector2i) -> void:
	if _stroke_hexes.has(hex):
		return
	_stroke_hexes[hex] = true
	var hexes: Array[Vector2i] = [hex]
	var segment: SetCellsCommand
	if active_tool == Tool.ERASE:
		segment = SetCellsCommand.erase(map, active_layer_id, hexes)
	else:
		var current: MapCell = map.get_cell(active_layer_id, hex)
		if active_terrain.is_empty() or (current != null and current.terrain_id == active_terrain):
			return  # Same terrain: keep its existing variant.
		segment = SetCellsCommand.paint(map, active_layer_id, hexes, MapCell.new(active_terrain, _pick_variant()))
	if segment.is_empty():
		return
	segment.do()
	_stroke.merge(segment)


func _pick_variant() -> int:
	var definition: TerrainDefinition = registry.get_definition(active_terrain)
	var count: int = definition.variants.size() if definition != null else 0
	return rng.randi_range(0, count - 1) if count > 1 else 0


func _stroke_name() -> String:
	return "Erase" if active_tool == Tool.ERASE else "Paint"


func _reset_active_layer() -> void:
	var layers: Array[MapLayer] = map.get_layers()
	active_layer_id = layers[0].id if not layers.is_empty() else -1
