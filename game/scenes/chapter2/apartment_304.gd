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
var session: PlaySession


func _ready() -> void:
	_photo_texture = load("res://assets/characters/family_304.png")
	_wall_mat = _wallpaper_material()
	_floor_mat = LevelKit.textured("floor_aged", 0.4, Color(0.56, 0.49, 0.4))
	_wood_mat = LevelKit.textured("wood", 0.8, Color(0.42, 0.32, 0.23))
	_trim_mat = LevelKit.textured("door", 0.8, Color(0.28, 0.23, 0.18))
	_build_environment()
	_build_room()
	_build_furniture()
	_build_evidence()
	_build_puzzle()
	_build_exit()
	_build_lamps()
	_build_audio()
	_build_player_and_ui()


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.005, 0.004)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.29, 0.23)
	env.ambient_light_energy = 0.58
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.fog_enabled = true
	env.fog_light_color = Color(0.045, 0.033, 0.025)
	env.fog_density = 0.013
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 0.78
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)


func _wallpaper_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/characters/wallpaper_304.png")
	mat.albedo_color = Color(0.46, 0.39, 0.32)
	mat.normal_enabled = true
	mat.normal_texture = load("res://assets/textures/wall_aged/normal.jpg")
	mat.normal_scale = 0.24
	mat.roughness_texture = load("res://assets/textures/wall_aged/roughness.jpg")
	mat.roughness = 0.96
	mat.ao_enabled = true
	mat.ao_texture = load("res://assets/textures/wall_aged/ao.jpg")
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(0.38, 0.38, 0.38)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return mat


const POLY := "res://assets/models/polyhaven/"
const FURN := "res://assets/models/furniture/"
const PROP := "res://assets/models/props/"

## Planta: um corredor central (x de -1 a 1) que vai da porta de entrada (z = 5)
## até a porta sem número (z = -29). Os cômodos ficam dos dois lados.
const HALL_WALL_X := 1.1   # centro das paredes do corredor
const OUTER_WALL_X := 5.9  # centro das paredes externas
const ROOM_MID_X := 3.5    # meio dos cômodos
const ENTRY_Z := 4.9
const END_Z := -28.9
const WALL_H := 2.8
const DOOR_H := 2.1

## Vãos nas paredes do corredor: [z do centro, largura]. Do z = -14 em diante
## são portas trancadas: o corredor continua, mas ninguém mora atrás delas.
const LEFT_OPENINGS := [[0.4, 1.8], [-5.6, 1.0], [-11.1, 1.0], [-17.5, 1.0], [-23.5, 1.0]]
const RIGHT_OPENINGS := [[2.4, 1.2], [-4.4, 1.0], [-9.7, 1.0], [-15.5, 1.0], [-20.5, 1.0], [-25.5, 1.0]]
## Paredes que separam um cômodo do outro (z do centro).
const LEFT_PARTITIONS := [-2.7, -8.5, -13.7]
const RIGHT_PARTITIONS := [-1.7, -7.1, -12.3]
const LOCKED_DOOR_TEXTS := [
	"Trancada por dentro. A chave ainda está na fechadura, do outro lado.",
	"Não abre. Alguém encostou um móvel pesado atrás dela.",
	"Trancada. O número foi arrancado da porta.",
	"A maçaneta gira em falso. Do outro lado, um telefone fora do gancho.",
	"Trancada. Tem luz por baixo da porta, e ela apaga quando você chega perto.",
]

var _tv_light: OmniLight3D
var _tv_screen: StandardMaterial3D
var _time := 0.0


func _process(delta: float) -> void:
	# A televisão ficou ligada num canal fora do ar: o brilho treme.
	_time += delta
	if _tv_light != null:
		var flicker := 0.5 + 0.5 * sin(_time * 23.0) * sin(_time * 7.1)
		_tv_light.light_energy = 0.32 + flicker * 0.3
		_tv_screen.emission_energy_multiplier = 0.7 + flicker * 0.7


func _build_room() -> void:
	var ceiling_mat := LevelKit.textured("ceiling", 0.55, Color(0.74, 0.68, 0.59))
	# Piso e teto em pedaços: cada pedaço recebe poucas luzes, o que mantém o
	# jogo leve no navegador (limite de luzes por objeto).
	var z := 5.2
	while z > -33.0:
		_box("HallFloor", Vector3(0, -0.11, z - 2.4), Vector3(2.4, 0.22, 4.8), _floor_mat)
		_box("HallCeiling", Vector3(0, 2.9, z - 2.4), Vector3(2.4, 0.18, 4.8), ceiling_mat)
		z -= 4.8
	for side in [-1.0, 1.0]:
		var bounds: Array = [ENTRY_Z + 0.2]
		bounds.append_array(LEFT_PARTITIONS if side < 0.0 else RIGHT_PARTITIONS)
		for i in bounds.size() - 1:
			var length: float = bounds[i] - bounds[i + 1]
			var mid: float = (bounds[i] + bounds[i + 1]) / 2.0
			_box("RoomFloor", Vector3(side * 3.6, -0.11, mid), Vector3(5.0, 0.22, length), _floor_mat)
			_box("RoomCeiling", Vector3(side * 3.6, 2.9, mid), Vector3(5.0, 0.18, length), ceiling_mat)
			_box("OuterWall", Vector3(side * OUTER_WALL_X, WALL_H / 2.0, mid), Vector3(0.2, WALL_H, length), _wall_mat)
			_box("Partition", Vector3(side * ROOM_MID_X, WALL_H / 2.0, bounds[i + 1]), Vector3(4.8, WALL_H, 0.2), _wall_mat)
		_hall_wall(side, LEFT_OPENINGS if side < 0.0 else RIGHT_OPENINGS)
		# parede da entrada e parede do fundo, cada uma com a sua porta no meio
		_box("EntryWall", Vector3(side * 3.25, WALL_H / 2.0, 5), Vector3(5.5, WALL_H, 0.2), _wall_mat)
		_box("FarWall", Vector3(side * 0.85, WALL_H / 2.0, -29), Vector3(0.7, WALL_H, 0.2), _wall_mat)
	_box("EntryLintel", Vector3(0, 2.45, 5), Vector3(1.0, 0.7, 0.2), _wall_mat)
	_box("FarLintel", Vector3(0, 2.45, -29), Vector3(1.0, 0.7, 0.2), _wall_mat)
	var entry_door := Door.new()
	entry_door.name = "Door304Entry"
	entry_door.position = Vector3(-0.5, 0, 5)
	entry_door.rotation_degrees.y = -90
	entry_door.open_angle_deg = 90
	add_child(entry_door)


