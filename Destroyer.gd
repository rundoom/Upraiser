extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_event_0"):
		get_parent().queue_free()
