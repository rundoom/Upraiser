extends TileMap
class_name WorldGame


@onready var space_state := get_world_2d().direct_space_state
var astar := AStar2D.new()
var cells_map := {}
var materialized_scenes := {}
var ground_cells : Array[Vector2i] = []


class TileType:
	const EMPTY_CELL = Vector2i(-1, -1)
	const WATER = Vector2i(6, 0)
	const GRASS = Vector2i(0, 0)
	const FOREST = Vector2i(2, 0)


func grow_plants():
	var grass_cells = get_used_cells(2)
	for plant in grass_cells:
		var current_atlas = get_cell_atlas_coords(2, plant)
		if current_atlas.x == 0 or randf() > 1: continue
		set_cell(2, plant, 4, Vector2i(current_atlas.x - 1, current_atlas.y))
		
	if ground_cells.is_empty():
		ground_cells = get_used_cells(0).filter(filter_ground)
	else:
		var rnd_idx = randi_range(0, ground_cells.size())
		var popped = ground_cells.pop_at(rnd_idx)
		set_cell(2, popped, 4, Vector2i(3, randi_range(0, 1)))


func filter_ground(it: Vector2i) -> bool:
	var tile_data = get_cell_tile_data(0, it)
	if tile_data == null: return false
	return tile_data.get_custom_data("is_ground") == true

func create_pathfinding_points() -> void:
	astar.clear()
	var used_cell_positions = get_used_cells(0)
	
	for cell_position in used_cell_positions:
#		var weight = get_cell_tile_data(0, cell_position).custom_data_0
		var weight = 1
		
		if weight > 0:
			var point_id = astar.get_available_point_id()
			cells_map[cell_position] = point_id
			astar.add_point(point_id, cell_position, weight)
		
	for cell_position in used_cell_positions:
		connect_cardinals(cell_position)


func connect_cardinals(point_position) -> void:
	var center = cells_map.get(point_position)
	if center == null: return
	
	var surroundings := get_surrounding_cells(point_position)
	for surrounding in surroundings:
		var surrounding_coord = cells_map.get(surrounding)
		if surrounding_coord == null: continue
		astar.connect_points(center, cells_map[surrounding], true)


func create_obstacle(shape: Shape2D, transform: Transform2D) -> void:
	var collision := PhysicsShapeQueryParameters2D.new()
	collision.shape = shape
	collision.transform = transform
	collision.collision_mask = 8
	var collisions := space_state.collide_shape(collision, 64)
	for coll in collisions:
		astar.set_point_disabled(cells_map[local_to_map(coll)])


func get_point_path(from: Vector2, to: Vector2) -> Array[Vector2]:
	var from_id := local_to_map(from)
	var to_id := local_to_map(to)
	
	var result: Array[Vector2] = []
	
	for it in astar.get_point_path(cells_map[from_id], cells_map[to_id]):
		result.append(map_to_local(it))
	
	return result


func get_used_cell_global_positions() -> Array:
	var cells = get_used_cells(0)
	var cell_positions := []
	for cell in cells:
		var cell_position := global_position + map_to_local(cell)
		cell_positions.append(cell_position)
	return cell_positions


func _physics_process(_delta: float) -> void:
	var cell_pos = local_to_map(get_local_mouse_position())
	var _cell_atlas = get_cell_atlas_coords(0, cell_pos)


func point_weight(point: Vector2i) -> float:
	return get_cell_tile_data(0, point).custom_data_0


func get_unit_in(point: Vector2i) -> Node2D:
	return _node_at_point(point, 1)


func get_item_in(point: Vector2i) -> Node2D:
	return _node_at_point(point, 2)
	

func materialize_tile(point: Vector2, tile_layer: int, collision_layers: int) -> Node2D:
	var i_coords = local_to_map(point)

	var data = get_cell_tile_data(tile_layer, i_coords)
	if data == null: return null
	
	var scene_path = data.get_custom_data("scene_represent")
	var scene = materialized_scenes.get(scene_path, null) as PackedScene
	if scene == null:
		scene = load(scene_path)
		materialized_scenes[scene_path] = scene

	erase_cell(tile_layer, i_coords)
	var material_node = scene.instantiate() as Node2D
	add_child(material_node)
	material_node.global_position = map_to_local(i_coords)
	return material_node


func _node_at_point(point: Vector2i, layer: int) -> Node2D:
	var interceptor_point = PhysicsPointQueryParameters2D.new()
	interceptor_point.position = map_to_local(point)
	interceptor_point.collision_mask = layer
	var colliders := space_state.intersect_point(interceptor_point)
	return colliders[0]["collider"] if !colliders.is_empty() else null


func is_point_passable(point: Vector2i) -> bool:
	return get_cell_atlas_coords(0, point) != TileType.EMPTY_CELL and \
		point_weight(point) != -1 and get_unit_in(point) == null


func _intersect_filter(visitor: Vector2i, from: Vector2i, exclude: CollisionObject2D = null) -> bool: 
	var excludes = [exclude.get_rid()] if exclude != null else []
	var ray = PhysicsRayQueryParameters2D.create(map_to_local(visitor), map_to_local(from), 1, excludes)
	var intersect = space_state.intersect_ray(ray)
	return true if intersect.is_empty() else false
