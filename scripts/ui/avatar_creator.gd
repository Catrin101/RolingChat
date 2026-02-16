extends Control

# Referencias corregidas a los nodos de la escena
@onready var nombre_input: LineEdit = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ContentHBox/FormContainer/NombreContainer/NombreInput
@onready var desc_input: TextEdit = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ContentHBox/FormContainer/DescripcionContainer/DescripcionInput
@onready var imagen_option: OptionButton = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ContentHBox/FormContainer/ImagenContainer/HBoxContainer/ImagenOption
@onready var load_file_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ContentHBox/FormContainer/ImagenContainer/HBoxContainer/LoadFileButton
@onready var raza_option: OptionButton = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ContentHBox/FormContainer/AttributesContainer/RazaContainer/RazaOption
@onready var sexo_option: OptionButton = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ContentHBox/FormContainer/AttributesContainer/SexoContainer/SexoOption
@onready var preview: TextureRect = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ContentHBox/PreviewContainer/PreviewPanel/PreviewTexture
@onready var save_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/SaveButton
@onready var load_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/LoadButton
@onready var random_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/RandomButton
@onready var back_button: Button = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/ButtonsContainer/BackButton

# Imágenes predefinidas (asegúrate de tener estos archivos o usa placeholders)
var imagenes_predefinidas: Array[String] = [
	"res://assets/images/avatars/default1.png",
	"res://assets/images/avatars/default2.png",
	"res://assets/images/avatars/default3.png",
	"res://assets/images/avatars/default4.png"
]

# Placeholder para imágenes faltantes
const PLACEHOLDER_IMAGE = "res://icon.svg"

func _ready():
	# Poblar opciones de raza
	for raza in ConfigLoader.razas:
		raza_option.add_item(raza["nombre"])
		raza_option.set_item_metadata(raza_option.item_count - 1, raza["id"])
	
	# Poblar opciones de sexo
	for sexo in ConfigLoader.sexos:
		var display_name = sexo["nombre"] + " " + sexo.get("icono", "")
		sexo_option.add_item(display_name)
		sexo_option.set_item_metadata(sexo_option.item_count - 1, sexo["id"])
	
	# Poblar opciones de imágenes
	for i in range(imagenes_predefinidas.size()):
		imagen_option.add_item("Avatar " + str(i + 1))
		imagen_option.set_item_metadata(i, imagenes_predefinidas[i])
	
	# Conectar señales de cambio para actualizar preview en tiempo real
	imagen_option.item_selected.connect(_on_selection_changed)
	raza_option.item_selected.connect(_on_selection_changed)
	sexo_option.item_selected.connect(_on_selection_changed)
	nombre_input.text_changed.connect(func(_text): _validate_form())
	
	# Conectar botones
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	random_button.pressed.connect(_on_random_pressed)
	back_button.pressed.connect(_on_back_pressed)
	load_file_button.pressed.connect(_on_load_file_pressed)
	
	# Inicializar preview
	_update_preview()
	_validate_form()

func _on_selection_changed(_idx: int = 0):
	_update_preview()
	_validate_form()

func _update_preview(_idx: int = 0):
	var img_path = imagen_option.get_item_metadata(imagen_option.selected)
	
	# Intentar cargar la imagen
	if FileAccess.file_exists(img_path):
		var image = Image.load_from_file(img_path)
		if image:
			var texture = ImageTexture.create_from_image(image)
			preview.texture = texture
			return
	
	# Si falla, usar placeholder
	if FileAccess.file_exists(PLACEHOLDER_IMAGE):
		var image = Image.load_from_file(PLACEHOLDER_IMAGE)
		if image:
			var texture = ImageTexture.create_from_image(image)
			preview.texture = texture

func _validate_form() -> bool:
	var is_valid = not nombre_input.text.strip_edges().is_empty()
	save_button.disabled = not is_valid
	return is_valid

func _on_save_pressed():
	if not _validate_form():
		push_error("Nombre del avatar vacío")
		return
	
	# Crear datos del avatar
	var avatar = AvatarData.new()
	avatar.nombre = nombre_input.text.strip_edges()
	avatar.descripcion = desc_input.text.strip_edges()
	avatar.imagen_url = imagen_option.get_item_metadata(imagen_option.selected)
	avatar.raza_id = raza_option.get_item_metadata(raza_option.selected)
	avatar.sexo_id = sexo_option.get_item_metadata(sexo_option.selected)
	
	# Guardar perfil
	var success = AvatarManager.save_profile(avatar, avatar.nombre)
	
	if success:
		print("[AvatarCreator] Avatar guardado: ", avatar.nombre)
		# Volver al menú con un pequeño delay para feedback visual
		save_button.text = "✓ Guardado!"
		save_button.disabled = true
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		push_error("[AvatarCreator] Error al guardar avatar")
		save_button.text = "✗ Error al guardar"
		await get_tree().create_timer(1.0).timeout
		save_button.text = "💾 Guardar"

func _on_load_pressed():
	# Crear diálogo de selección de archivos
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_USERDATA
	dialog.add_filter("*.json", "Avatar Files")
	dialog.title = "Cargar Avatar"
	
	dialog.file_selected.connect(func(path: String):
		var file = FileAccess.open(path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var data = JSON.parse_string(json_text)
			
			if data:
				var avatar = AvatarData.from_dict(data)
				_load_avatar_to_ui(avatar)
				print("[AvatarCreator] Avatar cargado: ", avatar.nombre)
			else:
				push_error("[AvatarCreator] JSON inválido")
		else:
			push_error("[AvatarCreator] No se pudo abrir archivo")
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func(): dialog.queue_free())
	
	add_child(dialog)
	dialog.popup_centered(Vector2i(800, 600))

func _load_avatar_to_ui(avatar: AvatarData):
	# Rellenar campos
	nombre_input.text = avatar.nombre
	desc_input.text = avatar.descripcion
	
	# Buscar índice de la imagen
	for i in range(imagen_option.item_count):
		if imagen_option.get_item_metadata(i) == avatar.imagen_url:
			imagen_option.select(i)
			break
	
	# Buscar índice de raza
	for i in range(raza_option.item_count):
		if raza_option.get_item_metadata(i) == avatar.raza_id:
			raza_option.select(i)
			break
	
	# Buscar índice de sexo
	for i in range(sexo_option.item_count):
		if sexo_option.get_item_metadata(i) == avatar.sexo_id:
			sexo_option.select(i)
			break
	
	_update_preview()
	_validate_form()

func _on_random_pressed():
	# Seleccionar valores aleatorios
	imagen_option.select(randi() % imagen_option.item_count)
	raza_option.select(randi() % raza_option.item_count)
	sexo_option.select(randi() % sexo_option.item_count)
	
	# Nombre aleatorio
	var nombres = ["Aria", "Thorin", "Luna", "Drax", "Selene", "Kael", "Nyx", "Zara"]
	var apellidos = ["Noctis", "Fireborn", "Stormwind", "Shadowbane", "Lightbringer", "Ironheart"]
	nombre_input.text = nombres[randi() % nombres.size()] + " " + apellidos[randi() % apellidos.size()]
	
	# Descripción aleatoria
	desc_input.text = "Un aventurero misterioso con un pasado oscuro..."
	
	_update_preview()
	_validate_form()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_load_file_pressed():
	# Implementar carga de imagen externa (opcional)
	push_warning("[AvatarCreator] Carga de archivos externos no implementada en MVP")
