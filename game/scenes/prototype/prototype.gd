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
const START := Vector3(0, 0.05, -0.8)
const CHECKPOINT_303 := Vector3(4.1, 0.05, -18.4)
const LISTENER_START_Z := -2.0
const LISTENER_FAR_Z := -29.0
## Meia largura do corredor: além disso o jogador ainda está dentro de um quarto.
const CORRIDOR_EDGE := 1.05

const TEXT_NOTICE := "PREFEITURA MUNICIPAL — DEFESA CIVIL\n\nDISTRITO 11 — INTERDIÇÃO IMEDIATA\n\nEdifício Aurora, 9 de agosto de 1989.\n\nOs moradores devem deixar os imóveis sem usar os telefones fixos. Chamadas dentro do perímetro devem ser registradas, nunca atendidas."
const TEXT_DIARY := "8 de agosto.\n\nO telefone do 304 tocou outra vez, mesmo fora da tomada. A chave pequena ficou na gaveta do criado-mudo do 301.\n\nGuardei o fusível reserva na gaveta da penteadeira. A gaveta emperrou depois que o prédio apagou.\n\nA fechadura do 303 foi feita para abrir com a sequência que o síndico espalhou em três bilhetes. Não deixe que a Marta encontre o último."
const TEXT_FRAGMENT_03 := "FICHA DE RONDA — 301\n\nChamado de teste: ramal 03.\n\nA telefonista escreveu no verso: “a primeira parte da senha é o número deste ramal”."
const TEXT_FRAGMENT_1 := "PAPEL ENCONTRADO NO RELÓGIO\n\n... 03:1_ ...\n\nO resto da tinta foi levado pela água."
const TEXT_FRAGMENT_7 := "ANOTAÇÃO DA ZELADORA\n\nA Marta repetia que a última parte era 7.\n\nNo calendário, o dia 9 está circulado. Depois disso, ninguém devia atender."
const TEXT_TRANSCRIPT := "LINHA 11 — TRANSCRIÇÃO AUTOMÁTICA\nRecebida: 9 de agosto de 1989, 02h51\n\n“Edifício Aurora, terceiro andar. Somos dois técnicos. O corredor está sem energia.”\n\n“Tem alguém no fim do corredor. Ela não enxerga, só escuta.”\n\n“Encontramos a chave do 304. Espera... tem mais alguém na linha.”\n\nObservação do operador: a gravação descreve uma equipe que ainda não havia sido enviada."
var player: Player
var listener: Listener
var power_on := false
var chapter_ended := false

var _hud: GameHud
var _pause: PauseMenu
var _modal: ModalLayer
var _phone: Phone
var _keypad: Keypad
var session: PlaySession
var _flicker: OmniLight3D
var _power_lights: Array[OmniLight3D] = []
var _light_energy := {}
var _time := 0.0
var _key_taken := false
var _in_304 := false
var _caught_lock := false
var _listener_armed := false
var _listener_waiting_for_303_exit := false
var _breaker_door: Door
var _barricade: Searchable
var _barricade_door: Door
var _barricade_boards: Array[Node3D] = []
var _clue_one: Readable
var _code_fragments := {"03": false, "1": false, "7": false}
var code_complete := false
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
	_m_wall = LevelKit.textured("wall_aged", 0.33, Color(0.78, 0.76, 0.68))
	_m_floor = LevelKit.textured("floor_aged", 0.4, Color(0.62, 0.56, 0.5))
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
	listener.z_min = -29.5
	listener.z_max = -1.0
	add_child(listener)
	listener.caught.connect(on_caught)

	player = Player.new()
	player.position = START
	player.add_to_group("player_target")
	add_child(player)
	player.flashlight.visible = true
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

	_pause = PauseMenu.new()
	add_child(_pause)

	session = PlaySession.new()
	add_child(session)
	session.bind(player, _hud, _modal, _pause)

	_phone.answered.connect(_on_phone_answered)
	_phone.call_finished.connect(_on_call_finished)

	add_child(preload("res://game/ui/debug_hud.tscn").instantiate())
	var hum := SoundKit.player_2d(self, SoundKit.hum(), -14.0)
	hum.play()
	_sting = SoundKit.player_2d(self, SoundKit.sting(), -3.0)

	set_power(false)
	session.set_objective("Restabeleça a energia do andar.")
	if player.has_touch_controls():
		_hud.show_message("Use o joystick para andar. A lanterna já está ligada; toque em LUZ para alternar.", 7.0)
	else:
		_hud.show_message("Distrito 11 — Edifício Aurora, 3º andar. Sem energia. [F] alterna a lanterna.", 7.0)


func _process(delta: float) -> void:
	_time += delta
	if _flicker != null and power_on:
		var on := sin(_time * 31.0) * sin(_time * 7.3) > -0.55
		_flicker.light_energy = _light_energy[_flicker] if on else 0.06
		var diffuser = (_flicker.get_meta("diffuser") if _flicker.has_meta("diffuser") else null)
		if diffuser != null:
			diffuser.visible = on

	_check_listener_release()
	if not _in_304 and player.global_position.z < -30.5:
		_in_304 = true
		_listener_armed = false
		listener.sleep()
		session.set_objective("Atenda o telefone.")


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
	if _breaker_door != null:
		_breaker_door.sealed = false
	if _clue_one != null:
		_clue_one.visible = true
		_clue_one.collision_layer = 1
	_phone.start_ringing()
	session.set_objective("A zeladoria abriu. Procure o pé-de-cabra e junte os três pedaços da senha.")
	_hud.show_message("A energia voltou, mas a chamada vem de dentro do prédio.", 5.0)

