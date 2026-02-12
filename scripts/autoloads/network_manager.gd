# scripts/autoloads/network_manager.gd
extends Node

## NetworkManager - Gestión centralizada de networking
## Arquitectura: Host-Client (ENet)
## Responsabilidad: Crear/unir salas, sincronizar jugadores, gestionar RPCs

# ===== CONSTANTES =====

const DEFAULT_PORT := 7777
const MAX_PLAYERS := 8
const PROTOCOL_VERSION := "1.0"

# ===== ESTADO =====

## Peer de red (ENet)
var peer: ENetMultiplayerPeer = null

## Código de la sala actual
var room_code: String = ""

## Diccionario de jugadores conectados {peer_id: PlayerNetData}
var players: Dictionary = {}

## Indica si somos el host
var is_host: bool = false

## Datos del avatar local (para enviar al host)
var local_avatar_data: Dictionary = {}

## Monitor de conexiones (solo host)
var connection_monitor: ConnectionMonitor = null

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Conectar señales de multiplayer de Godot
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Inicializar monitor de conexiones
	connection_monitor = ConnectionMonitor.new()
	add_child(connection_monitor)
	
	print("[NetworkManager] Sistema de networking inicializado")

# ===== API PÚBLICA =====

## Crea una nueva sala como host
## Retorna el código de la sala (IP:Puerto)
func create_room(p_room_name: String = "Sala de Rol") -> String:
	if peer != null:
		push_error("[NetworkManager] Ya estás en una sala")
		EventBus.emit_error("Ya estás conectado a una sala")
		return ""
	
	# Crear peer ENet como servidor
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	
	if error != OK:
		push_error("[NetworkManager] Error creando servidor: %s" % error)
		EventBus.emit_error("No se pudo crear la sala. Código de error: %d" % error)
		peer = null
		return ""
	
	# Asignar peer al multiplayer
	multiplayer.multiplayer_peer = peer
	is_host = true
	
	# Generar código de sala
	room_code = _generate_room_code()
	
	# Agregar el host a la lista de jugadores
	var host_peer_id = multiplayer.get_unique_id()
	players[host_peer_id] = {
		"peer_id": host_peer_id,
		"character_name": "Host",
		"avatar_data": {},
		"position": Vector2.ZERO,
		"state": "idle"
	}
	
	# Actualizar GameManager
	GameManager.set_is_host(true)
	GameManager.set_room_code(room_code)
	GameManager.set_room_name(p_room_name)
	GameManager.local_peer_id = host_peer_id
	
	# Iniciar monitoreo de conexiones
	connection_monitor.start_monitoring()
	
	print("[NetworkManager] ✓ Sala creada. Código: %s" % room_code)
	EventBus.room_created.emit(room_code)
	EventBus.emit_system_message("Sala '%s' creada exitosamente" % p_room_name)
	
	return room_code

## Se une a una sala existente usando código
## code: Puede ser "IP:Puerto" o solo "IP" (usa puerto por defecto)
func join_room(code: String, avatar_data: Dictionary = {}) -> bool:
	if peer != null:
		push_error("[NetworkManager] Ya estás en una sala")
		EventBus.emit_error("Ya estás conectado a una sala")
		return false
	
	# Parsear código (formato: IP o IP:Puerto)
	var host_ip := code
	var port := DEFAULT_PORT
	
	if ":" in code:
		var parts = code.split(":")
		host_ip = parts[0]
		port = int(parts[1])
	
	# Validar IP básica
	if not _is_valid_ip(host_ip):
		push_error("[NetworkManager] IP inválida: %s" % host_ip)
		EventBus.emit_error("Código de sala inválido")
		return false
	
	# Crear peer como cliente
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(host_ip, port)
	
	if error != OK:
		push_error("[NetworkManager] Error conectando: %s" % error)
		EventBus.emit_error("No se pudo conectar a la sala")
		peer = null
		return false
	
	multiplayer.multiplayer_peer = peer
	is_host = false
	local_avatar_data = avatar_data
	room_code = code
	
	GameManager.set_is_host(false)
	GameManager.set_room_code(code)
	
	print("[NetworkManager] Conectando a %s:%d..." % [host_ip, port])
	EventBus.emit_system_message("Conectando a la sala...")
	
	return true

