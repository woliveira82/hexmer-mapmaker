extends Node2D
## Main scene composition root: owns the map data and terrain registry, builds the map,
## wires input to the editor controller and controller signals to the highlight and status bar.

const ACTION_UNDO: StringName = &"edit_undo"
const ACTION_REDO: StringName = &"edit_redo"

@export_range(1, 1000) var map_width: int = 100
@export_range(1, 1000) var map_height: int = 100
@export var orientation: HexLayout.HexOrientation = HexLayout.HexOrientation.POINTY_TOP
@export var hex_size: float = 32.0
## Terrain that fills the base layer of new maps; empty leaves new maps blank.
@export var default_terrain: StringName = &"grassland"

var _registry: TerrainRegistry
var _map: MapData
var _controller: EditorController

@onready var _terrain_renderer: TerrainRenderer = $TerrainRenderer
@onready var _renderer: HexMapRenderer = $HexMapRenderer
@onready var _highlight: HexHighlight = $HexHighlight
@onready var _camera: MapCamera = $MapCamera
@onready var _status_bar: StatusBar = $UI/StatusBar
@onready var _settings_panel: MapSettingsPanel = $UI/MapSettingsPanel
@onready var _palette: TerrainPalette = $UI/TerrainPalette


func _ready() -> void:
	_registry = TerrainRegistry.create_starter()
	_map = _make_map()
	_controller = EditorController.new(_map, _registry)
	_controller.hovered_changed.connect(_on_hovered_changed)
	_controller.selected_changed.connect(_on_selected_changed)
	_camera.view_changed.connect(_on_view_changed)
	_settings_panel.settings_applied.connect(rebuild_map)
	_settings_panel.set_settings(map_width, map_height, orientation, hex_size)
	_connect_palette()
	_show_map()


## Replaces the map with a new grid of the given size, orientation and hex size, then fits the view.
func rebuild_map(
	p_width: int, p_height: int, p_orientation: HexLayout.HexOrientation, p_hex_size: float
) -> void:
	map_width = p_width
	map_height = p_height
	orientation = p_orientation
	hex_size = p_hex_size
	_map = _make_map()
	_controller.set_map(_map)
	_show_map()


func _make_map() -> MapData:
	var layout := HexLayout.new(orientation, Vector2(hex_size, hex_size))
	var map := MapData.create_default(HexGrid.new(map_width, map_height), layout)
	if not default_terrain.is_empty():
		map.fill_layer(map.get_layers()[0].id, MapCell.new(default_terrain))
	return map


func _show_map() -> void:
	var grid: HexGrid = _map.grid
	var layout: HexLayout = _map.layout
	_terrain_renderer.set_map(_map, _registry)
	_renderer.set_map(grid, layout)
	_highlight.layout = layout
	_highlight.queue_redraw()
	_status_bar.set_map_info(grid.width, grid.height, layout.orientation)
	_camera.map_rect = _renderer.get_map_rect()
	_camera.fit_to_map()


func _connect_palette() -> void:
	_palette.set_terrains(_registry)
	_palette.set_tool(_controller.active_tool)
	_palette.set_terrain(_controller.active_terrain)
	_palette.tool_selected.connect(func(tool: EditorController.Tool) -> void: _controller.active_tool = tool)
	_palette.terrain_selected.connect(_on_terrain_selected)
	_palette.undo_requested.connect(_controller.undo)
	_palette.redo_requested.connect(_controller.redo)
	_controller.tool_changed.connect(_palette.set_tool)
	_controller.active_terrain_changed.connect(_palette.set_terrain)
	_controller.undo_stack.changed.connect(_on_undo_stack_changed)


func _input(event: InputEvent) -> void:
	# Ends strokes even when the button is released over a panel, which would swallow the event.
	if event.is_action_released(MapCamera.ACTION_PRIMARY):
		_controller.primary_released()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var map_position: Vector2 = _mouse_map_position()
		_controller.update_hover(map_position)
		_controller.primary_dragged(map_position)
		return
	if event.is_action_pressed(MapCamera.ACTION_PRIMARY):
		# Clicking the map takes keyboard focus away from panel fields so shortcuts work.
		get_viewport().gui_release_focus()
		_controller.primary_pressed(_mouse_map_position())
	elif event.is_action_pressed(ACTION_REDO, false, true):
		_controller.redo()
	elif event.is_action_pressed(ACTION_UNDO, false, true):
		_controller.undo()
	else:
		var tool: int = _tool_for_event(event)
		if tool < 0:
			return
		_controller.active_tool = tool as EditorController.Tool
	get_viewport().set_input_as_handled()


## Returns the tool whose shortcut [param event] presses, or -1.
func _tool_for_event(event: InputEvent) -> int:
	for tool: EditorController.Tool in TerrainPalette.TOOL_ACTIONS:
		if event.is_action_pressed(TerrainPalette.TOOL_ACTIONS[tool], false, true):
			return tool
	return -1


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT and _controller != null:
		_controller.clear_hover()


func _mouse_map_position() -> Vector2:
	return _renderer.get_local_mouse_position()


func _on_hovered_changed(hex: Vector2i, inside: bool) -> void:
	_highlight.set_hover(hex, inside)
	_status_bar.set_hover(hex, inside)


func _on_selected_changed(hex: Vector2i, has_selection: bool) -> void:
	_highlight.set_selected(hex, has_selection)
	_status_bar.set_selected(hex, has_selection)


func _on_terrain_selected(terrain_id: StringName) -> void:
	_controller.active_terrain = terrain_id
	_controller.active_tool = EditorController.Tool.PAINT


func _on_undo_stack_changed() -> void:
	var stack: UndoStack = _controller.undo_stack
	_palette.set_undo_state(stack.can_undo(), stack.can_redo(), stack.undo_description(), stack.redo_description())


func _on_view_changed() -> void:
	var view_rect: Rect2 = _camera.get_view_rect()
	_terrain_renderer.set_view(view_rect, _camera.get_zoom_level())
	_renderer.set_view(view_rect, _camera.get_zoom_level())
	_highlight.set_zoom(_camera.get_zoom_level())
	_status_bar.set_zoom(_camera.get_zoom_level())
	# The map moved under a stationary cursor, so the hovered hex may have changed.
	_controller.update_hover(_mouse_map_position())
