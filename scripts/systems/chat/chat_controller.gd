extends Control

# Referencias corregidas a nodos
@onready var chat_log: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/ChatLogScroll/ChatLog
@onready var input_field: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/InputContainer/InputField
@onready var send_button: Button = $PanelContainer/MarginContainer/VBoxContainer/InputContainer/SendButton
@onready var chat_scroll: ScrollContainer = $PanelContainer/MarginContainer/VBoxContainer/ChatLogScroll

var parser = CommandParser.new()
var formatter = MessageFormatter.new()
var history: Array[String] = []
const MAX_HISTORY = 100

func _ready():
	# ✅ CRÍTICO: Verificar que todos los nodos existen
	if not chat_log:
		push_error("[ChatController] ERROR: chat_log es null - verificar ruta del nodo")
		return
	
	if not input_field:
		push_error("[ChatController] ERROR: input_field es null")
		return
	
	if not send_button:
		push_error("[ChatController] ERROR: send_button es null")
		return
	
	if not chat_scroll:
		push_error("[ChatController] ERROR: chat_scroll es null")
		return
	
	# Conectar señales
	input_field.text_submitted.connect(_on_text_submitted)
	send_button.pressed.connect(_on_send_pressed)
	
	# Conectar señal de mensajes del NetworkManager
	NetworkManager.chat_message_received.connect(_on_chat_message_received)
	
	# Mensaje de bienvenida
	_add_system_message("Chat iniciado. Escribe '/?' para ver comandos disponibles.")
	
	print("[ChatController] Inicializado correctamente")

func _on_send_pressed():
	if not input_field:
		return
		
	var text = input_field.text.strip_edges()
	if text.is_empty():
		return
	
	# Comando de ayuda local
	if text == "/?":
		_show_help()
		input_field.clear()
		return
	
	# Enviar mensaje al NetworkManager para que lo distribuya
	NetworkManager.send_chat_message(text)
	input_field.clear()
	input_field.grab_focus()

func _on_text_submitted(text: String):
	_on_send_pressed()

func _on_chat_message_received(sender: String, text: String, _type: String):
	# Parsear y formatear el mensaje
	var parsed = parser.parse(text, sender)
	var formatted = formatter.format(parsed)
	_add_to_log(formatted)

func _add_to_log(message: String):
	# ✅ VERIFICACIÓN: Asegurar que chat_log existe
	if not chat_log:
		push_error("[ChatController] No se puede añadir mensaje: chat_log es null")
		return
	
	# Añadir al historial
	history.append(message)
	if history.size() > MAX_HISTORY:
		history.pop_front()
	
	# Añadir al RichTextLabel
	chat_log.append_text(message + "\n")
	
	# Hacer scroll automático al final
	if chat_scroll:
		await get_tree().process_frame
		chat_scroll.scroll_vertical = int(chat_scroll.get_v_scroll_bar().max_value)

func _add_system_message(text: String):
	var formatted = "[color=#888888][i]• " + text + "[/i][/color]"
	_add_to_log(formatted)

func _show_help():
	_add_system_message("=== COMANDOS DISPONIBLES ===")
	_add_system_message("/me [acción] - Realizar una acción narrativa")
	_add_system_message("//[texto] o /ooc [texto] - Hablar fuera de personaje")
	_add_system_message("/roll XdY - Tirar dados (ej: /roll 2d6)")
	_add_system_message("/? - Mostrar esta ayuda")
	_add_system_message("===========================")

# Métodos públicos para otros sistemas
func add_notification(text: String, color: String = "#F5A623"):
	# ✅ VERIFICACIÓN: Asegurar que chat_log existe antes de usar
	if not is_node_ready() or not chat_log:
		# Si el chat no está listo, esperar
		await ready
		if not chat_log:
			push_error("[ChatController] No se puede mostrar notificación: chat_log es null")
			return
	
	var formatted = "[color=" + color + "]📢 " + text + "[/color]"
	_add_to_log(formatted)

func clear_chat():
	if not chat_log:
		return
		
	chat_log.clear()
	history.clear()
	_add_system_message("Chat limpiado")
