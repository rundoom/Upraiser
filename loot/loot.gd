extends StaticBody2D
class_name Loot


@export var MAX_VOLUME: int = 1
signal volume_changed(vol, max_vol)
@export var volume := 1:
	set(val):
		volume = val
		volume_changed.emit(val, MAX_VOLUME)
		if volume <= 0: queue_free()


@export var item_name := "untitled_item"
