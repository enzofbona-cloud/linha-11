class_name TapeRecorder
extends StaticBody3D
## Gravador que reproduz a discussão futura dos protagonistas.

var _played := false
var _static: AudioStreamPlayer3D


func _ready() -> void:
	_static = SoundKit.player_3d(self, SoundKit.static_noise(), 12.0, -10.0)
	var body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.27, 0.1, 0.18)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.1, 0.075)
	mat.metallic = 0.35
	mat.roughness = 0.62
	box.material = mat
	body.mesh = box
	body.position.y = 0.08
	add_child(body)
	var shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(0.4, 0.3, 0.32)
	shape.shape = collider
	shape.position.y = 0.1
	add_child(shape)


func get_prompt(_player: Player) -> String:
	return "[E] Reproduzir fita" if not _played else "[E] Ouvir a fita novamente"


func interact(player: Player) -> void:
	_played = true
	if _static != null:
		_static.play()
	player.make_noise(3.0)
	var lines := [
		"FITA 03 — gravada em 9 de agosto, 03h17.",
		"Davi (na gravação): Eu não voltei aqui.",
		"Íris: Você nunca saiu.",
		"[A fita continua girando, embora tenha acabado.]",
	]
	for i in lines.size():
		get_tree().create_timer(i * 3.1).timeout.connect(player.notify.bind(lines[i]))
