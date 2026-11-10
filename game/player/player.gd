class_name Player
extends CharacterBody3D
## Jogador em primeira pessoa: andar, correr, agachar, andar devagar, pular,
## lanterna, interação, inventário simples e o ruído que ele produz.

signal message(text: String)
signal prompt_changed(text: String)
signal inventory_changed(names: Array)
signal document_requested(title: String, body: String)
signal keypad_requested(keypad: Node)
## Emitido sempre que o jogador faz barulho (posição e raio em metros).
signal noise_made(origin: Vector3, radius: float)

const WALK_SPEED := 3.2
const SPRINT_SPEED := 5.6
const CROUCH_SPEED := 1.6
const SLOW_SPEED := 1.5
const JUMP_VELOCITY := 4.2
const GRAVITY := 12.0
const ACCELERATION := 12.0
const MOUSE_SENSITIVITY := 0.0022
const STICK_LOOK_SPEED := 2.6
const STAND_HEIGHT := 1.8
const CROUCH_HEIGHT := 1.1
const EYE_OFFSET := 0.15
const INTERACT_DISTANCE := 2.2

const NOISE_WALK := 5.5
const NOISE_SPRINT := 13.0
const NOISE_LAND := 8.0
const NOISE_DOOR := 7.0
const STRIDE_WALK := 0.8
const STRIDE_SPRINT := 1.1

var camera: Camera3D
var flashlight: SpotLight3D
var inventory: Dictionary = {}
## Falso enquanto um painel (documento, teclado) está aberto.
var controls_enabled := true

var _shape: CapsuleShape3D
var _collider: CollisionShape3D
var _ray: RayCast3D
var _height := STAND_HEIGHT
var _prompt := ""
var _stride := 0.0
var _was_on_floor := true
var _step_audio: AudioStreamPlayer
var _click_audio: AudioStreamPlayer


## Velocidade alvo conforme o estado. Agachar e andar devagar vencem correr.
static func target_speed(sprinting: bool, crouching: bool, slow: bool) -> float:
	if crouching:
		return CROUCH_SPEED
	if slow:
		return SLOW_SPEED
	if sprinting:
		return SPRINT_SPEED
	return WALK_SPEED


## Raio (em metros) em que os passos são ouvidos. Agachado ou devagar: silêncio.
static func noise_radius_for(moving: bool, sprinting: bool, crouching: bool, slow: bool) -> float:
	if not moving or crouching or slow:
		return 0.0
	return NOISE_SPRINT if sprinting else NOISE_WALK


func _init() -> void:
	name = "Player"
	_shape = CapsuleShape3D.new()
	_shape.radius = 0.32
	_shape.height = STAND_HEIGHT
	_collider = CollisionShape3D.new()
	_collider.shape = _shape
	_collider.position.y = STAND_HEIGHT / 2.0
	add_child(_collider)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.position.y = STAND_HEIGHT - EYE_OFFSET
	camera.fov = 72.0
	camera.near = 0.05
	camera.far = 80.0
	add_child(camera)

	flashlight = SpotLight3D.new()
	flashlight.name = "Flashlight"
	flashlight.position = Vector3(0.18, -0.12, 0.0)
	flashlight.light_color = Color(1.0, 0.95, 0.85)
	flashlight.light_energy = 6.0
	flashlight.spot_range = 16.0
	flashlight.spot_angle = 34.0
	flashlight.spot_attenuation = 1.1
	flashlight.spot_angle_attenuation = 2.2
	flashlight.shadow_enabled = true
	flashlight.visible = false
	camera.add_child(flashlight)

	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -INTERACT_DISTANCE)
	_ray.enabled = true
	camera.add_child(_ray)

	_step_audio = SoundKit.player_2d(self, SoundKit.step(), -8.0)
	_click_audio = SoundKit.player_2d(self, SoundKit.click(), -6.0)


