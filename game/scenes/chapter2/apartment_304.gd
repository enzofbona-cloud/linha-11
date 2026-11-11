extends Node3D
## Capítulo 2 — Apartamento 304. O interior excede a planta do prédio.

const PHOTO_TEXT := "FOTOGRAFIA — Edifício Aurora, 1989\n\nOs adultos não são identificados. O rosto do menino foi coberto com tinta preta. No verso, escrito à mão: D.R. — 304."
const SEQUENCE_NOTE := "RASCUNHO NO VERSO DA LISTA TELEFÔNICA\n\nTrês aparelhos. Uma ordem.\n\nO mais grave primeiro.\nO mais agudo depois.\nO tom do meio por último.\n\nNão deixe o último tocar sozinho."

var player: Player
var puzzle: PhoneSequence
var exit_door: Door
var chapter_ended := false
var _hud: GameHud
var _modal: ModalLayer
var _pause: PauseMenu
var _photo_texture: Texture2D
var _wall_mat: StandardMaterial3D
var _floor_mat: StandardMaterial3D
var _wood_mat: StandardMaterial3D
var _trim_mat: StandardMaterial3D
var _was_captured := false
var _controls_started := false


func _ready() -> void:
	_photo_texture = load("res://assets/characters/family_304.png")
	_wall_mat = _wallpaper_material()
	_floor_mat = LevelKit.textured("floor", 0.48, Color(0.56, 0.49, 0.4))
	_wood_mat = LevelKit.textured("wood", 0.8, Color(0.42, 0.32, 0.23))
	_trim_mat = LevelKit.textured("door", 0.8, Color(0.28, 0.23, 0.18))
	_build_environment()
	_build_room()
	_build_furniture()
	_build_evidence()
	_build_puzzle()
	_build_exit()
	_build_audio()
	_build_player_and_ui()


func _process(_delta: float) -> void:
	if chapter_ended or _modal.is_open or get_tree().paused:
		return
	if OS.has_feature("web"):
		_hud.set_click_hint(not _controls_started and not player.has_touch_controls())
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if captured:
		_was_captured = true
		_hud.set_click_hint(false)
	elif _was_captured:
		_pause_game()
	else:
		_hud.set_click_hint(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if chapter_ended:
			_quit_to_menu()
		elif get_tree().paused:
			_resume()
		else:
			_pause_game()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED \
			and not get_tree().paused and not _modal.is_open and not chapter_ended:
		if OS.has_feature("web"):
			_controls_started = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_hud.set_click_hint(false)
		else:
			_capture_mouse()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.005, 0.004)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34, 0.26, 0.19)
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.045, 0.033, 0.025)
	env.fog_density = 0.016
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.12
	env.adjustment_saturation = 0.78
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


func _wallpaper_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/characters/wallpaper_304.png")
	mat.albedo_color = Color(0.46, 0.39, 0.32)
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/textures/wall/normal.jpg")
	mat.normal_scale = 0.2
	mat.roughness_texture = load("res://assets/textures/wall/roughness.jpg")
	mat.roughness = 0.96
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(0.62, 0.62, 0.62)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


