extends StaticBody2D
class_name Loot


@export var volume := 1:
	set(val):
		volume = val
		if volume <= 0: queue_free()
 
@export var item_name := "untitled_item"
