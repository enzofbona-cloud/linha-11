extends Node3D
## Capítulo 1 — "O Primeiro Chamado" (primeira parte).
## 3º andar do Edifício Aurora: corredor, apartamentos 302, 303 e 304.
##
## Sequência: sem energia -> achar o fusível no 302 -> religar o quadro ->
## descobrir a senha do 303 no diário (03h17) -> pegar a chave do 304 ->
## a luz cai e o Ouvinte aparece -> chegar ao 304 em silêncio -> atender.
##
## O cenário é montado por código com blocos texturizados (provisório).

const WALL_H := 2.8
const DOOR_H := 2.1
const T := 0.2 # espessura das paredes
const START := Vector3(0, 0.05, -1.0)
const CHECKPOINT_303 := Vector3(3.6, 0.05, -10.5)
const LISTENER_START_Z := -2.0

const TEXT_NOTICE := "PREFEITURA MUNICIPAL — DEFESA CIVIL\n\nPor determinação sanitária, o Distrito 11 está INTERDITADO a partir de 9 de agosto.\n\nMoradores devem deixar os imóveis imediatamente. Não levem aparelhos telefônicos.\n\nNão atendam chamadas originadas dentro do perímetro."
const TEXT_DIARY := "8 de agosto.\n\nO telefone do 304 tocou a noite inteira de novo. A dona Marta jura que o aparelho está desligado da parede.\n\nO síndico trocou a fechadura do 303 por uma de senha. Disse que escolheu um número que ninguém aqui vai esquecer: a hora em que todos os relógios do prédio pararam.\n\nO meu parou às três e dezessete."
const TEXT_TRANSCRIPT := "LINHA 11 — TRANSCRIÇÃO AUTOMÁTICA\nRecebida: 9 de agosto, 02h51\n\n\"Edifício Aurora, terceiro andar. Somos dois técnicos. Está sem energia. Tem uma coisa no corredor, ela não enxerga, só escuta.\"\n\n\"…a gente achou a chave do 304.\"\n\nObservação do operador: a chamada descreve uma equipe que ainda não foi enviada."

var player: Player
var listener: Listener
var power_on := false
var chapter_ended := false

var _hud: GameHud
var _pause: PauseMenu
var _modal: ModalLayer
var _phone: Phone
var _keypad: Keypad
var _was_captured := false
var _flicker: OmniLight3D
var _power_lights: Array[OmniLight3D] = []
var _light_energy := {}
var _time := 0.0
var _key_taken := false
var _in_304 := false
var _caught_lock := false
var _sting: AudioStreamPlayer

var _m_wall: StandardMaterial3D
var _m_floor: StandardMaterial3D
var _m_ceiling: StandardMaterial3D
var _m_wood: StandardMaterial3D
var _m_metal: StandardMaterial3D
var _m_fabric: StandardMaterial3D
var _m_trim: StandardMaterial3D
var _m_paper: StandardMaterial3D


func _ready() -> void:
	_m_wall = LevelKit.textured("wall", 0.85, Color(0.78, 0.76, 0.68))
	_m_floor = LevelKit.textured("floor", 0.55, Color(0.62, 0.56, 0.5))
	_m_ceiling = LevelKit.textured("ceiling", 0.7, Color(0.7, 0.69, 0.66))
	_m_wood = LevelKit.textured("wood", 0.9, Color(0.5, 0.4, 0.32))
	_m_metal = LevelKit.textured("metal", 0.8, Color(0.55, 0.58, 0.6))
	_m_metal.metallic = 0.7
	_m_fabric = LevelKit.textured("fabric", 1.6, Color(0.45, 0.47, 0.4))
	_m_trim = LevelKit.textured("door", 0.9, Color(0.3, 0.28, 0.25))
	_m_paper = StandardMaterial3D.new()
	_m_paper.albedo_color = Color(0.86, 0.82, 0.7)
	_m_paper.roughness = 0.9
	_m_paper.emission_enabled = true
	_m_paper.emission = Color(0.86, 0.82, 0.7)
	_m_paper.emission_energy_multiplier = 0.06

	_build_environment()
	_build_structure()
	_build_doors()
	_build_trim()
	_build_furniture()
	_build_lights()
	_build_items()
	_phone = _build_phone()

	listener = Listener.new()
	listener.position = Vector3(0, 0, LISTENER_START_Z)
	listener.z_min = -15.0
	listener.z_max = -1.0
	add_child(listener)
	listener.caught.connect(on_caught)

	player = Player.new()
	player.position = START
	player.add_to_group("player_target")
	add_child(player)
	player.noise_made.connect(listener.hear)

	_hud = GameHud.new()
	add_child(_hud)
	player.message.connect(_hud.show_message)
	player.prompt_changed.connect(_hud.set_prompt)
	player.inventory_changed.connect(_hud.set_inventory)

	_modal = ModalLayer.new()
	add_child(_modal)
	player.document_requested.connect(_modal.open_document)
	player.keypad_requested.connect(_modal.open_keypad)
	_modal.opened.connect(func(): player.controls_enabled = false)
	_modal.closed.connect(_on_modal_closed)

	_pause = PauseMenu.new()
	add_child(_pause)
	_pause.resumed.connect(_resume)
	_pause.quit_to_menu.connect(_quit_to_menu)

	_phone.answered.connect(_on_phone_answered)
	_phone.call_finished.connect(_on_call_finished)

	add_child(preload("res://game/ui/debug_hud.tscn").instantiate())
	var hum := SoundKit.player_2d(self, SoundKit.hum(), -14.0)
	hum.play()
	_sting = SoundKit.player_2d(self, SoundKit.sting(), -3.0)

	set_power(false)
	_hud.set_objective("Restabeleça a energia do andar.")
	_hud.show_message("Distrito 11 — Edifício Aurora, 3º andar. Sem energia. Use a lanterna [F].", 7.0)
	_capture_mouse()


