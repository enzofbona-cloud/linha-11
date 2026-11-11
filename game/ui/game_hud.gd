class_name GameHud
extends CanvasLayer
## HUD do jogo: mira, texto de interação, legendas/mensagens, objetivo e inventário.

const TEXT_COLOR := Color(0.9, 0.87, 0.78)

var _prompt: Label
var _message: Label
var _objective: Label
var _inventory: Label
var _click_hint: Label
var _message_timer := 0.0


func _init() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var crosshair := ColorRect.new()
	crosshair.color = Color(1, 1, 1, 0.55)
	crosshair.size = Vector2(4, 4)
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position -= Vector2(2, 2)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(crosshair)

	_prompt = _label(root, 18, Control.PRESET_CENTER, Vector2(0, 46))
	_message = _label(root, 20, Control.PRESET_CENTER_BOTTOM, Vector2(0, -110))
	_click_hint = _label(root, 18, Control.PRESET_CENTER, Vector2(0, -60))
	_click_hint.text = "Clique na tela para controlar"
	_click_hint.visible = false

	_objective = _label(root, 15, Control.PRESET_TOP_RIGHT, Vector2(-20, 14))
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_objective.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_objective.grow_vertical = Control.GROW_DIRECTION_END
	_inventory = _label(root, 15, Control.PRESET_BOTTOM_LEFT, Vector2(20, -16))
	_inventory.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_inventory.grow_horizontal = Control.GROW_DIRECTION_END
	_inventory.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _label(parent: Control, font_size: int, preset: int, offset: Vector2) -> Label:
	var label := Label.new()
	label.set_anchors_preset(preset)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.position += offset
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	parent.add_child(label)
	return label


func _process(delta: float) -> void:
	if _message_timer > 0.0:
		_message_timer -= delta
		_message.modulate.a = clampf(_message_timer / 0.6, 0.0, 1.0)
		if _message_timer <= 0.0:
			_message.text = ""


func set_prompt(text: String) -> void:
	_prompt.text = text


func show_message(text: String, seconds := 4.5) -> void:
	_message.text = text
	_message.modulate.a = 1.0
	_message_timer = seconds


func set_objective(text: String) -> void:
	_objective.text = "Objetivo: %s" % text


func set_inventory(names: Array) -> void:
	_inventory.text = "" if names.is_empty() else "Inventário: %s" % ", ".join(PackedStringArray(names))


func set_click_hint(show: bool) -> void:
	_click_hint.visible = show

func set_click_hint_text(text: String) -> void:
	_click_hint.text = text
