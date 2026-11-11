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
var _torso: Node3D
var _head: Node3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_forearm: Node3D
var _right_forearm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _left_shin: Node3D
var _right_shin: Node3D
var _audio: AudioStreamPlayer3D


static func hears(distance: float, radius: float) -> bool:
	return radius > 0.0 and distance <= radius


func _init() -> void:
	name = "Listener"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
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
	_last_z = position.z
	_has_last_position = true
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
	if not _has_last_position:
		_last_z = position.z
		_has_last_position = true
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

	var moved := position.z - _last_z
	_last_z = position.z
	_animate(delta, moved)

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


## Passos por metro percorrido (um passo a cada PI de fase).
const GAIT_PER_METER := 2.4

var _gait_phase := 0.0
var _walk := 0.0
var _twitch := 0.0
var _next_twitch := 2.0
var _last_z := 0.0
var _lean := 0.0
var _last_move_direction := -1.0
var _has_last_position := false
var _skin: StandardMaterial3D
var _skin_dark: StandardMaterial3D
var _socket: StandardMaterial3D
var _hair: StandardMaterial3D
var _cloth: StandardMaterial3D


## Anima o corpo articulado: a passada acompanha a distância real e suaviza
## cada pivô, sem deslizar os pés nem deformar a criatura como uma imagem plana.
func _animate(delta: float, moved: float) -> void:
	if _body == null:
		return
	var safe_delta := maxf(delta, 0.001)
	var speed := absf(moved) / safe_delta
	if absf(moved) > 0.0001:
		_last_move_direction = signf(moved)
		_gait_phase += absf(moved) * GAIT_PER_METER
	else:
		_gait_phase += delta * 0.12

	var target_walk := clampf(speed / PATROL_SPEED, 0.0, 2.6)
	_walk = move_toward(_walk, target_walk, delta * (3.5 if target_walk > _walk else 5.0))
	var target_lean := 0.22 if state == State.CHASE else (0.11 if state == State.INVESTIGATE else 0.06)
	_lean = lerpf(_lean, target_lean, minf(delta * 3.2, 1.0))

	_twitch = maxf(_twitch - delta * 3.5, 0.0)
	_next_twitch -= delta
	if _next_twitch <= 0.0:
		_twitch = 1.0
		_next_twitch = randf_range(0.5, 1.6) if state == State.CHASE else randf_range(2.0, 6.0)

	# O corpo inteiro vira para o som investigado. Não é billboard: o perfil
	# permanece tridimensional mesmo quando a câmera se desloca para o lado.
	var direction := signf(target_z - position.z)
	if state == State.PATROL or direction == 0.0:
		direction = _last_move_direction if speed > 0.02 else _patrol_dir
	var desired_yaw := PI if direction > 0.0 else 0.0
	_body.rotation.y = lerp_angle(_body.rotation.y, desired_yaw, minf(delta * 4.5, 1.0))

	var stride := sin(_gait_phase) * minf(_walk, 1.4)
	var bob := absf(cos(_gait_phase * 2.0)) * 0.035 * minf(_walk, 1.0)
	_body.position.y = lerpf(_body.position.y, bob, minf(delta * 9.0, 1.0))
	_torso.rotation.x = lerpf(_torso.rotation.x, -0.28 - _lean, minf(delta * 5.0, 1.0))
	_torso.rotation.z = lerpf(_torso.rotation.z, 0.07 + sin(_gait_phase) * 0.035 * _walk, minf(delta * 5.0, 1.0))
	_left_leg.rotation.x = lerpf(_left_leg.rotation.x, stride * 0.42 - 0.1, minf(delta * 9.0, 1.0))
	_right_leg.rotation.x = lerpf(_right_leg.rotation.x, -stride * 0.42 + 0.04, minf(delta * 9.0, 1.0))
	_left_shin.rotation.x = lerpf(_left_shin.rotation.x, maxf(-stride, 0.0) * 0.48, minf(delta * 8.0, 1.0))
	_right_shin.rotation.x = lerpf(_right_shin.rotation.x, maxf(stride, 0.0) * 0.48, minf(delta * 8.0, 1.0))
	_left_arm.rotation.x = lerpf(_left_arm.rotation.x, -stride * 0.34 - 0.16, minf(delta * 7.0, 1.0))
	_right_arm.rotation.x = lerpf(_right_arm.rotation.x, stride * 0.38 + 0.22, minf(delta * 7.0, 1.0))
	_left_forearm.rotation.x = lerpf(_left_forearm.rotation.x, 0.12 + maxf(stride, 0.0) * 0.16, minf(delta * 7.0, 1.0))
	_right_forearm.rotation.x = lerpf(_right_forearm.rotation.x, 0.18 + maxf(-stride, 0.0) * 0.16, minf(delta * 7.0, 1.0))
	_head.rotation.x = lerpf(_head.rotation.x, -0.16 + sin(_time * 0.63) * 0.035 + _twitch * 0.11, minf(delta * 4.0, 1.0))
	_head.rotation.y = lerpf(_head.rotation.y, sin(_time * 0.47) * 0.13, minf(delta * 2.8, 1.0))
	_head.rotation.z = lerpf(_head.rotation.z, deg_to_rad(24.0) + sin(_time * 0.72) * 0.07 + _twitch * sin(_time * 37.0) * 0.12, minf(delta * 5.0, 1.0))


