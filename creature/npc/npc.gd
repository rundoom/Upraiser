extends CharacterBody2D
class_name NPC


@export var SPEED := 300

@export var MAX_ENERGY := 300
@export var energy := MAX_ENERGY
@export var energy_consume_idle := 1

@export var MAX_FOOD := 300
@export var food := MAX_FOOD


func energy_consume() -> void:
	energy -= energy_consume_idle
