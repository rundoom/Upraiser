extends CharacterBody2D
class_name NPC


@export var SPEED := 100

@export var MAX_ENERGY := 300.0
@export var energy := MAX_ENERGY:
	set(val):
		energy = val
		$ProgressBar.value = energy
		if energy <= 0 and food.is_empty(): queue_free()
		
@export var energy_consume_idle := 1

@export var MAX_FOOD := 30
@export var food :Array[Food] = []

@onready var space_state = get_world_2d().direct_space_state
@onready var detector_shape = preload("res://creature/npc/detector_shape.tres")

@onready var world := get_tree().get_first_node_in_group("world") as WorldGame

var move_to: Node2D
var current_path: Array[Vector2] 


func _physics_process(delta: float) -> void:
	var real_speed_factor := get_real_velocity().length()/200
	
	if is_current_path():
		velocity = global_position.direction_to(current_path.front()) * SPEED
		if global_position.distance_to(current_path.front()) < 15:
			current_path.remove_at(0)

	if energy >= real_speed_factor:
		move_and_slide()
		energy -= real_speed_factor


func energy_consume() -> void:
	energy -= energy_consume_idle * 5
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
	if is_current_path():
		return
	
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
			if !move_to.tree_exiting.is_connected(lost_food):
				move_to.tree_exiting.connect(lost_food, CONNECT_ONE_SHOT)
			
			var direct_vision = PhysicsRayQueryParameters2D.new()
			direct_vision.collision_mask = 4
			direct_vision.from = global_position
			direct_vision.to = move_to.global_position
			
			if is_direct_vision():
				current_path = [move_to.global_position]
			else:
				current_path = world.get_point_path(global_position, move_to.global_position)
				
			if is_current_path(): velocity = global_position.direction_to(current_path.front()) * SPEED


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
	current_path = []
	velocity = Vector2.ZERO


func is_current_path() -> bool:
	return current_path != null and !current_path.is_empty()
