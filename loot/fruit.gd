extends Food
class_name Fruit

signal fall(fruit)


func emit_fall():
	fall.emit(self)


func enable_collision() -> void:
	$CollisionShape2D.disabled = false
