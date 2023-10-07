extends RigidBody2D
class_name FoodForStomach


@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var bubbles := $Bubbles
@onready var food_represented: Food:
	set(val):
		food_represented = val
		val.volume_changed.connect(volume_changed)
		volume_changed(val.volume, val.MAX_VOLUME)


func hold_out_bubbles() -> void:
	bubbles.emitting = false
	bubbles.reparent(get_parent())
	get_tree().create_timer(bubbles.lifetime + bubbles.process_material.lifetime_randomness)\
		.timeout.connect(bubbles.queue_free)
		
	queue_free()


func volume_changed(vol: int, max_vol: int) -> void:
	animation_player.current_animation = "dissolving"
	animation_player.pause()
	var advance_to = animation_player.current_animation_length - (vol * (animation_player.current_animation_length / max_vol))

	animation_player.advance(advance_to - animation_player.current_animation_position)
