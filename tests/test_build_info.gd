extends GutTest


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_arquivo_ausente_devolve_dev_local():
	var d = BuildInfo.read_file("res://nao_existe.json")
	assert_eq(d.version, "dev-local")
	assert_eq(d.commit, "dev-local")
	assert_eq(d.channel, "local")


func test_json_invalido_devolve_dev_local():
	_write("user://ruim.json", "{isto nao e json")
	assert_eq(BuildInfo.read_file("user://ruim.json").version, "dev-local")


func test_arquivo_valido_devolve_valores():
	_write("user://ok.json", '{"version":"0.1.0","commit":"abc1234","date":"2026-11-10T12:00:00Z","channel":"dev"}')
	var d = BuildInfo.read_file("user://ok.json")
	assert_eq(d.version, "0.1.0")
	assert_eq(d.commit, "abc1234")
	assert_eq(d.date, "2026-11-10T12:00:00Z")
	assert_eq(d.channel, "dev")


func test_chave_faltando_usa_padrao():
	_write("user://parcial.json", '{"version":"0.1.0"}')
	var d = BuildInfo.read_file("user://parcial.json")
	assert_eq(d.version, "0.1.0")
	assert_eq(d.commit, "dev-local")


func test_json_que_nao_e_objeto_devolve_dev_local():
	_write("user://lista.json", '[1,2,3]')
	assert_eq(BuildInfo.read_file("user://lista.json").version, "dev-local")
