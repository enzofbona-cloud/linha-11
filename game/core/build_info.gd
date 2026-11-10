extends Node
## Informações do build atual (versão, commit, data, canal).
## No CI, `res://build_info.json` é gerado antes do export.
## Fora do CI o arquivo não existe e tudo vale "dev-local".

const BUILD_FILE := "res://build_info.json"
const DEFAULTS := {
	"version": "dev-local",
	"commit": "dev-local",
	"date": "",
	"channel": "local",
}

var version: String
var commit: String
var date: String
var channel: String


func _ready() -> void:
	var d := read_file(BUILD_FILE)
	version = d.version
	commit = d.commit
	date = d.date
	channel = d.channel


## Lê um arquivo de build. Sempre devolve as quatro chaves; qualquer
## problema (arquivo ausente, JSON inválido, chave faltando) cai no padrão.
static func read_file(path: String) -> Dictionary:
	var result := DEFAULTS.duplicate()
	if not FileAccess.file_exists(path):
		return result
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return result
	if typeof(json.data) != TYPE_DICTIONARY:
		return result
	for key in DEFAULTS:
		if typeof(json.data.get(key)) == TYPE_STRING:
			result[key] = json.data[key]
	return result
