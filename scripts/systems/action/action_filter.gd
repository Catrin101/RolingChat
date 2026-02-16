class_name ActionFilter

static func get_compatible_actions(player1: AvatarData, player2: AvatarData) -> Array:
	var acciones = ConfigLoader.acciones
	var compatible = []
	for accion in acciones:
		if _is_compatible(accion, player1, player2):
			compatible.append(accion)
	return compatible

static func _is_compatible(accion: Dictionary, p1: AvatarData, p2: AvatarData) -> bool:
	var sexos_match = false
	var razas_match = false
	
	for combo in accion["combinaciones_sexo"]:
		if (combo[0] == p1.sexo_id and combo[1] == p2.sexo_id) or \
		   (combo[0] == p2.sexo_id and combo[1] == p1.sexo_id):
			sexos_match = true
			break
	
	for combo in accion["combinaciones_raza"]:
		if (combo[0] == p1.raza_id and combo[1] == p2.raza_id) or \
		   (combo[0] == p2.raza_id and combo[1] == p1.raza_id):
			razas_match = true
			break
	
	return sexos_match and razas_match
