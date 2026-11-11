extends Control
## Menu principal em cima da arte cinematográfica do Distrito 11.

const PROTOTYPE_SCENE := "res://game/scenes/prototype/prototype.tscn"
const CHAPTER2_SCENE := "res://game/scenes/chapter2/apartment_304.tscn"
const SETTINGS_PATH := "user://linha11_settings.cfg"

var _chapter_panel: Control
var _settings_panel: Control
var _master_volume := 80.0
var _selected_button: Button
var _selected_dialog_button: Button


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	_build_backdrop()
	_build_main_menu()
	_build_chapter_panel()
	_build_settings_panel()
	_build_version_stamp()
	_load_settings()


func _build_backdrop() -> void:
	var image := TextureRect.new()
	image.name = "MenuBackground"
	image.texture = preload("res://assets/ui/main_menu_background.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(image)

	var shade := ColorRect.new()
	shade.name = "MenuVignette"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/ui/menu_vignette.gdshader")
	shade.material = material
	add_child(shade)


func _build_main_menu() -> void:
	var menu := VBoxContainer.new()
	menu.name = "MainMenuContent"
	menu.position = Vector2(70, 70)
	menu.size = Vector2(440, 570)
	menu.add_theme_constant_override("separation", 5)
	add_child(menu)

	var logo := HBoxContainer.new()
	logo.name = "Logo"
	logo.alignment = BoxContainer.ALIGNMENT_BEGIN
	logo.add_theme_constant_override("separation", 2)
	menu.add_child(logo)
	var title := UiKit.label("LINHA", 76, Color(0.91, 0.88, 0.82))
	title.name = "LogoWord"
	logo.add_child(title)
	var number := UiKit.label("11", 92, Color(0.62, 0.035, 0.025))
	number.name = "LogoNumber"
	logo.add_child(number)

	var subtitle := UiKit.label("A  Ú L T I M A   C H A M A D A", 17, Color(0.79, 0.74, 0.68))
	subtitle.name = "Subtitle"
	menu.add_child(subtitle)
	var rule := ColorRect.new()
	rule.color = Color(0.48, 0.035, 0.025, 0.86)
	rule.custom_minimum_size = Vector2(365, 2)
	menu.add_child(rule)
	var gap := Control.new()
	gap.custom_minimum_size.y = 28
	menu.add_child(gap)

	var new_game := _menu_button("Novo Jogo")
	new_game.name = "NewGameButton"
	new_game.pressed.connect(_start)
	menu.add_child(new_game)

	var continue_game := _menu_button("Continuar", false)
	continue_game.name = "ContinueButton"
	continue_game.tooltip_text = "Ainda não há um salvamento. Escolha Novo Jogo para começar."
	menu.add_child(continue_game)

	var chapters := _menu_button("Selecionar Capítulo")
	chapters.name = "ChapterSelectButton"
	chapters.pressed.connect(_show_chapters)
	menu.add_child(chapters)

	var settings := _menu_button("Configurações")
	settings.name = "SettingsButton"
	settings.pressed.connect(_show_settings)
	menu.add_child(settings)

	var quit := _menu_button("Sair")
	quit.name = "QuitButton"
	quit.pressed.connect(_exit_game)
	menu.add_child(quit)
	new_game.grab_focus()


func _menu_button(label: String, enabled := true, track_main_focus := true) -> Button:
	var button := Button.new()
	button.text = label
	button.set_meta("menu_label", label)
	button.custom_minimum_size = Vector2(390, 44)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL
	button.disabled = not enabled
	button.add_theme_font_size_override("font_size", 23)
	button.add_theme_color_override("font_color", Color(0.72, 0.70, 0.67))
	button.add_theme_color_override("font_hover_color", Color(0.94, 0.91, 0.85))
	button.add_theme_color_override("font_focus_color", Color(0.96, 0.93, 0.88))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.41, 0.39))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.015, 0.012, 0.01, 0.0)
	normal.content_margin_left = 14.0
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.12, 0.018, 0.014, 0.38)
	hover.border_width_left = 3
	hover.border_color = Color(0.57, 0.045, 0.03, 0.95)
	hover.content_margin_left = 14.0
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.14, 0.018, 0.014, 0.56)
	focus.border_width_left = 3
	focus.border_color = Color(0.70, 0.055, 0.035, 1.0)
	focus.content_margin_left = 14.0
	var pressed := focus.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.22, 0.025, 0.018, 0.7)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	if track_main_focus:
		button.focus_entered.connect(_on_menu_button_focused.bind(button))
	return button


func _on_menu_button_focused(button: Button) -> void:
	if is_instance_valid(_selected_button):
		_selected_button.text = "   " + str(_selected_button.get_meta("menu_label"))
	_selected_button = button
	button.text = "›  " + str(button.get_meta("menu_label"))


func _build_chapter_panel() -> void:
	_chapter_panel = _dialog_panel("SELECIONAR CAPÍTULO")
	_chapter_panel.name = "ChapterSelectPanel"
	add_child(_chapter_panel)
	var stack := _chapter_panel.get_node("Center/Panel/Content") as VBoxContainer
	var first := _dialog_button("Capítulo 1 — O Primeiro Chamado")
	first.name = "Chapter1Button"
	first.pressed.connect(_start)
	stack.add_child(first)
	var second := _dialog_button("Capítulo 2 — Apartamento 304")
	second.name = "Chapter2Button"
	second.pressed.connect(_start_chapter2)
	stack.add_child(second)
	var back := _dialog_button("Voltar")
	back.name = "ChapterBackButton"
	back.pressed.connect(_close_panels)
	stack.add_child(back)
	_chapter_panel.visible = false


