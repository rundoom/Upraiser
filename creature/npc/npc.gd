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

@export var MAX_FOOD := 60
@export var food :Array[Food] = []

@onready var space_state = get_world_2d().direct_space_state
@export var detector_shape: Shape2D 

@onready var world := get_tree().get_first_node_in_group("world") as WorldGame
@onready var animated_sprite_2d: AnimatedSprite2D = $Rotator/AnimatedSprite2D
@onready var rotator: Marker2D = $Rotator
@onready var main_camera := get_tree().get_first_node_in_group("main_camera") as MainCamera

static var MARGIN_HOLD := 5.0
static var MARGIN_MOVE := 0.1

var move_to: Node2D
var current_path: Array[Vector2] 

var under_cursor = false

enum States {IDLE, EAT, RUN}
var current_state: States

var is_picked: bool = false:
	set(val):
		toggle_ui_signals(val)
		if val:
			print(self)
			for it in get_tree().get_nodes_in_group("pickable"):
				if it == self: continue
				it.is_picked = false
#			main_camera.enabled = true
			main_camera.stick_to(self)
		else:
			main_camera.stick_to(null)
#			main_camera.reparent(world, false)
#			main_camera.enabled = false
		is_picked = val
			
			
signal food_changed(npc, food)


func _physics_process(delta: float) -> void:
	if current_state == States.EAT:
		animated_sprite_2d.play("eat")
		return
		
	check_needs()
	
	if get_real_velocity().x > 0:
		rotator.scale = Vector2(1, 1)
	elif get_real_velocity().x < 0:
		rotator.scale = Vector2(-1, 1)
	
	var real_speed_factor := get_real_velocity().length()/200
	
	velocity = Vector2.ZERO
	safe_margin = MARGIN_HOLD
	animated_sprite_2d.pause()
	
	if is_current_path():
		velocity = global_position.direction_to(current_path.front()) * SPEED
		if global_position.distance_to(current_path.front()) < 15:
			current_path.remove_at(0)
		
		animated_sprite_2d.play("run")
		safe_margin = MARGIN_MOVE
	else:
		animated_sprite_2d.play("idle")

	if energy >= real_speed_factor:
		move_and_slide()
		energy -= real_speed_factor
	
	var line_path = current_path.map(func(it): return it - global_position)
	line_path.push_front(Vector2.ZERO)
	$PathTracker.points = line_path


func energy_consume() -> void:
	energy -= energy_consume_idle * 5
	for it in food:
		var volume_subtractor = min((MAX_ENERGY - energy) / it.dissolve_rate, it.dissolve_tick, it.volume)
		var food_value = volume_subtractor * it.dissolve_rate

		it.volume -= volume_subtractor

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
			
			if $Picker.overlaps_body(move_to):
				_on_picker_body_entered(move_to)
				return
			
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
		animated_sprite_2d.play("eat")
		food.append(body)
		food_changed.emit(self, food)
		body.get_parent().remove_child(body)
		current_state = States.EAT
		get_tree().create_timer(1).timeout.connect(func(): current_state = States.IDLE)
		$Label.text = str(food.map(func(it): return it.volume))
		current_path = []
		$PathTracker.points = []


func lost_food() -> void:
	move_to = null
	current_path = []
	velocity = Vector2.ZERO


func is_current_path() -> bool:
	return current_path != null and !current_path.is_empty()


func enable_physics():
	process_mode = Node.PROCESS_MODE_INHERIT


func _on_mouse_entered() -> void:
	under_cursor = true


func _on_mouse_exited() -> void:
	under_cursor = false


func _input(event: InputEvent) -> void:
	if under_cursor and event.is_action_pressed("LMB"):
		is_picked = true
	if is_picked and event.is_action_pressed("RMB"):
		is_picked = false


func toggle_ui_signals(enable: bool):
	var food_presenters = get_tree().get_nodes_in_group("$food_change")
	
	for it in food_presenters:
		if enable:
			if !food_changed.is_connected(it.food_change): food_changed.connect(it.food_change)
			food_changed.emit(self, food)
		else:
			food_changed.emit(null, food)
			if food_changed.is_connected(it.food_change): food_changed.disconnect(it.food_change)


func _on_tree_exiting() -> void:
	is_picked = false
