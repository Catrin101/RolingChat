# scripts/systems/networking/connection_monitor.gd
class_name ConnectionMonitor
extends Node

## ConnectionMonitor - Monitorea conexiones activas
## Responsabilidad: Detectar conexiones muertas mediante heartbeat
## Uso: Solo en el host

# ===== CONSTANTES =====

const HEARTBEAT_INTERVAL := 5.0  # Segundos entre heartbeats
const TIMEOUT_THRESHOLD := 15.0  # Segundos sin respuesta = timeout

# ===== ESTADO =====

var last_heartbeat: Dictionary = {}  # {peer_id: timestamp}
var heartbeat_timer: Timer = null
var is_monitoring: bool = false

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Crear timer de heartbeat
	heartbeat_timer = Timer.new()
	heartbeat_timer.wait_time = HEARTBEAT_INTERVAL
	heartbeat_timer.timeout.connect(_on_heartbeat_timer_timeout)
	add_child(heartbeat_timer)
	
	print("[ConnectionMonitor] Monitor de conexiones inicializado")

# ===== API PÚBLICA =====

## Inicia el monitoreo (solo llamar en el host)
func start_monitoring() -> void:
	if not multiplayer.is_server():
		push_warning("[ConnectionMonitor] Solo el host puede monitorear conexiones")
		return
	
	is_monitoring = true
	heartbeat_timer.start()
	print("[ConnectionMonitor] Monitoreo iniciado")

## Detiene el monitoreo
func stop_monitoring() -> void:
	is_monitoring = false
	heartbeat_timer.stop()
	last_heartbeat.clear()
	print("[ConnectionMonitor] Monitoreo detenido")

## Registra un nuevo peer para monitoreo
func register_peer(peer_id: int) -> void:
	last_heartbeat[peer_id] = Time.get_ticks_msec() / 1000.0
	print("[ConnectionMonitor] Peer %d registrado" % peer_id)

## Elimina un peer del monitoreo
func unregister_peer(peer_id: int) -> void:
	if last_heartbeat.has(peer_id):
		last_heartbeat.erase(peer_id)
		print("[ConnectionMonitor] Peer %d desregistrado" % peer_id)

# ===== HEARTBEAT =====

func _on_heartbeat_timer_timeout() -> void:
	if not is_monitoring:
		return
	
	# Enviar heartbeat a todos los clientes
	rpc("_receive_heartbeat")
	
	# Verificar timeouts
	_check_timeouts()

@rpc("authority", "call_remote", "reliable")
func _receive_heartbeat() -> void:
	# Cliente responde al heartbeat
	rpc_id(1, "_heartbeat_response")

@rpc("any_peer", "call_remote", "reliable")
func _heartbeat_response() -> void:
	if not multiplayer.is_server():
		return
	
	var peer_id = multiplayer.get_remote_sender_id()
	var current_time = Time.get_ticks_msec() / 1000.0
	
	if last_heartbeat.has(peer_id):
		last_heartbeat[peer_id] = current_time

func _check_timeouts() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var timed_out_peers: Array[int] = []
	
	for peer_id in last_heartbeat.keys():
		var last_response = last_heartbeat[peer_id]
		var elapsed = current_time - last_response
		
		if elapsed > TIMEOUT_THRESHOLD:
			timed_out_peers.append(peer_id)
			print("[ConnectionMonitor] ⚠ Peer %d timeout (%.1fs sin respuesta)" % [peer_id, elapsed])
	
	# Desconectar peers con timeout
	for peer_id in timed_out_peers:
		_handle_timeout(peer_id)

func _handle_timeout(peer_id: int) -> void:
	print("[ConnectionMonitor] Desconectando peer %d por timeout" % peer_id)
	
	# Desconectar el peer
	if multiplayer.multiplayer_peer is ENetMultiplayerPeer:
		var enet_peer = multiplayer.multiplayer_peer as ENetMultiplayerPeer
		enet_peer.disconnect_peer(peer_id)
	
	# Eliminar del registro
	unregister_peer(peer_id)