## Desconecta de la sala actual
func disconnect_from_room() -> void:
	if peer == null:
		return
	
	print("[NetworkManager] Desconectando de la sala...")
	
	# Detener monitor de conexiones
	if is_host and connection_monitor:
		connection_monitor.stop_monitoring()
	
	if is_host:
		# Host notifica que cierra la sala
		print("[NetworkManager] Host cerrando sala, notificando a %d cliente(s)" % (players.size() - 1))
		rpc("_notify_room_closed")
		await get_tree().create_timer(0.5).timeout
	
	# Limpiar conexión
	multiplayer.multiplayer_peer = null
	peer = null
	is_host = false
	room_code = ""
	
	# Guardar conteo para log
	var player_count = players.size()
	players.clear()
	local_avatar_data.clear()
	
	GameManager.reset_session()
	
	print("[NetworkManager] ✓ Desconectado correctamente (%d jugador(es) estaban conectados)" % player_count)
	EventBus.emit_system_message("Desconectado de la sala")

## Envía un mensaje de chat a todos
func send_chat_message(text: String) -> void:
	if peer == null:
		push_warning("[NetworkManager] No conectado a sala")
		return
	
	# Validación básica
	text = text.strip_edges()
	if text.is_empty():
		return
	
	if text.length() > 500:
		text = text.substr(0, 500)
		EventBus.emit_info("Mensaje truncado a 500 caracteres")
	
	var sender_id = multiplayer.get_unique_id()
	
	# Siempre usar RPC para broadcasting (tanto host como cliente)
	if is_host:
		# Host hace broadcast a todos (incluyéndose a sí mismo con call_local)
		rpc("_broadcast_chat_message", sender_id, text)
	else:
		# Cliente envía al host para que lo distribuya
		rpc_id(1, "_receive_chat_message", text)

# ===== CALLBACKS DE MULTIPLAYER =====

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] Peer conectado: %d" % id)
	
	if is_host:
		# El host espera a que el cliente envíe su avatar
		EventBus.emit_system_message("Jugador conectándose...")
	else:
		# Como cliente, enviar avatar al host
		if not local_avatar_data.is_empty():
			rpc_id(1, "_send_avatar_data", local_avatar_data)

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] Peer desconectado: %d" % id)
	
	# Desregistrar del monitor
	if is_host and connection_monitor:
		connection_monitor.unregister_peer(id)
	
	if players.has(id):
		var player_name = players[id].get("character_name", "Jugador")
		players.erase(id)
		
		# Emitir señales
		EventBus.player_disconnected.emit(id)
		EventBus.emit_system_message("%s se ha desconectado" % player_name)
		
		# Mostrar notificación visual
		EventBus.show_notification.emit("%s se desconectó de la sala" % player_name, "warning")
		
		if is_host:
			# Host notifica a todos los demás
			rpc("_notify_player_left", id, player_name)
			
			print("[NetworkManager] Jugadores restantes: %d" % players.size())

func _on_connected_to_server() -> void:
	print("[NetworkManager] ✓ Conectado al servidor")
	GameManager.local_peer_id = multiplayer.get_unique_id()

func _on_connection_failed() -> void:
	print("[NetworkManager] ✗ Conexión fallida")
	EventBus.connection_failed.emit("No se pudo conectar al host")
	EventBus.emit_error("Conexión fallida. Verifica el código de sala.")
	peer = null

func _on_server_disconnected() -> void:
	print("[NetworkManager] ✗ El host se desconectó")
	
	# Mostrar notificación prominente
	EventBus.show_error.emit("El host cerró la sala. Volviendo al menú principal...")
	EventBus.emit_system_message("El host cerró la sala")
	
	# Esperar un momento para que el usuario vea el mensaje
	await get_tree().create_timer(2.0).timeout
	
	# Limpiar y volver al menú
	disconnect_from_room()
	EventBus.connection_lost.emit()

# ===== RPCs =====

