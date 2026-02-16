class_name CommandParser

func parse(text: String, sender: String) -> Dictionary:
	if text.begins_with("//") or text.begins_with("/ooc"):
		var content = text.trim_prefix("//").trim_prefix("/ooc ").strip_edges()
		return {"type": "ooc", "sender": sender, "text": content}
	elif text.begins_with("/me "):
		var content = text.trim_prefix("/me ").strip_edges()
		return {"type": "action", "sender": sender, "text": content}
	elif text.begins_with("/roll "):
		var dice_str = text.trim_prefix("/roll ").strip_edges()
		var result = _roll_dice(dice_str)
		return {"type": "roll", "sender": sender, "dice": dice_str, "result": result}
	else:
		return {"type": "ic", "sender": sender, "text": text}

func _roll_dice(notation: String) -> int:
	var parts = notation.split("d")
	if parts.size() != 2:
		return 0
	var num_dice = int(parts[0])
	var die_size = int(parts[1])
	if num_dice <= 0 or die_size <= 0:
		return 0
	var total = 0
	for i in range(num_dice):
		total += randi() % die_size + 1
	return total
