# scripts/ui/world_controller.gd
extends Node2D

## WorldController - Controlador del mundo de juego
## Responsabilidad: Gestionar la escena del mundo, UI overlay, transiciones
## Este es el mundo básico para MVP - será expandido en fases futuras

# ===== REFERENCIAS DE NODOS =====

@onready var player_spawner: PlayerSpawner = $PlayerSpawner
@onready var chat_panel: Control = $UI/ChatPanel
@onready var players_label: Label = $UI/TopBar/PlayersLabel
@onready var disconnect_button: Button = $UI/TopBar/DisconnectButton

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Conectar señales
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	
	# Conectar señales del EventBus
	EventBus.player_connected.connect(_on_player_connected)
	EventBus.player_disconnected.connect(_on_player_disconnected)
	EventBus.connection_lost.connect(_on_connection_lost)
	
	# Actualizar UI
	_update_players_count()
	
	# Mensaje de bienvenida
	EventBus.emit_system_message("Bienvenido al mundo de juego")
	
	print("[World] Mundo inicializado")

func _process(_delta: float) -> void:
	# Actualizar contador de jugadores
	_update_players_count()

# ===== CALLBACKS =====

func _on_disconnect_pressed() -> void:
	# Confirmar desconexión
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "¿Seguro que quieres salir del mundo?"
	confirm.confirmed.connect(_disconnect_confirmed)
	add_child(confirm)
	confirm.popup_centered()

func _disconnect_confirmed() -> void:
	NetworkManager.disconnect_from_room()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_player_connected(peer_id: int, player_name: String) -> void:
	_update_players_count()
	print("[World] Jugador conectado: %s (ID: %d)" % [player_name, peer_id])

func _on_player_disconnected(peer_id: int) -> void:
	_update_players_count()
	print("[World] Jugador desconectado (ID: %d)" % peer_id)

func _on_connection_lost() -> void:
	print("[World] Conexión perdida, volviendo al menú principal")
	
	# Mostrar mensaje de error
	EventBus.show_error.emit("Conexión perdida con el servidor")
	
	# Esperar un momento antes de cambiar de escena
	await get_tree().create_timer(1.5).timeout
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# ===== ACTUALIZACIÓN DE UI =====

func _update_players_count() -> void:
	var count = player_spawner.get_player_count()
	players_label.text = "Jugadores: %d/%d" % [count, NetworkManager.MAX_PLAYERS]

# ===== INPUT =====

func _input(event: InputEvent) -> void:
	# ESC para abrir menú de desconexión
	if event.is_action_pressed("ui_cancel"):
		_on_disconnect_pressed()
