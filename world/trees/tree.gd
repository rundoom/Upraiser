extends StaticBody2D


@onready var space_state := get_world_2d().direct_space_state
@onready var renderer := RenderingServer
@onready var world := get_tree().get_first_node_in_group("world") as WorldGame


func toggle_obstacle() -> void:
	await renderer.frame_post_draw
	world.create_obstacle.bind($HitBox.shape, $HitBox.global_transform).call_deferred()
