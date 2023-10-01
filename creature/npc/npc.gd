extends CharacterBody2D
class_name NPC


@export var SPEED := 100

@export var MAX_ENERGY := 300.0
@export var energy := MAX_ENERGY:
	set(val):
		energy = val
		$ProgressBar.value = energy
		
@export var energy_consume_idle := 1

@export var MAX_FOOD := 30
@export var food :Array[Food] = []

@onready var space_state = get_world_2d().direct_space_state
@onready var detector_shape = preload("res://creature/npc/detector_shape.tres")

var move_to: Node2D

func _physics_process(delta: float) -> void:
	var real_speed_factor := get_real_velocity().length()/200
	if energy >= real_speed_factor:
		move_and_slide()
		energy -= real_speed_factor


func energy_consume() -> void:
	energy -= energy_consume_idle
	$Label.text = str(food.map(func(it): return it.volume))
	for it in food:
		var food_value = it.dissolve_rate * it.dissolve_tick
		if food_value > MAX_ENERGY - energy: continue
		
		it.volume -= it.dissolve_tick
		if it.volume <= 0:
			food.erase(it)
			it.queue_free()
		energy += food_value
	$Label.text = str(food.map(func(it): return it.volume))


func check_needs() -> void:
	if move_to != null: return
	
	if food.reduce(func(acc, it): return it.volume + acc, 0) < MAX_FOOD / 2:
		var parameters = PhysicsShapeQueryParameters2D.new()
		parameters.shape = detector_shape
		parameters.transform = Transform2D(0, global_position)
		parameters.collision_mask = 2
		
		var intersects = space_state.intersect_shape(parameters)
		
		move_to = null
		
		for food_target in intersects.filter(func(it): return it.collider.is_in_group("edable")):
			if move_to == null or global_position.distance_to(food_target.collider.global_position) < global_position.distance_to(move_to.global_position):
				move_to = food_target.collider
				
		if move_to != null:
			move_to.tree_exiting.connect(lost_food, CONNECT_ONE_SHOT)
			
			var direct_vision = PhysicsRayQueryParameters2D.new()
			direct_vision.collision_mask = 4
			direct_vision.from = global_position
			direct_vision.to = move_to.global_position
			
			if is_direct_vision():
				velocity = global_position.direction_to(move_to.global_position) * SPEED
			
			
func is_direct_vision() -> bool:
	var direct_vision = PhysicsRayQueryParameters2D.new()
	direct_vision.collision_mask = 4
	direct_vision.from = global_position
	direct_vision.to = move_to.global_position
	
	return space_state.intersect_ray(direct_vision).is_empty()


func _on_picker_body_entered(body: Node2D) -> void:
	if body == move_to:
		food.append(body)
		body.get_parent().remove_child(body)


func lost_food() -> void:
	move_to = null
	velocity = Vector2.ZERO
