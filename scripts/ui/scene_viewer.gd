extends ColorRect

@onready var texture_rect: TextureRect = $CenterContainer/VBoxContainer/ImagePanel/ImageTexture
@onready var action_label: Label = $CenterContainer/VBoxContainer/ActionNameLabel
@onready var dismiss_button: Button = $CenterContainer/VBoxContainer/ButtonsContainer/DismissButton

var image_loader = ImageLoader.new()

func _ready():
	dismiss_button.pressed.connect(_on_dismiss_pressed)

func show_scene(accion: Dictionary):
	print("[SceneViewer] Mostrando escena: ", accion["nombre"])
	action_label.text = accion["nombre"]
	var url = accion["imagen_url"]
	_load_image(url)

func _load_image(url: String):
	if url.begins_with("res://") or url.begins_with("user://"):
		# Cargar imagen local
		if FileAccess.file_exists(url):
			var img = Image.load_from_file(url)
			if img:
				var texture = ImageTexture.create_from_image(img)
				texture_rect.texture = texture
				return
		
		# Si no existe, usar placeholder
		_load_placeholder()
	else:
		# Cargar desde HTTP
		image_loader.load_http(url, func(texture): 
			if texture:
				texture_rect.texture = texture
			else:
				_load_placeholder()
		)

func _load_placeholder():
	# Usar icono del proyecto como placeholder
	if FileAccess.file_exists("res://icon.svg"):
		var img = Image.load_from_file("res://icon.svg")
		if img:
			var texture = ImageTexture.create_from_image(img)
			texture_rect.texture = texture

func _on_dismiss_pressed():
	print("[SceneViewer] Escena cerrada")
	queue_free()

# Cerrar con ESC
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_dismiss_pressed()
		get_viewport().set_input_as_handled()