func _build_room() -> void:
	# A fachada do 304 tem apenas seis metros; o interior passa de trinta.
	_box("InteriorFloor", Vector3(0, -0.11, -14.5), Vector3(18, 0.22, 42), _floor_mat)
	_box("InteriorCeiling", Vector3(0, 2.9, -12), Vector3(18, 0.18, 36), LevelKit.textured("ceiling", 0.55, Color(0.74, 0.68, 0.59)))
	_box("LeftOuterWall", Vector3(-8.9, 1.4, -12), Vector3(0.2, 2.8, 34), _wall_mat)
	_box("RightOuterWall", Vector3(8.9, 1.4, -12), Vector3(0.2, 2.8, 34), _wall_mat)
	_box("EntryWallLeft", Vector3(-4.4, 1.4, 5), Vector3(9, 2.8, 0.2), _wall_mat)
	_box("EntryWallRight", Vector3(4.4, 1.4, 5), Vector3(9, 2.8, 0.2), _wall_mat)
	_box("EntryLintel", Vector3(0, 2.45, 5), Vector3(1.0, 0.7, 0.2), _wall_mat)
	var entry_door := Door.new()
	entry_door.name = "Door304Entry"
	entry_door.position = Vector3(-0.5, 0, 5)
	entry_door.rotation_degrees.y = -90
	entry_door.open_angle_deg = 90
	add_child(entry_door)
	_box("FarWallLeft", Vector3(-4.4, 1.4, -29), Vector3(9, 2.8, 0.2), _wall_mat)
	_box("FarWallRight", Vector3(4.4, 1.4, -29), Vector3(9, 2.8, 0.2), _wall_mat)
	_box("FarLintel", Vector3(0, 2.45, -29), Vector3(1.0, 0.7, 0.2), _wall_mat)
	_partition(-8.5, -4.8)
	_partition(-17.0, 4.8)
	for side in [-1.0, 1.0]:
		_box("Baseboard", Vector3(side * 8.76, 0.08, -12), Vector3(0.035, 0.16, 33.5), _trim_mat, false)
	_box("FrozenClock", Vector3(0, 2.46, -4.1), Vector3(0.5, 0.38, 0.05), _trim_mat, false)
	_box("ClockHands", Vector3(0, 2.46, -4.06), Vector3(0.025, 0.23, 0.015), LevelKit.material(Color(0.72, 0.62, 0.42)), false)
	LevelKit.lamp(self, Vector3(-5.6, 1.9, -6.4), Color(1.0, 0.62, 0.32), 0.48, 4.5, false)


func _partition(z: float, opening_center: float) -> void:
	var opening_width := 3.0
	var left_end := opening_center - opening_width / 2.0
	var right_start := opening_center + opening_width / 2.0
	_box("PartitionA", Vector3((-8.8 + left_end) / 2.0, 1.4, z), Vector3(left_end + 8.8, 2.8, 0.18), _wall_mat)
	_box("PartitionB", Vector3((right_start + 8.8) / 2.0, 1.4, z), Vector3(8.8 - right_start, 2.8, 0.18), _wall_mat)


func _build_furniture() -> void:
	_table("ClueTable", Vector3(0, 0, -2.8), Vector2(1.1, 0.7), 0.55)
	_table("PhoneTableGrave", Vector3(-5.3, 0, -5.5), Vector2(1.2, 0.7), 0.72)
	_table("SideboardTape", Vector3(5.7, 0, -9.9), Vector2(1.5, 0.55), 0.82)
	_table("PhoneTableHigh", Vector3(5.2, 0, -15.0), Vector2(1.1, 0.7), 0.7)
	_table("PhoneTableMid", Vector3(-5.6, 0, -23.0), Vector2(1.0, 0.7), 0.76)
	var fabric := LevelKit.textured("fabric", 1.4, Color(0.43, 0.35, 0.27))
	_box("SofaBase", Vector3(-5.9, 0.31, -7.0), Vector3(2.1, 0.62, 0.82), fabric)
	_box("SofaBack", Vector3(-5.9, 0.74, -7.38), Vector3(2.1, 0.85, 0.2), fabric)
	_box("SofaSeatLeft", Vector3(-6.38, 0.66, -6.88), Vector3(0.84, 0.16, 0.55), LevelKit.textured("fabric", 1.8, Color(0.52, 0.43, 0.34)))
	_box("SofaSeatRight", Vector3(-5.42, 0.66, -6.88), Vector3(0.84, 0.16, 0.55), LevelKit.textured("fabric", 1.8, Color(0.52, 0.43, 0.34)))
	_box("SofaArmLeft", Vector3(-7.02, 0.55, -7.0), Vector3(0.22, 0.42, 0.82), fabric)
	_box("SofaArmRight", Vector3(-4.78, 0.55, -7.0), Vector3(0.22, 0.42, 0.82), fabric)
	_box("Wardrobe304", Vector3(7.55, 1.15, -21.2), Vector3(1.7, 2.3, 0.58), _wood_mat)
	_box("DiningCabinet", Vector3(-7.7, 0.75, -13.7), Vector3(0.55, 1.5, 2.0), _wood_mat)
	for idx in 3:
		_box("CeilingBeam", Vector3(0, 2.72, -6.0 - float(idx) * 7.5), Vector3(17.6, 0.12, 0.22), _trim_mat, false)


