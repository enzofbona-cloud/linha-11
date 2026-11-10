class_name FuseBox
extends StaticBody3D
## Quadro de força. Precisa de um fusível para religar a energia.

signal power_restored

const FUSE_ID := "fusivel"

var powered := false


func _init() -> void:
	name = "FuseBox"


func get_prompt(player: Player) -> String:
	if powered:
		return ""
	return "[E] Colocar o fusível" if player.has_item(FUSE_ID) else "[E] Examinar o quadro de força"


func interact(player: Player) -> void:
	if powered:
		return
	if not player.has_item(FUSE_ID):
		player.notify("Falta um fusível. O encaixe está queimado e vazio.")
		return
	player.remove_item(FUSE_ID)
	powered = true
	player.make_noise(Player.NOISE_DOOR)
	player.notify("O fusível encaixou. As luzes voltaram.")
	power_restored.emit()