## Parede de um lado do corredor, com os vãos das portas, rodapé e batentes.
func _hall_wall(side: float, openings: Array) -> void:
	var x := side * HALL_WALL_X
	var cursor := ENTRY_Z + 0.1
	var locked := 0
	for opening in openings:
		var center: float = opening[0]
		var width: float = opening[1]
		_hall_wall_piece(x, side, cursor, center + width / 2.0)
		_box("HallLintel", Vector3(x, (DOOR_H + WALL_H) / 2.0, center), Vector3(0.2, WALL_H - DOOR_H, width), _wall_mat)
		for edge in [-1.0, 1.0]:
			_box("DoorJamb", Vector3(x, DOOR_H / 2.0, center + edge * (width / 2.0 - 0.03)), Vector3(0.26, DOOR_H, 0.06), _trim_mat, false)
		_box("DoorHead", Vector3(x, DOOR_H + 0.03, center), Vector3(0.26, 0.06, width), _trim_mat, false)
		if center < -14.0:
			var door := Door.new()
			door.name = "LockedDoor"
			door.position = Vector3(x, 0, center + 0.5)
			door.sealed = true
			door.sealed_text = LOCKED_DOOR_TEXTS[(locked + (0 if side < 0.0 else 2)) % LOCKED_DOOR_TEXTS.size()]
			add_child(door)
			# fundo escuro atrás da porta, para não aparecer vão nenhum
			_box("DoorBacking", Vector3(x + side * 0.16, DOOR_H / 2.0, center), Vector3(0.06, DOOR_H, width), _trim_mat)
			locked += 1
		cursor = center - width / 2.0
	_hall_wall_piece(x, side, cursor, END_Z - 0.1)


func _hall_wall_piece(x: float, side: float, z_from: float, z_to: float) -> void:
	var length := z_from - z_to
	if length <= 0.01:
		return
	var mid := (z_from + z_to) / 2.0
	_box("HallWall", Vector3(x, WALL_H / 2.0, mid), Vector3(0.2, WALL_H, length), _wall_mat)
	_box("Baseboard", Vector3(x - side * 0.11, 0.07, mid), Vector3(0.03, 0.14, length), _trim_mat, false)
	_box("Baseboard", Vector3(x + side * 0.11, 0.07, mid), Vector3(0.03, 0.14, length), _trim_mat, false)


# --- mobília ---

func _build_furniture() -> void:
	_furnish_hall()
	_furnish_living_room()
	_furnish_dining_room()
	_furnish_master_bedroom()
	_furnish_boys_bedroom()
	_furnish_office()
	_furnish_storage()


