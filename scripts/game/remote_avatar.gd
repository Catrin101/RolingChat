extends CharacterBody2D
## Script para avatares de jugadores (tanto local como remotos)
## Maneja movimiento, sincronización de red y visuales

# ✅ CORRECCIÓN: No usar @export para clases personalizadas
# En su lugar, usamos una variable normal y un setter
var avatar_data: AvatarData:
	set(value):
		avatar_data = value
		if is_node_ready():
			update_visual()

@onready var sprite: Sprite2D = $Sprite2D
@onready var nametag: Label = $Nametag

var speed: float = 150.0
var image_loader: ImageLoader = ImageLoader.new()

# Variables para interpolación de movimiento
var target_position: Vector2
var last_position: Vector2

func _ready():
	# Inicializar posiciones
	target_position = position
	last_position = position
	
	# Actualizar visuales si ya hay datos
	if avatar_data:
		update_visual()
	
	print("[RemoteAvatar] Avatar listo: ", name, " | Authority: ", get_multiplayer_authority())

func update_visual():
	if not avatar_data:
		return
	
	if not is_node_ready():
		return
	
	# Actualizar nametag
	nametag.text = avatar_data.nombre
	
	# Cargar imagen del avatar
	_load_image(avatar_data.imagen_url)
	
	print("[RemoteAvatar] Visuales actualizados para: ", avatar_data.nombre)

func _load_image(url: String):
	if url.begins_with("res://") or url.begins_with("user://"):
		# Cargar archivo local
		if FileAccess.file_exists(url):
			var img = Image.load_from_file(url)
			if img:
				var texture = ImageTexture.create_from_image(img)
				sprite.texture = texture
				return
		
		# Si no existe, usar placeholder
		_load_placeholder()
	else:
		# Cargar desde URL HTTP
		image_loader.load_http(url, func(texture): 
			if texture:
				sprite.texture = texture
			else:
				_load_placeholder()
		)

func _load_placeholder():
	# Usar el icono del proyecto como placeholder
	if FileAccess.file_exists("res://icon.svg"):
		var img = Image.load_from_file("res://icon.svg")
		if img:
			sprite.texture = ImageTexture.create_from_image(img)

func _physics_process(delta):
	if is_multiplayer_authority():
		# Este es el jugador local - procesar input
		_handle_local_movement()
	else:
		# Este es un jugador remoto - interpolar hacia la posición objetivo
		_interpolate_remote_movement(delta)

func _handle_local_movement():
	# Obtener dirección de input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * speed
	
	# Mover
	move_and_slide()
	
	# ✅ CORRECCIÓN: Usar rpc() en lugar de rpc_unreliable()
	# Godot 4.x usa rpc() con configuraciones en el decorador
	if position != last_position:
		_sync_position.rpc(position)
		last_position = position

func _interpolate_remote_movement(delta):
	# Interpolar suavemente hacia la posición objetivo
	if position.distance_to(target_position) > 1.0:
		position = position.lerp(target_position, delta * 10.0)

# ✅ CORRECCIÓN: Sintaxis correcta para RPC en Godot 4.x
@rpc("unreliable", "any_peer", "call_remote")
func _sync_position(pos: Vector2):
	# Solo actualizar si no somos la autoridad
	if not is_multiplayer_authority():
		target_position = pos

# Método público para establecer datos del avatar
func set_avatar_data(data: AvatarData):
	avatar_data = data

# Método público para obtener datos del avatar
func get_avatar_data() -> AvatarData:
	return avatar_data
