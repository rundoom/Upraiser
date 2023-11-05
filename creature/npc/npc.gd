extends CharacterBody2D
class_name NPC


@export var SPEED := 100

@export var MAX_ENERGY := 300.0
@export var energy := MAX_ENERGY:
	set(val):
		energy = val
		$ProgressBar.value = energy
		energy_changed.emit(self, energy, MAX_ENERGY)
		if energy <= 0 and food.is_empty(): queue_free()
		
signal energy_changed(npc, energy, max_energy)
		
@export var energy_consume_idle := 1

@export var MAX_FOOD := 60
@export var food :Array[Food] = []

@onready var space_state = get_world_2d().direct_space_state
@export var detector_shape: Shape2D 

@onready var world := get_tree().get_first_node_in_group("world") as WorldGame
@onready var animated_sprite_2d: AnimatedSprite2D = $Rotator/AnimatedSprite2D
@onready var rotator: Marker2D = $Rotator
@onready var main_camera := get_tree().get_first_node_in_group("main_camera") as MainCamera
@onready var ui_layer := get_tree().get_first_node_in_group("UI") as UILayer
@onready var move_pointer := get_tree().get_first_node_in_group("move_pointer") as Marker2D

@export var allowed_food: Array[StringName]

static var MARGIN_HOLD := 5.0
static var MARGIN_MOVE := 0.1

var move_to: Node2D
var current_path: Array[Vector2] 

var under_cursor = false
var under_control = false
static var is_some_selected = false

enum States {IDLE, EAT, RUN}
var current_state: States:
	set(val):
		current_state = val
		$Rotator/FoodParticles.emitting = current_state == States.EAT

var is_picked: bool = false:
	set(val):
		toggle_ui_signals(val)
		if val:
			print(self)
			for it in get_tree().get_nodes_in_group("pickable"):
				if it == self: continue
				it.is_picked = false
			main_camera.stick_to(self)
		elif is_picked:
			main_camera.stick_to(null)
		is_picked = val
			
			
signal food_changed(npc, food)


func _physics_process(delta: float) -> void:
	if current_state == States.EAT:
		animated_sprite_2d.play("eat")
		return
		
	if not under_control: check_needs()
	
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
		
		for food_target in intersects.filter(func(it): return it.collider.is_in_group("edable") and _is_group_intersects(it.collider.get_groups())):
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
		if not _is_group_intersects(body.get_groups()):
			move_to = null
			return
			
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
	if event.is_action_pressed("LMB"):
		if under_cursor and !is_some_selected:
			is_picked = true
			is_some_selected = true
		elif under_control:
			var is_fit_capacity = food.reduce(func(acc, it): return it.volume + acc, 0) < MAX_FOOD / 2
			var item_clicked = world.get_item_in(get_global_mouse_position())
			if item_clicked == null or not (is_fit_capacity and _is_group_intersects(item_clicked.get_groups())):
				move_to = world.materialize_tile(get_global_mouse_position(), 2, 64) if is_fit_capacity else null
				if move_to == null:
					move_to = move_pointer
					move_pointer.global_position = get_global_mouse_position()
			else:
				move_to = item_clicked
				if $Picker.overlaps_body(item_clicked):
					_on_picker_body_entered(item_clicked)
					return
				
			if is_direct_vision(): current_path = [move_to.global_position]
			else: current_path = world.get_point_path(global_position, move_to.global_position)
				
	if is_picked and event.is_action_pressed("RMB"):
		is_picked = false
		is_some_selected = false


func toggle_ui_signals(enable: bool):
	var food_presenters = get_tree().get_nodes_in_group("$food_change")
	
	if !energy_changed.is_connected(ui_layer.touch): energy_changed.connect(ui_layer.touch)

	if enable:
		energy_changed.emit(self, energy, MAX_ENERGY)
		if !energy_changed.is_connected(ui_layer.touch): energy_changed.connect(ui_layer.touch)
		for it in food_presenters:
			if !food_changed.is_connected(it.food_change): food_changed.connect(it.food_change)
			food_changed.emit(self, food)
	else:
		under_control = false
		energy_changed.emit(null, energy, MAX_ENERGY)
		if energy_changed.is_connected(ui_layer.touch): energy_changed.disconnect(ui_layer.touch)
		for it in food_presenters:
			food_changed.emit(null, food)
			if food_changed.is_connected(it.food_change): food_changed.disconnect(it.food_change)
			
			
func obey():
	under_control = true
	

func _on_tree_exiting() -> void:
	if is_picked: is_some_selected = false
	is_picked = false


func _is_group_intersects(food_groups: Array[StringName]):
	return food_groups.any(func(it): return allowed_food.has(it))
