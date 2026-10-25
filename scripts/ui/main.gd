extends Node2D
## Main scene composition root: builds the map grid and shows it with the renderer.
## Camera zoom/pan and picking arrive in later Milestone 1 steps.

## Fraction of the viewport the map fills when fitted to view.
const FIT_MARGIN: float = 0.95

@export_range(1, 1000) var map_width: int = 100
@export_range(1, 1000) var map_height: int = 100
@export var orientation: HexLayout.HexOrientation = HexLayout.HexOrientation.POINTY_TOP
@export var hex_size: float = 32.0

@onready var _renderer: HexMapRenderer = $HexMapRenderer
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	var grid := HexGrid.new(map_width, map_height)
	var layout := HexLayout.new(orientation, Vector2(hex_size, hex_size))
	_renderer.set_map(grid, layout)
	fit_camera_to_map()


## Centres the camera on the map and zooms so the whole map is visible.
func fit_camera_to_map() -> void:
	var rect: Rect2 = _renderer.get_map_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var view: Vector2 = get_viewport_rect().size
	var zoom: float = minf(view.x / rect.size.x, view.y / rect.size.y) * FIT_MARGIN
	_camera.position = rect.get_center()
	_camera.zoom = Vector2(zoom, zoom)