func _on_keypad_unlocked() -> void:
	player.notify("A fechadura do 303 destravou.")
	player.make_noise(Player.NOISE_DOOR)
	session.set_objective("Entre no 303 e encontre a chave do 304.")

func _on_item_picked(id: String) -> void:
	if id == "chave_304":
		on_key_taken()


func _on_searchable_item_found(id: String) -> void:
	match id:
		"chave_gaveta":
			session.set_objective("Volte ao 302 e abra a gaveta trancada da penteadeira.")
		"fusivel":
			session.set_objective("Leve o fusível ao quadro de força no corredor.")
		"pe_de_cabra":
			session.set_objective("Use o pé-de-cabra para abrir a entrada bloqueada do 305.")
		_:
			pass


func _on_code_fragment_read(fragment: String) -> void:
	if not _code_fragments.has(fragment):
		return
	_code_fragments[fragment] = true
	code_complete = _code_fragments["03"] and _code_fragments["1"] and _code_fragments["7"]
	if code_complete:
		_keypad.code = "0317"
		session.set_objective("Os três bilhetes formam 0317. Digite a senha no 303.")
	else:
		var found: Array[String] = []
		for part in ["03", "1", "7"]:
			if _code_fragments[part]:
				found.append(part)
		session.set_objective("Senha do 303: %s. Procure os pedaços que faltam." % " — ".join(found))


func _on_barricade_opened() -> void:
	_barricade_door.sealed = false
	for board in _barricade_boards:
		if is_instance_valid(board):
			board.queue_free()
	_barricade.queue_free()
	session.set_objective("Entre no 305 e procure a última parte da senha.")

func on_key_taken() -> void:
	if _key_taken:
		return
	_key_taken = true
	set_power(false)
	if _sting != null:
		_sting.play()
	session.set_objective("Atravesse o corredor até o 304 sem fazer barulho.")
	_hud.show_message("A luz caiu. Agache [%s] ou ande devagar [%s] antes de sair do 303: tem algo que só escuta." % [
		GameInput.crouch_key_name(), GameInput.slow_key_name()], 9.0)
	_arm_listener()

func _arm_listener() -> void:
	listener.sleep()
	_listener_armed = true
	_listener_waiting_for_303_exit = _is_in_303(player.global_position)
	_check_listener_release()


func _is_in_303(pos: Vector3) -> bool:
	return pos.x > 1.45 and pos.x < 6.4 and pos.z > -22.5 and pos.z < -14.0


func is_in_corridor(pos: Vector3) -> bool:
	return absf(pos.x) < CORRIDOR_EDGE and pos.z > -29.5 and pos.z < -0.2


## O Ouvinte só é liberado depois que o jogador com a chave sai fisicamente do 303.
func _check_listener_release() -> void:
	if not _listener_armed or _in_304:
		return
	if _is_in_303(player.global_position):
		_listener_waiting_for_303_exit = true
		return
	if not _listener_waiting_for_303_exit or not is_in_corridor(player.global_position):
		return
	_listener_armed = false
	_listener_waiting_for_303_exit = false
	var player_z := player.global_position.z
	var from_start := absf(player_z - LISTENER_START_Z) >= absf(player_z - LISTENER_FAR_Z)
	listener.position.z = LISTENER_START_Z if from_start else LISTENER_FAR_Z
	listener.wake()
	listener.walk_toward(player_z)
	_hud.show_message("Um passo ecoa no fundo do corredor. Está vindo.", 5.0)

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
	player.controls_enabled = true
	_caught_lock = false
	_arm_listener()
	_hud.show_message("Você acordou no 303. Silêncio desta vez.", 5.0)


func _on_phone_answered() -> void:
	listener.sleep()
	session.set_objective("Escute.")


func _on_call_finished() -> void:
	chapter_ended = true
	if _sting != null:
		_sting.play()
	session.end_chapter("O PRIMEIRO CHAMADO",
		"A voz no telefone sabia o seu nome.

A transcrição no 303 descrevia esta noite, com 17 anos de antecedência.

Fim do Capítulo 1.",
		"res://game/scenes/chapter2/apartment_304.tscn")


# --- construção do cenário ---

func _wall(node_name: String, center_xz: Vector2, size_xz: Vector2, y0 := 0.0, y1 := WALL_H) -> void:
	LevelKit.box(self, node_name,
		Vector3(center_xz.x, (y0 + y1) / 2.0, center_xz.y),
		Vector3(size_xz.x, y1 - y0, size_xz.y), _m_wall)


func _hall_side_wall(prefix: String, wall_x: float, gaps: Array) -> void:
	var ordered: Array = gaps.duplicate()
	ordered.sort()
	ordered.reverse()
	var cursor := -0.7
	for i in ordered.size():
		var gap: float = ordered[i]
		var segment_end := gap + Door.WIDTH / 2.0
		if cursor > segment_end:
			_wall("%sSegment%d" % [prefix, i],
				Vector2(wall_x, (cursor + segment_end) / 2.0),
				Vector2(T, cursor - segment_end))
		_wall("%sLintel%d" % [prefix, i], Vector2(wall_x, gap),
			Vector2(T, Door.WIDTH), DOOR_H, WALL_H)
		cursor = gap - Door.WIDTH / 2.0
	if cursor > -30.0:
		_wall("%sEndSegment" % prefix, Vector2(wall_x, (cursor - 30.0) / 2.0),
			Vector2(T, cursor + 30.0))


