# scripts/systems/chat/chat_controller.gd
class_name ChatController
extends Control

## ChatController - Sistema principal de chat
## Responsabilidad: Gestionar mensajes, historial y UI del chat
## Dependencias: CommandParser, MessageFormatter, NetworkManager

# ===== CONSTANTES =====

const MAX_HISTORY := 100
const MESSAGE_COOLDOWN := 0.5  # 500ms entre mensajes

# ===== REFERENCIAS DE NODOS =====

@onready var chat_log: RichTextLabel = $Panel/VBoxContainer/ScrollContainer/ChatLog
@onready var input_field: LineEdit = $Panel/VBoxContainer/HBoxContainer/InputField
@onready var send_button: Button = $Panel/VBoxContainer/HBoxContainer/SendButton

# ===== COMPONENTES =====

var parser: CommandParser = null
var formatter: MessageFormatter = null

# ===== ESTADO =====

var history: Array[String] = []
var _last_message_time: float = 0.0

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Inicializar componentes
	parser = CommandParser.new()
	formatter = MessageFormatter.new()
	add_child(parser)
	add_child(formatter)
	
	# Conectar señales de UI
	input_field.text_submitted.connect(_on_text_submitted)
	send_button.pressed.connect(_on_send_pressed)
	
	# Conectar señales del EventBus
	EventBus.message_received.connect(_on_message_received)
	
	# Configurar chat log
	chat_log.bbcode_enabled = true
	chat_log.scroll_following = true
	
	# Mensaje de bienvenida
	_add_system_message("Chat de rol iniciado. Comandos disponibles: /me, /roll, //")
	
	print("[ChatController] Sistema de chat inicializado")

# ===== ENVÍO DE MENSAJES =====

func _on_send_pressed() -> void:
	_send_message()

func _on_text_submitted(text: String) -> void:
	_send_message()

func _send_message() -> void:
	var text = input_field.text.strip_edges()
	
	# Validar que no esté vacío
	if text.is_empty():
		return
	
	# Validar rate limit
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_message_time < MESSAGE_COOLDOWN:
		_add_system_message("Espera un momento antes de enviar otro mensaje")
		return
	
	_last_message_time = current_time
	
	# Enviar a través del NetworkManager
	NetworkManager.send_chat_message(text)
	
	# Limpiar input
	input_field.clear()
	input_field.grab_focus()

# ===== RECEPCIÓN DE MENSAJES =====

func _on_message_received(sender: String, text: String, msg_type: String) -> void:
	# Si es mensaje del sistema, mostrarlo directamente
	if msg_type == "system":
		_add_system_message(text)
		return
	
	# Parsear comando
	var parsed = parser.parse(text, sender)
	
	# Formatear mensaje
	var formatted = formatter.format(parsed)
	
	# Agregar al log
	_add_to_log(formatted)

# ===== GESTIÓN DEL LOG =====

func _add_to_log(message: String) -> void:
	# Agregar al historial
	history.append(message)
	
	# Limitar tamaño del historial
	if history.size() > MAX_HISTORY:
		history.pop_front()
		# Reconstruir chat log
		_rebuild_chat_log()
	else:
		# Simplemente agregar nuevo mensaje
		chat_log.append_text(message + "\n")

func _add_system_message(message: String) -> void:
	var formatted = "[color=yellow][b][Sistema][/b] %s[/color]" % message
	_add_to_log(formatted)

func _rebuild_chat_log() -> void:
	chat_log.clear()
	for msg in history:
		chat_log.append_text(msg + "\n")

# ===== UTILIDADES =====

## Limpia el historial de chat
func clear_chat() -> void:
	history.clear()
	chat_log.clear()
	_add_system_message("Chat limpiado")

## Exporta el historial como texto plano
func export_history() -> String:
	var result = ""
	for msg in history:
		# Remover BBCode para exportación
		var clean = msg.replace("[color=", "").replace("[/color]", "")
		clean = clean.replace("[b]", "").replace("[/b]", "")
		clean = clean.replace("[i]", "").replace("[/i]", "")
		result += clean + "\n"
	return result

## Guarda el historial en un archivo
func save_history_to_file(filepath: String) -> void:
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if file == null:
		push_error("[ChatController] No se pudo guardar historial")
		return
	
	file.store_string(export_history())
	file.close()
	
	_add_system_message("Historial guardado en: " + filepath)
