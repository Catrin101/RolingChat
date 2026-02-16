extends Node2D

@onready var map: TileMap = $Map
var local_avatar: RemoteAvatar
var players: Dictionary[int, RemoteAvatar] = {}

func _ready():
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	# Crear avatar local
	_create_local_avatar()
	# Pedir a NetworkManager que nos dé los jugadores ya conectados
	for id in NetworkManager.player_names.keys():
		if id != multiplayer.get_unique_id():
			_spawn_remote_avatar(id, NetworkManager.player_names[id], NetworkManager.player_avatars[id])

func _create_local_avatar():
	var avatar_scene = preload("res://scenes/remote_avatar.tscn")  # Asumimos que existe la escena
	local_avatar = avatar_scene.instantiate()
	local_avatar.name = str(multiplayer.get_unique_id())
	local_avatar.avatar_data = AvatarManager.current_avatar
	local_avatar.set_multiplayer_authority(multiplayer.get_unique_id())
	add_child(local_avatar)
	# Posicionar en un lugar inicial
	local_avatar.position = Vector2(100, 100)

func _on_player_joined(id: int):
	var name = NetworkManager.player_names[id]
	var avatar_dict = NetworkManager.player_avatars[id]
	var avatar_data = AvatarData.from_dict(avatar_dict)
	_spawn_remote_avatar(id, name, avatar_data)

func _spawn_remote_avatar(id: int, name: String, avatar_data: AvatarData):
	var avatar_scene = preload("res://scenes/remote_avatar.tscn")
	var avatar = avatar_scene.instantiate()
	avatar.name = str(id)
	avatar.avatar_data = avatar_data
	avatar.set_multiplayer_authority(id)
	add_child(avatar)
	players[id] = avatar

func _on_player_left(id: int):
	if players.has(id):
		players[id].queue_free()
		players.erase(id)
