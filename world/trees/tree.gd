extends StaticBody2D


@onready var space_state := get_world_2d().direct_space_state
@onready var world := get_tree().get_first_node_in_group("world") as WorldGame
@export var FruitSc: PackedScene
@onready var fruit_pointer: PathFollow2D = $FruitPlaces/PathFollow2D


func toggle_obstacle() -> void:
	await RenderingServer.frame_post_draw
	world.create_obstacle($HitBox.shape, $HitBox.global_transform)


func spawn_fruit() -> void:
	if randf() < 0.9: return
	var fruit = FruitSc.instantiate() as Fruit
	fruit_pointer.progress_ratio = randf()
	
	$FruitHolder.add_child(fruit)
	fruit.global_position = fruit_pointer.global_position
	fruit.fall.connect(drop_fruit, CONNECT_ONE_SHOT)
	
	
func drop_fruit(fruit_node: Fruit) -> void:
	fruit_node.reparent(world)
	var tween = fruit_node.create_tween()
	tween.set_ease(tween.EASE_IN)
	tween.parallel().tween_property(fruit_node, "position", fruit_node.position + Vector2(0, 120), 0.5)
	tween.parallel().tween_property(fruit_node, "rotation", -43, 0.5)
	tween.finished.connect(fruit_node.enable_collision)
