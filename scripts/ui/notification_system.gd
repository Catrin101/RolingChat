# scripts/ui/notification_system.gd
extends CanvasLayer

## NotificationSystem - Sistema de notificaciones visuales
## Responsabilidad: Mostrar mensajes temporales en pantalla
## Tipos: Info, Warning, Error, Success

# ===== CONFIGURACIÓN =====

const NOTIFICATION_DURATION := 3.0  # Segundos
const FADE_DURATION := 0.5

# ===== REFERENCIAS DE NODOS =====

@onready var notification_container: VBoxContainer = $NotificationContainer
@onready var notification_template: PackedScene = preload("res://scenes/ui/notification_system.tscn")

# ===== COLA DE NOTIFICACIONES =====

var active_notifications: Array[Control] = []
const MAX_NOTIFICATIONS := 5

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Conectar señales del EventBus
	EventBus.show_notification.connect(_on_show_notification)
	EventBus.show_error.connect(_on_show_error)
	
	print("[NotificationSystem] Sistema de notificaciones inicializado")

# ===== API PÚBLICA =====

## Muestra una notificación
func show_notification(message: String, type: String = "info") -> void:
	# Limitar notificaciones simultáneas
	if active_notifications.size() >= MAX_NOTIFICATIONS:
		_remove_oldest_notification()
	
	# Crear notificación
	var notification = _create_notification(message, type)
	notification_container.add_child(notification)
	active_notifications.append(notification)
	
	# Animar entrada
	notification.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 1.0, FADE_DURATION)
	
	# Programar eliminación
	await get_tree().create_timer(NOTIFICATION_DURATION).timeout
	_remove_notification(notification)

## Muestra una notificación de error
func show_error(message: String) -> void:
	show_notification(message, "error")

## Muestra una notificación de éxito
func show_success(message: String) -> void:
	show_notification(message, "success")

## Muestra una notificación de advertencia
func show_warning(message: String) -> void:
	show_notification(message, "warning")

# ===== MÉTODOS PRIVADOS =====

func _create_notification(message: String, type: String) -> Control:
	var notification = Panel.new()
	notification.custom_minimum_size = Vector2(300, 60)
	
	# Configurar estilo según tipo
	var stylebox = StyleBoxFlat.new()
	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5
	stylebox.content_margin_left = 10
	stylebox.content_margin_right = 10
	stylebox.content_margin_top = 10
	stylebox.content_margin_bottom = 10
	
	match type:
		"info":
			stylebox.bg_color = Color(0.2, 0.4, 0.6, 0.9)
		"success":
			stylebox.bg_color = Color(0.2, 0.6, 0.3, 0.9)
		"warning":
			stylebox.bg_color = Color(0.8, 0.6, 0.2, 0.9)
		"error":
			stylebox.bg_color = Color(0.8, 0.2, 0.2, 0.9)
	
	notification.add_theme_stylebox_override("panel", stylebox)
	
	# Agregar label con el mensaje
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	
	# Layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(label)
	
	notification.add_child(margin)
	
	return notification

func _remove_notification(notification: Control) -> void:
	if not is_instance_valid(notification):
		return
	
	# Animar salida
	var tween = create_tween()
	tween.tween_property(notification, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	
	# Eliminar
	if active_notifications.has(notification):
		active_notifications.erase(notification)
	
	if is_instance_valid(notification):
		notification.queue_free()

func _remove_oldest_notification() -> void:
	if active_notifications.size() > 0:
		var oldest = active_notifications[0]
		_remove_notification(oldest)

# ===== CALLBACKS DE EVENTBUS =====

func _on_show_notification(message: String, type: String) -> void:
	show_notification(message, type)

func _on_show_error(message: String) -> void:
	show_error(message)