## Corredor: aparador de entrada, passadeira, quadros, e a bagunça de quem
## saiu às pressas, que vai aumentando conforme o corredor não acaba.
func _furnish_hall() -> void:
	_table("ClueTable", Vector3(0.78, 0, 0.5), Vector2(0.95, 0.36), 0.8, PI / 2.0)
	_prop("HallKeysBooks", PROP + "books_stack.glb", Vector3(0.8, 0.8, 0.82), 0.3)
	_prop("HallEntryLamp", PROP + "table_lamp_80s.glb", Vector3(0.82, 0.8, 0.16))
	_prop("HallEntrySlippers", PROP + "slippers_pair.glb", Vector3(-0.72, 0.0, 4.2), 0.2)
	_prop("HallEntryCalendar", PROP + "wall_calendar_august.glb", Vector3(0.97, 1.65, -0.7), -PI / 2.0)
	_rug("HallRunnerA", Vector3(0, 0.02, -4.6), Vector3(1.1, 0.04, 17.0), Color(0.33, 0.15, 0.12))
	_rug("HallRunnerB", Vector3(0, 0.02, -21.4), Vector3(1.1, 0.04, 13.0), Color(0.3, 0.14, 0.12))
	# relógio parado às 03h17, no trecho entre os quartos
	_box("FrozenClock", Vector3(0.96, 1.9, -6.6), Vector3(0.06, 0.4, 0.4), _trim_mat, false)
	_box("ClockFace", Vector3(0.925, 1.9, -6.6), Vector3(0.012, 0.32, 0.32), LevelKit.material(Color(0.78, 0.72, 0.58)), false)
	_box("ClockHands", Vector3(0.915, 1.93, -6.57), Vector3(0.01, 0.13, 0.02), LevelKit.material(Color(0.05, 0.04, 0.03)), false)
	var frames := [
		[-1.0, 3.2], [-1.0, -2.0], [1.0, -1.6], [-1.0, -3.6], [1.0, -7.4], [-1.0, -8.2],
		[1.0, -12.4], [-1.0, -14.6], [1.0, -17.8], [-1.0, -20.4], [1.0, -23.7], [-1.0, -26.2],
	]
	for i in frames.size():
		var side: float = frames[i][0]
		var model: String = "wall_crucifix.glb" if i % 5 == 4 else "photo_frame.glb"
		_prop("HallFrame%d" % i, PROP + model, Vector3(side * 0.97, 1.68, frames[i][1]), -side * PI / 2.0)
	# o trecho dos quartos: coisas largadas no caminho
	_solid("HallBench", FURN + "bench_wood_80s.glb", Vector3(0.78, 0, -13.6), PI / 2.0, Vector3(1.34, 0.5, 0.38))
	_prop("HallBenchClothes", PROP + "clothes_pile.glb", Vector3(0.78, 0.5, -13.4), 0.4)
	_prop("HallToy", PROP + "toy_truck.glb", Vector3(-0.55, 0.0, -3.1), 0.9)
	# depois dos quartos, o corredor continua: caixas, malas e papéis no chão
	_solid("HallCrateA", FURN + "crate_wood_80s.glb", Vector3(-0.7, 0, -16.2), 0.15, Vector3(0.53, 0.41, 0.44))
	_solid("HallCrateB", FURN + "crate_wood_80s.glb", Vector3(-0.68, 0.41, -16.25), -0.3, Vector3(0.53, 0.41, 0.44))
	_prop("HallSuitcase", FURN + "suitcase_open_80s.glb", Vector3(0.6, 0.0, -18.9), 0.5)
	_solid("HallFallenChair", POLY + "painted_wooden_chair_02/painted_wooden_chair_02_1k.gltf",
		Vector3(-0.55, 0, -21.6), 2.2, Vector3(0.48, 0.86, 0.48), Vector3(0.75, 0.68, 0.73))
	_solid("HallShelf", FURN + "bookcase_short_80s.glb", Vector3(0.78, 0, -22.6), -PI / 2.0, Vector3(0.55, 1.35, 0.4))
	_prop("HallShelfBooks", PROP + "books_stack.glb", Vector3(0.78, 1.35, -22.6), 0.2)
	_prop("HallSlippersFar", PROP + "slippers_pair.glb", Vector3(-0.7, 0.0, -24.2), -1.4)
	_solid("HallCrateC", FURN + "crate_wood_80s.glb", Vector3(0.7, 0, -27.3), 0.5, Vector3(0.53, 0.41, 0.44))
	var rng := RandomNumberGenerator.new()
	rng.seed = 304
	for i in 16:
		_prop("HallLoosePaper%d" % i, PROP + "paper_stack.glb",
			Vector3(rng.randf_range(-0.8, 0.8), 0.045, rng.randf_range(-27.5, -15.0)), rng.randf_range(0.0, TAU))


## Sala de estar (frente, à esquerda): sofá de frente para a TV, mesa de centro
## no tapete, poltrona ao lado; no fundo, o canto de leitura com as estantes.
func _furnish_living_room() -> void:
	_rug("LivingRug304", Vector3(-3.7, 0.02, 3.2), Vector3(3.0, 0.04, 3.2), Color(0.36, 0.17, 0.13))
	var sofa := _solid("Sofa304", POLY + "sofa_02/sofa_02_1k.gltf",
		Vector3(-5.3, 0, 3.2), PI / 2.0, Vector3(2.1, 0.8, 0.9), Vector3(1.16, 1.18, 1.0))
	sofa.add_to_group("room_props_ch2_living")
	_table("CoffeeTable304", Vector3(-3.95, 0, 3.2), Vector2(1.1, 0.55), 0.42, PI / 2.0)
	_prop("CoffeeCup", PROP + "glass_tumbler.glb", Vector3(-3.9, 0.42, 2.9))
	_prop("CoffeeBooks", PROP + "books_stack.glb", Vector3(-4.0, 0.42, 3.5), 0.5)
	_prop("CoffeeMedicine", PROP + "medicine_blister.glb", Vector3(-3.85, 0.43, 3.15), 0.7)
	_solid("ArmchairTv304", POLY + "ArmChair_01/ArmChair_01_1k.gltf",
		Vector3(-3.9, 0, 4.4), PI + 0.25, Vector3(0.85, 0.9, 0.77))
	_prop("SofaClothes", PROP + "clothes_pile.glb", Vector3(-5.25, 0.5, 3.8), 1.3)
	_prop("SofaSlippers", PROP + "slippers_pair.glb", Vector3(-4.6, 0.0, 2.6), 1.5)
	# mesinha ao lado do sofá: abajur e o telefone grave
	_nightstand("PhoneTableGrave", -5.5, 1.75, PI / 2.0)
	_prop("LampGraveTable", PROP + "table_lamp_80s.glb", Vector3(-5.6, 0.56, 1.62))
	# televisão sobre o aparador, encostada na parede do corredor
	_solid("TvSideboard304", FURN + "sideboard_80s.glb", Vector3(-1.5, 0, 3.2), -PI / 2.0, Vector3(1.46, 0.84, 0.57))
	_tv(Vector3(-1.52, 0.84, 3.2), -PI / 2.0)
	_prop("TvPhoto", PROP + "photo_frame.glb", Vector3(-1.45, 1.03, 3.8), -PI / 2.0 + 0.3)
	_prop("TvClock", PROP + "alarm_clock_analog.glb", Vector3(-1.5, 0.84, 2.62), -PI / 2.0)
	_solid("LivingFan304", FURN + "standing_fan_80s.glb", Vector3(-1.7, 0, 4.45), -2.4, Vector3(0.5, 1.57, 0.45))
	_prop("LivingCalendar", PROP + "wall_calendar_august.glb", Vector3(-3.0, 1.7, 4.87), PI)
	# cômoda sob a fotografia da família
	_cabinet("PhotoCabinet304", -5.5, -0.6, PI / 2.0)
	_prop("CabinetPerfume", PROP + "perfume_bottle.glb", Vector3(-5.55, 0.9, -0.95))
	_prop("CabinetPapers", PROP + "paper_stack.glb", Vector3(-5.5, 0.9, -0.3), 0.4)
	# canto de leitura no fundo da sala
	_shelf("LivingShelfA", -5.2, -2.47, 0.0)
	_shelf("LivingShelfB", -4.15, -2.47, 0.0)
	_prop("ShelfBooksA", PROP + "books_stack.glb", Vector3(-5.2, 1.05, -2.42), 0.1)
	_prop("ShelfBooksB", PROP + "books_stack.glb", Vector3(-4.2, 1.52, -2.42), -0.1)
	_prop("ShelfBooksC", PROP + "books_stack.glb", Vector3(-4.0, 0.59, -2.42), 0.2)
	_solid("ReadingChair304", POLY + "ArmChair_01/ArmChair_01_1k.gltf",
		Vector3(-2.2, 0, -1.9), -0.75, Vector3(0.85, 0.9, 0.77))
	_solid("ReadingStool", FURN + "crate_wood_80s.glb", Vector3(-3.1, 0, -2.2), 0.1, Vector3(0.53, 0.41, 0.44))
	_prop("ReadingBook", PROP + "open_book.glb", Vector3(-3.1, 0.43, -2.2), 0.6)
	_rug("ReadingRug", Vector3(-3.2, 0.02, -1.4), Vector3(2.6, 0.04, 1.8), Color(0.28, 0.24, 0.17))
	_prop("LivingCrucifix", PROP + "wall_crucifix.glb", Vector3(-1.23, 1.8, -1.6), -PI / 2.0)


