class_name Readable
extends StaticBody3D
## Documento que pode ser lido (aviso, diário, transcrição).

signal read

var title := ""
var body := ""
var _was_read := false


func _init() -> void:
	add_to_group("readables")


func get_prompt(_player: Player) -> String:
	return "[E] Ler: %s" % title


func interact(player: Player) -> void:
	player.read_document(title, body)
	if not _was_read:
		_was_read = true
		read.emit()
