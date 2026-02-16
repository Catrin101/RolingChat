extends ColorRect

@onready var texture_rect = $TextureRect
@onready var action_label = $Label

var image_loader = ImageLoader.new()

func show_scene(accion: Dictionary):
	action_label.text = accion["nombre"]
	var url = accion["imagen_url"]
	_load_image(url)
	# Mostrar (ya visible)

func _load_image(url: String):
	if url.begins_with("res://") or url.begins_with("user://"):
		var img = Image.load_from_file(url)
		if img:
			texture_rect.texture = ImageTexture.create_from_image(img)
	else:
		image_loader.load_http(url, func(texture): texture_rect.texture = texture)

func _on_despedirse_pressed():
	# Notificar al WorldController que termine la escena
	# Podría ser una señal o llamar a un método global
	queue_free()
