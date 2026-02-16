extends Control

# Referencias a nodos UI corregidas
@onready var create_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/CreateRoomButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/JoinContainer/JoinHBox/JoinButton
@onready var code_input: LineEdit = $CenterContainer/VBoxContainer/ButtonsContainer/JoinContainer/JoinHBox/CodeInput
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/QuitButton
@onready var status_label: Label = $StatusPanel/MarginContainer/StatusLabel

# ✅ NUEVO: Referencias al selector de avatares
@onready var avatar_section: VBoxContainer = $CenterContainer/VBoxContainer/ButtonsContainer/AvatarSection
@onready var avatar_selector: OptionButton = $CenterContainer/VBoxContainer/ButtonsContainer/AvatarSection/AvatarHBox/AvatarSelector
@onready var create_avatar_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/AvatarSection/AvatarHBox/CreateAvatarButton
@onready var selected_avatar_label: Label = $CenterContainer/VBoxContainer/ButtonsContainer/AvatarSection/SelectedAvatarLabel

var available_avatars: Array[String] = []
var selected_avatar_index: int = -1

func _ready():
	# Conectar señales de botones
	create_button.pressed.connect(_on_create_pressed)
	join_button.pressed.connect(_on_join_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# ✅ NUEVO: Conectar botones de avatar
	create_avatar_button.pressed.connect(_on_create_avatar_pressed)
	avatar_selector.item_selected.connect(_on_avatar_selected)
	
	# Conectar señal de enter en el LineEdit
	code_input.text_submitted.connect(func(_text): _on_join_pressed())
	
	# Conectar señales del NetworkManager
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.connection_successful.connect(_on_connection_successful)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	# ✅ NUEVO: Cargar lista de avatares
	_load_avatars()
	
	# Inicializar UI
	_update_status("Listo para jugar", Color.WHITE)

# ✅ NUEVO: Cargar avatares disponibles
func _load_avatars():
	available_avatars = AvatarManager.list_profiles()
	avatar_selector.clear()
	
	if available_avatars.is_empty():
		avatar_selector.add_item("Sin avatares disponibles")
		avatar_selector.disabled = true
		create_button.disabled = true
		join_button.disabled = true
		selected_avatar_label.text = "⚠️ Debes crear un avatar primero"
		selected_avatar_label.modulate = Color(0.96, 0.64, 0.14)
	else:
		for avatar_name in available_avatars:
			avatar_selector.add_item(avatar_name)
		
		# Seleccionar el primero automáticamente
		avatar_selector.select(0)
		selected_avatar_index = 0
		_update_selected_avatar_display()
		
		create_button.disabled = false
		join_button.disabled = false

# ✅ NUEVO: Actualizar display del avatar seleccionado
func _update_selected_avatar_display():
	if selected_avatar_index >= 0 and selected_avatar_index < available_avatars.size():
		var avatar_name = available_avatars[selected_avatar_index]
		var avatar_info = AvatarManager.get_profile_info(avatar_name)
		
		var raza_name = ""
		var raza = ConfigLoader.get_raza(avatar_info.get("raza_id", ""))
		if not raza.is_empty():
			raza_name = raza["nombre"]
		
		var sexo_name = ""
		var sexo = ConfigLoader.get_sexo(avatar_info.get("sexo_id", ""))
		if not sexo.is_empty():
			sexo_name = sexo["nombre"]
		
		selected_avatar_label.text = "✓ Avatar: %s (%s %s)" % [avatar_name, raza_name, sexo_name]
		selected_avatar_label.modulate = Color(0.31, 0.78, 0.47)
	else:
		selected_avatar_label.text = "Sin avatar seleccionado"
		selected_avatar_label.modulate = Color(0.69, 0.69, 0.76)

# ✅ NUEVO: Evento cuando se selecciona un avatar
func _on_avatar_selected(index: int):
	selected_avatar_index = index
	_update_selected_avatar_display()

# ✅ NUEVO: Ir al creador de avatares
func _on_create_avatar_pressed():
	get_tree().change_scene_to_file("res://scenes/avatar_creator.tscn")

func _on_create_pressed():
	# ✅ MEJORADO: Verificar que hay avatar seleccionado
	if selected_avatar_index < 0 or available_avatars.is_empty():
		_update_status("Debes seleccionar un avatar", Color(0.96, 0.64, 0.14))
		return
	
	_update_status("Cargando avatar...", Color(0.69, 0.69, 0.76))
	create_button.disabled = true
	
	# Cargar el avatar seleccionado
	var avatar_name = available_avatars[selected_avatar_index]
	var avatar: AvatarData = AvatarManager.load_profile(avatar_name)
	
	if not avatar:
		_update_status("Error al cargar avatar", Color(0.91, 0.3, 0.24))
		create_button.disabled = false
		return
	
	AvatarManager.set_current_avatar(avatar)
	
	# Crear sala
	_update_status("Creando sala...", Color(0.35, 0.56, 0.89))
	var code = NetworkManager.create_room(avatar.nombre, avatar.to_dict())
	
	if code == "":
		_update_status("Error al crear sala", Color(0.91, 0.3, 0.24))
		create_button.disabled = false
	# ✅ NO auto-entrar, mostrar código primero

func _on_join_pressed():
	var code = code_input.text.strip_edges().to_upper()
	
	# Validar código
	if code.is_empty():
		_update_status("Ingresa un código de sala", Color(0.96, 0.64, 0.14))
		code_input.grab_focus()
		return
	
	if code.length() != 8:
		_update_status("El código debe tener 8 caracteres", Color(0.91, 0.3, 0.24))
		code_input.grab_focus()
		return
	
	# ✅ MEJORADO: Verificar avatar seleccionado
	if selected_avatar_index < 0 or available_avatars.is_empty():
		_update_status("Debes seleccionar un avatar", Color(0.96, 0.64, 0.14))
		return
	
	_update_status("Cargando avatar...", Color(0.69, 0.69, 0.76))
	join_button.disabled = true
	
	# Cargar avatar seleccionado
	var avatar_name = available_avatars[selected_avatar_index]
	var avatar: AvatarData = AvatarManager.load_profile(avatar_name)
	
	if not avatar:
		_update_status("Error al cargar avatar", Color(0.91, 0.3, 0.24))
		join_button.disabled = false
		return
	
	AvatarManager.set_current_avatar(avatar)
	
	# Intentar unirse a la sala
	_update_status("Conectando a sala " + code + "...", Color(0.35, 0.56, 0.89))
	NetworkManager.join_room(code, avatar.nombre, avatar.to_dict())

func _on_quit_pressed():
	_update_status("Cerrando...", Color(0.69, 0.69, 0.76))
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()

# Callbacks de NetworkManager
func _on_room_created(code: String):
	# ✅ MEJORADO: No auto-entrar, dejar que el usuario copie el código
	_update_status("Sala creada: " + code, Color(0.31, 0.78, 0.47))
	
	# ✅ NUEVO: Mostrar botón para entrar
	create_button.text = "▶ Entrar al Lobby"
	create_button.disabled = false
	
	# Cambiar la funcionalidad del botón
	create_button.pressed.disconnect(_on_create_pressed)
	create_button.pressed.connect(_on_enter_lobby)

func _on_enter_lobby():
	_update_status("Entrando al lobby...", Color(0.35, 0.56, 0.89))
	create_button.disabled = true
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_connection_successful():
	_update_status("Conexión exitosa", Color(0.31, 0.78, 0.47))
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_connection_failed(reason: String):
	_update_status("Error: " + reason, Color(0.91, 0.3, 0.24))
	create_button.disabled = false
	join_button.disabled = false

# Función helper para actualizar el status
func _update_status(text: String, color: Color = Color.WHITE):
	status_label.text = text
	status_label.modulate = color
	print("[MainMenu] ", text)
