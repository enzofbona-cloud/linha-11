extends GutTest


func test_puzzle_aceita_grave_agudo_medio_e_destrava():
	var puzzle := PhoneSequence.new()
	add_child_autofree(puzzle)
	var player := Player.new()
	add_child_autofree(player)
	watch_signals(puzzle)
	puzzle.press(0, player)
	puzzle.press(2, player)
	puzzle.press(1, player)
	assert_true(puzzle.is_solved)
	assert_signal_emitted(puzzle, "solved")


func test_puzzle_reinicia_se_a_ordem_estiver_errada():
	var puzzle := PhoneSequence.new()
	add_child_autofree(puzzle)
	var player := Player.new()
	add_child_autofree(player)
	puzzle.press(0, player)
	puzzle.press(1, player)
	assert_false(puzzle.is_solved)
	assert_eq(puzzle.entered.size(), 0)


func test_apartamento_tem_foto_fita_e_tres_telefones():
	var scene = load("res://game/scenes/chapter2/apartment_304.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(2)
	assert_not_null(scene.get_node_or_null("FamilyPhoto304Image"))
	assert_not_null(scene.get_node_or_null("FutureArgumentTape"))
	assert_not_null(scene.get_node_or_null("SequencePhone0"))
	assert_not_null(scene.get_node_or_null("SequencePhone1"))
	assert_not_null(scene.get_node_or_null("SequencePhone2"))


func test_resolver_sequencia_abre_a_porta_impossivel():
	var scene = load("res://game/scenes/chapter2/apartment_304.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(1)
	scene._on_sequence_solved()
	assert_false(scene.exit_door.sealed)


func test_fim_do_capitulo_1_exibe_botao_para_continuar():
	var modal := ModalLayer.new()
	add_child_autofree(modal)
	modal.show_ending("O PRIMEIRO CHAMADO", "", "res://game/scenes/chapter2/apartment_304.tscn")
	assert_true(modal._ending_continue.visible)
	assert_eq(modal._ending_next_scene, "res://game/scenes/chapter2/apartment_304.tscn")
