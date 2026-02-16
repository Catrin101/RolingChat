extends Node
## Gestor global de avatares
## Maneja carga, guardado y gestión del avatar actual del jugador

var current_avatar: AvatarData = null
var profiles_path: String = "user://profiles/"

func _ready():
	# Crear carpeta de perfiles si no existe
	if not DirAccess.dir_exists_absolute(profiles_path):
		DirAccess.make_dir_absolute(profiles_path)
	print("[AvatarManager] Inicializado. Ruta de perfiles: ", profiles_path)

# ✅ CORRECCIÓN: Tipo de retorno explícito Array[String]
func list_profiles() -> Array[String]:
	var files: Array[String] = []  # ✅ Array tipado
	var dir = DirAccess.open(profiles_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".json"):
				# Remover la extensión .json
				files.append(file_name.replace(".json", ""))
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("[AvatarManager] Encontrados ", files.size(), " perfiles")
	else:
		push_error("[AvatarManager] No se pudo abrir el directorio de perfiles")
	
	return files

func load_profile(name: String) -> AvatarData:
	var path = profiles_path + name + ".json"
	
	if not FileAccess.file_exists(path):
		push_error("[AvatarManager] Perfil no encontrado: ", path)
		return null
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("[AvatarManager] No se pudo abrir archivo: ", path)
		return null
	
	var text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(text)
	if not data:
		push_error("[AvatarManager] JSON inválido en: ", path)
		return null
	
	var avatar = AvatarData.from_dict(data)
	print("[AvatarManager] Perfil cargado: ", avatar.nombre)
	return avatar

func save_profile(avatar: AvatarData, name: String) -> bool:
	if not avatar:
		push_error("[AvatarManager] Intento de guardar avatar null")
		return false
	
	if name.is_empty():
		push_error("[AvatarManager] Nombre de perfil vacío")
		return false
	
	# Sanitizar nombre de archivo
	var safe_name = _sanitize_filename(name)
	var path = profiles_path + safe_name + ".json"
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("[AvatarManager] No se pudo crear archivo: ", path)
		return false
	
	var json = JSON.stringify(avatar.to_dict(), "\t")
	file.store_string(json)
	file.close()
	
	print("[AvatarManager] Perfil guardado: ", path)
	return true

func delete_profile(name: String) -> bool:
	var path = profiles_path + name + ".json"
	
	if not FileAccess.file_exists(path):
		push_warning("[AvatarManager] Perfil no existe: ", path)
		return false
	
	var result = DirAccess.remove_absolute(path)
	if result == OK:
		print("[AvatarManager] Perfil eliminado: ", path)
		return true
	else:
		push_error("[AvatarManager] Error al eliminar perfil: ", result)
		return false

func set_current_avatar(avatar: AvatarData):
	if not avatar:
		push_error("[AvatarManager] Intento de establecer avatar null")
		return
	
	current_avatar = avatar
	print("[AvatarManager] Avatar actual establecido: ", avatar.nombre)

func get_current_avatar() -> AvatarData:
	return current_avatar

func has_current_avatar() -> bool:
	return current_avatar != null

func clear_current_avatar():
	current_avatar = null
	print("[AvatarManager] Avatar actual limpiado")

# Sanitizar nombre de archivo (remover caracteres inválidos)
func _sanitize_filename(filename: String) -> String:
	var safe = filename
	# Remover caracteres no permitidos en nombres de archivo
	var invalid_chars = ['/', '\\', ':', '*', '?', '"', '<', '>', '|']
	for char in invalid_chars:
		safe = safe.replace(char, "_")
	
	# Limitar longitud
	if safe.length() > 50:
		safe = safe.substr(0, 50)
	
	return safe

# Obtener información de un perfil sin cargarlo completamente
func get_profile_info(name: String) -> Dictionary:
	var path = profiles_path + name + ".json"
	
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	
	var text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(text)
	if not data:
		return {}
	
	# Retornar solo info básica
	return {
		"nombre": data.get("nombre", "Sin nombre"),
		"descripcion": data.get("descripcion", ""),
		"raza_id": data.get("raza_id", ""),
		"sexo_id": data.get("sexo_id", "")
	}