func _process(delta: float) -> void:
	_time += delta
	if _flicker != null and power_on:
		var on := sin(_time * 31.0) * sin(_time * 7.3) > -0.55
		_flicker.light_energy = _light_energy[_flicker] if on else 0.06
		var diffuser = (_flicker.get_meta("diffuser") if _flicker.has_meta("diffuser") else null)
		if diffuser != null:
			diffuser.visible = on

	if not _in_304 and player.global_position.z < -16.5:
		_in_304 = true
		listener.sleep()
		_hud.set_objective("Atenda o telefone.")

	if get_tree().paused or _modal.is_open or chapter_ended:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if captured:
		_was_captured = true
		_hud.set_click_hint(false)
	elif _was_captured:
		# O navegador solta o mouse sozinho quando o jogador aperta Esc.
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
		_capture_mouse()


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_modal_closed() -> void:
	player.controls_enabled = true
	_was_captured = false
	_capture_mouse()


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


# --- eventos do capítulo ---

func set_power(on: bool) -> void:
	power_on = on
	for light in _power_lights:
		light.light_energy = _light_energy[light] if on else 0.0
		var diffuser = (light.get_meta("diffuser") if light.has_meta("diffuser") else null)
		if diffuser != null:
			diffuser.visible = on
	if _keypad != null:
		_keypad.has_power = on


func _on_power_restored() -> void:
	set_power(true)
	_phone.start_ringing()
	_hud.set_objective("Um telefone está tocando. Encontre-o.")


func _on_keypad_unlocked() -> void:
	player.notify("A fechadura do 303 destravou.")
	player.make_noise(Player.NOISE_DOOR)


func _on_item_picked(id: String) -> void:
	if id == "chave_304":
		on_key_taken()


func on_key_taken() -> void:
	if _key_taken:
		return
	_key_taken = true
	set_power(false)
	listener.position.z = LISTENER_START_Z
	listener.wake()
	if _sting != null:
		_sting.play()
	_hud.set_objective("Chegue ao 304 sem fazer barulho.")
	_hud.show_message("A luz caiu. Tem algo no corredor. Agache [Ctrl] ou ande devagar [Alt]: ele só escuta.", 9.0)


func on_caught() -> void:
	if _caught_lock or chapter_ended or _in_304:
		return
	_caught_lock = true
	player.controls_enabled = false
	_modal.blackout(_respawn)
	_hud.show_message("Ele atendeu você.", 3.0)


func _respawn() -> void:
	player.global_position = CHECKPOINT_303
	player.velocity = Vector3.ZERO
	listener.position.z = LISTENER_START_Z
	listener.wake()
	listener.target_z = LISTENER_START_Z
	listener.state = Listener.State.PATROL
	player.controls_enabled = true
	_caught_lock = false
	_hud.show_message("Você acordou no 303. Silêncio desta vez.", 5.0)


func _on_phone_answered() -> void:
	listener.sleep()
	_hud.set_objective("Escute.")


