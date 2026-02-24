extends Node

@onready var map: TileMapLayer = get_parent().get_node("Map")
@onready var spawn_points: Node2D = get_parent().get_node("SpawnPoints")
@onready var interactive_objects: Node2D = get_parent().get_node("InteractiveObjects")
@onready var ui_layer: CanvasLayer = get_parent().get_node("UILayer")
@onready var room_code_label: Label = ui_layer.get_node("TopBar/MarginContainer/HBoxContainer/RoomCodeLabel")
@onready var players_label: Label = ui_layer.get_node("TopBar/MarginContainer/HBoxContainer/PlayersLabel")
@onready var leave_button: Button = ui_layer.get_node("TopBar/MarginContainer/HBoxContainer/LeaveButton")
@onready var chat: Control = ui_layer.get_node("Chat")

const REMOTE_AVATAR_SCENE = preload("res://scenes/remote_avatar.tscn")
const ACTION_SELECTOR_SCENE = preload("res://scenes/action_selector.tscn")
const SCENE_VIEWER_SCENE = preload("res://scenes/scene_viewer.tscn")

var local_avatar: CharacterBody2D
var players: Dictionary = {}
var current_spawn_index: int = 0
var room_code: String = ""

func _ready():
	print("[WorldController] Inicializando...")

	if not chat:
		push_error("[WorldController] ERROR: chat es null")
		return

	NetworkManager.player_joined.connect(_on_player_joined)
	NetworkManager.player_left.connect(_on_player_left)
	NetworkManager.room_created.connect(_on_room_code_received)

	if leave_button:
		leave_button.pressed.connect(_on_leave_pressed)

	_setup_interactive_objects()
	_create_local_avatar()
	_sync_existing_players()
	_update_ui()

	await get_tree().process_frame

	if AvatarManager.current_avatar:
		_safe_chat_notification(
			"¡Bienvenido al lobby, " + AvatarManager.current_avatar.nombre + "!",
			"#4A90E2"
		)

	# ✅ DIAGNÓSTICO: Imprimir estado del mundo
	_debug_world_state()

# ✅ NUEVO: Diagnóstico completo
func _debug_world_state():
	print("=== [WorldController] DIAGNÓSTICO ===")
	print("  Jugadores registrados: ", players.size())
	for peer_id in players.keys():
		var av = players[peer_id]
		print("  → Peer ", peer_id, " | Nodo: ", av.name,
			" | Posición: ", av.position,
			" | Visible: ", av.visible)
	print("  Spawn points: ", spawn_points.get_child_count() if spawn_points else 0)
	print("  Avatar local: ", local_avatar.name if local_avatar else "NULL")
	print("=====================================")

func _safe_chat_notification(text: String, color: String = "#F5A623"):
	if not chat or not chat.has_method("add_notification"):
		print("[WorldController] Chat no disponible: ", text)
		return
	chat.add_notification(text, color)

func _on_room_code_received(code: String):
	room_code = code
	_update_ui()

func _setup_interactive_objects():
	if not interactive_objects:
		return
	for child in interactive_objects.get_children():
		if child.has_signal("interaction_requested"):
			child.interaction_requested.connect(_on_interaction_requested)

func _create_local_avatar():
	if not AvatarManager.current_avatar:
		push_error("[WorldController] No hay avatar seleccionado")
		return

	var avatar = REMOTE_AVATAR_SCENE.instantiate()
	avatar.name = str(multiplayer.get_unique_id())
	avatar.set_multiplayer_authority(multiplayer.get_unique_id())

	# ✅ AÑADIR AL ÁRBOL ANTES de asignar avatar_data
	# Así @onready ya está listo cuando se dispara el setter
	var spawn_pos = _get_next_spawn_position()
	avatar.position = spawn_pos
	get_parent().add_child(avatar)

	# Asignar datos DESPUÉS de añadir al árbol
	avatar.avatar_data = AvatarManager.current_avatar

	# ✅ NUEVO: Añadir cámara que siga al jugador local
	_attach_camera(avatar)

	local_avatar = avatar
	players[multiplayer.get_unique_id()] = avatar

	print("[WorldController] Avatar local creado | Posición: ", spawn_pos,
		" | Peer: ", multiplayer.get_unique_id())

# ✅ NUEVO: Cámara que sigue al jugador
func _attach_camera(avatar_node: CharacterBody2D):
	var camera = Camera2D.new()
	camera.name = "PlayerCamera"
	camera.enabled = true
	# Límites suaves para que la cámara no salte
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0
	avatar_node.add_child(camera)
	print("[WorldController] Cámara adjuntada al avatar local")

func _sync_existing_players():
	for peer_id in NetworkManager.player_names.keys():
		if peer_id != multiplayer.get_unique_id():
			_spawn_remote_avatar(peer_id)

func _on_player_joined(peer_id: int):
	print("[WorldController] Jugador unido: ", peer_id)
	_spawn_remote_avatar(peer_id)
	_update_ui()
	var player_name = NetworkManager.player_names.get(peer_id, "Jugador")
	_safe_chat_notification(player_name + " se ha unido a la sala", "#50C878")

