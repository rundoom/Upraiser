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

var image_sprite: Texture2D:
	get:
		return $Sprite2D.texture

var image_region_rect:
	get:
		return $Sprite2D.region_rect

var image_region_scale:
	get:
		return $Sprite2D.scale

var image_size:
	get:
		return Vector2($Sprite2D.region_rect.size.x, $Sprite2D.region_rect.size.y)
