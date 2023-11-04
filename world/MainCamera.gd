extends Camera2D
class_name MainCamera


var follow_target: Node2D = null

var zoom_tween: Tween = null:
	get:
		return create_tween() if zoom_tween == null else zoom_tween


func stick_to(target: Node2D) -> void:
	follow_target = target
	
	if target != null:
		global_position = follow_target.global_position
		zoom_tween.tween_property(self, "zoom", Vector2(2, 2), 0.5)
	else:
		zoom_tween.tween_property(self, "zoom", Vector2(1, 1), 0.5)
	

func _physics_process(delta: float) -> void:
	if follow_target != null: global_position = follow_target.global_position