## Sala de jantar (frente, à direita): mesa posta para quatro no centro,
## cristaleira, e o aparador onde ficou o gravador.
func _furnish_dining_room() -> void:
	_rug("DiningRug304", Vector3(3.6, 0.02, 1.4), Vector3(3.0, 0.04, 2.6), Color(0.3, 0.22, 0.15))
	_table("DiningTable304", Vector3(3.6, 0, 1.4), Vector2(1.7, 0.9), 0.76)
	_chair("DiningChairA", 3.15, 0.72, 0.0)
	_chair("DiningChairB", 4.05, 0.7, 0.12)
	_chair("DiningChairC", 3.15, 2.08, PI)
	_chair("DiningChairD", 4.2, 2.3, PI - 0.5) # puxada, como se alguém tivesse levantado
	_prop("DiningGlassA", PROP + "glass_tumbler.glb", Vector3(3.2, 0.76, 1.15))
	_prop("DiningGlassB", PROP + "glass_tumbler.glb", Vector3(4.0, 0.76, 1.62))
	_prop("DiningPapers", PROP + "paper_stack.glb", Vector3(3.55, 0.76, 1.45), 0.3)
	_prop("DiningMedicine", PROP + "medicine_blister.glb", Vector3(4.15, 0.77, 1.2), 0.2)
	# aparador encostado na parede de fora, com a fita
	_solid("SideboardTape", FURN + "sideboard_80s.glb", Vector3(5.5, 0, -0.2), -PI / 2.0, Vector3(1.46, 0.84, 0.57))
	_prop("PaperSideboard304", PROP + "paper_stack.glb", Vector3(5.5, 0.84, -0.7), 0.2)
	_prop("SideboardFrame", PROP + "photo_frame.glb", Vector3(5.62, 1.03, 0.3), -PI / 2.0 - 0.2)
	_wardrobe("ChinaCabinet304", 4.3, 4.5, PI)
	_prop("ChinaShoebox", PROP + "shoebox_pair.glb", Vector3(4.3, 2.0, 4.5), 0.1)
	_cabinet("DiningCabinet", 2.2, -1.34, 0.0)
	_prop("DiningCabinetLamp", PROP + "table_lamp_80s.glb", Vector3(2.0, 0.9, -1.3))
	_prop("DiningCabinetBooks", PROP + "books_stack.glb", Vector3(2.45, 0.9, -1.3), -0.2)
	_solid("DiningCrate", FURN + "crate_wood_80s.glb", Vector3(5.35, 0, -1.25), 0.2, Vector3(0.53, 0.41, 0.44))
	_solid("DiningFan", FURN + "standing_fan_80s.glb", Vector3(1.75, 0, 4.4), 2.5, Vector3(0.5, 1.57, 0.45))
	_prop("FamilyCalendar304", PROP + "wall_calendar_august.glb", Vector3(5.77, 1.7, 2.2), -PI / 2.0)
	_prop("DiningCrucifix", PROP + "wall_crucifix.glb", Vector3(3.9, 1.85, -1.57), 0.0)
	_prop("DiningPhoto", PROP + "photo_frame.glb", Vector3(5.77, 1.65, -0.2), -PI / 2.0)