func _spawn_remote_avatar(peer_id: int):
	if players.has(peer_id):
		return

	var avatar_dict = NetworkManager.player_avatars.get(peer_id)
	if not avatar_dict:
		push_error("[WorldController] Sin datos de avatar para peer: ", peer_id)
		return

	var avatar_data_obj = AvatarData.from_dict(avatar_dict)

	var avatar = REMOTE_AVATAR_SCENE.instantiate()
	avatar.name = str(peer_id)
	avatar.set_multiplayer_authority(peer_id)

	# ✅ AÑADIR AL ÁRBOL ANTES de asignar datos
	avatar.position = _get_next_spawn_position()
	get_parent().add_child(avatar)
	avatar.avatar_data = avatar_data_obj

	players[peer_id] = avatar
	print("[WorldController] Avatar remoto creado | Peer: ", peer_id,
		" | Posición: ", avatar.position)

func _on_player_left(peer_id: int):
	if players.has(peer_id):
		var player_name = NetworkManager.player_names.get(peer_id, "Jugador")
		players[peer_id].queue_free()
		players.erase(peer_id)
		_update_ui()
		_safe_chat_notification(player_name + " ha salido de la sala", "#E94C3D")

func _get_next_spawn_position() -> Vector2:
	# ✅ Posiciones fijas más visibles: centro de pantalla aprox
	var default_positions = [
		Vector2(300, 300),
		Vector2(500, 300),
		Vector2(400, 450),
		Vector2(600, 450),
	]

	if spawn_points and spawn_points.get_child_count() > 0:
		var spawns = spawn_points.get_children()
		var spawn = spawns[current_spawn_index % spawns.size()]
		current_spawn_index += 1
		return spawn.position

	# Fallback a posiciones predefinidas
	var pos = default_positions[current_spawn_index % default_positions.size()]
	current_spawn_index += 1
	return pos

func _update_ui():
	if not room_code_label or not players_label:
		return

	var player_count = NetworkManager.player_names.size()
	players_label.text = "Jugadores: %d/4" % player_count

	if multiplayer.is_server():
		if room_code.is_empty():
			room_code_label.text = "Código de Sala: Generando..."
		else:
			room_code_label.text = "📋 Código: " + room_code + " (Click para copiar)"
			if not room_code_label.gui_input.is_connected(_on_room_code_clicked):
				room_code_label.gui_input.connect(_on_room_code_clicked)
	else:
		room_code_label.text = "Conectado como Cliente"

func _on_room_code_clicked(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not room_code.is_empty():
			DisplayServer.clipboard_set(room_code)
			_safe_chat_notification("Código copiado: " + room_code, "#4A90E2")

func _on_leave_pressed():
	_safe_chat_notification("Saliendo de la sala...", "#F5A623")
	await get_tree().create_timer(0.3).timeout
	multiplayer.multiplayer_peer = null
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_interaction_requested(players_near: Array):
	if players_near.size() != 2:
		_safe_chat_notification("Necesitas estar con otro jugador para interactuar", "#F5A623")
		return

	var other_avatar = null
	for player in players_near:
		if player != local_avatar:
			other_avatar = player
			break

	if not other_avatar:
		return

	var my_data = AvatarManager.current_avatar
	var other_peer_id = int(other_avatar.name)
	var other_data_dict = NetworkManager.player_avatars.get(other_peer_id)

	if not other_data_dict:
		push_error("[WorldController] Sin datos del otro jugador")
		return

	var other_data = AvatarData.from_dict(other_data_dict)
	var acciones = ActionFilter.get_compatible_actions(my_data, other_data)

	if acciones.is_empty():
		_safe_chat_notification("No hay acciones compatibles disponibles", "#E94C3D")
		return

	_show_action_selector(acciones, other_peer_id)

func _show_action_selector(acciones: Array, other_peer_id: int):
	var selector = ACTION_SELECTOR_SCENE.instantiate()
	selector.setup(acciones, other_peer_id, _on_action_selected)
	ui_layer.add_child(selector)

func _on_action_selected(accion: Dictionary, other_peer_id: int):
	_show_scene_for_all.rpc(accion, other_peer_id)

@rpc("any_peer", "call_local")
func _show_scene_for_all(accion: Dictionary, other_peer_id: int):
	var viewer = SCENE_VIEWER_SCENE.instantiate()
	viewer.show_scene(accion)
	ui_layer.add_child(viewer)

	var initiator_id = multiplayer.get_remote_sender_id()
	if initiator_id == 0:
		initiator_id = multiplayer.get_unique_id()

	var initiator = NetworkManager.player_names.get(initiator_id, "Alguien")
	var other = NetworkManager.player_names.get(other_peer_id, "Otro jugador")
	_safe_chat_notification(initiator + " y " + other + " realizan: " + accion["nombre"], "#4A90E2")
