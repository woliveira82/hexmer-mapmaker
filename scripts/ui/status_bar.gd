class_name StatusBar
extends PanelContainer
## Bottom status bar: hovered and selected hex, map dimensions/orientation and zoom.

const NO_HEX_TEXT: String = "—"

@onready var _hover_label: Label = %HoverLabel
@onready var _selected_label: Label = %SelectedLabel
@onready var _map_label: Label = %MapLabel
@onready var _zoom_label: Label = %ZoomLabel


## Formats a hex as axial coordinates plus its even-r offset.
static func format_hex(hex: Vector2i) -> String:
	var offset: Vector2i = HexCoordinates.axial_to_even_r(hex)
	return "(%d, %d)  [col %d, row %d]" % [hex.x, hex.y, offset.x, offset.y]


## Formats an orientation as e.g. "pointy-top".
static func format_orientation(orientation: HexLayout.HexOrientation) -> String:
	return String(HexLayout.HexOrientation.keys()[orientation]).to_lower().replace("_", "-")


## Formats a zoom level as a whole percentage, e.g. 0.25 → "25%".
static func format_zoom(zoom_level: float) -> String:
	return "%d%%" % roundi(zoom_level * 100.0)


## Shows the hovered hex, or a dash when the cursor is off the map.
func set_hover(hex: Vector2i, inside: bool) -> void:
	_hover_label.text = "Hex: %s" % (format_hex(hex) if inside else NO_HEX_TEXT)


## Shows the selected hex, or a dash when nothing is selected.
func set_selected(hex: Vector2i, has_selection: bool) -> void:
	_selected_label.text = "Selected: %s" % (format_hex(hex) if has_selection else NO_HEX_TEXT)


## Shows the map dimensions and orientation.
func set_map_info(width: int, height: int, orientation: HexLayout.HexOrientation) -> void:
	_map_label.text = "Map: %d × %d %s" % [width, height, format_orientation(orientation)]


## Shows the zoom percentage.
func set_zoom(zoom_level: float) -> void:
	_zoom_label.text = "Zoom: %s" % format_zoom(zoom_level)


## Returns the text currently shown in each field, in display order.
func get_texts() -> PackedStringArray:
	return PackedStringArray([_hover_label.text, _selected_label.text, _map_label.text, _zoom_label.text])
