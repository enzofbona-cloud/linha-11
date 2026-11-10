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


static func hears(distance: float, radius: float) -> bool:
	return radius > 0.0 and distance <= radius


func _init() -> void:
	name = "Listener"
	_build_body()
	visible = false


func _ready() -> void:
	_audio = SoundKit.player_3d(self, SoundKit.clicks(), 18.0, -2.0)
	_audio.position.y = 1.7


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


func sleep() -> void:
	visible = false
	_set_state(State.DORMANT)
	if _audio != null:
		_audio.stop()


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
	state_changed.emit(new_state)


func _animate() -> void:
	if _body == null:
		return
	var agitation := 3.0 if state == State.CHASE else 1.0
	_body.rotation.z = sin(_time * 1.7 * agitation) * 0.05 * agitation
	_body.rotation.x = sin(_time * 1.1 * agitation) * 0.04
	_body.position.y = sin(_time * 2.3) * 0.03


func _build_body() -> void:
	_body = Node3D.new()
	add_child(_body)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.035, 0.035, 0.04)
	skin.roughness = 0.45

	var torso := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.17
	capsule.height = 1.25
	capsule.material = skin
	torso.mesh = capsule
	torso.position.y = 1.45
	_body.add_child(torso)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.36
	sphere.material = skin
	head.mesh = sphere
	head.position = Vector3(0, 2.28, 0.05)
	_body.add_child(head)

	for side in [-1.0, 1.0]:
		# pernas longas
		var leg := MeshInstance3D.new()
		var leg_mesh := CapsuleMesh.new()
		leg_mesh.radius = 0.06
		leg_mesh.height = 1.0
		leg_mesh.material = skin
		leg.mesh = leg_mesh
		leg.position = Vector3(side * 0.1, 0.5, 0)
		_body.add_child(leg)
		# braços que quase tocam o chão
		var arm := MeshInstance3D.new()
		var arm_mesh := CapsuleMesh.new()
		arm_mesh.radius = 0.045
		arm_mesh.height = 1.5
		arm_mesh.material = skin
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.27, 1.25, 0.04)
		arm.rotation.z = side * 0.09
		_body.add_child(arm)