func _build_structure() -> void:
	LevelKit.box(self, "Floor", Vector3(0, -0.1, -19.4), Vector3(15.5, 0.2, 39.0), _m_floor)
	LevelKit.box(self, "Ceiling", Vector3(0, WALL_H + 0.1, -19.4), Vector3(15.5, 0.2, 39.0), _m_ceiling)
	_wall("HallEntryWall", Vector2(0, 0.15), Vector2(2.8, T))
	_hall_side_wall("HallLeft", -1.4, [-4.0, -10.5])
	_hall_side_wall("HallRight", 1.4, [-4.0, -10.5, -17.5])

	_wall("LeftExterior", Vector2(-6.4, -7.35), Vector2(T, 13.1))
	_wall("RightExterior", Vector2(6.4, -11.6), Vector2(T, 21.8))
	for z in [-0.7, -7.4, -14.0]:
		_wall("LeftRoomCross%s" % str(absf(z)), Vector2(-3.9, z), Vector2(5.0, T))
	for z in [-0.7, -7.4, -14.0, -22.5]:
		_wall("RightRoomCross%s" % str(absf(z)), Vector2(3.9, z), Vector2(5.0, T))

	_wall("End304Left", Vector2(-2.5, -30.0), Vector2(4.0, T))
	_wall("End304Right", Vector2(2.5, -30.0), Vector2(4.0, T))
	_wall("End304Lintel", Vector2(0, -30.0), Vector2(1.0, T), DOOR_H, WALL_H)
	_wall("Room304Left", Vector2(-4.5, -34.2), Vector2(T, 8.4))
	_wall("Room304Right", Vector2(4.5, -34.2), Vector2(T, 8.4))
	_wall("Room304Back", Vector2(0, -38.4), Vector2(9.0, T))

func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.004, 0.005, 0.007)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.23, 0.25, 0.31)
	env.ambient_light_energy = 0.38
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
	env.adjustment_contrast = 1.05
	env.adjustment_saturation = 0.88
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


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
	_door("Door301", Vector3(-1.4, 0, -3.5), 0, 90)
	_door("Door302", Vector3(-1.4, 0, -10.0), 0, 90)

	_breaker_door = _door("DoorZeladoria", Vector3(1.4, 0, -3.5), 0, -90)
	_breaker_door.sealed = true
	_breaker_door.sealed_text = "A porta da zeladoria só abre quando a energia voltar."

	_barricade_door = _door("Door305", Vector3(1.4, 0, -10.0), 0, -90)
	_barricade_door.sealed = true
	_barricade_door.sealed_text = "As tábuas ainda estão pregadas."
	_barricade = Searchable.new()
	_barricade.name = "Barricade305"
	_barricade.label = "as tábuas do 305"
	_barricade.locked_key = "pe_de_cabra"
	_barricade.locked_text = "As tábuas estão firmes. A zeladoria deve ter uma ferramenta."
	_barricade.position = Vector3(1.31, 1.0, -10.5)
	_add_box_visual(_barricade, Vector3(0.035, 1.8, 1.0), _m_wood, Vector3(0.12, 1.8, 1.15))
	var proxy := _barricade.get_child(0) as MeshInstance3D
	if proxy != null:
		proxy.visible = false
	add_child(_barricade)
	for i in 3:
		var board := LevelKit.box(self, "BarricadeBoard%d" % i,
			Vector3(1.28, 0.52 + float(i) * 0.54, -10.5),
			Vector3(0.07, 0.09, 1.03), _m_wood, false)
		_barricade_boards.append(board)
	_barricade.opened.connect(_on_barricade_opened)

	var door303 := _door("Door303", Vector3(1.4, 0, -17.0), 0, -90)
	door303.sealed = true
	door303.sealed_text = "O teclado ao lado está apagado."
	_keypad = Keypad.new()
	_keypad.name = "Keypad303"
	_keypad.code = "----"
	_keypad.door = door303
	_keypad.position = Vector3(1.23, 1.25, -16.25)
	_add_box_visual(_keypad, Vector3(0.04, 0.17, 0.11), _m_metal, Vector3(0.1, 0.22, 0.16))
	add_child(_keypad)
	_keypad.unlocked.connect(_on_keypad_unlocked)

	_door("Door304", Vector3(-0.5, 0, -30.0), -90, 90, "chave_304",
		"Trancada. A placa diz 304; o telefone toca do outro lado.")

func _build_trim() -> void:
	for side in [-1.0, 1.0]:
		LevelKit.box(self, "HallBaseboard%s" % str(side),
			Vector3(side * 1.28, 0.055, -15.3), Vector3(0.06, 0.11, 29.0), _m_trim, false)
	for x in [-6.28, 6.28]:
		LevelKit.box(self, "ApartmentBaseboard%s" % str(x),
			Vector3(x, 0.055, -11.6), Vector3(0.06, 0.11, 21.8), _m_trim, false)
	LevelKit.box(self, "End304BaseboardLeft", Vector3(-4.38, 0.055, -34.2),
		Vector3(0.06, 0.11, 8.2), _m_trim, false)
	LevelKit.box(self, "End304BaseboardRight", Vector3(4.38, 0.055, -34.2),
		Vector3(0.06, 0.11, 8.2), _m_trim, false)

	for entry in [
		["301", -1.4, -4.0], ["302", -1.4, -10.5],
		["ZELADORIA", 1.4, -4.0], ["305", 1.4, -10.5], ["303", 1.4, -17.5],
	]:
		_room_sign(entry[0], entry[1], entry[2])
		for offset in [-0.55, 0.55]:
			LevelKit.box(self, "DoorJamb%s%s" % [entry[0], str(offset)],
				Vector3(entry[1], 1.05, entry[2] + offset),
				Vector3(0.10, 2.1, 0.09), _m_trim, false)
		LevelKit.box(self, "DoorHead%s" % entry[0],
			Vector3(entry[1], 2.14, entry[2]),
			Vector3(0.12, 0.12, 1.18), _m_trim, false)
	for offset in [-0.55, 0.55]:
		LevelKit.box(self, "DoorJamb304%s" % str(offset), Vector3(offset, 1.05, -29.96),
			Vector3(0.09, 2.1, 0.1), _m_trim, false)
	LevelKit.box(self, "Plaque304", Vector3(0, 1.78, -29.86), Vector3(0.55, 0.28, 0.055), _m_metal, false)
	var label := Label3D.new()
	label.name = "RoomNumber304"
	label.text = "304"
	label.position = Vector3(0, 1.76, -29.82)
	label.font_size = 36
	label.pixel_size = 0.0022
	label.modulate = Color(0.82, 0.72, 0.52)
	add_child(label)


