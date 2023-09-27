extends Node


func _on_timer_timeout() -> void:
	get_tree().call_group("$energy_consume", "energy_consume")
