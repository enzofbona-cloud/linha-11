class_name Door
extends Node3D
## Porta com dobradiça. O nó fica na dobradiça; a folha se estende em -Z local.
## Pode estar trancada e exigir um item do inventário.

const WIDTH := 1.0
const HEIGHT := 2.08
const THICKNESS := 0.05
const SWING_TIME := 0.95

@export var open_angle_deg := 90.0
@export var locked_key := ""
@export var locked_text := "Trancada."
## Lacrada por outro mecanismo (ex.: fechadura eletrônica). Nenhuma chave abre.
var sealed := false
var sealed_text := "Não abre. Há uma fechadura eletrônica ao lado."
var is_open := false
## Desligado nos testes para o estado mudar na hora.
var animate := true

var _base_yaw := 0.0
var _tween: Tween
var _audio: AudioStreamPlayer3D


func _init() -> void:
	add_to_group("doors")


func _ready() -> void:
	_base_yaw = rotation.y
	if get_child_count() == 0:
		_build_panel()


func _build_panel() -> void:
	var body := AnimatableBody3D.new()
	body.name = "Panel"
	body.sync_to_physics = false
	body.position = Vector3(0, HEIGHT / 2.0, -WIDTH / 2.0)

	var mat := LevelKit.textured("door", 0.9, Color(0.62, 0.58, 0.5))

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(THICKNESS, HEIGHT, WIDTH)
	box.material = mat
	mesh.mesh = box
	body.add_child(mesh)

	var knob_mat := StandardMaterial3D.new()
	knob_mat.albedo_color = Color(0.55, 0.5, 0.38)
	knob_mat.metallic = 0.9
	knob_mat.roughness = 0.35
	for side in [-1.0, 1.0]:
		var knob := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.035
		sphere.height = 0.07
		sphere.material = knob_mat
		knob.mesh = sphere
		knob.position = Vector3(side * 0.05, -0.05, -WIDTH / 2.0 + 0.09)
		body.add_child(knob)

	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(THICKNESS, HEIGHT, WIDTH)
	shape.shape = box_shape
	body.add_child(shape)
	add_child(body)


func get_prompt(player: Player) -> String:
	if sealed:
		return "[E] Porta com fechadura eletrônica"
	if locked_key != "" and not player.has_item(locked_key):
		return "[E] Porta trancada"
	if locked_key != "":
		return "[E] Destrancar porta"
	return "[E] Fechar porta" if is_open else "[E] Abrir porta"


func interact(player: Player) -> void:
	if sealed:
		player.notify(sealed_text)
		_play(SoundKit.sfx("metallatch"), -4.0, randf_range(0.9, 1.05))
		return
	if locked_key != "":
		if not player.has_item(locked_key):
			player.notify(locked_text)
			# maçaneta forçada: trinco batendo, sem abrir
			_play(SoundKit.sfx("metallatch"), -3.0, randf_range(0.85, 1.0))
			player.make_noise(Player.NOISE_DOOR * 0.5)
			return
		locked_key = ""
		player.notify("A chave girou. A porta destrancou.")
		player.play_sfx(SoundKit.sfx("metalclick"), -2.0, 0.8)
	toggle()
	player.make_noise(Player.NOISE_DOOR)
	if is_open:
		_play(SoundKit.pick(SoundKit.DOOR_OPEN), -2.0, randf_range(0.92, 1.05))
		_play_delayed(SoundKit.pick(SoundKit.CREAKS), 0.18, -9.0, randf_range(0.8, 1.0))
	else:
		# a batida acontece quando a folha encosta no batente
		_play(SoundKit.pick(SoundKit.CREAKS), -11.0, randf_range(0.9, 1.1))
		_play_delayed(SoundKit.pick(SoundKit.DOOR_CLOSE), SWING_TIME * 0.85, -1.0, randf_range(0.92, 1.05))


func _play(stream: AudioStream, volume_db := 0.0, pitch := 1.0) -> void:
	if stream == null or not is_inside_tree() or not animate:
		return
	var voice := SoundKit.player_3d(self, stream, 16.0, volume_db)
	voice.position = Vector3(0, 1.0, -0.5)
	voice.pitch_scale = pitch
	voice.finished.connect(voice.queue_free)
	voice.play()


func _play_delayed(stream: AudioStream, delay: float, volume_db := 0.0, pitch := 1.0) -> void:
	if stream == null or not is_inside_tree() or not animate:
		return
	get_tree().create_timer(delay).timeout.connect(_play.bind(stream, volume_db, pitch))


func toggle() -> void:
	is_open = not is_open
	var target := _base_yaw + (deg_to_rad(open_angle_deg) if is_open else 0.0)
	if _tween != null:
		_tween.kill()
	if not animate or not is_inside_tree():
		rotation.y = target
		return
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "rotation:y", target, SWING_TIME)
