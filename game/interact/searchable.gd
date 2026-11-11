class_name Searchable
extends StaticBody3D
## Móvel revistável (gaveta, guarda-roupa, caixa). O jogador aperta [E] para
## revistar: pode estar trancado, pode ter um item dentro, ou só um comentário.

signal opened
signal item_found(id: String)

## Nome mostrado no aviso: "[E] Revistar a gaveta".
@export var label := "a gaveta"
## Item do inventário necessário para abrir ("" = destrancado).
@export var locked_key := ""
@export var locked_text := "Trancada. A fechadura é pequena."
## Item guardado aqui ("" = nada).
@export var item_id := ""
@export var item_name := ""
## Texto quando não há nada (ou depois de já ter pegado o item).
@export var empty_text := "Vazia."
## A chave some do inventário depois de usada.
@export var consume_key := true

var is_open := false
var _audio: AudioStreamPlayer3D


func _init() -> void:
	add_to_group("interactables")


func _ready() -> void:
	_audio = SoundKit.player_3d(self, SoundKit.pick(SoundKit.CREAKS), 10.0, -8.0)


func get_prompt(player: Player) -> String:
	if is_open:
		return ""
	if locked_key != "" and not player.has_item(locked_key):
		return "[E] Revistar %s (trancada)" % label
	return "[E] Revistar %s" % label


func interact(player: Player) -> void:
	if is_open:
		return
	if locked_key != "":
		if not player.has_item(locked_key):
			player.notify(locked_text)
			return
		if consume_key:
			player.remove_item(locked_key)
	is_open = true
	if _audio != null and is_inside_tree():
		_audio.stream = SoundKit.pick(SoundKit.CREAKS)
		_audio.play()
	player.make_noise(3.0)
	opened.emit()
	if item_id == "":
		player.notify(empty_text)
		return
	player.add_item(item_id, item_name)
	player.play_sfx(SoundKit.pick(SoundKit.PICKUPS), -6.0)
	player.notify("Você achou: %s." % item_name)
	item_found.emit(item_id)
