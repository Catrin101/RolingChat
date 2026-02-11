# scripts/autoloads/game_manager.gd
extends Node

## GameManager - Gestión del estado global del juego
## Responsabilidad: Mantener estado del jugador local, configuración y gestión de sesión
## Patrón: Singleton

# ===== CONSTANTES =====

const VERSION := "1.0.0-MVP"
const SAVE_PATH := "user://profiles/"
const CONFIG_PATH := "user://config.json"

# ===== ESTADO DEL JUEGO =====

## ID del peer local (asignado por NetworkManager)
var local_peer_id: int = 0

## Indica si el jugador local es el host de la sala
var is_host: bool = false

## Código de la sala actual
var room_code: String = ""

## Nombre de la sala actual
var room_name: String = ""

## Datos del avatar del jugador local
var current_avatar_data: Resource = null

# ===== CONFIGURACIÓN =====

## Configuración de audio
var audio_settings := {
	"master_volume": 0.8,
	"music_volume": 0.6,
	"sfx_volume": 0.8,
	"muted": false
}

## Configuración de video
var video_settings := {
	"fullscreen": false,
	"vsync": true,
	"resolution": Vector2i(1280, 720)
}

## Configuración de controles
var control_settings := {
	"move_up": "ui_up",
	"move_down": "ui_down",
	"move_left": "ui_left",
	"move_right": "ui_right",
	"interact": "ui_accept"
}

# ===== CICLO DE VIDA =====

func _ready() -> void:
	print("[GameManager] Inicializando versión %s" % VERSION)
	_ensure_directories_exist()
	_load_config()
	print("[GameManager] Sistema inicializado correctamente")

func _ensure_directories_exist() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_recursive_absolute(SAVE_PATH)
		print("[GameManager] Directorio de perfiles creado: ", SAVE_PATH)

# ===== GESTIÓN DE ESTADO =====

## Establece si el jugador local es el host
func set_is_host(value: bool) -> void:
	is_host = value
	print("[GameManager] Modo host: ", value)

## Establece el código de la sala actual
func set_room_code(code: String) -> void:
	room_code = code
	print("[GameManager] Código de sala: ", code)

## Establece el nombre de la sala
func set_room_name(name: String) -> void:
	room_name = name

## Obtiene el avatar actual del jugador
func get_current_avatar() -> Resource:
	return current_avatar_data

## Establece el avatar actual del jugador
func set_current_avatar(avatar_data: Resource) -> void:
	current_avatar_data = avatar_data
	print("[GameManager] Avatar actualizado: ", avatar_data)

# ===== GESTIÓN DE CONFIGURACIÓN =====

## Carga la configuración desde disco
func _load_config() -> void:
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		print("[GameManager] No se encontró config.json, usando valores por defecto")
		_save_config()
		return
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("[GameManager] Error parseando config.json")
		return
	
	var data = json.data
	if data.has("audio"):
		audio_settings.merge(data["audio"], true)
	if data.has("video"):
		video_settings.merge(data["video"], true)
	if data.has("controls"):
		control_settings.merge(data["controls"], true)
	
	print("[GameManager] Configuración cargada")

## Guarda la configuración en disco
func _save_config() -> void:
	var config = {
		"version": VERSION,
		"audio": audio_settings,
		"video": video_settings,
		"controls": control_settings
	}
	
	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[GameManager] No se pudo guardar config.json")
		return
	
	file.store_string(JSON.stringify(config, "\t"))
	file.close()
	print("[GameManager] Configuración guardada")

## Aplica la configuración de audio
func apply_audio_settings() -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(audio_settings["master_volume"])
	)
	AudioServer.set_bus_mute(
		AudioServer.get_bus_index("Master"),
		audio_settings["muted"]
	)

## Aplica la configuración de video
func apply_video_settings() -> void:
	if video_settings["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		get_window().size = video_settings["resolution"]
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if video_settings["vsync"] else DisplayServer.VSYNC_DISABLED
	)

# ===== UTILIDADES =====

## Limpia el estado del juego (llamar al salir de una sala)
func reset_session() -> void:
	is_host = false
	room_code = ""
	room_name = ""
	local_peer_id = 0
	print("[GameManager] Sesión reiniciada")

## Retorna información de debug del estado actual
func get_debug_info() -> Dictionary:
	return {
		"version": VERSION,
		"is_host": is_host,
		"peer_id": local_peer_id,
		"room_code": room_code,
		"has_avatar": current_avatar_data != null
	}
