extends Node


func _on_heartbeat() -> void:
	get_tree().call_group("$energy_consume", "energy_consume")
	get_tree().call_group("$check_needs", "check_needs")
