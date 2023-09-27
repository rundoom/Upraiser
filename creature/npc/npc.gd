extends CharacterBody2D
class_name NPC


@export var SPEED := 100

@export var MAX_ENERGY := 300
@export var energy := MAX_ENERGY:
	set(val):
		energy = val
		$ProgressBar.value = energy
		
@export var energy_consume_idle := 1

@export var MAX_FOOD := 30
@export var food :Array[Food] = []

@onready var space_state = get_world_2d().direct_space_state

var move_to: Node2D

func _physics_process(delta: float) -> void:
	move_and_slide()
	energy -= get_real_velocity().length()/100
		

func energy_consume() -> void:
	energy -= energy_consume_idle
	for it in food:
		it.volume -= it.dissolve_tick
		if it.volume <= 0:
			food.erase(it)
			it.queue_free()
		energy += it.dissolve_rate * it.dissolve_tick


func check_needs() -> void:
	if move_to != null: return
	print(food.reduce(func(acc, it): return it.volume + acc, 0))
	if food.reduce(func(acc, it): return it.volume + acc, 0) < MAX_FOOD / 2:
		var parameters = PhysicsShapeQueryParameters2D.new()
		parameters.shape = $Detector/CollisionShape2D.shape
		parameters.transform = Transform2D(0, global_position)
		parameters.collision_mask = 2
		
		var intersects = space_state.intersect_shape(parameters)
		
		move_to = null
		
		for food_target in intersects.filter(func(it): return it.collider.is_in_group("edable")):
			if move_to == null or global_position.distance_to(food_target.collider.global_position) < global_position.distance_to(move_to.global_position):
				move_to = food_target.collider
				
		if move_to != null:
			move_to.tree_exiting.connect(lost_food, CONNECT_ONE_SHOT)
			velocity = global_position.direction_to(move_to.global_position) * SPEED


func _on_picker_body_entered(body: Node2D) -> void:
	if body == move_to:
		food.append(body)
		body.get_parent().remove_child(body)


func lost_food() -> void:
	move_to = null
	velocity = Vector2.ZERO
