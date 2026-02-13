# scripts/systems/avatar/avatar_builder.gd
class_name AvatarBuilder
extends Node2D

## AvatarBuilder - Sistema Paper Doll para avatares modulares
## Responsabilidad: Construir sprite compuesto desde AvatarData
## Patrón: Builder Pattern

# ===== CONFIGURACIÓN =====

## Tipo de vista: "isometric" o "sideview"
@export var view_type: String = "isometric"

## Escala del sprite (para ajustar tamaño)
@export var sprite_scale: float = 1.0

# ===== COMPONENTES =====

## Datos del avatar
var avatar_data: AvatarData = null

## Contenedor de sprites (Paper Doll layers)
var layers: Dictionary = {}

# ===== ORDEN DE CAPAS (Z-Index) =====

const LAYER_ORDER_ISO := {
	"body": 0,
	"outfit": 1,
	"hair": 2
}

const LAYER_ORDER_SIDE := {
	"legs": 0,
	"shoes": 1,
	"torso": 2,
	"outfit_bottom": 3,
	"outfit_top": 4,
	"head": 5,
	"hair": 6
}

# ===== CICLO DE VIDA =====

func _ready() -> void:
	scale = Vector2(sprite_scale, sprite_scale)
	print("[AvatarBuilder] Builder inicializado (vista: %s)" % view_type)

# ===== API PÚBLICA =====

## Construye el avatar desde AvatarData
func build_from_data(data: AvatarData) -> void:
	avatar_data = data
	_clear_layers()
	
	if view_type == "isometric":
		_build_isometric()
	elif view_type == "sideview":
		_build_sideview()
	else:
		push_error("[AvatarBuilder] Tipo de vista inválido: %s" % view_type)
	
	print("[AvatarBuilder] Avatar construido: %s" % data.character_name)

## Reconstruye el avatar (llamar después de cambiar avatar_data)
func rebuild() -> void:
	if avatar_data:
		build_from_data(avatar_data)

## Cambia el tipo de vista y reconstruye
func set_view_type(new_type: String) -> void:
	if new_type != view_type:
		view_type = new_type
		rebuild()

# ===== CONSTRUCCIÓN ISOMÉTRICA =====

func _build_isometric() -> void:
	# Cuerpo base
	_add_layer("body", "isometric", "body", avatar_data.iso_body_id)
	
	# Outfit
	_add_layer("outfit", "isometric", "outfit", avatar_data.iso_outfit_id)
	
	# Cabello
	var hair_sprite = _add_layer("hair", "isometric", "hair", avatar_data.iso_hair_id)
	if hair_sprite:
		hair_sprite.modulate = avatar_data.iso_hair_color
	
	# Aplicar tintado de piel al cuerpo
	if layers.has("body"):
		layers["body"].modulate = avatar_data.iso_skin_color

# ===== CONSTRUCCIÓN SIDEVIEW =====

func _build_sideview() -> void:
	# Piernas
	_add_layer("legs", "sideview", "legs", avatar_data.side_legs_id)
	
	# Zapatos
	_add_layer("shoes", "sideview", "shoes", avatar_data.side_shoes_id)
	
	# Torso
	_add_layer("torso", "sideview", "torso", avatar_data.side_torso_id)
	
	# Outfit inferior
	_add_layer("outfit_bottom", "sideview", "outfit_bottom", avatar_data.side_outfit_bottom_id)
	
	# Outfit superior
	_add_layer("outfit_top", "sideview", "outfit_top", avatar_data.side_outfit_top_id)
	
	# Cabeza
	_add_layer("head", "sideview", "head", avatar_data.side_head_id)
	
	# Cabello
	var hair_sprite = _add_layer("hair", "sideview", "hair", avatar_data.side_hair_id)
	if hair_sprite:
		hair_sprite.modulate = avatar_data.side_hair_color
	
	# Aplicar tintado de piel
	if layers.has("head"):
		layers["head"].modulate = avatar_data.side_skin_color
	if layers.has("torso"):
		layers["torso"].modulate = avatar_data.side_skin_color

# ===== GESTIÓN DE CAPAS =====

func _add_layer(layer_name: String, registry_type: String, category: String, part_id: int) -> Sprite2D:
	# Obtener metadatos de la parte desde AssetRegistry
	var part_data = AssetRegistry.get_part(registry_type, category, part_id)
	
	if part_data.is_empty():
		print("[AvatarBuilder] Parte no encontrada: %s/%s/ID=%d" % [registry_type, category, part_id])
		return null
	
	# Crear sprite
	var sprite = Sprite2D.new()
	sprite.name = layer_name
	
	# Cargar textura
	var texture_path = part_data.get("path", "")
	if not texture_path.is_empty():
		var texture = AssetRegistry.get_texture(texture_path)
		if texture:
			sprite.texture = texture
		else:
			# Fallback: crear textura placeholder
			sprite.texture = _create_placeholder_texture(layer_name)
	else:
		sprite.texture = _create_placeholder_texture(layer_name)
	
	# Configurar z-index según tipo de vista
	var order = LAYER_ORDER_ISO if registry_type == "isometric" else LAYER_ORDER_SIDE
	sprite.z_index = order.get(layer_name, 0)
	
	# Agregar al árbol
	add_child(sprite)
	layers[layer_name] = sprite
	
	return sprite

func _clear_layers() -> void:
	for layer in layers.values():
		if is_instance_valid(layer):
			layer.queue_free()
	
	layers.clear()

func _create_placeholder_texture(layer_name: String) -> ImageTexture:
	# Crea una textura placeholder de color sólido
	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Colores según capa
	var color = Color.WHITE
	match layer_name:
		"body", "head", "torso":
			color = Color(0.9, 0.7, 0.6)  # Tono piel
		"hair":
			color = Color(0.3, 0.2, 0.1)  # Castaño
		"outfit", "outfit_top", "outfit_bottom":
			color = Color(0.2, 0.4, 0.8)  # Azul
		"legs":
			color = Color(0.4, 0.3, 0.2)  # Café
		"shoes":
			color = Color(0.1, 0.1, 0.1)  # Negro
	
	img.fill(color)
	return ImageTexture.create_from_image(img)

# ===== UTILIDADES =====

## Obtiene el sprite de una capa específica
func get_layer_sprite(layer_name: String) -> Sprite2D:
	return layers.get(layer_name, null)

## Cambia la textura de una capa específica
func set_layer_texture(layer_name: String, texture: Texture2D) -> void:
	if layers.has(layer_name):
		layers[layer_name].texture = texture

## Cambia el color de una capa específica
func set_layer_color(layer_name: String, color: Color) -> void:
	if layers.has(layer_name):
		layers[layer_name].modulate = color

## Oculta/muestra una capa
func set_layer_visible(layer_name: String, visible: bool) -> void:
	if layers.has(layer_name):
		layers[layer_name].visible = visible

## Obtiene todas las capas actuales
func get_all_layers() -> Array:
	return layers.keys()

## Exporta el avatar como imagen (screenshot del sprite compuesto)
func export_as_image() -> Image:
	# Renderizar el nodo a una imagen
	var viewport = get_viewport()
	var img = viewport.get_texture().get_image()
	
	# Recortar al área del sprite
	# TODO: Implementar recorte inteligente
	
	return img