func _on_call_finished() -> void:
	chapter_ended = true
	player.controls_enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _sting != null:
		_sting.play()
	_modal.show_ending("O PRIMEIRO CHAMADO",
		"A voz no telefone sabia o seu nome.\n\nA transcrição no 303 descrevia esta noite, com 17 anos de antecedência.\n\nFim da primeira parte do Capítulo 1. Obrigado por testar.")


# --- construção do cenário ---

func _wall(node_name: String, center_xz: Vector2, size_xz: Vector2, y0 := 0.0, y1 := WALL_H) -> void:
	LevelKit.box(self, node_name,
		Vector3(center_xz.x, (y0 + y1) / 2.0, center_xz.y),
		Vector3(size_xz.x, y1 - y0, size_xz.y), _m_wall)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.004, 0.005, 0.007)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.24, 0.32)
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.03, 0.035, 0.045)
	env.fog_density = 0.028
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.88
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


func _build_structure() -> void:
	LevelKit.box(self, "Floor", Vector3(0, -0.1, -11), Vector3(14, 0.2, 24), _m_floor)
	LevelKit.box(self, "Ceiling", Vector3(0, WALL_H + 0.1, -11), Vector3(14, 0.2, 24), _m_ceiling)

	# Corredor (x de -1.2 a 1.2, z de 0 a -16)
	_wall("CorridorBack", Vector2(0, 0.1), Vector2(2.8, T))
	_wall("CorridorLeftA", Vector2(-1.3, -2.5), Vector2(T, 5))
	_wall("CorridorLeftLintel", Vector2(-1.3, -5.5), Vector2(T, 1), DOOR_H)
	_wall("CorridorLeftB", Vector2(-1.3, -11), Vector2(T, 10))
	_wall("CorridorRightA", Vector2(1.3, -5), Vector2(T, 10))
	_wall("CorridorRightLintel", Vector2(1.3, -10.5), Vector2(T, 1), DOOR_H)
	_wall("CorridorRightB", Vector2(1.3, -13.5), Vector2(T, 5))

	# Parede do fundo do corredor, com a porta do 304
	_wall("EndWallLeft", Vector2(-1.8, -16.1), Vector2(2.6, T))
	_wall("EndWallRight", Vector2(1.8, -16.1), Vector2(2.6, T))
	_wall("EndWallLintel", Vector2(0, -16.1), Vector2(1, T), DOOR_H)

	# Apartamento 302 (esquerda)
	_wall("AptLeftOuter", Vector2(-6.3, -5.5), Vector2(T, 5.4))
	_wall("AptLeftNear", Vector2(-3.8, -2.9), Vector2(5.2, T))
	_wall("AptLeftFar", Vector2(-3.8, -8.1), Vector2(5.2, T))

	# Apartamento 303 (direita)
	_wall("AptRightOuter", Vector2(6.3, -10.5), Vector2(T, 5.4))
	_wall("AptRightNear", Vector2(3.8, -7.9), Vector2(5.2, T))
	_wall("AptRightFar", Vector2(3.8, -13.1), Vector2(5.2, T))

	# Apartamento 304 (fundo)
	_wall("Apt304Left", Vector2(-3.1, -19.1), Vector2(T, 6.2))
	_wall("Apt304Right", Vector2(3.1, -19.1), Vector2(T, 6.2))
	_wall("Apt304Back", Vector2(0, -22.1), Vector2(6.4, T))


func _door(node_name: String, hinge: Vector3, base_yaw_deg: float, open_deg: float, key := "", locked_text := "Trancada.") -> Door:
	var door := Door.new()
	door.name = node_name
	door.position = hinge
	door.rotation_degrees.y = base_yaw_deg
	door.open_angle_deg = open_deg
	door.locked_key = key
	door.locked_text = locked_text
	add_child(door)
	return door


func _build_doors() -> void:
	_door("Door302", Vector3(-1.3, 0, -5.0), 0, 90)
	var door303 := _door("Door303", Vector3(1.3, 0, -10.0), 0, -90)
	door303.sealed = true
	_door("Door304", Vector3(-0.5, 0, -16.1), -90, 90, "chave_304",
		"Trancada. A placa diz 304. Parece vir daqui o toque.")

	_keypad = Keypad.new()
	_keypad.name = "Keypad303"
	_keypad.code = "0317"
	_keypad.door = door303
	_keypad.position = Vector3(1.17, 1.25, -9.72)
	_add_box_visual(_keypad, Vector3(0.04, 0.17, 0.11), _m_metal, Vector3(0.1, 0.22, 0.16))
	add_child(_keypad)
	_keypad.unlocked.connect(_on_keypad_unlocked)


