extends RigidBody2D


@onready var bubbles := $Bubbles


func hold_out_bubbles() -> void:
	bubbles.emitting = false
	bubbles.reparent(get_parent())
	get_tree().create_timer(bubbles.lifetime + bubbles.process_material.lifetime_randomness)\
		.timeout.connect(bubbles.queue_free)
		
	queue_free()
