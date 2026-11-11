extends GutTest


func _new_player() -> Player:
	var p := Player.new()
	add_child_autofree(p)
	return p


func _new_door(key := "") -> Door:
	var d := Door.new()
	d.locked_key = key
	d.animate = false
	add_child_autofree(d)
	return d


# --- controles ---

func test_todas_as_acoes_existem_com_tecla():
	for action in ["move_forward", "move_back", "move_left", "move_right", "sprint",
			"crouch", "walk_slow", "jump", "interact", "flashlight", "pause"]:
		assert_true(InputMap.has_action(action), action)
		assert_gt(InputMap.action_get_events(action).size(), 0, action)


# --- jogador ---

func test_velocidade_por_estado():
	assert_eq(Player.target_speed(false, false, false), Player.WALK_SPEED)
	assert_eq(Player.target_speed(true, false, false), Player.SPRINT_SPEED)
	assert_eq(Player.target_speed(false, true, false), Player.CROUCH_SPEED)
	assert_eq(Player.target_speed(false, false, true), Player.SLOW_SPEED)


func test_agachado_nao_corre():
	assert_eq(Player.target_speed(true, true, false), Player.CROUCH_SPEED)


func test_andar_devagar_vence_correr():
	assert_eq(Player.target_speed(true, false, true), Player.SLOW_SPEED)


func test_jogador_tem_camera_e_lanterna():
	var p := _new_player()
	assert_not_null(p.camera)
	assert_not_null(p.flashlight)
	assert_false(p.flashlight.visible, "lanterna começa apagada")


func test_lanterna_liga_e_desliga():
	var p := _new_player()
	p.toggle_flashlight()
	assert_true(p.flashlight.visible)
	p.toggle_flashlight()
	assert_false(p.flashlight.visible)


func test_inventario_adiciona_sem_duplicar():
	var p := _new_player()
	watch_signals(p)
	assert_false(p.has_item("chave_304"))
	p.add_item("chave_304", "Chave do 304")
	p.add_item("chave_304", "Chave do 304")
	assert_true(p.has_item("chave_304"))
	assert_eq(p.inventory.size(), 1)
	assert_signal_emit_count(p, "inventory_changed", 1)


# --- portas ---

func test_porta_destrancada_abre_e_fecha():
	var p := _new_player()
	var d := _new_door()
	assert_false(d.is_open)
	d.interact(p)
	assert_true(d.is_open)
	assert_almost_eq(d.rotation_degrees.y, d.open_angle_deg, 0.01)
	d.interact(p)
	assert_false(d.is_open)
	assert_almost_eq(d.rotation_degrees.y, 0.0, 0.01)


func test_porta_trancada_nao_abre_sem_chave():
	var p := _new_player()
	var d := _new_door("chave_304")
	watch_signals(p)
	d.interact(p)
	assert_false(d.is_open)
	assert_signal_emitted(p, "message")


func test_porta_trancada_abre_com_chave_e_fica_destrancada():
	var p := _new_player()
	var d := _new_door("chave_304")
	p.add_item("chave_304", "Chave do 304")
	d.interact(p)
	assert_true(d.is_open)
	assert_eq(d.locked_key, "")


func test_texto_da_porta_muda_com_o_estado():
	var p := _new_player()
	var d := _new_door()
	assert_string_contains(d.get_prompt(p), "Abrir")
	d.interact(p)
	assert_string_contains(d.get_prompt(p), "Fechar")


# --- itens ---

func test_pegar_item_coloca_no_inventario_e_remove_do_mundo():
	var p := _new_player()
	var item := Pickup.new()
	item.item_id = "chave_304"
	item.item_name = "Chave do 304"
	add_child(item)
	item.interact(p)
	assert_true(p.has_item("chave_304"))
	assert_true(item.is_queued_for_deletion())


# --- cenas ---

func test_prototipo_tem_jogador_portas_chave_e_telefone():
	var cena = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	add_child_autofree(cena)
	assert_not_null(cena.find_child("Player", true, false))
	assert_gte(get_tree().get_nodes_in_group("doors").size(), 3)
	assert_gte(get_tree().get_nodes_in_group("pickups").size(), 1)
	assert_not_null(cena.find_child("Phone", true, false))
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_menu_tem_botao_de_nova_campanha():
	var menu = load("res://game/ui/main_menu.tscn").instantiate()
	add_child_autofree(menu)
	var b = menu.find_child("NewGameButton", true, false)
	assert_not_null(b)
	assert_false(b.disabled)


