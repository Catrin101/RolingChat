extends CharacterBody2D

@export var avatar_data: AvatarData : set = _set_avatar_data
@onready var sprite: Sprite2D = $Sprite2D
@onready var nametag: Label = $Nametag

var speed = 150.0
var image_loader = ImageLoader.new()  # Lo definiremos más abajo

func _ready():
	if avatar_data:
		update_visual()

func _set_avatar_data(value: AvatarData):
	avatar_data = value
	update_visual()

func update_visual():
	if not avatar_data:
		return
	nametag.text = avatar_data.nombre
	_load_image(avatar_data.imagen_url)

func _load_image(url: String):
	if url.begins_with("res://") or url.begins_with("user://"):
		# Archivo local
		var img = Image.load_from_file(url)
		if img:
			var texture = ImageTexture.create_from_image(img)
			sprite.texture = texture
	else:
		# URL http
		image_loader.load_http(url, func(texture): sprite.texture = texture)

func _physics_process(delta):
	if is_multiplayer_authority():
		var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		velocity = input_dir * speed
		move_and_slide()
		# Sincronizar posición (usar MultiplayerSynchronizer o RPC)
		rpc_unreliable("sync_position", position)
	else:
		# Interpolar posición recibida
		pass

@rpc("unreliable", "any_peer")
func sync_position(pos: Vector2):
	position = pos
