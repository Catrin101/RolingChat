# scripts/ui/main_menu_controller.gd
extends Control

## MainMenuController - Controlador del menú principal
## Responsabilidad: Gestionar UI de crear/unir sala y navegación inicial

# ===== REFERENCIAS DE NODOS =====

@onready var title_label: Label = $CenterContainer/VBoxContainer/TitleLabel
@onready var version_label: Label = $VersionLabel

# Panel de inicio
@onready var main_panel: Panel = $CenterContainer/VBoxContainer/MainPanel
@onready var create_room_button: Button = $CenterContainer/VBoxContainer/MainPanel/VBoxContainer/CreateRoomButton
@onready var join_room_button: Button = $CenterContainer/VBoxContainer/MainPanel/VBoxContainer/JoinRoomButton
@onready var create_avatar_button: Button = $CenterContainer/VBoxContainer/MainPanel/VBoxContainer/CreateAvatarButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/MainPanel/VBoxContainer/QuitButton

# Panel de crear sala
@onready var create_panel: Panel = $CenterContainer/VBoxContainer/CreatePanel
@onready var room_name_input: LineEdit = $CenterContainer/VBoxContainer/CreatePanel/VBoxContainer/RoomNameInput
@onready var create_confirm_button: Button = $CenterContainer/VBoxContainer/CreatePanel/VBoxContainer/HBoxContainer/CreateConfirmButton
@onready var create_cancel_button: Button = $CenterContainer/VBoxContainer/CreatePanel/VBoxContainer/HBoxContainer/CreateCancelButton

# Panel de código de sala
@onready var code_panel: Panel = $CenterContainer/VBoxContainer/CodePanel
@onready var code_display_label: RichTextLabel = $CenterContainer/VBoxContainer/CodePanel/VBoxContainer/CodeDisplayLabel
@onready var copy_code_button: Button = $CenterContainer/VBoxContainer/CodePanel/VBoxContainer/CopyCodeButton
@onready var start_button: Button = $CenterContainer/VBoxContainer/CodePanel/VBoxContainer/StartButton

# Panel de unirse
@onready var join_panel: Panel = $CenterContainer/VBoxContainer/JoinPanel
@onready var code_input: LineEdit = $CenterContainer/VBoxContainer/JoinPanel/VBoxContainer/CodeInput
@onready var join_confirm_button: Button = $CenterContainer/VBoxContainer/JoinPanel/VBoxContainer/HBoxContainer/JoinConfirmButton
@onready var join_cancel_button: Button = $CenterContainer/VBoxContainer/JoinPanel/VBoxContainer/HBoxContainer/JoinCancelButton

# Panel de perfiles
@onready var profiles_panel: Panel = $CenterContainer/VBoxContainer/ProfilesPanel
@onready var profiles_scroll: ScrollContainer = $CenterContainer/VBoxContainer/ProfilesPanel/VBoxContainer/ScrollContainer
@onready var profiles_container: VBoxContainer = $CenterContainer/VBoxContainer/ProfilesPanel/VBoxContainer/ScrollContainer/ProfilesContainer
@onready var no_profiles_label: Label = $CenterContainer/VBoxContainer/ProfilesPanel/VBoxContainer/NoProfilesLabel
@onready var new_profile_button: Button = $CenterContainer/VBoxContainer/ProfilesPanel/VBoxContainer/NewProfileButton
@onready var profiles_back_button: Button = $CenterContainer/VBoxContainer/ProfilesPanel/VBoxContainer/BackButton

# Mensajes
@onready var status_label: Label = $StatusLabel
@onready var error_label: Label = $ErrorLabel

# ===== ESTADO =====