func test_cena_principal_e_o_menu():
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://game/ui/main_menu.tscn")


# --- movimento real na cena (física) ---

func _spawn_prototype() -> Node:
	var cena = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	add_child_autofree(cena)
	return cena


func _release_all() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "sprint", "crouch", "jump"]:
		Input.action_release(a)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func test_andar_para_frente_move_o_jogador():
	var cena = _spawn_prototype()
	await wait_physics_frames(20)
	var p: Player = cena.player
	var z0 := p.global_position.z
	assert_true(p.is_on_floor(), "jogador deve estar apoiado no piso")
	Input.action_press("move_forward")
	await wait_physics_frames(60)
	_release_all()
	assert_lt(p.global_position.z, z0 - 1.5, "deveria ter avançado pelo corredor")
	assert_almost_eq(p.global_position.y, 0.0, 0.1, "não pode atravessar o piso")


func test_parede_bloqueia_o_jogador():
	var cena = _spawn_prototype()
	await wait_physics_frames(20)
	var p: Player = cena.player
	Input.action_press("move_right")
	await wait_physics_frames(120)
	_release_all()
	assert_lt(p.global_position.x, 1.2, "não pode atravessar a parede do corredor")


func test_correr_e_mais_rapido_que_andar():
	var cena = _spawn_prototype()
	await wait_physics_frames(20)
	var p: Player = cena.player
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await wait_physics_frames(45)
	var speed := Vector2(p.velocity.x, p.velocity.z).length()
	_release_all()
	assert_gt(speed, Player.WALK_SPEED + 1.0)


func test_pular_tira_o_jogador_do_chao_e_ele_volta():
	var cena = _spawn_prototype()
	await wait_physics_frames(20)
	var p: Player = cena.player
	Input.action_press("jump")
	await wait_physics_frames(8)
	Input.action_release("jump")
	assert_gt(p.global_position.y, 0.15)
	await wait_physics_frames(90)
	_release_all()
	assert_true(p.is_on_floor())


func test_porta_fechada_bloqueia_e_aberta_deixa_passar():
	var cena = _spawn_prototype()
	await wait_physics_frames(20)
	var p: Player = cena.player
	var door: Door = cena.get_node("Door302")
	door.animate = false
	p.global_position = Vector3(0, 0.05, -5.5)
	await wait_physics_frames(5)
	Input.action_press("move_left")
	await wait_physics_frames(90)
	assert_gt(p.global_position.x, -1.3, "porta fechada deve bloquear")
	door.interact(p)
	await wait_physics_frames(90)
	_release_all()
	assert_lt(p.global_position.x, -1.6, "porta aberta deve deixar entrar no 302")


# --- captura do mouse (PlaySession) ---

func test_durante_o_jogo_o_cursor_deve_ficar_preso():
	assert_true(PlaySession.wants_capture(false, false, false, false, false))


func test_cursor_fica_solto_na_pausa_no_fim_no_teclado_e_no_toque():
	assert_false(PlaySession.wants_capture(true, false, false, false, false), "pausado")
	assert_false(PlaySession.wants_capture(false, true, false, false, false), "fim de capítulo")
	assert_false(PlaySession.wants_capture(false, false, true, false, false), "teclado de senha")
	assert_false(PlaySession.wants_capture(false, false, false, true, false), "toque")
	assert_false(PlaySession.wants_capture(false, false, false, false, true), "modo sem captura")


func test_camera_so_gira_com_o_mouse_quando_liberada_pela_sessao():
	var p := Player.new()
	add_child_autofree(p)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(120, 0)
	p.look_enabled = false
	p._unhandled_input(motion)
	assert_almost_eq(p.rotation.y, 0.0, 0.0001, "sem captura não gira")
	p.look_enabled = true
	p._unhandled_input(motion)
	assert_lt(p.rotation.y, -0.1, "com captura gira para a direita")


func test_pausar_e_retomar_pela_sessao():
	var cena = _spawn_prototype()
	await wait_physics_frames(3)
	cena.session.pause()
	assert_true(get_tree().paused)
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE)
	cena.session.resume()
	assert_false(get_tree().paused)


func test_teclado_de_senha_precisa_do_cursor_e_documento_nao():
	var modal := ModalLayer.new()
	add_child_autofree(modal)
	modal.open_document("t", "c")
	assert_false(modal.needs_cursor())
	modal.close()
	var k := Keypad.new()
	add_child_autofree(k)
	modal.open_keypad(k)
	assert_true(modal.needs_cursor())
