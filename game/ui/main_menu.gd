extends Control
## Menu principal. A sala de boot fica renderizada ao fundo.

const PROTOTYPE_SCENE := "res://game/scenes/prototype/prototype.tscn"
const CHAPTER2_SCENE := "res://game/scenes/chapter2/apartment_304.tscn"


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false

	add_child(preload("res://game/scenes/boot/boot.tscn").instantiate())

	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.5)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	var box := UiKit.side_panel(root)
	box.add_child(UiKit.label("LINHA 11", 84, Color(0.94, 0.91, 0.85)))
	box.add_child(UiKit.label("A  Ú L T I M A  C H A M A D A", 20, UiKit.AMBER))
	box.add_child(UiKit.label(" ", 18))

	var new_game := UiKit.button("Nova campanha  (Capítulo 1)")
	new_game.name = "NewGameButton"
	new_game.pressed.connect(_start)
	box.add_child(new_game)

	var chapter2 := UiKit.button("Capítulo 2 — Apartamento 304")
	chapter2.name = "Chapter2Button"
	chapter2.pressed.connect(_start_chapter2)
	box.add_child(chapter2)

	box.add_child(UiKit.button("Continuar  (em breve)", false))
	box.add_child(UiKit.button("Criar sala  (em breve)", false))
	box.add_child(UiKit.button("Entrar em sala  (em breve)", false))
	box.add_child(UiKit.button("Configurações  (em breve)", false))

	if not OS.has_feature("web"):
		var quit := UiKit.button("Sair")
		quit.pressed.connect(func(): get_tree().quit())
		box.add_child(quit)

	box.add_child(UiKit.label(" ", 14))
	box.add_child(UiKit.label("CONTROLES", 14, UiKit.AMBER))
	box.add_child(UiKit.label(GameInput.HELP_TEXT, 15, UiKit.MUTED))

	new_game.grab_focus()


func _start() -> void:
	_start_chapter(PROTOTYPE_SCENE)


func _start_chapter2() -> void:
	_start_chapter(CHAPTER2_SCENE)


func _start_chapter(scene_path: String) -> void:
	# Pedir o pointer lock dentro do mesmo clique que inicia o capítulo.
	_request_mouse_capture()
	# Deixar o navegador confirmar a captura antes de trocar de cena.
	await get_tree().process_frame
	get_tree().change_scene_to_file(scene_path)


func _request_mouse_capture() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
