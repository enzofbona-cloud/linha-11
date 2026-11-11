class_name Listener
extends Node3D
## O Ouvinte: cego, reage só a som. Anda ao longo do corredor (eixo Z) e nunca
## entra nos cômodos, então sair do corredor em silêncio é o esconderijo.

signal caught
signal state_changed(new_state: int)

enum State { DORMANT, PATROL, INVESTIGATE, CHASE }

const MODEL_SCENE: PackedScene = preload("res://assets/models/characters/ouvinte_tripo.glb")
const MODEL_SCALE := 2.6
const PATROL_SPEED := 1.0
const INVESTIGATE_SPEED := 2.1
## Mais rápido que andar (3,2) e mais lento que correr (5,6).
const CHASE_SPEED := 4.4
## Som ouvido a menos desta distância faz perseguir em vez de investigar.
const CHASE_TRIGGER := 4.5
const CATCH_DISTANCE := 0.95
## Segundos de silêncio até desistir da perseguição.
const LOSE_TIME := 4.0
## Segundos parado no último lugar em que ouviu algo.
const SEARCH_TIME := 2.5
## Rosnado contido ao longe; cresce só quando ele investiga ou persegue.
const GROWL_DB := {State.PATROL: -12.0, State.INVESTIGATE: -8.0, State.CHASE: -4.0}
const GROWL_PITCH := {State.PATROL: 0.9, State.INVESTIGATE: 1.0, State.CHASE: 1.12}
## Passos graves, com volume reduzido para não encobrir o ambiente.
const STEP_DB := -9.0
## Frente do modelo Tripo convertida pelo importador do Godot.
const MODEL_FORWARD_YAW := 0.0

var state: int = State.DORMANT
var target_z := 0.0
var z_min := -15.0
var z_max := -1.0
## Meia largura do corredor: fora disso o jogador está em um cômodo.
var corridor_half_width := 1.2

var _quiet := 0.0
var _search := 0.0
var _patrol_dir := -1.0
var _body: Node3D
var _model: Node3D
var _face_blur: MeshInstance3D
var _growl: AudioStreamPlayer3D
var _step: AudioStreamPlayer3D
## Quantos passos ele já deu (cada um soa uma pancada no chão).
var steps_taken := 0

## Passos por metro percorrido (um passo a cada PI de fase).
const GAIT_PER_METER := 2.4

var _gait_phase := 0.0
var _walk := 0.0
var _twitch := 0.0
var _next_twitch := 2.0
var _last_z := 0.0
var _lean := 0.0
var _facing_sign := -1.0


static func hears(distance: float, radius: float) -> bool:
	return radius > 0.0 and distance <= radius


func _init() -> void:
	name = "Listener"
	_build_body()
	visible = false


func _ready() -> void:
	_growl = SoundKit.player_3d(self, SoundKit.growl(), 24.0, GROWL_DB[State.PATROL])
	_growl.position.y = 1.55
	_step = SoundKit.player_3d(self, SoundKit.monster_step(), 16.0, STEP_DB)
	_step.position.y = 0.08


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player_target") as Node3D
	if player != null:
		tick(delta, player.global_position)


## Liga o Ouvinte (começa a patrulhar e a fazer som).
func wake() -> void:
	visible = true
	target_z = position.z
	_last_z = position.z
	_set_state(State.PATROL)
	if _growl != null and not _growl.playing:
		_growl.play()


## Faz a patrulha começar andando na direção de `z` (ex.: onde está o jogador).
func walk_toward(z: float) -> void:
	_patrol_dir = 1.0 if z > position.z else -1.0
	_facing_sign = _patrol_dir
	_body.rotation.y = MODEL_FORWARD_YAW if _facing_sign > 0.0 else MODEL_FORWARD_YAW + PI


func sleep() -> void:
	visible = false
	_set_state(State.DORMANT)
	for voice in [_growl, _step]:
		if voice != null:
			voice.stop()


## Verdadeiro enquanto o rosnado está tocando (ele está acordado e por perto).
func is_growling() -> bool:
	return _growl != null and _growl.playing


func hear(origin: Vector3, radius: float) -> void:
	if state == State.DORMANT:
		return
	var distance := global_position.distance_to(origin) if is_inside_tree() else position.distance_to(origin)
	if not hears(distance, radius):
		return
	target_z = clampf(origin.z, z_min, z_max)
	_quiet = 0.0
	if distance <= CHASE_TRIGGER or state == State.CHASE:
		_set_state(State.CHASE)
	else:
		_set_state(State.INVESTIGATE)


## Avança a IA. Separado de _physics_process para ser testável.
func tick(delta: float, player_pos: Vector3) -> void:
	if state == State.DORMANT:
		return
	_quiet += delta

	match state:
		State.PATROL:
			position.z += _patrol_dir * PATROL_SPEED * delta
			if position.z <= z_min:
				position.z = z_min
				_patrol_dir = 1.0
			elif position.z >= z_max:
				position.z = z_max
				_patrol_dir = -1.0
		State.INVESTIGATE:
			if _move_to_target(INVESTIGATE_SPEED, delta):
				_search += delta
				if _search >= SEARCH_TIME:
					_set_state(State.PATROL)
		State.CHASE:
			_move_to_target(CHASE_SPEED, delta)
			if _quiet >= LOSE_TIME:
				_set_state(State.INVESTIGATE)

	_animate(delta)

	var in_corridor := absf(player_pos.x - position.x) <= corridor_half_width
	if in_corridor and absf(player_pos.z - position.z) <= CATCH_DISTANCE:
		caught.emit()


