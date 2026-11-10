class_name Phone
extends StaticBody3D
## O telefone que toca sem energia. Atender encerra o protótipo.

signal answered

const LINES := [
	"…chiado…",
	"\"Linha 11. Vocês demoraram dezessete anos.\"",
	"\"Não desliguem. Ele ouve quando vocês desligam.\"",
]

var _answered := false
var _led: MeshInstance3D
var _time := 0.0


func _init() -> void:
	name = "Phone"


func set_led(led: MeshInstance3D) -> void:
	_led = led


func _process(delta: float) -> void:
	_time += delta
	if _led != null and not _answered:
		_led.visible = fmod(_time, 1.2) < 0.6


func get_prompt(_player: Player) -> String:
	return "" if _answered else "[E] Atender o telefone"


func interact(player: Player) -> void:
	if _answered:
		return
	_answered = true
	if _led != null:
		_led.visible = true
	for i in LINES.size():
		get_tree().create_timer(i * 3.2).timeout.connect(player.notify.bind(LINES[i]))
	get_tree().create_timer(LINES.size() * 3.2).timeout.connect(func(): answered.emit())