var current_room_code: String = ""
var selected_profile_name: String = ""
var profile_card_scene: PackedScene = preload("res://scenes/ui/profile_card.tscn")

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Configurar versión
	version_label.text = "v" + GameManager.VERSION
	
	# Conectar señales de botones
	create_room_button.pressed.connect(_on_create_room_pressed)
	join_room_button.pressed.connect(_on_join_room_pressed)
	create_avatar_button.pressed.connect(_on_create_avatar_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	create_confirm_button.pressed.connect(_on_create_confirm_pressed)
	create_cancel_button.pressed.connect(_on_create_cancel_pressed)
	
	join_confirm_button.pressed.connect(_on_join_confirm_pressed)
	join_cancel_button.pressed.connect(_on_join_cancel_pressed)
	
	copy_code_button.pressed.connect(_on_copy_code_pressed)
	start_button.pressed.connect(_on_start_pressed)
	
	new_profile_button.pressed.connect(_on_new_profile_pressed)
	profiles_back_button.pressed.connect(_on_profiles_back_pressed)
	
	# Conectar señales del EventBus
	EventBus.room_created.connect(_on_room_created)
	EventBus.room_joined.connect(_on_room_joined)
	EventBus.connection_failed.connect(_on_connection_failed)
	EventBus.show_error.connect(_on_error_received)
	
	# Configurar inputs
	room_name_input.text_submitted.connect(_on_room_name_submitted)
	code_input.text_submitted.connect(_on_code_submitted)
	
	# Mostrar panel principal
	_show_main_panel()
	
	# Cargar perfil actual si existe
	_load_selected_profile()
	
	print("[MainMenu] Menú principal inicializado")

# ===== CARGA DE PERFIL =====

func _load_selected_profile() -> void:
	# Si ya hay un avatar en GameManager, usarlo
	var current_avatar = GameManager.get_current_avatar()
	if current_avatar != null:
		selected_profile_name = current_avatar.character_name
		print("[MainMenu] Perfil actual: %s" % selected_profile_name)
		return
	
	# Intentar cargar último perfil usado (guardado en config)
	# Por ahora, no hacemos nada si no hay perfil

# ===== NAVEGACIÓN DE PANELES =====

func _show_main_panel() -> void:
	main_panel.visible = true
	create_panel.visible = false
	code_panel.visible = false
	join_panel.visible = false
	profiles_panel.visible = false
	_clear_status()
	
	# Actualizar texto del botón de avatar según si hay perfil
	if selected_profile_name.is_empty():
		create_avatar_button.text = "✏ Crear Avatar"
	else:
		create_avatar_button.text = "✏ " + selected_profile_name

func _show_create_panel() -> void:
	main_panel.visible = false
	create_panel.visible = true
	code_panel.visible = false
	join_panel.visible = false
	room_name_input.clear()
	room_name_input.grab_focus()
	_clear_status()

func _show_code_panel() -> void:
	main_panel.visible = false
	create_panel.visible = false
	code_panel.visible = true
	join_panel.visible = false

func _show_join_panel() -> void:
	main_panel.visible = false
	create_panel.visible = false
	code_panel.visible = false
	join_panel.visible = true
	profiles_panel.visible = false
	code_input.clear()
	code_input.grab_focus()
	_clear_status()

func _show_profiles_panel() -> void:
	main_panel.visible = false
	create_panel.visible = false
	code_panel.visible = false
	join_panel.visible = false
	profiles_panel.visible = true
	_clear_status()
	_refresh_profiles_list()

# ===== CALLBACKS DE BOTONES =====

func _on_create_room_pressed() -> void:
	_show_create_panel()

func _on_join_room_pressed() -> void:
	_show_join_panel()

func _on_create_avatar_pressed() -> void:
	_show_profiles_panel()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_create_confirm_pressed() -> void:
	# Validar que haya un perfil seleccionado
	if selected_profile_name.is_empty():
		EventBus.show_error.emit("Debes seleccionar un perfil antes de crear una sala")
		return
	
	var room_name = room_name_input.text.strip_edges()
	
	if room_name.is_empty():
		room_name = "Sala de Rol"
	
	_set_status("Creando sala...", false)
	
	# Crear sala
	var code = NetworkManager.create_room(room_name)
	
	if code.is_empty():
		_set_status("Error al crear sala", true)
		return
	
	# Sala creada exitosamente (se maneja en la señal room_created)

func _on_create_cancel_pressed() -> void:
	_show_main_panel()

func _on_join_confirm_pressed() -> void:
	# Validar que haya un perfil seleccionado
	if selected_profile_name.is_empty():
		EventBus.show_error.emit("Debes seleccionar un perfil antes de unirte a una sala")
		return
	
	var code = code_input.text.strip_edges()
	
	if code.is_empty():
		_set_status("Ingresa un código de sala", true)
		return
	
	_set_status("Conectando...", false)
	
	# Obtener avatar actual
	var current_avatar = GameManager.get_current_avatar()
	var avatar_dict = {}
	
	if current_avatar:
		avatar_dict = current_avatar.to_dict()
	else:
		# Fallback si por alguna razón no hay avatar
		avatar_dict = {
			"name": "Jugador",
			"character_name": "Jugador"
		}
	
	var success = NetworkManager.join_room(code, avatar_dict)
	
	if not success:
		_set_status("Código inválido", true)
		return
	
	# La conexión está en progreso, esperamos señal room_joined o connection_failed

func _on_join_cancel_pressed() -> void:
	_show_main_panel()

func _on_copy_code_pressed() -> void:
	DisplayServer.clipboard_set(current_room_code)
	_set_status("Código copiado al portapapeles", false)

func _on_start_pressed() -> void:
	_set_status("Iniciando juego...", false)
	
	# Cargar lobby temporal
	get_tree().change_scene_to_file("res://scenes/game_world/lobby.tscn")
	
	print("[MainMenu] Iniciando juego como host")

# ===== CALLBACKS DE INPUTS =====

func _on_room_name_submitted(text: String) -> void:
	_on_create_confirm_pressed()

func _on_code_submitted(text: String) -> void:
	_on_join_confirm_pressed()

# ===== CALLBACKS DE EVENTBUS =====

func _on_room_created(room_code: String) -> void:
	current_room_code = room_code
	code_display_label.text = "Código de sala:\n\n[b]%s[/b]\n\nComparte este código con tus amigos" % room_code
	_show_code_panel()
	_set_status("Sala creada exitosamente", false)

func _on_room_joined() -> void:
	_set_status("Conectado a la sala", false)
	
	# Cargar lobby temporal
	await get_tree().create_timer(0.5).timeout  # Pequeña pausa para feedback visual
	get_tree().change_scene_to_file("res://scenes/game_world/lobby.tscn")
	
	print("[MainMenu] Conectado exitosamente como cliente")

func _on_connection_failed(reason: String) -> void:
	_set_status("Conexión fallida: %s" % reason, true)

func _on_error_received(message: String) -> void:
	_set_status(message, true)

# ===== UTILIDADES =====

func _set_status(message: String, is_error: bool) -> void:
	if is_error:
		error_label.text = message
		error_label.visible = true
		status_label.visible = false
	else:
		status_label.text = message
		status_label.visible = true
		error_label.visible = false

func _clear_status() -> void:
	status_label.visible = false
	error_label.visible = false

# ===== CALLBACKS - PANEL DE PERFILES =====

func _on_new_profile_pressed() -> void:
	# Ir al creador de avatares
	get_tree().change_scene_to_file("res://scenes/avatar_creator/avatar_creator.tscn")

func _on_profiles_back_pressed() -> void:
	_show_main_panel()

func _on_profile_selected(profile_name: String) -> void:
	# Cargar y establecer como perfil actual
	if ProfileManager.load_profile_as_current(profile_name):
		selected_profile_name = profile_name
		EventBus.show_success.emit("Perfil '%s' seleccionado" % profile_name)
		_refresh_profiles_list()
		
		# Actualizar botón en menú principal
		create_avatar_button.text = "✏ " + profile_name
	else:
		EventBus.show_error.emit("Error al cargar perfil")

func _on_profile_edited(profile_name: String) -> void:
	# Cargar perfil en el creador para edición
	var avatar_data = ProfileManager.load_profile(profile_name)
	if avatar_data == null:
		EventBus.show_error.emit("Error al cargar perfil")
		return
	
	# Establecer como actual y cambiar a editor
	GameManager.set_current_avatar(avatar_data)
	get_tree().change_scene_to_file("res://scenes/avatar_creator/avatar_creator.tscn")

func _on_profile_deleted(profile_name: String) -> void:
	if ProfileManager.delete_profile(profile_name):
		EventBus.show_success.emit("Perfil eliminado")
		
		# Si era el seleccionado, limpiar selección
		if selected_profile_name == profile_name:
			selected_profile_name = ""
			GameManager.set_current_avatar(null)
			create_avatar_button.text = "✏ Crear Avatar"
		
		_refresh_profiles_list()
	else:
		EventBus.show_error.emit("Error al eliminar perfil")

# ===== GESTIÓN DE LISTA DE PERFILES =====

func _refresh_profiles_list() -> void:
	# Limpiar lista actual
	for child in profiles_container.get_children():
		child.queue_free()
	
	# Obtener perfiles disponibles
	var profiles = ProfileManager.get_available_profiles()
	
	if profiles.is_empty():
		# Mostrar mensaje de no perfiles
		no_profiles_label.visible = true
		profiles_scroll.visible = false
	else:
		no_profiles_label.visible = false
		profiles_scroll.visible = true
		
		# Crear card para cada perfil
		for profile_name in profiles:
			var avatar_data = ProfileManager.load_profile(profile_name)
			
			if avatar_data == null:
				continue
			
			# Instanciar ProfileCard
			var card = profile_card_scene.instantiate()
			profiles_container.add_child(card)
			
			# Configurar card
			card.setup(profile_name, avatar_data)
			
			# Marcar como seleccionado si corresponde
			if profile_name == selected_profile_name:
				card.set_selected(true)
			
			# Conectar señales
			card.selected.connect(_on_profile_selected)
			card.edited.connect(_on_profile_edited)
			card.deleted.connect(_on_profile_deleted)
