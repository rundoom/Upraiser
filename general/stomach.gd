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
			$SpawnPoint/Foods.remove_child(child)
	
	for food in foods:
		if food in current_foods: continue
		var stomach_food = FoodForStomachSc.instantiate() as FoodForStomach
#		stomach_food.food_represented = food
		
		$SpawnPoint/Foods.add_child.call_deferred(stomach_food)
		if is_npc_changed:
			stomach_food.set_deferred("global_position", decide_marker())
		else:
			stomach_food.set_deferred("global_position", $EnterPoint.global_position)
			
		stomach_food.set_deferred("food_represented", food)
		
	current_foods = foods.duplicate()


func decide_marker() -> Vector2:
	match current_foods.size():
		0: return $SpawnPoint/Marker2D.global_position
		1: return $SpawnPoint/Marker2D2.global_position
		2: return $SpawnPoint/Marker2D3.global_position
		3: return $SpawnPoint/Marker2D5.global_position
		4: return $SpawnPoint/Marker2D4.global_position
		_: return $EnterPoint.global_position