func _move_to_target(speed: float, delta: float) -> bool:
	var previous_z := position.z
	position.z = move_toward(position.z, target_z, speed * delta)
	if not is_equal_approx(previous_z, position.z):
		_facing_sign = signf(position.z - previous_z)
	return is_equal_approx(position.z, target_z)


func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	_search = 0.0
	_quiet = 0.0
	# O som permanece distante na patrulha e só cresce quando ele caça.
	if _growl != null and GROWL_DB.has(new_state):
		_growl.volume_db = GROWL_DB[new_state]
		_growl.pitch_scale = GROWL_PITCH[new_state]
	state_changed.emit(new_state)


## Anima o corpo 3D com inércia, balanço de peso e espasmos pequenos.
## A malha do Tripo é única e não tem esqueleto; o movimento fica no corpo todo,
## sem fingir articulações que o arquivo não possui.
func _animate(delta: float) -> void:
	var moved := position.z - _last_z
	_last_z = position.z
	# Reposicionado de uma vez (acordou, voltou ao início): não é um passo.
	if absf(moved) > 0.5:
		moved = 0.0
	var speed := absf(moved) / maxf(delta, 0.001)
	var step_before := floori(_gait_phase / PI)
	_gait_phase += absf(moved) * GAIT_PER_METER
	if moved != 0.0 and floori(_gait_phase / PI) != step_before:
		steps_taken += 1
		if _step != null and is_inside_tree():
			_step.pitch_scale = randf_range(0.88, 1.02)
			_step.play()
	# Parado, ele ainda oscila quase imperceptivelmente, como quem escuta.
	if speed < 0.05:
		_gait_phase += delta * 0.35
	var target_walk := clampf(speed / PATROL_SPEED, 0.0, 2.6)
	_walk = lerpf(_walk, target_walk, minf(delta * 3.2, 1.0))
	var target_lean := 0.07 if state == State.CHASE else (0.025 if state == State.INVESTIGATE else 0.0)
	_lean = lerpf(_lean, target_lean * _facing_sign, minf(delta * 2.0, 1.0))

	_twitch = maxf(_twitch - delta * 2.5, 0.0)
	_next_twitch -= delta
	if _next_twitch <= 0.0:
		_twitch = 1.0
		_next_twitch = randf_range(0.6, 1.8) if state == State.CHASE else randf_range(2.5, 6.0)

	var weight := sin(_gait_phase)
	_body.position.x = weight * 0.055 * minf(_walk, 1.5)
	_body.position.z = -_facing_sign * sin(_gait_phase * 2.0) * 0.075 * minf(_walk, 1.5)
	_body.position.y = -absf(cos(_gait_phase)) * 0.025 * minf(_walk, 1.5)
	var target_yaw := MODEL_FORWARD_YAW if _facing_sign > 0.0 else MODEL_FORWARD_YAW + PI
	_body.rotation.y = lerp_angle(_body.rotation.y, target_yaw, minf(delta * 2.2, 1.0))
	_body.rotation.x = lerpf(_body.rotation.x, -_lean, minf(delta * 2.5, 1.0))
	var target_roll := weight * 0.035 * minf(_walk, 1.5) + _twitch * 0.025
	_body.rotation.z = lerpf(_body.rotation.z, target_roll, minf(delta * 3.0, 1.0))
	if _face_blur != null:
		_face_blur.rotation.z = sin(_gait_phase * 0.5) * 0.012 + _twitch * 0.006


func animation_state() -> Dictionary:
	return {"gait_phase": _gait_phase, "walk": _walk, "twitch": _twitch}


func _build_body() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	_model = MODEL_SCENE.instantiate() as Node3D
	_model.name = "TripoBody3D"
	_model.scale = Vector3.ONE * MODEL_SCALE
	_body.add_child(_model)
	_tune_body_materials(_model)
	_build_face_blur()


func _tune_body_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		mesh_instance.extra_cull_margin = 0.5
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				var imported := mesh_instance.mesh.surface_get_material(surface)
				if imported is StandardMaterial3D:
					var material := (imported as StandardMaterial3D).duplicate() as StandardMaterial3D
					material.albedo_color = Color(0.56, 0.58, 0.56, 1.0)
					material.roughness = maxf(material.roughness, 0.76)
					mesh_instance.set_surface_override_material(surface, material)
	for child in node.get_children():
		_tune_body_materials(child)


func _build_face_blur() -> void:
	# Borrão preto difuso, pequeno e só sobre a face.
	_face_blur = MeshInstance3D.new()
	_face_blur.name = "FaceBlur"
	var patch := QuadMesh.new()
	patch.size = Vector2(0.13, 0.11)
	patch.subdivide_width = 6
	patch.subdivide_depth = 6
	_face_blur.mesh = patch
	_face_blur.position = Vector3(-0.09, 0.88, 0.315)
	var material := ShaderMaterial.new()
	material.shader = preload("res://game/enemy/face_blur.gdshader")
	_face_blur.material_override = material
	_face_blur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_model.add_child(_face_blur)