## Quarto do casal (meio, à esquerda): cama de frente para a porta, um
## criado-mudo de cada lado, guarda-roupa e penteadeira.
func _furnish_master_bedroom() -> void:
	_rug("BedroomRug304", Vector3(-3.3, 0.02, -5.6), Vector3(2.0, 0.04, 3.0), Color(0.34, 0.2, 0.16))
	_bed("BedroomBed304", -4.72, -5.6, 1.5)
	_nightstand("BedroomNightstand304", -5.5, -4.5, PI / 2.0)
	_nightstand("BedroomNightstandB", -5.5, -6.7, PI / 2.0)
	_prop("BedLamp304", PROP + "table_lamp_80s.glb", Vector3(-5.55, 0.56, -6.72))
	_prop("BedClock304", PROP + "alarm_clock_analog.glb", Vector3(-5.38, 0.56, -6.55), PI / 2.0)
	_prop("BedGlass", PROP + "glass_tumbler.glb", Vector3(-5.62, 0.56, -4.3))
	_prop("BedroomClothes304", PROP + "clothes_pile.glb", Vector3(-4.2, 0.52, -5.9), 0.9)
	_prop("BedroomSlippers304", PROP + "slippers_pair.glb", Vector3(-4.3, 0.0, -4.6), 0.3)
	_prop("BedCrucifix", PROP + "wall_crucifix.glb", Vector3(-5.77, 1.75, -5.6), PI / 2.0)
	_wardrobe("Wardrobe304", -3.9, -8.07, 0.0)
	_prop("WardrobeShoebox", PROP + "shoebox_pair.glb", Vector3(-3.9, 2.0, -8.05), 0.2)
	_prop("BedroomSuitcase", FURN + "suitcase_open_80s.glb", Vector3(-2.2, 0.0, -7.6), 0.5)
	_solid("BedroomDresser304", FURN + "dresser_mirror_80s.glb", Vector3(-3.7, 0, -3.1), PI,
		Vector3(0.93, 0.9, 0.54), Vector3.ONE, -0.45)
	_prop("DresserPerfume", PROP + "perfume_bottle.glb", Vector3(-3.95, 0.9, -3.12))
	_prop("DresserComb", PROP + "comb.glb", Vector3(-3.5, 1.0, -3.1), 0.4)
	_chair("DresserChair", -3.7, -3.75, 0.0)
	_prop("BedroomPhoto304", PROP + "photo_frame.glb", Vector3(-1.23, 1.7, -3.9), -PI / 2.0)
	_prop("BedroomCalendar304", PROP + "wall_calendar_august.glb", Vector3(-1.23, 1.7, -7.4), -PI / 2.0)
	_window("BedroomWindow", -5.72, -7.75, PI / 2.0)


## Quarto do menino (meio, à direita): cama de solteiro no canto, escrivaninha,
## brinquedos no tapete.
func _furnish_boys_bedroom() -> void:
	_rug("BoyRug", Vector3(3.4, 0.02, -4.4), Vector3(2.2, 0.04, 2.4), Color(0.2, 0.26, 0.3))
	_bed("BoyBed", 4.72, -6.42, 1.0, true)
	_nightstand("BoyNightstand", 5.5, -5.5, -PI / 2.0)
	_prop("BoyLamp", PROP + "table_lamp_80s.glb", Vector3(5.55, 0.56, -5.5))
	_prop("BoyClothes", PROP + "clothes_pile.glb", Vector3(4.3, 0.52, -6.4), 0.3)
	_table("BoyDesk", Vector3(4.5, 0, -2.2), Vector2(1.2, 0.6), 0.72)
	_chair("BoyDeskChair", 4.4, -2.95, 0.3)
	_prop("BoyDeskBook", PROP + "open_book.glb", Vector3(4.4, 0.73, -2.2), 0.1)
	_prop("BoyDeskPapers", PROP + "paper_stack.glb", Vector3(4.9, 0.72, -2.15), 0.5)
	_prop("BoyDeskTruck", PROP + "toy_truck.glb", Vector3(4.0, 0.72, -2.1), 0.7)
	_solid("BoyBookcase", FURN + "bookcase_short_80s.glb", Vector3(2.0, 0, -2.05), 0.0, Vector3(0.55, 1.35, 0.4))
	_prop("BoyBookcaseBooks", PROP + "books_stack.glb", Vector3(2.0, 1.35, -2.05), 0.3)
	_prop("BoyBookcaseClock", PROP + "alarm_clock_analog.glb", Vector3(2.15, 1.35, -2.0))
	_cabinet("BoyToyChest", 5.5, -3.9, -PI / 2.0)
	_prop("BoyChestShoebox", PROP + "shoebox_pair.glb", Vector3(5.5, 0.9, -3.9), 1.4)
	_prop("BoyTruckA", PROP + "toy_truck.glb", Vector3(3.2, 0.04, -4.1), 2.1)
	_prop("BoyTruckB", PROP + "toy_truck.glb", Vector3(3.8, 0.04, -4.9), 0.4)
	_prop("BoyFloorBook", PROP + "open_book.glb", Vector3(2.9, 0.06, -4.9), 1.0)
	_prop("BoySlippers", PROP + "slippers_pair.glb", Vector3(3.5, 0.0, -5.9), 1.6)
	_prop("BoyCalendar", PROP + "wall_calendar_august.glb", Vector3(5.77, 1.65, -2.6), -PI / 2.0)
	_prop("BoyPhoto", PROP + "photo_frame.glb", Vector3(3.2, 1.7, -6.97), 0.0)
	_prop("BoyCrucifix", PROP + "wall_crucifix.glb", Vector3(4.7, 1.8, -6.97), 0.0)


