# scripts/systems/chat/command_parser.gd
class_name CommandParser
extends Node

## CommandParser - Parser de comandos de chat de roleplay
## Responsabilidad: Convertir texto en comandos estructurados
## Comandos soportados: (normal), /me, /roll, //ooc, /ooc

# ===== API PÚBLICA =====

## Parsea un mensaje y retorna un diccionario con el tipo y datos
func parse(text: String, sender: String) -> Dictionary:
	text = text.strip_edges()
	
	# Comando: OOC (Out Of Character)
	if text.begins_with("//") or text.begins_with("/ooc "):
		return _parse_ooc(text, sender)
	
	# Comando: Acción (/me)
	elif text.begins_with("/me "):
		return _parse_action(text, sender)
	
	# Comando: Dado (/roll)
	elif text.begins_with("/roll "):
		return _parse_roll(text, sender)
	
	# Comando: Susurro (/w) - Para futuro
	elif text.begins_with("/w "):
		return _parse_whisper(text, sender)
	
	# Mensaje normal (IC - In Character)
	else:
		return _parse_ic(text, sender)

# ===== PARSERS ESPECÍFICOS =====

func _parse_ic(text: String, sender: String) -> Dictionary:
	return {
		"type": "ic",
		"sender": sender,
		"text": text
	}

func _parse_ooc(text: String, sender: String) -> Dictionary:
	var content = text
	
	# Remover prefijos
	if content.begins_with("//"):
		content = content.trim_prefix("//").strip_edges()
	elif content.begins_with("/ooc "):
		content = content.trim_prefix("/ooc ").strip_edges()
	
	return {
		"type": "ooc",
		"sender": sender,
		"text": content
	}

func _parse_action(text: String, sender: String) -> Dictionary:
	var content = text.trim_prefix("/me ").strip_edges()
	
	return {
		"type": "action",
		"sender": sender,
		"text": content
	}

func _parse_roll(text: String, sender: String) -> Dictionary:
	var dice_notation = text.trim_prefix("/roll ").strip_edges()
	
	# Parsear notación de dados (formato: XdY o XdY+Z)
	var result = _roll_dice(dice_notation)
	
	return {
		"type": "roll",
		"sender": sender,
		"dice": dice_notation,
		"result": result["total"],
		"rolls": result["rolls"],
		"modifier": result["modifier"]
	}

func _parse_whisper(text: String, sender: String) -> Dictionary:
	# Formato: /w [nombre] [mensaje]
	var content = text.trim_prefix("/w ").strip_edges()
	var parts = content.split(" ", true, 1)
	
	if parts.size() < 2:
		return {
			"type": "error",
			"sender": sender,
			"text": "Uso: /w [nombre] [mensaje]"
		}
	
	return {
		"type": "whisper",
		"sender": sender,
		"target": parts[0],
		"text": parts[1]
	}

# ===== SISTEMA DE DADOS =====

func _roll_dice(notation: String) -> Dictionary:
	# Formato soportado: XdY, XdY+Z, XdY-Z
	# Ejemplos: 1d20, 2d6+3, 1d100-5
	
	var result = {
		"total": 0,
		"rolls": [],
		"modifier": 0
	}
	
	# Detectar modificador
	var modifier = 0
	var dice_part = notation
	
	if "+" in notation:
		var parts = notation.split("+")
		dice_part = parts[0].strip_edges()
		modifier = int(parts[1].strip_edges()) if parts.size() > 1 else 0
	elif "-" in notation:
		var parts = notation.split("-")
		dice_part = parts[0].strip_edges()
		modifier = -int(parts[1].strip_edges()) if parts.size() > 1 else 0
	
	result["modifier"] = modifier
	
	# Parsear XdY
	if not "d" in dice_part:
		push_warning("[CommandParser] Formato de dado inválido: %s" % notation)
		return result
	
	var dice_parts = dice_part.split("d")
	if dice_parts.size() != 2:
		push_warning("[CommandParser] Formato de dado inválido: %s" % notation)
		return result
	
	var num_dice = int(dice_parts[0]) if dice_parts[0].is_valid_int() else 1
	var die_size = int(dice_parts[1]) if dice_parts[1].is_valid_int() else 20
	
	# Validar rangos
	num_dice = clampi(num_dice, 1, 100)  # Máximo 100 dados
	die_size = clampi(die_size, 2, 1000)  # Dado de 2 a 1000 caras
	
	# Tirar dados
	var total = 0
	for i in range(num_dice):
		var roll = randi_range(1, die_size)
		result["rolls"].append(roll)
		total += roll
	
	# Agregar modificador
	total += modifier
	result["total"] = total
	
	return result

# ===== UTILIDADES =====

## Valida si un texto es un comando válido
func is_valid_command(text: String) -> bool:
	if text.is_empty():
		return false
	
	# Lista de comandos válidos
	var valid_prefixes = ["//", "/ooc ", "/me ", "/roll ", "/w "]
	
	for prefix in valid_prefixes:
		if text.begins_with(prefix):
			return true
	
	return true  # Texto normal también es válido

## Obtiene ayuda sobre comandos
func get_command_help() -> String:
	return """Comandos disponibles:
	
[b]Mensajes:[/b]
  (texto normal) - Mensaje In Character (IC)
  // o /ooc [texto] - Mensaje Out Of Character (OOC)
  /me [acción] - Narración de acción
  /roll XdY - Tira dados (ej: /roll 1d20, /roll 2d6+3)
  /w [nombre] [mensaje] - Susurro (próximamente)

[b]Ejemplos:[/b]
  Hola, ¿cómo estás? → IC blanco
  //Tengo que salir 5 min → OOC gris
  /me sonríe pícaramente → Acción naranja
  /roll 1d20 → 🎲 Resultado aleatorio"""
