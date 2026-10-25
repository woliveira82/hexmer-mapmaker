extends Node2D
## Main scene composition root: builds the map grid and shows it with the renderer.
## Picking and the status bar arrive in the next Milestone 1 step.

@export_range(1, 1000) var map_width: int = 100
@export_range(1, 1000) var map_height: int = 100
@export var orientation: HexLayout.HexOrientation = HexLayout.HexOrientation.POINTY_TOP
@export var hex_size: float = 32.0

@onready var _renderer: HexMapRenderer = $HexMapRenderer
@onready var _camera: MapCamera = $MapCamera


func _ready() -> void:
	var grid := HexGrid.new(map_width, map_height)
	var layout := HexLayout.new(orientation, Vector2(hex_size, hex_size))
	_renderer.set_map(grid, layout)
	_camera.map_rect = _renderer.get_map_rect()
	_camera.fit_to_map()
