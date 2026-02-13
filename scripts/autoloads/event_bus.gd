# scripts/autoloads/event_bus.gd
extends Node

## EventBus - Sistema centralizado de señales globales
## Permite comunicación desacoplada entre sistemas del juego
## Patrón: Observer

# ===== SEÑALES DE NETWORKING =====

## Emitida cuando un jugador se conecta exitosamente a la sala
signal player_connected(peer_id: int, player_name: String)

## Emitida cuando un jugador se desconecta
signal player_disconnected(peer_id: int)

## Emitida cuando la conexión al servidor falla
signal connection_failed(reason: String)

## Emitida cuando se pierde la conexión con el servidor
signal connection_lost()

## Emitida cuando se crea una sala exitosamente
signal room_created(room_code: String)

## Emitida cuando se une exitosamente a una sala
signal room_joined()

# ===== SEÑALES DE CHAT =====

## Emitida cuando se recibe un mensaje de chat
## sender: Nombre del personaje que envió el mensaje
## text: Contenido del mensaje
## msg_type: "ic", "ooc", "action", "roll", "system"
signal message_received(sender: String, text: String, msg_type: String)

# ===== SEÑALES DE ESCENAS CONJUNTAS =====

## Emitida cuando una escena conjunta está disponible para unirse
signal scene_available(object_id: String, template_id: String, initiator_peer_id: int)

## Emitida cuando una escena conjunta comienza
signal scene_started(scene_id: String, players: Array)

## Emitida cuando una escena conjunta termina
signal scene_ended(object_id: String)

# ===== SEÑALES DE AVATARES =====

## Emitida cuando un avatar es creado o modificado
signal avatar_created(avatar_data: Resource)

## Emitida cuando un avatar de otro jugador es actualizado
signal avatar_updated(peer_id: int, avatar_data: Dictionary)

# ===== SEÑALES DE INTERACCIÓN =====

## Emitida cuando un jugador interactúa con un objeto del mundo
signal object_interacted(object_id: String, template_id: String)

# ===== SEÑALES DE UI =====

## Emitida cuando se debe mostrar una notificación al usuario
signal show_notification(message: String, type: String)

## Emitida cuando se debe mostrar un error
signal show_error(message: String)

## Emitida cuando se debe mostrar un mensaje de éxito
signal show_success(message: String)

# ===== MÉTODOS DE UTILIDAD =====

func _ready() -> void:
	print("[EventBus] Sistema de señales globales inicializado")

## Emite un mensaje de sistema en el chat
func emit_system_message(message: String) -> void:
	message_received.emit("Sistema", message, "system")

## Emite una notificación de error
func emit_error(message: String) -> void:
	show_error.emit(message)
	print_rich("[color=red][ERROR][/color] ", message)

## Emite una notificación de éxito
func emit_success(message: String) -> void:
	show_success.emit(message)
	print_rich("[color=green][SUCCESS][/color] ", message)

## Emite una notificación informativa
func emit_info(message: String) -> void:
	show_notification.emit(message, "info")
	print("[INFO] ", message)