func animation_state() -> Dictionary:
	return {"gait_phase": _gait_phase, "walk": _walk, "twitch": _twitch,
		"stride": sin(_gait_phase) * minf(_walk, 1.4)}


func _build_body() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	_body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	add_child(_body)
	_skin = LevelKit.textured("creature_hide", 0.72, Color(0.43, 0.40, 0.36))
	_skin.normal_scale = 0.24
	_skin.roughness = 0.99
	_skin.metallic = 0.0
	_skin_dark = LevelKit.textured("creature_hide", 0.72, Color(0.25, 0.23, 0.21))
	_skin_dark.normal_scale = 0.18
	_skin_dark.roughness = 0.99
	_skin_dark.metallic = 0.0
	_socket = _material(Color(0.025, 0.022, 0.02), 1.0)
	_hair = _material(Color(0.055, 0.048, 0.043), 1.0)
	_cloth = LevelKit.textured("fabric", 0.58, Color(0.28, 0.24, 0.20))
	_cloth.roughness = 0.99
	_cloth.cull_mode = BaseMaterial3D.CULL_DISABLED

	# Tronco e pescoço assimétricos, com sobreposição suave para quebrar a forma
	# de boneco e conservar uma silhueta legível à distância.
	_torso = Node3D.new()
	_torso.name = "Torso"
	_body.add_child(_torso)
	_add_ellipsoid(_torso, "Pelvis", Vector3(0, 1.03, 0.025), Vector3(0.40, 0.39, 0.31), _skin_dark)
	_add_capsule(_torso, "Abdomen", 0.72, 0.19, Vector3(0, 1.34, 0.01), Vector3(1.05, 1.0, 0.88), _skin)
	_add_capsule(_torso, "Ribcage", 0.65, 0.23, Vector3(0, 1.59, -0.015), Vector3(1.30, 1.0, 0.82), _skin)
	_torso.rotation.x = -0.28
	_torso.rotation.z = 0.07
	var shoulder_line := _add_capsule(_torso, "ShoulderLine", 0.72, 0.12,
		Vector3(0, 1.71, 0.005), Vector3.ONE, _skin)
	shoulder_line.rotation.z = PI / 2.0
	_add_capsule(_torso, "Neck", 0.38, 0.105, Vector3(0, 1.91, 0.035), Vector3(1.0, 1.0, 0.94), _skin_dark)
	_torso.add_child(_build_torn_coat())

	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0.04, 2.02, -0.045)
	_head.rotation.z = deg_to_rad(31.0)
	_head.rotation.x = -0.20
	_torso.add_child(_head)
	_add_ellipsoid(_head, "Skull", Vector3(0, 0.10, 0), Vector3(0.34, 0.50, 0.31), _skin)
	_add_ellipsoid(_head, "HairMass", Vector3(0, 0.29, 0.025), Vector3(0.35, 0.30, 0.33), _hair)
	_head.add_child(_build_hair_curtain())
	# Fendas profundas sem olhos: o Ouvinte encontra as vítimas pelo som.
	_add_ellipsoid(_head, "LeftEyeSocket", Vector3(-0.073, 0.115, -0.29), Vector3(0.042, 0.095, 0.025), _socket)
	_add_ellipsoid(_head, "RightEyeSocket", Vector3(0.073, 0.105, -0.29), Vector3(0.042, 0.095, 0.025), _socket)
	_add_ellipsoid(_head, "Mouth", Vector3(0.015, -0.085, -0.31), Vector3(0.065, 0.13, 0.025), _socket)

	_left_arm = _build_arm("LeftArm", -0.37, 1.67, 0.67)
	_right_arm = _build_arm("RightArm", 0.34, 1.57, 0.82)
	_left_leg = _build_leg("LeftLeg", -0.15, 0.98, 0.58)
	_right_leg = _build_leg("RightLeg", 0.15, 0.94, 0.54)
	_left_arm.rotation.z = -0.16
	_right_arm.rotation.z = 0.12
	_left_forearm.rotation.z = -0.24
	_right_forearm.rotation.z = 0.30
	_left_leg.rotation.z = -0.08
	_right_leg.rotation.z = 0.07
	_last_z = position.z