## Escritório (fundo, à esquerda): escrivaninha com o terceiro telefone,
## estantes cobrindo as paredes, poltrona.
func _furnish_office() -> void:
	_rug("OfficeRug", Vector3(-3.6, 0.02, -11.1), Vector3(2.6, 0.04, 2.6), Color(0.26, 0.2, 0.15))
	_table("PhoneTableMid", Vector3(-5.38, 0, -11.1), Vector2(1.5, 0.7), 0.76, PI / 2.0)
	_chair("OfficeChair", -4.6, -10.95, -PI / 2.0 + 0.2)
	_prop("OfficeLamp", PROP + "table_lamp_80s.glb", Vector3(-5.5, 0.76, -10.55))
	_prop("OfficePapers", PROP + "paper_stack.glb", Vector3(-5.3, 0.76, -11.2), 0.3)
	_prop("OfficeBooks", PROP + "books_stack.glb", Vector3(-5.5, 0.76, -10.9), 0.2)
	_prop("OfficeGlass", PROP + "glass_tumbler.glb", Vector3(-5.15, 0.76, -10.7))
	_shelf("OfficeShelfA", -5.2, -13.47, 0.0)
	_shelf("OfficeShelfB", -4.15, -13.47, 0.0)
	_shelf("OfficeShelfC", -3.1, -13.47, 0.0)
	for i in 3:
		_prop("OfficeShelfBooks%d" % i, PROP + "books_stack.glb", Vector3(-5.2 + i * 1.05, [1.05, 1.52, 0.59][i], -13.42), 0.1 * i)
		_prop("OfficeShelfPapers%d" % i, PROP + "paper_stack.glb", Vector3(-5.1 + i * 1.05, [0.59, 1.05, 1.52][i], -13.42), -0.2 * i)
	_solid("OfficeMetalShelf", FURN + "metal_shelf_80s.glb", Vector3(-4.0, 0, -8.82), PI, Vector3(1.49, 1.83, 0.4))
	_prop("MetalShelfBox", PROP + "shoebox_pair.glb", Vector3(-4.3, 0.92, -8.82), 0.1)
	_prop("MetalShelfBooks", PROP + "books_stack.glb", Vector3(-3.7, 1.38, -8.82), 0.3)
	_solid("OfficeArmchair", POLY + "ArmChair_01/ArmChair_01_1k.gltf",
		Vector3(-1.9, 0, -12.9), -2.3, Vector3(0.85, 0.9, 0.77))
	_solid("OfficeCrate", FURN + "crate_wood_80s.glb", Vector3(-2.0, 0, -8.9), 0.3, Vector3(0.53, 0.41, 0.44))
	_prop("OfficeCratePapers", PROP + "paper_stack.glb", Vector3(-2.0, 0.42, -8.9), 0.8)
	_prop("OfficeCalendar", PROP + "wall_calendar_august.glb", Vector3(-5.77, 1.75, -9.6), PI / 2.0)
	_prop("OfficePhoto", PROP + "photo_frame.glb", Vector3(-5.77, 1.7, -12.4), PI / 2.0)
	_prop("OfficeFloorPapers", PROP + "paper_stack.glb", Vector3(-3.4, 0.045, -12.2), 1.1)


## Depósito (fundo, à direita): sem luz, tudo empilhado contra as paredes.
func _furnish_storage() -> void:
	_solid("StorageShelf", FURN + "metal_shelf_80s.glb", Vector3(5.55, 0, -9.7), -PI / 2.0, Vector3(1.49, 1.83, 0.4))
	_prop("StorageShelfBoxA", PROP + "shoebox_pair.glb", Vector3(5.55, 0.92, -9.4), 1.5)
	_prop("StorageShelfBoxB", PROP + "shoebox_pair.glb", Vector3(5.55, 1.38, -10.0), 1.6)
	_prop("StorageShelfBooks", PROP + "books_stack.glb", Vector3(5.55, 0.46, -9.9), 1.2)
	_wardrobe("StorageWardrobe", 4.2, -7.53, PI)
	_solid("StorageArmchair", FURN + "armchair_80s.glb", Vector3(2.0, 0, -7.75), PI - 0.4, Vector3(0.99, 0.9, 0.78))
	_prop("StorageArmchairClothes", PROP + "clothes_pile.glb", Vector3(2.0, 0.5, -7.8), 0.6)
	var crates := [
		[4.9, 0.0, -11.85, 0.1], [4.35, 0.0, -11.9, -0.15], [4.65, 0.41, -11.88, 0.4],
		[3.75, 0.0, -11.9, 0.2], [5.4, 0.0, -11.2, 1.3],
	]
	for i in crates.size():
		_solid("StorageCrate%d" % i, FURN + "crate_wood_80s.glb",
			Vector3(crates[i][0], crates[i][1], crates[i][2]), crates[i][3], Vector3(0.53, 0.41, 0.44))
	_prop("StorageSuitcaseA", FURN + "suitcase_open_80s.glb", Vector3(1.75, 0.0, -10.9), 0.3)
	_solid("StorageBench", FURN + "bench_wood_80s.glb", Vector3(2.6, 0, -11.98), 0.0, Vector3(1.34, 0.5, 0.38))
	_prop("StorageBenchBooks", PROP + "books_stack.glb", Vector3(2.9, 0.5, -11.98), 0.4)
	_solid("StorageFan", FURN + "standing_fan_80s.glb", Vector3(5.4, 0, -8.0), -2.0, Vector3(0.5, 1.57, 0.45))
	_prop("StorageToy", PROP + "toy_truck.glb", Vector3(3.6, 0.04, -10.4), 2.6)
	_prop("StoragePhoto", PROP + "photo_frame.glb", Vector3(3.4, 0.2, -12.14), 0.0)


# --- peças de mobília ---

## Móvel com colisão. `floor_pos` é o ponto do chão embaixo do centro do móvel;
## `size` é a caixa de colisão (largura, altura, profundidade) antes de girar.
func _solid(node_name: String, path: String, floor_pos: Vector3, yaw: float, size: Vector3,
		scale := Vector3.ONE, min_y := 0.0, visual_z := 0.0) -> StaticBody3D:
	var body := LevelKit.model(self, node_name, path, floor_pos + Vector3(0, size.y / 2.0, 0), yaw, size)
	var visual := body.get_node("Visual") as Node3D
	visual.scale = scale
	visual.position = Vector3(0, -size.y / 2.0 - min_y * scale.y, visual_z)
	_register_room_prop(body, floor_pos)
	return body


## Objeto pequeno, sem colisão (livros, copos, quadros).
func _prop(node_name: String, path: String, pos: Vector3, yaw := 0.0, scale := Vector3.ONE) -> Node3D:
	var prop := Node3D.new()
	prop.name = node_name
	prop.position = pos
	prop.rotation.y = yaw
	prop.scale = scale
	prop.add_child(LevelKit.model_visual(path))
	_register_room_prop(prop, pos)
	add_child(prop)
	return prop


