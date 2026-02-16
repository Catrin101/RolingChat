extends Node

signal room_created(code: String)
signal connection_successful()
signal connection_failed(reason: String)
signal player_joined(id: int)
signal player_left(id: int)
signal host_disconnected()
signal chat_message_received(sender: String, text: String, type: String)  # type: "ic", "ooc", "action", "roll"

var peer = ENetMultiplayerPeer.new()
var player_names: Dictionary[int, String] = {}  # id -> name
var player_avatars: Dictionary[int, Dictionary] = {}  # id -> avatar_data (as dict)

const PORT = 8080

func create_room(player_name: String, avatar_data: Dictionary) -> String:
	var code = _generate_room_code()
	var error = peer.create_server(PORT, 4)  # max 4 players
	if error != OK:
		connection_failed.emit("No se pudo crear el servidor")
		return ""
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Registrar el host
	var host_id = multiplayer.get_unique_id()
	player_names[host_id] = player_name
	player_avatars[host_id] = avatar_data
	
	room_created.emit(code)
	return code

func join_room(code: String, player_name: String, avatar_data: Dictionary) -> void:
	# Asumimos que el código es la IP o un identificador; en LAN podemos usar localhost
	# Para MVP usamos localhost y el código solo para mostrar
	var ip = "127.0.0.1"  # En un juego real se usaría un servidor de emparejamiento
	var error = peer.create_client(ip, PORT)
	if error != OK:
		connection_failed.emit("No se pudo conectar al host")
		return
	multiplayer.multiplayer_peer = peer
	peer.connection_failed.connect(_on_connection_failed)
	peer.connection_succeeded.connect(_on_connection_succeeded)
	
	# Esperar conexión y luego registrar
	await peer.connection_succeeded
	_register_player.rpc_id(1, player_name, JSON.stringify(avatar_data))

func _generate_room_code() -> String:
	var chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var code = ""
	for i in range(8):
		code += chars[randi() % chars.length()]
	return code

func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	# El host recibe la conexión, pero el registro lo hará el cliente con RPC

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	player_names.erase(id)
	player_avatars.erase(id)
	player_left.emit(id)

func _on_connection_failed():
	connection_failed.emit("No se pudo establecer conexión")

func _on_connection_succeeded():
	connection_successful.emit()

@rpc("any_peer", "call_local")
func _register_player(name: String, avatar_json: String):
	var id = multiplayer.get_remote_sender_id()
	player_names[id] = name
	player_avatars[id] = JSON.parse_string(avatar_json)
	player_joined.emit(id)
	# Reenviar a todos los clientes la información del nuevo jugador
	for other_id in player_names.keys():
		if other_id != id:
			_send_player_info.rpc(other_id, id, name, avatar_json)

@rpc("any_peer", "call_local")
func _send_player_info(for_id: int, new_id: int, name: String, avatar_json: String):
	if multiplayer.get_unique_id() == for_id:
		player_names[new_id] = name
		player_avatars[new_id] = JSON.parse_string(avatar_json)
		player_joined.emit(new_id)

func send_chat_message(text: String):
	var sender_id = multiplayer.get_unique_id()
	var sender_name = player_names[sender_id]
	# Parsear y formatear en cliente, pero enviar texto original para que todos formateen igual
	rpc("_receive_chat_message", sender_id, text)

@rpc("any_peer", "call_local")
func _receive_chat_message(sender_id: int, text: String):
	var sender_name = player_names[sender_id]
	# Emitir señal para que el ChatController procese y muestre
	chat_message_received.emit(sender_name, text, "")  # El tipo lo determina el parser