func _table(prefix: String, center: Vector3, size: Vector2, height: float) -> void:
	_box(prefix + "Top", center + Vector3(0, height, 0), Vector3(size.x, 0.06, size.y), _wood_mat)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(prefix + "Leg", center + Vector3(sx * (size.x / 2 - 0.06), height / 2, sz * (size.y / 2 - 0.06)), Vector3(0.06, height, 0.06), _wood_mat)


func _build_evidence() -> void:
	_add_readable("SequenceClue", "Rascunho dos telefones", SEQUENCE_NOTE, Vector3(0, 0.58, -2.8), Vector3(0.28, 0.018, 0.2))
	_add_photo("FamilyPhoto304", Vector3(8.77, 1.68, -5.2), Vector2(0.78, 0.53))
	_add_readable("PhotoBack", "Verso da fotografia", PHOTO_TEXT, Vector3(8.67, 1.62, -5.2), Vector3(0.08, 0.5, 0.72), false)
	_add_photo("SecondPhoto", Vector3(-8.77, 1.55, -20.3), Vector2(0.62, 0.43))
	var tape := TapeRecorder.new()
	tape.name = "FutureArgumentTape"
	tape.position = Vector3(5.7, 0.85, -9.9)
	add_child(tape)


func _add_photo(node_name: String, pos: Vector3, dimensions: Vector2) -> void:
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.12, 0.075, 0.042)
	frame_mat.roughness = 0.75
	_box(node_name + "Frame", pos, Vector3(0.08, dimensions.y + 0.12, dimensions.x + 0.12), frame_mat, false)
	var photo := MeshInstance3D.new()
	photo.name = node_name + "Image"
	var quad := QuadMesh.new()
	quad.size = dimensions
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _photo_texture
	mat.roughness = 0.98
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	quad.material = mat
	photo.mesh = quad
	photo.position = pos + Vector3(-0.12 if pos.x > 0 else 0.12, 0, 0)
	photo.rotation.y = deg_to_rad(-90 if pos.x > 0 else 90)
	photo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(photo)


func _add_readable(node_name: String, title: String, text: String, pos: Vector3, size: Vector3, show_paper := true) -> Readable:
	var doc := Readable.new()
	doc.name = node_name
	doc.title = title
	doc.body = text
	doc.position = pos
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = size + Vector3(0.14, 0.14, 0.14)
	shape.shape = collider
	doc.add_child(shape)
	if show_paper:
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		box.material = LevelKit.material(Color(0.77, 0.72, 0.61))
		mesh.mesh = box
		doc.add_child(mesh)
	add_child(doc)
	return doc


func _build_puzzle() -> void:
	puzzle = PhoneSequence.new()
	puzzle.name = "PhoneSequence"
	add_child(puzzle)
	puzzle.solved.connect(_on_sequence_solved)
	var phone_data := [
		[0, Vector3(-5.3, 0.75, -5.5)],
		[2, Vector3(5.2, 0.73, -15.0)],
		[1, Vector3(-5.6, 0.79, -23.0)],
	]
	for data in phone_data:
		var phone := SequencePhone.new()
		phone.name = "SequencePhone%d" % data[0]
		phone.tone_index = data[0]
		phone.position = data[1]
		phone.puzzle = puzzle
		add_child(phone)


