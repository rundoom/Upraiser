extends RigidBody2D
class_name FoodForStomach


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $SubViewportContainer/SubViewport/Sprite2D
@onready var animation_pauser: Timer = $AnimationPauser

@export_group("image")
@export var food_image: Texture2D:
	set(val):
		food_image = val
		sprite_2d.texture = food_image
		
@export var viewport_scale: Vector2:
	set(val):
		viewport_scale = val
		$SubViewportContainer.scale = viewport_scale
		
@export var food_image_region: Rect2:
	set(val):
		food_image_region = val
		sprite_2d.region_rect = food_image_region
		
		
@export var food_image_size: Vector2:
	set(val):
		food_image_size = val
		$SubViewportContainer.size = val
		
@export var food_image_position: Vector2:
	set(val):
		food_image_position = val
		$SubViewportContainer.position = val

@export_group("", "")

@onready var bubbles := $Bubbles
@onready var food_represented: Food:
	set(val):
		food_represented = val
		food_image = val.image_sprite
		viewport_scale = val.image_region_scale
		food_image_region = val.image_region_rect
		food_image_size = val.image_size
		food_image_position = (-val.image_size / 2) * val.image_region_scale
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
	var advance_to_pos = animation_player.current_animation_length - (vol * (animation_player.current_animation_length / max_vol))
	var advance_secs = advance_to_pos - animation_player.current_animation_position
	
	printt(vol, advance_to_pos)

	if is_just_started: 
		animation_player.advance(advance_secs)
	elif advance_secs > 0:
		animation_player.play("dissolving")
		if advance_to_pos < animation_player.current_animation_length:
			animation_pauser.wait_time = animation_pauser.time_left + advance_to_pos
			animation_pauser.start()