func _build_arm(node_name: String, x: float, y: float, forearm_length: float) -> Node3D:
	var arm := Node3D.new()
	arm.name = node_name
	arm.position = Vector3(x, y, 0)
	_torso.add_child(arm)
	_add_capsule(arm, "UpperArm", 0.62, 0.085, Vector3(0, -0.29, 0), Vector3(1.0, 1.0, 0.9), _skin)
	var forearm := Node3D.new()
	forearm.name = "Forearm"
	forearm.position.y = -0.57
	arm.add_child(forearm)
	if node_name == "LeftArm":
		_left_forearm = forearm
	else:
		_right_forearm = forearm
	_add_capsule(forearm, "ForearmMesh", forearm_length, 0.071, Vector3(0, -forearm_length * 0.46, -0.005), Vector3(0.94, 1.0, 0.85), _skin)
	_add_ellipsoid(forearm, "Palm", Vector3(0, -forearm_length * 0.91, -0.015), Vector3(0.13, 0.18, 0.08), _skin_dark)
	for finger in range(4):
		var finger_x := (float(finger) - 1.5) * 0.052
		var finger_length := 0.19 + (0.035 if finger == 1 or finger == 2 else 0.0)
		_add_capsule(forearm, "Finger%d" % finger, finger_length, 0.018,
			Vector3(finger_x, -forearm_length * 0.91 - finger_length * 0.70, -0.012),
			Vector3(0.82, 1.0, 0.82), _skin)
	return arm


func _build_leg(node_name: String, x: float, y: float, thigh_length: float) -> Node3D:
	var leg := Node3D.new()
	leg.name = node_name
	leg.position = Vector3(x, y, 0)
	_body.add_child(leg)
	_add_capsule(leg, "Thigh", thigh_length, 0.12, Vector3(0, -thigh_length * 0.48, 0.015), Vector3(1.05, 1.0, 0.91), _skin_dark)
	var shin := Node3D.new()
	shin.name = "Shin"
	shin.position.y = -thigh_length * 0.92
	leg.add_child(shin)
	if x < 0.0:
		_left_shin = shin
	else:
		_right_shin = shin
	var shin_length := 0.53 if x < 0.0 else 0.57
	_add_capsule(shin, "ShinMesh", shin_length, 0.082, Vector3(0, -shin_length * 0.48, 0), Vector3(0.94, 1.0, 0.88), _skin)
	_add_ellipsoid(shin, "Foot", Vector3(0, -shin_length * 0.91, -0.105), Vector3(0.16, 0.105, 0.27), _skin_dark)
	return leg


func _build_torn_coat() -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const ROWS := 9
	var strip_x := [-0.30, -0.08, 0.29, -0.28, 0.11, 0.31]
	var strip_length := [1.05, 0.72, 0.85, 0.90, 1.12, 0.72]
	var strip_width := [0.09, 0.07, 0.10, 0.08, 0.10, 0.07]
	for strip in strip_x.size():
		var back := strip >= 3
		var anchor_x: float = strip_x[strip]
		var length: float = strip_length[strip]
		var width: float = strip_width[strip]
		for row in ROWS:
			var t0 := float(row) / float(ROWS)
			var t1 := float(row + 1) / float(ROWS)
			var a := _coat_vertex(t0, anchor_x, length, width, back, strip)
			var b := _coat_vertex(t0, anchor_x, length, width, back, strip, true)
			var c := _coat_vertex(t1, anchor_x, length, width, back, strip)
			var d := _coat_vertex(t1, anchor_x, length, width, back, strip, true)
			_add_triangle(surface, a, c, b, Vector2(0, t0), Vector2(0, t1), Vector2(1, t0))
			_add_triangle(surface, b, c, d, Vector2(1, t0), Vector2(0, t1), Vector2(1, t1))
	surface.index()
	surface.generate_normals()
	var garment := MeshInstance3D.new()
	garment.name = "TornCoat"
	garment.mesh = surface.commit()
	garment.material_override = _cloth
	garment.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return garment