func _room_sign(text: String, wall_x: float, z: float) -> void:
	LevelKit.box(self, "Plaque%s" % text,
		Vector3(wall_x * 0.93, 1.78, z), Vector3(0.055, 0.28, 0.48), _m_metal, false)
	var label := Label3D.new()
	label.name = "RoomNumber%s" % text
	label.text = text
	label.position = Vector3(wall_x * 0.9, 1.76, z)
	label.rotation.y = PI / 2.0 if wall_x < 0 else -PI / 2.0
	label.font_size = 36
	label.pixel_size = 0.0022
	label.modulate = Color(0.82, 0.72, 0.52)
	add_child(label)

func _frame(center: Vector3, along_z: bool) -> void:
	var depth := T + 0.06
	for s in [-1.0, 1.0]:
		var offset := Vector3(0, DOOR_H / 2.0, s * 0.53) if along_z else Vector3(s * 0.53, DOOR_H / 2.0, 0)
		var size := Vector3(depth, DOOR_H, 0.06) if along_z else Vector3(0.06, DOOR_H, depth)
		LevelKit.box(self, "DoorJamb", center + offset, size, _m_trim, false)
	var top_size := Vector3(depth, 0.06, 1.12) if along_z else Vector3(1.12, 0.06, depth)
	LevelKit.box(self, "DoorHead", center + Vector3(0, DOOR_H + 0.03, 0), top_size, _m_trim, false)


## Tapete: dá um "centro" ao cômodo e junta os móveis em volta dele.
func _rug(node_name: String, center: Vector3, size: Vector2, color: Color) -> void:
	var rug := LevelKit.box(self, node_name, center + Vector3(0, 0.02, 0), Vector3(size.x, 0.04, size.y),
		LevelKit.textured("fabric", 1.25, color), false)
	_register_room_prop(rug, center)


## Móvel com colisão apoiado no chão: `size` é a caixa (largura, altura,
## profundidade) antes de girar e `scale` o ajuste do modelo.
func _floor_furniture(node_name: String, path: String, floor_pos: Vector3, yaw: float,
		size: Vector3, scale := Vector3.ONE, visual_z := 0.0) -> StaticBody3D:
	var body := _room_furniture(node_name, path, floor_pos + Vector3(0, size.y / 2.0, 0), yaw, size)
	var visual := body.get_node("Visual") as Node3D
	visual.scale = scale
	visual.position = Vector3(0, -size.y / 2.0, visual_z)
	return body


func _table(prefix: String, center: Vector3, size: Vector2, height := 0.75, yaw := 0.0) -> void:
	var top := LevelKit.box(self, prefix + "Top", center + Vector3(0, height / 2.0, 0), Vector3(size.x, height, size.y), _m_wood)
	top.rotation.y = yaw
	for child in top.get_children():
		if child is MeshInstance3D:
			top.remove_child(child)
			child.free()
	var visual := LevelKit.model_visual("res://assets/models/polyhaven/WoodenTable_01/WoodenTable_01_1k.gltf")
	visual.position = center
	visual.rotation.y = yaw
	visual.scale = Vector3(size.x / 1.799648, height / 0.548849, size.y / 0.657175)
	_register_room_prop(visual, center)
	add_child(visual)


func _register_room_prop(node: Node, pos: Vector3) -> void:
	node.add_to_group("room_props_chapter1")
	if pos.z < -0.7 and pos.z > -7.4:
		if pos.x < -1.4:
			node.add_to_group("room_props_301")
		elif pos.x > 1.4:
			node.add_to_group("room_props_zeladoria")
		else:
			node.add_to_group("room_props_corridor")
	elif pos.z <= -7.4 and pos.z > -14.0:
		if pos.x < -1.4:
			node.add_to_group("room_props_302")
		elif pos.x > 1.4:
			node.add_to_group("room_props_305")
		else:
			node.add_to_group("room_props_corridor")
	elif pos.z <= -14.0 and pos.z > -22.5 and pos.x > 1.4:
		node.add_to_group("room_props_303")
	elif pos.z < -30.0 and absf(pos.x) < 4.5:
		node.add_to_group("room_props_304")
	else:
		node.add_to_group("room_props_corridor")

func _replace_furniture_visual(body: Node3D, path: String, rotation_y := 0.0,
		scale := Vector3.ONE, visual_offset := Vector3.ZERO) -> void:
	for child in body.get_children():
		if child is MeshInstance3D:
			body.remove_child(child)
			child.free()
			break
	var visual := LevelKit.model_visual(path)
	visual.name = "Visual"
	visual.position = visual_offset
	visual.rotation.y = rotation_y
	visual.scale = scale
	body.add_child(visual)
	_register_room_prop(body, body.position)


func _room_furniture(node_name: String, path: String, center: Vector3,
		rotation_y: float, collision_size: Vector3) -> StaticBody3D:
	var furniture := LevelKit.model(self, node_name, path, center, rotation_y, collision_size)
	_register_room_prop(furniture, center)
	return furniture


