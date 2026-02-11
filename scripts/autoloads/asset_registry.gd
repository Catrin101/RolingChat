# scripts/autoloads/asset_registry.gd
extends Node

## AssetRegistry - Sistema de registro centralizado de assets
## Responsabilidad: Cargar y gestionar metadatos de sprites, escenas y configuraciones
## Patrón: Registry Pattern

# ===== REGISTRIES =====

## Registro de partes de avatar isométrico
var isometric_registry: Dictionary = {}

## Registro de partes de avatar lateral (sideview)
var sideview_registry: Dictionary = {}

## Registro de templates de escenas conjuntas
var scene_templates_registry: Dictionary = {}

## Registro de configuraciones de mapas
var maps_registry: Dictionary = {}

# ===== CACHE =====

var _texture_cache: Dictionary = {}

# ===== CICLO DE VIDA =====

func _ready() -> void:
	print("[AssetRegistry] Inicializando sistema de assets...")
	_load_all_registries()
	print("[AssetRegistry] Sistema inicializado")

func _load_all_registries() -> void:
	# Cargar registros de avatares
	_load_registry("res://data/avatar_registries/isometric_parts.json", isometric_registry)
	_load_registry("res://data/avatar_registries/sideview_parts.json", sideview_registry)
	
	# Cargar templates de escenas
	_load_scene_templates()
	
	# Cargar configuraciones de mapas
	_load_map_configs()
	
	print("[AssetRegistry] Registros cargados:")
	print("  - Isométrico: %d categorías" % isometric_registry.size())
	print("  - Sideview: %d categorías" % sideview_registry.size())
	print("  - Escenas: %d templates" % scene_templates_registry.size())
	print("  - Mapas: %d configuraciones" % maps_registry.size())

# ===== CARGA DE REGISTROS =====

func _load_registry(file_path: String, target_dict: Dictionary) -> void:
	if not FileAccess.file_exists(file_path):
		push_warning("[AssetRegistry] Archivo no encontrado: %s (será creado cuando agregues assets)" % file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[AssetRegistry] No se pudo abrir: %s" % file_path)
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("[AssetRegistry] Error parseando JSON en %s: %s" % [file_path, json.get_error_message()])
		return
	
	var data = json.data
	if data.has("parts"):
		target_dict.merge(data["parts"], true)
	
	print("[AssetRegistry] ✓ Cargado: %s" % file_path)

func _load_scene_templates() -> void:
	var templates_dir = "res://data/scene_templates/"
	
	if not DirAccess.dir_exists_absolute(templates_dir):
		print("[AssetRegistry] Directorio de templates no existe: %s" % templates_dir)
		return
	
	var dir = DirAccess.open(templates_dir)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path = templates_dir + file_name
			var template_data = _load_json(full_path)
			
			if not template_data.is_empty() and template_data.has("scene_id"):
				scene_templates_registry[template_data["scene_id"]] = template_data
				print("[AssetRegistry] ✓ Template cargado: %s" % template_data["scene_id"])
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _load_map_configs() -> void:
	var maps_dir = "res://data/maps/"
	
	if not DirAccess.dir_exists_absolute(maps_dir):
		print("[AssetRegistry] Directorio de mapas no existe: %s" % maps_dir)
		return
	
	var dir = DirAccess.open(maps_dir)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".json"):
			var full_path = maps_dir + file_name
			var map_data = _load_json(full_path)
			
			if not map_data.is_empty() and map_data.has("map_id"):
				maps_registry[map_data["map_id"]] = map_data
				print("[AssetRegistry] ✓ Mapa cargado: %s" % map_data["map_id"])
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("[AssetRegistry] Error en JSON %s: %s" % [path, json.get_error_message()])
		return {}
	
	return json.data

# ===== API PÚBLICA =====

## Obtiene metadatos de una parte específica de avatar
## registry_type: "isometric" o "sideview"
## category: "body", "hair", "outfit", etc.
## part_id: ID numérico de la parte
func get_part(registry_type: String, category: String, part_id: int) -> Dictionary:
	var registry = isometric_registry if registry_type == "isometric" else sideview_registry
	
	if not registry.has(category):
		push_warning("[AssetRegistry] Categoría no encontrada: %s" % category)
		return {}
	
	var parts_list = registry[category]
	for part in parts_list:
		if part["id"] == part_id:
			return part
	
	push_warning("[AssetRegistry] Parte no encontrada: %s/%s/ID=%d" % [registry_type, category, part_id])
	return {}

## Obtiene template de escena conjunta
func get_scene_template(scene_id: String) -> Dictionary:
	if not scene_templates_registry.has(scene_id):
		push_warning("[AssetRegistry] Template no encontrado: %s" % scene_id)
		return {}
	
	return scene_templates_registry[scene_id]

## Obtiene configuración de mapa
func get_map_config(map_id: String) -> Dictionary:
	if not maps_registry.has(map_id):
		push_warning("[AssetRegistry] Mapa no encontrado: %s" % map_id)
		return {}
	
	return maps_registry[map_id]

## Obtiene lista de todas las partes disponibles en una categoría
func get_available_parts(registry_type: String, category: String) -> Array:
	var registry = isometric_registry if registry_type == "isometric" else sideview_registry
	
	if not registry.has(category):
		return []
	
	return registry[category]

## Carga una textura con cache
func get_texture(path: String) -> Texture2D:
	if path.is_empty() or path == "null":
		return null
	
	# Verificar caché
	if _texture_cache.has(path):
		return _texture_cache[path]
	
	# Cargar textura
	if not ResourceLoader.exists(path):
		push_error("[AssetRegistry] Textura no existe: %s" % path)
		return null
	
	var texture = load(path)
	if texture:
		_texture_cache[path] = texture
	else:
		push_error("[AssetRegistry] Error cargando textura: %s" % path)
	
	return texture

## Limpia el caché de texturas
func clear_texture_cache() -> void:
	_texture_cache.clear()
	print("[AssetRegistry] Caché de texturas limpiado")

## Recarga todos los registros
func reload_registries() -> void:
	isometric_registry.clear()
	sideview_registry.clear()
	scene_templates_registry.clear()
	maps_registry.clear()
	_load_all_registries()
	print("[AssetRegistry] Registros recargados")