## Rodapés e batentes: detalhes que tiram a aparência de "caixa lisa".
func _build_trim() -> void:
	for side in [-1.0, 1.0]:
		var x: float = side * 1.185
		LevelKit.box(self, "Baseboard", Vector3(x, 0.05, -8.05), Vector3(0.03, 0.1, 15.9), _m_trim, false)
	_frame(Vector3(-1.3, 0, -5.5), true)
	_frame(Vector3(1.3, 0, -10.5), true)
	_frame(Vector3(0, 0, -16.1), false)


func _frame(center: Vector3, along_z: bool) -> void:
	var depth := T + 0.06
	for s in [-1.0, 1.0]:
		var offset := Vector3(0, DOOR_H / 2.0, s * 0.53) if along_z else Vector3(s * 0.53, DOOR_H / 2.0, 0)
		var size := Vector3(depth, DOOR_H, 0.06) if along_z else Vector3(0.06, DOOR_H, depth)
		LevelKit.box(self, "DoorJamb", center + offset, size, _m_trim, false)
	var top_size := Vector3(depth, 0.06, 1.12) if along_z else Vector3(1.12, 0.06, depth)
	LevelKit.box(self, "DoorHead", center + Vector3(0, DOOR_H + 0.03, 0), top_size, _m_trim, false)


func _table(prefix: String, center: Vector3, size: Vector2, height := 0.75) -> void:
	LevelKit.box(self, prefix + "Top", center + Vector3(0, height, 0), Vector3(size.x, 0.05, size.y), _m_wood)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			LevelKit.box(self, prefix + "Leg", center + Vector3(sx * (size.x / 2 - 0.05), height / 2, sz * (size.y / 2 - 0.05)),
				Vector3(0.05, height, 0.05), _m_wood, false)


func _build_furniture() -> void:
	# 302: cama, criado-mudo, guarda-roupa
	LevelKit.box(self, "Bed", Vector3(-5.2, 0.25, -6.8), Vector3(1.9, 0.5, 1.0), _m_fabric)
	LevelKit.box(self, "BedHead", Vector3(-6.1, 0.55, -6.8), Vector3(0.08, 1.1, 1.0), _m_wood)
	LevelKit.box(self, "Nightstand", Vector3(-5.9, 0.28, -5.9), Vector3(0.45, 0.56, 0.45), _m_wood)
	LevelKit.box(self, "Wardrobe", Vector3(-3.6, 1.0, -3.3), Vector3(1.6, 2.0, 0.6), _m_wood)

	# 303: mesa, cadeira caída, estante de metal, caixas
	_table("Table303", Vector3(4.6, 0, -11.6), Vector2(1.3, 0.8))
	LevelKit.box(self, "Chair", Vector3(3.7, 0.22, -12.2), Vector3(0.45, 0.44, 0.9), _m_wood)
	LevelKit.box(self, "Shelf", Vector3(6.0, 0.95, -9.2), Vector3(0.4, 1.9, 1.4), _m_metal)
	LevelKit.box(self, "BoxA", Vector3(2.2, 0.2, -8.6), Vector3(0.5, 0.4, 0.5), _m_fabric)
	LevelKit.box(self, "BoxB", Vector3(2.5, 0.55, -8.5), Vector3(0.4, 0.3, 0.4), _m_fabric)

	# Corredor: banco
	LevelKit.box(self, "Bench", Vector3(0.95, 0.22, -3.0), Vector3(0.4, 0.44, 1.4), _m_wood)

	# 304: mesa do telefone, poltrona, armário
	_table("PhoneTable", Vector3(0, 0, -21.2), Vector2(1.2, 0.6))
	LevelKit.box(self, "Armchair", Vector3(-2.2, 0.3, -20.6), Vector3(0.9, 0.6, 0.9), _m_fabric)
	LevelKit.box(self, "ArmchairBack", Vector3(-2.6, 0.75, -20.6), Vector3(0.15, 0.9, 0.9), _m_fabric)
	LevelKit.box(self, "Cupboard", Vector3(2.7, 1.0, -18.5), Vector3(0.5, 2.0, 1.8), _m_wood)


func _power_light(light: OmniLight3D) -> OmniLight3D:
	_power_lights.append(light)
	_light_energy[light] = light.light_energy
	return light


