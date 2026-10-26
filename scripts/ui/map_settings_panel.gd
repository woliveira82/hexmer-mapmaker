class_name MapSettingsPanel
extends PanelContainer
## Map settings inspector: width, height, orientation and hex size.
## Emits [signal settings_applied] when the user presses Apply; it never touches the map itself.

## Emitted with the chosen settings when Apply is pressed.
signal settings_applied(width: int, height: int, orientation: HexLayout.HexOrientation, hex_size: float)

const MIN_DIMENSION: int = 1
const MAX_DIMENSION: int = 1000
const MIN_HEX_SIZE: float = 4.0
const MAX_HEX_SIZE: float = 256.0

@onready var _width_spin: SpinBox = %WidthSpin
@onready var _height_spin: SpinBox = %HeightSpin
@onready var _orientation_option: OptionButton = %OrientationOption
@onready var _hex_size_spin: SpinBox = %HexSizeSpin
@onready var _apply_button: Button = %ApplyButton


func _ready() -> void:
	_setup_spin(_width_spin, MIN_DIMENSION, MAX_DIMENSION)
	_setup_spin(_height_spin, MIN_DIMENSION, MAX_DIMENSION)
	_setup_spin(_hex_size_spin, MIN_HEX_SIZE, MAX_HEX_SIZE)
	_orientation_option.clear()
	for orientation: int in HexLayout.HexOrientation.values():
		_orientation_option.add_item(StatusBar.format_orientation(orientation), orientation)
	_apply_button.pressed.connect(apply)


## Shows [param width], [param height], [param orientation] and [param hex_size] in the fields.
func set_settings(width: int, height: int, orientation: HexLayout.HexOrientation, hex_size: float) -> void:
	_width_spin.value = width
	_height_spin.value = height
	_orientation_option.select(_orientation_option.get_item_index(orientation))
	_hex_size_spin.value = hex_size


## Commits any half-typed field values and emits [signal settings_applied].
func apply() -> void:
	for spin: SpinBox in [_width_spin, _height_spin, _hex_size_spin]:
		# Only a field being typed in has newer text than value; otherwise the text may lag behind.
		if spin.get_line_edit().has_focus():
			spin.apply()
	settings_applied.emit(
		int(_width_spin.value),
		int(_height_spin.value),
		_orientation_option.get_selected_id() as HexLayout.HexOrientation,
		_hex_size_spin.value,
	)


func _setup_spin(spin: SpinBox, min_value: float, max_value: float) -> void:
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = 1.0
