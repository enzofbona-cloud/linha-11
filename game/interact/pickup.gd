class_name Pickup
extends StaticBody3D
## Item que pode ser pego e vai para o inventário do jogador.

signal picked(id: String)

@export var item_id := ""
@export var item_name := ""


func _init() -> void:
	add_to_group("pickups")


func get_prompt(_player: Player) -> String:
	return "[E] Pegar %s" % item_name


func interact(player: Player) -> void:
	player.add_item(item_id, item_name)
	player.notify("Você pegou: %s" % item_name)
	player.play_sfx(SoundKit.pick(SoundKit.PICKUPS), -3.0)
	picked.emit(item_id)
	queue_free()