## [CLIENT → HOST] Cliente envía su avatar al conectarse
@rpc("any_peer", "call_remote", "reliable")
func _send_avatar_data(avatar_data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Validar límite de jugadores
	if players.size() >= MAX_PLAYERS:
		push_error("[NetworkManager] Sala llena, rechazando peer %d" % sender_id)
		peer.disconnect_peer(sender_id)
		return
	
	# Crear entrada para el jugador
	var player_name = avatar_data.get("name", "Jugador %d" % sender_id)
	players[sender_id] = {
		"peer_id": sender_id,
		"character_name": player_name,
		"avatar_data": avatar_data,
		"position": Vector2(320, 240),
		"state": "idle"
	}
	
	# Registrar en el monitor de conexiones
	connection_monitor.register_peer(sender_id)
	
	# Enviar lista completa de jugadores al recién llegado
	rpc_id(sender_id, "_receive_player_list", _serialize_players())
	
	# Notificar a todos
	rpc("_notify_player_joined", sender_id, avatar_data)
	
	print("[NetworkManager] ✓ Jugador '%s' (ID:%d) se unió" % [player_name, sender_id])

## [HOST → CLIENT] Host envía lista completa de jugadores
@rpc("authority", "call_remote", "reliable")
func _receive_player_list(players_data: Array) -> void:
	players.clear()
	
	for data in players_data:
		var p = {
			"peer_id": data["peer_id"],
			"character_name": data["character_name"],
			"avatar_data": data["avatar_data"],
			"position": Vector2(data["position"]["x"], data["position"]["y"]),
			"state": data["state"]
		}
		players[p["peer_id"]] = p
	
	EventBus.room_joined.emit()
	EventBus.emit_system_message("Conectado a la sala. Hay %d jugador(es) en línea" % players.size())
	print("[NetworkManager] ✓ Lista de jugadores recibida (%d jugadores)" % players.size())

## [HOST → ALL] Notifica que un jugador se unió
@rpc("authority", "call_local", "reliable")
func _notify_player_joined(peer_id: int, avatar_data: Dictionary) -> void:
	if players.has(peer_id):
		return
	
	var player_name = avatar_data.get("name", "Jugador")
	players[peer_id] = {
		"peer_id": peer_id,
		"character_name": player_name,
		"avatar_data": avatar_data,
		"position": Vector2(320, 240),
		"state": "idle"
	}
	
	EventBus.player_connected.emit(peer_id, player_name)
	EventBus.emit_system_message("%s se ha unido a la sala" % player_name)

## [HOST → ALL] Notifica que la sala se cerró
@rpc("authority", "call_local", "reliable")
func _notify_room_closed() -> void:
	print("[NetworkManager] El host cerró la sala")
	disconnect_from_room()

## [CLIENT → HOST] Cliente envía mensaje de chat
@rpc("any_peer", "call_remote", "reliable")
func _receive_chat_message(text: String) -> void:
	if not multiplayer.is_server():
		return
	
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Host hace broadcast a todos (incluyendo al cliente que envió)
	rpc("_broadcast_chat_message", sender_id, text)

## [HOST → ALL] Distribuye mensaje de chat
@rpc("authority", "call_local", "reliable")
func _broadcast_chat_message(sender_id: int, text: String) -> void:
	if not players.has(sender_id):
		return
	
	var sender_name = players[sender_id]["character_name"]
	EventBus.message_received.emit(sender_name, text, "normal")

## [HOST → ALL] Notifica que un jugador se fue
@rpc("authority", "call_local", "reliable")
func _notify_player_left(peer_id: int, player_name: String) -> void:
	if players.has(peer_id):
		players.erase(peer_id)
	EventBus.player_disconnected.emit(peer_id)

# ===== MÉTODOS PRIVADOS =====

func _generate_room_code() -> String:
	# Obtener IP local
	var local_ip = ""
	for ip in IP.get_local_addresses():
		# Priorizar IPs de red local
		if ip.begins_with("192.168.") or ip.begins_with("10."):
			local_ip = ip
			break
	
	if local_ip.is_empty():
		local_ip = "127.0.0.1"
	
	return "%s:%d" % [local_ip, DEFAULT_PORT]

func _serialize_players() -> Array:
	var result = []
	for player in players.values():
		result.append({
			"peer_id": player["peer_id"],
			"character_name": player["character_name"],
			"avatar_data": player["avatar_data"],
			"position": {"x": player["position"].x, "y": player["position"].y},
			"state": player["state"]
		})
	return result

func _is_valid_ip(ip: String) -> bool:
	# Validación básica de formato IP
	if ip == "localhost":
		return true
	
	var parts = ip.split(".")
	if parts.size() != 4:
		return false
	
	for part in parts:
		if not part.is_valid_int():
			return false
		var num = int(part)
		if num < 0 or num > 255:
			return false
	
	return true