func _room_prop(node_name: String, path: String, pos: Vector3,
		rotation_y := 0.0, scale := Vector3.ONE) -> Node3D:
	var prop := Node3D.new()
	prop.name = node_name
	prop.position = pos
	prop.rotation.y = rotation_y
	prop.scale = scale
	prop.add_child(LevelKit.model_visual(path))
	_register_room_prop(prop, pos)
	add_child(prop)
	return prop


func _build_furniture() -> void:
	# 301 — quarto simples; cama, criado, armário e mesa de trabalho.
	_rug("Rug301", Vector3(-4.0, 0, -4.0), Vector2(2.5, 2.8), Color(0.34, 0.25, 0.18))
	_floor_furniture("Bed301", "res://assets/models/polyhaven/vintage_day_bed/vintage_day_bed_1k.gltf",
		Vector3(-5.35, 0, -5.65), 0.0, Vector3(1.85, 0.55, 1.05),
		Vector3(1.38, 1.0, 1.18), -0.08)
	_floor_furniture("Wardrobe301", "res://assets/models/polyhaven/GothicCabinet_01/GothicCabinet_01_1k.gltf",
		Vector3(-2.15, 0, -6.2), -PI / 2.0, Vector3(0.7, 1.9, 1.3),
		Vector3(0.88, 1.1, 1.0))
	_floor_furniture("Nightstand301", "res://assets/models/polyhaven/painted_wooden_nightstand/painted_wooden_nightstand_1k.gltf",
		Vector3(-3.55, 0, -5.35), -PI / 2.0, Vector3(0.5, 0.56, 0.48),
		Vector3(0.95, 1.0, 0.9))
	_floor_furniture("Bookcase301", "res://assets/models/polyhaven/Shelf_01/Shelf_01_1k.gltf",
		Vector3(-6.1, 0, -2.2), PI / 2.0, Vector3(0.32, 1.85, 1.15),
		Vector3(1.0, 1.18, 1.15))
	_table("Desk301", Vector3(-2.65, 0, -4.6), Vector2(1.25, 0.68), 0.76, PI / 2.0)
	_room_prop("DeskBook301", "res://assets/models/props/open_book.glb", Vector3(-2.65, 0.79, -4.72), 0.14)
	_room_prop("DeskPapers301", "res://assets/models/props/paper_stack.glb", Vector3(-2.28, 0.78, -4.52), -0.08)
	_room_prop("BedLamp301", "res://assets/models/props/table_lamp_80s.glb", Vector3(-5.45, 0.58, -4.5))
	_room_prop("Photo301", "res://assets/models/props/photo_frame.glb", Vector3(-4.0, 1.7, -7.28))
	_room_prop("Calendar301", "res://assets/models/props/wall_calendar_august.glb", Vector3(-5.6, 1.65, -7.28))
	_room_prop("Window301", "res://assets/models/furniture/window_curtains_80s.glb", Vector3(-6.18, 1.25, -4.8), PI / 2.0)

	# 302 — cama, penteadeira e mesa de jantar pequena.
	_rug("Rug302", Vector3(-4.0, 0, -10.8), Vector2(2.6, 2.8), Color(0.37, 0.18, 0.14))
	_floor_furniture("Bed302", "res://assets/models/polyhaven/vintage_day_bed/vintage_day_bed_1k.gltf",
		Vector3(-5.3, 0, -11.85), 0.0, Vector3(1.8, 0.55, 1.02),
		Vector3(1.35, 1.0, 1.15), -0.08)
	_floor_furniture("Vanity302", "res://assets/models/furniture/dresser_mirror_80s.glb",
		Vector3(-2.25, 0, -8.25), PI / 2.0, Vector3(0.62, 1.05, 1.2))
	_floor_furniture("Nightstand302", "res://assets/models/polyhaven/painted_wooden_nightstand/painted_wooden_nightstand_1k.gltf",
		Vector3(-3.15, 0, -11.8), -PI / 2.0, Vector3(0.55, 0.62, 0.5),
		Vector3(0.95, 1.0, 0.9))
	_floor_furniture("Bookcase302", "res://assets/models/polyhaven/Shelf_01/Shelf_01_1k.gltf",
		Vector3(-6.1, 0, -8.6), PI / 2.0, Vector3(0.3, 1.75, 1.12),
		Vector3(0.95, 1.12, 1.08))
	_table("Table302", Vector3(-3.45, 0, -13.0), Vector2(1.15, 0.65), 0.72)
	_floor_furniture("Chair302", "res://assets/models/polyhaven/painted_wooden_chair_02/painted_wooden_chair_02_1k.gltf",
		Vector3(-3.4, 0, -12.25), PI, Vector3(0.5, 0.82, 0.5),
		Vector3(0.88, 0.95, 0.88))
	_room_prop("Photo302", "res://assets/models/props/photo_frame.glb", Vector3(-4.1, 1.68, -13.83))
	_room_prop("Calendar302", "res://assets/models/props/wall_calendar_august.glb", Vector3(-5.7, 1.65, -13.83))
	_room_prop("Fan302", "res://assets/models/furniture/standing_fan_80s.glb", Vector3(-2.05, 0, -12.9), -0.25)
	_room_prop("Books302", "res://assets/models/props/books_stack.glb", Vector3(-3.55, 0.75, -13.05), 0.12)
	_room_prop("Tumbler302", "res://assets/models/props/glass_tumbler.glb", Vector3(-3.18, 0.75, -13.18))
	_room_prop("Clothes302", "res://assets/models/props/clothes_pile.glb", Vector3(-5.6, 0.04, -8.3), 0.28)
	_room_prop("Window302", "res://assets/models/furniture/window_curtains_80s.glb", Vector3(-6.18, 1.25, -11.8), PI / 2.0)

	# Zeladoria — bancada de manutenção, armário e caixas agrupadas na parede.
	_rug("RugCaretaker", Vector3(4.0, 0, -4.4), Vector2(2.8, 2.2), Color(0.22, 0.21, 0.18))
	_floor_furniture("CaretakerCabinet", "res://assets/models/polyhaven/painted_wooden_cabinet/painted_wooden_cabinet_1k.gltf",
		Vector3(5.8, 0, -6.1), -PI / 2.0, Vector3(0.58, 1.5, 1.4),
		Vector3(0.9, 1.05, 1.05))
	_floor_furniture("CaretakerShelf", "res://assets/models/polyhaven/Shelf_01/Shelf_01_1k.gltf",
		Vector3(6.1, 0, -2.25), PI / 2.0, Vector3(0.3, 1.8, 1.35),
		Vector3(1.0, 1.15, 1.1))
	_table("CaretakerBench", Vector3(2.35, 0, -5.9), Vector2(1.45, 0.72), 0.82, PI / 2.0)
	_floor_furniture("CaretakerChair", "res://assets/models/polyhaven/painted_wooden_chair_02/painted_wooden_chair_02_1k.gltf",
		Vector3(2.9, 0, -5.0), PI, Vector3(0.48, 0.82, 0.48),
		Vector3(0.86, 0.93, 0.86))
	_room_prop("CaretakerPapers", "res://assets/models/props/paper_stack.glb", Vector3(2.25, 0.87, -5.85))
	_room_prop("CaretakerBooks", "res://assets/models/props/books_stack.glb", Vector3(2.65, 0.87, -5.95), 0.08)
	_room_prop("ToolCrate", "res://assets/models/furniture/crate_wood_80s.glb", Vector3(5.5, 0.04, -3.2), 0.2)
	_room_prop("CaretakerCalendar", "res://assets/models/props/wall_calendar_august.glb", Vector3(3.8, 1.65, -7.28))
	_room_prop("CaretakerWindow", "res://assets/models/furniture/window_curtains_80s.glb", Vector3(6.18, 1.25, -4.4), -PI / 2.0)

	# 305 — sala abandonada; sofá, mesa baixa e estante, sem objetos de brinquedo.
	_rug("Rug305", Vector3(4.15, 0, -10.7), Vector2(2.8, 2.7), Color(0.27, 0.2, 0.15))
	_floor_furniture("Sofa305", "res://assets/models/polyhaven/sofa_02/sofa_02_1k.gltf",
		Vector3(5.15, 0, -12.3), PI, Vector3(2.0, 0.8, 0.86),
		Vector3(1.08, 1.0, 1.05), -0.12)
	_table("CoffeeTable305", Vector3(3.6, 0, -10.8), Vector2(1.2, 0.65), 0.46)
	_floor_furniture("Shelf305", "res://assets/models/polyhaven/Shelf_01/Shelf_01_1k.gltf",
		Vector3(6.1, 0, -8.35), PI / 2.0, Vector3(0.3, 1.75, 1.18),
		Vector3(1.0, 1.1, 1.05))
	_room_prop("Books305", "res://assets/models/props/books_stack.glb", Vector3(3.45, 0.5, -10.85))
	_room_prop("Lamp305", "res://assets/models/props/table_lamp_80s.glb", Vector3(3.85, 0.48, -10.72))
	_room_prop("Suitcase305", "res://assets/models/furniture/suitcase_open_80s.glb", Vector3(2.05, 0.04, -12.4), 0.38)
	_room_prop("Fan305", "res://assets/models/furniture/standing_fan_80s.glb", Vector3(5.9, 0.0, -8.7), -0.25)
	_room_prop("Photo305", "res://assets/models/props/photo_frame.glb", Vector3(4.0, 1.7, -13.83))
	_room_prop("Calendar305", "res://assets/models/props/wall_calendar_august.glb", Vector3(5.7, 1.65, -13.83))
	_room_prop("Window305", "res://assets/models/furniture/window_curtains_80s.glb", Vector3(6.18, 1.25, -10.6), -PI / 2.0)

	# 303 — sala de jantar modesta, móveis ao redor da mesa e dos recados.
	_rug("Rug303", Vector3(4.05, 0, -18.8), Vector2(2.8, 2.7), Color(0.31, 0.22, 0.16))
	_floor_furniture("Sofa303", "res://assets/models/polyhaven/sofa_02/sofa_02_1k.gltf",
		Vector3(5.3, 0, -21.0), PI, Vector3(2.0, 0.8, 0.86),
		Vector3(1.05, 1.0, 1.02), -0.12)
	_table("Table303", Vector3(3.3, 0, -18.4), Vector2(1.25, 0.75), 0.76, PI / 2.0)
	_floor_furniture("Chair303", "res://assets/models/polyhaven/painted_wooden_chair_02/painted_wooden_chair_02_1k.gltf",
		Vector3(3.25, 0, -19.15), 0.0, Vector3(0.48, 0.82, 0.48),
		Vector3(0.86, 0.94, 0.86))
	_floor_furniture("Bookcase303", "res://assets/models/polyhaven/GothicCabinet_01/GothicCabinet_01_1k.gltf",
		Vector3(6.05, 0, -16.0), PI / 2.0, Vector3(0.48, 1.75, 1.15),
		Vector3(0.85, 1.08, 1.0))
	_room_prop("Papers303", "res://assets/models/props/paper_stack.glb", Vector3(3.0, 0.78, -18.6))
	_room_prop("Lamp303", "res://assets/models/props/table_lamp_80s.glb", Vector3(3.45, 0.78, -18.15))
	_room_prop("Photo303", "res://assets/models/props/photo_frame.glb", Vector3(4.0, 1.68, -22.33))
	_room_prop("Calendar303", "res://assets/models/props/wall_calendar_august.glb", Vector3(5.7, 1.65, -22.33))
	_room_prop("Window303", "res://assets/models/furniture/window_curtains_80s.glb", Vector3(6.18, 1.25, -18.0), -PI / 2.0)

	# 304 — sala de estar estreita com telefone, sofá e mesa ao centro.
	_rug("Rug304", Vector3(0, 0, -34.2), Vector2(3.6, 3.2), Color(0.33, 0.16, 0.13))
	_floor_furniture("Sofa304", "res://assets/models/polyhaven/sofa_02/sofa_02_1k.gltf",
		Vector3(-2.25, 0, -34.8), PI / 2.0, Vector3(2.0, 0.8, 0.86),
		Vector3(1.05, 1.0, 1.0), -0.12)
	_table("PhoneTable", Vector3(0, 0, -35.2), Vector2(1.15, 0.62), 0.78)
	_table("CoffeeTable304", Vector3(-1.3, 0, -33.6), Vector2(1.05, 0.55), 0.44, PI / 2.0)
	_floor_furniture("Armchair304", "res://assets/models/polyhaven/ArmChair_01/ArmChair_01_1k.gltf",
		Vector3(2.05, 0, -33.5), -PI / 2.0, Vector3(0.92, 0.88, 0.85),
		Vector3(1.08, 1.0, 1.0), -0.1)
	_floor_furniture("Cabinet304", "res://assets/models/polyhaven/painted_wooden_cabinet/painted_wooden_cabinet_1k.gltf",
		Vector3(3.7, 0, -36.5), -PI / 2.0, Vector3(0.55, 1.7, 1.3),
		Vector3(0.88, 1.08, 1.0))
	_room_prop("PhoneLamp304", "res://assets/models/props/table_lamp_80s.glb", Vector3(0.34, 0.8, -35.15))
	_room_prop("Books304", "res://assets/models/props/books_stack.glb", Vector3(-1.25, 0.48, -33.6), -0.08)
	_room_prop("Glass304", "res://assets/models/props/glass_tumbler.glb", Vector3(-0.95, 0.48, -33.55))
	_room_prop("Suitcase304", "res://assets/models/furniture/suitcase_open_80s.glb", Vector3(-3.55, 0.04, -32.3), -0.3)
	_room_prop("PhotoWall304", "res://assets/models/props/photo_frame.glb", Vector3(-2.2, 1.68, -38.33))
	_room_prop("Calendar304", "res://assets/models/props/wall_calendar_august.glb", Vector3(2.3, 1.65, -38.33))
	_room_prop("Cross304", "res://assets/models/props/wall_crucifix.glb", Vector3(3.8, 1.65, -34.0), -PI / 2.0)
	_room_prop("Window304", "res://assets/models/furniture/window_curtains_80s.glb", Vector3(4.28, 1.25, -35.8), -PI / 2.0)

