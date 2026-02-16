extends Area2D

signal interaction_requested(players: Array)

var nearby_players: Array[RemoteAvatar] = []
var prompt_label: Label

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	# Crear un label para mostrar "Presiona E"
	prompt_label = Label.new()
	prompt_label.text = "Presiona E"
	prompt_label.visible = false
	prompt_label.position = Vector2(0, -50)
	add_child(prompt_label)

func _on_body_entered(body):
	if body is RemoteAvatar:
		nearby_players.append(body)
		_update_prompt()

func _on_body_exited(body):
	nearby_players.erase(body)
	_update_prompt()

func _update_prompt():
	prompt_label.visible = nearby_players.size() > 0

func _input(event):
	if event.is_action_pressed("interact") and nearby_players.size() > 0:
		interaction_requested.emit(nearby_players)
