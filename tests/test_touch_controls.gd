extends GutTest

func _new_touch_controls() -> TouchControls:
	var controls := TouchControls.new()
	add_child_autofree(controls)
	controls.set_anchors_preset(Control.PRESET_TOP_LEFT)
	controls.size = Vector2(360, 640)
	controls.is_touch_device = true
	return controls

func test_joystick_emits_forward_and_stops_on_release():
	var controls := _new_touch_controls()
	var values: Array[Vector2] = []
	controls.move_changed.connect(func(value: Vector2): values.append(value))
	var center := controls._joystick_center()
	var down := InputEventScreenTouch.new()
	down.index = 1
	down.pressed = true
	down.position = center
	controls._input(down)
	var drag := InputEventScreenDrag.new()
	drag.index = 1
	drag.position = center + Vector2(0, -50)
	drag.relative = Vector2(0, -50)
	controls._input(drag)
	assert_gt(values.back().y, 0.7, "arrastar para cima deve mover para frente")
	var up := InputEventScreenTouch.new()
	up.index = 1
	up.pressed = false
	up.position = drag.position
	controls._input(up)
	assert_eq(values.back(), Vector2.ZERO, "soltar deve parar o jogador")

func test_botao_luz_emite_acao_e_toque_detecta_celular():
	var controls := _new_touch_controls()
	controls.is_touch_device = false
	var counts := [0, 0]
	controls.touch_detected.connect(func(): counts[0] += 1)
	controls.flashlight_pressed.connect(func(): counts[1] += 1)
	var tap := InputEventScreenTouch.new()
	tap.index = 2
	tap.pressed = true
	tap.position = controls._button_center("flashlight")
	controls._input(tap)
	assert_eq(counts[0], 1)
	assert_eq(counts[1], 1)
	assert_true(controls.is_touch_device)