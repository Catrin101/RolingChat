class_name MessageFormatter

func format(parsed: Dictionary) -> String:
	match parsed["type"]:
		"ic":
			return "[color=white]%s: %s[/color]" % [parsed["sender"], parsed["text"]]
		"ooc":
			return "[color=gray](OOC) %s: %s[/color]" % [parsed["sender"], parsed["text"]]
		"action":
			return "[color=orange][i]* %s %s[/i][/color]" % [parsed["sender"], parsed["text"]]
		"roll":
			return "[color=green]🎲 %s rolled %s: %d[/color]" % [parsed["sender"], parsed["dice"], parsed["result"]]
	return ""