func _table(prefix: String, floor_pos: Vector3, size: Vector2, height: float, yaw := 0.0) -> StaticBody3D:
	return _solid(prefix, POLY + "WoodenTable_01/WoodenTable_01_1k.gltf", floor_pos, yaw,
		Vector3(size.x, height, size.y), Vector3(size.x / 1.799648, height / 0.548849, size.y / 0.657175))


func _chair(node_name: String, x: float, z: float, yaw: float) -> StaticBody3D:
	return _solid(node_name, POLY + "painted_wooden_chair_02/painted_wooden_chair_02_1k.gltf",
		Vector3(x, 0, z), yaw, Vector3(0.48, 0.86, 0.48), Vector3(0.75, 0.68, 0.73))


func _nightstand(node_name: String, x: float, z: float, yaw: float) -> StaticBody3D:
	return _solid(node_name, POLY + "painted_wooden_nightstand/painted_wooden_nightstand_1k.gltf",
		Vector3(x, 0, z), yaw, Vector3(0.45, 0.56, 0.45), Vector3(0.9, 0.91, 0.88))


func _cabinet(node_name: String, x: float, z: float, yaw: float) -> StaticBody3D:
	return _solid(node_name, POLY + "painted_wooden_cabinet/painted_wooden_cabinet_1k.gltf",
		Vector3(x, 0, z), yaw, Vector3(0.95, 0.9, 0.5), Vector3(0.8, 0.76, 0.81))


func _wardrobe(node_name: String, x: float, z: float, yaw: float) -> StaticBody3D:
	return _solid(node_name, POLY + "GothicCabinet_01/GothicCabinet_01_1k.gltf",
		Vector3(x, 0, z), yaw, Vector3(1.6, 2.0, 0.6), Vector3(0.93, 0.85, 0.53))


## Estante alta e rasa; (x, z) é o centro dela, já encostada na parede.
func _shelf(node_name: String, x: float, z: float, yaw: float) -> StaticBody3D:
	return _solid(node_name, POLY + "Shelf_01/Shelf_01_1k.gltf",
		Vector3(x, 0, z), yaw, Vector3(1.0, 2.08, 0.26), Vector3.ONE, 0.0, -0.13)


## Cama com a cabeceira para o lado de fora do apartamento. `width` 1.0 é de
## solteiro; 1.5 vira cama de casal.
func _bed(node_name: String, x: float, z: float, width: float, head_on_right := false) -> void:
	var bed := _solid(node_name, POLY + "vintage_day_bed/vintage_day_bed_1k.gltf",
		Vector3(x, 0, z), 0.0, Vector3(1.9, 0.5, 1.0 * width), Vector3(0.96, 1.0, 1.15 * width))
	LevelKit.tint_model_surfaces(bed.get_node("Visual"), Color(0.46, 0.41, 0.34), 0.96)
	var head_x := x + (0.98 if head_on_right else -0.98)
	_solid(node_name + "Headboard", FURN + "headboard_80s.glb", Vector3(head_x, 0, z), 0.0,
		Vector3(0.1, 1.1, 1.0 * width), Vector3(1.0, 1.06, width), -0.51)


func _window(node_name: String, x: float, z: float, yaw: float) -> void:
	var window := LevelKit.model(self, node_name, FURN + "window_curtains_80s.glb",
		Vector3(x, 1.45, z), yaw, Vector3(1.46, 1.45, 0.08))
	_register_room_prop(window, window.position)


## Televisão de tubo, ligada num canal fora do ar.
func _tv(pos: Vector3, yaw: float) -> void:
	var tv := Node3D.new()
	tv.name = "Television304"
	tv.position = pos
	tv.rotation.y = yaw
	add_child(tv)
	LevelKit.box(tv, "TvCase", Vector3(0, 0.24, 0), Vector3(0.66, 0.48, 0.44), _wood_mat, false)
	LevelKit.box(tv, "TvBezel", Vector3(-0.06, 0.25, 0.222), Vector3(0.46, 0.38, 0.012), LevelKit.material(Color(0.03, 0.03, 0.03), 0.4), false)
	_tv_screen = StandardMaterial3D.new()
	_tv_screen.albedo_color = Color(0.2, 0.24, 0.27)
	_tv_screen.albedo_texture = LevelKit.grime()
	_tv_screen.roughness = 0.2
	_tv_screen.emission_enabled = true
	_tv_screen.emission = Color(0.52, 0.62, 0.72)
	_tv_screen.emission_texture = LevelKit.grime()
	LevelKit.box(tv, "TvScreen", Vector3(-0.06, 0.25, 0.23), Vector3(0.4, 0.32, 0.012), _tv_screen, false)
	LevelKit.box(tv, "TvPanel", Vector3(0.24, 0.25, 0.222), Vector3(0.1, 0.38, 0.012), LevelKit.material(Color(0.2, 0.17, 0.13), 0.5), false)
	for i in 2:
		LevelKit.box(tv, "TvKnob", Vector3(0.24, 0.36 - i * 0.12, 0.235), Vector3(0.05, 0.05, 0.02), LevelKit.material(Color(0.5, 0.46, 0.38), 0.4), false)
	for sx in [-1.0, 1.0]:
		var antenna := LevelKit.box(tv, "TvAntenna", Vector3(sx * 0.12, 0.7, -0.05), Vector3(0.012, 0.46, 0.012), LevelKit.material(Color(0.6, 0.6, 0.6), 0.3), false)
		antenna.rotation.z = -sx * 0.45
	_tv_light = LevelKit.lamp(self, pos + Vector3(-0.9, 0.3, 0), Color(0.55, 0.68, 1.0), 0.5, 4.5, false)
	_tv_light.name = "TvGlow"
	var hiss := SoundKit.player_3d(tv, SoundKit.static_noise(), 5.0, -30.0)
	hiss.position.y = 0.25
	hiss.play()


