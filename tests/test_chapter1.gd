extends GutTest
## Mecânicas do Capítulo 1: ruído, Ouvinte, fusível, senha, documentos e a sequência da fase.


func _player() -> Player:
	var p := Player.new()
	add_child_autofree(p)
	return p


func _listener() -> Listener:
	var l := Listener.new()
	l.z_min = -15.0
	l.z_max = -1.0
	add_child_autofree(l)
	l.position = Vector3(0, 0, -2)
	l.wake()
	return l


func after_each():
	for a in ["move_forward", "move_back", "move_left", "move_right", "sprint", "crouch", "jump", "walk_slow"]:
		Input.action_release(a)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# --- ruído do jogador ---

func test_parado_nao_faz_barulho():
	assert_eq(Player.noise_radius_for(false, false, false, false), 0.0)


func test_correr_faz_mais_barulho_que_andar():
	var andar := Player.noise_radius_for(true, false, false, false)
	var correr := Player.noise_radius_for(true, true, false, false)
	assert_gt(andar, 0.0)
	assert_gt(correr, andar)


func test_agachado_ou_devagar_e_silencioso():
	assert_eq(Player.noise_radius_for(true, false, true, false), 0.0)
	assert_eq(Player.noise_radius_for(true, false, false, true), 0.0)
	assert_eq(Player.noise_radius_for(true, true, true, false), 0.0, "agachado não corre")


# --- Ouvinte ---

func test_ouvir_depende_da_distancia_e_do_raio():
	assert_true(Listener.hears(5.0, 6.0))
	assert_false(Listener.hears(7.0, 6.0))
	assert_false(Listener.hears(1.0, 0.0), "silêncio nunca é ouvido")


func test_ouvinte_dormindo_ignora_som():
	var l := Listener.new()
	add_child_autofree(l)
	l.hear(Vector3(0, 0, -3), 20.0)
	assert_eq(l.state, Listener.State.DORMANT)


func test_som_distante_faz_investigar():
	var l := _listener()
	l.hear(Vector3(0, 0, -12), 12.0)
	assert_eq(l.state, Listener.State.INVESTIGATE)
	assert_almost_eq(l.target_z, -12.0, 0.01)


func test_som_proximo_faz_perseguir():
	var l := _listener()
	l.hear(Vector3(0, 0, -4), 6.0)
	assert_eq(l.state, Listener.State.CHASE)


func test_som_fora_do_alcance_e_ignorado():
	var l := _listener()
	l.hear(Vector3(0, 0, -14), 5.0)
	assert_eq(l.state, Listener.State.PATROL)


func test_perseguindo_ele_anda_ate_o_som():
	var l := _listener()
	l.hear(Vector3(0, 0, -5), 6.0)
	var z0 := l.position.z
	for i in 30:
		l.tick(1.0 / 60.0, Vector3(5, 0, -30))
	assert_lt(l.position.z, z0 - 1.0)


func test_silencio_faz_perder_o_rastro():
	var l := _listener()
	l.hear(Vector3(0, 0, -4), 6.0)
	for i in int((Listener.LOSE_TIME + Listener.SEARCH_TIME + 3.0) * 60):
		l.tick(1.0 / 60.0, Vector3(5, 0, -30))
	assert_eq(l.state, Listener.State.PATROL)


func test_alcanca_jogador_no_corredor():
	var l := _listener()
	watch_signals(l)
	l.tick(1.0 / 60.0, Vector3(0.3, 0, -2.4))
	assert_signal_emitted(l, "caught")


func test_nao_alcanca_jogador_dentro_de_um_comodo():
	var l := _listener()
	watch_signals(l)
	l.tick(1.0 / 60.0, Vector3(-3.5, 0, -2.2))
	assert_signal_not_emitted(l, "caught")


func test_ele_nao_sai_do_corredor():
	var l := _listener()
	l.hear(Vector3(0, 0, -40), 100.0)
	for i in 60 * 20:
		l.tick(1.0 / 60.0, Vector3(5, 0, -30))
	assert_gte(l.position.z, l.z_min - 0.01)


# --- fusível ---

