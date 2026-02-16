extends Area2D
## Script para objetos interactivos en el mundo
## Emite señal cuando los jugadores están cerca y presionan E

signal interaction_requested(players: Array)

var nearby_players: Array[CharacterBody2D] = []  # ✅ Cambiado de RemoteAvatar a CharacterBody2D
var prompt_label: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Crear un label para mostrar "Presiona E"
	prompt_label = Label.new()
	prompt_label.text = "Presiona E"
	prompt_label.visible = false
	prompt_label.position = Vector2(0, -50)
	
	# Estilo del label
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt_label.add_theme_constant_override("outline_size", 2)
	
	add_child(prompt_label)
	
	# Debug
	print("[InteractiveObject] Objeto interactivo creado: ", name)

func _on_body_entered(body):
	# ✅ Verificar que es CharacterBody2D (clase base de los avatares)
	if body is CharacterBody2D:
		nearby_players.append(body)
		_update_prompt()
		print("[InteractiveObject] Jugador entró al área: ", body.name)

func _on_body_exited(body):
	if nearby_players.has(body):
		nearby_players.erase(body)
		_update_prompt()
		print("[InteractiveObject] Jugador salió del área: ", body.name)

func _update_prompt():
	prompt_label.visible = nearby_players.size() > 0
	
	# Actualizar texto según cantidad de jugadores
	if nearby_players.size() == 0:
		prompt_label.text = ""
	elif nearby_players.size() == 1:
		prompt_label.text = "Presiona E (espera otro jugador)"
	else:
		prompt_label.text = "Presiona E para interactuar"

func _input(event):
	if event.is_action_pressed("interact") and nearby_players.size() > 0:
		print("[InteractiveObject] Interacción solicitada con ", nearby_players.size(), " jugadores")
		interaction_requested.emit(nearby_players)
		# Consumir el evento para que no lo procesen otros objetos
		get_viewport().set_input_as_handled()
