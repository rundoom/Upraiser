extends AnimatedSprite2D
signal beat


func _on_frame_changed() -> void:
	if frame == 10:
		beat.emit()
