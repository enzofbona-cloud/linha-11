class_name PauseMenu
extends CanvasLayer
## Menu de pausa. Continua funcionando com o jogo pausado.

signal resumed
signal quit_to_menu

var _resume_button: Button


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)

	var box := UiKit.side_panel(root)
	box.add_child(UiKit.label("PAUSADO", 44, UiKit.AMBER))
	box.add_child(UiKit.label(" ", 10))

	_resume_button = UiKit.button("Continuar")
	_resume_button.pressed.connect(func(): resumed.emit())
	box.add_child(_resume_button)

	var quit := UiKit.button("Voltar ao menu")
	quit.pressed.connect(func(): quit_to_menu.emit())
	box.add_child(quit)

	box.add_child(UiKit.label(" ", 10))
	box.add_child(UiKit.label("CONTROLES", 14, UiKit.AMBER))
	box.add_child(UiKit.label(GameInput.help_text(), 15, UiKit.MUTED))


func open() -> void:
	visible = true
	_resume_button.grab_focus()


func close() -> void:
	visible = false
