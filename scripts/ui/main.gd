extends Node2D
## Main scene composition root: builds the map, wires input to the editor controller
## and controller signals to the highlight and status bar.

@export_range(1, 1000) var map_width: int = 100
@export_range(1, 1000) var map_height: int = 100
@export var orientation: HexLayout.HexOrientation = HexLayout.HexOrientation.POINTY_TOP
@export var hex_size: float = 32.0

var _controller: EditorController

@onready var _renderer: HexMapRenderer = $HexMapRenderer
@onready var _highlight: HexHighlight = $HexHighlight
@onready var _camera: MapCamera = $MapCamera
@onready var _status_bar: StatusBar = $UI/StatusBar


func _ready() -> void:
	var grid := HexGrid.new(map_width, map_height)
	var layout := HexLayout.new(orientation, Vector2(hex_size, hex_size))
	_renderer.set_map(grid, layout)
	_highlight.layout = layout
	_controller = EditorController.new(grid, layout)
	_controller.hovered_changed.connect(_on_hovered_changed)
	_controller.selected_changed.connect(_on_selected_changed)
	_camera.view_changed.connect(_on_view_changed)
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
