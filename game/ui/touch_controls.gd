class_name TouchControls
extends Control
## Controles por toque para Web em celulares e tablets.

signal move_changed(value: Vector2)
signal look_changed(delta: Vector2)
signal interact_pressed
signal flashlight_pressed
signal sprint_changed(pressed: bool)
signal crouch_changed(pressed: bool)
signal pause_pressed
signal touch_detected

var is_touch_device := false
var gameplay_enabled := true:
	set(value):
		gameplay_enabled = value
		if not value:
			_reset_touch_state()

var _move_finger := -1
var _look_finger := -1
var _button_fingers: Dictionary = {}
var _pressed_buttons: Dictionary = {}

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_touch_device = DisplayServer.is_touchscreen_available() \
			or OS.has_feature("web_android") or OS.has_feature("web_ios")
	visible = is_touch_device
	get_viewport().size_changed.connect(queue_redraw)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if not gameplay_enabled:
		return
	if event is InputEventScreenTouch:
		if not is_touch_device:
			is_touch_device = true
			visible = true
			touch_detected.emit()
		if event.pressed:
			_begin_touch(event.index, event.position)
		else:
			_end_touch(event.index)
		get_viewport().set_input_as_handled()
		queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == _move_finger:
			_update_move(event.position)
		elif event.index == _look_finger:
			look_changed.emit(event.relative)
		get_viewport().set_input_as_handled()
		queue_redraw()

func _begin_touch(index: int, position: Vector2) -> void:
	var button := _button_at(position)
	if not button.is_empty():
		_button_fingers[index] = button
		_activate_button(button)
		return
	if position.x < size.x * 0.48 and _move_finger == -1:
		_move_finger = index
		_update_move(position)
	elif _look_finger == -1:
		_look_finger = index

func _end_touch(index: int) -> void:
	if index == _move_finger:
		_move_finger = -1
		_last_move = Vector2.ZERO
		move_changed.emit(Vector2.ZERO)
	if index == _look_finger:
		_look_finger = -1
	if _button_fingers.has(index):
		var button: String = _button_fingers[index]
		_button_fingers.erase(index)
		_deactivate_button(button)

func _update_move(position: Vector2) -> void:
	var offset := position - _joystick_center()
	var value := Vector2(offset.x, -offset.y) / _joystick_radius()
	value = value.limit_length(1.0)
	if value.length() < 0.12:
		value = Vector2.ZERO
	_last_move = value
	move_changed.emit(value)

func _activate_button(button: String) -> void:
	_pressed_buttons[button] = true
	match button:
		"flashlight":
			flashlight_pressed.emit()
		"interact":
			interact_pressed.emit()
		"pause":
			pause_pressed.emit()
		"sprint":
			sprint_changed.emit(true)
		"crouch":
			crouch_changed.emit(true)

func _deactivate_button(button: String) -> void:
	_pressed_buttons.erase(button)
	match button:
		"sprint":
			sprint_changed.emit(false)
		"crouch":
			crouch_changed.emit(false)

func _reset_touch_state() -> void:
	_move_finger = -1
	_look_finger = -1
	_button_fingers.clear()
	_pressed_buttons.clear()
	_last_move = Vector2.ZERO
	move_changed.emit(Vector2.ZERO)
	sprint_changed.emit(false)
	crouch_changed.emit(false)
	queue_redraw()

func _button_at(position: Vector2) -> String:
	if position.distance_to(_pause_center()) <= _pause_radius() * 1.35:
		return "pause"
	for button in ["flashlight", "interact", "sprint", "crouch"]:
		if position.distance_to(_button_center(button)) <= _button_radius() * 1.35:
			return button
	return ""

func _joystick_center() -> Vector2:
	return Vector2(clampf(size.x * 0.17, 54.0, 104.0), size.y - maxf(72.0, size.y * 0.14))

func _joystick_radius() -> float:
	return clampf(minf(size.x, size.y) * 0.14, 42.0, 66.0)

func _button_radius() -> float:
	return clampf(minf(size.x, size.y) * 0.07, 25.0, 36.0)

func _button_center(button: String) -> Vector2:
	var radius := _button_radius()
	var right := size.x - radius - 12.0
	var left := right - radius * 2.35
	var upper := size.y - radius * 3.5
	var lower := size.y - radius * 1.4
	match button:
		"flashlight":
			return Vector2(right, upper)
		"interact":
			return Vector2(right, lower)
		"crouch":
			return Vector2(left, upper)
		"sprint":
			return Vector2(left, lower)
	return Vector2.ZERO

func _pause_center() -> Vector2:
	return Vector2(size.x - 42.0, 42.0)

func _pause_radius() -> float:
	return clampf(minf(size.x, size.y) * 0.06, 22.0, 30.0)

func _draw() -> void:
	if not is_touch_device:
		return
	var joystick := _joystick_center()
	var joystick_radius := _joystick_radius()
	draw_circle(joystick, joystick_radius, Color(0.02, 0.025, 0.03, 0.34))
	draw_arc(joystick, joystick_radius, 0.0, TAU, 48, Color(0.85, 0.81, 0.7, 0.68), 2.0, true)
	var knob := joystick
	if _move_finger != -1:
		knob += Vector2(_last_move.x, -_last_move.y) * joystick_radius
	draw_circle(knob, joystick_radius * 0.42, Color(0.74, 0.69, 0.56, 0.46))
	_draw_button("flashlight", "LUZ")
	_draw_button("interact", "USAR")
	_draw_button("sprint", "CORRER")
	_draw_button("crouch", "AGACHAR")
	var pause := _pause_center()
	_draw_button_circle(pause, _pause_radius(), _pressed_buttons.has("pause"))
	_draw_text(pause, "II", _pause_radius() * 2.0, 15)
	_draw_text(Vector2(size.x * 0.61, size.y * 0.58), "ARRASTE PARA OLHAR", size.x * 0.35, 12, Color(0.91, 0.88, 0.8, 0.72))

var _last_move := Vector2.ZERO

func _draw_button(button: String, label: String) -> void:
	var center := _button_center(button)
	var radius := _button_radius()
	_draw_button_circle(center, radius, _pressed_buttons.has(button))
	_draw_text(center, label, radius * 2.1, 10 if label.length() > 4 else 12)

func _draw_button_circle(center: Vector2, radius: float, pressed: bool) -> void:
	var fill := Color(0.58, 0.2, 0.13, 0.76) if pressed else Color(0.02, 0.025, 0.03, 0.55)
	draw_circle(center, radius, fill)
	draw_arc(center, radius, 0.0, TAU, 32, Color(0.85, 0.81, 0.7, 0.78), 2.0, true)

func _draw_text(center: Vector2, text: String, width: float, font_size: int, color := Color(0.96, 0.93, 0.85, 0.95)) -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, center + Vector2(-width * 0.5, font_size * 0.35), text,
			HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)