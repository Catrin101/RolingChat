extends Control

@onready var nombre_input = $Panel/VBoxContainer/LineEdit
@onready var desc_input = $Panel/VBoxContainer/TextEdit
@onready var imagen_option = $Panel/VBoxContainer/HBoxContainer/OptionButton
@onready var raza_option = $Panel/VBoxContainer/HBoxContainer/Raza
@onready var sexo_option = $Panel/VBoxContainer/HBoxContainer/Sexo
@onready var preview = $Panel/VBoxContainer/TextureRect

var imagenes_predefinidas = [
	"res://assets/images/avatars/default1.png",
	"res://assets/images/avatars/default2.png",
	"res://assets/images/avatars/default3.png",
	"res://assets/images/avatars/default4.png"
]

func _ready():
	# Poblar opciones de raza
	for raza in ConfigLoader.razas:
		raza_option.add_item(raza["nombre"], raza["id"])
	# Poblar sexo
	for sexo in ConfigLoader.sexos:
		sexo_option.add_item(sexo["nombre"] + " " + sexo.get("icono", ""), sexo["id"])
	# Poblar imágenes
	for i in range(imagenes_predefinidas.size()):
		imagen_option.add_item("Imagen " + str(i+1), i)
	
	# Conectar cambios para preview
	imagen_option.item_selected.connect(_update_preview)
	raza_option.item_selected.connect(_update_preview)
	sexo_option.item_selected.connect(_update_preview)
	
	# Botones
	$Panel/VBoxContainer/HBoxContainer2/Guardar.pressed.connect(_on_save)
	$Panel/VBoxContainer/HBoxContainer2/Cargar.pressed.connect(_on_load)
	$Panel/VBoxContainer/HBoxContainer2/Aleatorio.pressed.connect(_on_random)
	$Panel/VBoxContainer/HBoxContainer2/Volver.pressed.connect(_on_back)
	
	# Preview inicial
	_update_preview()

func _update_preview(idx = 0):
	# Cargar la imagen seleccionada
	var img_path = imagenes_predefinidas[imagen_option.selected]
	var image = Image.load_from_file(img_path)
	if image:
		var texture = ImageTexture.create_from_image(image)
		preview.texture = texture

func _on_save():
	var avatar = AvatarData.new()
	avatar.nombre = nombre_input.text
	avatar.descripcion = desc_input.text
	avatar.imagen_url = imagenes_predefinidas[imagen_option.selected]
	avatar.raza_id = raza_option.get_item_id(raza_option.selected)
	avatar.sexo_id = sexo_option.get_item_id(sexo_option.selected)
	
	if avatar.nombre.is_empty():
		# Mostrar error
		return
	
	# Guardar
	AvatarManager.save_profile(avatar, avatar.nombre)
	# Volver al menú
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_load():
	# Abrir diálogo de archivo para cargar JSON
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_USERDATA
	dialog.add_filter("*.json", "Avatar files")
	dialog.file_selected.connect(func(path):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var data = JSON.parse_string(file.get_as_text())
			var avatar = AvatarData.from_dict(data)
			# Rellenar campos
			nombre_input.text = avatar.nombre
			desc_input.text = avatar.descripcion
			# Buscar índice de la imagen
			var img_idx = imagenes_predefinidas.find(avatar.imagen_url)
			if img_idx >= 0:
				imagen_option.select(img_idx)
			# Buscar índices de raza y sexo
			var raza_idx = 0
			for i in range(raza_option.item_count):
				if raza_option.get_item_id(i) == avatar.raza_id:
					raza_idx = i
					break
			raza_option.select(raza_idx)
			var sexo_idx = 0
			for i in range(sexo_option.item_count):
				if sexo_option.get_item_id(i) == avatar.sexo_id:
					sexo_idx = i
					break
			sexo_option.select(sexo_idx)
			_update_preview()
	)
	add_child(dialog)
	dialog.popup_centered()

func _on_random():
	# Seleccionar valores aleatorios
	imagen_option.select(randi() % imagen_option.item_count)
	raza_option.select(randi() % raza_option.item_count)
	sexo_option.select(randi() % sexo_option.item_count)
	# Nombre aleatorio (opcional)
	nombre_input.text = "Aventurer@" + str(randi() % 1000)
	desc_input.text = "Un personaje misterioso..."
	_update_preview()

func _on_back():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