func _power_light(light: OmniLight3D) -> OmniLight3D:
	_power_lights.append(light)
	_light_energy[light] = light.light_energy
	return light


func _build_lights() -> void:
	_power_light(LevelKit.ceiling_light(self, Vector3(0, WALL_H - 0.1, -4.6), Color(1, 0.85, 0.68), 1.05, 7.0))
	_flicker = _power_light(LevelKit.ceiling_light(self, Vector3(0, WALL_H - 0.1, -14.5), Color(0.82, 0.9, 1.0), 0.95, 7.0))
	_power_light(LevelKit.ceiling_light(self, Vector3(0, WALL_H - 0.1, -25.0), Color(1, 0.83, 0.66), 1.0, 7.0))
	_power_light(LevelKit.lamp(self, Vector3(-5.1, 0.9, -5.1), Color(1, 0.72, 0.42), 0.68, 4.8))
	_power_light(LevelKit.lamp(self, Vector3(-5.1, 0.9, -12.0), Color(1, 0.72, 0.42), 0.68, 4.8))
	_power_light(LevelKit.lamp(self, Vector3(5.3, 0.9, -5.3), Color(0.9, 0.76, 0.56), 0.62, 4.8))
	_power_light(LevelKit.lamp(self, Vector3(4.8, 0.9, -20.3), Color(1, 0.73, 0.47), 0.66, 4.8))
	_power_light(LevelKit.lamp(self, Vector3(3.85, 0.9, -10.72), Color(1, 0.72, 0.45), 0.62, 4.7))
	LevelKit.lamp(self, Vector3(0, 1.2, -35.2), Color(1, 0.16, 0.09), 0.42, 3.4)

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


