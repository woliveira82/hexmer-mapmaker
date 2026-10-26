extends Node2D
## Main scene composition root: owns the map data and terrain registry, builds the map,
## wires input to the editor controller and controller signals to the highlight and status bar.

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


func _ready() -> void:
	_registry = TerrainRegistry.create_starter()
	_map = _make_map()
	_controller = EditorController.new(_map.grid, _map.layout)
	_controller.hovered_changed.connect(_on_hovered_changed)
	_controller.selected_changed.connect(_on_selected_changed)
	_camera.view_changed.connect(_on_view_changed)
	_settings_panel.settings_applied.connect(rebuild_map)
	_settings_panel.set_settings(map_width, map_height, orientation, hex_size)
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
	_controller.set_map(_map.grid, _map.layout)
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


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_controller.update_hover(_mouse_map_position())
	elif event.is_action_pressed(MapCamera.ACTION_PRIMARY):
		_controller.select_at(_mouse_map_position())
		get_viewport().set_input_as_handled()


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


func _on_view_changed() -> void:
	_highlight.set_zoom(_camera.get_zoom_level())
	_status_bar.set_zoom(_camera.get_zoom_level())
	# The map moved under a stationary cursor, so the hovered hex may have changed.
	_controller.update_hover(_mouse_map_position())