func _build_exit() -> void:
	exit_door = Door.new()
	exit_door.name = "ImpossibleExit"
	exit_door.position = Vector3(-0.5, 0, -29)
	exit_door.rotation_degrees.y = -90
	exit_door.open_angle_deg = 90
	exit_door.sealed = true
	exit_door.sealed_text = "A maçaneta está fria. Os três telefones ainda não foram sincronizados."
	add_child(exit_door)
	var area := Area3D.new()
	area.name = "ExitTrigger"
	area.position = Vector3(0, 1, -31.3)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3, 2, 2)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(_on_exit_entered)
	add_child(area)


func _build_audio() -> void:
	var hum := SoundKit.player_2d(self, SoundKit.hum(), -18.0)
	hum.play()
	var distant := SoundKit.player_3d(self, SoundKit.ring(), 30.0, -19.0)
	distant.position = Vector3(0, 1.0, -26.0)
	distant.play()


func _build_player_and_ui() -> void:
	player = Player.new()
	player.position = Vector3(0, 0.05, 1.0)
	player.add_to_group("player_target")
	player.flashlight.light_energy = 3.8
	player.flashlight.spot_angle = 31.0
	add_child(player)
	player.flashlight.visible = true
	_hud = GameHud.new()
	add_child(_hud)
	player.message.connect(_hud.show_message)
	player.prompt_changed.connect(_hud.set_prompt)
	player.inventory_changed.connect(_hud.set_inventory)
	player.pause_requested.connect(_pause_game)
	player.touch_mode_activated.connect(_on_touch_mode_activated)
	_modal = ModalLayer.new()
	add_child(_modal)
	player.document_requested.connect(_modal.open_document)
	_modal.opened.connect(func(): player.controls_enabled = false)
	_modal.closed.connect(func():
		player.controls_enabled = true
		_was_captured = false
		_capture_mouse())
	_pause = PauseMenu.new()
	add_child(_pause)
	_pause.resumed.connect(_resume)
	_pause.quit_to_menu.connect(_quit_to_menu)
	add_child(preload("res://game/ui/debug_hud.tscn").instantiate())
	_hud.set_objective("Descubra por que o 304 é maior por dentro.")
	_hud.show_message("A porta fechou atrás de você. O corredor não termina.\nA fita está no aparador.", 8.0)
	if player.has_touch_controls():
		_hud.set_click_hint_text("Joystick: andar  •  deslize à direita: olhar")
		_hud.set_click_hint(false)
	else:
		_hud.set_click_hint_text("WASD: andar  •  mouse: olhar  •  F: lanterna  •  E: interagir")
		_hud.set_click_hint(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _on_sequence_solved() -> void:
	exit_door.sealed = false
	_hud.set_objective("A porta sem número destravou. Atravesse.")
	_hud.show_message("Os três telefones tocam juntos. Do outro lado da porta, uma rua responde.", 7.0)


func _on_exit_entered(body: Node3D) -> void:
	if body != player or not puzzle.is_solved or chapter_ended:
		return
	chapter_ended = true
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_modal.show_ending("SEM SINAL",
		"A porta do 304 dá para uma rua que não existia no mapa.\n\nO rádio de Íris só recebe chiado. Ao longe, um orelhão começa a tocar.\n\nContinua: Capítulo 3 — Sem Sinal.")


func _box(node_name: String, center: Vector3, size: Vector3, mat: Material, solid := true) -> Node3D:
	return LevelKit.box(self, node_name, center, size, mat, solid)


func _capture_mouse() -> void:
	if OS.has_feature("web"):
		_controls_started = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_hud.set_click_hint(false)
		return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_touch_mode_activated() -> void:
	_controls_started = true
	_hud.set_click_hint_text("Joystick: andar  •  deslize à direita: olhar  •  LUZ: lanterna  •  USAR: interagir")
	_hud.set_click_hint(false)
	_hud.show_message("Controles de toque ativados. O botao LUZ alterna a lanterna.", 6.0)


func _pause_game() -> void:
	get_tree().paused = true
	_was_captured = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_pause.open()


func _resume() -> void:
	_pause.close()
	get_tree().paused = false
	_capture_mouse()


func _quit_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://game/ui/main_menu.tscn")
