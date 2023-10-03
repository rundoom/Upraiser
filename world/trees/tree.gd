extends StaticBody2D


@onready var space_state := get_world_2d().direct_space_state
@onready var renderer := RenderingServer
@onready var world := get_tree().get_first_node_in_group("world") as WorldGame
@onready var FruitSc = preload("res://loot/fruit.tscn")
@onready var fruit_pointer: PathFollow2D = $FruitPlaces/PathFollow2D


func toggle_obstacle() -> void:
	await renderer.frame_post_draw
	world.create_obstacle.bind($HitBox.shape, $HitBox.global_transform).call_deferred()


func spawn_fruit() -> void:
	if $FruitHolder.get_child_count() >= 5: return
	var fruit = FruitSc.instantiate() as Fruit
	fruit_pointer.progress_ratio = randf()
	
	$FruitHolder.add_child(fruit)
	fruit.global_position = fruit_pointer.global_position
	fruit.fall.connect(drop_fruit, CONNECT_ONE_SHOT)
	
	
func drop_fruit() -> void:
	pass
