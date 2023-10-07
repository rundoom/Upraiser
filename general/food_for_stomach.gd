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
	var is_just_started = not animation_player.assigned_animation == "dissolving"
		
	animation_player.current_animation = "dissolving"
	animation_player.pause()
	var advance_to_pos = (animation_player.current_animation_length - (vol * (animation_player.current_animation_length / max_vol))) - animation_player.current_animation_position

	if is_just_started: 
		animation_player.advance(advance_to_pos)
	elif advance_to_pos > 0:
		animation_player.play("dissolving")
		get_tree().create_timer(advance_to_pos).timeout.connect(animation_player.pause)
