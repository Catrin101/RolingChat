# scripts/ui/avatar_creator_controller.gd
extends Control

## AvatarCreatorController - UI del creador de avatares
## Responsabilidad: Gestionar la interfaz de creación/edición de avatares
## Patrón: MVC Controller

# ===== REFERENCIAS DE NODOS =====

@onready var avatar_preview: Node2D = $PreviewPanel/AvatarPreview
@onready var view_toggle_button: Button = $PreviewPanel/ViewToggleButton

# Información básica
@onready var name_input: LineEdit = $RightPanel/VBoxContainer/BasicInfo/NameInput
@onready var backstory_input: TextEdit = $RightPanel/VBoxContainer/BasicInfo/BackstoryInput

# Controles Isométrico
@onready var iso_panel: Control = $RightPanel/VBoxContainer/IsometricPanel
@onready var iso_body_spin: SpinBox = $RightPanel/VBoxContainer/IsometricPanel/BodySpinBox
@onready var iso_hair_spin: SpinBox = $RightPanel/VBoxContainer/IsometricPanel/HairSpinBox
@onready var iso_outfit_spin: SpinBox = $RightPanel/VBoxContainer/IsometricPanel/OutfitSpinBox

# Controles Sideview
@onready var side_panel: Control = $RightPanel/VBoxContainer/SideviewPanel
@onready var side_head_spin: SpinBox = $RightPanel/VBoxContainer/SideviewPanel/HeadSpinBox
@onready var side_torso_spin: SpinBox = $RightPanel/VBoxContainer/SideviewPanel/TorsoSpinBox
@onready var side_legs_spin: SpinBox = $RightPanel/VBoxContainer/SideviewPanel/LegsSpinBox
@onready var side_hair_spin: SpinBox = $RightPanel/VBoxContainer/SideviewPanel/HairSpinBox

# Botones de acción
@onready var randomize_button: Button = $RightPanel/VBoxContainer/Actions/RandomizeButton
@onready var save_button: Button = $RightPanel/VBoxContainer/Actions/SaveButton
@onready var cancel_button: Button = $RightPanel/VBoxContainer/Actions/CancelButton

# ===== COMPONENTES =====

