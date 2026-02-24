extends CharacterBody2D
## Script para avatares de jugadores (tanto local como remotos)
## Maneja movimiento, sincronización de red y visuales

var avatar_data: AvatarData:
	set(value):
		avatar_data = value
		if is_node_ready():
			update_visual()

@onready var sprite: Sprite2D = $Sprite2D
@onready var nametag: Label = $Nametag
@onready var fallback_rect: ColorRect = $FallbackRect # ✅ NUEVO: respaldo visual siempre visible

var speed: float = 150.0
var image_loader: ImageLoader = ImageLoader.new()

var target_position: Vector2
var last_position: Vector2

# ✅ NUEVO: Colores por índice para distinguir jugadores sin imagen
const PLAYER_COLORS = [
	Color(0.2, 0.4, 0.8, 1.0), # Azul
	Color(0.8, 0.2, 0.2, 1.0), # Rojo
	Color(0.2, 0.7, 0.3, 1.0), # Verde
	Color(0.7, 0.5, 0.0, 1.0), # Naranja
]
const PLAYER_ICONS = ["🧙", "⚔️", "🏹", "🛡️"]

func _ready():
	target_position = position
	last_position = position

	# ✅ CRÍTICO: Asignar color distinto a cada jugador para que sean visibles
	var peer_id = get_multiplayer_authority()
	var color_index = peer_id % PLAYER_COLORS.size()
	fallback_rect.color = PLAYER_COLORS[color_index]
	
	var icon_node = fallback_rect.get_node("AvatarIcon")
	if icon_node:
		icon_node.text = PLAYER_ICONS[color_index]

	# ✅ NUEVO: Hacer al nodo visible y destacado para debug
	modulate = Color(1, 1, 1, 1)

	if avatar_data:
		update_visual()

	print("[RemoteAvatar] Avatar listo | Peer: ", peer_id,
		" | Es local: ", is_multiplayer_authority(),
		" | Posición: ", position)

func update_visual():
	if not avatar_data or not is_node_ready():
		return

	# Actualizar nametag
	nametag.text = avatar_data.nombre

	# ✅ Intentar cargar imagen; si falla, el FallbackRect sigue visible
	if avatar_data.imagen_url != "":
		_load_image(avatar_data.imagen_url)

	print("[RemoteAvatar] Visual actualizado: ", avatar_data.nombre)

func _load_image(url: String):
	if url.begins_with("res://") or url.begins_with("user://"):
		if FileAccess.file_exists(url):
			var img = Image.load_from_file(url)
			if img:
				var texture = ImageTexture.create_from_image(img)
				sprite.texture = texture
				# ✅ Ocultar el rectángulo de respaldo si la imagen cargó bien
				fallback_rect.visible = false
				return

		# No existe la imagen, mostrar el fallback
		print("[RemoteAvatar] Imagen no encontrada, usando fallback: ", url)
		fallback_rect.visible = true
	else:
		# URL HTTP: mientras carga, dejar el fallback visible
		fallback_rect.visible = true
		image_loader.load_http(url, func(texture):
			if texture:
				sprite.texture = texture
				fallback_rect.visible = false
			# Si falla, el fallback permanece visible
		)

func _physics_process(delta):
	if is_multiplayer_authority():
		_handle_local_movement()
	else:
		_interpolate_remote_movement(delta)

func _handle_local_movement():
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed
	move_and_slide()

	if position != last_position:
		_sync_position.rpc(position)
		last_position = position

func _interpolate_remote_movement(delta):
	if position.distance_to(target_position) > 1.0:
		position = position.lerp(target_position, delta * 10.0)

@rpc("unreliable", "any_peer", "call_remote")
func _sync_position(pos: Vector2):
	if not is_multiplayer_authority():
		target_position = pos

func set_avatar_data(data: AvatarData):
	avatar_data = data

func get_avatar_data() -> AvatarData:
	return avatar_data
