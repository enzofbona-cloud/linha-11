extends Node3D
## Protótipo da Fase 3: um andar de prédio do Distrito 11.
## Corredor, dois apartamentos, uma porta trancada e o telefone que toca.
## O cenário é montado por código com blocos (blocagem provisória).

const WALL_H := 2.8
const DOOR_H := 2.1
const T := 0.2 # espessura das paredes

var player: Player
var _hud: GameHud
var _pause: PauseMenu
var _was_captured := false
var _flicker: OmniLight3D
var _time := 0.0

var _m_wall: StandardMaterial3D
var _m_floor: StandardMaterial3D
var _m_ceiling: StandardMaterial3D
var _m_wood: StandardMaterial3D
var _m_metal: StandardMaterial3D
var _m_fabric: StandardMaterial3D


func _ready() -> void:
	_m_wall = LevelKit.material(Color(0.5, 0.48, 0.42), 0.95)
	_m_floor = LevelKit.material(Color(0.2, 0.18, 0.16), 0.8, 0.5)
	_m_ceiling = LevelKit.material(Color(0.36, 0.35, 0.33), 1.0)
	_m_wood = LevelKit.material(Color(0.24, 0.15, 0.09), 0.7, 0.8)
	_m_metal = LevelKit.material(Color(0.28, 0.3, 0.31), 0.5, 0.6)
	_m_metal.metallic = 0.6
	_m_fabric = LevelKit.material(Color(0.25, 0.27, 0.22), 1.0, 1.2)

	_build_environment()
	_build_structure()
	_build_doors()
	_build_furniture()
	_build_lights()
	_build_key()
	var phone := _build_phone()

	player = Player.new()
	player.position = Vector3(0, 0.05, -1.0)
	add_child(player)

	_hud = GameHud.new()
	add_child(_hud)
	player.message.connect(_hud.show_message)
	player.prompt_changed.connect(_hud.set_prompt)
	player.inventory_changed.connect(_hud.set_inventory)

	_pause = PauseMenu.new()
	add_child(_pause)
	_pause.resumed.connect(_resume)
	_pause.quit_to_menu.connect(_quit_to_menu)

	phone.answered.connect(_on_phone_answered)

	add_child(preload("res://game/ui/debug_hud.tscn").instantiate())

	_hud.set_objective("Encontre a origem da chamada.")
	_hud.show_message("Distrito 11 — Edifício Aurora, 3º andar.")
	_capture_mouse()


func _process(delta: float) -> void:
	_time += delta
	if _flicker != null:
		var n := sin(_time * 31.0) * sin(_time * 7.3)
		_flicker.light_energy = 0.9 if n > -0.55 else 0.08

	if get_tree().paused:
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
		if get_tree().paused:
			_resume()
		else:
			_pause_game()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
		_capture_mouse()


func _capture_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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


func _on_phone_answered() -> void:
	_hud.set_objective("Fim do protótipo. Obrigado por testar.")
	_hud.show_message("Fim do protótipo — aperte Esc para voltar ao menu.", 12.0)


# --- construção do cenário ---

func _wall(node_name: String, center_xz: Vector2, size_xz: Vector2, y0 := 0.0, y1 := WALL_H) -> void:
	LevelKit.box(self, node_name,
		Vector3(center_xz.x, (y0 + y1) / 2.0, center_xz.y),
		Vector3(size_xz.x, y1 - y0, size_xz.y), _m_wall)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.005, 0.006, 0.008)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.13, 0.15, 0.2)
	env.ambient_light_energy = 0.22
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.025, 0.03)
	env.fog_density = 0.035
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
	_door("Door303", Vector3(1.3, 0, -10.0), 0, -90)
	_door("Door304", Vector3(-0.5, 0, -16.1), -90, 90, "chave_304",
		"Trancada. A placa diz 304. O telefone toca do outro lado.")


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

	# Corredor: banco e extintor (bloco)
	LevelKit.box(self, "Bench", Vector3(0.95, 0.22, -3.0), Vector3(0.4, 0.44, 1.4), _m_wood)
	LevelKit.box(self, "Cabinet", Vector3(-1.05, 0.5, -13.5), Vector3(0.3, 1.0, 0.8), _m_metal)

	# 304: mesa do telefone, poltrona, armário
	_table("PhoneTable", Vector3(0, 0, -21.2), Vector2(1.2, 0.6))
	LevelKit.box(self, "Armchair", Vector3(-2.2, 0.3, -20.6), Vector3(0.9, 0.6, 0.9), _m_fabric)
	LevelKit.box(self, "ArmchairBack", Vector3(-2.6, 0.75, -20.6), Vector3(0.15, 0.9, 0.9), _m_fabric)
	LevelKit.box(self, "Cupboard", Vector3(2.7, 1.0, -18.5), Vector3(0.5, 2.0, 1.8), _m_wood)


func _build_lights() -> void:
	LevelKit.lamp(self, Vector3(0, 2.6, -2.5), Color(1, 0.85, 0.62), 0.9, 6.0, true)
	_flicker = LevelKit.lamp(self, Vector3(0, 2.6, -10.5), Color(0.8, 0.9, 1.0), 0.9, 6.0)
	LevelKit.lamp(self, Vector3(0, 1.4, -21.0), Color(1, 0.2, 0.12), 0.5, 4.5)


func _build_key() -> void:
	var key := Pickup.new()
	key.name = "Key304"
	key.item_id = "chave_304"
	key.item_name = "Chave do 304"
	key.position = Vector3(4.6, 0.8, -11.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.75, 0.62, 0.3)
	mat.metallic = 0.9
	mat.roughness = 0.3
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.38, 0.12)
	mat.emission_energy_multiplier = 0.35
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.09, 0.012, 0.03)
	box.material = mat
	mesh.mesh = box
	key.add_child(mesh)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.14
	shape.shape = sphere
	key.add_child(shape)
	add_child(key)


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
