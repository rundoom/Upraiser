extends Node


func _on_heartbeat() -> void:
	get_tree().call_group("$energy_consume", "energy_consume")
#	get_tree().call_group("$check_needs", "check_needs")
	get_tree().call_group("$spawn_fruit", "spawn_fruit")
	get_tree().call_group("$check_needs", "enable_physics")
	get_tree().call_group("world", "grow_plants")
