# scripts/systems/world/player_spawner.gd
class_name PlayerSpawner
extends Node2D

## PlayerSpawner - Gestiona spawning de jugadores en el mundo
## Responsabilidad: Crear/destruir PlayerEntity según conexiones/desconexiones
## Patrón: Factory + Observer

# ===== CONFIGURACIÓN =====

const PLAYER_ENTITY_SCENE := preload("res://scenes/wold/player_entity.tscn")

# Puntos de spawn por defecto
const DEFAULT_SPAWN_POSITIONS := [
	Vector2(100, 100),
	Vector2(200, 100),
	Vector2(300, 100),
	Vector2(100, 200),
	Vector2(200, 200),
	Vector2(300, 200),
	Vector2(100, 300),
	Vector2(200, 300),
]

# ===== ESTADO =====

## Diccionario de entidades spawneadas {peer_id: PlayerEntity}
var player_entities: Dictionary = {}

## Índice para rotar spawn positions
var next_spawn_index: int = 0

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Conectar señales del EventBus
	EventBus.player_connected.connect(_on_player_connected)
	EventBus.player_disconnected.connect(_on_player_disconnected)
	
	print("[PlayerSpawner] Sistema de spawning inicializado")
	
	# Spawn jugadores existentes (útil si entramos a un mundo con jugadores ya conectados)
	call_deferred("_spawn_existing_players")

# ===== SPAWNING =====

func _spawn_existing_players() -> void:
	# Spawnear todos los jugadores ya conectados
	for peer_id in NetworkManager.players.keys():
		var player_data = NetworkManager.players[peer_id]
		_spawn_player(peer_id, player_data)

func _spawn_player(peer_id: int, player_data: Dictionary) -> void:
	# Evitar duplicados
	if player_entities.has(peer_id):
		print("[PlayerSpawner] Jugador %d ya existe" % peer_id)
		return
	
	# Crear entidad
	var player_entity = PLAYER_ENTITY_SCENE.instantiate()
	add_child(player_entity)
	
	# Determinar si es local
	var is_local = (peer_id == multiplayer.get_unique_id())
	
	# Obtener datos del avatar
	var character_name = player_data.get("character_name", "Jugador")
	var avatar_dict = player_data.get("avatar_data", {})
	
	# Convertir dict a AvatarData si es necesario
	var avatar_data: AvatarData = null
	if not avatar_dict.is_empty():
		avatar_data = AvatarData.new()
		avatar_data.from_dict(avatar_dict)
	
	# Obtener posición de spawn
	var spawn_pos = _get_spawn_position()
	player_entity.position = spawn_pos
	
	# Setup de la entidad
	player_entity.setup(peer_id, character_name, avatar_data, is_local)
	
	# Agregar al diccionario
	player_entities[peer_id] = player_entity
	
	print("[PlayerSpawner] ✓ Spawneado: %s (ID:%d, Local:%s)" % [character_name, peer_id, is_local])
	
	# Si es local, hacer que la cámara lo siga
	if is_local:
		_setup_camera_follow(player_entity)

func _despawn_player(peer_id: int) -> void:
	if not player_entities.has(peer_id):
		return
	
	var player_entity = player_entities[peer_id]
	var character_name = player_entity.character_name
	
	# Remover del diccionario
	player_entities.erase(peer_id)
	
	# Destruir entidad
	player_entity.queue_free()
	
	print("[PlayerSpawner] ✓ Despawneado: %s (ID:%d)" % [character_name, peer_id])

# ===== POSICIONAMIENTO =====

func _get_spawn_position() -> Vector2:
	var pos = DEFAULT_SPAWN_POSITIONS[next_spawn_index % DEFAULT_SPAWN_POSITIONS.size()]
	next_spawn_index += 1
	return pos

# ===== CÁMARA =====

func _setup_camera_follow(player_entity: PlayerEntity) -> void:
	# Crear cámara para seguir al jugador local
	var camera = Camera2D.new()
	camera.enabled = true
	camera.zoom = Vector2(1.5, 1.5) # Zoom in un poco
	player_entity.add_child(camera)
	
	print("[PlayerSpawner] Cámara configurada para jugador local")

# ===== CALLBACKS =====

func _on_player_connected(peer_id: int, player_name: String) -> void:
	print("[PlayerSpawner] Jugador conectado: %s (ID:%d)" % [player_name, peer_id])
	
	# Esperar un frame para que NetworkManager actualice su diccionario
	await get_tree().process_frame
	
	# Spawn del nuevo jugador
	if NetworkManager.players.has(peer_id):
		_spawn_player(peer_id, NetworkManager.players[peer_id])

func _on_player_disconnected(peer_id: int) -> void:
	print("[PlayerSpawner] Jugador desconectado: ID:%d" % peer_id)
	_despawn_player(peer_id)

# ===== SINCRONIZACIÓN DE POSICIONES =====

func _physics_process(_delta: float) -> void:
	# Actualizar posiciones de jugadores remotos
	_sync_remote_positions()

func _sync_remote_positions() -> void:
	for peer_id in player_entities.keys():
		var entity = player_entities[peer_id]
		
		# Solo actualizar remotos
		if not entity.is_local():
			# Obtener posición desde NetworkManager si está disponible
			if NetworkManager.players.has(peer_id):
				var player_data = NetworkManager.players[peer_id]
				if player_data.has("position"):
					var pos = player_data["position"]
					entity.update_remote_position(pos)

# ===== API PÚBLICA =====

## Obtiene la entidad del jugador local
func get_local_player() -> PlayerEntity:
	var local_peer_id = multiplayer.get_unique_id()
	return player_entities.get(local_peer_id, null)

## Obtiene una entidad por peer_id
func get_player_entity(peer_id: int) -> PlayerEntity:
	return player_entities.get(peer_id, null)

## Obtiene todas las entidades
func get_all_players() -> Array:
	return player_entities.values()

## Obtiene el conteo de jugadores spawneados
func get_player_count() -> int:
	return player_entities.size()
