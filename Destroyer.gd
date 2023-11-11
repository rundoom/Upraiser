extends Node


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_event_0"):
		if get_parent().has_method("die"): get_parent().die()
		else: get_parent().queue_free()
