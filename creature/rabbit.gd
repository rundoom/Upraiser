extends NPC


func check_needs() -> void:
	super.check_needs()
	if is_current_path():
		return
	
	if food.reduce(func(acc, it): return it.volume + acc, 0) < MAX_FOOD / 2:
		var parameters = PhysicsShapeQueryParameters2D.new()
		parameters.shape = detector_shape
		parameters.transform = Transform2D(0, global_position)
		parameters.collision_mask = 64
		
		var intersects = space_state.collide_shape(parameters)
		
		var to_point = null
		
		for food_target in intersects:
			if to_point == null or global_position.distance_to(food_target) < global_position.distance_to(to_point):
				to_point = food_target
				
		if to_point == null: return
		
		move_to = world.materialize_tile(to_point, 2, 64)
				
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