func _build_lights() -> void:
	_power_light(LevelKit.ceiling_light(self, Vector3(0, WALL_H - 0.1, -2.5), Color(1, 0.86, 0.66), 1.3, 7.0, true))
	_flicker = _power_light(LevelKit.ceiling_light(self, Vector3(0, WALL_H - 0.1, -10.5), Color(0.82, 0.92, 1.0), 1.2, 7.0, true))
	# Abajur do 302 (depende da energia)
	_power_light(LevelKit.lamp(self, Vector3(-5.9, 0.9, -5.9), Color(1, 0.72, 0.42), 0.7, 4.5, true))
	# O brilho vermelho do telefone não depende de energia nenhuma
	LevelKit.lamp(self, Vector3(0, 1.3, -20.9), Color(1, 0.18, 0.1), 0.6, 5.0)


func _add_box_visual(body: Node3D, size: Vector3, mat: Material, collision_size := Vector3.ZERO) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = mat
	mesh.mesh = box
	body.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = collision_size if collision_size != Vector3.ZERO else size
	shape.shape = box_shape
	body.add_child(shape)


func _readable(node_name: String, title: String, body: String, pos: Vector3, size: Vector3) -> Readable:
	var doc := Readable.new()
	doc.name = node_name
	doc.title = title
	doc.body = body
	doc.position = pos
	_add_box_visual(doc, size, _m_paper, size + Vector3(0.12, 0.12, 0.12))
	add_child(doc)
	return doc


func _pickup(node_name: String, id: String, display: String, pos: Vector3, size: Vector3, color: Color) -> Pickup:
	var item := Pickup.new()
	item.name = node_name
	item.item_id = id
	item.item_name = display
	item.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.85
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.25
	_add_box_visual(item, size, mat, Vector3(0.24, 0.2, 0.24))
	item.picked.connect(_on_item_picked)
	add_child(item)
	return item


func _build_items() -> void:
	# Aviso da Defesa Civil colado na parede, logo na entrada
	_readable("Notice", "Aviso de interdição", TEXT_NOTICE, Vector3(1.19, 1.5, -1.9), Vector3(0.01, 0.3, 0.21))
	# 302: diário na cama e fusível no criado-mudo
	_readable("Diary", "Diário (apto 302)", TEXT_DIARY, Vector3(-4.9, 0.515, -6.7), Vector3(0.15, 0.03, 0.21))
	_pickup("Fuse", FuseBox.FUSE_ID, "Fusível", Vector3(-5.9, 0.59, -5.85), Vector3(0.03, 0.03, 0.09), Color(0.8, 0.75, 0.6))
	# 303: transcrição e chave em cima da mesa
	_readable("Transcript", "Transcrição da Linha 11", TEXT_TRANSCRIPT, Vector3(4.95, 0.78, -11.5), Vector3(0.21, 0.01, 0.3))
	_pickup("Key304", "chave_304", "Chave do 304", Vector3(4.35, 0.79, -11.65), Vector3(0.09, 0.012, 0.03), Color(0.75, 0.62, 0.3))

	# Quadro de força no corredor
	var box := FuseBox.new()
	box.position = Vector3(-1.14, 1.35, -13.5)
	_add_box_visual(box, Vector3(0.12, 0.6, 0.45), _m_metal)
	add_child(box)
	box.power_restored.connect(_on_power_restored)


func _build_phone() -> Phone:
	var phone := Phone.new()
	phone.position = Vector3(0, 0.82, -21.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.04, 0.04, 0.04)
	mat.roughness = 0.35
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.24, 0.09, 0.2)
	box.material = mat
	mesh.mesh = box
	phone.add_child(mesh)
	var handset := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(0.26, 0.04, 0.06)
	hbox.material = mat
	handset.mesh = hbox
	handset.position = Vector3(0, 0.065, -0.04)
	phone.add_child(handset)

	var led_mat := StandardMaterial3D.new()
	led_mat.albedo_color = Color(0.6, 0.05, 0.03)
	led_mat.emission_enabled = true
	led_mat.emission = Color(1, 0.12, 0.06)
	led_mat.emission_energy_multiplier = 3.0
	var led := MeshInstance3D.new()
	var lbox := BoxMesh.new()
	lbox.size = Vector3(0.02, 0.02, 0.02)
	lbox.material = led_mat
	led.mesh = lbox
	led.position = Vector3(0.09, 0.05, 0.07)
	phone.add_child(led)
	phone.set_led(led)

	var shape := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = Vector3(0.3, 0.16, 0.26)
	shape.shape = bshape
	phone.add_child(shape)
	add_child(phone)
	return phone
