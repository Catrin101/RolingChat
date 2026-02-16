extends Control

@onready var chat_log: RichTextLabel = $ChatLog
@onready var input_field: LineEdit = $InputField
@onready var send_button: Button = $SendButton

var parser = CommandParser.new()
var formatter = MessageFormatter.new()
var history: Array[String] = []
const MAX_HISTORY = 100

func _ready():
	input_field.text_submitted.connect(_on_text_submitted)
	send_button.pressed.connect(_on_send_pressed)
	NetworkManager.chat_message_received.connect(_on_chat_message_received)

func _on_send_pressed():
	var text = input_field.text.strip_edges()
	if text.is_empty():
		return
	NetworkManager.send_chat_message(text)
	input_field.clear()

func _on_text_submitted(text: String):
	_on_send_pressed()

func _on_chat_message_received(sender: String, text: String, _type: String):
	var parsed = parser.parse(text, sender)
	var formatted = formatter.format(parsed)
	_add_to_log(formatted)

func _add_to_log(message: String):
	history.append(message)
	if history.size() > MAX_HISTORY:
		history.pop_front()
	chat_log.append_text(message + "\n")
	chat_log.scroll_to_line(chat_log.get_line_count() - 1)
