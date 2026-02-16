extends Node

var current_avatar: AvatarData = null
var profiles_path: String = "user://profiles/"

func _ready():
	# Crear carpeta de perfiles si no existe
	if not DirAccess.dir_exists_absolute(profiles_path):
		DirAccess.make_dir_absolute(profiles_path)

func list_profiles() -> Array[String]:
	var files = []
	var dir = DirAccess.open(profiles_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				files.append(file_name.replace(".json", ""))
			file_name = dir.get_next()
	return files

func load_profile(name: String) -> AvatarData:
	var path = profiles_path + name + ".json"
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var data = JSON.parse_string(text)
		if data:
			return AvatarData.from_dict(data)
	return null

func save_profile(avatar: AvatarData, name: String) -> bool:
	var path = profiles_path + name + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json = JSON.stringify(avatar.to_dict(), "\t")
		file.store_string(json)
		return true
	return false

func delete_profile(name: String) -> bool:
	var path = profiles_path + name + ".json"
	if FileAccess.file_exists(path):
		return DirAccess.remove_absolute(path) == OK
	return false

func set_current_avatar(avatar: AvatarData):
	current_avatar = avatar
