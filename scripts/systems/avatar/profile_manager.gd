# scripts/systems/avatar/profile_manager.gd
extends Node

## ProfileManager - Gestión de perfiles de avatar
## Responsabilidad: Guardar/cargar avatares en JSON
## Singleton pattern (agregar como autoload)

# ===== CONSTANTES =====

const PROFILES_DIR := "user://profiles/"
const PROFILE_EXTENSION := ".json"
const DEFAULT_PROFILE := "default_avatar"

# ===== ESTADO =====

var available_profiles: Array[String] = []

# ===== CICLO DE VIDA =====

func _ready() -> void:
	_ensure_profiles_directory_exists()
	_scan_profiles()
	print("[ProfileManager] Sistema de perfiles inicializado")
	print("[ProfileManager] Perfiles encontrados: %d" % available_profiles.size())

# ===== API PÚBLICA - GUARDADO =====

## Guarda un avatar con el nombre especificado
func save_profile(avatar_data: AvatarData, profile_name: String) -> bool:
	if profile_name.is_empty():
		push_error("[ProfileManager] Nombre de perfil vacío")
		return false
	
	# Sanitizar nombre (remover caracteres inválidos)
	var safe_name = _sanitize_filename(profile_name)
	
	# Actualizar timestamp
	avatar_data.update_modified_timestamp()
	
	# Serializar a diccionario
	var data = avatar_data.to_dict()
	
	# Convertir a JSON
	var json_string = JSON.stringify(data, "\t")
	
	# Guardar archivo
	var file_path = PROFILES_DIR + safe_name + PROFILE_EXTENSION
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file == null:
		push_error("[ProfileManager] No se pudo crear archivo: %s" % file_path)
		return false
	
	file.store_string(json_string)
	file.close()
	
	# Actualizar lista de perfiles
	if not available_profiles.has(safe_name):
		available_profiles.append(safe_name)
	
	print("[ProfileManager] ✓ Perfil guardado: %s" % safe_name)
	return true

## Guarda el perfil actual en GameManager
func save_current_profile(profile_name: String) -> bool:
	var avatar_data = GameManager.get_current_avatar()
	
	if avatar_data == null:
		push_error("[ProfileManager] No hay avatar actual para guardar")
		return false
	
	return save_profile(avatar_data, profile_name)

# ===== API PÚBLICA - CARGA =====

## Carga un perfil por nombre
func load_profile(profile_name: String) -> AvatarData:
	var safe_name = _sanitize_filename(profile_name)
	var file_path = PROFILES_DIR + safe_name + PROFILE_EXTENSION
	
	if not FileAccess.file_exists(file_path):
		push_error("[ProfileManager] Perfil no encontrado: %s" % safe_name)
		return null
	
	# Leer archivo
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[ProfileManager] No se pudo abrir archivo: %s" % file_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	# Parsear JSON
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("[ProfileManager] Error parseando JSON: %s" % json.get_error_message())
		return null
	
	# Crear AvatarData y cargar datos
	var avatar_data = AvatarData.new()
	avatar_data.from_dict(json.data)
	
	print("[ProfileManager] ✓ Perfil cargado: %s" % safe_name)
	return avatar_data

## Carga un perfil y lo establece como actual en GameManager
func load_profile_as_current(profile_name: String) -> bool:
	var avatar_data = load_profile(profile_name)
	
	if avatar_data == null:
		return false
	
	GameManager.set_current_avatar(avatar_data)
	return true

# ===== API PÚBLICA - GESTIÓN =====

## Elimina un perfil
func delete_profile(profile_name: String) -> bool:
	var safe_name = _sanitize_filename(profile_name)
	var file_path = PROFILES_DIR + safe_name + PROFILE_EXTENSION
	
	if not FileAccess.file_exists(file_path):
		push_warning("[ProfileManager] Perfil no existe: %s" % safe_name)
		return false
	
	var dir = DirAccess.open(PROFILES_DIR)
	if dir == null:
		push_error("[ProfileManager] No se pudo acceder a directorio de perfiles")
		return false
	
	var error = dir.remove(safe_name + PROFILE_EXTENSION)
	
	if error != OK:
		push_error("[ProfileManager] Error eliminando perfil: %s" % safe_name)
		return false
	
	# Actualizar lista
	available_profiles.erase(safe_name)
	
	print("[ProfileManager] ✓ Perfil eliminado: %s" % safe_name)
	return true

