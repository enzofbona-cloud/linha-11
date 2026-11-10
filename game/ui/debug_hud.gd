extends CanvasLayer
## HUD de depuração: identificação do build e contador de FPS.

const FPS_INTERVAL := 0.5

@onready var _build_label: Label = %BuildLabel
@onready var _fps_label: Label = %FpsLabel

var _elapsed := 0.0


func _ready() -> void:
	_build_label.text = build_text()
	_fps_label.text = "FPS: --"


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= FPS_INTERVAL:
		_elapsed = 0.0
		_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()


func build_text() -> String:
	var parts := PackedStringArray(["LINHA 11 v%s" % BuildInfo.version, BuildInfo.commit])
	if BuildInfo.date != "":
		parts.append(BuildInfo.date)
	return " · ".join(parts)