func test_quadro_sem_fusivel_nao_liga():
	var p := _player()
	var box := FuseBox.new()
	add_child_autofree(box)
	watch_signals(box)
	box.interact(p)
	assert_false(box.powered)
	assert_signal_not_emitted(box, "power_restored")


func test_quadro_com_fusivel_liga_e_gasta_o_fusivel():
	var p := _player()
	p.add_item("fusivel", "Fusível")
	var box := FuseBox.new()
	add_child_autofree(box)
	watch_signals(box)
	box.interact(p)
	assert_true(box.powered)
	assert_false(p.has_item("fusivel"))
	assert_signal_emitted(box, "power_restored")


# --- senha ---

func test_senha_errada_mantem_porta_lacrada():
	var d := Door.new()
	d.animate = false
	d.sealed = true
	add_child_autofree(d)
	var k := Keypad.new()
	k.code = "0317"
	k.door = d
	k.has_power = true
	add_child_autofree(k)
	assert_false(k.try_code("1234"))
	assert_true(d.sealed)
	d.interact(_player())
	assert_false(d.is_open)


func test_senha_certa_libera_a_porta():
	var d := Door.new()
	d.animate = false
	d.sealed = true
	add_child_autofree(d)
	var k := Keypad.new()
	k.code = "0317"
	k.door = d
	k.has_power = true
	add_child_autofree(k)
	assert_true(k.try_code("0317"))
	assert_false(d.sealed)
	d.interact(_player())
	assert_true(d.is_open)


func test_teclado_sem_energia_nao_abre_painel():
	var p := _player()
	var k := Keypad.new()
	add_child_autofree(k)
	watch_signals(p)
	k.interact(p)
	assert_signal_not_emitted(p, "keypad_requested")
	assert_signal_emitted(p, "message")


# --- documentos ---

func test_ler_documento_pede_painel_com_titulo_e_texto():
	var p := _player()
	var doc := Readable.new()
	doc.title = "Aviso"
	doc.body = "Texto"
	add_child_autofree(doc)
	watch_signals(p)
	doc.interact(p)
	assert_signal_emitted_with_parameters(p, "document_requested", ["Aviso", "Texto"])


# --- sequência do capítulo ---

func test_capitulo_comeca_sem_energia_e_com_ouvinte_dormindo():
	var cena = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	add_child_autofree(cena)
	await wait_physics_frames(5)
	assert_false(cena.power_on)
	assert_true(cena.player.flashlight.visible, "lanterna deve iniciar ligada para o corredor ser visivel" )
	assert_eq(cena.listener.state, Listener.State.DORMANT)
	assert_true(cena.get_node("Door303").sealed)


func test_fusivel_liga_a_energia_e_o_telefone():
	var cena = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	add_child_autofree(cena)
	await wait_physics_frames(5)
	cena.player.add_item("fusivel", "Fusível")
	cena.get_node("FuseBox").interact(cena.player)
	assert_true(cena.power_on)
	assert_true(cena.get_node("Keypad303").has_power)


func test_pegar_a_chave_acorda_o_ouvinte_e_apaga_a_luz():
	var cena = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	add_child_autofree(cena)
	await wait_physics_frames(5)
	cena.player.add_item("fusivel", "Fusível")
	cena.get_node("FuseBox").interact(cena.player)
	cena.get_node("Key304").interact(cena.player)
	assert_false(cena.power_on)
	assert_ne(cena.listener.state, Listener.State.DORMANT)


func test_ser_pego_devolve_ao_ponto_seguro():
	var cena = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	add_child_autofree(cena)
	await wait_physics_frames(5)
	cena.player.add_item("fusivel", "Fusível")
	cena.get_node("FuseBox").interact(cena.player)
	cena.get_node("Key304").interact(cena.player)
	cena.player.global_position = Vector3(0, 0.05, -6)
	cena.on_caught()
	await wait_seconds(0.6)
	assert_gt(cena.player.global_position.x, 1.5, "deve voltar para dentro do 303")
	assert_true(cena.player.has_item("chave_304"), "não perde a chave")


