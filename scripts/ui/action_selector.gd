extends Control

var acciones: Array = []
var otro_jugador_id: int
var callback: Callable

func setup(acciones_list: Array, other_id: int, on_selected: Callable):
	acciones = acciones_list
	otro_jugador_id = other_id
	callback = on_selected
	_populate()

func _populate():
	var vbox = $Panel/VBoxContainer
	# Limpiar botones previos (excepto Cancelar)
	for child in vbox.get_children():
		if child is Button and child.text != "Cancelar":
			child.queue_free()
	
	for accion in acciones:
		var btn = Button.new()
		btn.text = accion["nombre"]
		btn.pressed.connect(_on_action_selected.bind(accion))
		vbox.add_child(btn)
		vbox.move_child(btn, vbox.get_child_count() - 2)  # justo antes de Cancelar

func _on_action_selected(accion):
	callback.call(accion, otro_jugador_id)
	queue_free()

func _on_cancel_pressed():
	queue_free()
