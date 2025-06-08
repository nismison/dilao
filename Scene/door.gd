extends Area2D

class_name DoorBase

@onready var next_room_info: Control = $NextRoomInfo

@export var is_opened: bool = false


func _ready() -> void:
	next_room_info.visible = false


func _on_body_entered(body: Node2D) -> void:
	if not is_opened:
		return
		
	next_room_info.global_position = global_position + Vector2(20, -20)
	next_room_info.set_label_text("123\n321\n\n\n\n778899")
	next_room_info.visible = true


func _on_body_exited(body: Node2D) -> void:
	if not is_opened:
		return
		
	next_room_info.visible = false
