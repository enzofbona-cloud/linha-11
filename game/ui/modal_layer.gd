class_name ModalLayer
extends CanvasLayer
## Painéis que tomam a tela durante o jogo: documento, teclado de senha,
## tela escura (ao ser pego) e tela de fim de capítulo.

signal opened
signal closed

var is_open := false

var _root: Control
var _doc_panel: Control
var _doc_title: Label
var _doc_body: Label
var _keypad_panel: Control
var _keypad_display: Label
var _keypad_hint: Label
var _keypad: Keypad
var _entry := ""
var _fade: ColorRect
var _ending: Control
var _ending_title: Label
var _ending_body: Label
var _ending_continue: Button
var _ending_next_scene := ""
var _beep: AudioStreamPlayer


func _init() -> void:
	layer = 15
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)

	_build_document()
	_build_keypad()
	_build_ending()
	_beep = SoundKit.player_2d(self, SoundKit.click(), -8.0)


func _panel(min_size: Vector2, color: Color) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	_root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_content_margin_all(28)
	style.border_color = Color(0, 0, 0, 0.5)
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	return [dim, box]


func _build_document() -> void:
	var parts := _panel(Vector2(560, 0), Color(0.83, 0.79, 0.68))
	_doc_panel = parts[0]
	var box: VBoxContainer = parts[1]
	_doc_title = UiKit.label("", 22, Color(0.16, 0.12, 0.08))
	box.add_child(_doc_title)
	_doc_body = UiKit.label("", 17, Color(0.2, 0.17, 0.13))
	_doc_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_doc_body.custom_minimum_size = Vector2(500, 0)
	box.add_child(_doc_body)
	box.add_child(UiKit.label("[E] ou [Esc] para fechar", 13, Color(0.4, 0.36, 0.3)))


func _build_keypad() -> void:
	var parts := _panel(Vector2(280, 0), Color(0.11, 0.12, 0.13))
	_keypad_panel = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiKit.label("FECHADURA 303", 14, UiKit.AMBER))
	_keypad_display = UiKit.label("_ _ _ _", 34, Color(0.6, 1.0, 0.65))
	_keypad_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_keypad_display)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	for key in ["1", "2", "3", "4", "5", "6", "7", "8", "9", "←", "0", "OK"]:
		var b := Button.new()
		b.text = key
		b.custom_minimum_size = Vector2(72, 52)
		b.add_theme_font_size_override("font_size", 22)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_key.bind(key))
		grid.add_child(b)
	_keypad_hint = UiKit.label("Digite 4 números. [Esc] para sair.", 13, UiKit.MUTED)
	box.add_child(_keypad_hint)


func _build_ending() -> void:
	_ending = ColorRect.new()
	_ending.color = Color(0, 0, 0, 0.94)
	_ending.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ending.visible = false
	_root.add_child(_ending)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ending.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_ending_title = UiKit.label("", 40, UiKit.AMBER)
	_ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_ending_title)
	_ending_body = UiKit.label("", 18)
	_ending_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_body.custom_minimum_size = Vector2(620, 0)
	box.add_child(_ending_body)
	var hint := UiKit.label("[Esc] para voltar ao menu", 14, UiKit.MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	_ending_continue = UiKit.button("Continuar")
	_ending_continue.visible = false
	_ending_continue.pressed.connect(_on_ending_continue)
	box.add_child(_ending_continue)


# --- documento ---

func open_document(title: String, body: String) -> void:
	_doc_title.text = title
	_doc_body.text = body
	_doc_panel.visible = true
	_open()


# --- teclado ---

func open_keypad(keypad: Keypad) -> void:
	_keypad = keypad
	_entry = ""
	_keypad_hint.text = "Digite 4 números. [Esc] para sair."
	_refresh_display()
	_keypad_panel.visible = true
	_open()


func _on_key(key: String) -> void:
	_beep.play()
	if key == "←":
		_entry = _entry.left(-1) if _entry.length() > 0 else ""
	elif key == "OK":
		_submit()
		return
	elif _entry.length() < 4:
		_entry += key
	_refresh_display()


func _submit() -> void:
	if _keypad != null and _keypad.try_code(_entry):
		close()
		return
	_entry = ""
	_keypad_hint.text = "Senha incorreta."
	_refresh_display()


func _refresh_display() -> void:
	var shown := PackedStringArray()
	for i in 4:
		shown.append(_entry[i] if i < _entry.length() else "_")
	_keypad_display.text = " ".join(shown)


## Verdadeiro quando o painel aberto precisa do cursor (teclado, tela final).
func needs_cursor() -> bool:
	return _keypad_panel.visible or _ending.visible


func _open() -> void:
	is_open = true
	opened.emit()


func close() -> void:
	if not is_open:
		return
	_doc_panel.visible = false
	_keypad_panel.visible = false
	_keypad = null
	is_open = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	if event.is_action_pressed("pause") or (event.is_action_pressed("interact") and not _keypad_panel.visible):
		get_viewport().set_input_as_handled()
		close()
	elif _keypad_panel.visible and event is InputEventKey and event.pressed and not event.echo:
		var digit := -1
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			digit = event.keycode - KEY_0
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
			digit = event.keycode - KEY_KP_0
		if digit >= 0:
			_on_key(str(digit))
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_BACKSPACE:
			_on_key("←")
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_key("OK")
			get_viewport().set_input_as_handled()


# --- tela escura e fim ---

## Escurece a tela, chama `midpoint` no escuro e clareia de novo.
func blackout(midpoint: Callable, text := "") -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", 1.0, 0.25)
	tween.tween_callback(midpoint)
	tween.tween_interval(1.2)
	tween.tween_property(_fade, "color:a", 0.0, 0.9)


func show_ending(title: String, body: String, next_scene := "") -> void:
	_ending_title.text = title
	_ending_body.text = body
	_ending_next_scene = next_scene
	_ending_continue.visible = not next_scene.is_empty()
	_ending.visible = true


func _on_ending_continue() -> void:
	if _ending_next_scene.is_empty():
		return
	get_tree().change_scene_to_file(_ending_next_scene)
