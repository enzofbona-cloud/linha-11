class_name Keypad
extends StaticBody3D
## Fechadura eletrônica com senha. Só funciona com energia.

signal unlocked

var code := "0000"
var door: Door
var has_power := false
var solved := false


func get_prompt(_player: Player) -> String:
	if solved:
		return ""
	return "[E] Digitar a senha" if has_power else "[E] Teclado sem energia"


func interact(player: Player) -> void:
	if solved:
		return
	if not has_power:
		player.notify("O teclado está apagado. Sem energia.")
		return
	player.use_keypad(self)


## Devolve true se a senha estiver certa (e libera a porta).
func try_code(attempt: String) -> bool:
	if solved or attempt != code:
		return false
	solved = true
	if door != null:
		door.sealed = false
	unlocked.emit()
	return true
