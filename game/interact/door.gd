class_name Door
extends Node3D
## Porta com dobradiça. O nó fica na dobradiça; a folha se estende em -Z local.
## Pode estar trancada e exigir um item do inventário.

const WIDTH := 1.0
const HEIGHT := 2.08
const THICKNESS := 0.05
const SWING_TIME := 0.55

@export var open_angle_deg := 90.0
@export var locked_key := ""
@export var locked_text := "Trancada."
var is_open := false
## Desligado nos testes para o estado mudar na hora.
var animate := true

var _base_yaw := 0.0
var _tween: Tween


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

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.27, 0.2, 0.15)
	mat.roughness = 0.65

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
	if locked_key != "" and not player.has_item(locked_key):
		return "[E] Porta trancada"
	if locked_key != "":
		return "[E] Destrancar porta"
	return "[E] Fechar porta" if is_open else "[E] Abrir porta"


func interact(player: Player) -> void:
	if locked_key != "":
		if not player.has_item(locked_key):
			player.notify(locked_text)
			return
		locked_key = ""
		player.notify("A chave girou. A porta destrancou.")
	toggle()


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