var avatar_builder: AvatarBuilder = null
var current_avatar_data: AvatarData = null
var current_view: String = "isometric"

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Inicializar avatar builder
	avatar_builder = AvatarBuilder.new()
	avatar_builder.view_type = current_view
	avatar_preview.add_child(avatar_builder)
	
	# Conectar señales
	view_toggle_button.pressed.connect(_on_view_toggle_pressed)
	randomize_button.pressed.connect(_on_randomize_pressed)
	save_button.pressed.connect(_on_save_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Conectar spinboxes
	iso_body_spin.value_changed.connect(_on_iso_body_changed)
	iso_hair_spin.value_changed.connect(_on_iso_hair_changed)
	iso_outfit_spin.value_changed.connect(_on_iso_outfit_changed)
	
	side_head_spin.value_changed.connect(_on_side_head_changed)
	side_torso_spin.value_changed.connect(_on_side_torso_changed)
	side_legs_spin.value_changed.connect(_on_side_legs_changed)
	side_hair_spin.value_changed.connect(_on_side_hair_changed)
	
	# Conectar inputs de texto
	name_input.text_changed.connect(_on_name_changed)
	backstory_input.text_changed.connect(_on_backstory_changed)
	
	# Inicializar avatar por defecto
	_initialize_default_avatar()
	
	# Actualizar visibilidad de paneles
	_update_panel_visibility()
	
	print("[AvatarCreator] Creador de avatares inicializado")

# ===== INICIALIZACIÓN =====

func _initialize_default_avatar() -> void:
	current_avatar_data = AvatarData.new()
	current_avatar_data.initialize_defaults()
	
	# Actualizar UI desde datos
	_update_ui_from_data()
	
	# Construir preview
	avatar_builder.build_from_data(current_avatar_data)

func _initialize_from_existing(avatar_data: AvatarData) -> void:
	current_avatar_data = avatar_data.duplicate_avatar()
	
	_update_ui_from_data()
	avatar_builder.build_from_data(current_avatar_data)

# ===== ACTUALIZACIÓN DE UI =====

func _update_ui_from_data() -> void:
	# Información básica
	name_input.text = current_avatar_data.character_name
	backstory_input.text = current_avatar_data.backstory
	
	# Isométrico
	iso_body_spin.value = current_avatar_data.iso_body_id
	iso_hair_spin.value = current_avatar_data.iso_hair_id
	iso_outfit_spin.value = current_avatar_data.iso_outfit_id
	
	# Sideview
	side_head_spin.value = current_avatar_data.side_head_id
	side_torso_spin.value = current_avatar_data.side_torso_id
	side_legs_spin.value = current_avatar_data.side_legs_id
	side_hair_spin.value = current_avatar_data.side_hair_id

func _update_panel_visibility() -> void:
	iso_panel.visible = (current_view == "isometric")
	side_panel.visible = (current_view == "sideview")
	
	view_toggle_button.text = "Vista: " + ("Isométrica" if current_view == "isometric" else "Lateral")

# ===== CALLBACKS - VISTA =====

func _on_view_toggle_pressed() -> void:
	# Alternar vista
	current_view = "sideview" if current_view == "isometric" else "isometric"
	
	# Actualizar builder
	avatar_builder.set_view_type(current_view)
	
	# Actualizar UI
	_update_panel_visibility()

# ===== CALLBACKS - ISOMÉTRICO =====

func _on_iso_body_changed(value: float) -> void:
	current_avatar_data.iso_body_id = int(value)
	avatar_builder.rebuild()

func _on_iso_hair_changed(value: float) -> void:
	current_avatar_data.iso_hair_id = int(value)
	avatar_builder.rebuild()

func _on_iso_outfit_changed(value: float) -> void:
	current_avatar_data.iso_outfit_id = int(value)
	avatar_builder.rebuild()

# ===== CALLBACKS - SIDEVIEW =====

func _on_side_head_changed(value: float) -> void:
	current_avatar_data.side_head_id = int(value)
	avatar_builder.rebuild()

func _on_side_torso_changed(value: float) -> void:
	current_avatar_data.side_torso_id = int(value)
	avatar_builder.rebuild()

func _on_side_legs_changed(value: float) -> void:
	current_avatar_data.side_legs_id = int(value)
	avatar_builder.rebuild()

func _on_side_hair_changed(value: float) -> void:
	current_avatar_data.side_hair_id = int(value)
	avatar_builder.rebuild()

# ===== CALLBACKS - INFORMACIÓN =====

func _on_name_changed(new_text: String) -> void:
	current_avatar_data.character_name = new_text

func _on_backstory_changed() -> void:
	current_avatar_data.backstory = backstory_input.text

# ===== CALLBACKS - ACCIONES =====

func _on_randomize_pressed() -> void:
	current_avatar_data.randomize_avatar()
	_update_ui_from_data()
	avatar_builder.rebuild()
	
	print("[AvatarCreator] Avatar aleatorizado")

func _on_save_pressed() -> void:
	# Validar
	if current_avatar_data.character_name.strip_edges().is_empty():
		EventBus.show_error.emit("El nombre del personaje no puede estar vacío")
		return
	
	# Guardar perfil
	if not ProfileManager.save_profile(current_avatar_data, current_avatar_data.character_name):
		EventBus.show_error.emit("Error al guardar el perfil")
		return
	
	# Establecer como avatar actual
	GameManager.set_current_avatar(current_avatar_data)
	
	# Notificar
	EventBus.show_success.emit("Perfil guardado: " + current_avatar_data.character_name)
	
	# Volver al menú principal
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

func _on_cancel_pressed() -> void:
	# Volver al menú sin guardar
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")

# ===== API PÚBLICA =====

## Carga un perfil existente para edición
func load_profile_for_editing(profile_name: String) -> void:
	var avatar_data = ProfileManager.load_profile(profile_name)
	
	if avatar_data == null:
		EventBus.show_error.emit("No se pudo cargar el perfil: " + profile_name)
		return
	
	_initialize_from_existing(avatar_data)
	print("[AvatarCreator] Perfil cargado para edición: %s" % profile_name)
