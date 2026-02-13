# scripts/ui/profile_card.gd
class_name ProfileCard
extends PanelContainer

## ProfileCard - Widget para mostrar un perfil de avatar
## Responsabilidad: Mostrar información del perfil con botones de acción
## Señales: selected, edited, deleted

# ===== SEÑALES =====

signal selected(profile_name: String)
signal edited(profile_name: String)
signal deleted(profile_name: String)

# ===== REFERENCIAS DE NODOS =====

@onready var name_label: Label = $MarginContainer/VBoxContainer/NameLabel
@onready var summary_label: Label = $MarginContainer/VBoxContainer/SummaryLabel
@onready var created_label: Label = $MarginContainer/VBoxContainer/CreatedLabel
@onready var buttons_container: HBoxContainer = $MarginContainer/VBoxContainer/ButtonsContainer

@onready var select_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/SelectButton
@onready var edit_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/EditButton
@onready var delete_button: Button = $MarginContainer/VBoxContainer/ButtonsContainer/DeleteButton

# ===== ESTADO =====

var profile_name: String = ""
var avatar_data: AvatarData = null

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Conectar señales de botones
	select_button.pressed.connect(_on_select_pressed)
	edit_button.pressed.connect(_on_edit_pressed)
	delete_button.pressed.connect(_on_delete_pressed)

# ===== API PÚBLICA =====

## Inicializa la card con datos de un perfil
func setup(p_profile_name: String, p_avatar_data: AvatarData) -> void:
	profile_name = p_profile_name
	avatar_data = p_avatar_data
	
	# Actualizar UI
	name_label.text = avatar_data.character_name
	summary_label.text = avatar_data.get_summary()
	
	# Formatear fecha de creación
	if not avatar_data.created_at.is_empty():
		var date_parts = avatar_data.created_at.split("T")
		if date_parts.size() > 0:
			created_label.text = "Creado: " + date_parts[0]
		else:
			created_label.text = "Creado: " + avatar_data.created_at
	else:
		created_label.text = "Creado: Desconocido"

## Marca este perfil como seleccionado
func set_selected(is_selected: bool) -> void:
	if is_selected:
		select_button.text = "✓ Seleccionado"
		select_button.disabled = true
		
		# Cambiar estilo del panel
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = Color(0.3, 0.5, 0.3, 0.5)
		stylebox.border_width_left = 3
		stylebox.border_width_right = 3
		stylebox.border_width_top = 3
		stylebox.border_width_bottom = 3
		stylebox.border_color = Color(0.4, 0.8, 0.4)
		add_theme_stylebox_override("panel", stylebox)
	else:
		select_button.text = "Seleccionar"
		select_button.disabled = false
		
		# Restablecer estilo
		remove_theme_stylebox_override("panel")

# ===== CALLBACKS =====

func _on_select_pressed() -> void:
	selected.emit(profile_name)

func _on_edit_pressed() -> void:
	edited.emit(profile_name)

func _on_delete_pressed() -> void:
	# Confirmar eliminación
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "¿Seguro que quieres eliminar el perfil '%s'?\nEsta acción no se puede deshacer." % avatar_data.character_name
	confirm.confirmed.connect(_delete_confirmed)
	add_child(confirm)
	confirm.popup_centered()

func _delete_confirmed() -> void:
	deleted.emit(profile_name)
