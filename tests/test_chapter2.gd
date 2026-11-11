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


func test_menu_permite_ir_direto_ao_capitulo_2():
	var menu = load("res://game/ui/main_menu.tscn").instantiate()
	add_child_autofree(menu)
	var b = menu.find_child("Chapter2Button", true, false)
	assert_not_null(b)
	assert_false(b.disabled)


func test_capitulo_2_do_inicio_ao_fim():
	var scene = load("res://game/scenes/chapter2/apartment_304.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(3)
	var p: Player = scene.player
	assert_true(scene.exit_door.sealed)
	scene.get_node("SequencePhone0").interact(p)
	scene.get_node("SequencePhone2").interact(p)
	scene.get_node("SequencePhone1").interact(p)
	assert_true(scene.puzzle.is_solved)
	assert_false(scene.exit_door.sealed)
	scene.exit_door.animate = false
	scene.exit_door.interact(p)
	assert_true(scene.exit_door.is_open)
	p.global_position = Vector3(0, 0.05, -31.0)
	await wait_physics_frames(6)
	assert_true(scene.chapter_ended)
	assert_true(scene.session.ended)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_capitulo_2_tem_luz_suficiente_para_jogar():
	var scene = load("res://game/scenes/chapter2/apartment_304.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(1)
	var luzes := 0
	for child in scene.get_children():
		if child is OmniLight3D:
			luzes += 1
	assert_gte(luzes, 8, "abajures ao longo do apartamento")
	assert_almost_eq(scene.player.flashlight.light_energy, 6.0, 0.01, "lanterna com a força padrão")
	get_tree().paused = false


func test_cada_telefone_fica_em_um_comodo_diferente_e_mobiliado():
	var scene = load("res://game/scenes/chapter2/apartment_304.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(2)
	var comodos := {}
	for i in 3:
		var fone: Node3D = scene.get_node("SequencePhone%d" % i)
		assert_gt(absf(fone.position.x), 1.2, "telefone dentro de um cômodo, não no corredor")
		comodos[scene._room_index(fone.position.z, scene.LEFT_PARTITIONS)] = true
	assert_eq(comodos.size(), 3, "sala, quarto e escritório")
	for grupo in ["living", "dining", "bedroom", "boy", "office", "storage", "hall"]:
		var total := get_tree().get_nodes_in_group("room_props_ch2_" + grupo).size()
		assert_gte(total, 12, "cômodo '%s' mobiliado" % grupo)
	get_tree().paused = false


func test_moveis_do_304_ficam_dentro_das_paredes():
	var scene = load("res://game/scenes/chapter2/apartment_304.tscn").instantiate()
	add_child_autofree(scene)
	await wait_physics_frames(2)
	for node in get_tree().get_nodes_in_group("room_props_chapter2"):
		var pos: Vector3 = (node as Node3D).position
		assert_lt(absf(pos.x), 5.85, "%s atravessa a parede de fora" % node.name)
		assert_between(pos.z, -28.9, 4.95, "%s fora do apartamento" % node.name)
	get_tree().paused = false