func test_capitulo_inteiro_do_inicio_ao_fim():
	var cena = load("res://game/scenes/prototype/prototype.tscn").instantiate()
	add_child_autofree(cena)
	await wait_physics_frames(5)
	var p: Player = cena.player
	# 302: fusível
	cena.get_node("Fuse").interact(p)
	assert_true(p.has_item("fusivel"))
	# quadro de força
	cena.get_node("FuseBox").interact(p)
	assert_true(cena.power_on)
	assert_true(cena.get_node("Phone").is_ringing, "telefone começa a tocar com a energia")
	# senha do 303
	var teclado: Keypad = cena.get_node("Keypad303")
	assert_false(teclado.try_code("1109"))
	assert_true(teclado.try_code("0317"))
	var porta303: Door = cena.get_node("Door303")
	porta303.animate = false
	porta303.interact(p)
	assert_true(porta303.is_open)
	# chave: a luz cai e o Ouvinte acorda
	cena.get_node("Key304").interact(p)
	assert_false(cena.power_on)
	assert_ne(cena.listener.state, Listener.State.DORMANT)
	# porta do 304 abre com a chave
	var porta304: Door = cena.get_node("Door304")
	porta304.animate = false
	porta304.interact(p)
	assert_true(porta304.is_open)
	# dentro do 304 o Ouvinte para
	p.global_position = Vector3(0, 0.05, -18.5)
	await wait_physics_frames(5)
	assert_eq(cena.listener.state, Listener.State.DORMANT)
	# telefone
	var telefone: Phone = cena.get_node("Phone")
	telefone.line_interval = 0.05
	telefone.interact(p)
	await wait_seconds(0.6)
	assert_true(cena.chapter_ended)


# --- animação do Ouvinte ---

func test_ouvinte_anima_a_passada_conforme_anda():
	var l := _listener()
	l.hear(Vector3(0, 0, -12), 100.0)
	var antes: float = l.animation_state().gait_phase
	for i in 60:
		l.tick(1.0 / 60.0, Vector3(5, 0, -30))
	var depois = l.animation_state()
	assert_gt(depois.gait_phase, antes + 1.0, "a fase da passada avança com a distância")
	assert_gt(depois.walk, 0.5, "está em ritmo de caminhada")


func test_ouvinte_parado_quase_nao_marcha():
	var l := _listener()
	l.state = Listener.State.INVESTIGATE
	l.target_z = l.position.z
	for i in 60:
		l.tick(1.0 / 60.0, Vector3(5, 0, -30))
	assert_lt(l.animation_state().walk, 0.2)


func test_ouvinte_nao_da_salto_na_animacao_ao_acordar():
	var l := _listener()
	var before: float = l.animation_state().gait_phase
	l.tick(1.0 / 60.0, Vector3(5, 0, -30))
	var phase_delta: float = l.animation_state().gait_phase - before
	assert_lt(phase_delta, 0.1, "a primeira passada mede o deslocamento desde o spawn")
	assert_lt(l.animation_state().walk, 0.2, "não acelera como se tivesse teletransportado")


func test_ouvinte_tem_modelo_3d_articulado_sem_billboard():
	var l := _listener()
	assert_null(l.find_child("CreatureSprite", true, false))
	assert_not_null(l.find_child("LeftArm", true, false))
	assert_not_null(l.find_child("RightArm", true, false))
	assert_not_null(l.find_child("LeftLeg", true, false))
	assert_not_null(l.find_child("RightLeg", true, false))
	var meshes := l.find_children("*", "MeshInstance3D", true, false)
	assert_gte(meshes.size(), 20)
	for candidate in meshes:
		assert_false((candidate as MeshInstance3D).mesh is QuadMesh, "o Ouvinte deve ter volume, não ser uma imagem plana")


# --- sons gravados ---

func test_gravacoes_reais_existem_para_passos_portas_e_trinco():
	for nome in SoundKit.FOOTSTEPS + SoundKit.DOOR_OPEN + SoundKit.DOOR_CLOSE + SoundKit.CREAKS + ["metallatch", "metalclick"]:
		assert_not_null(SoundKit.sfx(nome), nome)


func test_sorteio_de_passos_nao_repete_o_anterior():
	var anterior: AudioStream = SoundKit.pick(SoundKit.FOOTSTEPS)
	for i in 30:
		var atual: AudioStream = SoundKit.pick(SoundKit.FOOTSTEPS)
		assert_ne(atual, anterior)
		anterior = atual
