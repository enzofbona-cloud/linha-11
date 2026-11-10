class_name Phone
extends StaticBody3D
## O telefone que toca sem energia. Atender encerra o capítulo.

signal answered
signal call_finished

## Segundos entre as falas (variável para os testes poderem acelerar).
var line_interval := 3.6
const LINES := [
	"…chiado…",
	"\"Linha 11. Vocês demoraram dezessete anos.\"",
	"\"Tira o menino do 304. Agora. Antes das três e dezessete.\"",
	"\"…Davi? É você que está ouvindo?\"",
]

var is_ringing := false
var _answered := false
var _led: MeshInstance3D
var _time := 0.0
var _ring: AudioStreamPlayer3D
var _static: AudioStreamPlayer3D


func _init() -> void:
	name = "Phone"


func _ready() -> void:
	_ring = SoundKit.player_3d(self, SoundKit.ring(), 30.0, 2.0)
	_static = SoundKit.player_3d(self, SoundKit.static_noise(), 8.0, -6.0)


func set_led(led: MeshInstance3D) -> void:
	_led = led
	_led.visible = false


func start_ringing() -> void:
	if _answered or is_ringing:
		return
	is_ringing = true
	if _ring != null:
		_ring.play()


func _process(delta: float) -> void:
	_time += delta
	if _led != null and is_ringing:
		_led.visible = fmod(_time, 1.2) < 0.6


func get_prompt(_player: Player) -> String:
	return "" if _answered else "[E] Atender o telefone"


func interact(player: Player) -> void:
	if _answered:
		return
	_answered = true
	is_ringing = false
	if _ring != null:
		_ring.stop()
		_static.play()
	if _led != null:
		_led.visible = true
	answered.emit()
	for i in LINES.size():
		get_tree().create_timer(i * line_interval).timeout.connect(player.notify.bind(LINES[i]))
	get_tree().create_timer(LINES.size() * line_interval).timeout.connect(func():
		if _static != null:
			_static.stop()
		call_finished.emit())
