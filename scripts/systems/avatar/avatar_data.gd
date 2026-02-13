# scripts/systems/avatar/avatar_data.gd
class_name AvatarData
extends Resource

## AvatarData - Resource para almacenar configuración de avatar
## Responsabilidad: Datos persistentes del avatar (partes, nombre, colores)
## Se serializa a JSON para networking y guardado

# ===== INFORMACIÓN BÁSICA =====

## Nombre del personaje
@export var character_name: String = "Aventurero"

## Historia del personaje (opcional)
@export_multiline var backstory: String = ""

# ===== CONFIGURACIÓN DE AVATAR ISOMÉTRICO =====

@export_group("Isométrico")

## ID del cuerpo base
@export var iso_body_id: int = 0

## ID del cabello
@export var iso_hair_id: int = 0

## ID del outfit/ropa
@export var iso_outfit_id: int = 0

## Color del cabello (opcional)
@export var iso_hair_color: Color = Color.WHITE

## Color de la piel (opcional)
@export var iso_skin_color: Color = Color.WHITE

# ===== CONFIGURACIÓN DE AVATAR LATERAL (SIDEVIEW) =====

@export_group("Sideview")

## ID de la cabeza
@export var side_head_id: int = 0

## ID del torso
@export var side_torso_id: int = 0

## ID de las piernas
@export var side_legs_id: int = 0

## ID del cabello
@export var side_hair_id: int = 0

## ID del outfit superior
@export var side_outfit_top_id: int = 0

## ID del outfit inferior
@export var side_outfit_bottom_id: int = 0

## ID de los zapatos
@export var side_shoes_id: int = 0

## Color del cabello
@export var side_hair_color: Color = Color.WHITE

## Color de la piel
@export var side_skin_color: Color = Color.WHITE

# ===== METADATOS =====

@export_group("Metadatos")

## Timestamp de creación
@export var created_at: String = ""

## Timestamp de última modificación
@export var modified_at: String = ""

## Versión del sistema de avatares
@export var version: String = "1.0"

# ===== MÉTODOS PÚBLICOS =====

## Inicializa el avatar con valores por defecto
func initialize_defaults() -> void:
	character_name = "Aventurero"
	backstory = ""
	
	# Isométrico: valores por defecto
	iso_body_id = 0
	iso_hair_id = 0
	iso_outfit_id = 0
	iso_hair_color = Color.WHITE
	iso_skin_color = Color.WHITE
	
	# Sideview: valores por defecto
	side_head_id = 0
	side_torso_id = 0
	side_legs_id = 0
	side_hair_id = 0
	side_outfit_top_id = 0
	side_outfit_bottom_id = 0
	side_shoes_id = 0
	side_hair_color = Color.WHITE
	side_skin_color = Color.WHITE
	
	# Metadatos
	created_at = Time.get_datetime_string_from_system()
	modified_at = created_at
	version = "1.0"

## Actualiza timestamp de modificación
func update_modified_timestamp() -> void:
	modified_at = Time.get_datetime_string_from_system()

## Serializa a diccionario (para networking y JSON)
func to_dict() -> Dictionary:
	return {
		"character_name": character_name,
		"backstory": backstory,
		"iso": {
			"body_id": iso_body_id,
			"hair_id": iso_hair_id,
			"outfit_id": iso_outfit_id,
			"hair_color": iso_hair_color.to_html(),
			"skin_color": iso_skin_color.to_html()
		},
		"side": {
			"head_id": side_head_id,
			"torso_id": side_torso_id,
			"legs_id": side_legs_id,
			"hair_id": side_hair_id,
			"outfit_top_id": side_outfit_top_id,
			"outfit_bottom_id": side_outfit_bottom_id,
			"shoes_id": side_shoes_id,
			"hair_color": side_hair_color.to_html(),
			"skin_color": side_skin_color.to_html()
		},
		"metadata": {
			"created_at": created_at,
			"modified_at": modified_at,
			"version": version
		}
	}

## Carga desde diccionario
func from_dict(data: Dictionary) -> void:
	character_name = data.get("character_name", "Aventurero")
	backstory = data.get("backstory", "")
	
	# Isométrico
	if data.has("iso"):
		var iso = data["iso"]
		iso_body_id = iso.get("body_id", 0)
		iso_hair_id = iso.get("hair_id", 0)
		iso_outfit_id = iso.get("outfit_id", 0)
		iso_hair_color = Color.from_string(iso.get("hair_color", "#ffffff"), Color.WHITE)
		iso_skin_color = Color.from_string(iso.get("skin_color", "#ffffff"), Color.WHITE)
	
	# Sideview
	if data.has("side"):
		var side = data["side"]
		side_head_id = side.get("head_id", 0)
		side_torso_id = side.get("torso_id", 0)
		side_legs_id = side.get("legs_id", 0)
		side_hair_id = side.get("hair_id", 0)
		side_outfit_top_id = side.get("outfit_top_id", 0)
		side_outfit_bottom_id = side.get("outfit_bottom_id", 0)
		side_shoes_id = side.get("shoes_id", 0)
		side_hair_color = Color.from_string(side.get("hair_color", "#ffffff"), Color.WHITE)
		side_skin_color = Color.from_string(side.get("skin_color", "#ffffff"), Color.WHITE)
	
	# Metadatos
	if data.has("metadata"):
		var meta = data["metadata"]
		created_at = meta.get("created_at", "")
		modified_at = meta.get("modified_at", "")
		version = meta.get("version", "1.0")

## Randomiza el avatar (útil para el botón "Aleatorio")
func randomize_avatar() -> void:
	# Por ahora, asigna IDs aleatorios básicos
	# Cuando tengamos assets reales, esto usará AssetRegistry para obtener rangos válidos
	
	iso_body_id = randi() % 3  # 0-2
	iso_hair_id = randi() % 3
	iso_outfit_id = randi() % 3
	
	side_head_id = randi() % 3
	side_torso_id = randi() % 3
	side_legs_id = randi() % 3
	side_hair_id = randi() % 3
	side_outfit_top_id = randi() % 3
	side_outfit_bottom_id = randi() % 3
	side_shoes_id = randi() % 3
	
	# Colores aleatorios de cabello
	var hair_colors = [
		Color.from_string("#2C1810", Color.WHITE),  # Negro
		Color.from_string("#8B4513", Color.WHITE),  # Castaño
		Color.from_string("#FFD700", Color.WHITE),  # Rubio
		Color.from_string("#DC143C", Color.WHITE),  # Rojo
		Color.from_string("#C0C0C0", Color.WHITE),  # Plata
	]
	
	var random_hair = hair_colors[randi() % hair_colors.size()]
	iso_hair_color = random_hair
	side_hair_color = random_hair
	
	update_modified_timestamp()

## Clona el avatar
func duplicate_avatar() -> AvatarData:
	var new_avatar = AvatarData.new()
	new_avatar.from_dict(to_dict())
	return new_avatar

## Valida que el avatar tenga datos coherentes
func is_valid() -> bool:
	if character_name.is_empty():
		return false
	
	# Validaciones adicionales podrían ir aquí
	return true

## Obtiene un resumen del avatar para mostrar en UI
func get_summary() -> String:
	return "Nombre: %s | Iso: %d-%d-%d | Side: %d-%d-%d" % [
		character_name,
		iso_body_id, iso_hair_id, iso_outfit_id,
		side_head_id, side_torso_id, side_hair_id
	]
