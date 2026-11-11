class_name Listener
extends Node3D
## O Ouvinte: cego, reage só a som. Anda ao longo do corredor (eixo Z) e nunca
## entra nos cômodos, então sair do corredor em silêncio é o esconderijo.

signal caught
signal state_changed(new_state: int)

enum State { DORMANT, PATROL, INVESTIGATE, CHASE }

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

var state: int = State.DORMANT
var target_z := 0.0
var z_min := -15.0
var z_max := -1.0
## Meia largura do corredor: fora disso o jogador está em um cômodo.
var corridor_half_width := 1.2

var _quiet := 0.0
var _search := 0.0
var _patrol_dir := -1.0
var _time := 0.0
var _body: Node3D
var _audio: AudioStreamPlayer3D
var _growl: AudioStreamPlayer3D
var _step: AudioStreamPlayer3D
## Quantos passos ele já deu (cada um soa uma pancada no chão).
var steps_taken := 0

const GROWL_DB := {State.PATROL: 1.0, State.INVESTIGATE: 4.0, State.CHASE: 8.0}
const GROWL_PITCH := {State.PATROL: 0.92, State.INVESTIGATE: 1.05, State.CHASE: 1.28}


static func hears(distance: float, radius: float) -> bool:
	return radius > 0.0 and distance <= radius


func _init() -> void:
	name = "Listener"
	_build_body()
	visible = false


func _ready() -> void:
	_audio = SoundKit.player_3d(self, SoundKit.clicks(), 18.0, -2.0)
	_audio.position.y = 1.7
	_growl = SoundKit.player_3d(self, SoundKit.growl(), 26.0, GROWL_DB[State.PATROL])
	_growl.position.y = 1.5
	_step = SoundKit.player_3d(self, SoundKit.monster_step(), 24.0, 1.0)
	_step.position.y = 0.1


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player_target") as Node3D
	if player != null:
		tick(delta, player.global_position)


## Liga o Ouvinte (começa a patrulhar e a fazer som).
func wake() -> void:
	visible = true
	target_z = position.z
	_set_state(State.PATROL)
	if _audio != null and not _audio.playing:
		_audio.play()
	if _growl != null and not _growl.playing:
		_growl.play()


## Faz a patrulha começar andando na direção de `z` (ex.: onde está o jogador).
func walk_toward(z: float) -> void:
	_patrol_dir = 1.0 if z > position.z else -1.0


func sleep() -> void:
	visible = false
	_set_state(State.DORMANT)
	for voice in [_audio, _growl, _step]:
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
	_time += delta
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

	_animate()

	var in_corridor := absf(player_pos.x - position.x) <= corridor_half_width
	if in_corridor and absf(player_pos.z - position.z) <= CATCH_DISTANCE:
		caught.emit()


func _move_to_target(speed: float, delta: float) -> bool:
	position.z = move_toward(position.z, target_z, speed * delta)
	return is_equal_approx(position.z, target_z)


func _set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	_search = 0.0
	# Quanto mais perto de atacar, mais alto e mais agudo ele rosna.
	if _growl != null and GROWL_DB.has(new_state):
		_growl.volume_db = GROWL_DB[new_state]
		_growl.pitch_scale = GROWL_PITCH[new_state]
	state_changed.emit(new_state)


## Passos por metro percorrido (um passo a cada PI de fase).
const GAIT_PER_METER := 2.4

var _puppet: ShaderMaterial
var _gait_phase := 0.0
var _walk := 0.0
var _twitch := 0.0
var _next_twitch := 2.0
var _last_z := 0.0
var _lean := 0.0


## Anima o boneco: a passada acompanha a distância realmente percorrida, então
## os pés não "patinam"; cabeça e ombros dão espasmos em intervalos irregulares.
func _animate() -> void:
	if _puppet == null:
		return
	var delta := maxf(get_physics_process_delta_time(), 0.001)
	var moved := position.z - _last_z
	_last_z = position.z
	# Reposicionado de uma vez (acordou, voltou ao início): não é um passo.
	if absf(moved) > 0.5:
		moved = 0.0
	var speed := absf(moved) / delta
	var step_before := floori(_gait_phase / PI)
	_gait_phase += absf(moved) * GAIT_PER_METER
	# cada meia volta da fase é um pé no chão: aí soa a pancada do passo
	if moved != 0.0 and floori(_gait_phase / PI) != step_before:
		steps_taken += 1
		if _step != null and is_inside_tree():
			_step.pitch_scale = randf_range(0.82, 1.0)
			_step.play()
	# parado, ele ainda oscila devagar, como quem escuta
	if speed < 0.05:
		_gait_phase += delta * 0.5
	var target_walk := clampf(speed / PATROL_SPEED, 0.0, 2.6)
	_walk = lerpf(_walk, target_walk, minf(delta * 5.0, 1.0))
	# inclina-se para a frente quando persegue
	var target_lean := 0.10 if state == State.CHASE else (0.03 if state == State.INVESTIGATE else 0.0)
	_lean = lerpf(_lean, target_lean * signf(moved if moved != 0.0 else 1.0), minf(delta * 3.0, 1.0))

	_twitch = maxf(_twitch - delta * 3.5, 0.0)
	_next_twitch -= delta
	if _next_twitch <= 0.0:
		_twitch = 1.0
		_next_twitch = randf_range(0.5, 1.6) if state == State.CHASE else randf_range(2.0, 6.0)

	# Andar arrastado: o corpo joga o peso de um lado para o outro e avança aos
	# trancos (dá o passo, hesita, puxa a outra perna), em vez de deslizar reto.
	# É só visual: a posição lógica usada pela IA continua em linha reta.
	var weight := sin(_gait_phase)
	_body.position.x = weight * 0.11 * minf(_walk, 1.6)
	_body.position.z = -signf(moved if moved != 0.0 else 1.0) * sin(_gait_phase * 2.0) * 0.16 * minf(_walk, 1.6)
	_body.position.y = -absf(cos(_gait_phase)) * 0.05 * minf(_walk, 1.6)

	_puppet.set_shader_parameter("gait_phase", _gait_phase)
	_puppet.set_shader_parameter("walk", _walk)
	_puppet.set_shader_parameter("twitch", _twitch)
	_puppet.set_shader_parameter("lean", _lean)


func animation_state() -> Dictionary:
	return {"gait_phase": _gait_phase, "walk": _walk, "twitch": _twitch}


func _build_body() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)

	_puppet = ShaderMaterial.new()
	_puppet.shader = load("res://game/enemy/listener_puppet.gdshader")
	_puppet.set_shader_parameter("creature", load("res://assets/characters/listener_v2.png"))
	_puppet.set_shader_parameter("tint", Color(0.72, 0.72, 0.72))

	var sprite := MeshInstance3D.new()
	sprite.name = "CreatureSprite"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.72, 2.58)
	# malha subdividida: é ela que permite dobrar pernas, braços e cabeça
	quad.subdivide_width = 18
	quad.subdivide_depth = 28
	quad.material = _puppet
	sprite.mesh = quad
	sprite.position.y = 1.29
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# a deformação sai da caixa original; evita sumir na borda da tela
	sprite.extra_cull_margin = 1.0
	_body.add_child(sprite)