func _build_settings_panel() -> void:
	_settings_panel = _dialog_panel("CONFIGURAÇÕES")
	_settings_panel.name = "SettingsPanel"
	add_child(_settings_panel)
	var stack := _settings_panel.get_node("Center/Panel/Content") as VBoxContainer
	var label := UiKit.label("VOLUME PRINCIPAL", 17, Color(0.82, 0.77, 0.70))
	stack.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	stack.add_child(row)
	var slider := HSlider.new()
	slider.name = "MasterVolumeSlider"
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.custom_minimum_size = Vector2(300, 32)
	slider.value = _master_volume
	slider.value_changed.connect(_on_volume_changed)
	row.add_child(slider)
	var value := UiKit.label("%d%%" % int(_master_volume), 17)
	value.name = "MasterVolumeValue"
	row.add_child(value)
	slider.value_changed.connect(func(amount: float): value.text = "%d%%" % int(amount))
	var controls := UiKit.label(GameInput.help_text(), 15, Color(0.62, 0.59, 0.54))
	controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls.custom_minimum_size = Vector2(420, 74)
	stack.add_child(controls)
	var back := _dialog_button("Voltar")
	back.name = "SettingsBackButton"
	back.pressed.connect(_close_panels)
	stack.add_child(back)
	_settings_panel.visible = false


func _dialog_panel(title_text: String) -> Control:
	var wrap := Control.new()
	wrap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.z_index = 20
	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.005, 0.004, 0.004, 0.78)
	wrap.add_child(veil)
	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrap.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.custom_minimum_size = Vector2(540, 350)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.021, 0.019, 0.97)
	panel_style.border_color = Color(0.37, 0.055, 0.035, 0.95)
	panel_style.set_border_width_all(1)
	panel_style.content_margin_left = 32.0
	panel_style.content_margin_right = 32.0
	panel_style.content_margin_top = 28.0
	panel_style.content_margin_bottom = 28.0
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)
	var stack := VBoxContainer.new()
	stack.name = "Content"
	stack.add_theme_constant_override("separation", 12)
	panel.add_child(stack)
	var title := UiKit.label(title_text, 25, Color(0.90, 0.84, 0.76))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var divider := ColorRect.new()
	divider.color = Color(0.51, 0.045, 0.03, 0.9)
	divider.custom_minimum_size.y = 2
	stack.add_child(divider)
	return wrap


func _dialog_button(label: String) -> Button:
	var button := _menu_button(label, true, false)
	button.custom_minimum_size = Vector2(450, 42)
	button.focus_entered.connect(_focus_dialog_button.bind(button))
	return button


func _focus_dialog_button(button: Button) -> void:
	if is_instance_valid(_selected_dialog_button):
		_selected_dialog_button.text = "   " + str(_selected_dialog_button.get_meta("menu_label"))
	_selected_dialog_button = button
	button.text = "›  " + str(button.get_meta("menu_label"))


func _show_chapters() -> void:
	_settings_panel.visible = false
	_chapter_panel.visible = true
	(_chapter_panel.find_child("Chapter1Button", true, false) as Button).grab_focus()


func _show_settings() -> void:
	_chapter_panel.visible = false
	_settings_panel.visible = true
	(_settings_panel.find_child("MasterVolumeSlider", true, false) as HSlider).grab_focus()


func _close_panels() -> void:
	_chapter_panel.visible = false
	_settings_panel.visible = false
	if is_instance_valid(_selected_button):
		_selected_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _chapter_panel.visible or _settings_panel.visible:
			_close_panels()
			get_viewport().set_input_as_handled()


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		_master_volume = float(config.get_value("audio", "master_volume", 80.0))
	_apply_master_volume(_master_volume)
	var slider := _settings_panel.find_child("MasterVolumeSlider", true, false) as HSlider
	var value := _settings_panel.find_child("MasterVolumeValue", true, false) as Label
	slider.value = _master_volume
	value.text = "%d%%" % int(_master_volume)


func _on_volume_changed(value: float) -> void:
	_master_volume = value
	_apply_master_volume(value)
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", value)
	config.save(SETTINGS_PATH)


func _apply_master_volume(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value / 100.0, 0.001)))


func _build_version_stamp() -> void:
	var version := UiKit.label("v%s" % ProjectSettings.get_setting("application/config/version", "0.1.0"), 13, Color(0.66, 0.63, 0.59))
	version.name = "VersionStamp"
	version.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version.position = Vector2(32, -32)
	version.size = Vector2(200, 24)
	add_child(version)


func _start() -> void:
	_start_chapter(PROTOTYPE_SCENE)


func _start_chapter2() -> void:
	_start_chapter(CHAPTER2_SCENE)


func _start_chapter(scene_path: String) -> void:
	_chapter_panel.visible = false
	_settings_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await get_tree().process_frame
	get_tree().change_scene_to_file(scene_path)


func _exit_game() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = '../';", true)
	else:
		get_tree().quit()
