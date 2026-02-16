class_name AvatarData extends RefCounted

var id: String
var nombre: String
var descripcion: String
var imagen_url: String
var raza_id: String
var sexo_id: String

func _init(p_id: String = "", p_nombre: String = "", p_descripcion: String = "", p_imagen: String = "", p_raza: String = "", p_sexo: String = ""):
	id = p_id if p_id else _generate_uuid()
	nombre = p_nombre
	descripcion = p_descripcion
	imagen_url = p_imagen
	raza_id = p_raza
	sexo_id = p_sexo

func to_dict() -> Dictionary:
	return {
		"id": id,
		"nombre": nombre,
		"descripcion": descripcion,
		"imagen_url": imagen_url,
		"raza_id": raza_id,
		"sexo_id": sexo_id
	}

static func from_dict(data: Dictionary) -> AvatarData:
	var avatar = AvatarData.new(
		data.get("id", ""),
		data.get("nombre", ""),
		data.get("descripcion", ""),
		data.get("imagen_url", ""),
		data.get("raza_id", ""),
		data.get("sexo_id", "")
	)
	return avatar

func _generate_uuid() -> String:
	# Simple UUID v4-like (no es necesario perfecto para MVP)
	var hex = "0123456789abcdef"
	var uuid = ""
	for i in range(36):
		if i == 8 or i == 13 or i == 18 or i == 23:
			uuid += "-"
		else:
			uuid += hex[randi() % 16]
	return uuid
