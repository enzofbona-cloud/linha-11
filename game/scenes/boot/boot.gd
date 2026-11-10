extends Node3D
## Cena de verificação da Fase 2: prova que o render 3D funciona em cada
## plataforma. A lâmpada oscila de leve para deixar visível que o jogo
## está rodando (e não travado em um quadro).

@onready var _lamp: OmniLight3D = $Lamp

var _time := 0.0
var _base_energy := 1.0


func _ready() -> void:
	_base_energy = _lamp.light_energy


func _process(delta: float) -> void:
	_time += delta
	var flicker := sin(_time * 2.3) * 0.06 + sin(_time * 17.0) * 0.03
	_lamp.light_energy = _base_energy * (1.0 + flicker)
