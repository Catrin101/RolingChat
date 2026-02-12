# scripts/systems/chat/message_formatter.gd
class_name MessageFormatter
extends Node

## MessageFormatter - Formatea mensajes con BBCode
## Responsabilidad: Convertir comandos parseados en texto formateado
## Usa BBCode de Godot para colores y estilos

# ===== CONFIGURACIÓN DE COLORES =====

const COLOR_IC := "white"           # In Character
const COLOR_OOC := "gray"           # Out Of Character
const COLOR_ACTION := "orange"      # Acciones (/me)
const COLOR_ROLL := "lightgreen"    # Dados (/roll)
const COLOR_WHISPER := "pink"       # Susurros (/w)
const COLOR_SYSTEM := "yellow"      # Mensajes del sistema
const COLOR_ERROR := "red"          # Errores

# ===== API PÚBLICA =====

## Formatea un mensaje parseado a BBCode
func format(parsed: Dictionary) -> String:
	var msg_type = parsed.get("type", "ic")
	
	match msg_type:
		"ic":
			return _format_ic(parsed)
		"ooc":
			return _format_ooc(parsed)
		"action":
			return _format_action(parsed)
		"roll":
			return _format_roll(parsed)
		"whisper":
			return _format_whisper(parsed)
		"error":
			return _format_error(parsed)
		_:
			return _format_ic(parsed)

# ===== FORMATEADORES ESPECÍFICOS =====

func _format_ic(parsed: Dictionary) -> String:
	var sender = parsed.get("sender", "Desconocido")
	var text = parsed.get("text", "")
	
	return "[color=%s][b]%s:[/b] %s[/color]" % [COLOR_IC, sender, text]

func _format_ooc(parsed: Dictionary) -> String:
	var sender = parsed.get("sender", "Desconocido")
	var text = parsed.get("text", "")
	
	return "[color=%s](OOC) [b]%s:[/b] %s[/color]" % [COLOR_OOC, sender, text]

func _format_action(parsed: Dictionary) -> String:
	var sender = parsed.get("sender", "Desconocido")
	var text = parsed.get("text", "")
	
	return "[color=%s][i]* %s %s[/i][/color]" % [COLOR_ACTION, sender, text]

func _format_roll(parsed: Dictionary) -> String:
	var sender = parsed.get("sender", "Desconocido")
	var dice = parsed.get("dice", "?")
	var total = parsed.get("result", 0)
	var rolls = parsed.get("rolls", [])
	var modifier = parsed.get("modifier", 0)
	
	# Construir detalle de tiradas
	var detail = ""
	if rolls.size() > 0:
		var rolls_str = []
		for roll in rolls:
			rolls_str.append(str(roll))
		detail = " (%s)" % ", ".join(rolls_str)
		
		if modifier != 0:
			var mod_sign = "+" if modifier > 0 else ""
			detail += " %s%d" % [mod_sign, modifier]
	
	return "[color=%s]🎲 [b]%s[/b] tiró [b]%s[/b]: [b]%d[/b]%s[/color]" % [
		COLOR_ROLL, sender, dice, total, detail
	]

func _format_whisper(parsed: Dictionary) -> String:
	var sender = parsed.get("sender", "Desconocido")
	var target = parsed.get("target", "?")
	var text = parsed.get("text", "")
	
	# Verificar si somos el destinatario o el emisor
	var my_name = GameManager.current_avatar_data.character_name if GameManager.current_avatar_data else ""
	
	if my_name == sender:
		return "[color=%s][i]Susurras a [b]%s[/b]: %s[/i][/color]" % [COLOR_WHISPER, target, text]
	elif my_name == target:
		return "[color=%s][i][b]%s[/b] te susurra: %s[/i][/color]" % [COLOR_WHISPER, sender, text]
	else:
		# No deberías ver este mensaje si no eres parte
		return ""

func _format_error(parsed: Dictionary) -> String:
	var text = parsed.get("text", "Error desconocido")
	
	return "[color=%s][b][Error][/b] %s[/color]" % [COLOR_ERROR, text]

# ===== UTILIDADES =====

## Formatea un mensaje del sistema
func format_system_message(message: String) -> String:
	return "[color=%s][b][Sistema][/b] %s[/color]" % [COLOR_SYSTEM, message]

## Limpia BBCode de un texto (para exportar)
func strip_bbcode(text: String) -> String:
	var clean = text
	
	# Remover tags de color
	var regex = RegEx.new()
	regex.compile("\\[color=[^\\]]+\\]|\\[\\/color\\]")
	clean = regex.sub(clean, "", true)
	
	# Remover tags de formato
	clean = clean.replace("[b]", "").replace("[/b]", "")
	clean = clean.replace("[i]", "").replace("[/i]", "")
	clean = clean.replace("[u]", "").replace("[/u]", "")
	
	return clean

## Genera preview de un mensaje (primeras N palabras)
func get_preview(text: String, max_words: int = 10) -> String:
	var clean = strip_bbcode(text)
	var words = clean.split(" ")
	
	if words.size() <= max_words:
		return clean
	
	var preview_words = []
	for i in range(max_words):
		preview_words.append(words[i])
	
	return " ".join(preview_words) + "..."
