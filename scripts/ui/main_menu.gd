extends Control

@onready var create_button = $VBoxContainer/CrearSala
@onready var join_button = $VBoxContainer/HBoxContainer/Unirse
@onready var code_input = $VBoxContainer/HBoxContainer/LineEdit
@onready var status_label = $Panel/Label  # si tienes panel

func _ready():
	# Conectar señales
	create_button.pressed.connect(_on_create_pressed)
	join_button.pressed.connect(_on_join_pressed)
	$VBoxContainer/Salir.pressed.connect(_on_quit_pressed)
	
	# Conectar señales de red
	NetworkManager.room_created.connect(_on_room_created)
	NetworkManager.connection_successful.connect(_on_connection_successful)
	NetworkManager.connection_failed.connect(_on_connection_failed)

func _on_create_pressed():
	# Aquí deberías asegurarte de que el jugador tiene un avatar seleccionado
	# Para simplificar, cargamos el primer avatar disponible o uno por defecto
	var avatars = AvatarManager.list_profiles()
	if avatars.is_empty():
		# Si no hay avatares, ir al creador
		get_tree().change_scene_to_file("res://scenes/avatar_creator.tscn")
		return
	# Tomamos el primer avatar como ejemplo (en un juego real deberías elegir uno)
	var avatar = AvatarManager.load_profile(avatars[0])
	AvatarManager.set_current_avatar(avatar)
	
	# Crear sala
	var code = NetworkManager.create_room(avatar.nombre, avatar.to_dict())
	if code != "":
		status_label.text = "Sala creada. Código: " + code

func _on_join_pressed():
	var code = code_input.text.strip_edges()
	if code.is_empty():
		status_label.text = "Ingresa un código"
		return
	# Verificar que hay avatar seleccionado (similar a crear)
	var avatars = AvatarManager.list_profiles()
	if avatars.is_empty():
		get_tree().change_scene_to_file("res://scenes/avatar_creator.tscn")
		return
	var avatar = AvatarManager.load_profile(avatars[0])
	AvatarManager.set_current_avatar(avatar)
	
	NetworkManager.join_room(code, avatar.nombre, avatar.to_dict())

func _on_quit_pressed():
	get_tree().quit()

func _on_room_created(code: String):
	status_label.text = "Código: " + code
	# Esperar a que alguien se una? Por ahora pasamos al lobby directamente
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_connection_successful():
	get_tree().change_scene_to_file("res://scenes/lobby.tscn")

func _on_connection_failed(reason: String):
	status_label.text = "Error: " + reason
