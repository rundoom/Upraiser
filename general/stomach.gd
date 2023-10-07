extends StaticBody2D


var FoodForStomachSc = preload("res://general/food_for_stomach.tscn")
var current_npc: NPC = null
var current_foods: Array[Food] = []


func food_change(npc: NPC, foods: Array[Food]) -> void:
	var is_npc_changed = false
	if current_npc != npc:
		current_npc = npc
		is_npc_changed = true
		current_foods = []
		for child in $SpawnPoint/Foods.get_children():
			child.queue_free()
	
	for food in foods:
		if food in current_foods: continue
		var stomach_food = FoodForStomachSc.instantiate() as FoodForStomach
#		prevent render bug
		stomach_food.hide()
		
		place_food.call_deferred(stomach_food, food, is_npc_changed)
			
	current_foods = foods.duplicate()


func place_food(stomach_food: FoodForStomach, food: Food, is_npc_changed:bool) -> void:
		$SpawnPoint/Foods.add_child(stomach_food)
		stomach_food.food_represented = food
		if is_npc_changed:
			stomach_food.global_position = decide_marker()
		else:
			stomach_food.global_position = $EnterPoint.global_position

#		prevent render bug
		RenderingServer.frame_post_draw.connect(stomach_food.show)


func decide_marker() -> Vector2:
	match $SpawnPoint/Foods.get_child_count():
		0: return $SpawnPoint/Marker2D.global_position
		1: return $SpawnPoint/Marker2D2.global_position
		2: return $SpawnPoint/Marker2D3.global_position
		3: return $SpawnPoint/Marker2D5.global_position
		4: return $SpawnPoint/Marker2D4.global_position
		_: return $EnterPoint.global_position
