extends CharacterBody2D
class_name NPC


@export var SPEED := 100

@export var MAX_ENERGY := 300
@export var energy := MAX_ENERGY
@export var energy_consume_idle := 1

@export var MAX_FOOD := 30
@export var food :Array[Food] = []

@onready var space_state = get_world_2d().direct_space_state

var move_to: Node2D


func _physics_process(delta: float) -> void:
	move_and_slide()


func energy_consume() -> void:
	energy -= energy_consume_idle
	for it in food:
		it.volume -= it.dissolve_tick
		if it.volume <= 0:
			food.erase(it)
			it.queue_free()
		energy += it.dissolve_rate * it.dissolve_tick
	


func check_needs() -> void:
#	if food < MAX_FOOD / 2:
		var parameters = PhysicsShapeQueryParameters2D.new()
		parameters.shape = $Detector/CollisionShape2D.shape
		parameters.transform = Transform2D(0, global_position)
		parameters.collision_mask = 2
		
		var intersects = space_state.intersect_shape(parameters)
		
		move_to = null
		
		for food_target in intersects.filter(func(it): return it.collider.is_in_group("edable")):
			if move_to == null or global_position.distance_to(food_target.collider.global_position) < global_position.distance_to(move_to.global_position):
				move_to = food_target.collider
				velocity = global_position.direction_to(food_target.collider.global_position) * SPEED


func _on_picker_body_entered(body: Node2D) -> void:
	if body == move_to:
		food.append(body)
		body.get_parent().remove_child(body)
		velocity = Vector2.ZERO