func _coat_vertex(t: float, anchor_x: float, length: float, width: float,
		back: bool, strip: int, right_edge := false) -> Vector3:
	var side := 1.0 if right_edge else -1.0
	var drift := sin(t * 3.4 + float(strip) * 1.9) * 0.045
	var tear := maxf(0.0, sin(float(strip) * 5.3 + 1.4)) * 0.08 if t > 0.86 else 0.0
	var y := 1.82 - length * t - (tear if right_edge else tear * 0.25)
	var x := anchor_x + drift + side * width * (0.5 + t * 0.12)
	var z := (0.235 if back else -0.235) + sin(t * 5.0 + float(strip)) * 0.025
	return Vector3(x, y, z)


func _build_hair_curtain() -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	const LOCKS := 9
	const ROWS := 10
	const SIDES := 6
	for lock in LOCKS:
		var ratio := float(lock) / float(LOCKS - 1)
		var center_x := lerpf(-0.22, 0.19, ratio) + 0.025 * sin(float(lock) * 2.2)
		var length := 0.48 + 0.20 * float((lock * 5) % 4) / 3.0
		var radius := 0.017 + 0.006 * float(lock % 3) / 2.0
		for row in ROWS:
			var t0 := float(row) / float(ROWS)
			var t1 := float(row + 1) / float(ROWS)
			for side in SIDES:
				var angle0 := TAU * float(side) / SIDES
				var angle1 := TAU * float(side + 1) / SIDES
				var a := _hair_vertex(t0, center_x, length, radius, lock, angle0)
				var b := _hair_vertex(t0, center_x, length, radius, lock, angle1)
				var c := _hair_vertex(t1, center_x, length, radius, lock, angle0)
				var d := _hair_vertex(t1, center_x, length, radius, lock, angle1)
				_add_triangle(surface, a, c, b, Vector2(0, t0), Vector2(0, t1), Vector2(1, t0))
				_add_triangle(surface, b, c, d, Vector2(1, t0), Vector2(0, t1), Vector2(1, t1))
	surface.index()
	surface.generate_normals()
	var curtain := MeshInstance3D.new()
	curtain.name = "HairCurtain"
	curtain.mesh = surface.commit()
	curtain.material_override = _hair
	_hair.cull_mode = BaseMaterial3D.CULL_DISABLED
	curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return curtain


func _hair_vertex(t: float, center_x: float, length: float, radius: float,
		lock: int, angle: float) -> Vector3:
	var radius_taper := lerpf(radius, radius * 0.24, t)
	var sway := sin(t * 5.2 + float(lock) * 1.7) * 0.05 + sin(t * 2.1 + float(lock) * 0.6) * 0.03
	var y := 0.40 - t * length
	var x := center_x + sway + cos(angle) * radius_taper
	var z := -0.32 - cos(t * 2.6 + float(lock)) * 0.05 + sin(angle) * radius_taper
	return Vector3(x, y, z)


func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3,
		uv_a: Vector2, uv_b: Vector2, uv_c: Vector2) -> void:
	surface.set_uv(uv_a)
	surface.add_vertex(a)
	surface.set_uv(uv_b)
	surface.add_vertex(b)
	surface.set_uv(uv_c)
	surface.add_vertex(c)


func _add_capsule(parent: Node3D, node_name: String, height: float, radius: float,
		pos: Vector3, stretch: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 6
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = pos
	instance.scale = stretch
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func _add_ellipsoid(parent: Node3D, node_name: String, pos: Vector3, stretch: Vector3,
		material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = pos
	instance.scale = stretch
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(instance)
	return instance


func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = 0.0
	return material