func _replace_item_visual(body: Node3D, path: String, scale: Vector3) -> void:
	for child in body.get_children():
		if child is MeshInstance3D:
			body.remove_child(child)
			child.free()
			break
	var visual := LevelKit.model_visual(path)
	visual.name = "Visual"
	visual.scale = scale
	body.add_child(visual)
	_register_room_prop(body, body.position)

func _readable(node_name: String, title: String, body: String, pos: Vector3, size: Vector3) -> Readable:
	var doc := Readable.new()
	doc.name = node_name
	doc.title = title
	doc.body = body
	doc.position = pos
	_add_box_visual(doc, size, _m_paper, size + Vector3(0.12, 0.12, 0.12))
	add_child(doc)
	if node_name == "Diary":
		_replace_item_visual(doc, "res://assets/models/props/open_book.glb", Vector3(0.42, 0.75, 1.0))
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
	if node_name == "Fuse":
		_replace_item_visual(item, "res://assets/models/props/glass_fuse_1980s.glb", Vector3.ONE)
	item.picked.connect(_on_item_picked)
	add_child(item)
	return item


func _searchable(node_name: String, label: String, pos: Vector3, visual_size: Vector3,
		item_id := "", item_name := "", locked_key := "", locked_text := "Trancada.") -> Searchable:
	var searchable := Searchable.new()
	searchable.name = node_name
	searchable.label = label
	searchable.item_id = item_id
	searchable.item_name = item_name
	searchable.locked_key = locked_key
	searchable.locked_text = locked_text
	searchable.position = pos
	_add_box_visual(searchable, visual_size, _m_wood, visual_size + Vector3(0.05, 0.03, 0.05))
	searchable.item_found.connect(_on_searchable_item_found)
	add_child(searchable)
	return searchable