func _register_room_prop(node: Node, pos: Vector3) -> void:
	node.add_to_group("room_props_chapter2")
	if absf(pos.x) < 1.1:
		node.add_to_group("room_props_ch2_hall")
	elif pos.x < 0.0:
		var names := ["room_props_ch2_living", "room_props_ch2_bedroom", "room_props_ch2_office"]
		node.add_to_group(names[_room_index(pos.z, LEFT_PARTITIONS)])
	else:
		var names := ["room_props_ch2_dining", "room_props_ch2_boy", "room_props_ch2_storage"]
		node.add_to_group(names[_room_index(pos.z, RIGHT_PARTITIONS)])


func _room_index(z: float, partitions: Array) -> int:
	for i in partitions.size():
		if z > partitions[i]:
			return i
	return partitions.size() - 1


func _rug(node_name: String, center: Vector3, size: Vector3, color := Color(0.29, 0.23, 0.17)) -> void:
	var rug := LevelKit.box(self, node_name, center, size, LevelKit.textured("fabric", 1.25, color), false)
	_register_room_prop(rug, center)


func _build_evidence() -> void:
	_add_readable("SequenceClue", "Rascunho dos telefones", SEQUENCE_NOTE, Vector3(0.74, 0.815, 0.45), Vector3(0.2, 0.018, 0.28))
	_add_photo("FamilyPhoto304", Vector3(-5.76, 1.68, -0.6), Vector2(0.78, 0.53))
	_add_readable("PhotoBack", "Verso da fotografia", PHOTO_TEXT, Vector3(-5.66, 1.62, -0.6), Vector3(0.08, 0.5, 0.72), false)
	_add_photo("SecondPhoto", Vector3(-0.96, 1.55, -19.4), Vector2(0.62, 0.43))
	var tape := TapeRecorder.new()
	tape.name = "FutureArgumentTape"
	tape.position = Vector3(5.45, 0.84, -0.1)
	tape.rotation.y = -PI / 2.0
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
	# Um telefone por cômodo: sala (grave), quarto do casal (agudo), escritório (médio).
	var phone_data := [
		[0, Vector3(-5.45, 0.56, 1.86)],
		[2, Vector3(-5.5, 0.56, -4.56)],
		[1, Vector3(-5.4, 0.76, -11.6)],
	]
	for data in phone_data:
		var phone := SequencePhone.new()
		phone.name = "SequencePhone%d" % data[0]
		phone.tone_index = data[0]
		phone.position = data[1]
		phone.rotation.y = PI / 2.0
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


## Luzes: plafons no corredor e um abajur aceso em cada cômodo habitado. O
## depósito fica no escuro. Sem sombras, para ficar leve no navegador.
func _build_lamps() -> void:
	var warm := Color(1.0, 0.68, 0.38)
	var cold := Color(0.86, 0.9, 0.82)
	for z in [1.2, -6.0, -13.0, -19.5, -26.0]:
		LevelKit.ceiling_light(self, Vector3(0, 2.76, z), cold if z < -14.0 else warm, 0.85, 6.5, false)
	var lamps := [
		[Vector3(0.8, 1.35, 0.3), 0.6, 3.5],     # aparador da entrada
		[Vector3(-5.3, 1.2, 1.7), 0.95, 5.5],    # sala: abajur do telefone grave
		[Vector3(-3.4, 2.3, -1.2), 0.5, 5.0],    # sala: canto de leitura
		[Vector3(3.6, 2.3, 1.4), 0.9, 6.0],      # sala de jantar: sobre a mesa
		[Vector3(-5.3, 1.2, -6.6), 0.9, 5.5],    # quarto do casal
		[Vector3(5.3, 1.2, -5.4), 0.8, 5.0],     # quarto do menino
		[Vector3(-5.2, 1.4, -10.6), 0.9, 5.5],   # escritório
	]
	for lamp in lamps:
		LevelKit.lamp(self, lamp[0], warm, lamp[1], lamp[2], false)


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
	add_child(player)
	player.flashlight.visible = true
	_hud = GameHud.new()
	add_child(_hud)
	player.message.connect(_hud.show_message)
	player.prompt_changed.connect(_hud.set_prompt)
	player.inventory_changed.connect(_hud.set_inventory)
	_modal = ModalLayer.new()
	add_child(_modal)
	player.document_requested.connect(_modal.open_document)
	_pause = PauseMenu.new()
	add_child(_pause)
	session = PlaySession.new()
	add_child(session)
	session.bind(player, _hud, _modal, _pause)
	add_child(preload("res://game/ui/debug_hud.tscn").instantiate())
	session.set_objective("Descubra por que o 304 é maior por dentro.")
	_hud.show_message("A porta fechou atrás de você. O corredor não termina.
A fita está no aparador da sala de jantar.", 8.0)


func _on_sequence_solved() -> void:
	exit_door.sealed = false
	session.set_objective("A porta sem número destravou. Atravesse.")
	_hud.show_message("Os três telefones tocam juntos. Do outro lado da porta, uma rua responde.", 7.0)


func _on_exit_entered(body: Node3D) -> void:
	if body != player or not puzzle.is_solved or chapter_ended:
		return
	chapter_ended = true
	session.end_chapter("SEM SINAL",
		"A porta do 304 dá para uma rua que não existia no mapa.

O rádio de Íris só recebe chiado. Ao longe, um orelhão começa a tocar.

Continua: Capítulo 3 — Sem Sinal.")


func _box(node_name: String, center: Vector3, size: Vector3, mat: Material, solid := true) -> Node3D:
	return LevelKit.box(self, node_name, center, size, mat, solid)