func _ready() -> void:
	_ray.add_exception(self)
	camera.current = true


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		_look(-event.relative.x * MOUSE_SENSITIVITY, -event.relative.y * MOUSE_SENSITIVITY)
	elif event.is_action_pressed("flashlight"):
		toggle_flashlight()
	elif event.is_action_pressed("interact"):
		interact_with_target()


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	var crouching := false
	var sprinting := false
	var slow := false
	var wants_jump := false
	if controls_enabled:
		var stick := Vector2(
			Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
		if stick.length() > 0.2:
			_look(-stick.x * STICK_LOOK_SPEED * delta, -stick.y * STICK_LOOK_SPEED * delta)
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		crouching = Input.is_action_pressed("crouch")
		sprinting = Input.is_action_pressed("sprint")
		slow = Input.is_action_pressed("walk_slow")
		wants_jump = Input.is_action_just_pressed("jump")

	_update_height(crouching, delta)

	var on_floor := is_on_floor()
	if not on_floor:
		velocity.y -= GRAVITY * delta
	elif wants_jump and not crouching:
		velocity.y = JUMP_VELOCITY
	if on_floor and not _was_on_floor:
		make_noise(NOISE_LAND)
		_play_step(0.0)
	_was_on_floor = on_floor

	var direction := (global_transform.basis * Vector3(input.x, 0, input.y))
	direction.y = 0
	direction = direction.limit_length(1.0)
	var speed := target_speed(sprinting, crouching, slow)
	var blend := minf(ACCELERATION * delta, 1.0)
	velocity.x = lerpf(velocity.x, direction.x * speed, blend)
	velocity.z = lerpf(velocity.z, direction.z * speed, blend)
	move_and_slide()

	_update_steps(delta, on_floor, sprinting and not crouching and not slow, crouching, slow)
	_update_prompt()


func _update_steps(delta: float, on_floor: bool, sprinting: bool, crouching: bool, slow: bool) -> void:
	var horizontal := Vector2(velocity.x, velocity.z).length()
	var moving := on_floor and horizontal > 0.6
	if not moving:
		_stride = 0.0
		return
	_stride += horizontal * delta
	var stride := STRIDE_SPRINT if sprinting else STRIDE_WALK
	if _stride < stride:
		return
	_stride = 0.0
	var radius := noise_radius_for(true, sprinting, crouching, slow)
	if radius > 0.0:
		make_noise(radius)
		_play_step(-2.0 if sprinting else -9.0)
	else:
		_play_step(-24.0)


func _play_step(volume_db: float) -> void:
	_step_audio.volume_db = volume_db
	_step_audio.pitch_scale = randf_range(0.9, 1.1)
	_step_audio.play()


func make_noise(radius: float) -> void:
	if radius > 0.0:
		noise_made.emit(global_position, radius)


func _look(yaw: float, pitch: float) -> void:
	rotate_y(yaw)
	camera.rotation.x = clampf(camera.rotation.x + pitch, deg_to_rad(-85), deg_to_rad(85))


func _update_height(crouching: bool, delta: float) -> void:
	var target := CROUCH_HEIGHT if crouching else STAND_HEIGHT
	if is_equal_approx(_height, target):
		return
	if target > _height and test_move(global_transform, Vector3.UP * (target - _height)):
		return # sem espaço para levantar
	_height = move_toward(_height, target, 4.0 * delta)
	_shape.height = _height
	_collider.position.y = _height / 2.0
	camera.position.y = _height - EYE_OFFSET


func toggle_flashlight() -> void:
	flashlight.visible = not flashlight.visible
	if is_inside_tree():
		_click_audio.play()


# --- interação ---

## Devolve o objeto interativo sob a mira (ou null).
func get_target() -> Node:
	if not _ray.is_colliding():
		return null
	var node := _ray.get_collider() as Node
	while node != null:
		if node.has_method("interact"):
			return node
		node = node.get_parent()
	return null


func interact_with_target() -> void:
	var target := get_target()
	if target != null:
		target.interact(self)


func _update_prompt() -> void:
	var target := get_target() if controls_enabled else null
	var text := ""
	if target != null and target.has_method("get_prompt"):
		text = target.get_prompt(self)
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)


func notify(text: String) -> void:
	message.emit(text)


func read_document(title: String, body: String) -> void:
	document_requested.emit(title, body)


func use_keypad(keypad: Node) -> void:
	keypad_requested.emit(keypad)


# --- inventário ---

func has_item(id: String) -> bool:
	return inventory.has(id)


func add_item(id: String, display_name: String) -> void:
	if inventory.has(id):
		return
	inventory[id] = display_name
	inventory_changed.emit(inventory.values())


func remove_item(id: String) -> void:
	if inventory.erase(id):
		inventory_changed.emit(inventory.values())
