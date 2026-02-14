# scripts/ui/lobby_controller.gd
extends Control

## LobbyController - Lobby temporal para testing
## Responsabilidad: Gestionar la escena de lobby donde los jugadores pueden chatear
## Este es un MVP, será reemplazado por el mundo completo en futuras fases

# ===== REFERENCIAS A NODOS =====

@onready var room_info_label: Label = $RoomInfoLabel
@onready var players_label: Label = $PlayersLabel

# ===== ESTADO =====

var connected_players: int = 0

# ===== CICLO DE VIDA =====

func _ready() -> void:
	EventBus.player_connected.connect(_on_player_connected)
	EventBus.player_disconnected.connect(_on_player_disconnected)
	EventBus.connection_lost.connect(_on_connection_lost)
	
	# Inicializar contador con jugadores ya conectados
	connected_players = NetworkManager.players.size()
	
	# Actualizar UI
	_update_room_info()
	_update_players_count()
	
	# Mensaje de bienvenida
	if GameManager.is_host:
		EventBus.emit_system_message("Bienvenido al lobby. Eres el host de la sala.")
	else:
		EventBus.emit_system_message("Bienvenido al lobby. Te has unido a la sala.")
	
	print("[Lobby] Lobby inicializado")

# ===== CALLBACKS =====

func _on_disconnect_pressed() -> void:
	# Confirmar desconexión
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "¿Seguro que quieres salir de la sala?"
	confirm.confirmed.connect(_disconnect_confirmed)
	add_child(confirm)
	confirm.popup_centered()

func _disconnect_confirmed() -> void:
	print("[Lobby] Desconectando de la sala...")
	NetworkManager.disconnect_from_room()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_player_connected(peer_id: int, player_name: String) -> void:
	# Actualizar con el total real de jugadores
	connected_players = NetworkManager.players.size()
	_update_players_count()
	print("[Lobby] Jugador conectado: %s (ID: %d)" % [player_name, peer_id])

func _on_player_disconnected(peer_id: int) -> void:
	# Actualizar con el total real de jugadores
	connected_players = NetworkManager.players.size()
	_update_players_count()
	print("[Lobby] Jugador desconectado (ID: %d)" % peer_id)

func _on_connection_lost() -> void:
	print("[Lobby] Conexión perdida, volviendo al menú principal")
	
	# Mostrar mensaje de error
	EventBus.show_error.emit("Conexión perdida con el servidor")
	
	# Esperar un momento antes de cambiar de escena
	await get_tree().create_timer(1.5).timeout
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# ===== ACTUALIZACIÓN DE UI =====

func _update_room_info() -> void:
	var room_code = GameManager.room_code
	var room_name = GameManager.room_name
	
	if room_name.is_empty():
		room_name = "Sala de Rol"
	
	room_info_label.text = "Sala: %s | Código: %s" % [room_name, room_code]

func _update_players_count() -> void:
	var total_players = NetworkManager.players.size()
	players_label.text = "Jugadores: %d/%d" % [total_players, NetworkManager.MAX_PLAYERS]

# ===== UTILIDADES =====

func _input(event: InputEvent) -> void:
	# Atajo: ESC para abrir menú de desconexión
	if event.is_action_pressed("ui_cancel"):
		_on_disconnect_pressed()
