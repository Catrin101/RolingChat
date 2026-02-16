extends Control

# Referencias a nodos UI corregidas
@onready var create_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/CreateRoomButton
@onready var join_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/JoinContainer/JoinHBox/JoinButton
@onready var code_input: LineEdit = $CenterContainer/VBoxContainer/ButtonsContainer/JoinContainer/JoinHBox/CodeInput
@onready var quit_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/QuitButton
@onready var status_label: Label = $StatusPanel/MarginContainer/StatusLabel

func _ready():
	# Conectar señales de botones
	create_button.pressed.connect(_on_create_pressed)
	join_button.pressed.connect(_on_join_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Conectar señal de enter en el LineEdit
	code_input.text_submitted.connect(func(_text): _on_join_pressed())
	
	# Conectar señales del NetworkManager
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.connection_successful.connect(_on_connection_successful)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	
	# Inicializar UI
	_update_status("Listo para jugar", Color.WHITE)

func _on_create_pressed():
	_update_status("Verificando avatares...", Color(0.69, 0.69, 0.76))
	create_button.disabled = true
	
	# ✅ CORRECCIÓN: Obtener array tipado correctamente
	var avatars: Array[String] = AvatarManager.list_profiles()
	
	if avatars.is_empty():
		_update_status("Primero debes crear un avatar", Color(0.96, 0.64, 0.14))
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/avatar_creator.tscn")
		return
	
	# Cargar el primer avatar
	var avatar: AvatarData = AvatarManager.load_profile(avatars[0])
	
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
	else:
		_update_status("Sala creada: " + code, Color(0.31, 0.78, 0.47))

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
	
	_update_status("Verificando avatares...", Color(0.69, 0.69, 0.76))
	join_button.disabled = true
	
	# ✅ CORRECCIÓN: Obtener array tipado correctamente
	var avatars: Array[String] = AvatarManager.list_profiles()
	
	if avatars.is_empty():
		_update_status("Primero debes crear un avatar", Color(0.96, 0.64, 0.14))
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/avatar_creator.tscn")
		return
	
	# Cargar avatar
	var avatar: AvatarData = AvatarManager.load_profile(avatars[0])
	
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
	_update_status("Sala creada: " + code, Color(0.31, 0.78, 0.47))
	await get_tree().create_timer(1.5).timeout
	_update_status("Entrando al lobby...", Color(0.35, 0.56, 0.89))
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
