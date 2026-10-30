extends GutTest

const EPSILON: float = 0.001

var _camera: MapCamera


func before_each() -> void:
	_camera = MapCamera.new()
	add_child_autofree(_camera)


func after_each() -> void:
	Input.action_release(MapCamera.ACTION_PAN_HOLD)


func _mouse_button(action_button: MouseButton, pressed: bool, position: Vector2 = Vector2.ZERO) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = action_button
	event.pressed = pressed
	event.position = position
	event.factor = 1.0
	return event


func _motion(relative: Vector2) -> InputEventMouseMotion:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	return event


func test_input_actions_are_defined() -> void:
	var actions: Array[StringName] = [
		MapCamera.ACTION_ZOOM_IN, MapCamera.ACTION_ZOOM_OUT, MapCamera.ACTION_PAN,
		MapCamera.ACTION_PAN_HOLD, MapCamera.ACTION_PRIMARY, MapCamera.ACTION_FIT,
	]
	for action: StringName in actions:
		assert_true(InputMap.has_action(action), "action %s exists" % action)
		assert_gt(InputMap.action_get_events(action).size(), 0, "action %s has a binding" % action)


func test_zoom_about_point_keeps_map_point_fixed() -> void:
	var pos := Vector2(120.0, -40.0)
	var offset := Vector2(300.0, -150.0)
	var before: Vector2 = pos + offset / 0.5
	var new_pos: Vector2 = MapCamera.zoom_about_point(pos, 0.5, 2.0, offset)
	var after: Vector2 = new_pos + offset / 2.0
	assert_lt(before.distance_to(after), EPSILON)


func test_zoom_by_clamps_to_limits() -> void:
	_camera.zoom_by(1000.0)
	assert_almost_eq(_camera.get_zoom_level(), _camera.max_zoom, EPSILON)
	_camera.zoom_by(0.000001)
	assert_almost_eq(_camera.get_zoom_level(), _camera.min_zoom, EPSILON)


func test_pan_moves_opposite_to_drag_scaled_by_zoom() -> void:
	_camera.zoom = Vector2(2.0, 2.0)
	_camera.position = Vector2(10.0, 10.0)
	_camera.pan_by_screen(Vector2(40.0, -20.0))
	assert_lt(_camera.position.distance_to(Vector2(-10.0, 20.0)), EPSILON)


func test_fit_rect_centres_and_fits() -> void:
	_camera.fit_margin = 1.0
	_camera.fit_rect(Rect2(100.0, 200.0, 4000.0, 1000.0), Vector2(1000.0, 1000.0))
	assert_lt(_camera.position.distance_to(Vector2(2100.0, 700.0)), EPSILON)
	assert_almost_eq(_camera.get_zoom_level(), 0.25, EPSILON, "limited by width")


func test_wheel_zooms_in_and_out() -> void:
	var start: float = _camera.get_zoom_level()
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_WHEEL_UP, true))
	assert_almost_eq(_camera.get_zoom_level(), start * _camera.zoom_step, EPSILON)
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_WHEEL_DOWN, true))
	assert_almost_eq(_camera.get_zoom_level(), start, EPSILON)


func test_middle_drag_pans() -> void:
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_MIDDLE, true))
	assert_true(_camera.is_dragging())
	_camera._unhandled_input(_motion(Vector2(30.0, 0.0)))
	assert_lt(_camera.position.distance_to(Vector2(-30.0, 0.0)), EPSILON)
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_MIDDLE, false))
	assert_false(_camera.is_dragging())


func test_left_drag_pans_only_with_space_held() -> void:
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_LEFT, true))
	assert_false(_camera.is_dragging(), "plain left click is for tools, not panning")
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_LEFT, false))
	Input.action_press(MapCamera.ACTION_PAN_HOLD)
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_LEFT, true))
	assert_true(_camera.is_dragging())
	_camera._unhandled_input(_mouse_button(MOUSE_BUTTON_LEFT, false))
	assert_false(_camera.is_dragging())


func test_motion_without_drag_does_not_pan() -> void:
	_camera._unhandled_input(_motion(Vector2(50.0, 50.0)))
	assert_eq(_camera.position, Vector2.ZERO)


func test_view_rect_is_viewport_in_map_space() -> void:
	_camera.position = Vector2(100.0, 50.0)
	_camera.zoom = Vector2(0.5, 0.5)
	var view_size: Vector2 = _camera.get_viewport_rect().size
	var rect: Rect2 = _camera.get_view_rect()
	assert_almost_eq(rect.get_center(), Vector2(100.0, 50.0), Vector2(EPSILON, EPSILON))
	assert_almost_eq(rect.size, view_size * 2.0, Vector2(EPSILON, EPSILON))
