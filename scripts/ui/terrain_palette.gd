class_name TerrainPalette
extends PanelContainer
## Left tool panel: tool buttons, undo/redo and the terrain list.
## Emits requests; the main scene applies them to the [EditorController].

## Emitted when the user picks a tool.
signal tool_selected(tool: EditorController.Tool)
## Emitted when the user picks a terrain.
signal terrain_selected(terrain_id: StringName)
## Emitted when the Undo button is pressed.
signal undo_requested
## Emitted when the Redo button is pressed.
signal redo_requested

const ICON_SIZE: Vector2i = Vector2i(32, 32)
const ACTION_UNDO: StringName = &"edit_undo"
const ACTION_REDO: StringName = &"edit_redo"
const TOOL_ACTIONS: Dictionary[EditorController.Tool, StringName] = {
	EditorController.Tool.SELECT: &"tool_select",
	EditorController.Tool.PAINT: &"tool_paint",
	EditorController.Tool.ERASE: &"tool_erase",
}

var _tool_buttons: Dictionary[EditorController.Tool, Button] = {}

@onready var _undo_button: Button = %UndoButton
@onready var _redo_button: Button = %RedoButton
@onready var _terrain_list: ItemList = %TerrainList


## Returns the first key binding of [param action] as text, e.g. "Ctrl+Z", or "" if none.
static func shortcut_text(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	return events[0].as_text() if not events.is_empty() else ""


func _ready() -> void:
	_tool_buttons = {
		EditorController.Tool.SELECT: %SelectButton,
		EditorController.Tool.PAINT: %PaintButton,
		EditorController.Tool.ERASE: %EraseButton,
	}
	var group := ButtonGroup.new()
	for tool: EditorController.Tool in _tool_buttons:
		var button: Button = _tool_buttons[tool]
		button.toggle_mode = true
		button.button_group = group
		button.tooltip_text = _with_shortcut(button.text, TOOL_ACTIONS[tool])
		button.pressed.connect(tool_selected.emit.bind(tool))
	_undo_button.pressed.connect(undo_requested.emit)
	_redo_button.pressed.connect(redo_requested.emit)
	_terrain_list.fixed_icon_size = ICON_SIZE
	_terrain_list.item_selected.connect(_on_terrain_item_selected)
	set_undo_state(false, false, "", "")


## Fills the terrain list from [param registry], in registry order.
func set_terrains(registry: TerrainRegistry) -> void:
	_terrain_list.clear()
	for id: StringName in registry.ids():
		var definition: TerrainDefinition = registry.get_definition(id)
		var index: int = _terrain_list.add_item(definition.display_name, _make_icon(definition))
		_terrain_list.set_item_metadata(index, id)
		_terrain_list.set_item_tooltip(index, "%s (%s)" % [definition.display_name, definition.category])


## Shows [param tool] as the active tool without emitting [signal tool_selected].
func set_tool(tool: EditorController.Tool) -> void:
	# set_pressed_no_signal() doesn't release the other buttons in the group, so set them all.
	for other: EditorController.Tool in _tool_buttons:
		_tool_buttons[other].set_pressed_no_signal(other == tool)


## Highlights [param terrain_id] in the list without emitting [signal terrain_selected].
func set_terrain(terrain_id: StringName) -> void:
	for index: int in _terrain_list.item_count:
		if _terrain_list.get_item_metadata(index) == terrain_id:
			_terrain_list.select(index)
			return
	_terrain_list.deselect_all()


## Enables the undo/redo buttons and names the edit each would apply.
func set_undo_state(can_undo: bool, can_redo: bool, undo_name: String, redo_name: String) -> void:
	_undo_button.disabled = not can_undo
	_redo_button.disabled = not can_redo
	_undo_button.tooltip_text = _with_shortcut("Undo " + undo_name if can_undo else "Nothing to undo", ACTION_UNDO)
	_redo_button.tooltip_text = _with_shortcut("Redo " + redo_name if can_redo else "Nothing to redo", ACTION_REDO)


## Returns the terrain IDs in list order.
func get_terrain_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for index: int in _terrain_list.item_count:
		result.append(_terrain_list.get_item_metadata(index))
	return result


## Returns the active tool shown by the buttons.
func get_shown_tool() -> EditorController.Tool:
	for tool: EditorController.Tool in _tool_buttons:
		if _tool_buttons[tool].button_pressed:
			return tool
	return EditorController.Tool.SELECT


## Returns the button for [param tool] (for tests and tooltips).
func get_tool_button(tool: EditorController.Tool) -> Button:
	return _tool_buttons[tool]


## Returns whether the Undo and Redo buttons are enabled, in that order.
func get_undo_buttons_enabled() -> Array[bool]:
	return [not _undo_button.disabled, not _redo_button.disabled]


func _on_terrain_item_selected(index: int) -> void:
	terrain_selected.emit(_terrain_list.get_item_metadata(index))


func _with_shortcut(text: String, action: StringName) -> String:
	var shortcut: String = shortcut_text(action)
	return "%s (%s)" % [text, shortcut] if not shortcut.is_empty() else text


func _make_icon(definition: TerrainDefinition) -> Texture2D:
	var texture: Texture2D = definition.get_variant_texture(0)
	if texture != null:
		return texture
	var image := Image.create_empty(ICON_SIZE.x, ICON_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(definition.color)
	return ImageTexture.create_from_image(image)
