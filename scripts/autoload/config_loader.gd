extends Node

var razas: Array = []
var sexos: Array = []
var acciones: Array = []

func _ready():
	load_configs()

func load_configs():
	_load_json("res://data/razas.json", func(data): razas = data["razas"])
	_load_json("res://data/sexos.json", func(data): sexos = data["sexos"])
	_load_json("res://data/acciones_rol.json", func(data): acciones = data["acciones"])

func _load_json(path: String, callback: Callable):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json:
			callback.call(json)
		else:
			push_error("Error parseando JSON: ", path)
	else:
		push_error("No se pudo abrir archivo: ", path)

func get_raza(id: String) -> Dictionary:
	for r in razas:
		if r["id"] == id:
			return r
	return {}

func get_sexo(id: String) -> Dictionary:
	for s in sexos:
		if s["id"] == id:
			return s
	return {}
