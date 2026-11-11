class_name PhoneSequence
extends Node
## Puzzle de três tons do apartamento 304.

signal solved
signal progress_changed(progress: int)

const ANSWER := [0, 2, 1] # grave, agudo, médio
var entered: Array[int] = []
var is_solved := false


func press(tone: int, player: Player) -> void:
	if is_solved:
		return
	entered.append(tone)
	var idx := entered.size() - 1
	if idx >= ANSWER.size() or entered[idx] != ANSWER[idx]:
		entered.clear()
		progress_changed.emit(0)
		player.notify("A sequência se desfaz. Os aparelhos ficam mudos.")
		return
	progress_changed.emit(entered.size())
	if entered.size() == ANSWER.size():
		is_solved = true
		player.notify("Os três toques se alinham. Uma fechadura destrava ao fundo.")
		solved.emit()
	else:
		player.notify("O tom permanece no ar. (%d/3)" % entered.size())
