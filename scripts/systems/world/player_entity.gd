# scripts/systems/world/player_entity.gd
class_name PlayerEntity
extends CharacterBody2D

## PlayerEntity - Representa a un jugador en el mundo
## Responsabilidad: Movimiento, avatar visual, sincronización de red
## Patrón: Entity-Component

# ===== CONFIGURACIÓN =====

const SPEED := 200.0
const SYNC_INTERVAL := 0.1  # 10 veces por segundo

# ===== COMPONENTES =====

@onready var avatar_builder: AvatarBuilder = $AvatarBuilder
@onready var name_label: Label = $NameLabel
@onready var sync_timer: Timer = $SyncTimer

# ===== ESTADO =====

var peer_id: int = 0
var character_name: String = "Jugador"
var avatar_data: AvatarData = null
var is_local_player: bool = false

# Para interpolación de movimiento
var target_position: Vector2 = Vector2.ZERO
var interpolation_speed: float = 10.0

# ===== CICLO DE VIDA =====

func _ready() -> void:
	# Configurar sincronización
	if is_local_player:
		sync_timer.wait_time = SYNC_INTERVAL
		sync_timer.timeout.connect(_on_sync_timeout)
		sync_timer.start()
	else:
		# Para jugadores remotos, usar interpolación
		target_position = position
	
	print("[PlayerEntity] Entidad creada para peer %d (%s)" % [peer_id, character_name])

func _physics_process(delta: float) -> void:
	if is_local_player:
		_handle_local_movement(delta)
	else:
		_handle_remote_interpolation(delta)

# ===== INICIALIZACIÓN =====

## Inicializa la entidad con datos del jugador
func setup(p_peer_id: int, p_character_name: String, p_avatar_data: AvatarData, p_is_local: bool) -> void:
	peer_id = p_peer_id
	character_name = p_character_name
	avatar_data = p_avatar_data
	is_local_player = p_is_local
	
	# Actualizar label de nombre
	name_label.text = character_name
	
	# Construir avatar visual
	if avatar_data and avatar_builder:
		avatar_builder.build_from_data(avatar_data)
	
	# Configurar visibilidad del label
	if is_local_player:
		name_label.modulate = Color(0.5, 1.0, 0.5)  # Verde para local
	
	print("[PlayerEntity] Setup completado para %s (local: %s)" % [character_name, is_local_player])

# ===== MOVIMIENTO LOCAL =====

func _handle_local_movement(delta: float) -> void:
	# Obtener input
	var input_direction := Vector2.ZERO
	input_direction.x = Input.get_axis("ui_left", "ui_right")
	input_direction.y = Input.get_axis("ui_up", "ui_down")
	
	# Normalizar para velocidad consistente en diagonales
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
	
	# Aplicar velocidad
	velocity = input_direction * SPEED
	
	# Mover
	move_and_slide()

# ===== MOVIMIENTO REMOTO (INTERPOLACIÓN) =====

func _handle_remote_interpolation(delta: float) -> void:
	# Interpolar hacia la posición objetivo
	if position.distance_to(target_position) > 1.0:
		position = position.lerp(target_position, interpolation_speed * delta)
	else:
		position = target_position

## Actualiza la posición objetivo (llamado desde RPC)
func update_remote_position(new_position: Vector2) -> void:
	target_position = new_position

# ===== SINCRONIZACIÓN DE RED =====



# ===== API PÚBLICA =====

## Obtiene el peer_id de esta entidad
func get_peer_id() -> int:
	return peer_id

## Verifica si es el jugador local
func is_local() -> bool:
	return is_local_player

## Cambia el tipo de vista del avatar
func set_avatar_view(view_type: String) -> void:
	if avatar_builder:
		avatar_builder.set_view_type(view_type)

## Teletransporta a una posición (sin interpolación)
func teleport_to(new_position: Vector2) -> void:
	position = new_position
	target_position = new_position
