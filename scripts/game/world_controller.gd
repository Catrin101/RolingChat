extends Node

# Referencias a nodos de la escena
@onready var map: TileMapLayer = get_parent().get_node("Map")
@onready var spawn_points: Node2D = get_parent().get_node("SpawnPoints")
@onready var interactive_objects: Node2D = get_parent().get_node("InteractiveObjects")
@onready var ui_layer: CanvasLayer = get_parent().get_node("UILayer")
@onready var room_code_label: Label = ui_layer.get_node("TopBar/MarginContainer/HBoxContainer/RoomCodeLabel")
@onready var players_label: Label = ui_layer.get_node("TopBar/MarginContainer/HBoxContainer/PlayersLabel")
@onready var leave_button: Button = ui_layer.get_node("TopBar/MarginContainer/HBoxContainer/LeaveButton")
@onready var chat: Control = ui_layer.get_node("Chat")

# Escenas precargadas
const REMOTE_AVATAR_SCENE = preload("res://scenes/remote_avatar.tscn")
const ACTION_SELECTOR_SCENE = preload("res://scenes/action_selector.tscn")
const SCENE_VIEWER_SCENE = preload("res://scenes/scene_viewer.tscn")

# Estado del mundo
var local_avatar: CharacterBody2D
var players: Dictionary = {}  # peer_id -> RemoteAvatar
var current_spawn_index: int = 0

func _ready():
	# Conectar señales del NetworkManager
	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	
	# Conectar botón de salir
	leave_button.pressed.connect(_on_leave_pressed)
	
	# Configurar objetos interactivos
	_setup_interactive_objects()
	
	# Crear avatar local
	_create_local_avatar()
	
	# Sincronizar jugadores ya conectados
	_sync_existing_players()
	
	# Actualizar UI
	_update_ui()

func _setup_interactive_objects():
	# Los objetos interactivos deben crearse manualmente en el editor
	# o instanciarse aquí desde código
	for child in interactive_objects.get_children():
		if child.has_signal("interaction_requested"):
			child.interaction_requested.connect(_on_interaction_requested)

func _create_local_avatar():
	if not AvatarManager.current_avatar:
		push_error("[WorldController] No hay avatar seleccionado")
		return
	
	# Instanciar avatar
	local_avatar = REMOTE_AVATAR_SCENE.instantiate()
	local_avatar.name = str(multiplayer.get_unique_id())
	local_avatar.avatar_data = AvatarManager.current_avatar
	local_avatar.set_multiplayer_authority(multiplayer.get_unique_id())
	
	# Posicionar en spawn point
	var spawn_pos = _get_next_spawn_position()
	local_avatar.position = spawn_pos
	
	# Añadir al mapa
	get_parent().add_child(local_avatar)
	
	# Guardar referencia
	players[multiplayer.get_unique_id()] = local_avatar
	
	print("[WorldController] Avatar local creado en posición: ", spawn_pos)

func _sync_existing_players():
	# Sincronizar jugadores que ya estaban en la sala
	for peer_id in NetworkManager.player_names.keys():
		if peer_id != multiplayer.get_unique_id():
			_spawn_remote_avatar(peer_id)

func _on_player_joined(peer_id: int):
	print("[WorldController] Jugador unido: ", peer_id)
	_spawn_remote_avatar(peer_id)
	_update_ui()
	
	# Notificar en el chat
	var player_name = NetworkManager.player_names.get(peer_id, "Jugador")
	chat.add_notification(player_name + " se ha unido a la sala", "#50C878")

func _spawn_remote_avatar(peer_id: int):
	if players.has(peer_id):
		return  # Ya existe
	
	# Obtener datos del avatar
	var avatar_dict = NetworkManager.player_avatars.get(peer_id)
	if not avatar_dict:
		push_error("[WorldController] No hay datos de avatar para peer ", peer_id)
		return
	
	var avatar_data = AvatarData.from_dict(avatar_dict)
	
	# Instanciar avatar remoto
	var avatar = REMOTE_AVATAR_SCENE.instantiate()
	avatar.name = str(peer_id)
	avatar.avatar_data = avatar_data
	avatar.set_multiplayer_authority(peer_id)
	
	# Posicionar
	avatar.position = _get_next_spawn_position()
	
	# Añadir al mapa
	get_parent().add_child(avatar)
	
	# Guardar referencia
	players[peer_id] = avatar
	
	print("[WorldController] Avatar remoto creado para peer ", peer_id)