func _build_items() -> void:
	_readable("Notice", "Aviso de interdição", TEXT_NOTICE, Vector3(1.22, 1.48, -1.25), Vector3(0.01, 0.3, 0.21))

	var fragment_03 := _readable("Fragment03", "Ficha de ronda — 301", TEXT_FRAGMENT_03,
		Vector3(-2.65, 0.79, -4.55), Vector3(0.22, 0.015, 0.3))
	fragment_03.read.connect(_on_code_fragment_read.bind("03"))
	_readable("Diary", "Diário — 302", TEXT_DIARY, Vector3(-3.15, 0.64, -11.8), Vector3(0.22, 0.015, 0.3))

	_clue_one = _readable("Fragment1", "Papel no relógio — 302", TEXT_FRAGMENT_1,
		Vector3(-5.8, 1.35, -10.4), Vector3(0.01, 0.28, 0.22))
	_clue_one.visible = false
	_clue_one.collision_layer = 0
	_clue_one.read.connect(_on_code_fragment_read.bind("1"))

	var keeper_note := _readable("CaretakerLog", "Caderno da zeladora",
		"MARTA — 8/8\n\nO ramal toca às 03:17 mesmo quando a central está desligada. O síndico mandou lacrar o 305. Ainda ouço alguém atender do outro lado.",
		Vector3(2.5, 0.86, -5.85), Vector3(0.22, 0.015, 0.3))
	keeper_note.read.connect(func(): session.set_objective("O 303 está lacrado. Reúna a senha espalhada pelo andar."))

	var fragment_seven := _readable("Fragment7", "Bilhete atrás do calendário — 305", TEXT_FRAGMENT_7,
		Vector3(3.2, 0.79, -12.5), Vector3(0.22, 0.015, 0.3))
	fragment_seven.read.connect(_on_code_fragment_read.bind("7"))

	var transcript := _readable("Transcript", "Transcrição da Linha 11 — 303", TEXT_TRANSCRIPT,
		Vector3(3.1, 0.79, -18.3), Vector3(0.22, 0.015, 0.3))

	_searchable("KeyDrawer301", "a gaveta do criado-mudo", Vector3(-3.55, 0.53, -5.35),
		Vector3(0.38, 0.14, 0.045), "chave_gaveta", "Chave pequena")
	_searchable("EmptyWardrobe301", "o armário", Vector3(-2.0, 0.86, -6.1),
		Vector3(0.4, 0.3, 0.045), "", "", "", "Só roupas úmidas e cheiro de fumaça.")
	_searchable("FuseDrawer302", "a gaveta trancada da penteadeira", Vector3(-2.0, 0.62, -8.25),
		Vector3(0.48, 0.17, 0.05), FuseBox.FUSE_ID, "Fusível", "chave_gaveta",
		"A fechadura é pequena. A chave deve estar em outro apartamento.")
	_searchable("EmptyNightstand302", "o criado-mudo", Vector3(-3.15, 0.57, -11.55),
		Vector3(0.34, 0.12, 0.04), "", "", "", "Uma fotografia desbotada e um bilhete molhado.")
	_searchable("CrowbarLocker", "o armário de ferramentas", Vector3(5.8, 0.8, -5.9),
		Vector3(0.42, 0.25, 0.05), "pe_de_cabra", "Pé-de-cabra")
	_searchable("EmptyCrate305", "a caixa de papelão", Vector3(2.45, 0.28, -12.2),
		Vector3(0.42, 0.26, 0.36), "", "", "", "Só jornais grudados pela umidade.")

	var fuse_box := FuseBox.new()
	fuse_box.position = Vector3(-1.21, 1.34, -1.35)
	_add_box_visual(fuse_box, Vector3(0.12, 0.58, 0.42), _m_metal)
	add_child(fuse_box)
	fuse_box.power_restored.connect(_on_power_restored)

	_pickup("Key304", "chave_304", "Chave do 304", Vector3(4.95, 0.79, -20.55),
		Vector3(0.09, 0.012, 0.03), Color(0.75, 0.62, 0.3))

func _build_phone() -> Phone:
	var phone := Phone.new()
	phone.position = Vector3(0, 0.82, -35.2)
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
	led_mat.emission = Color(0.7, 0.04, 0.015)
	led_mat.emission_energy_multiplier = 1.1
	var led := MeshInstance3D.new()
	var led_mesh := SphereMesh.new()
	led_mesh.radius = 0.025
	led_mesh.height = 0.05
	led_mesh.material = led_mat
	led.mesh = led_mesh
	led.position = Vector3(0.08, 0.06, 0.045)
	phone.add_child(led)
	add_child(phone)
	return phone
