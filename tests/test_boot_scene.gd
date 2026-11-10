extends GutTest


func test_boot_carrega_e_instancia():
	var cena = load("res://game/scenes/boot/boot.tscn")
	assert_not_null(cena)
	var inst = cena.instantiate()
	add_child_autofree(inst)
	assert_not_null(inst.get_node_or_null("Camera3D"))
	assert_not_null(inst.find_child("BuildLabel", true, false))
	assert_not_null(inst.find_child("FpsLabel", true, false))


func test_texto_do_build_contem_versao_e_commit():
	var hud = load("res://game/ui/debug_hud.tscn").instantiate()
	add_child_autofree(hud)
	assert_string_contains(hud.build_text(), "LINHA 11")
	assert_string_contains(hud.build_text(), BuildInfo.version)
	assert_string_contains(hud.build_text(), BuildInfo.commit)


func test_cena_principal_do_projeto_e_o_boot():
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), "res://game/scenes/boot/boot.tscn")