func _on_player_left(peer_id: int):
	print("[WorldController] Jugador desconectado: ", peer_id)
	
	if players.has(peer_id):
		var player_name = NetworkManager.player_names.get(peer_id, "Jugador")
		players[peer_id].queue_free()
		players.erase(peer_id)
		_update_ui()
		
		# Notificar en el chat
		chat.add_notification(player_name + " ha salido de la sala", "#E94C3D")

func _get_next_spawn_position() -> Vector2:
	var spawns = spawn_points.get_children()
	if spawns.is_empty():
		return Vector2(200, 200)  # Posición por defecto
	
	var spawn = spawns[current_spawn_index % spawns.size()]
	current_spawn_index += 1
	return spawn.position

func _update_ui():
	# Actualizar contador de jugadores
	var player_count = NetworkManager.player_names.size()
	players_label.text = "Jugadores: %d/8" % player_count
	
	# Si somos el host, mostrar código de sala
	if multiplayer.is_server():
		# El código se genera en NetworkManager, aquí lo mostramos
		# Para MVP, usamos un código dummy
		room_code_label.text = "Código de Sala: (Modo Local)"

func _on_leave_pressed():
	# Desconectar y volver al menú
	print("[WorldController] Saliendo de la sala...")
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_interaction_requested(players_near: Array):
	print("[WorldController] Interacción solicitada con ", players_near.size(), " jugadores")
	
	# Debe haber exactamente 2 jugadores
	if players_near.size() != 2:
		chat.add_notification("Necesitas estar con otro jugador para interactuar", "#F5A623")
		return
	
	# Identificar el otro jugador
	var other_avatar = null
	for player in players_near:
		if player != local_avatar:
			other_avatar = player
			break
	
	if not other_avatar:
		return
	
	# Obtener IDs de los avatares
	var my_data = AvatarManager.current_avatar
	var other_peer_id = int(other_avatar.name)
	var other_data_dict = NetworkManager.player_avatars.get(other_peer_id)
	
	if not other_data_dict:
		push_error("[WorldController] No se encontraron datos del otro jugador")
		return
	
	var other_data = AvatarData.from_dict(other_data_dict)
	
	# Filtrar acciones compatibles
	var acciones = ActionFilter.get_compatible_actions(my_data, other_data)
	
	if acciones.is_empty():
		chat.add_notification("No hay acciones compatibles disponibles", "#E94C3D")
		return
	
	# Mostrar selector de acciones
	_show_action_selector(acciones, other_peer_id)

func _show_action_selector(acciones: Array, other_peer_id: int):
	var selector = ACTION_SELECTOR_SCENE.instantiate()
	selector.setup(acciones, other_peer_id, _on_action_selected)
	ui_layer.add_child(selector)

func _on_action_selected(accion: Dictionary, other_peer_id: int):
	print("[WorldController] Acción seleccionada: ", accion["nombre"])
	
	# Enviar RPC para sincronizar la escena en ambos clientes
	rpc("_show_scene_for_all", accion, other_peer_id)

@rpc("any_peer", "call_local")
func _show_scene_for_all(accion: Dictionary, other_peer_id: int):
	# Mostrar el visor de escena
	var viewer = SCENE_VIEWER_SCENE.instantiate()
	viewer.show_scene(accion)
	ui_layer.add_child(viewer)
	
	# Notificar en el chat
	var initiator = NetworkManager.player_names.get(multiplayer.get_remote_sender_id(), "Alguien")
	var other = NetworkManager.player_names.get(other_peer_id, "Otro jugador")
	chat.add_notification(initiator + " y " + other + " están realizando: " + accion["nombre"], "#4A90E2")
