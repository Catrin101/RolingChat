extends Control

var acciones: Array = []
var otro_jugador_id: int
var callback: Callable

@onready var actions_container: VBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ActionsContainer
@onready var cancel_button: Button = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CancelButton

func _ready():
	cancel_button.pressed.connect(_on_cancel_pressed)

func setup(acciones_list: Array, other_id: int, on_selected: Callable):
	acciones = acciones_list
	otro_jugador_id = other_id
	callback = on_selected
	_populate()

func _populate():
	# Limpiar botones previos
	for child in actions_container.get_children():
		child.queue_free()
	
	# Crear un botón por cada acción
	for accion in acciones:
		var btn = Button.new()
		btn.text = accion["nombre"]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.pressed.connect(_on_action_selected.bind(accion))
		
		# Añadir tooltip con descripción si existe
		if accion.has("descripcion"):
			btn.tooltip_text = accion["descripcion"]
		
		actions_container.add_child(btn)
	
	print("[ActionSelector] Mostrando ", acciones.size(), " acciones disponibles")

func _on_action_selected(accion: Dictionary):
	print("[ActionSelector] Acción seleccionada: ", accion["nombre"])
	callback.call(accion, otro_jugador_id)
	queue_free()

func _on_cancel_pressed():
	print("[ActionSelector] Selección cancelada")
	queue_free()

# Cerrar con ESC
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
