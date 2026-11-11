extends GutTest
## Móvel revistável: base das etapas de busca do capítulo 1.


func _player() -> Player:
	var p := Player.new()
	add_child_autofree(p)
	return p


func _searchable() -> Searchable:
	var c := Searchable.new()
	add_child_autofree(c)
	return c


func test_gaveta_vazia_abre_e_avisa():
	var p := _player()
	var c := _searchable()
	watch_signals(p)
	watch_signals(c)
	c.interact(p)
	assert_true(c.is_open)
	assert_signal_emitted(c, "opened")
	assert_signal_emitted_with_parameters(p, "message", ["Vazia."])
	assert_eq(c.get_prompt(p), "", "depois de revistada não oferece mais nada")


func test_gaveta_com_item_entrega_uma_vez_so():
	var p := _player()
	var c := _searchable()
	c.item_id = "chave_pequena"
	c.item_name = "Chave pequena"
	watch_signals(c)
	c.interact(p)
	c.interact(p)
	assert_true(p.has_item("chave_pequena"))
	assert_signal_emit_count(c, "item_found", 1)


func test_gaveta_trancada_exige_a_chave_e_a_consome():
	var p := _player()
	var c := _searchable()
	c.locked_key = "chave_pequena"
	c.item_id = "fusivel"
	c.item_name = "Fusível"
	c.interact(p)
	assert_false(c.is_open, "sem a chave não abre")
	assert_false(p.has_item("fusivel"))
	assert_true(c.get_prompt(p).contains("trancada"))
	p.add_item("chave_pequena", "Chave pequena")
	c.interact(p)
	assert_true(c.is_open)
	assert_true(p.has_item("fusivel"))
	assert_false(p.has_item("chave_pequena"), "a chave fica na fechadura")