## Renombra un perfil
func rename_profile(old_name: String, new_name: String) -> bool:
	var avatar_data = load_profile(old_name)
	
	if avatar_data == null:
		return false
	
	# Actualizar nombre del personaje
	avatar_data.character_name = new_name
	
	# Guardar con nuevo nombre
	if not save_profile(avatar_data, new_name):
		return false
	
	# Eliminar el viejo
	delete_profile(old_name)
	
	print("[ProfileManager] ✓ Perfil renombrado: %s → %s" % [old_name, new_name])
	return true

## Duplica un perfil
func duplicate_profile(profile_name: String, new_name: String) -> bool:
	var avatar_data = load_profile(profile_name)
	
	if avatar_data == null:
		return false
	
	# Crear copia
	var copy = avatar_data.duplicate_avatar()
	copy.character_name = new_name
	copy.created_at = Time.get_datetime_string_from_system()
	
	return save_profile(copy, new_name)

## Obtiene lista de perfiles disponibles
func get_available_profiles() -> Array[String]:
	return available_profiles.duplicate()

## Verifica si existe un perfil
func profile_exists(profile_name: String) -> bool:
	var safe_name = _sanitize_filename(profile_name)
	return available_profiles.has(safe_name)

## Reescanea el directorio de perfiles
func refresh_profiles() -> void:
	_scan_profiles()

# ===== MÉTODOS PRIVADOS =====

func _ensure_profiles_directory_exists() -> void:
	if not DirAccess.dir_exists_absolute(PROFILES_DIR):
		DirAccess.make_dir_recursive_absolute(PROFILES_DIR)
		print("[ProfileManager] Directorio de perfiles creado: %s" % PROFILES_DIR)

func _scan_profiles() -> void:
	available_profiles.clear()
	
	var dir = DirAccess.open(PROFILES_DIR)
	if dir == null:
		push_error("[ProfileManager] No se pudo abrir directorio: %s" % PROFILES_DIR)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(PROFILE_EXTENSION):
			var profile_name = file_name.trim_suffix(PROFILE_EXTENSION)
			available_profiles.append(profile_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	print("[ProfileManager] Perfiles escaneados: %s" % str(available_profiles))

func _sanitize_filename(name: String) -> String:
	# Remover caracteres inválidos para nombres de archivo
	var safe = name.strip_edges()
	safe = safe.replace("/", "_")
	safe = safe.replace("\\", "_")
	safe = safe.replace(":", "_")
	safe = safe.replace("*", "_")
	safe = safe.replace("?", "_")
	safe = safe.replace("\"", "_")
	safe = safe.replace("<", "_")
	safe = safe.replace(">", "_")
	safe = safe.replace("|", "_")
	
	# Limitar longitud
	if safe.length() > 50:
		safe = safe.substr(0, 50)
	
	return safe

# ===== UTILIDADES =====

## Crea un perfil por defecto
func create_default_profile() -> AvatarData:
	var avatar_data = AvatarData.new()
	avatar_data.initialize_defaults()
	avatar_data.character_name = "Aventurero"
	
	return avatar_data

## Exporta un perfil a un diccionario (para debugging)
func export_profile_dict(profile_name: String) -> Dictionary:
	var avatar_data = load_profile(profile_name)
	
	if avatar_data == null:
		return {}
	
	return avatar_data.to_dict()

## Importa un perfil desde un diccionario
func import_profile_dict(data: Dictionary, profile_name: String) -> bool:
	var avatar_data = AvatarData.new()
	avatar_data.from_dict(data)
	
	return save_profile(avatar_data, profile_name)
