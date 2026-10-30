class_name MapCamera
extends Camera2D
## Editor camera: wheel zoom toward the cursor, drag to pan, fit to the map.
## All bindings come from InputMap actions defined in project.godot.

## Emitted whenever the zoom or position changes.
signal view_changed

const ACTION_ZOOM_IN: StringName = &"camera_zoom_in"
const ACTION_ZOOM_OUT: StringName = &"camera_zoom_out"
const ACTION_PAN: StringName = &"camera_pan"
const ACTION_PAN_HOLD: StringName = &"camera_pan_hold"
const ACTION_PRIMARY: StringName = &"editor_primary"
const ACTION_FIT: StringName = &"camera_fit"

@export var min_zoom: float = 0.01
@export var max_zoom: float = 8.0
## Zoom multiplier per wheel notch.
@export var zoom_step: float = 1.15
## Fraction of the viewport the map fills after [method fit_to_map].
@export var fit_margin: float = 0.95

## Map-space rectangle used by [method fit_to_map].
var map_rect: Rect2

var _dragging: bool = false


## Returns the current uniform zoom level (1.0 = 100 %).
func get_zoom_level() -> float:
	return zoom.x


## Returns the map-space rectangle visible in the viewport. Assumes the camera's parent
## is at the map origin, as in the main scene.
func get_view_rect() -> Rect2:
	var size: Vector2 = get_viewport_rect().size / zoom.x
	return Rect2(position - size / 2.0, size)


## Returns true while a pan drag is in progress.
func is_dragging() -> bool:
	return _dragging


## Returns the camera position that keeps the map point under [param screen_offset]
## (pixels from the viewport centre) fixed when zoom goes from [param old_zoom] to [param new_zoom].
static func zoom_about_point(
		camera_position: Vector2, old_zoom: float, new_zoom: float, screen_offset: Vector2) -> Vector2:
	return camera_position + screen_offset / old_zoom - screen_offset / new_zoom


## Multiplies the zoom by [param factor] (clamped to the limits), keeping the map point
## under [param screen_offset] fixed.
func zoom_by(factor: float, screen_offset: Vector2 = Vector2.ZERO) -> void:
	var old_zoom: float = zoom.x
	var new_zoom: float = clampf(old_zoom * factor, min_zoom, max_zoom)
	if is_equal_approx(new_zoom, old_zoom):
		return
	position = zoom_about_point(position, old_zoom, new_zoom, screen_offset)
	zoom = Vector2(new_zoom, new_zoom)
	view_changed.emit()


## Moves the camera so the map follows a screen-space drag of [param screen_delta] pixels.
func pan_by_screen(screen_delta: Vector2) -> void:
	position -= screen_delta / zoom.x
	view_changed.emit()


## Centres on [param rect] and zooms so it fits in [param view_size], within the zoom limits.
func fit_rect(rect: Rect2, view_size: Vector2) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var fit: float = minf(view_size.x / rect.size.x, view_size.y / rect.size.y) * fit_margin
	fit = clampf(fit, min_zoom, max_zoom)
	position = rect.get_center()
	zoom = Vector2(fit, fit)
	view_changed.emit()


## Fits [member map_rect] into the current viewport.
func fit_to_map() -> void:
	fit_rect(map_rect, get_viewport_rect().size)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(ACTION_ZOOM_IN):
		zoom_by(pow(zoom_step, _wheel_factor(event)), _offset_from_center(event))
	elif event.is_action_pressed(ACTION_ZOOM_OUT):
		zoom_by(1.0 / pow(zoom_step, _wheel_factor(event)), _offset_from_center(event))
	elif event.is_action_pressed(ACTION_PAN) or (
			event.is_action_pressed(ACTION_PRIMARY) and Input.is_action_pressed(ACTION_PAN_HOLD)):
		_dragging = true
	elif _dragging and (event.is_action_released(ACTION_PAN) or event.is_action_released(ACTION_PRIMARY)):
		_dragging = false
	elif _dragging and event is InputEventMouseMotion:
		pan_by_screen((event as InputEventMouseMotion).relative)
	elif event.is_action_pressed(ACTION_FIT):
		fit_to_map()
	else:
		return
	get_viewport().set_input_as_handled()


func _offset_from_center(event: InputEvent) -> Vector2:
	if event is InputEventMouse:
		return (event as InputEventMouse).position - get_viewport_rect().size / 2.0
	return Vector2.ZERO


## High-precision wheels report fractional notches; others report 0 or 1.
func _wheel_factor(event: InputEvent) -> float:
	if event is InputEventMouseButton and (event as InputEventMouseButton).factor > 0.0:
		return (event as InputEventMouseButton).factor
	return 1.0
